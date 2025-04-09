// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IPool} from "../../interfaces/aaveV3/IPool.sol";
import {ICoreCrossCenter} from "../../interfaces/core/ICoreCrossCenter.sol";
import {IGovernance} from "../../interfaces/core/IGovernance.sol";
import {IVineStruct} from "../../interfaces/IVineStruct.sol";
import {IVineEvent} from "../../interfaces/IVineEvent.sol";
import {IVineErrors} from "../../interfaces/IVineErrors.sol";
import {ISharer} from "../../interfaces/ISharer.sol";
import {VineLib} from "../../libraries/VineLib.sol";
import {IVineVaultCore} from "../../interfaces/core/IVineVaultCore.sol";
import {IRewardPool} from "../../interfaces/reward/IRewardPool.sol";
import {IVineConfig1} from "../../interfaces/core/IVineConfig1.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title VineAaveV3LendMain02
/// @author VineLabs member 0xlive(https://github.com/VineFiLabs)
/// @notice VineFinance Main Market core contract
contract VineAaveV3LendMain02 is
    ReentrancyGuard,
    IVineStruct,
    IVineEvent,
    IVineErrors,
    ISharer
{
    using SafeERC20 for IERC20;
    
    uint64 public curatorId;
    address public factory;
    address public govern;
    address public owner;
    address public manager;

    bytes1 private immutable ZEROBYTES1;
    bytes1 private immutable ONEBYTES1 = 0x01;
    uint16 private referralCode;

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

    mapping(uint256 => strategyInfo) private StrategyInfo; 

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

    /**
    * @notice The curator of the main market sets whether a policy is locked.
    * @param id The market ID belonging to this main market
    * @param state 0x00 No lock, otherwise lock deposite function
    */
    function setLock(uint256 id, bytes1 state) external onlyManager {
        _checkValidId(id);
        StrategyInfo[id].lockState = state;
    }

    /**
    * @notice Users pledge assets from this main market, or from VineRouter, and the assets are pledged directly into AaveV3.
    * For security, please Approve the size of the amount pledged.
    * @param indexConfig The configuration index of VineConfig1 is passed 0 by the AaveV3 module
    * @param id The market ID belonging to this main market
    * @param amount Quantity supplied from VineVault to AaveV3
    */
    function deposite(
        uint256 id,
        uint8 indexConfig,
        uint64 amount,
        address receiver
    ) external nonReentrant {
        _checkValidId(id);
        require(StrategyInfo[id].lockState == ZEROBYTES1, "Lock");
        //amount >= 10000
        require(amount >= 10000, "Least 10000");
        uint64 currentTime = uint64(block.timestamp);
        uint256 shareTokenAmount = (_getMarketInfo(id).endTime - currentTime) * amount;
        require(currentTime <= _getMarketInfo(id).bufferTime, "Over buffer time");

        address vineVault = _getMarketInfo(id).vineVault;
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address aavePool = _getVineConfig(indexConfig, id).callee;
        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(usdc).safeTransfer(vineVault, amount);
        emit AaveV3Supply(id, amount);
        if(_aaveSupply(vineVault, aavePool, usdc, amount) == false){
            revert SupplyFail(0x17);
        }

        StrategyInfo[id].depositeTotalAmount += amount;
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
        require(block.timestamp >= _getMarketInfo(id).endTime + 12 hours, "Non withdraw time");
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address vineVault = _getMarketInfo(id).vineVault;
        uint256 userShareTokenAmount = _tokenBalance(vineVault, msg.sender);
        uint256 thisTotalSupply = IERC20(vineVault).totalSupply();
        require(StrategyInfo[id].finallyAmount > 0, "Zero finallyAmount");
        uint256 earnAmount = VineLib._getUserFinallyAmount(
            _getMarketInfo(id).curatorFee, 
            _getMarketInfo(id).protocolFee, 
            _UserSupplyInfo[msg.sender][id].pledgeAmount, 
            StrategyInfo[id].depositeTotalAmount, 
            userShareTokenAmount, 
            StrategyInfo[id].finallyAmount, 
            thisTotalSupply
        );
        require(earnAmount >0, "Zero");
        if(IVineVaultCore(vineVault).callVault(usdc, earnAmount) == false){
            revert CallVaultFail(0x15);
        }
        IERC20(usdc).safeTransfer(msg.sender, earnAmount);
        _UserSupplyInfo[msg.sender][id].pledgeAmount = 0;

        //reward
        IRewardPool(_getMarketInfo(id).rewardPool).reward(
            id,
            msg.sender,
            thisTotalSupply
        );

        emit UserWithdraw(id, msg.sender, earnAmount);
        require(IVineVaultCore(vineVault).withdrawBurn(msg.sender, userShareTokenAmount) == ONEBYTES1, "Burn fail");
    }

    /**
    * @notice The curators of this main market extract profitable strategy fees from VineVault
    * @param indexConfig The configuration index of VineConfig1 is passed 0 by the AaveV3 module
    * @param id The market ID belonging to this main market
    */
    function withdrawFee(uint8 indexConfig, uint256 id) external nonReentrant {
        _checkValidId(id);
        uint16 curatorFee = _getMarketInfo(id).curatorFee;
        uint64 endTime = _getMarketInfo(id).endTime;
        address feeReceiver = _getMarketInfo(id).feeReceiver;
        address vineVault = _getMarketInfo(id).vineVault;
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        uint256 curatorFeeAmount = VineLib._curatorFeeAmount(
            curatorFee,
            StrategyInfo[id].depositeTotalAmount,  
            StrategyInfo[id].finallyAmount
        );
        require(curatorFeeAmount>0, "Zero fee");
        require(feeReceiver != address(0), "Zero address");
        require(block.timestamp >= endTime + 12 hours, "Non Withdraw Time");
        if(CuratorWithdrawState[manager][id] == false){
            if(IVineVaultCore(vineVault).callVault(usdc, curatorFeeAmount) == false){
                revert CallVaultFail(0x15);
            }
            IERC20(usdc).safeTransfer(
                feeReceiver,
                curatorFeeAmount
            );
            CuratorWithdrawState[manager][id] = true;
        }else {
            revert AlreadyWithdraw(0x18);
        }
    }

    /**
    * @notice Vinelabs collects fees from profitable strategies that it captures
    * @param indexConfig The configuration index of VineConfig1 is passed 0 by the AaveV3 module
    * @param id The market ID belonging to this main market
    */
    function officeWithdraw(uint8 indexConfig, uint256 id) external nonReentrant {
        _checkValidId(id);
        require(block.timestamp >= _getMarketInfo(id).endTime + 12 hours, "Non Withdraw Time");
        address vineVault = _getMarketInfo(id).vineVault;
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        if(StrategyInfo[id].protocolFeeState == ZEROBYTES1){
            uint256 officialFeeAmount = VineLib._protocolFeeAmount
            (
                _getMarketInfo(id).protocolFee, 
                StrategyInfo[id].depositeTotalAmount, 
                StrategyInfo[id].finallyAmount
            );
            if(IVineVaultCore(vineVault).callVault(usdc, officialFeeAmount) == false){
                revert CallVaultFail(0x15);
            }
            if(officialFeeAmount > 0){
                IERC20(usdc).safeTransfer(
                    _getMarketInfo(id).protocolFeeReceiver,
                    officialFeeAmount
                );
                StrategyInfo[id].protocolFeeState = ONEBYTES1;
            }
        }else {
            revert AlreadyWithdraw(0x18);
        }
    }

    /**
    * @notice The curators of this main market supply AaveV3 deployed on Layer1 and receive ATtokens in VineVault.
    * @param indexConfig The configuration index of VineConfig1 is passed 0 by the AaveV3 module
    * @param id The market ID belonging to this main market
    * @param amount Quantity supplied from VineVault to AaveV3
    */
    function inL1Supply(
        uint8 indexConfig,
        uint256 id,
        uint256 amount
    ) external onlyManager {
        _checkValidId(id);
        _checkValidEndTime(id);
        address vineVault = _getMarketInfo(id).vineVault;
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address usdcPool = _getVineConfig(indexConfig, id).callee;
        emit AaveV3Supply(id, amount);
        if(_aaveSupply(vineVault, usdcPool, usdc, amount) == false){
            revert SupplyFail(0x17);
        }
    }

    /**
    * @notice The curator or anyone 12h after the expiration of the policy can extract VineVault from Layer1 and Layer1's AaveV3,
    * and the corresponding number of tokens in the VineVault will be destroyed.
    * @param indexConfig The configuration index of VineConfig1 is passed 0 by the AaveV3 module
    * @param id The market ID belonging to this main market
    * @param ausdcAmount Quantity supplied from VineVault to AaveV3
    */
    function inL1Withdraw(
        uint8 indexConfig,
        uint256 id,
        uint256 ausdcAmount
    ) external {
        _checkValidId(id);
        _checkOperator(id);
        address vineVault = _getMarketInfo(id).vineVault;
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address ausdc = _getVineConfig(indexConfig, id).derivedToken;
        address usdcPool = _getVineConfig(indexConfig, id).callee;
        emit AaveV3Withdraw(id, ausdcAmount);
        require(_aaveWithdraw(vineVault, usdcPool, ausdc, usdc, ausdcAmount), "Withdraw fail");
        _updateFinallyAmount(id, usdc, vineVault);
    }
        
    /**
    * @notice The curator performs CCTP cross-chain operations, 
    * sending the funds of a strategy to the VineVault of the market of the target chain before the strategy ends
    * @param id The market ID belonging to this main market
    * @param indexConfig The configuration index of VineConfig1 is passed 0 by the AaveV3 module
    * @param destinationDomain CCTP domain of the target chain
    * @param inputBlock The block number that accompanies the transaction initiation
    * @param amount Cross-chain quantity
    */
    function crossUSDC(
        uint256 id,
        uint8 indexConfig,
        uint32 destinationDomain,
        uint64 inputBlock,
        uint256 amount
    ) external onlyManager {
        _checkValidId(id);
        _checkValidEndTime(id);
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        bytes32 destVault = _getValidVault(id, destinationDomain);
        address crossCenter = _getMarketInfo(id).crossCenter;
        address currentVault = _getMarketInfo(id).vineVault;
        require(_bytes32ToAddress(destVault) != currentVault, "Invalid destinationDomain");
        if(IVineVaultCore(currentVault).callVault(usdc, amount) == false){
            revert CallVaultFail(0x15);
        }
        IERC20(usdc).approve(crossCenter, amount);
        ICoreCrossCenter(crossCenter).crossUSDC(
            destinationDomain,
            inputBlock,
            destVault,
            amount
        );
    }

    /**
    * @notice Using CCTP, receive USDC to VineVault for this market.
    * @param indexConfig The configuration index of VineConfig1 is passed 0 by the AaveV3 module
    * @param id The market ID belonging to this main market
    * @param message Source chain information
    * @param attestation Source chain CCTP gives proof
    */
    function receiveUSDC(
        uint8 indexConfig,
        uint256 id,
        bytes calldata message,
        bytes calldata attestation
    ) external {
        _checkValidId(id);
        address crossCenter = _getMarketInfo(id).crossCenter;
        require(ICoreCrossCenter(crossCenter).receiveUSDC(
            indexConfig,
            id,
            message,
            attestation
        ));
    }

    /**
    * @notice VineLabs administrator, or update the final amount with CrossCenter, 
    * note that only when VineVault's USDC current amount> bafore finallyAmount is updated
    * @param indexConfig The configuration index of VineConfig1 is passed 0 by the AaveV3 module
    * @param id The market ID belonging to this main market
    */
    function updateFinallyAmount(uint8 indexConfig, uint256 id) external {
        _checkValidId(id);
        address usdc = _getVineConfig(indexConfig, id).mainToken;
        address crossCenter = _getMarketInfo(id).crossCenter;
        address vineVault = _getMarketInfo(id).vineVault;
        require(msg.sender == crossCenter || msg.sender == _officialManager());
        require(_updateFinallyAmount(id, usdc, vineVault) == ONEBYTES1, "Update fail");
    }

    /**
    * @notice The administrator of VineLabs deletes tokens to the VineVault of the corresponding market ID
    * @param token token to be cleared
    * @param id The market ID belonging to this main market
    * @param amount Clearance quantity
    */
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
        uint256 beforeFinallyAmount = StrategyInfo[id].finallyAmount;
        uint64 usdcBalance = uint64(_tokenBalance(usdc, vineVault));
        if(block.timestamp >= endTime){
            if(usdcBalance > beforeFinallyAmount){
                 StrategyInfo[id].finallyAmount = usdcBalance;
            }
        }
        return ONEBYTES1;
    }

    function _aaveSupply(
        address vineVault,
        address usdcPool,
        address usdc,
        uint256 amount
    ) private returns (bool state) {
        bytes memory payload = abi.encodeCall(
            IPool(usdcPool).supply,
            (usdc, amount, vineVault, referralCode)
        );
        state = IVineVaultCore(vineVault).callWay(
            2,
            usdc,
            usdcPool,
            amount,
            payload
        );
    }

    function _aaveWithdraw(
        address vineVault,
        address usdcPool,
        address ausdc,
        address usdc,
        uint256 amount
    ) private returns (bool state) {
        bytes memory payload = abi.encodeCall(
            IPool(usdcPool).withdraw,
            (usdc, amount, vineVault)
        );
        state = IVineVaultCore(vineVault).callWay(
            2,
            ausdc,
            usdcPool,
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

    function _officialManager() private view returns(address _offManager){
        _offManager = IGovernance(govern).manager();
    }

    function _checkValidId(uint256 id) private view {
        require(curatorId == _getMarketInfo(id).userId, "Not this curator");
    }

    function _checkOperator(uint256 id) private view {
        require(msg.sender == manager || (block.timestamp > _getMarketInfo(id).endTime + 12 hours), "Non manager or not emergency time");
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

    function _getValidVault(uint256 id, uint32 destinationDomain) private view returns(bytes32 validVault){
        validVault = IGovernance(govern).getDestVault(id, destinationDomain);
    }

    function _checkValidEndTime(uint256 id) private view {
        uint64 endTime = _getMarketInfo(id).endTime;
        require(block.timestamp < endTime, "Over end time");
    }

    function _getMarketInfo(uint256 id) private view returns(IGovernance.MarketInfo memory _marketInfo){
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
        
    /**
    * @notice Gets information that the user supplies to a policy
    * @param user The user who made the pledge
    * @param id The market ID belonging to this main market
    * @return Return the UserSupplyInfo struct
    */
    function getUserSupply(address user, uint256 id)external view returns(UserSupplyInfo memory){
        return _UserSupplyInfo[user][id];
    }
    
    /**
    * @notice Get some strategic information for this main market
    * @param id The market ID belonging to this main market
    * @return Return the strategyInfo struct
    */
    function getStrategyInfo(uint256 id) external view returns(strategyInfo memory) {
        return StrategyInfo[id];
    }
    
    /**
    * @notice Whether the curator has extracted curatorial fees for a strategy
    * @param id The market ID belonging to this main market
    * @return Return withdraw bool status
    */
    function getCuratorWithdrawState(address user, uint256 id) external view returns(bool) {
        return CuratorWithdrawState[user][id];
    }

}
