// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@fhenixprotocol/cofhe-contracts/FHE.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IConfidentialERC7984Like.sol";

/// @title CoffheeSwap
/// @notice Minimal fixed-rate confidential token swap for two Fhenix-style confidential tokens.
/// @dev This is intentionally simple:
///      - fixed public rate
///      - no AMM curve
///      - no slippage logic
///      - no fee
///      - designed for tokens that support Fhenix euint64 confidential transfers
// ArbSepolia address: 0xd30B60e2b53133899CC10c9f53eb61C05e053CF0

contract CoffheeSwap is Ownable {
    IConfidentialERC7984Like public immutable tokenA;
    IConfidentialERC7984Like public immutable tokenB;

    // Public fixed rates:
    // A -> B : amountOut = amountIn * rateAToBNumerator / rateAToBDenominator
    uint64 public rateAToBNumerator;
    uint64 public rateAToBDenominator;

    // B -> A : amountOut = amountIn * rateBToANumerator / rateBToADenominator
    uint64 public rateBToANumerator;
    uint64 public rateBToADenominator;

    event SwapAForB(address indexed sender);
    event SwapBForA(address indexed sender);
    event RatesUpdated(
        uint64 aToBNumerator,
        uint64 aToBDenominator,
        uint64 bToANumerator,
        uint64 bToADenominator
    );

    constructor(
        address _tokenA,
        address _tokenB,
        uint64 _rateAToBNumerator,
        uint64 _rateAToBDenominator,
        uint64 _rateBToANumerator,
        uint64 _rateBToADenominator,
        address initialOwner
    ) Ownable(initialOwner) {
        require(_tokenA != address(0), "tokenA=0");
        require(_tokenB != address(0), "tokenB=0");
        require(_tokenA != _tokenB, "same token");
        require(_rateAToBDenominator != 0, "A/B denom=0");
        require(_rateBToADenominator != 0, "B/A denom=0");

        tokenA = IConfidentialERC7984Like(_tokenA);
        tokenB = IConfidentialERC7984Like(_tokenB);

        rateAToBNumerator = _rateAToBNumerator;
        rateAToBDenominator = _rateAToBDenominator;
        rateBToANumerator = _rateBToANumerator;
        rateBToADenominator = _rateBToADenominator;
    }

    function setRates(
        uint64 _rateAToBNumerator,
        uint64 _rateAToBDenominator,
        uint64 _rateBToANumerator,
        uint64 _rateBToADenominator
    ) external onlyOwner {
        require(_rateAToBDenominator != 0, "A/B denom=0");
        require(_rateBToADenominator != 0, "B/A denom=0");

        rateAToBNumerator = _rateAToBNumerator;
        rateAToBDenominator = _rateAToBDenominator;
        rateBToANumerator = _rateBToANumerator;
        rateBToADenominator = _rateBToADenominator;

        emit RatesUpdated(
            _rateAToBNumerator,
            _rateAToBDenominator,
            _rateBToANumerator,
            _rateBToADenominator
        );
    }

    /// @notice Swap confidential token A for confidential token B.
    /// @param encryptedAmountIn Encrypted uint64 prepared by the CoFHE SDK.
    function swapAForB(InEuint64 memory encryptedAmountIn) external {
        euint64 amountIn = FHE.asEuint64(encryptedAmountIn);

        // Let this contract operate on the incoming amount.
        FHE.allowThis(amountIn);

        // Pull token A from user -> pool.
        // Assumes the token contract accepts a previously-authorized euint64 handle.
        tokenA.confidentialTransferFrom(msg.sender, address(this), amountIn);

        // Compute amountOut = amountIn * num / denom
        euint64 num = FHE.asEuint64(rateAToBNumerator);
        euint64 den = FHE.asEuint64(rateAToBDenominator);
        euint64 amountOut = FHE.div(FHE.mul(amountIn, num), den);

        // Give the token contract temporary access to the computed ciphertext so it can transfer it.
        FHE.allowTransient(amountOut, address(tokenB));

        // Send token B from pool -> user.
        tokenB.confidentialTransfer(msg.sender, amountOut);

        // Optional ACLs for the local handle
        FHE.allowThis(amountOut);
        FHE.allowSender(amountOut);

        emit SwapAForB(msg.sender);
    }

    /// @notice Swap confidential token B for confidential token A.
    /// @param encryptedAmountIn Encrypted uint64 prepared by the CoFHE SDK.
    function swapBForA(InEuint64 memory encryptedAmountIn) external {
        euint64 amountIn = FHE.asEuint64(encryptedAmountIn);

        FHE.allowThis(amountIn);

        tokenB.confidentialTransferFrom(msg.sender, address(this), amountIn);

        euint64 num = FHE.asEuint64(rateBToANumerator);
        euint64 den = FHE.asEuint64(rateBToADenominator);
        euint64 amountOut = FHE.div(FHE.mul(amountIn, num), den);

        FHE.allowTransient(amountOut, address(tokenA));

        tokenA.confidentialTransfer(msg.sender, amountOut);

        FHE.allowThis(amountOut);
        FHE.allowSender(amountOut);

        emit SwapBForA(msg.sender);
    }

    /// @notice Owner can fund the pool with token A using an encrypted amount.
    function depositTokenA(InEuint64 memory encryptedAmount) external onlyOwner {
        euint64 amount = FHE.asEuint64(encryptedAmount);
        FHE.allowThis(amount);
        tokenA.confidentialTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Owner can fund the pool with token B using an encrypted amount.
    function depositTokenB(InEuint64 memory encryptedAmount) external onlyOwner {
        euint64 amount = FHE.asEuint64(encryptedAmount);
        FHE.allowThis(amount);
        tokenB.confidentialTransferFrom(msg.sender, address(this), amount);
    }
}