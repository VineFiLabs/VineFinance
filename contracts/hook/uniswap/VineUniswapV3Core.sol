// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IV3SwapRouter} from "../../interfaces/uniswapV3/IV3SwapRouter.sol";
import {INonfungiblePositionManager} from "../../interfaces/uniswapV3/INonfungiblePositionManager.sol";
import {IUniswapV3Factory} from "../../interfaces/uniswapV3/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "../../interfaces/uniswapV3/IUniswapV3Pool.sol";
import {IPoolInitializer} from "../../interfaces/uniswapV3/IPoolInitializer.sol";
import {IERC721Receiver} from "../../interfaces/uniswapV3/IERC721Receiver.sol";
import {IWETH} from "../../interfaces/IWETH.sol";

import {IL2Pool} from "../../interfaces/aaveV3/IL2Pool.sol";
import {IL2Encode} from "../../interfaces/aaveV3/IL2Encode.sol";
import {IDebtTokenBase} from "../../interfaces/aaveV3/IDebtTokenBase.sol";
import {IWrappedTokenGatewayV3} from "../../interfaces/aaveV3/IWrappedTokenGatewayV3.sol";

import {ICrossCenter} from "../../interfaces/core/ICrossCenter.sol";
import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
import {IVineVault} from "../../interfaces/core/IVineVault.sol";
import {IVineUniswapCore} from "../../interfaces/hook/uniswap/IVineUniswapCore.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {IVineStruct} from "../../interfaces/IVineStruct.sol";
import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
import {ISharer} from "../../interfaces/ISharer.sol";
import {VineLib} from "../../libraries/VineLib.sol";
import {IVineVault} from "../../interfaces/core/IVineVault.sol";
import {IVineConfig1} from "../../interfaces/core/IVineConfig1.sol";

