// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IPool} from "../../interfaces/aaveV3/IPool.sol";
import {ShareToken} from "../../core/ShareToken.sol";
import {VineLib} from "../../libraries/VineLib.sol";
import {IL2Pool} from "../../interfaces/aaveV3/IL2Pool.sol";
import {IL2Encode} from "../../interfaces/aaveV3/IL2Encode.sol";
import {ICoreCrossCenter} from "../../interfaces/ICoreCrossCenter.sol";
import {IGovernance} from "../../interfaces/core/IGovernance.sol";
import {IVineStruct} from "../../interfaces/IVineStruct.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
import {ISharer} from "../../interfaces/ISharer.sol";
import {VineLib} from "../../libraries/VineLib.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineAaveV3LendMain02 is
    ShareToken,
    ReentrancyGuard,
    IVineStruct,
    IVineEvent,
    IVineHookErrors,
    ISharer
{
    using SafeERC20 for IERC20;

    using SafeERC20 for IERC20;
    uint256 public id;
    address public factory;
    address public govern;
    address public owner;
    address public manager;

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1 = 0x01;
    bytes1 public lockState;
    bytes1 public protocolFeeState;
    uint16 private referralCode;
    uint32 public currentDomain;
    uint64 public depositeTotalAmount;
    uint256 public finallyAmount;

    constructor(
        address _govern, 
        address _owner, 
        address _manager, 
        uint256 _id,
        string memory name_, 
        string memory symbol_
    )ShareToken(name_, symbol_) {
        factory = msg.sender;
        govern = _govern;
        owner = _owner;
        manager = _manager;
        id = _id;
        currentDomain = VineLib._currentDomain();
    }

    mapping(address => UserSupplyInfo) private _UserSupplyInfo;

    mapping(address => bool) public CuratorWithdrawState;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }

    function transferOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function transferManager(address newManager) external onlyOwner {
        manager = newManager;
    }

    function setReferralCode(uint16 _referralCode) external onlyManager {
        referralCode = _referralCode;
    }

    function setLock(bytes1 state) external onlyManager {
        lockState = state;
    }

    function changeDomain(uint32 newDomain) external onlyManager{
        currentDomain = newDomain;
    }

    //user deposite usdc
    function deposite(
        uint64 amount,
        address usdc,
        address usdcPool,
        address receiver
    ) external nonReentrant {
        if(lockState != ZEROBYTES1){
            revert LockError(ErrorType.Lock);
        }
        //amount >= 10000
        if(amount < 10000 ){
            revert InsufficientBalance(ErrorType.InsufficientBalance);
        }
        uint64 currentTime = uint64(block.timestamp);
        uint64 bufferTime = _getMarketInfo().bufferTime;
        uint64 endTime = _getMarketInfo().endTime;
        if(currentTime > bufferTime){
            revert EndOfPledgeError(ErrorType.EndOfPledge);
        }
        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);

        bytes1 state = _aaveSupply(usdcPool, usdc, amount);
        if(state != ONEBYTES1){
            revert SupplyFail(ErrorType.SupplyFail);
        }
        uint256 shareTokenAmount = (endTime - currentTime) * amount;
        depositeTotalAmount += amount;
        _UserSupplyInfo[receiver].pledgeAmount += amount; 
        _UserSupplyInfo[receiver].supplyTime = currentTime;
        emit UserDeposite(receiver, amount);

        bytes1 state2 = depositeMint(receiver, shareTokenAmount);
        if(state2 != ONEBYTES1){
            revert MintFail(ErrorType.MintFail);
        }
    }

    function withdraw(address usdc) external nonReentrant {
        uint64 endTime = _getMarketInfo().endTime;
        if(block.timestamp < endTime + 4 hours){
            revert NonWithdrawTime(ErrorType.NonWithdrawTime);
        }
        uint16 curatorFee = _getMarketInfo().curatorFee;
        uint16 protocolFee = _getMarketInfo().protocolFee;
        uint64  pledgeAmount = _UserSupplyInfo[msg.sender].pledgeAmount;
        uint256 userShareTokenAmount = balanceOf(msg.sender);
        uint256 thisTotalSupply = totalSupply();
        address protocolFeeReceiver = _getMarketInfo().protocolFeeReceiver;
        if(finallyAmount == 0){
            revert InsufficientBalance(ErrorType.InsufficientBalance);
        }
        uint256 earnAmount = VineLib._getUserFinallyAmount(
            curatorFee, 
            protocolFee, 
            pledgeAmount, 
            depositeTotalAmount, 
            userShareTokenAmount, 
            finallyAmount, 
            thisTotalSupply
        );
        if(earnAmount == 0){
            revert ZeroBalance(ErrorType.ZeroBalance);
        }
        IERC20(usdc).safeTransfer(msg.sender, earnAmount);
        if(pledgeAmount > 0){
            _UserSupplyInfo[msg.sender].pledgeAmount = 0;
            depositeTotalAmount -= pledgeAmount;
        }
        //protocol fee
        if(protocolFeeState == ZEROBYTES1){
            uint256 officialFeeAmount = VineLib._protocolFeeAmount(protocolFee, depositeTotalAmount, finallyAmount);
            if(officialFeeAmount > 0){
                IERC20(usdc).safeTransfer(
                    protocolFeeReceiver,
                    officialFeeAmount
                );
                protocolFeeState = ONEBYTES1;
            }
        }
        emit UserWithdraw(msg.sender, earnAmount);
        bytes1 withdrawBurnState = withdrawBurn(msg.sender, userShareTokenAmount);
        if(withdrawBurnState != ONEBYTES1){
            revert BurnFail(ErrorType.BurnFail);
        }
    }

    function withdrawFee(address usdc) external nonReentrant onlyManager {
        uint16 curatorFee = _getMarketInfo().curatorFee;
        uint64 endTime = _getMarketInfo().endTime;
        address feeReceiver = _getMarketInfo().feeReceiver;
        uint256 curatorFeeAmount = VineLib._curatorFeeAmount(curatorFee, depositeTotalAmount, finallyAmount);
        if(curatorFeeAmount == 0){
            revert InsufficientBalance(ErrorType.InsufficientBalance); 
        }
        if(feeReceiver == address(0)){
            revert ZeroAddress(ErrorType.ZeroAddress);
        }
        if(CuratorWithdrawState[manager]){
            revert AlreadyWithdraw(ErrorType.AlreadyWithdraw);
        }
        if(block.timestamp < endTime + 4 hours){
            revert NonWithdrawTime(ErrorType.NonWithdrawTime);
        }
        if(CuratorWithdrawState[manager] == false){
            IERC20(usdc).safeTransfer(
                feeReceiver,
                curatorFeeAmount
            );
            CuratorWithdrawState[manager] = true;
        }
    }

    function inL1Supply(
        address usdcPool,
        address usdc,
        uint256 amount
    ) public onlyManager {
        _checkValidEndTime();
        bytes1 state = _aaveSupply(usdcPool, usdc, amount);
        if(state != ONEBYTES1){
            revert SupplyFail(ErrorType.SupplyFail);
        }
    }

    function inL1Withdraw(
        address usdcPool,
        address ausdc,
        address usdc,
        uint256 amount
    ) external {
        bytes1 state = _aaveWithdraw(usdcPool, ausdc, usdc, amount);
        if(state != ONEBYTES1){
            revert WithdrawFail(ErrorType.WithdrawFail);
        }
        require(_updateFinallyAmount(usdc) == ONEBYTES1);
    }

    function crossUSDC(
        uint8 indexDestHook,
        uint32 destinationDomain,
        uint64 inputBlock,
        address usdc,
        uint256 amount
    ) public onlyManager {
        _checkValidEndTime();
        bytes32 hook = _getValidHook(destinationDomain, indexDestHook);
        _crossUsdc(
            destinationDomain,
            inputBlock,
            hook,
            usdc,
            amount
        );
    }

    function receiveUSDC(
        bytes calldata message,
        bytes calldata attestation
    ) external onlyManager {
        _receiveUSDC(message, attestation);
    }

    function receiveUSDCAndL1Supply(
        IVineStruct.ReceiveUSDCAndL1SupplyParams calldata params
    ) external onlyManager {
        _checkValidEndTime();
        _receiveUSDC(params.message, params.attestation);
        uint256 usdcBalance = _tokenBalance(params.usdc, address(this));
        if(usdcBalance == 0){
            revert ZeroBalance(ErrorType.ZeroBalance);
        }
        bytes1 supplyState = _aaveSupply(params.usdcPool, params.usdc, usdcBalance);
        if(supplyState != ONEBYTES1){
            revert SupplyFail(ErrorType.SupplyFail);
        }
    }

    function l1WithdrawAndCrossUSDC(
        IVineStruct.L1WithdrawAndCrossUSDCParams calldata params
    ) external {
        _checkValidEndTime();
        bytes32 hook = _getValidHook(params.destinationDomain, params.indexDestHook);
        bytes1 withdrawState = _aaveWithdraw(
            params.usdcPool,
            params.ausdc,
            params.usdc,
            params.ausdcAmount
        );
        if(withdrawState != ONEBYTES1){
            revert WithdrawFail(ErrorType.WithdrawFail);
        }
        uint256 usdcBalance = _tokenBalance(params.usdc, address(this));
        if (usdcBalance == 0) {
            revert ZeroBalance(ErrorType.ZeroBalance);
        }
        _crossUsdc(
            params.destinationDomain,
            params.inputBlock,
            hook,
            params.usdc,
            usdcBalance
        );
    }

    function updateFinallyAmount(address usdc) external{
        address crossCenter = _getMarketInfo().crossCenter;
        require(msg.sender == crossCenter || msg.sender == _officialManager(), "Non caller");
        require(_updateFinallyAmount(usdc) == ONEBYTES1);
    }

    function _updateFinallyAmount(address usdc) private returns(bytes1){
        uint64 endTime = _getMarketInfo().endTime;
        uint256 beforeFinallyAmount = finallyAmount;
        uint256 usdcBalance = _tokenBalance(usdc, address(this));
        if(block.timestamp >= endTime){
            if(usdcBalance > beforeFinallyAmount){
                finallyAmount = usdcBalance;
            }
        }
        return ONEBYTES1;
    }

    function _aaveSupply(
        address usdcPool,
        address usdc,
        uint256 amount
    ) private returns (bytes1 state) {
        IERC20(usdc).approve(usdcPool, amount);
        IPool(usdcPool).supply(usdc, amount, address(this), referralCode);
        emit L2Supply(amount);
        state = ONEBYTES1;
    }

    function _aaveWithdraw(
        address usdcPool,
        address ausdc,
        address usdc,
        uint256 amount
    ) private returns (bytes1 state) {
        IERC20(ausdc).approve(usdcPool, amount);
        IPool(usdcPool).withdraw(usdc, amount, address(this));
        state = ONEBYTES1;
    }

    function _crossUsdc(
        uint32 destinationDomain, 
        uint64 inputBlock, 
        bytes32 hook, 
        address usdc, 
        uint256 amount
    ) private {
        if(destinationDomain == currentDomain){
            address destCurrentChainHook = _bytes32ToAddress(hook);
            IERC20(usdc).approve(destCurrentChainHook, amount);
            IERC20(usdc).transfer(destCurrentChainHook, amount);
        }else{
            address crossCenter = _getMarketInfo().crossCenter;
            IERC20(usdc).approve(crossCenter, amount);
            ICoreCrossCenter(crossCenter).crossUSDC(
                destinationDomain,
                inputBlock,
                hook,
                amount
            );
        }
    }

    function _receiveUSDC(
        bytes calldata message,
        bytes calldata attestation
    ) private {
        address crossCenter = _getMarketInfo().crossCenter;
        bool _receiveState = ICoreCrossCenter(crossCenter).receiveUSDC(
            message,
            attestation
        );
        if(_receiveState == false){
            revert ReceiveUSDCFail(ErrorType.ReceiveUSDCFail);
        }
    }

    function _checkOwner() private view {
        require(msg.sender == owner, "Non owner");
    }

    function _checkManager() private view {
        require(msg.sender == manager, "Non manager");
    }

    function _officialManager() private view returns(address _offManager){
        _offManager = IGovernance(govern).manager();
    }

    function _getValidHook(uint32 destinationDomain, uint8 indexDestHook) private view returns(bytes32 validHook){
        validHook = IGovernance(govern).getDestHook(id, destinationDomain, indexDestHook);
    }

    function _tokenBalance(
        address token,
        address user
    ) private view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = IERC20(token).balanceOf(user);
    }

    function _checkValidEndTime() private view {
        uint64 endTime = _getMarketInfo().endTime;
        if(block.timestamp >= endTime){
            revert NonCrossTime(ErrorType.NonCrossTime);
        }
    }

    function _getMarketInfo() private view returns(IGovernance.MarketInfo memory _marketInfo){
        _marketInfo = IGovernance(govern).getMarketInfo(id);
    }

    function _bytes32ToAddress(
        bytes32 _bytes32Account
    ) private pure returns (address) {
        return address(uint160(uint256(_bytes32Account)));
    }

    function getUserSupply(address user)external view returns(UserSupplyInfo memory){
        return _UserSupplyInfo[user];
    }

}
