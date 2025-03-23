// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./VineAaveV3InL2Lend.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

contract VineInL2LendFactory is IFactorySharer {
    address public govern;

    constructor(address _govern) {
        govern = _govern;
    }

    mapping(address => bool) public ValidMarket;
    mapping(uint256 => address) internal UserIdToHook;

    event CreateL2AaveV3LendMarket(
        address indexed creator,
        uint256 indexed marketId,
        address market
    );

    function createMarket(address owner, address manager) external {
        address currentUser = msg.sender;
        uint256 id = IVineHookCenter(govern).getCuratorToId(currentUser);
        require(UserIdToHook[id] == address(0), "Already create");
        address l2LendMarket = address(
            new VineAaveV3InL2Lend{
                salt: keccak256(abi.encodePacked(id, currentUser))
            }(govern, owner, manager, id)
        );
        ValidMarket[l2LendMarket] = true;
        UserIdToHook[id] = l2LendMarket;
        require(l2LendMarket != address(0), "Invalid address");
        emit CreateL2AaveV3LendMarket(currentUser, id, l2LendMarket);
    }

    function getUserIdToHook(uint256 _id) external view returns (address) {
        return UserIdToHook[_id];
    }
}
