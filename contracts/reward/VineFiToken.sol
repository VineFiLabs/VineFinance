// SPDX-License-Identifier: GPL-3.0
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VineFiToken is ERC20, Ownable, ERC20Permit, ERC20Votes {

    uint8 private currentDecimals = 18;
    uint256 private immutable limitTotalSupply = 500_000_000 ether;

    constructor(address initialOwner)
        ERC20("VineFi Token", "V")
        Ownable(initialOwner)
        ERC20Permit("VineFi Token")
    {}

    function mint(address to, uint256 amount) public onlyOwner {
        require(ERC20.totalSupply() + amount <= limitTotalSupply, "Overflow");
        _mint(to, amount);
    }

    function decimals() public view override(ERC20) returns(uint8) {
        return currentDecimals;
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address thisOwner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(thisOwner);
    }
}
