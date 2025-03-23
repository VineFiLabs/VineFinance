// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IVineMorphoFactory {

    event CreateMorphoMarketEvent(
        address indexed creator,
        uint256 indexed marketId,
        address market
    );

    function IndexMorphoMarket(uint8)external view returns(address);

}