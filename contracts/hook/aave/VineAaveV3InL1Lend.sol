// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IPool} from "../../interfaces/aaveV3/IPool.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
import {IVineStruct} from "../../interfaces/IVineStruct.sol";
import {ICrossCenter} from "../../interfaces/core/ICrossCenter.sol";
import {ISharer} from "../../interfaces/ISharer.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {VineLib} from "../../libraries/VineLib.sol";
import {IVineVault} from "../../interfaces/core/IVineVault.sol";
import {IVineConfig1} from "../../interfaces/core/IVineConfig1.sol";

import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title VineAaveV3InL1Lend
/// @author VineLabs member 0xlive(https://github.com/VineFiLabs)
/// @notice AaveV3 is a module in layer1
contract VineAaveV3InL1Lend is
    IVineEvent,
    IVineStruct,
    IVineHookErrors,
    ISharer,
    IWormholeReceiver
{
    using SafeERC20 for IERC20;

    uint16 private referralCode;
    uint64 public curatorId;
    address public immutable factory;
    address public immutable govern;
    address public immutable owner;
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
        uint8 indexConfig,
        uint256 amount
    ) external onlyManager {
        _checkValidId(id);
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address usdcPool = _getVineConfig(indexConfig, id).callee;
        address vineVault = _getMarketInfo(id).vineVault;
        emit AaveV3Supply(id, amount);
        require(_aaveSupply(vineVault, usdcPool, usdc, amount), "Supply fail");
    }

    function inL1Withdraw(
        uint256 id,
        uint8 indexConfig,
        uint256 ausdcAmount
    ) external {
        _checkValidId(id);
        _checkOperator(id);
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address ausdc = _getVineConfig(indexConfig, id).derivedToken;
        address usdcPool = _getVineConfig(indexConfig, id).callee;
        address vineVault = _getMarketInfo(id).vineVault;
        emit AaveV3Withdraw(id, ausdcAmount);
        require(_aaveWithdraw( vineVault, usdcPool, ausdc, usdc, ausdcAmount), "Withdraw fail");
    }

    function crossUSDC(
        CrossUSDCParams calldata params
    ) external {
        _checkValidId(params.id);
        _checkOperator(params.id);
        address usdc = _getVineConfig(params.indexConfig, params.id).mainToken;
        bytes32 bytes32DestVault = _getValidVault(params.id, params.destinationDomain);
        address destVault = _bytes32ToAddress(bytes32DestVault);
        address crossCenter = _getMarketInfo(params.id).crossCenter;
        address currentVault = _getMarketInfo(params.id).vineVault;
        require(destVault != currentVault && destVault != address(0), "Invalid destinationDomain");
        IVineVault(currentVault).callVault(usdc, params.amount);
        if(params.sameChain){
            IERC20(usdc).safeTransfer(destVault, params.amount);
        }else {
            IERC20(usdc).approve(crossCenter, params.amount);
            ICrossCenter(crossCenter).crossUSDC(
                params.destinationDomain,
                params.inputBlock,
                bytes32DestVault,
                params.amount
            );
        }
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32,
        uint16,
        bytes32
    ) external payable {
        require(msg.sender == _wormholeRelayer(), "Not relayer");
        (uint256 crossId, uint256 crossEmergencyTime) = abi.decode(payload, (uint256, uint256));
        _checkValidId(crossId);
        emergencyTime[crossId] = crossEmergencyTime;
        emit Emergency(crossId, crossEmergencyTime);
        if(block.timestamp <= crossEmergencyTime){
            revert("Not emergency time");
        }
    } 

    function skimToVault(
        address token, 
        uint256 id, 
        uint256 amount
    ) external {
        require(msg.sender == _officialManager());
        address vineVault = _getMarketInfo(id).vineVault;
        if(amount >0 ){
            IERC20(token).safeTransfer(vineVault, amount);
        }
    }

    function _aaveSupply(
        address vineVault,
        address usdcPool,
        address usdc,
        uint256 amount
    ) private returns (bool state) {
        bytes memory payload = abi.encodeCall(
            IPool(usdcPool).supply,
            (usdc, amount, vineVault, referralCode)
        );
        (state, ) = IVineVault(vineVault).callWay(
            2,
            usdc,
            usdcPool,
            amount,
            payload
        );
    }

    function _aaveWithdraw(
        address vineVault,
        address usdcPool,
        address ausdc,
        address usdc,
        uint256 amount
    ) private returns (bool state) {
        bytes memory payload = abi.encodeCall(
            IPool(usdcPool).withdraw,
            (usdc, amount, vineVault)
        );
        (state, ) = IVineVault(vineVault).callWay(
            2,
            ausdc,
            usdcPool,
            amount,
            payload
        );
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

    function _officialManager() private view returns(address _offManager){
        _offManager = IVineHookCenter(govern).manager();
    }

    function _getMarketInfo(uint256 id) private view returns(IVineHookCenter.MarketInfo memory _marketInfo){
        _marketInfo = IVineHookCenter(govern).getMarketInfo(id);
    }

    function _getVineConfig(uint8 indexConfig, uint256 id) private view returns (IVineConfig1.calleeInfo memory _calleeInfo){
        _calleeInfo = IVineConfig1(_getMarketInfo(id).vineConfigAddress).getCalleeInfo(indexConfig);
    }
    
    function _getValidVault(uint256 id, uint32 destinationDomain) private view returns(bytes32 validVault){
        validVault = IVineHookCenter(govern).getDestVault(id, destinationDomain);
    }

    function _checkOperator(uint256 id) private view {
        require(msg.sender == manager || (block.timestamp > emergencyTime[id] && emergencyTime[id] > 0), "Non manager or not emergency time");
    } 
    function _checkValidId(uint256 id) private view {
        require(curatorId == _getMarketInfo(id).userId, "Not this curator");
    }

    function _wormholeRelayer() private view returns(address){
        return IVineHookCenter(govern).wormholeRelayer();
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
