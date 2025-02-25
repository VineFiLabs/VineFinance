// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVineUniswapCore{

    struct V3LiquidityInfo {
        address tokenA;
        address tokenB;
        uint256 addAmountA;
        uint256 addAmountB;
        uint256 removeAmountA;
        uint256 removeAmountB;
        uint256 collectAmountA;
        uint256 collectAmountB;
        uint256 liquidityAmount;
        uint256 lastestTime;
    }

    struct V2LiquidityInfo {
        address tokenA;
        address tokenB;
        uint256 addAmountA;
        uint256 addAmountB;
        uint256 removeAmountA;
        uint256 removeAmountB;
        uint256 lpAmount;
        uint256 lastestTime;
    }

    struct AddV3LiquidityParams {
        uint32 deadline;
        address nonfungiblePositionManager;
        uint256 tokenId;
        address tokenA;
        address tokenB;
        uint256 amountAIn;
        uint256 amountBIn;
        uint256 amountAMin;
        uint256 amountBMin;
    }

    struct RemoveV3LiquidityParams {
        uint32 deadline;
        address nonfungiblePositionManager;
        address nftAddress;
        uint128 liquidity;
        uint256 tokenId;
        uint256 amountAMin;
        uint256 amountBMin;
    }

    
    struct V2LiquidityParams {
        uint32 deadline;
        address v2Router;
        address v2Factory;
        address tokenA;
        address tokenB;
        uint256 amountAIn;
        uint256 amountBIn;
        uint256 amountAOutMin;
        uint256 amountBOutMin;
    }

    struct RemoveV2LiquidityParams {
        uint32 deadline;
        address v2Router;
        address v2Factory;
        address lpToken;
        address tokenA;
        address tokenB;
        uint256 liquidity;
        uint256 amountAOutMin;
        uint256 amountBOutMin;
    }

}