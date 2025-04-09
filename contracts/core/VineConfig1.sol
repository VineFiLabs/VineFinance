// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IVineConfig1} from "../interfaces/core/IVineConfig1.sol";

contract VineConfig1 is IVineConfig1{

    address public owner;
    address public manager;

    constructor(address _owner, address _manager) {
        owner = _owner;
        manager = _manager;
    }

    mapping(uint8 => calleeInfo) private CalleeInfo;

    function setCalleeInfo(
        uint8 id, 
        address _mainToken,
        address _derivedToken,
        address _callee,
        address _otherCaller,
        address _rewardProxyReceiver
    ) external {
        require(msg.sender == manager, "Non manager");
        CalleeInfo[id] = calleeInfo({
            mainToken: _mainToken,
            derivedToken: _derivedToken,
            callee: _callee,
            otherCaller: _otherCaller,
            rewardProxyReceiver: _rewardProxyReceiver
        });
    }

    function changeOwner(address _newOwner) external {
        require(msg.sender == owner, "Non owner");
        owner = _newOwner;
    }

    function changeManager(address _newManager) external {
        require(msg.sender == owner, "Non owner");
        manager = _newManager;
    } 

    function getCalleeInfo(uint8 indexConfig) external view returns(calleeInfo memory){
        return CalleeInfo[indexConfig];
    }
    
}
