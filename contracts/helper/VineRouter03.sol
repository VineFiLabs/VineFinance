// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IGovernance} from "../interfaces/core/IGovernance.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineRouter03 is Ownable{   
    using SafeERC20 for IERC20;

    IGovernance public Governance;
    address public usdc;

    constructor(address _Governance, address _usdc)Ownable(msg.sender){
        Governance = IGovernance(_Governance);
        usdc = _usdc;
    }

    


}