// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import {IGovernance} from "../interfaces/core/IGovernance.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract Governance is IGovernance {
    uint256 public ID;
    IWormholeRelayer public wormholeRelayer;

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1=0x01;
    bytes32 private immutable ZEROBYTES32;
    uint16 public protocolFee = 1000; ///  fee rate = protocolFee / 10000
    address public owner;
    address public manager;
    address public feeManager;
    address public Caller;
    address public protocolFeeReceiver;
    address private l2Encode;

    constructor(
        address _owner, 
        address _manager, 
        address _feeManager, 
        address _caller, 
        address _wormholeRelayer
    )
    {
        owner = _owner;
        manager = _manager;
        feeManager = _feeManager;
        Caller = _caller;
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    mapping(address => bytes1) public ValidToken;
    mapping(bytes32 => bytes1) public Blacklist;
    mapping(uint8 => address) public crossCenterGroup;
    
    mapping(uint256 => MarketInfo) private IdToMarketInfo;
    mapping(address => uint256) private CuratorToId;
    mapping(address => bytes1) public RegisterState;
    mapping(uint256 => bytes1) public InitializeState;

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

    mapping(uint256 => IdValidHooksInfo) private idToHooksInfo;

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
        Caller = _newCaller;
    }

    function changeFeeManager(address _newFeeManager) external onlyOwner {
        address oldFeeManager = feeManager;
        feeManager = _newFeeManager;
        emit UpdateFeeManager(oldFeeManager, _newFeeManager);
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

    function changeCrossCenter(uint8 _index, address _crossCenter) external onlyManager{
        crossCenterGroup[_index] = _crossCenter;
    }

    function changeL2Encode(address _l2Encode) external onlyManager{
        l2Encode = _l2Encode;
    }

    function batchSetValidTokens(
        address[] calldata tokens,
        bytes1[] calldata states
    ) external onlyManager {
        unchecked{
            for (uint256 i; i < tokens.length; i++) {
                ValidToken[tokens[i]] = states[i];
            }
        }
    }

    function batchSetBlacklists(
        bytes32[] calldata hooks,
        bytes1[] calldata states
    ) external onlyManager {
        unchecked {
            for(uint256 i; i< hooks.length; i++){
                Blacklist[hooks[i]] = states[i];
            }
        }
    }
    
    function batchSetValidHooks(
        uint32 destinationDomain,
        bytes32[] calldata hooks
    ) external {
        address currentUser = msg.sender;
        uint256 id = CuratorToId[currentUser];
        require(hooks.length <= 5);
        if(currentUser != IdToMarketInfo[id].curator){
            revert InvalidAddress(ErrorType.InvalidAddress);
        }
        if(idToHooksInfo[id].destHooks[destinationDomain].state == ONEBYTES1){
            revert AlreadySetError(ErrorType.AlreadySet);
        }
        unchecked{
            for (uint8 i; i < hooks.length; i++) {
                idToHooksInfo[id].destHooks[destinationDomain].hooks.push(hooks[i]);
            }
        }
        idToHooksInfo[id].domains.push(destinationDomain);
        idToHooksInfo[id].destHooks[destinationDomain].state = 0x01;
    }

    function skim(address token) external onlyManager{
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(protocolFeeReceiver, balance);
    }
    
    function examine(uint256 id, bool state) external onlyCaller {
        IdToMarketInfo[id].validState = state;
        emit ExamineID(id, state);
    }

    //Register become a curator
    function register(
        uint8 _crossCenterIndex,
        uint16 _feeRate, 
        uint64 _bufferTime, 
        uint64 _endTime, 
        address _feeReceiver
    ) external {
        address currentUser = msg.sender; 
        address crossCenter = crossCenterGroup[_crossCenterIndex];
        if(RegisterState[currentUser] == ONEBYTES1){
            revert AlreadySetError(ErrorType.AlreadySet);
        } 
        if(_feeReceiver == address(0) || crossCenter == address(0)){
            revert InvalidFeeReceiver(ErrorType.InvalidFeeReceiver);
        }
        if(_feeRate > 5000){
            revert InvalidFeeRate(ErrorType.InvalidFeeRate);
        }
        uint64 currentTime = uint64(block.timestamp);
        uint64 bufferTime =  _bufferTime + currentTime;
        uint64 endTime = _endTime + currentTime;
        uint64 bufferLimit = bufferTime + 1 days;
        if(_bufferTime <= 3600 || endTime < bufferLimit){
            revert InvalidTime(ErrorType.InvalidTime);
        }
        address _protocolFeeReceiver;
        if(protocolFeeReceiver == address(0)){
            _protocolFeeReceiver = address(this);
        }else{
            _protocolFeeReceiver = protocolFeeReceiver;
        }
        IdToMarketInfo[ID] = MarketInfo({
            validState: true,
            curatorFee: _feeRate,
            protocolFee: protocolFee,
            bufferTime: bufferTime,
            endTime: endTime,
            coreLendMarket: address(0),
            crossCenter: crossCenter,
            feeReceiver: _feeReceiver,
            protocolFeeReceiver: _protocolFeeReceiver,
            curator: currentUser
        });
        CuratorToId[currentUser] = ID;
        RegisterState[currentUser] = ONEBYTES1;
        ID++;
        emit CreateID(ID, currentUser);
    }

    function initialize(address coreLendMarket) external{
        uint256 id = CuratorToId[msg.sender];
        _checkValidId(id);
        if(InitializeState[id] == ONEBYTES1){
            revert AlreadySetError(ErrorType.AlreadySet);
        }   
        IdToMarketInfo[id].coreLendMarket = coreLendMarket;
        InitializeState[id] = ONEBYTES1;
        emit Initialize(msg.sender, coreLendMarket);
    }

    function curatorChangeFeeReceiver(address _feeReceiver) external {
        uint256 id = CuratorToId[msg.sender];
        _checkValidId(id);
        if(IdToMarketInfo[id].feeReceiver == address(0)){
            revert InvalidAddress(ErrorType.InvalidAddress);
        }
        IdToMarketInfo[id].feeReceiver = _feeReceiver;
        emit CuratorChangeFeeReceiver(msg.sender, _feeReceiver);
    }

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

    //emergency
    function sendMessage(
        uint16 targetChain,
        uint32 gasLimit,
        address targetAddress,
        uint256 id
    ) external payable {
        require(block.timestamp > IdToMarketInfo[id].endTime + 6 hours, "Not end time");
        uint256 cost = quoteCrossChainCost(targetChain, gasLimit);
        uint256 emergencyTime = uint256(IdToMarketInfo[id].endTime) + 6 hours;
        bytes memory payload = abi.encode(id, emergencyTime);
        require(msg.value == cost,"Insufficient eth");

        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            payload,
            0,
            gasLimit
        );
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

    function _checkValidId(uint256 id) private view {
        if(IdToMarketInfo[id].validState == false){
            revert InvalidId(ErrorType.InvalidId);
        }
    }

    function getCuratorToId(address curator) external view returns (uint256) {
        uint256 id = CuratorToId[curator];
        _checkValidId(id);
        return id;
    }

    function getL2Encode() external view returns(address){
        return l2Encode;
    }

    function getDestHook(uint256 id, uint32 destinationDomain, uint8 index) external view returns(bytes32 hook){
        _checkValidId(id);
        bytes32 thisHook = idToHooksInfo[id].destHooks[destinationDomain].hooks[index];
        if(Blacklist[thisHook] == ONEBYTES1){
            revert BlacklistError(ErrorType.Blacklist);
        }
        if(thisHook == ZEROBYTES32){
            revert InvalidHook(ErrorType.InvalidHook);
        }else{
            hook = thisHook;
        }
    }

    function getDestChainValidHooks(uint256 id, uint32 destinationDomain)external view returns(ValidHooksInfo memory){
        return idToHooksInfo[id].destHooks[destinationDomain];
    }

    function getDestChainValidHooksLength(uint256 id, uint32 destinationDomain)public view returns(uint256){
        return idToHooksInfo[id].destHooks[destinationDomain].hooks.length;
    }

    function getDestChainHooksState(uint256 id, uint32 destinationDomain)external view returns(bytes1){
        return idToHooksInfo[id].destHooks[destinationDomain].state;
    }

    function getIdAllDomains(uint256 id)external view returns(uint256[] memory allDomains){
        uint256 len = idToHooksInfo[id].domains.length;
        allDomains = new uint256[](len);
        unchecked {
            for(uint256 i; i<len; i++){
                allDomains[i] = idToHooksInfo[id].domains[i];
            }
        }
    }

    function getMarketInfo(
        uint256 id
    ) external view returns (MarketInfo memory) {
        return IdToMarketInfo[id];
    }
    
}
