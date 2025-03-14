// //SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.8.23;

// import {IUniswapV2Router01, IUniswapV2Router02} from "../../interfaces/uniswapV2/IUniswapV2Router02.sol";
// import {IUniswapV2Factory} from "../../interfaces/uniswapV2/IUniswapV2Factory.sol";
// import {IERC721Receiver} from "../../interfaces/IERC721Receiver.sol";
// import {IWETH} from "../../interfaces/IWETH.sol";

// import {IL2Pool} from "../../interfaces/aaveV3/IL2Pool.sol";
// import {IL2Encode} from "../../interfaces/aaveV3/IL2Encode.sol";
// import {IDebtTokenBase} from "../../interfaces/aaveV3/IDebtTokenBase.sol";

// import {ICrossCenter} from "../../interfaces/ICrossCenter.sol";
// import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
// import {IVineUniswapCore} from "../../interfaces/IVineUniswapCore.sol";
// import {IVineEvent} from "../../interfaces/IVineEvent.sol";
// import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
// import {ISharer} from "../../interfaces/ISharer.sol";
// import {VineLib} from "../../libraries/VineLib.sol";

// import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
// import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// contract VineUniswapV2Core is
//     IVineUniswapCore,
//     IVineEvent,
//     IVineHookErrors,
//     ISharer,
//     IWormholeReceiver
// {
//     using SafeERC20 for IERC20;

//     uint256 public id;
//     uint16 private referralCode;
//     uint32 public currentDomain;
//     address public factory;
//     address public owner;
//     address public manager;
//     address public govern;
//     uint256 public emergencyTime;

//     mapping(address => V2LiquidityInfo) private v2LiquidityInfo;

//     constructor(
//         address _owner,
//         address _manager,
//         address _govern,
//         uint256 _id
//     ) {
//         factory = msg.sender;
//         owner = _owner;
//         manager = _manager;
//         govern = _govern;
//         id = _id;
//         currentDomain = VineLib._currentDomain();
//     }

//     modifier onlyOwner() {
//         _checkOwner();
//         _;
//     }

//     modifier onlyManager() {
//         _checkManager();
//         _;
//     }

//     receive() external payable {}

//     event AddV2LiquidityEvent(address indexed _pool, uint256 amount0, uint256 amount1);
//     event RemoveV2LiquidityEvent(address indexed _pool, uint256 lpAmount, uint256 amount0, uint256 amount1);

//     function transferOwner(address newOwner) external onlyOwner {
//         owner = newOwner;
//     }

//     function transferManager(address newManager) external onlyOwner {
//         manager = newManager;
//     }

//     function setReferralCode(uint16 _referralCode) external onlyManager {
//         referralCode = _referralCode;
//     }

//     function changeDomain(uint32 newDomain) external onlyManager{
//         currentDomain = newDomain;
//     }

//     function getV2Pool(
//         address v2Factory,
//         address token0,
//         address token1
//     ) public view returns (address) {
//         return IUniswapV2Factory(v2Factory).getPair(token0, token1);
//     }

//     function addV2Liquidity(V2LiquidityParams calldata params) external onlyManager{
//         if(params.tokenB == address(0)){

//         }else{
//             IERC20(params.tokenB).approve(params.v2Router, params.amountBIn);
//         }
//         IERC20(params.tokenA).approve(params.v2Router, params.amountAIn);
//         IUniswapV2Router01(params.v2Router).addLiquidity(
//             params.tokenA,
//             params.tokenB,
//             params.amountAIn,
//             params.amountBIn,
//             params.amountAOutMin,
//             params.amountBOutMin,
//             address(this),
//             uint256(params.deadline) + block.timestamp
//         );
//         v2LiquidityInfo[params.v2Pool].tokenA = params.tokenA;
//         v2LiquidityInfo[params.v2Pool].tokenB = params.tokenB;
//         v2LiquidityInfo[params.v2Pool].addAmountA += params.amountAIn;
//         v2LiquidityInfo[params.v2Pool].addAmountB += params.amountBIn;
//         v2LiquidityInfo[params.v2Pool].lpAmount = _tokenBalance(params.v2Pool, address(this));
//         v2LiquidityInfo[params.v2Pool].lastestTime = block.timestamp;
//         emit AddV2LiquidityEvent(params.v2Pool, params.amountAIn, params.amountBIn);
//     }

