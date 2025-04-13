// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVineSwapCore{

    struct V3LiquidityParams {
        address nonfungiblePositionManager;
        uint256 tokenId;
        address token0;
        address token1;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 amountAdd0;
        uint256 amountAdd1;
    }

    
    struct V2LiquidityParams {
        address v2Router;
        address tokenA;
        address tokenB;
        uint256 amountAIn;
        uint256 amountBIn;
        uint256 amountAOutMin;
        uint256 amountBOutMin;
        uint32 deadline;
    }

    struct RemoveV2LiquidityParams {
        address v2Router;
        address tokenA;
        address tokenB;
        uint256 liquidity;
        uint256 amountAOutMin;
        uint256 amountBOutMin;
        uint32 deadline;
    }

    struct V3SwapParams {
        address v3Router;
        address weth;
        uint24 fee;
        uint32 deadline;
        uint160 sqrtPriceLimitX96;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    
    struct V2SwapParams {
        address v2Router;
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
        uint32 deadline;
    }

}