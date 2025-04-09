// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";

import {IGovernance} from "../interfaces/core/IGovernance.sol";
import {IVineVaultCoreFactory} from "../interfaces/core/IVineVaultCoreFactory.sol";
import {IVineVaultCore} from "../interfaces/core/IVineVaultCore.sol";
import {IERC20} from "../interfaces/IERC20.sol";

/// @title Governance
/// @author VineLabs member 0xlive(https://github.com/VineFiLabs)
/// @notice VineFinance Governance
/// @dev Used for official configuration and curator registration and initialization
contract Governance is IGovernance {
    uint256 public ID;
    
    IWormholeRelayer public wormholeRelayer;

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1=0x01;
    bytes32 private immutable ZEROBYTES32;

    uint16 public protocolFee = 1000; ///  fee rate = protocolFee / 10000
    uint64 public curatorId;
    address public owner;
    address public manager;
    address public Caller;
    address public protocolFeeReceiver;
    address public vineVaultFactory;
    address public currentRewardPool;
    address public vineConfig;
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
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    mapping(address => bytes1) public ValidToken;
    mapping(bytes32 => bytes1) public Blacklist;
    mapping(uint8 => address) public crossCenterGroup;
    
    mapping(uint256 => MarketInfo) private IdToMarketInfo;
    mapping(uint256 => bytes1) public InitializeState;


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

    function changeProtocolFeeReceiver(
        address _newProtocolFeeReceiver
    ) external onlyOwner {
        address oldProtocolFeeReceiver = protocolFeeReceiver;
        protocolFeeReceiver = _newProtocolFeeReceiver;
        emit UpdateProtocolFeeReceiver(
            oldProtocolFeeReceiver,
            _newProtocolFeeReceiver
        );
    }

    function changeProtocolFee(uint16 _newProtocolFee) external onlyOwner {
        require(_newProtocolFee <= 5000);
        uint16 oldProtocolFee = protocolFee;
        protocolFee = _newProtocolFee;
        emit UpdateProtocolFee(oldProtocolFee, _newProtocolFee);
    }

    function changeCrossCenter(uint8 _index, address _crossCenter) external onlyOwner {
        crossCenterGroup[_index] = _crossCenter;
        emit UpdateCrossCenter(_index, _crossCenter);
    }

    function setVineConfig(address _rewardPool, address _vineVaultFactory, address _vineConfig) external onlyOwner {
        vineVaultFactory = _vineVaultFactory;
        currentRewardPool = _rewardPool;
        vineConfig = _vineConfig;
    }

    function changeL2Encode(address _l2Encode) external onlyManager {
        l2Encode = _l2Encode;
    }

    /**
    * @notice VineLabs The administrator configures valid token groups in batches
    * @param tokens Token group
    * @param status Hook status, 0x00 valid, otherwise invalid
    */
    function batchSetValidTokens(
        address[] calldata tokens,
        bytes1[] calldata status
    ) external onlyManager {
        unchecked{
            for (uint256 i; i < tokens.length; i++) {
                ValidToken[tokens[i]] = status[i];
            }
        }
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
    * @notice VineLabs The administrator change the current cctp domain of a VineVault
    * @param vineVault The Hook array of bytes32
    * @param newDomain Hook status, 0x00 valid, otherwise invalid
    */
    function changeVineVaultDomain(address vineVault, uint32 newDomain) external onlyManager{
        IVineVaultCore(vineVault).changeDomain(newDomain);
    }

    /**
    * @notice The VineLabs administrator cleans the Governance token to the protocol receiver address
    * @param token token to be cleared
    */
    function skim(address token) external onlyManager {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(protocolFeeReceiver, balance);
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
    * Note The thisFeeReceiver of RegisterParams cannot be zero address
    * Note Curatorial fees require <50% of revenue, eg: 1000 = 10%
    * Note A maximum of six CCTP domain can be selected
    * Note RegisterParams min bufferTime > 1 days, min endTime  >= bufferTime + 1 days,
    * eg: min bufferTime = 86401, endTime = 172801
    * @param params Registers the incoming RegisterParams struct
    */
    function register(
        RegisterParams calldata params
    ) external {
        address currentUser = msg.sender; 
        address thisProtocolFeeReceiver;
        address crossCenter = crossCenterGroup[params.crossCenterIndex];
        require(
            params.thisFeeReceiver != address(0) && 
            crossCenter != address(0) && 
            vineConfig != address(0) &&
            currentRewardPool != address(0), "Zero address");
        require(params.feeRate <= 5000, "Invalid fee rate");
        require(params.chooseDomains.length < 7, "Domains need < 7");  //max chains = 6 
        uint64 currentTime = uint64(block.timestamp);
        uint64 thisBufferTime =  params.bufferTime + currentTime;
        uint64 thisEndTime = params.endTime + currentTime;
        uint64 bufferLimit = thisBufferTime + 1 days;
        require(params.bufferTime > 1 days && thisEndTime >= bufferLimit, "Invalid time");
        if(protocolFeeReceiver == address(0)){
            thisProtocolFeeReceiver = address(this);
        }else{
            thisProtocolFeeReceiver = protocolFeeReceiver;
        }
        address vineVaultAddress = IVineVaultCoreFactory(vineVaultFactory).createMarket(
            params.domain,
            ID, 
            params.tokenName, 
            params.tokenSymbol
        );
        if(curatorInfo[currentUser].state == ZEROBYTES1){
            curatorInfo[currentUser].state = ONEBYTES1;
            curatorInfo[currentUser].userId = curatorId;
            curatorIdToCurator[curatorId] = currentUser;
            curatorId++;
        }
        IdToMarketInfo[ID] = MarketInfo({
            validState: true,
            curatorFee: params.feeRate,
            protocolFee: protocolFee,
            domain: params.domain,
            bufferTime: thisBufferTime,
            endTime: thisEndTime,
            userId: curatorInfo[currentUser].userId,
            coreLendMarket: address(0),
            vineVault: vineVaultAddress,
            crossCenter: crossCenter,
            rewardPool: currentRewardPool,
            vineConfigAddress: vineConfig,
            feeReceiver: params.thisFeeReceiver,
            protocolFeeReceiver: thisProtocolFeeReceiver,
            curator: currentUser
        });
        curatorInfo[currentUser].marketIds.push(ID);
        for(uint256 i; i<params.chooseDomains.length; i++){
            idToHooksInfo[ID].domains.push(params.chooseDomains[i]);
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
            idToHooksInfo[id].destHooks[destinationDomain].state = ONEBYTES1;
        }else{
            revert ("Invalid destinationDomain");
        }
    }

    /**
    * @notice The curator or VineLabs administrator initiates the core market contract for a market
    * Note This command can be executed only once
    * @param id The market ID belonging to this main market
    * @param coreLendMarket Core market contract address
    */
    function initialize(uint256 id, address coreLendMarket) external {
        require(msg.sender == IdToMarketInfo[id].curator || msg.sender ==  manager, "Not operator");
        require(InitializeState[id] == ZEROBYTES1, "Already initialize");
        IdToMarketInfo[id].coreLendMarket = coreLendMarket;
        InitializeState[id] = ONEBYTES1;
        emit Initialize(msg.sender, coreLendMarket);
    }

    /**
    * @notice The curator changes the fee recipient address of the marketplace he creates
    * @param id The market ID belonging to this main market
    * @param curatorFeeReceiver Fee recipient
    */
    function curatorChangeFeeReceiver(uint256 id, address curatorFeeReceiver) external onlyCurator(id) {
        if(IdToMarketInfo[id].feeReceiver == address(0)){
            revert InvalidAddress("Invalid address");
        }
        IdToMarketInfo[id].feeReceiver = curatorFeeReceiver;
        emit CuratorChangeFeeReceiver(msg.sender, curatorFeeReceiver);
    }

    /**
    * @notice Retrieves the cost of delivering cross-chain information to the target chain using wormhole
    * @param targetChain wormhole Target chain id
    * @param gasLimit The gaslimit required for execution of the target chain
    * Note Set the gasLimit as large as possible, 500000 is recommended
    * @return cost the cost of the wormhole
    */
    function quoteCrossChainCost(
        uint16 targetChain,
        uint32 gasLimit
    ) public view returns (uint256 cost) {
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            gasLimit
        );
    }

    /**
    * @notice In the event of an emergency for a policy, anyone can send emergency information to the target chain, 
    * perform extraction and cross the chain to the main market VineVault
    * @param targetChain wormhole Target chain id
    * @param gasLimit The gaslimit required for execution of the target chain
    * Note Set the gasLimit as large as possible, 500000 is recommended
    * @param targetAddress The Hook address of the policy of the target chain
    * @param id The market ID belonging to this main market
    */
    function sendMessage(
        uint16 targetChain,
        uint32 gasLimit,
        address targetAddress,
        uint256 id
    ) external payable {
        require(block.timestamp > IdToMarketInfo[id].endTime + 12 hours, "Not emergency time");
        uint256 cost = quoteCrossChainCost(targetChain, gasLimit);
        uint256 emergencyTime = uint256(IdToMarketInfo[id].endTime) + 12 hours;
        bytes memory payload = abi.encode(id, emergencyTime);
        require(msg.value >= cost,"Insufficient eth");

        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            payload,
            0,
            gasLimit
        );
    }

    function _checkOwner() private view {
        require(msg.sender == owner);
    }

    function _checkManager() private view {
        require(msg.sender == manager);
    }

    function _checkCaller() private view {
        require(msg.sender == Caller);
    }

    function _checkOwnerById(uint256 id) private view {
        require(msg.sender == IdToMarketInfo[id].curator, "Not this curator");
    }

    /**
    * @notice Get the curator id
    * @param user Curator address
    * @return  thisCuratorId The id of the curator
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
        len =  curatorInfo[user].marketIds.length;
    }

    /**
    * @notice Get the curator's newly created market id
    * @param user Curator address
    * @return id of the newly created marketplace
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
    function getL2Encode() external view returns(address){
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
    * @return All valid ValidHooksInfo groups for bytes32 of the target chain
    */ 
    function getDestChainValidHooks(uint256 id, uint32 destinationDomain) external view returns(ValidHooksInfo memory) {
        return idToHooksInfo[id].destHooks[destinationDomain];
    }

    /**
    * @notice Get the length of the effective hook group of the target chain
    * @param id The market ID belonging to this main market
    * @param destinationDomain cctp domain of the target chain
    * @return Length of the effective hook group of the target chain
    */
    function getDestChainValidHooksLength(uint256 id, uint32 destinationDomain) public view returns(uint256) {
        return idToHooksInfo[id].destHooks[destinationDomain].hooks.length;
    }

    /**
    * @notice Get the state of the valid hook group of the target chain
    * @param id The market ID belonging to this main market
    * @param destinationDomain cctp domain of the target chain
    * @return The state of the hook group of the target chain, 0x01 is valid, otherwise invalid
    */
    function getDestChainHooksState(uint256 id, uint32 destinationDomain) external view returns(bytes1) {
        return idToHooksInfo[id].destHooks[destinationDomain].state;
    }

    /**
    * @notice Get the market id for all cctp domains
    * @param id The market ID belonging to this main market
    * @return allDomains Market id for all cctp domains
    */
    function getIdAllDomains(uint256 id) external view returns(uint256[] memory allDomains) {
        uint256 len = idToHooksInfo[id].domains.length;
        allDomains = new uint256[](len);
        unchecked {
            for(uint256 i; i<len; i++){
                allDomains[i] = idToHooksInfo[id].domains[i];
            }
        }
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
