// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IVineRouter02 {

    function deposite(
        uint256 id,
        uint64 amount,
        address coreLendMarket,
        address l2Pool
    ) external;

    function getUserJoinGroup(address user, uint32 indexPage) external view returns(uint256[] memory newJoinGroup);

    function getUserLastPage(address user) external view returns(uint32 lastPage);

    function getUserIfJoin(address user, uint256 id) external view returns(bool ifJoin) ;
}