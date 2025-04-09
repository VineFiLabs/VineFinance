// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IVineVaultFactory} from "../interfaces/core/IVineVaultFactory.sol";
import {IVineHookCenter} from "../interfaces/core/IVineHookCenter.sol";
import {IVineVault} from "../interfaces/core/IVineVault.sol";

/// @title CoreCrossCenter
/// @author VineLabs member 0xlive(https://github.com/VineFiLabs)
/// @notice CoreCrossCenter is the main entry to the policy module
/// @dev Curators need to register to use the chain module
contract VineHookCenter is IVineHookCenter {
    uint256 public ID;

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1=0x01;
    bytes32 private immutable ZEROBYTES32;

    uint64 public curatorId;
    address public owner;
    address public manager;
    address public Caller;
    address public vineVaultFactory;
    address public vineConfig;
    address public wormholeRelayer;
    address private l2Encode;

    constructor(
        address _owner, 
        address _manager, 
        address _caller,
        address _wormholeRelayer
    )
    {
        owner = _owner;
        manager = _manager;
        Caller = _caller;
        wormholeRelayer = _wormholeRelayer;
    }

    mapping(bytes32 => bytes1) public Blacklist;
    mapping(uint8 => address) public crossCenterGroup;
    
    mapping(uint256 => MarketInfo) private IdToMarketInfo;

    mapping(uint64 => address) public curatorIdToCurator;
    mapping(address => CuratorInfo) private curatorInfo;
    mapping(uint256 => IdValidHooksInfo) private idToHooksInfo;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }

    modifier onlyCaller() {
        _checkCaller();
        _;
    }

    modifier onlyCurator(uint256 id) {
        _checkOwnerById(id);
        _;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = _newOwner;
        emit UpdateOwner(oldOwner, _newOwner);
    }

    function changeManager(address _newManager) external onlyOwner {
        address oldManager = manager;
        manager = _newManager;
        emit UpdateManager(oldManager, _newManager);
    }
    
    function changeCaller(address _newCaller) external onlyOwner {
        address oldCaller = Caller;
        Caller = _newCaller;
        emit UpdateCaller(oldCaller, _newCaller);
    }

    function changeCrossCenter(uint8 _index, address _crossCenter) external onlyManager {
        crossCenterGroup[_index] = _crossCenter;
        emit UpdateCrossCenter(_index, _crossCenter);
    }

    function setVineConfig(address _vineVaultFactory, address _vineConfig) external onlyOwner {
        vineVaultFactory = _vineVaultFactory;
        vineConfig = _vineConfig;
    }

    function changeL2Encode(address _l2Encode) external onlyManager {
        l2Encode = _l2Encode;
    }

    function changeWormholeRelayer(address _wormholeRelayer) external onlyManager{
        wormholeRelayer = _wormholeRelayer;
    }

    /**
    * @notice The VineLabs administrator sets the state of the created hooks in batches
    * @param hooks The Hook array of bytes32
    * @param status Hook status, 0x00 valid, otherwise invalid
    */
    function batchSetBlacklists(
        bytes32[] calldata hooks,
        bytes1[] calldata status
    ) external onlyManager {
        unchecked {
            for(uint256 i; i< hooks.length; i++){
                Blacklist[hooks[i]] = status[i];
                emit SetBlacklist(hooks[i], status[i]);
            }
        }
    }
    
    /**
    * @notice VineLabs' caller countermeasure curator for review, false means invalid
    * @param id The market ID belonging to this main market
    * @param state The market ID status
    */
    function examine(uint256 id, bool state) external onlyCaller {
        IdToMarketInfo[id].validState = state;
        emit ExamineID(id, state);
    }

    /**
    * @notice Anyone can register as a curator while creating a VineVault of the policy
    * eg: min bufferTime = 86401, endTime = 172801
    * @param crossCenterIndex Index your desired CrossCenter seat cross-chain repeater
    * @param domain cctp domain of the current chain
    * @param chooseDomains The current policy in the chain wants to cross the chain cctp domain group
    */
    function register(
        uint8 crossCenterIndex, 
        uint32 domain,
        uint32[] calldata chooseDomains
    ) external {
        address currentUser = msg.sender; 
        address crossCenter = crossCenterGroup[crossCenterIndex];
        require(crossCenter != address(0), "Invalid address");
        address vineVaultAddress = IVineVaultFactory(vineVaultFactory).createMarket(
            domain,
            ID
        );
        if(curatorInfo[currentUser].state == ZEROBYTES1){
            curatorInfo[currentUser].state = ONEBYTES1;
            curatorInfo[currentUser].userId = curatorId;
            curatorIdToCurator[curatorId] = currentUser;
            curatorId++;
        }
        IdToMarketInfo[ID] = MarketInfo({
            validState: true,
            domain: domain,
            userId: curatorInfo[currentUser].userId,
            crossCenter: crossCenter,
            vineVault: vineVaultAddress,
            vineConfigAddress: vineConfig,
            curator: currentUser
        });
        curatorInfo[currentUser].marketIds.push(ID);
        for(uint256 i; i<chooseDomains.length; i++){
            idToHooksInfo[ID].domains.push(chooseDomains[i]);
        }
        emit CreateID(ID, currentUser);
        ID++;
        require(vineVaultAddress != address(0));
    }

    /**
    * @notice The curator sets personal policies for Hooks and vaults
    * Note The current chain also needs to be configured with corresponding information
    * @param id The market ID belonging to this main market
    * @param destinationDomain cctp domain of the target chain
    * @param vault VineVault of the target chain bytes32
    * @param hooks The bytes32 array of the hook of the target chain
    */
    function batchSetValidHooks(
        uint256 id,
        uint32 destinationDomain,
        bytes32 vault,
        bytes32[] calldata hooks
    ) external onlyCurator(id) {
        require(hooks.length < 7);
        require(idToHooksInfo[id].destHooks[destinationDomain].state == ZEROBYTES1, "Already set this chain");
        bool state;
        unchecked{
            for(uint256 i; i<idToHooksInfo[id].domains.length; i++){
                if(destinationDomain == idToHooksInfo[id].domains[i]){
                    state = true;
                }
            }
        }
        if(state){
            unchecked{
                for (uint256 j; j < hooks.length; j++) {
                    idToHooksInfo[id].destHooks[destinationDomain].hooks.push(hooks[j]);
                }
            }
            idToHooksInfo[id].destHooks[destinationDomain].vault = vault;
            idToHooksInfo[id].destHooks[destinationDomain].state = 0x01;
        }else{
            revert ("Invalid destinationDomain");
        }
    }

    function _checkOwner() private view {
        require(msg.sender == owner, "Non owner");
    }

    function _checkManager() private view {
        require(msg.sender == manager, "Non manager");
    }

    function _checkCaller() private view {
        require(msg.sender == Caller, "Non caller");
    }

    function _checkOwnerById(uint256 id) private view {
        require(msg.sender == IdToMarketInfo[id].curator, "Not this curator");
    }

    function getL2Encode() external view returns(address) {
        return l2Encode;
    }

    /**
    * @notice Get the hook of the target chain
    * @param id The market ID belonging to this main market
    * @param destinationDomain cctp domain of the target chain
    * @param index Target chain hooks index
    * @return hook Get the bytes32 hook of the target chain
    */ 
    function getDestHook(uint256 id, uint32 destinationDomain, uint8 index) external view returns(bytes32 hook) {
        require(IdToMarketInfo[id].validState, "Invalid id");
        bytes32 thisHook = idToHooksInfo[id].destHooks[destinationDomain].hooks[index];
        require(Blacklist[thisHook] == ZEROBYTES1, "Blacklist");
        if(thisHook == ZEROBYTES32){
            revert InvalidHook("Invalid hook");
        }else{
            hook = thisHook;
        }
    }
    
    /**
    * @notice Get the vault of the target chain
    * @param id The market ID belonging to this main market
    * @param destinationDomain cctp domain of the target chain
    * @return destVault Get the bytes32 vault of the target chain
    */ 
    function getDestVault(uint256 id, uint32 destinationDomain) external view returns(bytes32 destVault){
        require(IdToMarketInfo[id].validState, "Invalid id");
        bytes32 thisVault = idToHooksInfo[id].destHooks[destinationDomain].vault;
        if(thisVault == ZEROBYTES32){
            revert ("Invalid vault");
        }else{
            destVault = thisVault;
        }
    }

    /**
    * @notice Get all valid hook groups for bytes32 of the target chain
    * @param id The market ID belonging to this main market
    * @param destinationDomain cctp domain of the target chain
    * @return All valid hook groups for bytes32 of the target chain
    */ 
    function getDestChainValidHooks(uint256 id, uint32 destinationDomain)external view returns(ValidHooksInfo memory) {
        return idToHooksInfo[id].destHooks[destinationDomain];
    }

    /**
    * @notice Get the length of the effective hook group of the target chain
    * @param id The market ID belonging to this main market
    * @param destinationDomain cctp domain of the target chain
    * @return Length of the effective hook group of the target chain
    */
    function getDestChainValidHooksLength(uint256 id, uint32 destinationDomain)public view returns(uint256) {
        return idToHooksInfo[id].destHooks[destinationDomain].hooks.length;
    }

    /**
    * @notice Get the state of the valid hook group of the target chain
    * @param id The market ID belonging to this main market
    * @param destinationDomain cctp domain of the target chain
    * @return The state of the hook group of the target chain, 0x01 is valid, otherwise invalid
    */
    function getDestChainHooksState(uint256 id, uint32 destinationDomain)external view returns(bytes1) {
        return idToHooksInfo[id].destHooks[destinationDomain].state;
    }

    /**
    * @notice Get the market id for all cctp domains
    * @param id The market ID belonging to this main market
    * @return allDomains Market id for all cctp domains
    */
    function getIdAllDomains(uint256 id)external view returns(uint256[] memory allDomains) {
        uint256 len = idToHooksInfo[id].domains.length;
        allDomains = new uint256[](len);
        unchecked {
            for(uint256 i; i<len; i++){
                allDomains[i] = idToHooksInfo[id].domains[i];
            }
        }
    }

    /**
    * @notice Get the curator id
    * @param user Curator address
    * @return thisCuratorId  The id of the curator
    */
    function getCuratorId(address user) external view returns(uint64 thisCuratorId) {
        if(curatorInfo[user].state == ONEBYTES1){
            thisCuratorId = curatorInfo[user].userId;
        }else {
            revert ("Invalid curatorId");
        }
    }

    /**
    * @notice Get the length of all market ids created by the curator
    * @param user Curator address
    * @return len All market ids length
    */ 
    function getCuratorMarketIdsLength(address user) external view returns(uint256 len) {
        len = curatorInfo[user].marketIds.length;
    }

    /**
    * @notice Get the curator's newly created market id
    * @param user Curator address
    * @return id Id of the newly created marketplace
    */ 
    function getCuratorLastId(address user) external view returns(uint256 id) {
        uint256 len = curatorInfo[user].marketIds.length;
        if(len > 0){
            id =curatorInfo[user].marketIds[len - 1];
        }else{
            revert ("Not registered");
        }
    }

    /**
    * @notice Index the market id created by the curator
    * @param user Curator address
    * @param index Created market id index
    * @return id Market id
    */ 
    function indexCuratorToId(address user, uint256 index) external view returns(uint256 id) {
        id = curatorInfo[user].marketIds[index];
    }

    /**
    * @notice Get the market id information
    * @param id The market ID belonging to this main market
    * @return MarketInfo struct
    */
    function getMarketInfo(
        uint256 id
    ) external view returns (MarketInfo memory) {
        return IdToMarketInfo[id];
    }

}
