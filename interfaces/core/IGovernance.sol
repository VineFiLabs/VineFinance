// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.23;

interface IGovernance {

    enum ErrorType{
        InvalidHook,
        InvalidId,
        InvalidState,
        InvalidTime,
        InvalidAddress,
        InvalidFeeReceiver,
        InvalidFeeRate,
        Blacklist,
        AlreadySet
    }

    error InvalidHook(ErrorType errorType);
    error InvalidId(ErrorType errorType);
    error InvalidState(ErrorType errorType);
    error InvalidTime(ErrorType errorType);
    error InvalidAddress(ErrorType errorType);
    error InvalidFeeReceiver(ErrorType errorType);
    error InvalidFeeRate(ErrorType errorType);
    error BlacklistError(ErrorType errorType);
    error AlreadySetError(ErrorType errorType);

    event UpdateProtocolFee(
        uint16 indexed oldProtocolFee,
        uint16 indexed newProtocolFee
    );
    event UpdateOwner(address indexed oldOwner, address indexed newOwner);
    event UpdateManager(address indexed oldManager, address indexed newManager);
    event UpdateFeeManager(
        address indexed oldFeeManager,
        address indexed newFeeManager
    );
    event UpdateProtocolFeeReceiver(
        address indexed oldProtocolFeeReceiver,
        address indexed newProtocolFeeReceiver
    );
    event CreateID(uint256 indexed id, address creator);
    event ExamineID(uint256 indexed id, bool state);
    event Initialize(address indexed curator, address indexed coreLendMarket);
    event CuratorChangeFeeReceiver(address indexed curator, address indexed newFeeReceiver);

    struct MarketInfo{
        bool validState;
        uint16 curatorFee;
        uint16 protocolFee;
        uint64 bufferTime;
        uint64 endTime;
        address coreLendMarket;
        address crossCenter;
        address feeReceiver;
        address protocolFeeReceiver;
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

    function changeFeeManager(address _newFeeManager) external;

    function changeProtocolFeeReceiver(
        address _newProtocolFeeReceiver
    ) external;

    function changeProtocolFee(uint16 _newProtocolFee) external;

    function changeCrossCenter(uint8 _index, address _crossCenter) external;

    function changeL2Encode(address _l2Encode) external;
    function batchSetValidTokens(
        address[] calldata tokens,
        bytes1[] calldata states
    ) external;

    function batchSetBlacklists(
        bytes32[] calldata hooks,
        bytes1[] calldata states
    ) external;
    
    function batchSetValidHooks(
        uint32 destinationDomain,
        bytes32[] calldata hooks
    ) external;
    function skim(address token) external;
    function examine(uint256 id, bool state) external;

    //Register become a curator
    function register(
        uint8 _crossCenterIndex,
        uint16 _feeRate, 
        uint64 _bufferTime, 
        uint64 _endTime, 
        address _feeReceiver
    ) external;

    function initialize(address coreLendMarket) external;

    function curatorChangeFeeReceiver(address _feeReceiver) external;

    function ID() external view returns (uint256);
    function protocolFee() external view returns (uint16);
    function owner() external view returns (address);
    function manager() external view returns (address);
    function feeManager() external view returns (address);
    function protocolFeeReceiver() external view returns (address);
    function crossCenterGroup(uint8) external view returns (address);
    function ValidToken(address) external view returns (bytes1);
    function Blacklist(bytes32) external view returns (bytes1);
    function RegisterState(address) external view returns (bytes1);
    function InitializeState(uint256) external view returns (bytes1);

    function getCuratorToId(address curator) external view returns (uint256);

    function getL2Encode() external view returns(address);

    function getDestHook(uint256 id, uint32 destinationDomain, uint8 index) external view returns(bytes32 hook);
    
    function getDestChainValidHooks(uint256 id, uint32 destinationDomain)external view returns(ValidHooksInfo memory);

    function getDestChainValidHooksLength(uint256 id, uint32 destinationDomain)external view returns(uint256);

    function getDestChainHooksState(uint256 id, uint32 destinationDomain)external view returns(bytes1);

    function getIdAllDomains(uint256 id)external view returns(uint256[] memory allDomains);

    function getMarketInfo(uint256 id) external view returns (MarketInfo memory);

}
