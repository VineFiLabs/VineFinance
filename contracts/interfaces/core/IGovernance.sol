// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.23;

import {IGetHook} from "./IGetHook.sol";
interface IGovernance is IGetHook{

    error InvalidHook(string);
    error InvalidAddress(string);

    event UpdateProtocolFee(
        uint16 indexed oldProtocolFee,
        uint16 indexed newProtocolFee
    );
    event UpdateOwner(address indexed oldOwner, address indexed newOwner);
    event UpdateManager(address indexed oldManager, address indexed newManager);
    event UpdateProtocolFeeReceiver(
        address indexed oldProtocolFeeReceiver,
        address indexed newProtocolFeeReceiver
    );
    event UpdateCaller(address indexed oldCaller, address indexed newCaller);
    event UpdateCrossCenter(uint8 indexed index, address indexed crossCenter);
    event SetBlacklist(bytes32 indexed hook, bytes1 state);

    event CreateID(uint256 indexed id, address creator);
    event ExamineID(uint256 indexed id, bool state);
    event Initialize(address indexed curator, address indexed coreLendMarket);
    event CuratorChangeFeeReceiver(address indexed curator, address indexed newFeeReceiver);
    
    struct CuratorInfo{
        bytes1 state;
        uint64 userId;
        uint256[] marketIds;
    }

    struct MarketInfo{
        bool validState;
        uint16 curatorFee;
        uint16 protocolFee;
        uint32 domain;
        uint64 bufferTime;
        uint64 endTime;
        uint64 userId;
        address coreLendMarket;
        address vineVault;
        address crossCenter;
        address rewardPool;
        address vineConfigAddress;
        address feeReceiver;
        address protocolFeeReceiver;
        address curator;
    }

    struct RegisterParams{
        uint8 crossCenterIndex;
        uint16 feeRate;
        uint32 domain;
        uint32[] chooseDomains;
        uint64 bufferTime; 
        uint64 endTime;
        address thisFeeReceiver;
        string tokenName;
        string tokenSymbol;
    }

    function changeOwner(address _newOwner) external;

    function changeManager(address _newManager) external;
    
    function changeCaller(address _newCaller) external;

    function changeProtocolFeeReceiver(
        address _newProtocolFeeReceiver
    ) external;

    function changeProtocolFee(uint16 _newProtocolFee) external;

    function changeCrossCenter(uint8 _index, address _crossCenter) external;

    function changeL2Encode(address _l2Encode) external;
    function batchSetValidTokens(
        address[] calldata tokens,
        bytes1[] calldata status
    ) external;

    function batchSetBlacklists(
        bytes32[] calldata hooks,
        bytes1[] calldata status
    ) external;

    function examine(uint256 id, bool state) external;

    //Register become a curator
    function register(
        RegisterParams calldata params
    ) external;
    
    function batchSetValidHooks(
        uint256 id,
        uint32 destinationDomain,
        bytes32 vault,
        bytes32[] calldata hooks
    ) external;

    function initialize(uint256 id, address coreLendMarket) external;

    function curatorChangeFeeReceiver(uint256 id, address curatorFeeReceiver) external;

    function ID() external view returns (uint256);
    function protocolFee() external view returns (uint16);
    function curatorId() external view returns (uint64);
    function owner() external view returns (address);
    function manager() external view returns (address);
    function protocolFeeReceiver() external view returns (address);

    function crossCenterGroup(uint8) external view returns (address);
    function ValidToken(address) external view returns (bytes1);
    function Blacklist(bytes32) external view returns (bytes1);
    function InitializeState(uint256) external view returns (bytes1);
    function curatorIdToCurator(uint64) external view returns (address);

    function getCuratorId(address user) external view returns(uint64 thisCuratorId);

    function getCuratorMarketIdsLength(address user) external view returns(uint256 len);

    function getCuratorLastId(address user) external view returns(uint256 id);

    function indexCuratorToId(address user, uint256 index) external view returns(uint256 id);

    function getL2Encode() external view returns(address);

    function getMarketInfo(uint256 id) external view returns (MarketInfo memory);

}
