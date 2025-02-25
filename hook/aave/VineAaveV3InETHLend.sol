// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IPool} from "../../interfaces/aaveV3/IPool.sol";
import {IVineStruct} from "../../interfaces/IVineStruct.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
import {ICrossCenter} from "../../interfaces/ICrossCenter.sol";
import {ISharer} from "../../interfaces/ISharer.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import "../../libraries/VineLib.sol";

import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineAaveV3InETHLend is
    IVineStruct,
    IVineEvent,
    IVineHookErrors,
    ISharer,
    IWormholeReceiver
{
    using SafeERC20 for IERC20;

    uint256 public id;
    bytes1 private immutable ONEBYTES1 = 0x01;
    uint16 private referralCode;
    uint32 public currentDomain;
    address public factory;
    address public govern;
    address public owner;
    address public manager;
    uint256 public emergencyTime;

    constructor(address _govern, address _owner, address _manager, uint256 _id) {
        factory = msg.sender;
        govern = _govern;
        owner = _owner;
        manager = _manager;
        id = _id;
        currentDomain = VineLib._currentDomain();
    }

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

    function transferManager(address newManager)external onlyOwner{
        manager = newManager;
    }

    function setReferralCode(uint16 _referralCode) external onlyManager{
        referralCode = _referralCode;
    }

    function changeDomain(uint32 newDomain) external onlyManager{
        currentDomain = newDomain;
    }

    function inEthSupply(
        address usdcPool,
        address usdc,
        uint256 amount
    ) public onlyManager {
        bytes1 state = _aaveSupply(usdcPool, usdc, amount);
        if(state != ONEBYTES1){
            revert SupplyFail(ErrorType.SupplyFail);
        }
    }

    function inEthWithdraw(
        address usdcPool,
        address ausdc,
        address usdc,
        uint256 amount
    ) external {
        _checkOperator();
        uint256 ausdcBalance=_tokenBalance(ausdc, address(this));
        uint256 withdrawAmount=amount>ausdcBalance?ausdcBalance:amount;
        bytes1 state = _aaveWithdraw(usdcPool, ausdc, usdc, withdrawAmount);
        if(state != ONEBYTES1){
            revert WithdrawFail(ErrorType.WithdrawFail);
        }
    }

    function crossUSDC(
        uint8 indexDestHook,
        uint32 destinationDomain,
        uint64 sendBlock,
        address usdc,
        uint256 amount
    ) external {
        _checkOperator();
        bytes32 hook = _getValidHook(destinationDomain, indexDestHook);
        _crossUSDC(
            destinationDomain, 
            sendBlock, 
            hook, 
            usdc, 
            amount
        );
    }

    function receiveUSDCAndETHSupply(
        IVineStruct.ReceiveUSDCAndL1SupplyParams calldata params
    ) external onlyManager {
        address crossCenter = _crossCenter();
        ICrossCenter(crossCenter).receiveUSDC(params.message, params.attestation);
        uint256 usdcBalance = _tokenBalance(params.usdc, address(this));
        if(usdcBalance == 0){
            revert ZeroBalance(ErrorType.ZeroBalance);
        }
        bytes1 supplyState = _aaveSupply(params.usdcPool, params.usdc, usdcBalance);
        if(supplyState != ONEBYTES1){
            revert SupplyFail(ErrorType.SupplyFail);
        }
    }

    function ethWithdrawAndCrossUSDC(
        IVineStruct.L1WithdrawAndCrossUSDCParams calldata params
    ) external {
        _checkOperator();
        bytes32 hook = _getValidHook(params.destinationDomain, params.indexDestHook);
        uint256 ausdcBalance=_tokenBalance(params.ausdc, address(this));
        bytes1 withdrawState = _aaveWithdraw(
            params.usdcPool,
            params.ausdc,
            params.usdc,
            ausdcBalance
        );
        if(withdrawState != ONEBYTES1){
            revert WithdrawFail(ErrorType.WithdrawFail);
        }
        uint256 usdcBalance = _tokenBalance(params.usdc, address(this));
        if (usdcBalance == 0) {
            revert ZeroBalance(ErrorType.ZeroBalance);
        }
        _crossUSDC(
            params.destinationDomain,
            params.inputBlock,
            hook,
            params.usdc,
            usdcBalance
        );
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32,
        uint16,
        bytes32
    ) external payable{
        (uint256 crossId, uint256 crossEmergencyTime) = abi.decode(payload, (uint256, uint256));
        emergencyTime = crossEmergencyTime;
        if(crossId != id){
            revert("Invalid id");
        }
        if(block.timestamp < crossEmergencyTime){
            revert("Not emergency time");
        }
    } 

    function _crossUSDC(
        uint32 destinationDomain,
        uint64 sendBlock,
        bytes32 hook, 
        address usdc,
        uint256 amount
    )private {
        if(destinationDomain == currentDomain){
            address destCurrentChainHook = _bytes32ToAddress(hook);
            IERC20(usdc).approve(destCurrentChainHook, amount);
            IERC20(usdc).transfer(destCurrentChainHook, amount);
        }else{
            address crossCenter = _crossCenter();
            IERC20(usdc).approve(crossCenter, amount);
            ICrossCenter(crossCenter).crossUSDC(destinationDomain, sendBlock, hook, usdc, amount);
        }
    }

    function _aaveSupply(
        address usdcPool,
        address usdc,
        uint256 amount
    ) private returns (bytes1 state) {
        IERC20(usdc).approve(usdcPool, amount);
        IPool(usdcPool).supply(usdc, amount, address(this), referralCode);
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

    function _getValidHook(uint32 destinationDomain, uint8 index) private view returns(bytes32 validHook){
        validHook = IVineHookCenter(govern).getDestHook(id, destinationDomain, index);
    }

    function _tokenBalance(
        address token,
        address user
    ) private view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = IERC20(token).balanceOf(user);
    }

    function _checkOwner() internal view {
        require(msg.sender == owner);
    }

    function _checkManager() internal view {
        require(msg.sender == manager);
    }

    function _crossCenter() private view returns(address crossCenter){
        crossCenter = IVineHookCenter(govern).getMarketInfo(id).crossCenter;
    }

    function _checkOperator() private view {
        require(msg.sender == manager || (block.timestamp > emergencyTime && emergencyTime > 0), "Non manager or not emergency time");
    } 

    function _bytes32ToAddress(
        bytes32 _bytes32Account
    ) private pure returns (address) {
        return address(uint160(uint256(_bytes32Account)));
    }

    function getTokenBalance(
        address token,
        address user
    ) external view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = _tokenBalance(token, user);
    }

}
