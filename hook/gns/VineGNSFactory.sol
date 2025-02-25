// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "./VineGNSCore.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

contract VineGNSFactory is IFactorySharer {
    address public govern;

    constructor(address _govern) {
        govern = _govern;
    }

    mapping(address => bool) public ValidMarket;

    mapping(uint256 => address) internal UserIdToHook;

    function createGNSMarket(address owner, address manager) external {
        uint256 id = IVineHookCenter(govern).getCuratorToId(msg.sender);
        require(UserIdToHook[id] == address(0), "Already create");
        address gnsMarket = address(
            new VineGNSCore{
                salt: keccak256(abi.encodePacked(id, msg.sender))
            }(owner, manager, govern)
        );
        ValidMarket[gnsMarket] = true;
        UserIdToHook[id] = gnsMarket;
        require(gnsMarket != address(0), "Invalid address");
    }
}
