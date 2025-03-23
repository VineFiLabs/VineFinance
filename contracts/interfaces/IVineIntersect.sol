// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IVineIntersect {
    event SwapHook(
        uint256 indexed chainId,
        uint256 indexed marketId,
        address indexed toucher,
        address[] tokens,
        address receiver,
        address router,
        uint256 amount
    );

    event CrossHook(
        uint256 indexed chainId,
        uint256 indexed marketId,
        address indexed toucher,
        address token,
        bytes32 receiver,
        uint256 targetChainId,
        uint256 amount
    );

    event SupplyHook(
        uint256 indexed chainId,
        uint256 indexed marketId,
        address indexed toucher,
        address token,
        uint256 amount
    );

    event WithdrawHook(
        uint256 indexed chainId,
        uint256 indexed marketId,
        address indexed toucher,
        address token,
        uint256 amount
    );

    event CallHook(address indexed hook, uint256 amount, bytes inputData, bytes outputDate);

    function swapEvent(
        uint256 chainId,
        uint256 marketId,
        address[] calldata tokens,
        address receiver,
        address router,
        uint256 amount
    )external;

    function crossEvent(
        uint256 chainId,
        uint256 marketId,
        address token,
        bytes32 receiver,
        uint256 targetChainId,
        uint256 amount
    )external;

    function supplyEvent(
        uint256 chainId,
        uint256 marketId,
        address token,
        uint256 amount
    )external;

    function withdrawEvent(
        uint256 chainId,
        uint256 marketId,
        address token,
        uint256 amount
    )external;
}
