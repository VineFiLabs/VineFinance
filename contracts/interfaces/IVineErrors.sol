// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVineErrors {
    
    error CallVaultFail(bytes1);  //0x15
    error UpdateFail(bytes1);  //0x16
    error SupplyFail(bytes1);  //0x17
    error AlreadyWithdraw(bytes1);  //0x18

}