//     function addV2LiquidityETH(
//         V2LiquidityParams calldata params
//     ) external {
//         IERC20(params.tokenA).approve(params.v2Router, params.amountAIn);
//         (
//             uint256 amountToken, 
//             uint256 amountETH, 
//             uint256 liquidity
//         )=IUniswapV2Router01(params.v2Router).addLiquidityETH{value: params.amountBIn}(
//             params.tokenA, 
//             params.amountAIn, 
//             params.amountAOutMin, 
//             params.amountBOutMin, 
//             address(this), 
//             uint256(params.deadline) + block.timestamp
//         );
//         address v2Pool = getV2Pool(
//             params.v2Factory, 
//             params.tokenA, 
//             params.tokenB
//         );
//         v2LiquidityInfo[v2Pool].tokenA = params.tokenA;
//         v2LiquidityInfo[v2Pool].tokenB = params.tokenB;
//         v2LiquidityInfo[v2Pool].addAmountA += params.amountAIn;
//         v2LiquidityInfo[v2Pool].addAmountB += params.amountBIn;
//         v2LiquidityInfo[v2Pool].lpAmount = _tokenBalance(v2Pool, address(this));
//         v2LiquidityInfo[v2Pool].lastestTime = block.timestamp;
//         emit AddV2LiquidityEvent(v2Pool, params.amountAIn, params.amountBIn);
//     }

//     function removeV2Liquidity(
//         RemoveV2LiquidityParams calldata params
//     ) external {
//         _checkOperator();
//         IERC20(params.lpToken).approve(params.v2Router, params.liquidity);
//          (uint256 amountA, uint256 amountB) = IUniswapV2Router01(params.v2Router).removeLiquidity(
//             params.tokenA,
//             params.tokenB,
//             params.liquidity,
//             params.amountAOutMin,
//             params.amountBOutMin,
//             address(this),
//             uint256(params.deadline) + block.timestamp
//         );
//         address v2Pool = getV2Pool(
//             params.v2Factory, 
//             params.tokenA, 
//             params.tokenB
//         );
//         v2LiquidityInfo[v2Pool].removeAmountA += amountA;
//         v2LiquidityInfo[v2Pool].removeAmountB += amountB;
//         v2LiquidityInfo[v2Pool].lpAmount = _tokenBalance(v2Pool, address(this));
//         v2LiquidityInfo[v2Pool].lastestTime = block.timestamp;
//         emit RemoveV2LiquidityEvent(v2Pool, params.liquidity, amountA, amountB);
//     }

//     function removeV2LiquidityETH(
//         RemoveV2LiquidityParams calldata params
//     )external {
//         IERC20(params.lpToken).approve(params.v2Router, params.liquidity);
//          (uint256 amountA, uint256 amountB) = IUniswapV2Router01(params.v2Router).removeLiquidityETH(
//             params.tokenA,
//             params.liquidity,
//             params.amountAOutMin,
//             params.amountBOutMin,
//             address(this),
//             uint256(params.deadline) + block.timestamp
//         );
//         address v2Pool = getV2Pool(
//             params.v2Factory, 
//             params.tokenA, 
//             params.tokenB
//         );
//         v2LiquidityInfo[v2Pool].removeAmountA += amountA;
//         v2LiquidityInfo[v2Pool].removeAmountB += amountB;
//         v2LiquidityInfo[v2Pool].lpAmount = _tokenBalance(v2Pool, address(this));
//         v2LiquidityInfo[v2Pool].lastestTime = block.timestamp;
//         emit RemoveV2LiquidityEvent(v2Pool, params.liquidity, amountA, amountB);
//     }

//     function inL2Supply(
//         address l2Pool,
//         address usdc,
//         uint256 amount
//     ) external onlyManager {
//         IERC20(usdc).approve(l2Pool, amount);
//         address l2Encode = _getL2Encode();
//         bytes32 encodeMessage = IL2Encode(l2Encode).encodeSupplyParams(
//             usdc,
//             amount,
//             referralCode
//         );
//         IL2Pool(l2Pool).supply(encodeMessage);
//         emit L2Supply(amount);
//     }

//     function inL2Withdraw(
//         address l2Pool,
//         address ausdc,
//         uint256 ausdcAmount
//     ) external {
//         _checkOperator();
//         address l2Encode = _getL2Encode();
//         bytes32 encodeMessage = IL2Encode(l2Encode).encodeWithdrawParams(
//             ausdc,
//             ausdcAmount
//         );
//         IERC20(ausdc).approve(l2Pool, ausdcAmount);
//         IL2Pool(l2Pool).withdraw(encodeMessage);
//     }

