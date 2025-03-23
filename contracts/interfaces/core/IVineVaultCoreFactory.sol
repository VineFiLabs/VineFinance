//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVineVaultCoreFactory {
    function createMarket(
        uint32 thisDomain,
        uint256 thisId,
        string memory tokenName, 
        string memory tokenSymbol
    ) external returns(address vineVault);

    function IdToVineVault(uint256) external view returns(address);
}
    