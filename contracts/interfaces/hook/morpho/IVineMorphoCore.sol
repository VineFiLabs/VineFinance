// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVineMorphoCore {

    struct MorphoInfo{
        uint256 assetsSupplied; 
        uint256 sharesSupplied;
    }

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