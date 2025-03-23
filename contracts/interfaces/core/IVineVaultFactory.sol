//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVineVaultFactory {
    function createMarket(
        uint32 thisDomain,
        uint256 thisId
    ) external returns(address vineVaultCore);

    function IdToVineVault(uint256) external view returns(address);
}
    