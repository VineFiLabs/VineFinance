// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVineEvent{

    event UserDeposite(uint256 indexed id, address indexed user,uint256  amount);
    event UserWithdraw(uint256 indexed id, address indexed user,uint256  amount);
    event AaveV3Supply(uint256 indexed id, uint256 amount);
    event AaveV3Withdraw(uint256 indexed id, uint256 amount);

    event CrossUSDC(address indexed _receiver,uint256 amount);
    event ReceiveMessage(address indexed receiver,address indexed token,uint256 indexed amount);
    event Emergency(uint256 indexed id, uint256 time);

    event UpdateFee(uint16 oldFee, uint16 newFee);
    event UpdateTime(uint64 bufferTime, uint64 endTime);
}