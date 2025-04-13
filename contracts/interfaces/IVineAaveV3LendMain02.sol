// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IVineStruct} from "./IVineStruct.sol";
import {IERC20} from "./IERC20.sol";

interface IVineAaveV3LendMain02 is IERC20, IVineStruct{

    function id()external view returns(uint256);
    function factory()external view returns(address);
    function govern()external view returns(address);
    function owner()external view returns(address);
    function manager()external view returns(address);
    function lockState()external view returns(bytes1);
    function protocolFeeState()external view returns(bytes1);
    function finallyState()external view returns(bytes1);
    function depositeTotalAmount()external view returns(uint64);
    function finallyAmount()external view returns(uint256);

    function transferOwner(address newOwner) external;

    function transferManager(address newManager) external;

    function setReferralCode(uint16 _referralCode) external;

    function setLock(bytes1 state) external;

    //user deposite usdc
    function deposite(
        uint64 amount,
        address usdc,
        address usdcPool,
        address receiver
    ) external;

    function withdraw(address usdc) external;

    function withdrawFee(address usdc) external;

    function inL1Supply(
        address usdcPool,
        address usdc,
        uint256 amount
    ) external;

    function inL1Withdraw(
        address usdcPool,
        address ausdc,
        address usdc,
        uint256 amount
    ) external;

    function crossUSDC(
        uint8 indexDestHook,
        uint32 destinationDomain,
        uint64 inputBlock,
        address usdc,
        uint256 amount
    ) external;

    function receiveUSDC(
        bytes calldata message,
        bytes calldata attestation
    ) external;
    function receiveUSDCAndL1Supply(
        IVineStruct.ReceiveUSDCAndL1SupplyParams calldata params
    ) external;

    function l1WithdrawAndCrossUSDC(
        IVineStruct.L1WithdrawAndCrossUSDCParams calldata params
    ) external;

    function updateFinallyAmount(address usdc) external;


    function getUserSupply(address user)external view returns(UserSupplyInfo memory);
}