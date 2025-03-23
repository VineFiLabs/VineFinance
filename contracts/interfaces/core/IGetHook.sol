// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.23;
interface IGetHook {
    struct ValidHooksInfo {
        bytes32[] hooks;           
        bytes1 state;            
    }
    struct IdValidHooksInfo {
        mapping(uint32 => ValidHooksInfo) destHooks;  
        uint32[] domains;
    }

    function getDestHook(uint256 id, uint32 destinationDomain, uint8 index) external view returns(bytes32 hook);

    function getDestChainValidHooks(uint256 id, uint32 destinationDomain)external view returns(ValidHooksInfo memory);

    function getDestChainValidHooksLength(uint256 id, uint32 destinationDomain)external view returns(uint256);

    function getDestChainHooksState(uint256 id, uint32 destinationDomain)external view returns(bytes1);

    function getIdAllDomains(uint256 id)external view returns(uint256[] memory allDomains);
}