// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@fhenixprotocol/cofhe-contracts/FHE.sol";

/// @notice Minimal Fhenix-compatible confidential token interface.
/// @dev This is intentionally "ERC7984-like", not a strict copy of the draft EIP.
///      It is shaped for Fhenix CoFHE's InEuint*/euint* flow.
interface IConfidentialERC7984Like {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /// Optional/read methods for confidential balances
    function confidentialBalanceOf(address account) external view returns (euint64);

    /// Operator model (ERC-7984-inspired)
    function setOperator(address operator, uint48 until) external;
    function isOperator(address holder, address operator) external view returns (bool);

    /// Pull encrypted tokens from `from` to `to`
    /// The token contract is expected to honor FHE ACL permissions on `amount`.
    function confidentialTransferFrom(
        address from,
        address to,
        euint64 amount
    ) external returns (euint64 transferred);

    /// Push encrypted tokens from caller to `to`
    function confidentialTransfer(
        address to,
        euint64 amount
    ) external returns (euint64 transferred);
}