// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "./VineSwapCore.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

contract VineSwapFactory is IFactorySharer {
    address public govern;

    constructor(address _govern) {
        govern = _govern;
    }

    mapping(address => bool) public ValidMarket;

    mapping(uint256 => address) internal UserIdToHook;

    event CreateSwapMarket(
        address indexed creator,
        uint256 indexed marketId,
        address market
    );

    function createSwapMarket(address owner, address manager) external {
        uint256 id = IVineHookCenter(govern).getCuratorToId(msg.sender);
        require(UserIdToHook[id] == address(0), "Already create");
        address swapMarket = address(
            new VineSwapCore{
                salt: keccak256(abi.encodePacked(id, msg.sender))
            }(owner, manager, govern, id)
        );
        ValidMarket[swapMarket] = true;
        UserIdToHook[id] = swapMarket;
        require(swapMarket != address(0), "Invalid address");
        emit CreateSwapMarket(msg.sender, id, swapMarket);
    }
}
