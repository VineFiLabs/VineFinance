// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IVineStruct} from "./IVineStruct.sol";
import {IERC20} from "./IERC20.sol";

interface IVineAaveV3LendMain is IERC20{

    function lockState()external view returns(bytes1);

    function depositeTotalAmount()external view returns(uint64);

    function finallyAmount()external view returns(uint256);

    function deposite(
        uint64 amount,
        address usdc,
        address l2Pool,
        address receiver
    ) external;

    function withdraw(address usdc) external;

    function updateFinallyAmount(address usdc) external;

    function getUserSupply(address user) external view returns(IVineStruct.UserSupplyInfo memory);
}