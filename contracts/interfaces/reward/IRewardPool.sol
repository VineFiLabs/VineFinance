// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IRewardPool {

    event Reward(address indexed receiver, address indexed token, uint256 amount);
    
    struct RewardTokensInfo{
        bool state;
        address[] tokens;
        uint256[] amounts;
    }
    
    function reward(
        uint256 id, 
        address user, 
        uint256 totalShareAmount
    ) external;

    function getRewardTokenAmount(
        uint256 id, 
        uint256 userShareAmount, 
        uint256 totalShareAmount
    ) external view returns(uint256[] memory rewardAmountGroup);

    function getIdToRewardTokensInfo(uint256 id) external view returns(RewardTokensInfo memory);
}