// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVineVault {

    function changeDomain(uint32 _newDomain)external;

    function callVault(address token, uint256 amount)external payable;

    function callWay(
        uint8 tokenType, 
        address token, 
        address caller, 
        uint256 amount, 
        bytes memory data
    )external returns(bool success, bytes memory resultData);
    
}