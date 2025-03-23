// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IVineStruct} from "../../IVineStruct.sol";
import {ISharer} from "../../ISharer.sol";

interface IVineAaveV3LendMain02 is ISharer, IVineStruct{

    function transferManager(address newManager) external;

    function setReferralCode(uint16 _referralCode) external;

    function setLock(bytes1 state) external;

    //user deposite usdc
    function deposite(
        uint256 id,
        uint64 amount,
        address usdc,
        address usdcPool,
        address receiver
    ) external;

    function withdraw(uint256 id, address usdc) external;

    function withdrawFee(uint256 id, address usdc) external;

    function inL1Supply(
        uint256 id,
        address usdcPool,
        address usdc,
        uint256 amount
    ) external;

    function inL1Withdraw(
        uint256 id,
        address usdcPool,
        address ausdc,
        address usdc,
        uint256 amount
    ) external;

    function crossUSDC(
        uint256 id,
        uint8 indexDestHook,
        uint32 destinationDomain,
        uint64 inputBlock,
        address usdc,
        uint256 amount
    ) external;

    function receiveUSDC(
        uint256 id,
        bytes calldata message,
        bytes calldata attestation
    ) external;

    function updateFinallyAmount(uint256 id, address usdc) external;

    function getUserSupply(address user, uint256 id)external view returns(UserSupplyInfo memory);

    function getStrategyInfo(uint256 id)external view returns(strategyInfo memory);

    function getCuratorWithdrawState(address user, uint256 id) external view returns(bool);
}