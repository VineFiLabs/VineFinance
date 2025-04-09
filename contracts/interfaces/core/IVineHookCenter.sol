// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.23;

import {IGetHook} from "./IGetHook.sol";
interface IVineHookCenter is IGetHook{
    
    error InvalidHook(string);
    error InvalidAddress(string);

    event UpdateOwner(address indexed oldOwner, address indexed newOwner);
    event UpdateManager(address indexed oldManager, address indexed newManager);
    event UpdateCaller(address indexed oldCaller, address indexed newCaller);
    event UpdateCrossCenter(uint8 indexed index, address indexed crossCenter);
    event SetBlacklist(bytes32 indexed hook, bytes1 state);
    event CuratorChangeDomain(address indexed curator, uint32 newDomain);

    event CreateID(uint256 indexed id, address creator);
    event ExamineID(uint256 indexed id, bool state);

    struct CuratorInfo{
        bytes1 state;
        uint64 userId;
        uint256[] marketIds;
    }

    struct MarketInfo{
        bool validState;
        uint32 domain;
        uint64 userId;
        address crossCenter;
        address vineVault;
        address vineConfigAddress;
        address curator;
    }

    function changeOwner(address _newOwner) external;

    function changeManager(address _newManager) external;
    
    function changeCaller(address _newCaller) external;

    function changeCrossCenter(uint8 _index, address _crossCenter) external;

    function changeL2Encode(address _l2Encode) external;

    function batchSetBlacklists(
        bytes32[] calldata hooks,
        bytes1[] calldata status
    ) external;

    function examine(uint256 id, bool state) external;

    //Register become a curator
    function register(
        uint8 crossCenterIndex, 
        uint32 domain,
        uint32[] calldata chooseDomains
    ) external;

    function batchSetValidHooks(
        uint256 id,
        uint32 destinationDomain,
        bytes32 vault,
        bytes32[] calldata hooks
    ) external;

    function ID() external view returns (uint256);
    function owner() external view returns (address);
    function manager() external view returns (address);
    function wormholeRelayer() external view returns (address);
    function curatorId() external view returns (uint64);
    function crossCenterGroup(uint8) external view returns (address);
    function Blacklist(bytes32) external view returns (bytes1);
    function curatorIdToCurator(uint64) external view returns (address);

    function getCuratorId(address user) external view returns(uint64 thisCuratorId);

    function getCuratorMarketIdsLength(address user) external view returns(uint256 len);

    function getCuratorLastId(address user) external view returns(uint256 id);

    function indexCuratorToId(address user, uint256 index) external view returns(uint256 id);

    function getL2Encode() external view returns(address);

    function getMarketInfo(uint256 id) external view returns (MarketInfo memory);
}
