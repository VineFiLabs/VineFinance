// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IMessageTransmitter} from "../../interfaces/cctp/IMessageTransmitter.sol";
import {ITokenMessenger} from "../../interfaces/cctp/ITokenMessenger.sol";
import {IVineStruct} from "../../interfaces/IVineStruct.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {IVineMorphoCore} from "../../interfaces/hooks/IVineMorphoCore.sol";
import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
import {ICrossCenter} from "../../interfaces/ICrossCenter.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {VineLib} from "../../libraries/VineLib.sol";
import {IVineMorphoFactory} from "../../interfaces/hooks/IVineMorphoFactory.sol";

import {IMorpho, MarketParams, Position, Market, Authorization, Id} from "../../interfaces/morpho/IMorpho.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineMorphoCore is 
    IVineMorphoCore, 
    IVineStruct, 
    IVineEvent, 
    IVineHookErrors 
{
    using SafeERC20 for IERC20;

    uint256 public id;
    bytes1 private immutable ONEBYTES1 = 0x01;
    uint32 public currentDomain;
    address public factory;
    address public govern;
    address public owner;
    address public manager;
    uint256 public emergencyTime;

    struct MorphoInfo{
        uint256 assetsSupplied; 
        uint256 sharesSupplied;
        uint256 amountWithdrawn;
        uint256 sharesWithdrawn;
    }
    mapping(uint256 => MorphoInfo) public IdToMorphoInfo;

    constructor(address _govern, address _owner, address _manager, uint256 _id) {
        factory = msg.sender;
        govern = _govern;
        owner = _owner;
        manager = _manager;
        id = _id;
        currentDomain = VineLib._currentDomain();
    }

    mapping(uint32 => address) private destinationDomainToRecever;

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

    function changeDomain(uint32 newDomain) external onlyManager{
        currentDomain = newDomain;
    }
    function supply(
        MarketParams memory marketParams,
        uint8 indexMorphoMarket,
        uint256 amount,
        uint256 shares
    ) external onlyManager{
        address morphoMarket = _indexMorphoMarket(indexMorphoMarket);
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
        uint8 indexMorphoMarket,
        uint256 amount,
        uint256 shares
    ) external {
        _checkOperator();
        address morphoMarket = _indexMorphoMarket(indexMorphoMarket);
        (uint256 amountWithdrawn, uint256 sharesWithdrawn) = IMorpho(
            morphoMarket
        ).withdraw(marketParams, amount, shares, address(this), address(this));
        IdToMorphoInfo[id].amountWithdrawn += amountWithdrawn;
        IdToMorphoInfo[id].sharesWithdrawn += sharesWithdrawn;
        emit MorphoWithdraw(msg.sender, amountWithdrawn, sharesWithdrawn);
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
        uint256 balance = _tokenBalance(usdc, address(this));
        if (balance == 0) {
            revert ZeroBalance(ErrorType.ZeroBalance);
        }
        if (destinationDomain == currentDomain) {
            address destCurrentChainHook = _bytes32ToAddress(hook);
            IERC20(usdc).approve(destCurrentChainHook, amount);
            IERC20(usdc).transfer(destCurrentChainHook, amount);
        } else {
            address crossCenter = _crossCenter();
            IERC20(usdc).approve(crossCenter, amount);
            ICrossCenter(crossCenter).crossUSDC(
                destinationDomain,
                sendBlock,
                hook,
                usdc,
                amount
            );
        }
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

    function _tokenBalance(
        address token,
        address user
    ) private view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = IERC20(token).balanceOf(user);
    }

    function _indexMorphoMarket(uint8 index)private view returns(address){
        address morphoMarket= IVineMorphoFactory(factory).IndexMorphoMarket(index);
        require(morphoMarket!=address(0), "Invalid morpho market");
        return morphoMarket;
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

    function getIdToMarketParams(
        uint8 indexMorphoMarket,
        Id morphoId
    )public view returns (MarketParams memory)
    {   
        address morphoMarket = _indexMorphoMarket(indexMorphoMarket);
        return IMorpho(morphoMarket).idToMarketParams(morphoId);
    }

    function getPosition(
        uint8 indexMorphoMarket,
        Id morphoId,
        address user
    ) external view returns (Position memory) {
        address morphoMarket = _indexMorphoMarket(indexMorphoMarket);
        return IMorpho(morphoMarket).position(morphoId, user);
    }

    function getMarket(
        uint8 indexMorphoMarket,
        Id morphoId
    )external view returns (Market memory market)
    {   
        address morphoMarket = _indexMorphoMarket(indexMorphoMarket);
        market = IMorpho(morphoMarket).market(morphoId);
    }
}
