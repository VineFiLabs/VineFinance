// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.23;

// import "./VineUniswapV2Core.sol";
// import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
// import {IFactorySharer} from "../../interfaces/IFactorySharer.sol";

// contract VineUniswapV2Factory is IFactorySharer {
//     address public govern;

//     constructor(address _govern) {
//         govern = _govern;
//     }

//     mapping(address => bool) public ValidMarket;

//     mapping(uint256 => address) internal UserIdToHook;

//     event CreateUniswapMarketEvent(
//         address indexed creator,
//         uint256 indexed marketId,
//         address market
//     );

//     function createUniSwapMarket(address owner, address manager) external {
//         uint256 id = IVineHookCenter(govern).getCuratorToId(msg.sender);
//         require(UserIdToHook[id] == address(0), "Already create");
//         address swapMarket = address(
//             new VineUniswapV2Core{
//                 salt: keccak256(abi.encodePacked(id, msg.sender))
//             }(owner, manager, govern, id)
//         );
//         ValidMarket[swapMarket] = true;
//         UserIdToHook[id] = swapMarket;
//         require(swapMarket != address(0));
//         emit CreateUniswapMarketEvent(msg.sender, id, swapMarket);
//     }

//     function getUserIdToHook(uint256 _id)external view returns(address){
//         return UserIdToHook[_id];
//     }
// }
