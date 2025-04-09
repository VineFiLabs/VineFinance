// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "./VineAaveV3InL2Lend.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

contract VineInL2LendFactory is IFactorySharer {

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1 = 0x01;
    address public govern;
    constructor(address _govern) {
        govern = _govern;
    }

    struct HookMarketInfo{
        bytes1 state;
        address hook;
    }

    mapping(uint64 => HookMarketInfo) public CuratorIdToHookMarketInfo;
    mapping(address => bool) public ValidMarket;

    event CreateL2AaveV3LendMarket(
        address indexed creator,
        uint64 indexed thisCuratorId,
        address market
    );

    function createMarket(address owner, address manager) external {
        uint64 curatorId = IVineHookCenter(govern).getCuratorId(msg.sender);
        require(CuratorIdToHookMarketInfo[curatorId].state == ZEROBYTES1,"Already create");
        address l2LendMarket = address(
            new VineAaveV3InL2Lend{
                salt: keccak256(abi.encodePacked(curatorId, msg.sender, block.chainid))
            }(govern, owner, manager, curatorId)
        );
        CuratorIdToHookMarketInfo[curatorId] = HookMarketInfo({
            state: ONEBYTES1,
            hook: l2LendMarket
        });
        ValidMarket[l2LendMarket] = true;
        emit CreateL2AaveV3LendMarket(msg.sender, curatorId, l2LendMarket);
        require(l2LendMarket != address(0), "Invalid address");
    }

}
