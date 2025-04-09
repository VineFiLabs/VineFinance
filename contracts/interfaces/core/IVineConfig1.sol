// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.23;

interface IVineConfig1 {

    struct calleeInfo{
        address mainToken;
        address derivedToken;
        address callee;
        address otherCaller;
        address rewardProxyReceiver;
    }

    function getCalleeInfo(uint8 indexConfig) external view returns(calleeInfo memory);

}
