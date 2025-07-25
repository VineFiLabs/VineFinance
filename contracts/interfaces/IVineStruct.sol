// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVineStruct{

    struct CrossUSDCParams{
        bool sameChain;
        uint8 indexConfig;
        uint32 destinationDomain;
        uint64 inputBlock;
        uint256 id;
        uint256 amount;
    }
    
    struct StrategyInfo{
        bytes1 lockState;
        bytes1 protocolFeeState;
        uint64 depositeTotalAmount;
        uint64 finallyAmount;
        uint64 extractedAmount;
    }

    struct UserSupplyInfo{
        uint64 supplyTime;
        uint64 pledgeAmount;
    }

}