import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VineUniswapV3Core is
    IVineUniswapCore,
    IVineEvent,
    IVineStruct,
    IVineHookErrors,
    IERC721Receiver,
    ISharer,
    IWormholeReceiver
{
    using SafeERC20 for IERC20;
    
    bytes1 private immutable ONEBYTES1 = 0x01;
    uint16 private referralCode;
    uint64 public curatorId;
    address public immutable factory;
    address public immutable govern;
    address public immutable owner;
    address public manager;
    uint256 public deadline = 30;

    constructor(address _govern, address _owner, address _manager, uint64 _curatorId) {
        factory = msg.sender;
        govern = _govern;
        owner = _owner;
        manager = _manager;
        curatorId = _curatorId;
    }

    mapping(uint256 => uint256)public emergencyTime;

    mapping(uint256 => uint256[]) private V3LiquidityTokenIds;
    mapping(uint256 => mapping(uint256 => V3LiquidityInfo)) private v3LiquidityInfo;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }

    receive() external payable {}

    function transferManager(address newManager) external onlyOwner {
        manager = newManager;
    }

    function setReferralCode(uint16 _referralCode) external onlyManager {
        referralCode = _referralCode;
    }

    function setDeadline(uint256 _deadline) external onlyManager {
        deadline = _deadline;
    }
    function getV3Pool(
        address v3factory,
        address token0,
        address token1,
        uint24 thiaPoolFee
    ) external view returns (address) {
        return IUniswapV3Factory(v3factory).getPool(token0, token1, thiaPoolFee);
    }

    function mintLiquidityPool(
        MintLiquidityPoolParams calldata params
    ) public onlyManager {
        _checkValidId(params.id);
        address token0 = _getVineConfig(params.indexConfig, params.id).mainToken;
        address token1 = _getVineConfig(params.indexConfig, params.id).derivedToken;
        address nonfungiblePositionManager = _getVineConfig(params.indexConfig, params.id).callee;
        address vineVault = _getMarketInfo(params.id).vineVault;
        _callVault(vineVault, token0, params.token0Amount);
        _callVault(vineVault, token1, params.token1Amount);
        IERC20(token0).approve(
            nonfungiblePositionManager,
            params.token0Amount
        );
        IERC20(token1).approve(
            nonfungiblePositionManager,
            params.token1Amount
        );
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
        // Create the liquidity position
        INonfungiblePositionManager.MintParams
            memory mintParams = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: params.poolFee,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: params.token0Amount,
                amount1Desired: params.token1Amount,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min,
                recipient: address(this),
                deadline: block.timestamp + deadline
            });
        (tokenId, liquidity, amount0, amount1) = INonfungiblePositionManager(
            nonfungiblePositionManager
        ).mint(mintParams);
        v3LiquidityInfo[params.id][tokenId].tokenA = token0;
        v3LiquidityInfo[params.id][tokenId].tokenB = token1;
        v3LiquidityInfo[params.id][tokenId].addAmountA += params.token0Amount;
        v3LiquidityInfo[params.id][tokenId].addAmountB += params.token1Amount;
        v3LiquidityInfo[params.id][tokenId].liquidityAmount += liquidity;
        v3LiquidityInfo[params.id][tokenId].lastestTime = block.timestamp;
        if (v3LiquidityInfo[params.id][tokenId].exist == false) {
                V3LiquidityTokenIds[params.id].push(tokenId);
        }
        v3LiquidityInfo[params.id][tokenId].exist = true;

        emit MintEvent(tokenId, liquidity);
    }

    function addV3Liquidity(
        AddV3LiquidityParams calldata params
    ) external onlyManager {
        _checkValidId(params.id);
        address token0 = _getVineConfig(params.indexConfig, params.id).mainToken;
        address token1 = _getVineConfig(params.indexConfig, params.id).derivedToken;
        address nonfungiblePositionManager = _getVineConfig(params.indexConfig, params.id).callee;
        address vineVault = _getMarketInfo(params.id).vineVault;
        _callVault(vineVault, token0, params.token0Amount);
        _callVault(vineVault, token1, params.token1Amount);
        IERC20(token0).approve(
            nonfungiblePositionManager,
            params.token0Amount
        );
        IERC20(token1).approve(
            nonfungiblePositionManager,
            params.token1Amount
        );
        INonfungiblePositionManager.IncreaseLiquidityParams
            memory increaseLiquidityParams = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: params.tokenId,
                    amount0Desired: params.token0Amount,
                    amount1Desired: params.token1Amount,
                    amount0Min: params.amount0Min,
                    amount1Min: params.amount1Min,
                    deadline: block.timestamp + deadline
                });

        (
            uint256 liquidity,
            uint256 amount0,
            uint256 amount1
        ) = INonfungiblePositionManager(nonfungiblePositionManager)
                .increaseLiquidity(increaseLiquidityParams);
        v3LiquidityInfo[params.id][params.tokenId].addAmountA += amount0;
        v3LiquidityInfo[params.id][params.tokenId].addAmountB += amount1;
        v3LiquidityInfo[params.id][params.tokenId].liquidityAmount += liquidity;
        v3LiquidityInfo[params.id][params.tokenId].lastestTime = block.timestamp;
        emit AddV3LiquidityEvent(params.tokenId, amount0, amount1);
    }

    function batchCollectAllFees(
        uint256 id,
        uint8 indexConfig,
        uint256[] calldata tokenIds
    ) external {
        _checkValidId(id);
        address vineVault = _getMarketInfo(id).vineVault;
        address nonfungiblePositionManager = _getVineConfig(indexConfig, id).callee;
        for(uint256 i; i<tokenIds.length; i++){
            INonfungiblePositionManager.CollectParams
                memory params = INonfungiblePositionManager.CollectParams({
                    tokenId: tokenIds[i],
                    recipient: vineVault,
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                });
            (uint256 amount0, uint256 amount1) = INonfungiblePositionManager(
                nonfungiblePositionManager
            ).collect(params);
            v3LiquidityInfo[id][tokenIds[i]].collectAmountA += amount0;
            v3LiquidityInfo[id][tokenIds[i]].collectAmountB += amount1;
            v3LiquidityInfo[id][tokenIds[i]].lastestTime = block.timestamp;
            emit CollectFeesEvent(tokenIds[i], amount0, amount1);
        }
    }

    function batchRemoveV3Liquidity(
        RemoveV3LiquidityParams calldata params
    ) external {
        _checkValidId(params.id);
        _checkOperator(params.id);
        address vineVault = _getMarketInfo(params.id).vineVault;
        address nftAddress = _getVineConfig(params.indexConfig, params.id).otherCaller;
        address nonfungiblePositionManager = _getVineConfig(params.indexConfig, params.id).callee;
        address token0 = _getVineConfig(params.indexConfig, params.id).mainToken;
        address token1 = _getVineConfig(params.indexConfig, params.id).derivedToken;
        unchecked {
            for (uint256 i; i < params.tokenIds.length; i++) {
                //nft approve
                IERC721(nftAddress).approve(
                    nonfungiblePositionManager,
                    params.tokenIds[i]
                );

                INonfungiblePositionManager.DecreaseLiquidityParams
                    memory decreaseLiquidityParams = INonfungiblePositionManager
                        .DecreaseLiquidityParams({
                            tokenId: params.tokenIds[i],
                            liquidity: params.liquiditys[i],
                            amount0Min: params.amountAMins[i],
                            amount1Min: params.amountBMins[i],
                            deadline: block.timestamp + deadline
                        });
                (uint256 amount0Out, uint256 amount1Out) = INonfungiblePositionManager(
                        nonfungiblePositionManager
                ).decreaseLiquidity(decreaseLiquidityParams);
                
                IERC20(token0).safeTransfer(vineVault, amount0Out);
                IERC20(token1).safeTransfer(vineVault, amount1Out);

                v3LiquidityInfo[params.id][params.tokenIds[i]].removeAmountA += amount0Out;
                v3LiquidityInfo[params.id][params.tokenIds[i]].removeAmountB += amount1Out;
                v3LiquidityInfo[params.id][params.tokenIds[i]].lastestTime = block.timestamp;
                emit RemoveV3LiquidityEvent(
                    params.tokenIds[i],
                    params.liquiditys[i]
                );
            }
        }
    }

    function doETH(
        uint256 id,
        uint8 way, 
        uint8 indexConfig,
        uint256 amount
    ) external {
        _checkValidId(id);
        _checkOperator(id);
        address vineVault = _getMarketInfo(id).vineVault;
        address weth = _getVineConfig(indexConfig, id).callee;
        if (way == 0) {
            bytes memory withdrawPayload = abi.encodeCall(
                IWETH(weth).withdraw,
                (amount)
            );
            _callWay(vineVault, 0, weth, weth, amount, withdrawPayload);
        } else {
            bytes memory depositPayload = abi.encodeCall(
                IWETH(weth).deposit,
                ()
            );
            _callWay(vineVault, 0, weth, weth, amount, depositPayload);
        }
    }

    function v3Swap(V3SwapParams calldata params) external {
        _checkValidId(params.id);
        _checkOperator(params.id);
         address vineVault = _getMarketInfo(params.id).vineVault;
        address v3Router = _getVineConfig(params.indexConfig, params.id).callee;
        address tokenIn = _getVineConfig(params.indexConfig, params.id).mainToken;
        address tokenOut = _getVineConfig(params.indexConfig, params.id).derivedToken;
        IV3SwapRouter.ExactInputSingleParams memory v3Params = IV3SwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: params.poolFee,
                recipient: vineVault,
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        bytes memory payload = abi.encodeCall(
            IV3SwapRouter(v3Router).exactInputSingle,
            (v3Params)
        );
        _callWay(vineVault, 2, tokenIn, v3Router, params.amountIn, payload);
    }

    function crossUSDC(
        CrossUSDCParams calldata params
    ) external {
        _checkValidId(params.id);
        _checkOperator(params.id);
        address usdc = _getVineConfig(params.indexConfig, params.id).mainToken;
        bytes32 bytes32DestVault = _getValidVault(params.id, params.destinationDomain);
        address destVault = _bytes32ToAddress(bytes32DestVault);
        address crossCenter = _getMarketInfo(params.id).crossCenter;
        address currentVault = _getMarketInfo(params.id).vineVault;
        require(destVault != currentVault && destVault != address(0), "Invalid destinationDomain");
        IVineVault(currentVault).callVault(usdc, params.amount);
        if(params.sameChain){
            IERC20(usdc).safeTransfer(destVault, params.amount);
        }else {
            IERC20(usdc).approve(crossCenter, params.amount);
            ICrossCenter(crossCenter).crossUSDC(
                params.destinationDomain,
                params.inputBlock,
                bytes32DestVault,
                params.amount
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
        require(msg.sender == _wormholeRelayer(), "Not relayer");
        (uint256 crossId, uint256 crossEmergencyTime) = abi.decode(payload, (uint256, uint256));
        _checkValidId(crossId);
        emergencyTime[crossId] = crossEmergencyTime;
        emit Emergency(crossId, crossEmergencyTime);
        if(block.timestamp < crossEmergencyTime){
            revert("Not emergency time");
        }
    } 

    function skimToVault(
        address token, 
        uint256 id, 
        uint256 amount
    ) external {
        require(msg.sender == _officialManager());
        address vineVault = _getMarketInfo(id).vineVault;
        _skim(token, vineVault, amount);
    }

    function _callWay(
        address vineVault,
        uint8 tokenType,
        address token,
        address caller, 
        uint256 amount,
        bytes memory data
    ) private {
        (bool state, ) = IVineVault(
            vineVault
        ).callWay(
            tokenType, 
            token, 
            caller, 
            amount, 
            data
        );
        require(state, "Call way fail");
    }

    function _callVault(address vineVault, address token, uint256 amount) private {
        IVineVault(vineVault).callVault(token, amount);
    }

    function _tokenBalance(
        address token,
        address user
    ) private view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = IERC20(token).balanceOf(user);
    }

    function _skim(
        address token, 
        address receiver,
        uint256 diffAmount
    ) private {
        if(diffAmount >0 ){
            IERC20(token).safeTransfer(receiver, diffAmount);
        }
    }

    function _checkOwner() internal view {
        require(msg.sender == owner, "Non owner");
    }

    function _checkManager() internal view {
        require(msg.sender == manager, "Non manager");
    }

    function _officialManager() private view returns(address _offManager){
        _offManager = IVineHookCenter(govern).manager();
    }

    function _getL2Encode()private view returns(address _l2Encode) {
        _l2Encode = IVineHookCenter(govern).getL2Encode();
    }

    function _getMarketInfo(uint256 id) private view returns(IVineHookCenter.MarketInfo memory _marketInfo){
        _marketInfo = IVineHookCenter(govern).getMarketInfo(id);
    }

    function _getVineConfig(uint8 indexConfig, uint256 id) private view returns (IVineConfig1.calleeInfo memory _calleeInfo){
        _calleeInfo = IVineConfig1(_getMarketInfo(id).vineConfigAddress).getCalleeInfo(indexConfig);
    }

    function _getValidVault(uint256 id, uint32 destinationDomain) private view returns(bytes32 validVault){
        validVault = IVineHookCenter(govern).getDestVault(id, destinationDomain);
    }

    function _checkOperator(uint256 id) private view {
        require(msg.sender == manager || (block.timestamp > emergencyTime[id] && emergencyTime[id] > 0), "Non manager or not emergency time");
    } 
    function _checkValidId(uint256 id) private view {
        require(curatorId == _getMarketInfo(id).userId, "Not this curator");
    }

    function _wormholeRelayer() private view returns(address){
        return IVineHookCenter(govern).wormholeRelayer();
    }

    function _bytes32ToAddress(
        bytes32 _bytes32Account
    ) private pure returns (address) {
        return address(uint160(uint256(_bytes32Account)));
    }

    function getTokenBalance(
        address token,
        address user
    ) external view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = _tokenBalance(token, user);
    }

    function getV3LiquidityInfo(
        uint256 id,
        uint256 tokenId
    ) external view returns (V3LiquidityInfo memory) {
        return v3LiquidityInfo[id][tokenId];
    }

    function indexV3LiquidityTokenIds(
        uint256 id,
        uint256 index
    ) external view returns (uint256) {
        return V3LiquidityTokenIds[id][index];
    }

    function v3LiquidityTokenIdsLength(uint256 id) external view returns (uint256) {
        return V3LiquidityTokenIds[id].length;
    }

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
