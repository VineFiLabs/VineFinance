// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IMessageTransmitter} from "../interfaces/cctp/IMessageTransmitter.sol";
import {ITokenMessenger} from "../interfaces/cctp/ITokenMessenger.sol";
import {IVineStruct} from "../interfaces/IVineStruct.sol";
import {ICoreCrossCenter} from "../interfaces/ICoreCrossCenter.sol";
import {IGovernance} from "../interfaces/core/IGovernance.sol";
import {IFactorySharer} from "../interfaces/IFactorySharer.sol";
import {ISharer} from "../interfaces/ISharer.sol";
import {IVineAaveV3LendMain} from "../interfaces/IVineAaveV3LendMain.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CoreCrossCenter is
    ICoreCrossCenter,
    IVineStruct
{
    using SafeERC20 for IERC20;

    bytes1 private immutable ZEROBYTES1;
    bytes32 private immutable ZEROBYTES32;
    address public owner;
    address public manager;
    address public govern;
    address public usdc;
    address public tokenMessager;
    address public messageTransmitter;

    constructor(
        address _owner,
        address _manager,
        address _govern,
        address _usdc,
        address _tokenMessager,
        address _messageTransmitter
    ) {
        owner = _owner;
        manager = _manager;
        govern = _govern;
        usdc = _usdc;
        tokenMessager = _tokenMessager;
        messageTransmitter = _messageTransmitter;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyManager() {
        _checkManager();
        _;
    }

    mapping(address => bytes1) public _ValidFactory;

    mapping(bytes32 => HookCrossRecord) private _HookCrossRecord;

    mapping(bytes => bytes1) private _ValidAttsetation;

    function transferOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function transferManager(address newManager) external onlyOwner {
        manager = newManager;
    }

    function setUSDC(address _usdc) external onlyManager {
        usdc = _usdc;
    }

    function batchSetValidCaller(
        address[] calldata callers,
        bytes1[] calldata states
    ) external onlyManager {
        unchecked {
            for (uint256 i; i < callers.length; i++) {
                _ValidFactory[callers[i]] = states[i];
            }
        }
    }

    function setCCTPConfig(
        address _tokenMessager,
        address _messageTransmitter
    ) external onlyManager {
        tokenMessager = _tokenMessager;
        messageTransmitter = _messageTransmitter;
    }

    function crossUSDC(
        uint32 destinationDomain,
        uint64 sendBlock,
        bytes32 destHook,
        uint256 amount
    ) external {
        _checkValidCaller();
        bytes1 crossUSDCState = _crossUSDC(
            destinationDomain,
            sendBlock,
            destHook,
            amount
        );
        if (crossUSDCState != 0x01) {
            revert CrossUSDCFail(ErrorType.CrossUSDCFail);
        }
    }

    function receiveUSDC(
        bytes calldata message,
        bytes calldata attestation
    ) external returns(bool) {
        _checkValidCaller();
        bool _receiveState = IMessageTransmitter(messageTransmitter).receiveMessage(
            message,
            attestation
        );
        _ValidAttsetation[attestation] = 0x01;
        IVineAaveV3LendMain(msg.sender).updateFinallyAmount(usdc);
        return _receiveState;
    }

    function reStart(
        bytes calldata originalMessage,
        bytes calldata originalAttestation,
        bytes32 newDestinationCaller,
        bytes32 destHook
    ) external onlyManager {
        if (destHook == ZEROBYTES32) {
            revert ZeroAddress(ErrorType.ZeroAddress);
        }
        ITokenMessenger(tokenMessager).replaceDepositForBurn(
            originalMessage,
            originalAttestation,
            newDestinationCaller,
            destHook
        );
    }

    function emergency(
        uint32 destinationDomain, 
        uint8 indexDestHook, 
        uint256 id, 
        uint256 amount
    ) external onlyManager {
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));
        require(usdcBalance > 0 && amount <= usdcBalance, "USDC amount error");
        bytes32 bytes32Hook = IGovernance(govern).getDestHook(id, destinationDomain, indexDestHook);
        address hook = bytes32ToAddress(bytes32Hook);
        if(hook == address(0)){
            revert ZeroAddress(ErrorType.ZeroAddress);
        }
        IERC20(usdc).transfer(hook, amount);
    }

    function _crossUSDC(
        uint32 destinationDomain,
        uint64 sendBlock,
        bytes32 destHook,
        uint256 amount
    ) private returns (bytes1) {
        if (destHook == ZEROBYTES32) {
            revert ZeroAddress(ErrorType.ZeroAddress);
        }
        bytes32 caller = addressToBytes32(msg.sender);
        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(usdc).approve(tokenMessager, amount);
        uint64 nonce = ITokenMessenger(tokenMessager).depositForBurn(
            amount,
            destinationDomain,
            destHook,
            usdc
        );
        _HookCrossRecord[caller] = HookCrossRecord({
            destinationDomain: destinationDomain,
            lastestTime: uint64(block.timestamp),
            lastestBlock: sendBlock,
            usdcNonce: nonce,
            destHook: destHook,
            lastestCrossAmount: amount
        });
        emit HookCrossUSDC(msg.sender, destHook, amount);
        return 0x01;
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

    function _checkValidCaller() internal view {
        address _factory = ISharer(msg.sender).factory();
        require(_ValidFactory[_factory] == 0x01, "Invalid factory");
        bool state = IFactorySharer(_factory).ValidMarket(msg.sender);
        require(state, "Invalid market");
    }

    function _protolcolFeeReceiver() private view returns (address) {
        address protocolFeeReceiver = IGovernance(govern).protocolFeeReceiver();
        if (protocolFeeReceiver == address(0)) {
            return govern;
        } else {
            return protocolFeeReceiver;
        }
    }

    function getvalidAttsetation(
        bytes calldata _attsetation
    ) external view returns (bytes1 state) {
        state = _ValidAttsetation[_attsetation];
    }

    function getTokenBalance(
        address token,
        address user
    ) external view returns (uint256 _thisTokenBalance) {
        _thisTokenBalance = _tokenBalance(token, user);
    }

    function getHookCrossRecord(
        bytes32 hook
    ) external view returns (HookCrossRecord memory newHookCrossRecord) {
        newHookCrossRecord = _HookCrossRecord[hook];
    }

    function addressToBytes32(address _account) public view returns (bytes32) {
        return bytes32(uint256(uint160(_account)));
    }

    function bytes32ToAddress(
        bytes32 _bytes32Account
    ) public view returns (address) {
        return address(uint160(uint256(_bytes32Account)));
    }
}
