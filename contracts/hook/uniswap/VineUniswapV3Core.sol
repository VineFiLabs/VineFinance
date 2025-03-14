// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IUniSwapV3Router} from "../../interfaces/uniswapV3/IUniSwapV3Router.sol";
import {INonfungiblePositionManager} from "../../interfaces/uniswapV3/INonfungiblePositionManager.sol";
import {IUniswapV3Factory} from "../../interfaces/uniswapV3/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "../../interfaces/uniswapV3/IUniswapV3Pool.sol";
import {IPoolInitializer} from "../../interfaces/uniswapV3/IPoolInitializer.sol";
import {IERC721Receiver} from "../../interfaces/IERC721Receiver.sol";
import {IWETH} from "../../interfaces/IWETH.sol";

import {IL2Pool} from "../../interfaces/aaveV3/IL2Pool.sol";
import {IL2Encode} from "../../interfaces/aaveV3/IL2Encode.sol";
import {IDebtTokenBase} from "../../interfaces/aaveV3/IDebtTokenBase.sol";
import {IWrappedTokenGatewayV3} from "../../interfaces/aaveV3/IWrappedTokenGatewayV3.sol";

import {ICrossCenter} from "../../interfaces/ICrossCenter.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IVineUniswapCore} from "../../interfaces/IVineUniswapCore.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
import {ISharer} from "../../interfaces/ISharer.sol";
import {VineLib} from "../../libraries/VineLib.sol";

