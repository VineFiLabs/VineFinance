// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IShareToken{
    function depositeMint(address to, uint256 amount) external returns(bytes1 _state);

    function withdrawBurn(address to, uint256 amount) external returns(bytes1 _state);

    function balanceOf(address account) external view returns (uint256);

    function decimals()external view returns(uint8);
    
    function totalSupply() external view returns (uint256);
}