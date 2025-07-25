// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IL2Pool} from "../../interfaces/aaveV3/IL2Pool.sol";
import {IL2Encode} from "../../interfaces/aaveV3/IL2Encode.sol";
import {ICoreCrossCenter} from "../../interfaces/core/ICoreCrossCenter.sol";
import {IGovernance} from "../../interfaces/core/IGovernance.sol";
import {IVineStruct} from "../../interfaces/IVineStruct.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {ISharer} from "../../interfaces/ISharer.sol";
import {VineLib} from "../../libraries/VineLib.sol";
import {IVineVaultCore} from "../../interfaces/core/IVineVaultCore.sol";
import {IRewardPool} from "../../interfaces/reward/IRewardPool.sol";
import {IVineConfig1} from "../../interfaces/core/IVineConfig1.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title VineAaveV3LendMain01
/// @author VineLabs member 0xlive(https://github.com/VineFiLabs)
/// @notice VineFinance Main Market core contract
contract VineAaveV3LendMain01 is
    ReentrancyGuard,
    IVineStruct,
    IVineEvent,
    ISharer
{
    using SafeERC20 for IERC20;

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1 = 0x01;
    uint16 private referralCode;
    uint64 public curatorId;
    address public immutable factory;
    address public immutable govern;
    address public immutable owner;
    address public manager;
    uint256 private constant MinLiquidity = 10;

    constructor(
        address _govern, 
        address _owner, 
        address _manager, 
        uint64 _curatorId
    ) {
        factory = msg.sender;
        govern = _govern;
        owner = _owner;
        manager = _manager;
        curatorId = _curatorId;
    }

    mapping(address => mapping(uint256 => UserSupplyInfo)) private _UserSupplyInfo;

    mapping(uint256 => StrategyInfo) private strategyInfo;

    mapping(address => mapping(uint256 => bool)) private CuratorWithdrawState;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }

    function transferManager(address newManager) external onlyOwner {
        manager = newManager;
    }

    function setReferralCode(uint16 _referralCode) external onlyManager {
        referralCode = _referralCode;
    }

    function setLock(uint256 id, bytes1 state) external onlyManager {
        strategyInfo[id].lockState = state;
    }

    //user deposite usdc
    function deposite(
        uint256 id,
        uint8 indexConfig,
        uint64 amount,
        address receiver
    ) external nonReentrant {
        require(strategyInfo[id].lockState == ZEROBYTES1, "Lock");
        uint64 currentTime = uint64(block.timestamp);
        uint256 shareTokenAmount = (_getMarketInfo(id).endTime - currentTime) * amount;
        require(currentTime <= _getMarketInfo(id).bufferTime, "Non buffer time");

        address vineVault = _getMarketInfo(id).vineVault;
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address ausdc =  _getVineConfig(indexConfig, id).derivedToken;
        address l2Pool = _getVineConfig(indexConfig, id).callee;

        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(usdc).safeTransfer(vineVault, amount);
        uint256 beforeAmount = _tokenBalance(ausdc, address(this));
        emit AaveV3Supply(id, amount);
        require(_aaveSupply(vineVault, l2Pool, usdc, amount), "Supply fail");
        uint256 afterAmount = _tokenBalance(ausdc, address(this));
        uint256 skimAmount = afterAmount - beforeAmount;
        _skim(ausdc, vineVault, skimAmount);

        strategyInfo[id].depositeTotalAmount += amount;
        _UserSupplyInfo[receiver][id].pledgeAmount += amount; 
        _UserSupplyInfo[receiver][id].supplyTime = currentTime;
        emit UserDeposite(id, receiver, amount);

        require(IVineVaultCore(vineVault).depositeMint(receiver, shareTokenAmount) == ONEBYTES1, "Mint fail");
    }

    /**
    * @notice Users extract their revenue from this main market
    * @param indexConfig The configuration index of VineConfig1 is passed 0 by the AaveV3 module
    * @param id The market ID belonging to this main market
    */
    function withdraw(uint8 indexConfig, uint256 id) external nonReentrant {
        _checkValidId(id);
        _checkValidWithdrawTime(id);
        uint64 pledgeAmount = _UserSupplyInfo[msg.sender][id].pledgeAmount;
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address vineVault = _getMarketInfo(id).vineVault;
        uint64 depositeTotalAmount = strategyInfo[id].depositeTotalAmount;
        uint64 finallyAmount;

        //user
        {   
            //aave
            {   
                address ausdc = _getVineConfig(indexConfig, id).derivedToken;
                address usdcPool = _getVineConfig(indexConfig, id).callee;
                uint256 ausdcBalance = _tokenBalance(ausdc, vineVault);
                address l2Encode = _getL2Encode();
                bytes32 encodeMessage = IL2Encode(l2Encode).encodeWithdrawParams(
                    usdc,
                    ausdcBalance
                );
                if(ausdcBalance > 0){
                    bytes memory payload = abi.encodeCall(
                        IL2Pool(usdcPool).withdraw,
                        (encodeMessage)
                    );
                    (bool suc, ) = IVineVaultCore(vineVault).callWay(
                        2,
                        ausdc,
                        usdcPool,
                        ausdcBalance,
                        payload
                    );
                    require(suc, "Aave withdraw fail");
                }
            }

            uint256 userShareTokenAmount = _tokenBalance(vineVault, msg.sender);
            uint256 shareTotalSupply = IERC20(vineVault).totalSupply();

            //update
            _updateFinallyAmount(id, usdc, vineVault);
            finallyAmount = strategyInfo[id].finallyAmount;
            require(finallyAmount > 0, "Zero finallyAmount");

            uint256 earnAmount = VineLib._getUserFinallyAmount(
                _getMarketInfo(id).curatorFee, 
                _getMarketInfo(id).protocolFee, 
                pledgeAmount, 
                depositeTotalAmount, 
                userShareTokenAmount, 
                finallyAmount, 
                shareTotalSupply
            );
            require(earnAmount > 0, "Zero");

            IVineVaultCore(vineVault).callVault(usdc, earnAmount);
            if(pledgeAmount > 0){
                _UserSupplyInfo[msg.sender][id].pledgeAmount = 0;
            }
            IERC20(usdc).safeTransfer(msg.sender, earnAmount);

            //reward
            IRewardPool(_getMarketInfo(id).rewardPool).reward(
                id,
                msg.sender,
                shareTotalSupply
            );
            emit UserWithdraw(id, msg.sender, earnAmount);
            strategyInfo[id].extractedAmount += uint64(earnAmount);
            require(IVineVaultCore(vineVault).withdrawBurn(msg.sender, userShareTokenAmount) == ONEBYTES1, "Burn fail");
        }

        
        {   
            uint256 officialFeeAmount = VineLib._protocolFeeAmount
            (
                _getMarketInfo(id).protocolFee, 
                depositeTotalAmount, 
                finallyAmount
            );
            uint256 curatorFeeAmount = VineLib._curatorFeeAmount(
                _getMarketInfo(id).curatorFee,
                depositeTotalAmount,  
                finallyAmount
            );
            IVineVaultCore(vineVault).callVault(usdc, officialFeeAmount + curatorFeeAmount);
            //curator
            if(CuratorWithdrawState[manager][id] == false){
                address curatorFeeReceiver = _getMarketInfo(id).feeReceiver;
                if(curatorFeeAmount > 0){
                    IERC20(usdc).safeTransfer(
                        curatorFeeReceiver == address(0) ? owner : curatorFeeReceiver,
                        curatorFeeAmount
                    );
                    strategyInfo[id].extractedAmount += uint64(curatorFeeAmount);
                    CuratorWithdrawState[manager][id] = true;
                }
            }

            //official
            if(strategyInfo[id].protocolFeeState == ZEROBYTES1){
                if(officialFeeAmount > 0){
                    IERC20(usdc).safeTransfer(
                        _getMarketInfo(id).protocolFeeReceiver,
                        officialFeeAmount
                    );
                    strategyInfo[id].extractedAmount += uint64(officialFeeAmount);
                    strategyInfo[id].protocolFeeState = ONEBYTES1;
                }
            }
        }

    }

    function inL2Supply(
        uint8 indexConfig,
        uint256 id,
        uint256 amount
    ) external onlyManager {
        _checkValidId(id);
        _checkValidEndTime(id);
        address vineVault = _getMarketInfo(id).vineVault;
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address l2Pool = _getVineConfig(indexConfig, id).callee;
        emit AaveV3Supply(id, amount);
        require(_aaveSupply(vineVault, l2Pool, usdc, amount), "Supply fail");
    }

    function inL2Withdraw(
         uint8 indexConfig,
        uint256 id,
        uint256 amount
    ) external {
        _checkValidId(id);
        _checkOperator(id);
        address vineVault = _getMarketInfo(id).vineVault;
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address ausdc = _getVineConfig(indexConfig, id).derivedToken;
        address l2Pool = _getVineConfig(indexConfig, id).callee;
        emit AaveV3Withdraw(id, amount);
        require(_aaveWithdraw(vineVault, l2Pool, ausdc, usdc, amount), "Withdraw fail");
        require(_updateFinallyAmount(id, usdc, vineVault) == ONEBYTES1, "Update finally amount fail");
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
        require(destVault != currentVault && destVault != address(0));
        IVineVaultCore(currentVault).callVault(usdc, params.amount);
        if(params.sameChain){
            IERC20(usdc).safeTransfer(destVault, params.amount);
        }else {
            IERC20(usdc).approve(crossCenter, params.amount);
            ICoreCrossCenter(crossCenter).crossUSDC(
                params.destinationDomain,
                params.inputBlock,
                bytes32DestVault,
                params.amount
            );
        }
    }

    function receiveUSDC(
        uint8 indexConfig,
        uint256 id,
        bytes calldata message,
        bytes calldata attestation
    ) external onlyManager {
        _checkValidId(id);
        address crossCenter = _getMarketInfo(id).crossCenter;
        bool _receiveState = ICoreCrossCenter(crossCenter).receiveUSDC(
            indexConfig,
            id,
            message,
            attestation
        );
        require(_receiveState);
    }
    
    function updateFinallyAmount(uint8 indexConfig, uint256 id) external {
        _checkValidId(id);
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address crossCenter = _getMarketInfo(id).crossCenter;
        address vineVault = _getMarketInfo(id).vineVault;
        require(msg.sender == crossCenter || msg.sender == _officialManager());
        require(_updateFinallyAmount(id, usdc, vineVault) == ONEBYTES1, "Update finally amount fail");
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

    function _updateFinallyAmount(
        uint256 id, 
        address usdc, 
        address vineVault
    ) private returns(bytes1) {
        uint64 endTime = _getMarketInfo(id).endTime;
        uint64 beforeFinallyAmount = strategyInfo[id].finallyAmount;
        uint64 currentBalance = uint64(_tokenBalance(usdc, vineVault));
        uint64 currentFinallyAmount =  currentBalance + strategyInfo[id].extractedAmount;
        if(block.timestamp >= endTime){
            if(currentFinallyAmount > beforeFinallyAmount){
                 strategyInfo[id].finallyAmount = currentFinallyAmount;
            }
        }
        return ONEBYTES1;
    }

    function _aaveSupply(
        address vineVault,
        address l2Pool,
        address usdc,
        uint256 amount
    ) private returns (bool state) {
        address l2Encode = _getL2Encode();
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeSupplyParams(
            usdc,
            amount,
            referralCode
        );
        bytes memory payload = abi.encodeCall(
            IL2Pool(l2Pool).supply,
            (encodeMessage)
        );
        (state, ) = IVineVaultCore(vineVault).callWay(
            2,
            usdc,
            l2Pool,
            amount,
            payload
        );
    }

    function _aaveWithdraw(
        address vineVault,
        address l2Pool,
        address ausdc,
        address usdc,
        uint256 amount
    ) private returns (bool state) {
        address l2Encode = _getL2Encode();
        bytes32 encodeMessage = IL2Encode(l2Encode).encodeWithdrawParams(
            usdc,
            amount
        );

        bytes memory payload = abi.encodeCall(
             IL2Pool(l2Pool).withdraw,
            (encodeMessage)
        );
        (state, ) = IVineVaultCore(vineVault).callWay(
            2,
            ausdc,
            l2Pool,
            amount,
            payload
        );
    }

    function _checkOwner() private view {
        require(msg.sender == owner, "Non owner");
    }

    function _checkManager() private view {
        require(msg.sender == manager, "Non manager");
    }

    function _officialManager() private view returns(address _offManager) {
        _offManager = IGovernance(govern).manager();
    }

    function _getL2Encode() private view returns(address _l2Encode) {
        _l2Encode = IGovernance(govern).getL2Encode();
    }

    function _checkValidWithdrawTime(uint256 id) private view {
        require(block.timestamp >= _getMarketInfo(id).endTime + 12 hours, "Non Withdraw Time");
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

    function _checkValidId(uint256 id) private view {
        require(curatorId == _getMarketInfo(id).userId, "Not this curator");
    }

    function _checkOperator(uint256 id) private view {
        require(msg.sender == manager || (block.timestamp > _getMarketInfo(id).endTime + 12 hours), "Non manager or not emergency time");
    } 

    function _getValidVault(uint256 id, uint32 destinationDomain) private view returns(bytes32 validVault){
        validVault = IGovernance(govern).getDestVault(id, destinationDomain);
    }

    function _checkValidEndTime(uint256 id) private view {
        uint64 endTime = _getMarketInfo(id).endTime;
        require(block.timestamp < endTime, "Over end time");
    }

    function _getMarketInfo(uint256 id) private view returns(IGovernance.MarketInfo memory _marketInfo) {
        _marketInfo = IGovernance(govern).getMarketInfo(id);
    }

    function _getVineConfig(uint8 indexConfig, uint256 id) private view returns (IVineConfig1.calleeInfo memory _calleeInfo){
        _calleeInfo = IVineConfig1(_getMarketInfo(id).vineConfigAddress).getCalleeInfo(indexConfig);
    }

    function _bytes32ToAddress(
        bytes32 _bytes32Account
    ) private pure returns (address) {
        return address(uint160(uint256(_bytes32Account)));
    }

    function getUserSupply(address user, uint256 id) external view returns(UserSupplyInfo memory) {
        return _UserSupplyInfo[user][id];
    }

    function getStrategyInfo(uint256 id) external view returns(StrategyInfo memory) {
        return strategyInfo[id];
    }

    function getCuratorWithdrawState(address user, uint256 id) external view returns(bool) {
        return CuratorWithdrawState[user][id];
    }


}
