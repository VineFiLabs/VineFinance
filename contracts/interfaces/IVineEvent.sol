// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IVineEvent{
    event UserDeposite(address indexed _user,uint256 indexed _amount);
    event UserWithdraw(address indexed _user,uint256 indexed _amount);
    event L2Supply(uint256 amount);
    event L2withdraw(uint256 _usdcAmount,uint256 _ausdcAmount);

    event CrossUSDC(address indexed _receiver,uint256 amount);
    event ReceiveMessage(address indexed receiver,address indexed token,uint256 indexed amount);

    event UpdateFee(uint16 oldFee, uint16 newFee);
    event UpdateTime(uint64 _bufferTime, uint64 _endTime);
}