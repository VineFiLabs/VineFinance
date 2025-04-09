// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVineCompoundFactory {

    event CreateCompoundMarketEvent(
        address indexed creator,
        uint256 indexed marketId,
        address market
    );

}