// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {IPool} from "../../interfaces/aaveV3/IPool.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
import {ICrossCenter} from "../../interfaces/core/ICrossCenter.sol";
import {ISharer} from "../../interfaces/ISharer.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {VineLib} from "../../libraries/VineLib.sol";
import {IVineVault} from "../../interfaces/core/IVineVault.sol";

import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineAaveV3InL1Lend is
    IVineEvent,
    IVineHookErrors,
    ISharer,
    IWormholeReceiver
{
    using SafeERC20 for IERC20;

    bytes1 private immutable ONEBYTES1 = 0x01;
    uint16 private referralCode;
    uint64 public curatorId;
    address public factory;
    address public govern;
    address public owner;
    address public manager;

    constructor(
        address _govern, 
        address _owner, 
        address _manager, 
        uint64 _curatorId
    ) {
        factory = msg.sender;
        govern = _govern;
        owner = _owner;
        manager = _manager;
        curatorId = _curatorId;
    }

    mapping(uint256 => uint256)public emergencyTime;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }

    function transferManager(address newManager)external onlyOwner {
        manager = newManager;
    }

    function setReferralCode(uint16 _referralCode) external onlyManager {
        referralCode = _referralCode;
    }

    function inL1Supply(
        uint256 id,
        address usdcPool,
        address usdc,
        uint256 amount
    ) external onlyManager {
        _checkValidId(id);
        address vineVault = _getMarketInfo(id).vineVault;
        bytes1 state = _aaveSupply(vineVault, usdcPool, usdc, amount);
        emit AaveV3Supply(id, amount);
        require(state == ONEBYTES1, "Supply fail");
    }

    function inL1Withdraw(
        uint256 id,
        address usdcPool,
        address ausdc,
        uint256 ausdcAmount
    ) external {
        _checkValidId(id);
        _checkOperator(id);
        address vineVault = _getMarketInfo(id).vineVault;
        bytes1 aaveWithdrawState = _aaveWithdraw( vineVault, usdcPool, ausdc, ausdcAmount);
        emit AaveV3Withdraw(id, ausdcAmount);
        require(aaveWithdrawState == ONEBYTES1, "Withdraw fail");
    }

    function crossUSDC(
        uint256 id,
        uint8 indexDestHook,
        uint32 destinationDomain,
        uint64 inputBlock,
        address usdc,
        uint256 amount
    ) external {
        _checkValidId(id);
        _checkOperator(id);
        bytes32 hook = _getValidHook(id, destinationDomain, indexDestHook);
        address crossCenter = _getMarketInfo(id).crossCenter;
        address vineVault = _getMarketInfo(id).vineVault;
        require(_crossUsdc(
            id,
            destinationDomain,
            inputBlock,
            hook,
            usdc,
            vineVault,
            crossCenter,
            amount
        )==ONEBYTES1);
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32,
        uint16,
        bytes32
    ) external payable {
        (uint256 crossId, uint256 crossEmergencyTime) = abi.decode(payload, (uint256, uint256));
        _checkValidId(crossId);
        emergencyTime[crossId] = crossEmergencyTime;
        if(block.timestamp <= crossEmergencyTime){
            revert("Not emergency time");
        }
    } 

    function _crossUsdc(
        uint256 id,
        uint32 destinationDomain, 
        uint64 inputBlock, 
        bytes32 hook, 
        address usdc, 
        address vineVault,
        address crossCenter,
        uint256 amount
    ) private returns(bytes1 state) {
        bool callVaultState = IVineVault(vineVault).callVault(usdc, amount);
        uint32 currentDomain = _getMarketInfo(id).domain;
        require(callVaultState, "call vault fail");
        if(destinationDomain == currentDomain){
            address destCurrentChainHook = _bytes32ToAddress(hook);
            IERC20(usdc).approve(destCurrentChainHook, amount);
            IERC20(usdc).safeTransfer(destCurrentChainHook, amount);
        }else{
            IERC20(usdc).approve(crossCenter, amount);
            ICrossCenter(crossCenter).crossUSDC(
                destinationDomain,
                inputBlock,
                hook,
                amount
            );
        }
        state = ONEBYTES1;
    }

    function _aaveSupply(
        address vineVault,
        address usdcPool,
        address usdc,
        uint256 amount
    ) private returns (bytes1 state) {
        bytes memory payload = abi.encodeCall(
            IPool(usdcPool).supply,
            (usdc, amount, address(this), referralCode)
        );
        IVineVault(vineVault).delegateCallWay(
            2,
            usdc,
            usdcPool,
            amount,
            payload
        );
        state = ONEBYTES1;
    }

    function _aaveWithdraw(
        address vineVault,
        address usdcPool,
        address ausdc,
        uint256 amount
    ) private returns (bytes1 state) {
        bytes memory payload = abi.encodeCall(
            IPool(usdcPool).withdraw,
            (ausdc, amount, vineVault)
        );
        IVineVault(vineVault).delegateCallWay(
            2,
            ausdc,
            usdcPool,
            amount,
            payload
        );
        state = ONEBYTES1;
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

    function _getMarketInfo(uint256 id) private view returns(IVineHookCenter.MarketInfo memory _marketInfo){
        _marketInfo = IVineHookCenter(govern).getMarketInfo(id);
    }
    
    function _getValidHook(uint256 id, uint32 destinationDomain, uint8 indexDestHook) private view returns(bytes32 validHook) {
        validHook = IVineHookCenter(govern).getDestHook(id, destinationDomain, indexDestHook);
    }

    function _checkOperator(uint256 id) private view {
        require(msg.sender == manager || (block.timestamp > emergencyTime[id] && emergencyTime[id] > 0), "Non manager or not emergency time");
    } 
    function _checkValidId(uint256 id) private view {
        require(curatorId == _getMarketInfo(id).userId, "Not this curator");
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
