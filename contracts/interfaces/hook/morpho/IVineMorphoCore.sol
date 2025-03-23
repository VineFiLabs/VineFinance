// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IVineMorphoCore {

    event MorphoSupply(
        address indexed sender,
        uint256 assetsSupplied,
        uint256 sharesSupplied
    );
    event MorphoWithdraw(
        address indexed sender,
        uint256 assetsWithdrawn,
        uint256 sharesWithdrawn
    );


}