// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "../IERC20.sol";
interface IVineVaultCore is IERC20{

    function changeDomain(uint32 _newDomain)external;

    function callVault(address token, uint256 amount)external payable returns(bool state);

    function delegateCallWay(
        uint8 tokenType, 
        address token, 
        address spender, 
        uint256 amount, 
        bytes memory data
    )external;

    function depositeMint(address to, uint256 amount)external returns(bytes1);

    function withdrawBurn(address to, uint256 amount)external returns(bytes1);
    
}