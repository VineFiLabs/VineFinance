// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./VineAaveV3InL1Lend.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

contract VineInL1LendFactory is IFactorySharer {

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

    event CreateL1AaveV3LendMarket(
        address indexed creator,
        uint64 indexed thisCuratorId,
        address market
    );

    function createMarket(address owner, address manager) external {
        uint64 curatorId = IVineHookCenter(govern).getCuratorId(msg.sender);
        require(CuratorIdToHookMarketInfo[curatorId].state == ZEROBYTES1,"Already create");
        address l1LendMarket = address(
            new VineAaveV3InL1Lend{
                salt: keccak256(abi.encodePacked(curatorId, msg.sender, block.chainid))
            }(govern, owner, manager, curatorId)
        );
        CuratorIdToHookMarketInfo[curatorId] = HookMarketInfo({
            state: ONEBYTES1,
            hook: l1LendMarket
        });
        ValidMarket[l1LendMarket] = true;
        emit CreateL1AaveV3LendMarket(msg.sender, curatorId, l1LendMarket);
        require(l1LendMarket != address(0), "Invalid address");
    }

}
