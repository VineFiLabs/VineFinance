// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./VineAaveV3LendMain02.sol";
import {IGovernance} from "../../interfaces/core/IGovernance.sol";
import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

contract VineAaveV3LendMain02Factory is IFactorySharer{

    address public govern;

    constructor(address _govern) {
        govern = _govern;
    }

    mapping(address => bool) public ValidMarket;
    mapping(uint256 => address) internal UserIdToHook;

    event CreateAaveV3MainLendMarket(address indexed creator, uint256 indexed marketId, address market);

    function createMarket(address owner, address manager, string memory tokenName, string memory tokenSymbol) external {
        address currentUser = msg.sender;
        uint256 id=IGovernance(govern).getCuratorToId(currentUser);
        require(UserIdToHook[id] == address(0),"Already create");
        address aaveV3MainLendMarket = address(
            new VineAaveV3LendMain02{
                salt: keccak256(abi.encodePacked(id, currentUser))
            }(govern, owner, manager, id, tokenName, tokenSymbol)
        );
        require(aaveV3MainLendMarket != address(0));
        ValidMarket[aaveV3MainLendMarket]=true;
        UserIdToHook[id]=aaveV3MainLendMarket;
        emit CreateAaveV3MainLendMarket(currentUser, id, aaveV3MainLendMarket);
    }

    function getUserIdToHook(uint256 _id)external view returns(address){
        return UserIdToHook[_id];
    }

}
