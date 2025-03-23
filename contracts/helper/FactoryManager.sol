// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

abstract contract FactoryManager {
    address public factoryManager;
    constructor(address _factoryManager){
        factoryManager = _factoryManager;
    }

    modifier onlyManager(){
        _checkFactoryManager();
        _;
    }

    function _checkFactoryManager()internal view {
        require(msg.sender == factoryManager, "Non factory manager");
    }

    function changeFactoryManager(address newFactoryManager)external onlyManager{
        factoryManager = newFactoryManager;
    }
}