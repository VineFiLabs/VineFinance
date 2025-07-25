// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "./VineAaveV3LendMain01.sol";
import {IGovernance} from "../../interfaces/core/IGovernance.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

contract VineAaveV3LendMain01Factory is IFactorySharer{

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

    event CreateAaveV3MainLendMarket(address indexed creator, uint64 indexed thisCuratorId, address market);

    function createMarket(address owner, address manager) external {
        uint64 curatorId = IGovernance(govern).getCuratorId(msg.sender);
        require(CuratorIdToHookMarketInfo[curatorId].state == ZEROBYTES1,"Already create");
        address aaveV3MainLendMarket = address(
            new VineAaveV3LendMain01{
                salt: keccak256(abi.encodePacked(curatorId, msg.sender, block.chainid))
            }(govern, owner, manager, curatorId)
        );
        CuratorIdToHookMarketInfo[curatorId] = HookMarketInfo({
            state: ONEBYTES1,
            hook: aaveV3MainLendMarket
        });
        ValidMarket[aaveV3MainLendMarket] = true;
        emit CreateAaveV3MainLendMarket(msg.sender, curatorId, aaveV3MainLendMarket);
        require(aaveV3MainLendMarket != address(0));
    }


}
