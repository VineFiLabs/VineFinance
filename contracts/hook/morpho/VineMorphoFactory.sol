// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "./VineMorphoCore.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IVineMorphoFactory} from "../../interfaces/hook/morpho/IVineMorphoFactory.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

contract VineMorphoFactory is IVineMorphoFactory, IFactorySharer {

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1 = 0x01;
    address public govern;

    constructor(address _govern){
        govern = _govern;
    }

    struct HookMarketInfo{
        bytes1 state;
        address hook;
    }

    mapping(uint64 => HookMarketInfo) public CuratorIdToHookMarketInfo;
    mapping(address => bool) public ValidMarket;
    function createMorphoMarket(address owner, address manager) external {
        uint64 curatorId = IVineHookCenter(govern).getCuratorId(msg.sender);
        require(CuratorIdToHookMarketInfo[curatorId].state == ZEROBYTES1,"Already create");
        address morphoMarket = address(
            new VineMorphoCore{
                salt: keccak256(abi.encodePacked(curatorId, msg.sender, block.chainid))
            }(govern, owner, manager, curatorId)
        );
        CuratorIdToHookMarketInfo[curatorId] = HookMarketInfo({
            state: ONEBYTES1,
            hook: morphoMarket
        });
        ValidMarket[morphoMarket] = true;
        emit CreateMorphoMarketEvent(msg.sender, curatorId, morphoMarket);
        require(morphoMarket != address(0));
    }

}
