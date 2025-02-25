// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVineErrors {
    enum ErrorType{
        InsufficientBalance,
        ZeroBalance,
        ZeroAddress,
        InvalidAddress,
        InvalidHook,
        AlreadyInitialize,
        SupplyFail,
        WithdrawFail,
        MintFail,
        BurnFail,
        NotEndTime,
        AlreadyEnd,
        CrossUSDCFail,
        ReceiveUSDCFail
    }

    error InsufficientBalance(ErrorType);
    error ZeroBalance(ErrorType);
    error ZeroAddress(ErrorType);
    error InvalidAddress(ErrorType);
    error InvalidHook(ErrorType);
    error AlreadyInitialize(ErrorType);
    error SupplyFail(ErrorType);
    error WithdrawFail(ErrorType);
    error MintFail(ErrorType);
    error BurnFail(ErrorType);
    error NotEndTime(ErrorType);
    error AlreadyEnd(ErrorType);
    error CrossUSDCFail(ErrorType);
    error ReceiveUSDCFail(ErrorType);

    
}