// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IVineHookErrors {

    enum ErrorType{
        Lock,
        EndOfPledge,
        NonWithdrawTime,
        InsufficientBalance,
        ZeroBalance,
        ZeroAddress,
        InvalidAddress,
        AlreadyWithdraw,
        InvalidHook,
        AlreadyInitialize,
        SupplyFail,
        WithdrawFail,
        MintFail,
        BurnFail,
        NotEndTime,
        NonCrossTime,
        AlreadyEnd,
        CrossUSDCFail,
        ReceiveUSDCFail
    }
    error LockError(ErrorType);
    error EndOfPledgeError(ErrorType);
    error NonWithdrawTime(ErrorType);
    error InsufficientBalance(ErrorType);
    error ZeroBalance(ErrorType);
    error ZeroAddress(ErrorType);
    error InvalidAddress(ErrorType);
    error AlreadyWithdraw(ErrorType);
    error InvalidHook(ErrorType);
    error AlreadyInitialize(ErrorType);
    error SupplyFail(ErrorType);
    error WithdrawFail(ErrorType);
    error MintFail(ErrorType);
    error BurnFail(ErrorType);
    error NotEndTime(ErrorType);
    error NonCrossTime(ErrorType);
    error AlreadyEnd(ErrorType);
    error CrossUSDCFail(ErrorType);
    error ReceiveUSDCFail(ErrorType);

    error CallVaultFail(bytes1); //0x15

    
}