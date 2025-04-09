// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IGovernance} from "../interfaces/core/IGovernance.sol";
import {ISharer} from "../interfaces/ISharer.sol";
import {IRewardPool} from "../interfaces/reward/IRewardPool.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Governance
/// @author VineLabs member 0xlive(https://github.com/VineFiLabs)
/// @notice VineFinance Main Market core contract
/// @dev Used for official configuration and curator registration and initialization
contract RewardPool is Ownable, IRewardPool {
    using SafeERC20 for IERC20;

    address public govern;
    address public receiver;

    constructor(address _govern, address _receiver)Ownable(msg.sender){
        govern = _govern;
        receiver = _receiver; 
    }

    receive()external payable{}

    mapping(uint256 =>RewardTokensInfo) private idToRewardTokensInfo;

    function changeGovern(address newGovern) external onlyOwner {
        govern = newGovern;
    }

    function changeReceiver(address newReceiver) external onlyOwner {
        receiver = newReceiver;
    }

    function skim(address token) external onlyOwner {
        uint256 balance;
        if(token == address(0)){
            balance = address(this).balance;
            (bool success,) = receiver.call{value: balance}("");
            require(success);
        }else{
            balance = _tokenBalance(token, address(this));
            IERC20(token).safeTransfer(receiver, balance);
        }
    }

    function batchSetRewardToken(uint256 id, address[] calldata tokens, uint256[] calldata amounts, bool state) external onlyOwner {
        address[] memory newTokens = new address[](tokens.length);
        uint256[] memory newAmounts = new uint256[](amounts.length);
        unchecked{
            for(uint256 i; i<tokens.length; i++){
                newTokens[i] = tokens[i];
            }
        }
        unchecked{
            for(uint256 j; j<amounts.length; j++){
                newAmounts[j] = amounts[j];
            }
        }
        idToRewardTokensInfo[id] = RewardTokensInfo({
            state: state,
            tokens: newTokens,
            amounts: newAmounts
        });
    }

    function reward(
        uint256 id, 
        address user, 
        uint256 totalShareAmount
    ) external {
        _checkValidCaller(id);
        if(idToRewardTokensInfo[id].state){
            uint256 userShareBalance = _tokenBalance(_getMarketInfo(id).vineVault, user);
            unchecked {
                for(uint256 i; i<idToRewardTokensInfo[id].tokens.length; i++){
                    address token = idToRewardTokensInfo[id].tokens[i];
                    uint256 rewardAmount = _compute(idToRewardTokensInfo[id].amounts[i], userShareBalance, totalShareAmount);
                    uint256 currentBalance = _tokenBalance(token, address(this));
                    uint256 earnAmount = rewardAmount > currentBalance ? currentBalance : rewardAmount;
                    IERC20(token).safeTransfer(user, earnAmount);
                    emit Reward(user, token, earnAmount);
                }
            }
        }
    }

    function _compute(
        uint256 rewardAmount,
        uint256 userShareAmount, 
        uint256 totalShareAmount
    ) private pure returns(uint256 _amount){
        _amount = rewardAmount * userShareAmount / totalShareAmount;
    }
    
    function _checkValidCaller(uint256 id)private view{
        require(ISharer(msg.sender).govern() == govern);
        require(msg.sender == _getMarketInfo(id).coreLendMarket, "Invalid hook");
    }

    function _getMarketInfo(uint256 id) private view returns(IGovernance.MarketInfo memory _marketInfo){
        _marketInfo = IGovernance(govern).getMarketInfo(id);
    }

    function _tokenBalance(
        address token,
        address user
    ) private view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = IERC20(token).balanceOf(user);
    }

    function getRewardTokenAmount(
        uint256 id, 
        uint256 userShareAmount, 
        uint256 totalShareAmount
    ) external view returns(uint256[] memory rewardAmountGroup){
        rewardAmountGroup = new uint256[](idToRewardTokensInfo[id].tokens.length);
        unchecked {
            for(uint256 i; i<idToRewardTokensInfo[id].tokens.length; i++){
                rewardAmountGroup[i] =  _compute(idToRewardTokensInfo[id].amounts[i], userShareAmount, totalShareAmount);
            }
        }
    }

    function getIdToRewardTokensInfo(uint256 id) external view returns(RewardTokensInfo memory){
        return idToRewardTokensInfo[id];
    }

}
    