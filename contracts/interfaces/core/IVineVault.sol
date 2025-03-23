// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IVineVault {

    function changeDomain(uint32 _newDomain)external;

    function callVault(address token, uint256 amount)external payable returns(bool state);

    function delegateCallWay(
        uint8 tokenType, 
        address token, 
        address spender, 
        uint256 amount, 
        bytes memory data
    )external;
    
}