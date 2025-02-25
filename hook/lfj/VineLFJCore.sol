// // SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.8.23;

// import {ICrossCenter} from "../../interfaces/ICrossCenter.sol";
// import {IVineHookCenter} from "../../interfaces/core/IVineHookCenter.sol";
// import {ILBRouter} from "../../interfaces/lfj/ILBRouter.sol";
// import {ILBFactory} from "../../interfaces/lfj/ILBFactory.sol";
// import {ILBPair} from "../../interfaces/lfj/ILBPair.sol";

// import {IVineStruct} from "../../interfaces/IVineStruct.sol";
// import {IVineUniswapCore} from "../../interfaces/IVineUniswapCore.sol";
// import {IVineEvent} from "../../interfaces/IVineEvent.sol";
// import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
// import {ISharer} from "../../interfaces/ISharer.sol";

// import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// contract VineLFJCore is 
//     ReentrancyGuard,
//     ERC1155Holder,
//     IVineStruct,
//     IVineEvent,
//     IVineHookErrors{

//     using SafeERC20 for IERC20;

//     uint256 public id;
//     address public factory;
//     address public owner;
//     address public manager;
//     address public govern;

//     uint256 public pairId;

//     constructor(address _owner, address _manager) {
//         factory = msg.sender;
//         owner = _owner;
//         manager = _manager;
//     }

//     modifier onlyOwner() {
//         _checkOwner();
//         _;
//     }

//     modifier onlyManager() {
//         _checkManager();
//         _;
//     }

//     struct LiquidityInfo{
//         address pair;
//         uint256 amountXAdded;
//         uint256 amountYAdded;
//         uint256 amountXLeft;
//         uint256 amountYLeft;
//         uint256[] depositIds;
//         uint256[] liquidityMinted;
//     }

//     mapping(address => LiquidityInfo) public liquidityInfo;

//     function transferOwner(address newOwner) external onlyOwner {
//         owner = newOwner;
//     }

//     function transferManager(address newManager) external onlyOwner {
//         manager = newManager;
//     }

//     struct addLiquidityParams{
//         address pair;
//         address router;
//         address tokenX;
//         address tokenY; 
//         uint256 amountx; 
//         uint256 amounty;
//         uint256 binStep;
//         uint256 slippage;
//         uint256 deadline;
//         int256[] deltaIds;
//         uint256[] distributionX;
//         uint256[] distributionY;
//     }

//     struct removeLiquidityParams{
//         address router;
//         uint256 thisPairId;
//         address tokenX;
//         address tokenY;
//         uint16 binStep;
//         uint256 amountXMin;
//         uint256 amountYMin;
//         uint256[] ids;
//         uint256[] amounts;
//         uint256 deadline;
//     }

//     event LBPairCreated(address pair);
//     function createLBPair(
//         IERC20 tokenX, 
//         IERC20 tokenY, 
//         uint24 activeId, 
//         uint16 binStep
//     )external returns (ILBPair pair){
//         pair = ILBFactory(factory).createLBPair(tokenX, tokenY, activeId, binStep);
//         liquidityInfo[address(this)] = LiquidityInfo({
//             pair: address(pair),
//             amountXAdded: 0,
//             amountYAdded: 0,
//             amountXLeft: 0,
//             amountYLeft: 0,
//             depositIds: new uint256[](0),
//             liquidityMinted: new uint256[](0)
//         });
//         emit LBPairCreated(address(pair));
//         return pair;
//     }

