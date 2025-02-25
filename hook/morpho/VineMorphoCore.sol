// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IMessageTransmitter} from "../../interfaces/cctp/IMessageTransmitter.sol";
import {ITokenMessenger} from "../../interfaces/cctp/ITokenMessenger.sol";
import {IVineStruct} from "../../interfaces/IVineStruct.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
import {IMorpho, MarketParams, Position, Market, Authorization, Id} from "../../interfaces/morpho/IMorpho.sol";
import {ICrossCenter} from "../../interfaces/ICrossCenter.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineMorphoCore is IVineHookErrors{
    using SafeERC20 for IERC20;

    address public owner;
    address public manager;
    bool public INITSTATE;
    ICrossCenter public crossCenter;

    mapping(uint32 => address) private destinationDomainToRecever;

    event MorphoSupply(address indexed sender, uint256 assetsSupplied, uint256 sharesSupplied);
    event MorphoWithdraw(address indexed sender, uint256 assetsWithdrawn, uint256 sharesWithdrawn);

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

    function initialize(
        address _manager,
        address _crossCenter,
        uint32[] calldata destinationDomains,
        address[] calldata validReceiveGroup
    ) external onlyOwner {
        if(INITSTATE != false){
            revert AlreadyInitialize(ErrorType.AlreadyInitialize);
        }
        manager = _manager;
        crossCenter = ICrossCenter(_crossCenter);
        for (uint256 i = 0; i < validReceiveGroup.length; i++) {
            destinationDomainToRecever[destinationDomains[i]]=validReceiveGroup[i];
        }
        INITSTATE = true;
    }

    //usdc approve 0x10ad974526D621667dBaE33E6Fc92Bf711f98054
    function supply(
        MarketParams memory marketParams,
        address morphoMarket,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        bytes memory data
    )external {
        IERC20(marketParams.collateralToken).safeTransferFrom(msg.sender, address(this), assets);
        IERC20(marketParams.collateralToken).approve(morphoMarket, assets);
        (uint256 assetsSupplied, uint256 sharesSupplied)=IMorpho(morphoMarket).supply(marketParams, assets, shares, onBehalf, data);
        emit MorphoSupply(msg.sender, assetsSupplied, sharesSupplied);
    }

    function withdraw(
        MarketParams memory marketParams,
        address morphoMarket,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        address receiver
    )external {
        (uint256 assetsWithdrawn,uint256 sharesWithdrawn)=IMorpho(morphoMarket).withdraw(marketParams, assets, shares, onBehalf, receiver);
        emit MorphoWithdraw(msg.sender, assetsWithdrawn, sharesWithdrawn);
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

    function getTokenBalance(
        address token,
        address user
    ) external view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = _tokenBalance(token, user);
    }

    function getPosition(address morphoMarket, Id id, address user)external view returns(Position memory){
        return IMorpho(morphoMarket).position(id, user);
    }

    
}