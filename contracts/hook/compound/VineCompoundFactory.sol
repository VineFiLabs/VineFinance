// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "./VineCompoundCore.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IVineCompoundFactory} from "../../interfaces/hook/compound/IVineCompoundFactory.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

contract VineCompoundFactory is IVineCompoundFactory, IFactorySharer {

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
    function createCompoundMarket(address owner, address manager) external {
        uint64 curatorId = IVineHookCenter(govern).getCuratorId(msg.sender);
        require(CuratorIdToHookMarketInfo[curatorId].state == ZEROBYTES1,"Already create");
        address compoundMarket = address(
            new VineCompoundCore{
                salt: keccak256(abi.encodePacked(curatorId, msg.sender, block.chainid))
            }(govern, owner, manager, curatorId)
        );
        CuratorIdToHookMarketInfo[curatorId] = HookMarketInfo({
            state: ONEBYTES1,
            hook: compoundMarket
        });
        ValidMarket[compoundMarket] = true;
        emit CreateCompoundMarketEvent(msg.sender, curatorId, compoundMarket);
        require(compoundMarket != address(0));
    }

}
