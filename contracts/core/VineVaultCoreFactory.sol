//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {VineVaultCore} from "./VineVaultCore.sol";

contract VineVaultCoreFactory {

    address public govern;

    constructor(address _govern){
        govern = _govern;
    }

    mapping(uint256 => address)public IdToVineVault;

    function createMarket(
        uint32 thisDomain,
        uint256 thisId,
        string memory tokenName, 
        string memory tokenSymbol
    ) external returns(address vineVaultCore){
        vineVaultCore = address(
            new VineVaultCore{
                salt: keccak256(abi.encodePacked(thisId, block.timestamp, block.chainid))
            }(thisDomain, govern, thisId, tokenName, tokenSymbol)
        );
        IdToVineVault[thisId] = vineVaultCore;
        require(vineVaultCore != address(0));
    }

}