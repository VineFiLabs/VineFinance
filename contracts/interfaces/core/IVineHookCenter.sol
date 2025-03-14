// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.23;

interface IVineHookCenter {
    
    error InvalidHook(string);
    error InvalidAddress(string);

    event UpdateOwner(address indexed oldOwner, address indexed newOwner);
    event UpdateManager(address indexed oldManager, address indexed newManager);
    event UpdateCaller(address indexed oldCaller, address indexed newCaller);
    event UpdateCrossCenter(uint8 indexed index, address indexed crossCenter);
    event SetBlacklist(bytes32 indexed hook, bytes1 state);

    event CreateID(uint256 indexed id, address creator);
    event ExamineID(uint256 indexed id, bool state);
    
    event Initialize(address indexed curator, address indexed coreLendMarket);

    struct MarketInfo{
        bool validState;
        address crossCenter;
        address curator;
    }

    
    struct ValidHooksInfo {
        bytes32[] hooks;           
        bytes1 state;            
    }
    struct IdValidHooksInfo {
        mapping(uint32 => ValidHooksInfo) destHooks;  
        uint32[] domains;
    }

    function changeOwner(address _newOwner) external;

    function changeManager(address _newManager) external;
    
    function changeCaller(address _newCaller) external;

    function changeCrossCenter(uint8 _index, address _crossCenter) external;

    function changeL2Encode(address _l2Encode) external;

    function batchSetBlacklists(
        bytes32[] calldata hooks,
        bytes1[] calldata states
    ) external;
    
    function batchSetValidHooks(
        uint32 destinationDomain,
        bytes32[] calldata hooks
    ) external;

    function examine(uint256 id, bool state) external;

    //Register become a curator
    function register(uint8 _crossCenterIndex) external;


    function ID() external view returns (uint256);
    function owner() external view returns (address);
    function manager() external view returns (address);
    function crossCenterGroup(uint8) external view returns (address);
    function Blacklist(bytes32) external view returns (bytes1);
    function RegisterState(address) external view returns (bytes1);
    function InitializeState(uint256) external view returns (bytes1);

    function getL2Encode() external view returns(address);

    function getDestHook(uint256 id, uint32 destinationDomain, uint8 index) external view returns(bytes32 hook);

    function getDestChainValidHooks(uint256 id, uint32 destinationDomain)external view returns(ValidHooksInfo memory);

    function getDestChainValidHooksLength(uint256 id, uint32 destinationDomain)external view returns(uint256);

    function getDestChainHooksState(uint256 id, uint32 destinationDomain)external view returns(bytes1);

    function getIdAllDomains(uint256 id)external view returns(uint256[] memory allDomains);

    function getCuratorToId(address curator) external view returns (uint256);

    function getMarketInfo(uint256 id) external view returns (MarketInfo memory);
}
