// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IVineHookCenter} from "../interfaces/core/IVineHookCenter.sol";

contract VineHookCenter is IVineHookCenter {
    uint256 public ID;

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1=0x01;
    bytes32 private immutable ZEROBYTES32;
    uint16 public protocolFee = 1000; ///  fee rate = protocolFee / 10000
    address public owner;
    address public manager;
    address public Caller;
    address public protocolFeeReceiver;
    address private l2Encode;

    constructor(address _owner, address _manager, address _caller)
    {
        owner = _owner;
        manager = _manager;
        Caller = _caller;
    }

    mapping(bytes32 => bytes1) public Blacklist;
    mapping(uint8 => address) public crossCenterGroup;
    
    mapping(uint256 => MarketInfo) private IdToMarketInfo;
    mapping(address => uint256) private CuratorToId;
    mapping(address => bytes1) public RegisterState;
    mapping(uint256 => bytes1) public InitializeState;

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

    function changeCrossCenter(uint8 _index, address _crossCenter) external onlyManager{
        crossCenterGroup[_index] = _crossCenter;
    }

    function changeL2Encode(address _l2Encode) external onlyManager{
        l2Encode = _l2Encode;
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
    
    function examine(uint256 id, bool state) external onlyCaller {
        IdToMarketInfo[id].validState = state;
        emit ExamineID(id, state);
    }

    //Register become a curator
    function register(uint8 _crossCenterIndex) external {
        address currentUser = msg.sender; 
        address crossCenter = crossCenterGroup[_crossCenterIndex];
        if(RegisterState[currentUser] == ONEBYTES1){
            revert AlreadySetError(ErrorType.AlreadySet);
        } 
        if(crossCenter == address(0)){
            revert InvalidAddress(ErrorType.InvalidAddress);
        }
        IdToMarketInfo[ID] = MarketInfo({
            validState: true,
            crossCenter: crossCenter,
            curator: currentUser
        });
        CuratorToId[currentUser] = ID;
        RegisterState[currentUser] = ONEBYTES1;
        ID++;
        emit CreateID(ID, currentUser);
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

    function getCuratorToId(address curator) external view returns (uint256) {
        uint256 id = CuratorToId[curator];
        _checkValidId(id);
        return id;
    }

    function getMarketInfo(
        uint256 id
    ) external view returns (MarketInfo memory) {
        return IdToMarketInfo[id];
    }

}