//     function addLiquidity(
//         addLiquidityParams memory params
//     )external payable {
//         IERC20(params.tokenX).safeTransferFrom(msg.sender, address(this), params.amountx);
//         IERC20(params.tokenY).safeTransferFrom(msg.sender, address(this), params.amounty);
//         IERC20(params.tokenX).approve(params.router, params.amountx);
//         IERC20(params.tokenY).approve(params.router, params.amounty);
//         int256[] memory newDeltaIds = new int256[](params.deltaIds.length);
//         for (uint256 i = 0; i < params.deltaIds.length; i++) {
//             newDeltaIds[i] = params.deltaIds[i];
//         }
//         uint256[] memory newDistributionX = new uint256[](params.distributionX.length);
//         for (uint256 i = 0; i < params.distributionX.length; i++) {
//             newDistributionX[i] = params.distributionX[i];
//         }
//         uint256[] memory newDistributionY = new uint256[](params.distributionY.length);
//         for (uint256 i = 0; i < params.distributionY.length; i++) {
//             newDistributionY[i] = params.distributionY[i];
//         }
//         ILBRouter.LiquidityParameters memory liquidityParameters = ILBRouter.LiquidityParameters({
//             tokenX: IERC20(params.tokenX),
//             tokenY: IERC20(params.tokenY),
//             binStep: params.binStep,   
//             amountX: params.amountx,
//             amountY: params.amounty,
//             amountXMin: params.amountx * (10000 - params.slippage) / 10000,
//             amountYMin: params.amounty * (10000 - params.slippage) / 10000,
//             activeIdDesired: 0,
//             idSlippage: params.slippage,
//             deltaIds: newDeltaIds,
//             distributionX: newDistributionX,
//             distributionY: newDistributionY,
//             to: address(this),
//             refundTo: address(this),
//             deadline: block.timestamp + params.deadline
//         }); 
//         (uint256 amountXAdded,
//             uint256 amountYAdded,
//             uint256 amountXLeft,
//             uint256 amountYLeft,
//             uint256[] memory depositIds,
//             uint256[] memory liquidityMinted)=ILBRouter(params.router).addLiquidity(liquidityParameters);
//         liquidityInfo[address(this)] = LiquidityInfo({
//             pair: params.pair,
//             amountXAdded: amountXAdded,
//             amountYAdded: amountYAdded,
//             amountXLeft: amountXLeft,
//             amountYLeft: amountYLeft,
//             depositIds: depositIds,
//             liquidityMinted: liquidityMinted
//         });
//         pairId++;
//     }

//     function removeLiquidity(
//         removeLiquidityParams calldata params
//     ) external returns (uint256 amountX, uint256 amountY){
//         ILBPair(liquidityInfo[address(this)].pair).approveForAll(params.router, true);

//         (amountX, amountY)=ILBRouter(params.router).removeLiquidity(
//             IERC20(params.tokenX),
//             IERC20(params.tokenY),
//             params.binStep,
//             params.amountXMin,
//             params.amountYMin,
//             params.ids,
//             params.amounts,
//             address(this),
//             block.timestamp + params.deadline   
//         );
//     }


//     function crossUSDC(
//         uint16 indexDestHook,
//         uint32 destinationDomain,
//         uint64 sendBlock,
//         address usdc,
//         uint256 amount
//     ) public onlyManager {
//         bytes32 hook = _getValidHook(destinationDomain, indexDestHook);
//         uint256 balance = _tokenBalance(usdc, address(this));
//         if (balance == 0) {
//             revert ZeroBalance(ErrorType.ZeroBalance);
//         }
//         address crossCenter = _crossCenter();
//         IERC20(usdc).approve(crossCenter, amount);
//         ICrossCenter(crossCenter).crossUSDC(
//             destinationDomain,
//             sendBlock,
//             hook,
//             usdc,
//             amount
//         );
//     }

//     function receiveUSDC(
//         bytes calldata message,
//         bytes calldata attestation
//     ) external {
//         address crossCenter = _crossCenter();
//         ICrossCenter(crossCenter).receiveUSDC(message, attestation);
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

//     function _getValidHook(uint32 destinationDomain, uint16 indexDestHook) private view returns(bytes32 validHook){
//         validHook = IVineHookCenter(govern).getDestHook(id, destinationDomain, indexDestHook);
//     }

//     function _crossCenter() private view returns(address crossCenter){
//         crossCenter = IVineHookCenter(govern).getMarketInfo(id).crossCenter;
//     }

//     function getTokenBalance(
//         address token,
//         address user
//     ) external view returns (uint256 _thisTokenBalance) {
//         _thisTokenBalance = _tokenBalance(token, user);
//     }



        
// }
