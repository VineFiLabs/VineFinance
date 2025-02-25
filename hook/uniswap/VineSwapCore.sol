// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {ICrossCenter} from "../../interfaces/ICrossCenter.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IUniswapV2Router01, IUniswapV2Router02} from "../../interfaces/uniswapV2/IUniswapV2Router02.sol";
import {IUniSwapV3Router} from "../../interfaces/uniswapV3/IUniSwapV3Router.sol";
import {INonfungiblePositionManager} from "../../interfaces/uniswapV3/INonfungiblePositionManager.sol";
import {IERC721Receiver} from "../../interfaces/IERC721Receiver.sol";
import {IWETH} from "../../interfaces/IWETH.sol";

import {IVineStruct} from "../../interfaces/IVineStruct.sol";
import {IVineSwapCore} from "../../interfaces/IVineSwapCore.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
import {ISharer} from "../../interfaces/ISharer.sol";


import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineSwapCore is
    ReentrancyGuard,
    IVineStruct,
    IVineSwapCore,
    IVineEvent,
    IVineHookErrors,
    IERC721Receiver,
    ISharer,
    IWormholeReceiver
{
    using SafeERC20 for IERC20;

    uint256 public id;
    address public factory;
    address public owner;
    address public manager;
    address public govern;
    uint256 public emergencyTime;


    constructor(address _owner, address _manager, address _govern, uint256 _id) {
        factory = msg.sender;
        owner = _owner;
        manager = _manager;
        govern = _govern;
        id = _id;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }

    function transferOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function transferManager(address newManager) external onlyOwner {
        manager = newManager;
    }

    function addV3Liquidity(
        V3LiquidityParams calldata params
    ) external onlyManager returns (uint128 liquidity) {
        IERC20(params.token0).approve(
            params.nonfungiblePositionManager,
            params.amountAdd0
        );
        IERC20(params.token1).approve(
            params.nonfungiblePositionManager,
            params.amountAdd1
        );
        INonfungiblePositionManager.IncreaseLiquidityParams
            memory increaseLiquidityParams = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: params.tokenId,
                    amount0Desired: params.amountAdd0,
                    amount1Desired: params.amountAdd1,
                    amount0Min: params.amount0Min,
                    amount1Min: params.amount1Min,
                    deadline: block.timestamp + 30
                });

        (liquidity, , ) = INonfungiblePositionManager(
            params.nonfungiblePositionManager
        ).increaseLiquidity(increaseLiquidityParams);
    }

    function addV2ETHLiquidity(
        V2LiquidityParams calldata params
    ) external onlyManager{
        IERC20(params.tokenB).approve(params.v2Router, params.amountBIn);
        IUniswapV2Router01(params.v2Router).addLiquidityETH{
            value: params.amountAIn
        }(
            params.tokenB,
            params.amountBIn,
            params.amountBOutMin,
            params.amountAOutMin, //eth amountOutMin
            address(this),
            uint256(params.deadline) + block.timestamp
        );
    }

    function addV2Liquidity(V2LiquidityParams calldata params) external onlyManager{
        IERC20(params.tokenA).approve(params.v2Router, params.amountAIn);
        IERC20(params.tokenB).approve(params.v2Router, params.amountBIn);
        IUniswapV2Router01(params.v2Router).addLiquidity(
            params.tokenA,
            params.tokenB,
            params.amountAIn,
            params.amountBIn,
            params.amountAOutMin,
            params.amountBOutMin,
            address(this),
            uint256(params.deadline) + block.timestamp
        );
    }

    function removeV2ETHLiquidity(
        RemoveV2LiquidityParams calldata params
    ) external{
        require(msg.sender == manager || (block.timestamp > emergencyTime && emergencyTime > 0), "Non manager or not emergency time");
        IUniswapV2Router01(params.v2Router).removeLiquidityETH(
            params.tokenB,
            params.liquidity,
            params.amountBOutMin,
            params.amountAOutMin, //eth amountOutMin
            address(this),
            uint256(params.deadline) + block.timestamp
        );
    }

    function removeV2Liquidity(
        RemoveV2LiquidityParams calldata params
    ) external {
        require(msg.sender == manager || (block.timestamp > emergencyTime && emergencyTime > 0), "Non manager or not emergency time");
        IUniswapV2Router01(params.v2Router).removeLiquidity(
            params.tokenA,
            params.tokenB,
            params.liquidity,
            params.amountAOutMin,
            params.amountBOutMin,
            address(this),
            uint256(params.deadline) + block.timestamp
        );
    }

    function v3Swap(V3SwapParams calldata params) external onlyManager{
        address _tokenIn = params.tokenIn;
        address _tokenOut = params.tokenOut;
        if (params.tokenIn == address(0)) {
            _tokenIn = params.weth;
            IWETH(params.weth).deposit{value: params.amountIn}();
        } else if (params.tokenOut == address(0)) {
            _tokenOut = params.weth;
        }
        IERC20(_tokenIn).approve(params.v3Router, params.amountIn);

        IUniSwapV3Router.ExactInputSingleParams memory v3Params = IUniSwapV3Router
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: params.fee,
                recipient: address(this),
                deadline: block.timestamp + uint256(params.deadline),
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOutMinimum,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            });
        uint256 amountOut = IUniSwapV3Router(params.v3Router).exactInputSingle(v3Params);
    }

    function v2Swap(V2SwapParams calldata params) external onlyManager{
        if (params.path[0] == address(0)) {
            IUniswapV2Router01(params.v2Router).swapExactETHForTokens{
                value: params.amountIn
            }(
                params.amountOutMin,
                params.path,
                address(this),
                uint256(params.deadline) + block.timestamp
            );
        } else if (params.path[1] == address(0)) {
            IERC20(params.path[0]).approve(params.v2Router, params.amountIn);
            IUniswapV2Router01(params.v2Router).swapExactTokensForETH(
                params.amountIn,
                params.amountOutMin,
                params.path,
                address(this),
                uint256(params.deadline) + block.timestamp
            );
        } else {
            IERC20(params.path[0]).approve(params.v2Router, params.amountIn);
            IUniswapV2Router01(params.v2Router).swapExactTokensForTokens(
                params.amountIn,
                params.amountOutMin,
                params.path,
                address(this),
                uint256(params.deadline) + block.timestamp
            );
        }
    }

    function wrapETH(address weth,uint256 ethAmount)external onlyManager{
        IWETH(weth).deposit{value: ethAmount}();
    }

    function unWrapETH(address weth,uint256 wethAmount)external onlyManager{
        IWETH(weth).withdraw(wethAmount);
    }

    function crossUSDC(
        uint16 indexDestHook,
        uint32 destinationDomain,
        uint64 sendBlock,
        address usdc,
        uint256 amount
    ) public {
        require(msg.sender == manager || (block.timestamp > emergencyTime && emergencyTime > 0), "Non manager or not emergency time");
        bytes32 hook = _getValidHook(destinationDomain, indexDestHook);
        uint256 balance = _tokenBalance(usdc, address(this));
        if (balance == 0) {
            revert ZeroBalance(ErrorType.ZeroBalance);
        }
        address crossCenter = _crossCenter();
        IERC20(usdc).approve(crossCenter, amount);
        ICrossCenter(crossCenter).crossUSDC(
            destinationDomain,
            sendBlock,
            hook,
            usdc,
            amount
        );
    }

    function receiveUSDC(
        bytes calldata message,
        bytes calldata attestation
    ) external {
        address crossCenter = _crossCenter();
        ICrossCenter(crossCenter).receiveUSDC(message, attestation);
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32,
        uint16,
        bytes32
    ) external payable{
        (uint256 crossId, uint256 crossEmergencyTime) = abi.decode(payload, (uint256, uint256));
        emergencyTime = crossEmergencyTime;
        if(crossId != id){
            revert("Invalid id");
        }
        if(block.timestamp < crossEmergencyTime){
            revert("Not emergency time");
        }
    } 

    function _tokenBalance(
        address token,
        address user
    ) private view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = IERC20(token).balanceOf(user);
    }

    function _checkOwner() internal view {
        require(msg.sender == owner, "Non owner");
    }

    function _checkManager() internal view {
        require(msg.sender == manager, "Non manager");
    }

    function _getValidHook(uint32 destinationDomain, uint16 indexDestHook) private view returns(bytes32 validHook){
        validHook = IVineHookCenter(govern).getDestHook(id, destinationDomain, indexDestHook);
    }

    function _crossCenter() private view returns(address crossCenter){
        crossCenter = IVineHookCenter(govern).getMarketInfo(id).crossCenter;
    }

    function getTokenBalance(
        address token,
        address user
    ) external view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = _tokenBalance(token, user);
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
