// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVineStruct{
    
    struct strategyInfo{
        bytes1 lockState;
        bytes1 protocolFeeState;
        uint64 depositeTotalAmount;
        uint64 finallyAmount;
    }

    struct UserSupplyInfo{
        uint64 supplyTime;
        uint64 pledgeAmount;
    }

    // struct L1WithdrawAndCrossUSDCParams{
    //     uint8 indexDestHook;
    //     uint32 destinationDomain;
    //     address usdcPool;
    //     uint64 inputBlock;
    //     address ausdc;
    //     address usdc;
    //     uint256 ausdcAmount;
    // }
    // struct ReceiveUSDCAndL1SupplyParams{
    //     bytes message;
    //     bytes attestation;
    //     address usdcPool;
    //     address usdc;
    // }

    // struct L2WithdrawAndCrossUSDCParams{
    //     uint8 indexDestHook;
    //     uint32 destinationDomain;
    //     address l2Pool;
    //     uint64 inputBlock;
    //     address ausdc;
    //     address usdc;
    //     uint256 ausdcAmount;
    // }
    // struct ReceiveUSDCAndL2SupplyParams{
    //     bytes message;
    //     bytes attestation;
    //     address usdc;
    //     address l2Pool;
    // }


}