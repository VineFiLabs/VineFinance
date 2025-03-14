// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "./VineAaveV3InETHLend.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

contract VineInETHLendFactory is IFactorySharer {
    address public govern;

    constructor(address _govern) {
        govern = _govern;
    }

    mapping(address => bool) public ValidMarket;

    mapping(uint256 => address) internal UserIdToHook;

    event CreateETHAaveV3LendMarket(
        address indexed creator,
        uint256 indexed marketId,
        address market
    );

    function createMarket(address owner, address manager) external {
        address currentUser = msg.sender;
        uint256 id = IVineHookCenter(govern).getCuratorToId(currentUser);
        require(UserIdToHook[id] == address(0), "Already create");
        address ethLendMarket = address(
            new VineAaveV3InETHLend{
                salt: keccak256(abi.encodePacked(id, currentUser))
            }(govern, owner, manager, id)
        );
        ValidMarket[ethLendMarket] = true;
        UserIdToHook[id] = ethLendMarket;
        require(ethLendMarket != address(0), "Invalid address");
        emit CreateETHAaveV3LendMarket(currentUser, id, ethLendMarket);
    }

    function getUserIdToHook(uint256 _id) external view returns (address) {
        return UserIdToHook[_id];
    }
}
