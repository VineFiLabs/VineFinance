// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IWETH} from "../interfaces/IWETH.sol";
import {IUniSwapV3Router} from "../interfaces/uniswapV3/IUniSwapV3Router.sol";
import {IVineUniswapCore} from "../interfaces/hook/uniswap/IVineUniswapCore.sol";


import {ICometMainInterface} from "../interfaces/compound/ICometMainInterface.sol";
import {ICometRewards} from "../interfaces/compound/ICometRewards.sol";

import {IPool} from "../interfaces/aaveV3/IPool.sol";
import {IL2Pool} from "../interfaces/aaveV3/IL2Pool.sol";
import {IL2Encode} from "../interfaces/aaveV3/IL2Encode.sol";
import {IDebtTokenBase} from "../interfaces/aaveV3/IDebtTokenBase.sol";
import {IWrappedTokenGatewayV3} from "../interfaces/aaveV3/IWrappedTokenGatewayV3.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Demo is IVineUniswapCore{
    using SafeERC20 for IERC20;

    uint16 referralCode;
    address public l2Encode;

    constructor(address _l2Encode){
        l2Encode = _l2Encode;
    }

    // receive() external payable {}

    function changeL2Encode(address _l2Encode) external {
        l2Encode = _l2Encode;
    }

    // function aaveSupply(address pool, address usdc, address receiver,uint256 amount) external {
    //     IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
    //     IERC20(usdc).approve(pool, amount);
    //     IPool(pool).supply(usdc, amount, receiver, referralCode);
    // }

    // function aaveWithdraw(address pool, address ausdc, address receiver, uint256 amount) external {
    //     if(receiver != address(this)){
    //         IERC20(ausdc).safeTransferFrom(msg.sender, address(this), amount);
    //     }
    //     IERC20(ausdc).approve(pool, amount);
    //     IPool(pool).withdraw(ausdc, amount, receiver);
    // }

    function callAave1(address caller, address pool, address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(pool, amount);
        bytes memory payload = abi.encodeCall(
            IPool(pool).supply,
            (token, amount, msg.sender, referralCode )
        );
        (bool success, ) = caller.call{value: 0}(payload);
        require(success, "call fail");
    }

    function callAave2(address caller, address pool, address token, address receiver, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(pool, amount);
        bytes memory payload = abi.encodeCall(
            IPool(pool).withdraw,
            (token, amount, receiver)
        );
        (bool success, ) = caller.call{value: 0}(payload);
        require(success, "call fail");
    }

    function callAave3(address caller, address pool, address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(pool, amount);
         bytes32 encodeMessage = IL2Encode(l2Encode).encodeSupplyParams(
            token,
            amount,
            referralCode
        );
        bytes memory payload = abi.encodeCall(
            IL2Pool(pool).supply,
            (encodeMessage)
        );
        (bool success, ) = caller.call{value: 0}(payload);
        require(success, "call fail");
    }

    function callAave4(address caller, address pool, address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(pool, amount);
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeWithdrawParams(
            token,
            amount
        );
        bytes memory payload = abi.encodeCall(
             IL2Pool(pool).withdraw,
            (encodeMessage)
        );
        (bool success, ) = caller.call{value: 0}(payload);
        require(success, "call fail");
    }

    // function inL2Supply(
    //     address l2Pool,
    //     address usdc,
    //     uint256 amount
    // ) external {
    //     IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
    //     bytes32 encodeMessage = IL2Encode(l2Encode).encodeSupplyParams(
    //         usdc,
    //         amount,
    //         referralCode
    //     );
    //     IERC20(usdc).approve(l2Pool, amount);
    //     IL2Pool(l2Pool).supply(encodeMessage);
    // }

    // function inL2Withdraw(
    //     address l2Pool,
    //     address ausdc,
    //     uint256 ausdcAmount
    // ) external {
    //     bytes32 encodeMessage = IL2Encode(l2Encode).encodeWithdrawParams(
    //         ausdc,
    //         ausdcAmount
    //     );
    //     IERC20(ausdc).safeTransferFrom(msg.sender, address(this), ausdcAmount);
    //     IERC20(ausdc).approve(l2Pool, ausdcAmount);
    //     IL2Pool(l2Pool).withdraw(encodeMessage);
    // }

    // function inL2Borrow(
    //     address vToken,
    //     address wrappedTokenGateway,
    //     address l2Pool,
    //     uint256 amount,
    //     uint256 interestRateMode
    // ) external {
    //     IDebtTokenBase(vToken).approveDelegation(wrappedTokenGateway, type(uint64).max);
    //     IWrappedTokenGatewayV3(wrappedTokenGateway).borrowETH(l2Pool, amount, interestRateMode, referralCode);
    // }

    // function inL2Repay(
    //     address asset,
    //     address l2Pool,
    //     uint256 amount,
    //     uint256 interestRateMode
    // ) external {
    //     bytes32 encodeMessage = IL2Encode(l2Encode).encodeRepayParams(
    //         asset,
    //         amount,
    //         interestRateMode
    //     );
    //     IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
    //     IERC20(asset).approve(l2Pool, amount);
    //     IL2Pool(l2Pool).repay(encodeMessage);
    // }

    // function compoundSupply(address cometAddress, address asset, uint256 amount) external {
    //     IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
    //     IERC20(asset).approve(cometAddress, amount);
    //     ICometMainInterface(cometAddress).supply(asset, amount);
    // }

    // function compoundWithdraw(address cometAddress, address asset, uint256 amount) external {
    //     ICometMainInterface(cometAddress).withdraw(asset, amount);
    // }

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
    //     IUniSwapV3Router.ExactInputSingleParams memory v3Params = IUniSwapV3Router
    //         .ExactInputSingleParams({
    //             tokenIn: params.tokenIn,
    //             tokenOut: params.tokenOut,
    //             fee: params.fee,
    //             recipient: address(this),
    //             deadline: params.deadline + uint64(block.timestamp),
    //             amountIn: params.amountIn,
    //             amountOutMinimum: params.amountOutMinimum,
    //             sqrtPriceLimitX96: 0
    //         });
    //     amountOut = IUniSwapV3Router(params.v3Router).exactInputSingle(v3Params);
    // }


    // function _bytes32ToAddress(
    //     bytes32 _bytes32Account
    // ) private pure returns (address) {
    //     return address(uint160(uint256(_bytes32Account)));
    // }


}
