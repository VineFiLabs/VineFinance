// //SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.8.23;

// import {IUniswapV2Router01, IUniswapV2Router02} from "../../interfaces/uniswapV2/IUniswapV2Router02.sol";
// import {IUniswapV2Factory} from "../../interfaces/uniswapV2/IUniswapV2Factory.sol";
// import {IWETH} from "../../interfaces/IWETH.sol";

// import {IL2Pool} from "../../interfaces/aaveV3/IL2Pool.sol";
// import {IL2Encode} from "../../interfaces/aaveV3/IL2Encode.sol";
// import {IDebtTokenBase} from "../../interfaces/aaveV3/IDebtTokenBase.sol";

// import {ICrossCenter} from "../../interfaces/core/ICrossCenter.sol";
// import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
// import {IVineUniswapCore} from "../../interfaces/hook/uniswap/IVineUniswapCore.sol";
// import {IVineEvent} from "../../interfaces/IVineEvent.sol";
// import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
// import {ISharer} from "../../interfaces/ISharer.sol";
// import {VineLib} from "../../libraries/VineLib.sol";
// import {IVineConfig1} from "../../interfaces/core/IVineConfig1.sol";

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

//     bytes1 private immutable ONEBYTES1 = 0x01;
//     uint16 private referralCode;
//     uint64 public curatorId;
//     address public factory;
//     address public govern;
//     address public owner;
//     address public manager;
//     constructor(address _govern, address _owner, address _manager, uint64 _curatorId) {
//         factory = msg.sender;
//         govern = _govern;
//         owner = _owner;
//         manager = _manager;
//         curatorId = _curatorId;
//     }

//     mapping(uint256 => uint256)public emergencyTime;

//     mapping(address => V2LiquidityInfo) private v2LiquidityInfo;

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

//     function transferManager(address newManager) external onlyOwner {
//         manager = newManager;
//     }

//     function setReferralCode(uint16 _referralCode) external onlyManager {
//         referralCode = _referralCode;
//     }

//     function getV2Pool(
//         uint256 id,
//         uint8 indexConfig,
//         address v2Factory
//     ) public view returns (address) {
//         address usdc = _getVineConfig(indexConfig, id).mainToken;
//         address otherToken = _getVineConfig(indexConfig, id).derivedToken;
//         return IUniswapV2Factory(v2Factory).getPair(usdc, otherToken);
//     }

//     function addV2Liquidity(V2LiquidityParams calldata params) external onlyManager{
//         if(params.tokenB == address(0)){

//         }else{
//             IERC20(params.tokenB).approve(params.v2Router, params.amountBIn);
//         }
//         address usdc = _getVineConfig(indexConfig, id).mainToken;
//         address otherToken = _getVineConfig(indexConfig, id).derivedToken;
//         address l2Pool = _getVineConfig(indexConfig, id).callee;
//         bytes memory payload = abi.encodeCall(
//             IL2Pool(l2Pool).supply,
//             (encodeMessage)
//         );
//         (state, ) = IVineVault(vineVault).callWay(
//             2,
//             usdc,
//             l2Pool,
//             amount,
//             payload
//         );
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
//         emit AaveV3Supply(amount);
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

//    function crossUSDC(
    //     CrossUSDCParams calldata params
    // ) external {
    //     _checkValidId(params.id);
    //     _checkOperator(params.id);
    //     address usdc = _getVineConfig(params.indexConfig, params.id).mainToken;
    //     bytes32 bytes32DestVault = _getValidVault(params.id, params.destinationDomain);
    //     address destVault = _bytes32ToAddress(bytes32DestVault);
    //     address crossCenter = _getMarketInfo(params.id).crossCenter;
    //     address currentVault = _getMarketInfo(params.id).vineVault;
    //     require(destVault != currentVault && destVault != address(0), "Invalid destinationDomain");
    //     IVineVault(currentVault).callVault(usdc, params.amount);
    //     if(params.sameChain){
    //         IERC20(usdc).safeTransfer(destVault, params.amount);
    //     }else {
    //         IERC20(usdc).approve(crossCenter, params.amount);
    //         ICrossCenter(crossCenter).crossUSDC(
    //             params.destinationDomain,
    //             params.inputBlock,
    //             bytes32DestVault,
    //             params.amount
    //         );
    //     }
    // }

//     function receiveWormholeMessages(
//         bytes memory payload,
//         bytes[] memory,
//         bytes32,
//         uint16,
//         bytes32
//     ) external payable{
//         require(msg.sender == _wormholeRelayer(), "Not relayer");
//         (uint256 crossId, uint256 crossEmergencyTime) = abi.decode(payload, (uint256, uint256));
//         _checkValidId(crossId);
//         emergencyTime[crossId] = crossEmergencyTime;
//         emit Emergency(crossId, crossEmergencyTime);
//         if(block.timestamp < crossEmergencyTime){
//             revert("Not emergency time");
//         }
//     } 

//     function _tokenBalance(
//         address token,
//         address user
//     ) private view returns (uint256 _thisTokenBalance) {
//         _thisTokenBalance = IERC20(token).balanceOf(user);
//     }

//     function _checkOwner() internal view {
//         require(msg.sender == owner, "Non owner");
//     }

//     function _checkManager() internal view {
//         require(msg.sender == manager, "Non manager");
//     }

//     function _officialManager() private view returns(address _offManager){
//         _offManager = IVineHookCenter(govern).manager();
//     }

//     function _getMarketInfo(uint256 id) private view returns(IVineHookCenter.MarketInfo memory _marketInfo){
//         _marketInfo = IVineHookCenter(govern).getMarketInfo(id);
//     }

//     function _getVineConfig(uint8 indexConfig, uint256 id) private view returns (IVineConfig1.calleeInfo memory _calleeInfo){
//         _calleeInfo = IVineConfig1(_getMarketInfo(id).vineConfigAddress).getCalleeInfo(indexConfig);
//     }

//     function _getValidVault(uint256 id, uint32 destinationDomain) private view returns(bytes32 validVault){
//         validVault = IVineHookCenter(govern).getDestVault(id, destinationDomain);
//     }

//     function _checkOperator(uint256 id) private view {
//         require(msg.sender == manager || (block.timestamp > emergencyTime[id] && emergencyTime[id] > 0), "Non manager or not emergency time");
//     } 
//     function _checkValidId(uint256 id) private view {
//         require(curatorId == _getMarketInfo(id).userId, "Not this curator");
//     }

//     function _wormholeRelayer() private view returns(address){
//         return IVineHookCenter(govern).wormholeRelayer();
//     }

//     function _bytes32ToAddress(
//         bytes32 _bytes32Account
//     ) private pure returns (address) {
//         return address(uint160(uint256(_bytes32Account)));
//     }

//     function getTokenBalance(
//         address token,
//         address user
//     ) external view returns (uint256 _thisTokenBalance) {
//         _thisTokenBalance = _tokenBalance(token, user);
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

// }
