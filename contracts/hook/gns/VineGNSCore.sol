// // SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.8.23;

// import {IMessageTransmitter} from "../../interfaces/cctp/IMessageTransmitter.sol";
// import {ITokenMessenger} from "../../interfaces/cctp/ITokenMessenger.sol";
// import {IVineStruct} from "../../interfaces/IVineStruct.sol";
// import {IVineEvent} from "../../interfaces/IVineEvent.sol";
// import {IVineHookErrors} from "../../interfaces/IVineHookErrors.sol";
// import {ITradingInteractionsUtils, ITradingStorage} from "../../interfaces/gns/ITradingInteractionsUtils.sol";
// import {ITradingStorageUtils} from "../../interfaces//gns/ITradingStorageUtils.sol";
// import {IVineCCTP} from "../../interfaces/IVineCCTP.sol";
// import {IGovernance} from "../../interfaces/core/IGovernance.sol";

// import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// contract VineGNSCore is IVineHookErrors{
//     using SafeERC20 for IERC20;
//     address public owner;
//     address public manager;
//     bool public INITSTATE;
//     IVineCCTP public VineCCTP;
//     address public referrer;

//     constructor(address _owner){
//         referrer = msg.sender;
//         owner = _owner;
//     }

//     mapping(uint32 => address) private destinationDomainToRecever;


//     modifier onlyOwner() {
//         _checkOwner();
//         _;
//     }

//     modifier onlyManager() {
//         _checkManager();
//         _;
//     }

//     function transferOwner(address newOwner) external onlyOwner {
//         owner = newOwner;
//     }

//     function transferManager(address newManager)external onlyOwner{
//         manager = newManager;
//     }

//     function initialize(
//         address _manager,
//         address _VineCCTP,
//         uint32[] calldata destinationDomains,
//         address[] calldata validReceiveGroup
//     ) external onlyOwner {
//         if(INITSTATE != false){
//             revert AlreadyInitialize(ErrorType.AlreadyInitialize);
//         }
//         manager = _manager;
//         VineCCTP = IVineCCTP(_VineCCTP);
//         for (uint256 i = 0; i < validReceiveGroup.length; i++) {
//             destinationDomainToRecever[destinationDomains[i]]=validReceiveGroup[i];
//         }
//         INITSTATE = true;
//     }

//     /**
//     * Arbitrum sepolia usdc:0x4cC7EbEeD5EA3adf3978F19833d2E1f3e8980cD6
//     * approve spender:0xd659a15812064C79E189fd950A189b15c75d3186
//      */

//     //open order
//     function openOrder(
//         address gnsMarket,
//         ITradingStorage.Trade memory trade,
//         uint16 maxSlippageP,
//         address usdcAddress,
//         address spender
//     ) external {
//         IERC20(usdcAddress).safeTransferFrom(msg.sender, address(this), trade.collateralAmount);
//         IERC20(usdcAddress).approve(spender, trade.collateralAmount);
//         ITradingStorage.Trade memory newTrade=ITradingStorage.Trade({
//             user: address(this),
//             index: trade.index,
//             pairIndex: trade.pairIndex,
//             leverage: trade.leverage,
//             long: trade.long,
//             isOpen: trade.isOpen,
//             collateralIndex: trade.collateralIndex,
//             tradeType: trade.tradeType,
//             collateralAmount: trade.collateralAmount,
//             openPrice: trade.openPrice,
//             tp: trade.tp,
//             sl: trade.sl,
//             __placeholder: trade.__placeholder
//         });

//         ITradingInteractionsUtils(gnsMarket).openTrade(newTrade, maxSlippageP, referrer);
//     }

//     function closeTradeMarket(address gnsMarket, uint32 _index, uint64 _expectedPrice)external {
//         ITradingInteractionsUtils(gnsMarket).closeTradeMarket( _index, _expectedPrice);
//     }

//     function updateOpenOrder(
//         address gnsMarket, 
//         uint32 _index, 
//         uint64 _triggerPrice,
//         uint64 _tp,
//         uint64 _sl,
//         uint16 _maxSlippageP
//     )external {
//         ITradingInteractionsUtils(gnsMarket).updateOpenOrder(_index, _triggerPrice, _tp, _sl, _maxSlippageP);
//     }

//     function cancelOpenOrder(address gnsMarket, uint32 _index)external{
//         ITradingInteractionsUtils(gnsMarket).cancelOpenOrder(_index);
//     }

//     function cancelOrderAfterTimeout(address gnsMarket, uint32 _index)external {
//         ITradingInteractionsUtils(gnsMarket).cancelOrderAfterTimeout(_index);
//     }

//     function updateMaxClosingSlippageP(address gnsMarket, uint32 _index, uint16 _maxSlippageP)external {
//         ITradingInteractionsUtils(gnsMarket).updateMaxClosingSlippageP(_index, _maxSlippageP);
//     }

//     function updateTp(address gnsMarket, uint32 _index, uint64 _newTp)external {
//         ITradingInteractionsUtils(gnsMarket).updateTp(_index, _newTp);
//     }

//     function updateSl(address gnsMarket, uint32 _index, uint64 _newSl)external {
//         ITradingInteractionsUtils(gnsMarket).updateSl(_index, _newSl);
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

//     function receiveUSDC(
//         address messageTransmitter,
//         bytes calldata message,
//         bytes calldata attestation
//     ) external onlyManager {
//         VineCCTP.receiveUSDC(messageTransmitter, message, attestation);
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

//     function _VineCCTP() private view returns(address VineCCTP){
//         VineCCTP = IGovernance(govern).VineCCTP();
//     }

// function _getValidVault(uint256 id, uint32 destinationDomain) private view returns(bytes32 validVault){
//         validVault = IVineHookCenter(govern).getDestVault(id, destinationDomain);
//     }

//     function getTokenBalance(
//         address token,
//         address user
//     ) external view returns (uint256 _thisTokenBalance) {
//         _thisTokenBalance = _tokenBalance(token, user);
//     }

//     //0x7c338C4d096D79dFe702b3F4cB13790c25D3AD8e
//     function getTradeInfo(address gnsTradeStorage)external view returns(ITradingStorage.Trade[] memory){
//         return ITradingStorageUtils(gnsTradeStorage).getTrades(address(this));
//     }


// }
