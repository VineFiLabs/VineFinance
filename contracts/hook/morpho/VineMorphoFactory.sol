// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./VineMorphoCore.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IVineMorphoFactory} from "../../interfaces/hooks/IVineMorphoFactory.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";
import {FactoryManager} from "../../helper/FactoryManager.sol";

contract VineMorphoFactory is FactoryManager, IVineMorphoFactory, IFactorySharer {
    address public govern;

    constructor(address _govern) FactoryManager(msg.sender){
        govern = _govern;
    }

    mapping(address => bool) public ValidMarket;

    mapping(uint256 => address) internal UserIdToHook;

    mapping(uint8 => address) public IndexMorphoMarket;

    function changeMorphoMarket(uint8 index, address morphoMarket)external onlyManager{
        IndexMorphoMarket[index] = morphoMarket;
    }
    function createMorphoMarket(address owner, address manager) external {
        uint256 id = IVineHookCenter(govern).getCuratorToId(msg.sender);
        require(UserIdToHook[id] == address(0), "Already create");
        address swapMarket = address(
            new VineMorphoCore{
                salt: keccak256(abi.encodePacked(id, msg.sender))
            }(govern, owner, manager, id)
        );
        ValidMarket[swapMarket] = true;
        UserIdToHook[id] = swapMarket;
        require(swapMarket != address(0));
        emit CreateMorphoMarketEvent(msg.sender, id, swapMarket);
    }

    function getUserIdToHook(uint256 _id)external view returns(address){
        return UserIdToHook[_id];
    }
}
