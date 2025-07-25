// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "./VineUniswapV3Core.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

contract VineUniswapV3Factory is IFactorySharer {
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

    event CreateUniswapMarketEvent(
        address indexed creator,
        uint64 indexed thisCuratorId,
        address market
    );

    function createUniSwapV3Market(address owner, address manager) external {
        uint64 curatorId = IVineHookCenter(govern).getCuratorId(msg.sender);
        require(CuratorIdToHookMarketInfo[curatorId].state == ZEROBYTES1,"Already create");
        address uniswapV3Market = address(
            new VineUniswapV3Core{
                salt: keccak256(abi.encodePacked(curatorId, msg.sender, block.chainid))
            }(govern, owner, manager, curatorId)
        );
        CuratorIdToHookMarketInfo[curatorId] = HookMarketInfo({
            state: ONEBYTES1,
            hook: uniswapV3Market
        });
        ValidMarket[uniswapV3Market] = true;
        emit CreateUniswapMarketEvent(msg.sender, curatorId, uniswapV3Market);
        require(uniswapV3Market != address(0), "Invalid address");
    }

}
