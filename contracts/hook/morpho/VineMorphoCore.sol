// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {IVineMorphoCore} from "../../interfaces/hook/morpho/IVineMorphoCore.sol";
import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
import {ICrossCenter} from "../../interfaces/core/ICrossCenter.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {VineLib} from "../../libraries/VineLib.sol";
import {IVineVault} from "../../interfaces/core/IVineVault.sol";
import {IVineConfig1} from "../../interfaces/core/IVineConfig1.sol";

import {IMorpho, MarketParams, Position, Market, Authorization, Id} from "../../interfaces/morpho/IMorpho.sol";
import {IMorphoReward} from "../../interfaces/morpho/IMorphoReward.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title VineMorphoCore
/// @author VineLabs member 0xlive(https://github.com/VineFiLabs)
/// @notice morpho module
contract VineMorphoCore is 
    IVineMorphoCore, 
    IVineEvent, 
    IVineHookErrors 
{
    using SafeERC20 for IERC20;

    bytes1 private immutable ONEBYTES1 = 0x01;
    uint64 public curatorId;
    address public factory;
    address public govern;
    address public owner;
    address public manager;
    constructor(address _govern, address _owner, address _manager, uint64 _curatorId) {
        factory = msg.sender;
        govern = _govern;
        owner = _owner;
        manager = _manager;
        curatorId = _curatorId;
    }

    mapping(uint256 => uint256)public emergencyTime;

    mapping(uint256 => MorphoInfo) public IdToMorphoInfo;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }
    function transferManager(address newManager) external onlyOwner {
        manager = newManager;
    }
    function supply(
        MarketParams memory marketParams,
        uint256 id,
        uint8 indexConfig,
        uint256 amount,
        uint256 shares
    ) external onlyManager{
        _checkValidId(id);
        address USDC = _getVineConfig(indexConfig, id).mainToken;
        address morphoMarket = _getVineConfig(indexConfig, id).callee;
        address vineVault = _getMarketInfo(id).vineVault;
        require(IVineVault(vineVault).callVault(USDC, amount), "Call vault fail");
        IERC20(marketParams.loanToken).approve(morphoMarket, amount);
        bytes memory data = hex"";
        (uint256 assetsSupplied, uint256 sharesSupplied) = IMorpho(morphoMarket)
            .supply(marketParams, amount, shares, address(this), data);
        IdToMorphoInfo[id].assetsSupplied += assetsSupplied;
        IdToMorphoInfo[id].sharesSupplied += sharesSupplied;
        emit MorphoSupply(msg.sender, assetsSupplied, sharesSupplied);
    }

    function withdraw(
        MarketParams memory marketParams,
        uint256 id,
        uint8 indexConfig,
        uint256 amount,
        uint256 shares
    ) external {
        _checkValidId(id);
        _checkOperator(id);
        address morphoMarket = _getVineConfig(indexConfig, id).callee;
        address vineVault = _getMarketInfo(id).vineVault;
        (uint256 amountWithdrawn, uint256 sharesWithdrawn) = IMorpho(
            morphoMarket
        ).withdraw(marketParams, amount, shares, address(this), vineVault);
        IdToMorphoInfo[id].amountWithdrawn += amountWithdrawn;
        IdToMorphoInfo[id].sharesWithdrawn += sharesWithdrawn;
        emit MorphoWithdraw(msg.sender, amountWithdrawn, sharesWithdrawn);
    }

    function claimMorphoReward(
        uint256 id,
        uint8 indexConfig,
        uint256 claimable,
        bytes32[] memory proof
    ) external {
        require(msg.sender == _officialManager());
        address caller = _getVineConfig(indexConfig, id).callee;
        address morphoRewardAddress = _getVineConfig(indexConfig, id).otherCaller;
        address rewardProxyReceiver = _getVineConfig(indexConfig, id).rewardProxyReceiver;
        IMorphoReward(caller).claim(rewardProxyReceiver, morphoRewardAddress, claimable, proof);
    }

    function crossUSDC(
        uint256 id,
        uint8 indexConfig,
        uint32 destinationDomain,
        uint64 inputBlock,
        uint256 amount
    ) external {
        _checkValidId(id);
        _checkOperator(id);
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        bytes32 destVault = _getValidVault(id, destinationDomain);
        address crossCenter = _getMarketInfo(id).crossCenter;
        address currentVault = _getMarketInfo(id).vineVault;
        require(_bytes32ToAddress(destVault) != currentVault, "Invalid destinationDomain");
        require(IVineVault(currentVault).callVault(usdc, amount), "call vault fail");
        IERC20(usdc).approve(crossCenter, amount);
        ICrossCenter(crossCenter).crossUSDC(
            destinationDomain,
            inputBlock,
            destVault,
            amount
        );
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32,
        uint16,
        bytes32
    ) external payable{
        require(msg.sender == _wormholeRelayer(), "Not relayer");
        (uint256 crossId, uint256 crossEmergencyTime) = abi.decode(payload, (uint256, uint256));
        _checkValidId(crossId);
        emergencyTime[crossId] = crossEmergencyTime;
        emit Emergency(crossId, crossEmergencyTime);
        if(block.timestamp < crossEmergencyTime){
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

    function getIdToMarketParams(
        Id morphoId,
        address morphoMarket
    )public view returns (MarketParams memory)
    {   
        return IMorpho(morphoMarket).idToMarketParams(morphoId);
    }

    function getPosition(
        Id morphoId,
        address user,
        address morphoMarket
    ) external view returns (Position memory) {
        return IMorpho(morphoMarket).position(morphoId, user);
    }

    function getMarket(
        Id morphoId,
        address morphoMarket
    )external view returns (Market memory market)
    {   
        market = IMorpho(morphoMarket).market(morphoId);
    }
}
