// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {ShareToken} from "../../core/ShareToken.sol";
import {VineLib} from "../../libraries/VineLib.sol";
import {IL2Pool} from "../../interfaces/aaveV3/IL2Pool.sol";
import {IL2Encode} from "../../interfaces/aaveV3/IL2Encode.sol";
import {ICrossCenter} from "../../interfaces/ICrossCenter.sol";
import {IGovernance} from "../../interfaces/core/IGovernance.sol";
import {IVineStruct} from "../../interfaces/IVineStruct.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {ISharer} from "../../interfaces/ISharer.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineAaveV3LendMain is
    ShareToken,
    ReentrancyGuard,
    IVineStruct,
    IVineEvent,
    ISharer
{
    using SafeERC20 for IERC20;
    uint256 public id;
    address public factory;
    address public govern;
    address public owner;
    address public manager;

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1;
    bytes1 public lockState;
    bytes1 public protocolFeeState;
    bytes1 public finallyState;
    uint16 private referralCode;
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

    modifier Lock() {
        require(lockState == ZEROBYTES1, "Lock");
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

    //user deposite usdc
    function deposite(
        uint64 amount,
        address usdc,
        address l2Pool,
        address receiver
    ) external nonReentrant Lock {
        uint64 currentTime = uint64(block.timestamp);
        uint64 bufferTime = _getMarketInfo().bufferTime;
        uint64 endTime = _getMarketInfo().endTime;
        require(currentTime <= bufferTime, "End of pledge");  //need > 1 days
        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        bytes1 state1 = _l2Deposite(l2Pool, usdc, amount);
        require(state1 == ONEBYTES1, "Supply fail");
        uint256 shareTokenAmount = (endTime - currentTime) * amount;
        depositeTotalAmount += amount;
        _UserSupplyInfo[receiver].pledgeAmount += amount; 
        _UserSupplyInfo[receiver].supplyTime = currentTime;
        emit UserDeposite(receiver, amount);
        bytes1 state2 = depositeMint(receiver, shareTokenAmount);
        require(state2 == ONEBYTES1, "Mint fail");
    }

    function withdraw(address usdc) external nonReentrant {
        uint64 endTime = _getMarketInfo().endTime;
        require(block.timestamp >= endTime + 4 hours,"Non withdraw time");   //need 4 hours
        _updateFinallyAmount(usdc, endTime);
        uint16 curatorFee = _getMarketInfo().curatorFee;
        uint16 protocolFee = _getMarketInfo().protocolFee;
        uint64  pledgeAmount = _UserSupplyInfo[msg.sender].pledgeAmount;
        uint256 userShareTokenAmount = balanceOf(msg.sender);
        uint256 totalSupply = totalSupply();
        address protocolFeeReceiver = _getMarketInfo().protocolFeeReceiver;
        require(finallyAmount > 0, "Zero withdraw amount");
        uint256 earnAmount = VineLib._getUserFinallyAmount(
            curatorFee, 
            protocolFee, 
            pledgeAmount, 
            depositeTotalAmount, 
            userShareTokenAmount, 
            finallyAmount, 
            totalSupply
        );
        require(earnAmount > 0, "Zero");
        IERC20(usdc).safeTransfer(msg.sender, earnAmount);
        if(pledgeAmount > 0){
            _UserSupplyInfo[msg.sender].pledgeAmount = 0;
            depositeTotalAmount -= pledgeAmount;
        }
        //total fee
        if(protocolFeeState == ZEROBYTES1){
            uint256 officialFeeAmount = VineLib._feeAmount(protocolFee, depositeTotalAmount, finallyAmount);
            IERC20(usdc).safeTransfer(
                protocolFeeReceiver,
                officialFeeAmount
            );
            protocolFeeState = ONEBYTES1;
        }
        emit UserWithdraw(msg.sender, earnAmount);
        bytes1 withdrawBurnState = withdrawBurn(msg.sender, userShareTokenAmount);
        require(withdrawBurnState == ONEBYTES1, "Burn fail");
    }

    function withdrawFee(address usdc) external nonReentrant onlyManager {
        uint16 curatorFee = _getMarketInfo().curatorFee;
        uint64 endTime = _getMarketInfo().endTime;
        address feeReceiver = _getMarketInfo().feeReceiver;
        require(feeReceiver != address(0));
        require(CuratorWithdrawState[manager] == false, "Already withdraw");
        require(block.timestamp >= endTime + 4 hours,"Non withdraw time");   //need 4 hours
        _updateFinallyAmount(usdc, endTime);
        if(CuratorWithdrawState[manager] == false){
            uint256 curatorFeeAmount = VineLib._feeAmount(curatorFee, depositeTotalAmount, finallyAmount);
            IERC20(usdc).safeTransfer(
                feeReceiver,
                curatorFeeAmount
            );
            CuratorWithdrawState[manager] = true;
        }
    }

    function inL2Supply(
        address l2Pool,
        address usdc,
        uint256 amount
    ) external onlyManager {
        bytes1 l2DepositeState = _l2Deposite(l2Pool, usdc, amount);
        require(l2DepositeState == ONEBYTES1, "L2Deposite fail");
    }

    function inL2Withdraw(
        address l2Pool,
        address ausdc,
        uint256 ausdcAmount
    ) external onlyManager {
        bytes1 l2withdrawState = _l2Withdraw(l2Pool, ausdc, ausdcAmount);
        require(l2withdrawState == ONEBYTES1, "L2Withdraw fail");
    }

    function crossUSDC(
        uint16 indexDestHook,
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

    function receiveUSDCAndL2Supply(
        IVineStruct.ReceiveUSDCAndL2SupplyParams calldata params
    ) external onlyManager {
        address crossCenter = _getMarketInfo().crossCenter;
        ICrossCenter(crossCenter).receiveUSDC(
            params.message,
            params.attestation
        );
        uint256 usdcBalance = _tokenBalance(params.usdc, address(this));
        require(usdcBalance > 0, "USDC zero balance");
        bytes1 depositeState = _l2Deposite(params.l2Pool, params.usdc, usdcBalance);
        require(depositeState == ONEBYTES1, "L2Deposite fail");
    }

    function l2WithdrawAndCrossUSDC(
        IVineStruct.L2WithdrawAndCrossUSDCParams calldata params
    ) external onlyManager {
        _checkValidEndTime();
        bytes32 hook =  _getValidHook(params.destinationDomain, params.indexDestHook);
        uint256 ausdcBalance = _tokenBalance(params.ausdc, address(this));
        bytes1 l2withdrawState = _l2Withdraw(params.l2Pool, params.ausdc, ausdcBalance);
        require(l2withdrawState == ONEBYTES1, "Withdraw fail");
        uint256 usdcBalance = _tokenBalance(params.usdc, address(this));
        _crossUsdc(
            params.destinationDomain,
            params.inputBlock,
            hook,
            params.usdc,
            usdcBalance
        );
    }
    
    function updateFinallyAmount(address usdc) external {
        require(msg.sender == manager || msg.sender == _officialManager());
        uint64 endTime = _getMarketInfo().endTime;
        require(block.timestamp >= endTime);
        if(finallyState == ZEROBYTES1){
            finallyAmount = _tokenBalance(usdc, address(this));
            finallyState = ONEBYTES1;
        }else{
            revert("Already update");
        }
    }

    function _updateFinallyAmount(address usdc, uint64 endTime) private {
        if(block.timestamp >= endTime){
            if(finallyState == ZEROBYTES1){
                finallyAmount = _tokenBalance(usdc, address(this));
                finallyState = ONEBYTES1;
            }
        }
    }

    function _l2Deposite(
        address l2Pool,
        address usdc,
        uint256 amount
    ) private returns (bytes1) {
        IERC20(usdc).approve(l2Pool, amount);
        address l2Encode = _getL2Encode();
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeSupplyParams(
            usdc,
            amount,
            referralCode
        );
        IL2Pool(l2Pool).supply(encodeMessage);
        emit L2Supply(amount);
        return ONEBYTES1;
    }

    function _l2Withdraw(
        address l2Pool,
        address ausdc,
        uint256 ausdcAmount
    ) private returns (bytes1) {
        require(ausdcAmount > 0, "AUSDC amount zero");
        address l2Encode = _getL2Encode();
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeWithdrawParams(
            ausdc,
            ausdcAmount
        );
        IERC20(ausdc).approve(l2Pool, ausdcAmount);
        uint256 usdcAmount = IL2Pool(l2Pool).withdraw(encodeMessage);
        emit L2withdraw(usdcAmount, ausdcAmount);
        return ONEBYTES1;
    }

    function _crossUsdc(
        uint32 destinationDomain, 
        uint64 inputBlock, 
        bytes32 hook, 
        address usdc, 
        uint256 crossUSDCAmount
    ) private {
        _checkValidEndTime();
        address crossCenter = _getMarketInfo().crossCenter;
        IERC20(usdc).approve(crossCenter, crossUSDCAmount);
        ICrossCenter(crossCenter).crossUSDC(
            destinationDomain,
            inputBlock,
            hook,
            usdc,
            crossUSDCAmount
        );
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

    function _getL2Encode()private view returns(address _l2Encode){
        _l2Encode = IGovernance(govern).getL2Encode();
    }

    function _tokenBalance(
        address token,
        address user
    ) private view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = IERC20(token).balanceOf(user);
    }

    function _checkValidEndTime() private view {
        uint64 endTime = _getMarketInfo().endTime;
        require(block.timestamp < endTime, "Non cross time");
    }

    function _getMarketInfo() private view returns(IGovernance.MarketInfo memory _marketInfo){
        _marketInfo = IGovernance(govern).getMarketInfo(id);
    }

    function _getValidHook(uint32 destinationDomain, uint16 indexDestHook) private view returns(bytes32 validHook){
        validHook = IGovernance(govern).getDestHook(id, destinationDomain, indexDestHook);
    }

    function getUserSupply(address user)external view returns(UserSupplyInfo memory){
        return _UserSupplyInfo[user];
    }


}
