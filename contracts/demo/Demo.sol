// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IWETH} from "../interfaces/IWETH.sol";
import {IUniSwapV3Router} from "../interfaces/uniswapV3/IUniSwapV3Router.sol";
import {IVineUniswapCore} from "../interfaces/IVineUniswapCore.sol";

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

    receive() external payable {}

    function inL2Supply(
        address l2Pool,
        address usdc,
        uint256 amount
    ) external {
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
        uint256 ausdcAmount
    ) external {
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeWithdrawParams(
            ausdc,
            ausdcAmount
        );
        IERC20(ausdc).approve(l2Pool, ausdcAmount);
        IL2Pool(l2Pool).withdraw(encodeMessage);
    }

    function inL2Borrow(
        address asset,
        address vToken,
        address wrappedTokenGateway,
        address l2Pool,
        uint256 amount,
        uint256 interestRateMode
    ) external {
        IDebtTokenBase(vToken).approveDelegation(wrappedTokenGateway, type(uint64).max);
        IWrappedTokenGatewayV3(wrappedTokenGateway).borrowETH(l2Pool, amount, interestRateMode, referralCode);
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

    function doETH(uint8 way, address weth, uint256 amount) external {
        if (way == 0) {
            IWETH(weth).withdraw(amount);
        } else {
            IWETH(weth).deposit{value: amount}();
        }
    }

    function v3Swap(V3SwapParams calldata params) external returns (uint256 amountOut) {
        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);
        IERC20(params.tokenIn).approve(params.v3Router, params.amountIn);
        IUniSwapV3Router.ExactInputSingleParams memory v3Params = IUniSwapV3Router
            .ExactInputSingleParams({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                fee: params.fee,
                recipient: address(this),
                deadline: params.deadline + uint64(block.timestamp),
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        amountOut = IUniSwapV3Router(params.v3Router).exactInputSingle(v3Params);
    }


    function _bytes32ToAddress(
        bytes32 _bytes32Account
    ) private pure returns (address) {
        return address(uint160(uint256(_bytes32Account)));
    }


}
