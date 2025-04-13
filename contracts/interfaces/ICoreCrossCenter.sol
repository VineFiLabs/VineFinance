// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface ICoreCrossCenter {
    enum ErrorType {
        CrossUSDCFail,
        ReceiveUSDCFail,
        ReStartFail,
        ZeroAddress
    }
    error CrossUSDCFail(ErrorType errorType);
    error ReceiveUSDCFail(ErrorType errorType);
    error ZeroAddress(ErrorType errorType);

    event SetValidHook(bytes32 indexed hook, bytes1 state);
    event HookCrossUSDC(
        address indexed sender,
        bytes32 indexed receiver,
        uint256 amount
    );

    struct HookCrossRecord {
        uint32 destinationDomain;
        uint64 lastestTime;
        uint64 lastestBlock;
        uint64 usdcNonce;
        bytes32 destHook; 
        uint256 lastestCrossAmount;
    }

    function owner() external view returns (address);
    function manager() external view returns (address);
    function govern() external view returns (address);
    function tokenMessager() external view returns (address);

    function _ValidFactory(address) external view returns (bytes1);

    function crossUSDC(
        uint32 destinationDomain,
        uint64 sendBlock,
        bytes32 destHook,
        uint256 amount
    ) external;

    function receiveUSDC(
        bytes calldata message,
        bytes calldata attestation
    ) external returns(bool) ;

    function reStart(
        bytes calldata originalMessage,
        bytes calldata originalAttestation,
        bytes32 newDestinationCaller,
        bytes32 destHook
    ) external;

    function getvalidAttsetation(
        bytes calldata _attsetation
    ) external view returns (bytes1 state);

    function getHookCrossRecord(
        bytes32 hook
    ) external view returns (HookCrossRecord memory newHookCrossRecord);

    function addressToBytes32(address _address) external view returns (bytes32);

    function bytes32ToAddress(
        bytes32 _mintReceiver
    ) external view returns (address);
}
