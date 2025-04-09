// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface ISharer {
    function curatorId() external view returns (uint64);
    function factory() external view returns (address);
    function govern() external view returns (address);
    function owner() external view returns (address);
    function manager() external view returns (address);
}
