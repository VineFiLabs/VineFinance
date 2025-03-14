// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IFactorySharer{
    function ValidMarket(address) external view returns(bool);
}