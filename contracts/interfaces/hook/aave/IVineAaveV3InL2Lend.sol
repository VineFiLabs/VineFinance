// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ISharer} from "../../ISharer.sol";

interface IVineAaveV3InL2Lend is ISharer{

    function emergencyTime(uint256) external view returns(uint256);

    function transferManager(address newManager)external;

    function setReferralCode(uint16 _referralCode) external;

    function inL2Supply(
        uint256 id,
        address l2Pool,
        address usdc,
        uint256 amount
    ) external;

    function inL2Withdraw(
        uint256 id,
        address l2Pool,
        address ausdc,
        uint256 ausdcAmount
    ) external;

    function crossUSDC(
        uint256 id,
        uint8 indexDestHook,
        uint32 destinationDomain,
        uint64 inputBlock,
        address usdc,
        uint256 amount
    ) external;

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32,
        uint16,
        bytes32
    ) external payable;

    function getTokenBalance(
        address token,
        address user
    ) external view returns (uint256 _thisTokenBalance);
}