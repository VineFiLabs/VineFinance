//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {VineVault} from "./VineVault.sol";

contract VineVaultFactory {

    address public govern;

    constructor(address _govern){
        govern = _govern;
    }

    mapping(uint256 => address)public IdToVineVault;

    function createMarket(
        uint32 thisDomain,
        uint256 thisId
    ) external returns(address vineVault){
        vineVault = address(
            new VineVault{
                salt: keccak256(abi.encodePacked(thisId, block.timestamp, block.chainid))
            }(thisDomain, govern, thisId)
        );
        IdToVineVault[thisId] = vineVault;
        require(vineVault != address(0));
    }

}