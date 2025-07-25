// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IWETH} from "../interfaces/IWETH.sol";
import {IV3SwapRouter} from "../interfaces/uniswapV3/IV3SwapRouter.sol";

import {IV3SwapRouter} from "../interfaces/uniswapV3/IV3SwapRouter.sol";
import {INonfungiblePositionManager} from "../interfaces/uniswapV3/INonfungiblePositionManager.sol";
import {IUniswapV3Factory} from "../interfaces/uniswapV3/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "../interfaces/uniswapV3/IUniswapV3Pool.sol";
import {IPoolInitializer} from "../interfaces/uniswapV3/IPoolInitializer.sol";
import {IERC721Receiver} from "../interfaces/uniswapV3/IERC721Receiver.sol";
import {IWETH} from "../interfaces/IWETH.sol";

import {ICometMainInterface} from "../interfaces/compound/ICometMainInterface.sol";
import {ICometRewards} from "../interfaces/compound/ICometRewards.sol";

import {IMorpho, MarketParams, Position, Market, Authorization, Id} from "../interfaces/morpho/IMorpho.sol";
import {IMorphoReward} from "../interfaces/morpho/IMorphoReward.sol";

import {IPool} from "../interfaces/aaveV3/IPool.sol";
import {IL2Pool} from "../interfaces/aaveV3/IL2Pool.sol";
import {IL2Encode} from "../interfaces/aaveV3/IL2Encode.sol";
import {IDebtTokenBase} from "../interfaces/aaveV3/IDebtTokenBase.sol";
import {IWrappedTokenGatewayV3} from "../interfaces/aaveV3/IWrappedTokenGatewayV3.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Demo is IERC721Receiver {
    using SafeERC20 for IERC20;

    uint16 referralCode;
    address public l2Encode;

    constructor(address _l2Encode) {
        l2Encode = _l2Encode;
    }

    // receive() external payable {}

    function changeL2Encode(address _l2Encode) external {
        l2Encode = _l2Encode;
    }

    function getV3Pool(
        address v3factory,
        address token0,
        address token1,
        uint24 poolFee
    ) external view returns (address) {
        return IUniswapV3Factory(v3factory).getPool(token0, token1, poolFee);
    }

    struct CreatePoolAndInit {
        address nonfungiblePositionManager;
        address token0;
        address token1;
        uint24 poolFee;
        uint160 sqrtPriceX96;
    }

    function createPool(
        CreatePoolAndInit memory params
    ) public returns (bytes1 state) {
        (address token0, address token1) = getTokenContracts(
            params.token0,
            params.token1
        );
        address pool = IPoolInitializer(params.nonfungiblePositionManager)
            .createAndInitializePoolIfNecessary(
                token0,
                token1,
                params.poolFee,
                params.sqrtPriceX96
            );
        state = 0x01;
    }

    struct MintNewPositionParams {
        address nonfungiblePositionManager;
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint24 poolFee;
        uint256 token0Amount;
        uint256 token1Amount;
    }

    function mintLiquidityPool(MintNewPositionParams calldata params) public {
        IERC20(params.token0).safeTransferFrom(
            msg.sender,
            address(this),
            params.token0Amount
        );
        IERC20(params.token1).safeTransferFrom(
            msg.sender,
            address(this),
            params.token1Amount
        );
        IERC20(params.token0).approve(
            params.nonfungiblePositionManager,
            params.token0Amount
        );
        IERC20(params.token1).approve(
            params.nonfungiblePositionManager,
            params.token1Amount
        );
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
        // Create the liquidity position
        INonfungiblePositionManager.MintParams
            memory mintParams = INonfungiblePositionManager.MintParams({
                token0: params.token0,
                token1: params.token1,
                fee: params.poolFee,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: params.token0Amount,
                amount1Desired: params.token1Amount,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 30
            });
        (tokenId, liquidity, amount0, amount1) = INonfungiblePositionManager(
            params.nonfungiblePositionManager
        ).mint(mintParams);
    }

    function createAndMintLiquidity(
        CreatePoolAndInit calldata createParams,
        MintNewPositionParams calldata mintpParams
    ) external {
        bytes1 state1 = createPool(createParams);
        require(state1 == 0x01, "Create pool fail");
        mintLiquidityPool(mintpParams);
    }

    function aaveSupply(
        address pool,
        address usdc,
        address receiver,
        uint256 amount
    ) external {
        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(usdc).approve(pool, amount);
        IPool(pool).supply(usdc, amount, receiver, referralCode);
    }

    function aaveWithdraw(
        address pool,
        address ausdc,
        address usdc,
        address receiver,
        uint256 amount
    ) external {
        if (receiver != address(this)) {
            IERC20(ausdc).safeTransferFrom(msg.sender, address(this), amount);
        }
        IERC20(ausdc).approve(pool, amount);
        IPool(pool).withdraw(usdc, amount, receiver);
    }

    function callAave1(
        address caller,
        address token,
        address receiver,
        uint256 amount
    ) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(caller, amount);
        bytes memory payload = abi.encodeCall(
            IPool(caller).supply,
            (token, amount, receiver, referralCode)
        );
        (bool success, ) = caller.call{value: 0}(payload);
        require(success, "call fail");
    }

    function callAave2(
        address caller,
        address token,
        address receiver,
        uint256 amount
    ) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(caller, amount);
        bytes memory payload = abi.encodeCall(
            IPool(caller).withdraw,
            (token, amount, receiver)
        );
        (bool success, ) = caller.call{value: 0}(payload);
        require(success, "call fail");
    }

    function callAave3(address caller, address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(caller, amount);
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeSupplyParams(
            token,
            amount,
            referralCode
        );
        bytes memory payload = abi.encodeCall(
            IL2Pool(caller).supply,
            (encodeMessage)
        );
        (bool success, ) = caller.call{value: 0}(payload);
        require(success, "call fail");
    }

    function callAave4(address caller, address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(caller, amount);
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeWithdrawParams(
            token,
            amount
        );
        bytes memory payload = abi.encodeCall(
            IL2Pool(caller).withdraw,
            (encodeMessage)
        );
        (bool success, ) = caller.call{value: 0}(payload);
        require(success, "call fail");
    }

    function inL2Supply(address l2Pool, address usdc, uint256 amount) external {
        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeSupplyParams(
            usdc,
            amount,
            referralCode
        );
        IERC20(usdc).approve(l2Pool, amount);
        IL2Pool(l2Pool).supply(encodeMessage);
    }

    function inL2Withdraw(
        address l2Pool,
        address ausdc,
        address usdc,
        uint256 ausdcAmount
    ) external {
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeWithdrawParams(
            usdc,
            ausdcAmount
        );
        IERC20(ausdc).safeTransferFrom(msg.sender, address(this), ausdcAmount);
        IERC20(ausdc).approve(l2Pool, ausdcAmount);
        IL2Pool(l2Pool).withdraw(encodeMessage);
    }

    function inL2Borrow(
        address vToken,
        address wrappedTokenGateway,
        address l2Pool,
        uint256 amount,
        uint256 interestRateMode
    ) external {
        IDebtTokenBase(vToken).approveDelegation(
            wrappedTokenGateway,
            type(uint64).max
        );
        IWrappedTokenGatewayV3(wrappedTokenGateway).borrowETH(
            l2Pool,
            amount,
            interestRateMode,
            referralCode
        );
    }

    function inL2Repay(
        address asset,
        address l2Pool,
        uint256 amount,
        uint256 interestRateMode
    ) external {
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeRepayParams(
            asset,
            amount,
            interestRateMode
        );
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(l2Pool, amount);
        IL2Pool(l2Pool).repay(encodeMessage);
    }

    function compoundSupply(
        address cometAddress,
        address asset,
        uint256 amount
    ) external {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(cometAddress, amount);
        ICometMainInterface(cometAddress).supply(asset, amount);
    }

    function compoundWithdraw(
        address cometAddress,
        address asset,
        uint256 amount
    ) external {
        ICometMainInterface(cometAddress).withdraw(asset, amount);
    }

    function morphoSupply(
        MarketParams memory marketParams,
        address morphoMarket,
        uint256 amount,
        uint256 shares
    ) external {
        IERC20(marketParams.loanToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(marketParams.loanToken).approve(morphoMarket, amount);
        (uint256 assetsSupplied, uint256 sharesSupplied) = IMorpho(morphoMarket)
            .supply(marketParams, amount, shares, address(this), hex"");
    }

    
    function morphoWithdraw(
        MarketParams memory marketParams,
        address morphoMarket,
        uint256 amount,
        uint256 shares
    ) external {
         bytes memory payload = abi.encodeCall(
            IMorpho(morphoMarket).withdraw,
            (marketParams, amount, shares, address(this), address(this))
        );
        (bool success,)= morphoMarket.call(payload);
        require(success, "Morpho withdraw fail");
    }

    function getIdToMarketParams(
        Id morphoId,
        address morphoMarket
    )public view returns (MarketParams memory)
    {   
        return IMorpho(morphoMarket).idToMarketParams(morphoId);
    }

    function getPosition(
        Id morphoId,
        address user,
        address morphoMarket
    ) external view returns (Position memory) {
        return IMorpho(morphoMarket).position(morphoId, user);
    }


    // /*
    // * Get the current supply APR in Compound III
    // */
    // function getSupplyApr(address cometAddress) external view returns (uint256) {
    //     uint256 utilization = ICometMainInterface(cometAddress).getUtilization();
    //     uint256 supplyApr = ICometMainInterface(cometAddress).getSupplyRate(utilization) * 100 * 365 days;
    //     return supplyApr;
    // }

    // /*
    // * Get the current reward for supplying APR in Compound III
    // * @param rewardTokenPriceFeed The address of the reward token (e.g. COMP) price feed
    // * @return The reward APR in USD as a decimal scaled up by 1e18
    // */
    // function getRewardAprForSupplyBase(address cometAddress, address rewardTokenPriceFeed) external view returns (uint256) {
    //     uint256 rewardTokenPriceInUsd = ICometMainInterface(cometAddress).getPrice(rewardTokenPriceFeed);
    //     uint256 usdcPriceInUsd = ICometMainInterface(cometAddress).getPrice((ICometMainInterface(cometAddress).baseTokenPriceFeed()));
    //     uint256 usdcTotalSupply = ICometMainInterface(cometAddress).totalSupply();
    //     uint256 baseTrackingSupplySpeed = ICometMainInterface(cometAddress).baseTrackingSupplySpeed();
    //     uint256 base_mantissa = ICometMainInterface(cometAddress).baseScale();
    //     uint256 base_index_scale = ICometMainInterface(cometAddress).baseIndexScale();
    //     uint256 rewardToSuppliersPerDay = baseTrackingSupplySpeed * 1 days * (base_index_scale / base_mantissa);
    //     uint256 supplyBaseRewardApr = (rewardTokenPriceInUsd * rewardToSuppliersPerDay / (usdcTotalSupply * usdcPriceInUsd)) * 365;
    //     return supplyBaseRewardApr;
    // }

    // /*
    // * Claims the reward tokens due to this contract address
    // */
    // function claimCometRewards(address cometAddress, address rewardsContract) external {
    //     ICometRewards(rewardsContract).claim(cometAddress, address(this), true);
    // }

    // function doETH(uint8 way, address weth, uint256 amount) external {
    //     if (way == 0) {
    //         IWETH(weth).withdraw(amount);
    //     } else {
    //         IWETH(weth).deposit{value: amount}();
    //     }
    // }

    // function v3Swap(V3SwapParams calldata params) external returns (uint256 amountOut) {
    //     IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);
    //     IERC20(params.tokenIn).approve(params.v3Router, params.amountIn);
    //     IV3SwapRouter.ExactInputSingleParams memory v3Params = IV3SwapRouter
    //         .ExactInputSingleParams({
    //             tokenIn: params.tokenIn,
    //             tokenOut: params.tokenOut,
    //             fee: params.fee,
    //             recipient: address(this),
    //             amountIn: params.amountIn,
    //             amountOutMinimum: params.amountOutMinimum,
    //             sqrtPriceLimitX96: 0
    //         });
    //     amountOut = IV3SwapRouter(params.v3Router).exactInputSingle(v3Params);
    // }

    // function _bytes32ToAddress(
    //     bytes32 _bytes32Account
    // ) private pure returns (address) {
    //     return address(uint160(uint256(_bytes32Account)));
    // }

    function getTokenContracts(
        address tokenA,
        address tokenB
    ) public view returns (address _tokenA, address _tokenB) {
        _tokenA = tokenA < tokenB ? tokenA : tokenB;
        _tokenB = tokenA < tokenB ? tokenB : tokenA;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