import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineUniswapV3Core is
    IVineUniswapCore,
    IVineEvent,
    IVineHookErrors,
    IERC721Receiver,
    ISharer,
    IWormholeReceiver
{
    using SafeERC20 for IERC20;

    uint256 public id;
    uint16 private referralCode;
    uint32 public currentDomain;
    address public factory;
    address public owner;
    address public manager;
    address public govern;
    uint256 public emergencyTime;

    mapping(uint256 => V3LiquidityInfo) private v3LiquidityInfo;
    mapping(uint256 => bool) public tokenIdExists;

    //max save 50 id
    uint256[] private V3LiquidityTokenIds;

    constructor(
        address _govern,
        address _owner,
        address _manager,
        uint256 _id
    ) {
        factory = msg.sender;
        govern = _govern;
        owner = _owner;
        manager = _manager;
        id = _id;
        currentDomain = VineLib._currentDomain();
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }

    receive() external payable {}

    function transferOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function transferManager(address newManager) external onlyOwner {
        manager = newManager;
    }

    function setReferralCode(uint16 _referralCode) external onlyManager {
        referralCode = _referralCode;
    }

    function changeDomain(uint32 newDomain) external onlyManager {
        currentDomain = newDomain;
    }

    function getV3Pool(
        address v3factory,
        address token0,
        address token1,
        uint24 poolFee
    ) external view returns (address) {
        return IUniswapV3Factory(v3factory).getPool(token0, token1, poolFee);
    }

    function createPool(
        CreatePoolAndInit calldata params
    ) public onlyManager returns (bytes1 state) {
        address pool = IPoolInitializer(params.poolInitAddress)
            .createAndInitializePoolIfNecessary(
                params.token0,
                params.token1,
                params.poolFee,
                params.sqrtPriceX96
            );
        emit CreatePoolEvent(pool, params.sqrtPriceX96);
        state = 0x01;
    }

    function mintLiquidityPool(
        MintNewPositionParams calldata params
    ) public onlyManager {
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
        v3LiquidityInfo[tokenId].tokenA = params.token0;
        v3LiquidityInfo[tokenId].tokenB = params.token1;
        v3LiquidityInfo[tokenId].addAmountA += params.token0Amount;
        v3LiquidityInfo[tokenId].addAmountB += params.token1Amount;
        v3LiquidityInfo[tokenId].liquidityAmount += liquidity;
        v3LiquidityInfo[tokenId].lastestTime = block.timestamp;
        if (tokenIdExists[tokenId] == false) {
            if (V3LiquidityTokenIds.length <= 50) {
                V3LiquidityTokenIds.push(tokenId);
            }
        }
        tokenIdExists[tokenId] = true;

        emit MintEvent(tokenId, liquidity);
    }

    function createAndMintLiquidity(
        CreatePoolAndInit calldata createParams,
        MintNewPositionParams calldata mintpParams
    ) external onlyManager {
        bytes1 state1 = createPool(createParams);
        require(state1 == 0x01, "Create pool fail");
        mintLiquidityPool(mintpParams);
    }

    function addV3Liquidity(
        AddV3LiquidityParams calldata params
    ) external onlyManager {
        IERC20(params.tokenA).approve(
            params.nonfungiblePositionManager,
            params.amountAIn
        );
        IERC20(params.tokenB).approve(
            params.nonfungiblePositionManager,
            params.amountBIn
        );
        INonfungiblePositionManager.IncreaseLiquidityParams
            memory increaseLiquidityParams = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: params.tokenId,
                    amount0Desired: params.amountAIn,
                    amount1Desired: params.amountBIn,
                    amount0Min: params.amountAMin,
                    amount1Min: params.amountBMin,
                    deadline: uint256(params.deadline) + block.timestamp
                });

        (
            uint256 liquidity,
            uint256 amount0,
            uint256 amount1
        ) = INonfungiblePositionManager(params.nonfungiblePositionManager)
                .increaseLiquidity(increaseLiquidityParams);
        v3LiquidityInfo[params.tokenId].addAmountA += amount0;
        v3LiquidityInfo[params.tokenId].addAmountB += amount1;
        v3LiquidityInfo[params.tokenId].liquidityAmount += liquidity;
        v3LiquidityInfo[params.tokenId].lastestTime = block.timestamp;
        emit AddV3LiquidityEvent(params.tokenId, amount0, amount1);
    }

    function batchCollectAllFees(
        uint256[] calldata tokenIds,
        address nonfungiblePositionManager
    ) external onlyManager {
        for(uint256 i; i<tokenIds.length; i++){
            INonfungiblePositionManager.CollectParams
                memory params = INonfungiblePositionManager.CollectParams({
                    tokenId: tokenIds[i],
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                });

            (uint256 amount0, uint256 amount1) = INonfungiblePositionManager(
                nonfungiblePositionManager
            ).collect(params);
            v3LiquidityInfo[tokenIds[i]].collectAmountA += amount0;
            v3LiquidityInfo[tokenIds[i]].collectAmountB += amount1;
            v3LiquidityInfo[tokenIds[i]].lastestTime = block.timestamp;
            emit CollectFeesEvent(tokenIds[i], amount0, amount1);
        }
    }

    function batchRemoveV3Liquidity(
        RemoveV3LiquidityParams calldata params
    ) external {
        _checkOperator();
        unchecked {
            for (uint256 i; i < params.tokenIds.length; i++) {
                IERC721(params.nftAddress).approve(
                    params.nonfungiblePositionManager,
                    params.tokenIds[i]
                );
                INonfungiblePositionManager.DecreaseLiquidityParams
                    memory decreaseLiquidityParams = INonfungiblePositionManager
                        .DecreaseLiquidityParams({
                            tokenId: params.tokenIds[i],
                            liquidity: params.liquiditys[i],
                            amount0Min: params.amountAMins[i],
                            amount1Min: params.amountBMins[i],
                            deadline: uint256(params.deadline) + block.timestamp
                        });
                (
                    uint256 amount0Out,
                    uint256 amount1Out
                ) = INonfungiblePositionManager(
                        params.nonfungiblePositionManager
                    ).decreaseLiquidity(decreaseLiquidityParams);

                v3LiquidityInfo[params.tokenIds[i]].removeAmountA += amount0Out;
                v3LiquidityInfo[params.tokenIds[i]].removeAmountB += amount1Out;
                v3LiquidityInfo[params.tokenIds[i]].lastestTime = block.timestamp;
                emit RemoveV3LiquidityEvent(
                    params.tokenIds[i],
                    params.liquiditys[i],
                    amount0Out,
                    amount1Out
                );
            }
        }
    }

    function inL2Supply(
        address l2Pool,
        address usdc,
        uint256 amount
    ) external onlyManager {
        address l2Encode = _getL2Encode();
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeSupplyParams(
            usdc,
            amount,
            referralCode
        );
        IERC20(usdc).approve(l2Pool, amount);
        IL2Pool(l2Pool).supply(encodeMessage);
        emit L2Supply(amount);
    }

    function inL2Withdraw(
        address l2Pool,
        address ausdc,
        uint256 ausdcAmount
    ) external {
        _checkOperator();
        address l2Encode = _getL2Encode();
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
        _checkOperator();
        address l2Encode = _getL2Encode();
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeBorrowParams(
            asset,
            amount,
            interestRateMode,
            referralCode
        );
        IDebtTokenBase(vToken).approveDelegation(wrappedTokenGateway, type(uint64).max);
        IWrappedTokenGatewayV3(wrappedTokenGateway).borrowETH(l2Pool, amount, interestRateMode, referralCode);
    }

    function inL2Repay(
        address asset,
        address l2Pool,
        uint256 amount,
        uint256 interestRateMode
    ) external {
        _checkOperator();
        address l2Encode = _getL2Encode();
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeRepayParams(
            asset,
            amount,
            interestRateMode
        );
        IERC20(asset).approve(l2Pool, amount);
        IL2Pool(l2Pool).repay(encodeMessage);
    }

    function doETH(uint8 way, address weth, uint256 amount) external {
        _checkOperator();
        if (way == 0) {
            IWETH(weth).withdraw(amount);
        } else {
            IWETH(weth).deposit{value: amount}();
        }
    }

    function v3Swap(V3SwapParams calldata params) external returns (uint256 amountOut) {
        IERC20(params.tokenIn).approve(params.v3Router, params.amountIn);
        IUniSwapV3Router.ExactInputSingleParams memory v3Params = IUniSwapV3Router
            .ExactInputSingleParams({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                fee: params.fee,
                recipient: address(this),
                deadline: params.deadline + block.timestamp,
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        amountOut = IUniSwapV3Router(params.v3Router).exactInputSingle(v3Params);
    }

    function crossUSDC(
        uint8 indexDestHook,
        uint32 destinationDomain,
        uint64 sendBlock,
        address usdc,
        uint256 amount
    ) external {
        _checkOperator();
        bytes32 hook = _getValidHook(destinationDomain, indexDestHook);
        uint256 balance = _tokenBalance(usdc, address(this));
        if (balance == 0) {
            revert ZeroBalance(ErrorType.ZeroBalance);
        }
        if (destinationDomain == currentDomain) {
            address destCurrentChainHook = _bytes32ToAddress(hook);
            IERC20(usdc).approve(destCurrentChainHook, amount);
            IERC20(usdc).transfer(destCurrentChainHook, amount);
        } else {
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
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32,
        uint16,
        bytes32
    ) external payable {
        (uint256 crossId, uint256 crossEmergencyTime) = abi.decode(
            payload,
            (uint256, uint256)
        );
        emergencyTime = crossEmergencyTime;
        if (crossId != id || block.timestamp < crossEmergencyTime) {
            revert("Invalid message");
        }
    }

    function _tokenBalance(
        address token,
        address user
    ) private view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = IERC20(token).balanceOf(user);
    }

    function _checkOwner() internal view {
        require(msg.sender == owner);
    }

    function _checkManager() internal view {
        require(msg.sender == manager);
    }

    function _getL2Encode() private view returns (address _l2Encode) {
        _l2Encode = IVineHookCenter(govern).getL2Encode();
    }

    function _getValidHook(
        uint32 destinationDomain,
        uint8 indexDestHook
    ) private view returns (bytes32 validHook) {
        validHook = IVineHookCenter(govern).getDestHook(
            id,
            destinationDomain,
            indexDestHook
        );
    }

    function _crossCenter() private view returns (address crossCenter) {
        crossCenter = IVineHookCenter(govern).getMarketInfo(id).crossCenter;
    }

    function _checkOperator() private view {
        require(
            msg.sender == manager ||
                (block.timestamp > emergencyTime && emergencyTime > 0)
        );
    }

    function _bytes32ToAddress(
        bytes32 _bytes32Account
    ) private pure returns (address) {
        return address(uint160(uint256(_bytes32Account)));
    }

    function getV3LiquidityInfo(
        uint256 tokenId
    ) external view returns (V3LiquidityInfo memory) {
        return v3LiquidityInfo[tokenId];
    }

    function indexV3LiquidityTokenIds(
        uint256 index
    ) external view returns (uint256) {
        return V3LiquidityTokenIds[index];
    }

    function v3LiquidityTokenIdsLength() external view returns (uint256) {
        return V3LiquidityTokenIds.length;
    }

    function getTokenContracts(
        address tokenA,
        address tokenB
    ) external view returns (address _tokenA, address _tokenB) {
        _tokenA = tokenA < tokenB ? tokenA : tokenB;
        _tokenB = tokenA < tokenB ? tokenB : tokenA;
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
