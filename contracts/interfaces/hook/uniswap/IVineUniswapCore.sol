// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVineUniswapCore{
    
    event CreatePoolEvent(address indexed newPool, uint160 sqrtPriceX96);
    event MintEvent(uint256 indexed _tokenId, uint256 liquidityAmount);
    event CollectFeesEvent(
        uint256 indexed _tokenId,
        uint256 amount0,
        uint256 amount1
    );
    event AddV3LiquidityEvent(
        uint256 indexed _tokenId,
        uint256 amount0,
        uint256 amount1
    );
    event RemoveV3LiquidityEvent(
        uint256 indexed _tokenId,
        uint256 liquidityAmount
    );

    // struct V3LiquidityInfo {
    //     address tokenA;
    //     address tokenB;
    //     uint256 addAmountA;
    //     uint256 addAmountB;
    //     uint256 removeAmountA;
    //     uint256 removeAmountB;
    //     uint256 collectAmountA;
    //     uint256 collectAmountB;
    //     uint256 liquidityAmount;
    //     uint256 lastestTime;
    // }

    // struct V2LiquidityInfo {
    //     address tokenA;
    //     address tokenB;
    //     uint256 addAmountA;
    //     uint256 addAmountB;
    //     uint256 removeAmountA;
    //     uint256 removeAmountB;
    //     uint256 lpAmount;
    //     uint256 lastestTime;
    // }

    // struct AddV3LiquidityParams {
    //     uint32 deadline;
    //     address nonfungiblePositionManager;
    //     uint256 tokenId;
    //     address tokenA;
    //     address tokenB;
    //     uint256 amountAIn;
    //     uint256 amountBIn;
    //     uint256 amountAMin;
    //     uint256 amountBMin;
    // }

    // struct RemoveV3LiquidityParams {
    //     uint32 deadline;
    //     address nonfungiblePositionManager;
    //     address nftAddress;
    //     uint128[] liquiditys;
    //     uint256[] tokenIds;
    //     uint256[] amountAMins;
    //     uint256[] amountBMins;
    // }

    
    // struct V2LiquidityParams {
    //     uint32 deadline;
    //     address v2Router;
    //     address v2Factory;
    //     address v2Pool;
    //     address tokenA;
    //     address tokenB;
    //     uint256 amountAIn;
    //     uint256 amountBIn;
    //     uint256 amountAOutMin;
    //     uint256 amountBOutMin;
    // }

    // struct RemoveV2LiquidityParams {
    //     uint32 deadline;
    //     address v2Router;
    //     address v2Factory;
    //     address lpToken;
    //     address tokenA;
    //     address tokenB;
    //     uint256 liquidity;
    //     uint256 amountAOutMin;
    //     uint256 amountBOutMin;
    // }


    // 

    // struct V3SwapParams {
    //     uint24 fee;
    //     address tokenIn;
    //     address tokenOut;
    //     uint256 amountIn;
    //     uint256 amountOutMinimum;
    //     address v3Router;
    // }

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
        bool exist;
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
        uint256 id;
        uint8 indexConfig;
        uint256 tokenId;
        uint256 token0Amount;
        uint256 token1Amount;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    struct RemoveV3LiquidityParams {
        uint256 id;
        uint8 indexConfig;
        uint128[] liquiditys;
        uint256[] tokenIds;
        uint256[] amountAMins;
        uint256[] amountBMins;
    }

    
    struct V2LiquidityParams {
        uint32 deadline;
        address v2Router;
        address v2Factory;
        address v2Pool;
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

    
    struct CreatePoolAndInit {
        address nonfungiblePositionManager;
        address token0;
        address token1;
        uint24 poolFee;
        uint160 sqrtPriceX96;
    }

    struct MintLiquidityPoolParams{
        uint256 id;
        uint8 indexConfig;
        uint24 poolFee;
        int24 tickLower;
        int24 tickUpper;
        uint256 token0Amount;
        uint256 token1Amount;
        uint256 amount0Min;
        uint256 amount1Min;
    }
    

    struct V3SwapParams {
        uint256 id;
        uint8 indexConfig;
        uint24 poolFee;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

}