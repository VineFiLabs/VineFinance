// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IVineStruct} from "../../interfaces/IVineStruct.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {ISharer} from "../../interfaces/ISharer.sol";
import {IL2Pool} from "../../interfaces/aaveV3/IL2Pool.sol";
import {IL2Encode} from "../../interfaces/aaveV3/IL2Encode.sol";
import {ICrossCenter} from "../../interfaces/ICrossCenter.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {VineLib} from "../../libraries/VineLib.sol";

import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineAaveV3InL2Lend is
    IVineStruct,
    IVineEvent,
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

    function transferManager(address newManager) external onlyOwner {
        manager = newManager;
    }

    function setReferralCode(uint16 _referralCode) external onlyManager {
        referralCode = _referralCode;
    }

    function changeDomain(uint32 newDomain) external onlyManager{
        currentDomain = newDomain;
    }

    function inL2Supply(
        address l2Pool,
        address usdc,
        uint256 amount
    ) external onlyManager {
        bytes1 state = _l2Deposite(l2Pool, usdc, amount);
        require(state == ONEBYTES1, "Supply fail");
    }

    function inL2Withdraw(
        address l2Pool,
        address ausdc,
        uint256 ausdcAmount
    ) external {
        _checkOperator();
        uint256 ausdcBalance = _tokenBalance(ausdc, address(this));
        require(ausdcBalance > 0, "Zero balance");
        address l2Encode = _getL2Encode();
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeWithdrawParams(
            ausdc,
            ausdcAmount
        );
        IERC20(ausdc).approve(l2Pool, ausdcAmount);
        IL2Pool(l2Pool).withdraw(encodeMessage);
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
        uint256 usdcBalance = _tokenBalance(usdc, address(this));
        require(usdcBalance > 0, "Zero balance");
        _crossUSDC(
            destinationDomain,
            sendBlock,
            hook,
            usdc,
            amount
        );
    }

    function receiveUSDCAndL2Supply(
        IVineStruct.ReceiveUSDCAndL2SupplyParams calldata params
    ) external onlyManager {
        address crossCenter = _crossCenter();
        ICrossCenter(crossCenter).receiveUSDC(
            params.message,
            params.attestation
        );
        uint256 usdcBalance = _tokenBalance(params.usdc, address(this));
        require(usdcBalance > 0, "Zero balance");
        bytes1 depositeState = _l2Deposite(params.l2Pool, params.usdc, usdcBalance);
        require(depositeState == ONEBYTES1, "Supply fail");
    }

    function l2WithdrawAndCrossUSDC(
        IVineStruct.L2WithdrawAndCrossUSDCParams calldata params
    ) external {
        _checkOperator();
        bytes32 hook = _getValidHook(params.destinationDomain, params.indexDestHook);
        bytes1 l2withdrawState = _l2Withdraw(params.l2Pool, params.ausdc);
        require(l2withdrawState == ONEBYTES1, "Withdraw fail");
        uint256 usdcBalance = _tokenBalance(params.usdc, address(this));
        require(usdcBalance > 0, "Zero balance");
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
        address ausdc
    ) private returns (bytes1) {
        uint256 ausdcBalance = _tokenBalance(ausdc, address(this));
        address l2Encode = _getL2Encode();
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeWithdrawParams(
            ausdc,
            ausdcBalance
        );
        IERC20(ausdc).approve(l2Pool, ausdcBalance);
        uint256 usdcAmount = IL2Pool(l2Pool).withdraw(encodeMessage);
        emit L2withdraw(usdcAmount, ausdcBalance);
        return ONEBYTES1;
    }

    function _tokenBalance(
        address token,
        address user
    ) private view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = IERC20(token).balanceOf(user);
    }

    function _checkOwner() internal view {
        require(msg.sender == owner, "Non owner");
    }

    function _checkManager() internal view {
        require(msg.sender == manager, "Non manager");
    }

    function _crossCenter() private view returns(address crossCenter){
        crossCenter = IVineHookCenter(govern).getMarketInfo(id).crossCenter;
    }

    function _getL2Encode()private view returns(address _l2Encode){
        _l2Encode = IVineHookCenter(govern).getL2Encode();
    }

    function _getValidHook(uint32 destinationDomain, uint8 indexDestHook) private view returns(bytes32 validHook){
        validHook = IVineHookCenter(govern).getDestHook(id, destinationDomain, indexDestHook);
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
