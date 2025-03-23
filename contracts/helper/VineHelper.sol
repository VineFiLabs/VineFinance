// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {IGovernance} from "../interfaces/core/IGovernance.sol";
import {IVineAaveV3LendMain02} from "../interfaces/hook/aave/IVineAaveV3LendMain02.sol";
import {IVineVaultCore} from "../interfaces/core/IVineVaultCore.sol";
import {IVineRouter02} from "../interfaces/helper/IVineRouter02.sol";
import "../libraries/VineLib.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title VineHelper
/// @author Vinelabs(https://github.com/VineFiLabs)
/// @notice Aggregate read method
/// @dev Used to quickly request and respond to multiple data
contract VineHelper is Ownable{
    using SafeERC20 for IERC20;

    bytes1 private immutable ZEROBYTES1;
    address public govern;
    address public vineRouter;

    constructor(address _govern, address _vineRouter)Ownable(msg.sender){
        govern = _govern;
        vineRouter = _vineRouter;
    }

    enum MarketState {
        InPledge,
        Cooking,
        PendingWithdraw,
        Emergency,
        Withdraw,
        Blacklist
    }

    function changeConfig(address _newGovern, address _newVineRouter) external onlyOwner{
        govern = _newGovern;
        vineRouter = _newVineRouter;
    }

    function _getMarketInfo(
        uint256 _id
    ) private view returns (IGovernance.MarketInfo memory newMarketInfo) {
        newMarketInfo = IGovernance(govern).getMarketInfo(_id);
    }
    function _getMarketState(
        uint256 id,
        IGovernance.MarketInfo memory marketInfo,
        address coreLengMarket
    ) private view returns (MarketState state) {
        uint64 bufferTime = marketInfo.bufferTime;
        uint64 endTime = marketInfo.endTime;
        bytes32 hook = addressToBytes32(coreLengMarket);
        bytes1 blacklist = IGovernance(govern).Blacklist(hook);
        if (blacklist == ZEROBYTES1) {
            if (block.timestamp <= bufferTime) {
                state = MarketState.InPledge;
            } else if (
                block.timestamp > bufferTime && block.timestamp < endTime
            ) {
                state = MarketState.Cooking;
            } else if (
                block.timestamp >= endTime && block.timestamp < 4 hours
            ) {
                state = MarketState.PendingWithdraw;
            } else {
                uint256 finallyAmount = IVineAaveV3LendMain02(coreLengMarket).getStrategyInfo(id).finallyAmount;
                if (finallyAmount == 0) {
                    state = MarketState.Emergency;
                } else {
                    state = MarketState.Withdraw;
                }
            }
        } else {
            state = MarketState.Blacklist;
        }
    }

    function _getUserSupplyToHookAmount(
        uint256 _id,
        address _coreLendMarket,
        address _user
    ) private view returns (uint64 supplyAmount) {
        supplyAmount = IVineAaveV3LendMain02(_coreLendMarket).getUserSupply(_user, _id).pledgeAmount;
    }

    function _getUserFinallyAmount(
        uint16 _curatorFee,
        uint16 _protocolFee,
        address _coreLendMarket,
        address _vineVault,
        address _user,
        uint256 _id
    ) private view returns (uint256 userFinallyAmount) {
        userFinallyAmount = VineLib._getUserFinallyAmount(
            _curatorFee,
            _protocolFee,
            _getUserSupplyToHookAmount(_id, _coreLendMarket, _user),
            getStrategyInfo(_id, _coreLendMarket).depositeTotalAmount,
            getUserTokenBalance(_vineVault, _user),
            getStrategyInfo(_id, _coreLendMarket).finallyAmount,
            _getMarketTotalSupply(_vineVault)
        );
    }

    function _getMarketTotalSupply(
        address _vineVault
    ) private view returns (uint256 totalSupply) {
        totalSupply = IVineVaultCore(_vineVault).totalSupply();
    }

    function getStrategyInfo(uint256 _id, address _coreLendMarket) public view returns(IVineAaveV3LendMain02.strategyInfo memory newStrategyInfo){
        newStrategyInfo = IVineAaveV3LendMain02(_coreLendMarket).getStrategyInfo(_id);
    }

    function getUserTokenBalance(
        address token,
        address account
    ) public view returns (uint256 accountTokenBalance) {
        accountTokenBalance = IERC20(token).balanceOf(account);
    }

    function getUserSupplyToHookAmount(
        uint256 id,
        address user
    ) external view returns (uint64 supplyAmount) {
        supplyAmount = _getUserSupplyToHookAmount(
            id,
            _getMarketInfo(id).coreLendMarket,
            user
        );
    }

    function getMarketTotalSupply(
        address vineVault
    ) external view returns (uint256 totalSupply) {
        totalSupply = _getMarketTotalSupply(
            vineVault
        );
    }

    function addressToBytes32(address _account) public view returns (bytes32) {
        return bytes32(uint256(uint160(_account)));
    }

    function bytes32ToAddress(
        bytes32 _bytes32Account
    ) public view returns (address) {
        return address(uint160(uint256(_bytes32Account)));
    }

    function getUserFinallyAmount(
        uint256 id,
        address user
    ) external view returns (uint256 userFinallyAmount) {
        IGovernance.MarketInfo memory newMarketInfo = _getMarketInfo(
            id
        );
        userFinallyAmount = _getUserFinallyAmount(
            newMarketInfo.curatorFee,
            newMarketInfo.protocolFee,
            newMarketInfo.coreLendMarket,
            newMarketInfo.vineVault,
            user,
            id
        );
    }

    function getFeeData(
        uint256 id
    ) external view returns (uint256, uint256, uint256) {
        IGovernance.MarketInfo memory newMarketInfo = _getMarketInfo(
            id
        );
        address coreLendMarket = newMarketInfo.coreLendMarket;
        uint64 depositeTotalAmount = getStrategyInfo(id, coreLendMarket).depositeTotalAmount;
        uint64 finallyAmount = getStrategyInfo(id, coreLendMarket).finallyAmount;
        uint256 curatorFee = VineLib._curatorFeeAmount(
            newMarketInfo.curatorFee,
            depositeTotalAmount,
            finallyAmount
        );
        uint256 protocolFee = VineLib._protocolFeeAmount(
            newMarketInfo.protocolFee,
            depositeTotalAmount,
            finallyAmount
        );
        uint256 totalFee = curatorFee + protocolFee;
        return (curatorFee, protocolFee, totalFee);
    }

    ///@dev Get market list information
    ///@notice Maximum 10 data per page
    function getMarketInfoList(
        uint256 pageIndex
    )
        external
        view
        returns (
            IGovernance.MarketInfo[] memory marketInfoList,
            MarketState[] memory stateList,
            uint64[] memory depositeAmountList,
            uint256[] memory totalSupplyList
        )
    {
        uint256 lastId = IGovernance(govern).ID();
        uint256 currentId;
        uint256 len;
        if (lastId == 0) {
            len = 0;
        } else if (lastId > 0 && lastId <= 10) {
            len = lastId;
        } else {
            len = lastId % 10;
            currentId = pageIndex * 10;
        }
        marketInfoList = new IGovernance.MarketInfo[](len);
        stateList = new MarketState[](len);
        depositeAmountList = new uint64[](len);
        totalSupplyList = new uint256[](len);
        unchecked {
            for (uint256 i; i < len; i++) {
                marketInfoList[i] = _getMarketInfo(currentId);
                address newCoreLendMarket = marketInfoList[i].coreLendMarket;
                if (newCoreLendMarket == address(0)) {
                    stateList[i] = MarketState.Blacklist;
                    depositeAmountList[i] = 0;
                    totalSupplyList[i] = 0;
                } else {
                    stateList[i] = _getMarketState(
                        currentId,
                        marketInfoList[i],
                        newCoreLendMarket
                    );
                    depositeAmountList[i] = getStrategyInfo(
                        currentId,
                        newCoreLendMarket
                    ).depositeTotalAmount;
                    totalSupplyList[i] = _getMarketTotalSupply(
                        marketInfoList[i].vineVault
                    );
                }
                currentId++;
            }
        }
    }

    function getUserMarketInfoList(
        address user,
        uint32 pageIndex
    )
        external
        view
        returns (
            IGovernance.MarketInfo[] memory marketInfoList,
            MarketState[] memory stateList,
            IVineAaveV3LendMain02.strategyInfo[] memory strategyInfoList,
            uint64[] memory userSupplyAmountList,
            uint256[] memory userFinallyAmountList
        )
    {
        uint256 len = IVineRouter02(vineRouter)
            .getUserJoinGroup(user, pageIndex)
            .length;
        uint256[] memory newMarketIdList = new uint256[](len);
        marketInfoList = new IGovernance.MarketInfo[](len);
        stateList = new MarketState[](len);
        strategyInfoList = new IVineAaveV3LendMain02.strategyInfo[](len);
        userSupplyAmountList = new uint64[](len);
        userFinallyAmountList = new uint256[](len);
        for (uint256 i; i < len; i++) {
            newMarketIdList[i] = IVineRouter02(vineRouter)
                .getUserJoinGroup(user, pageIndex)[i];
            marketInfoList[i] = _getMarketInfo(newMarketIdList[i]);
            if (marketInfoList[i].coreLendMarket == address(0)) {
                stateList[i] = MarketState.Blacklist;
                userSupplyAmountList[i] = 0;
                userFinallyAmountList[i] = 0;
            } else {
                stateList[i] = _getMarketState(
                    newMarketIdList[i],
                    marketInfoList[i],
                    marketInfoList[i].coreLendMarket
                );
                strategyInfoList[i] = getStrategyInfo(
                    newMarketIdList[i],
                    marketInfoList[i].coreLendMarket
                );
                userSupplyAmountList[i] = _getUserSupplyToHookAmount(
                    newMarketIdList[i],
                    marketInfoList[i].coreLendMarket,
                    user
                );
                userFinallyAmountList[i] = _getUserFinallyAmount(
                    marketInfoList[i].curatorFee,
                    marketInfoList[i].protocolFee,
                    marketInfoList[i].coreLendMarket,
                    marketInfoList[i].vineVault,
                    user,
                    newMarketIdList[i]
                );
            }
        }
    }
}