//     function inL2Borrow(
//         address asset,
//         address l2Pool,
//         address token,
//         address delegate,
//         uint256 amount,
//         uint256 interestRateMode
//     ) external {
//         _checkOperator();
//         address l2Encode = _getL2Encode();
//         bytes32 encodeMessage = IL2Encode(l2Encode).encodeBorrowParams(
//             asset,
//             amount,
//             interestRateMode,
//             referralCode
//         );
//         IDebtTokenBase(token).approveDelegation(delegate, amount);
//         IL2Pool(l2Pool).borrow(encodeMessage);
//     }

//     function inL2Repay(
//         address asset,
//         address l2Pool,
//         uint256 amount,
//         uint256 interestRateMode
//     ) external {
//         _checkOperator();
//         address l2Encode = _getL2Encode();
//         IERC20(asset).approve(l2Pool, amount);
//         bytes32 encodeMessage = IL2Encode(l2Encode).encodeRepayParams(
//             asset,
//             amount,
//             interestRateMode
//         );
//         IL2Pool(l2Pool).repay(encodeMessage);
//     }

//     function doETH(uint8 way, address weth, uint256 amount) external {
//         _checkOperator();
//         if(way == 0){
//             IWETH(weth).withdraw(amount);
//         }else{
//             IWETH(weth).deposit{value: amount}();
//         }
//     }

//     function crossUSDC(
//         uint8 indexDestHook,
//         uint32 destinationDomain,
//         uint64 sendBlock,
//         address usdc,
//         uint256 amount
//     ) external {
//         _checkOperator();
//         bytes32 hook = _getValidHook(destinationDomain, indexDestHook);
//         uint256 balance = _tokenBalance(usdc, address(this));
//         if (balance == 0) {
//             revert ZeroBalance(ErrorType.ZeroBalance);
//         }
//         if(destinationDomain == currentDomain){
//             address destCurrentChainHook = _bytes32ToAddress(hook);
//             IERC20(usdc).approve(destCurrentChainHook, amount);
//             IERC20(usdc).transfer(destCurrentChainHook, amount);
//         }else{
//             address crossCenter = _crossCenter();
//             IERC20(usdc).approve(crossCenter, amount);
//             ICrossCenter(crossCenter).crossUSDC(
//                 destinationDomain, 
//                 sendBlock, 
//                 hook, 
//                 usdc, 
//                 amount
//             );
//         }
//     }

//     function receiveWormholeMessages(
//         bytes memory payload,
//         bytes[] memory,
//         bytes32,
//         uint16,
//         bytes32
//     ) external payable {
//         (uint256 crossId, uint256 crossEmergencyTime) = abi.decode(
//             payload,
//             (uint256, uint256)
//         );
//         emergencyTime = crossEmergencyTime;
//         if (crossId != id || block.timestamp < crossEmergencyTime) {
//             revert("Invalid message");
//         }
//     }

//     function _tokenBalance(
//         address token,
//         address user
//     ) private view returns (uint256 _thisTokenBalance) {
//         _thisTokenBalance = IERC20(token).balanceOf(user);
//     }

//     function _checkOwner() internal view {
//         require(msg.sender == owner);
//     }

//     function _checkManager() internal view {
//         require(msg.sender == manager);
//     }

//     function _getL2Encode()private view returns(address _l2Encode){
//         _l2Encode = IVineHookCenter(govern).getL2Encode();
//     }

//     function _getValidHook(
//         uint32 destinationDomain,
//         uint8 indexDestHook
//     ) private view returns (bytes32 validHook) {
//         validHook = IVineHookCenter(govern).getDestHook(
//             id,
//             destinationDomain,
//             indexDestHook
//         );
//     }

//     function _crossCenter() private view returns (address crossCenter) {
//         crossCenter = IVineHookCenter(govern).getMarketInfo(id).crossCenter;
//     }

//     function _checkOperator() private view {
//         require(msg.sender == manager || (block.timestamp > emergencyTime && emergencyTime > 0));
//     } 

//     function _bytes32ToAddress(
//         bytes32 _bytes32Account
//     ) private pure returns (address) {
//         return address(uint160(uint256(_bytes32Account)));
//     }

//     function getV2LiquidityInfo(address v2Pool)external view returns(V2LiquidityInfo memory){
//         return v2LiquidityInfo[v2Pool];
//     }

//     function getTokenContracts(
//         address tokenA,
//         address tokenB
//     ) external view returns (address _tokenA, address _tokenB) {
//         _tokenA = tokenA < tokenB ? tokenA : tokenB;
//         _tokenB = tokenA < tokenB ? tokenB : tokenA;
//     }

//     function getTokenBalance(
//         address token,
//         address user
//     ) external view returns (uint256 _thisTokenBalance) {
//         _thisTokenBalance = _tokenBalance(token, user);
//     }

// }
