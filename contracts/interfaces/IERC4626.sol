// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

/// @title ERC4626 interface
/// See: https://eips.ethereum.org/EIPS/eip-4626
abstract contract IERC4626 is ERC20 {
    /*////////////////////////////////////////////////////////
                      Events
    ////////////////////////////////////////////////////////*/

    /// @notice `sender_` has exchanged `assets_` for `positions_`,
    /// and transferred those `positions_` to `receiver_`.
    event Deposit(
        address indexed sender_,
        address indexed receiver_,
        uint256 assets_,
        uint256 positions_
    );

    /// @notice `sender_` has exchanged `positions_` for `assets_`,
    /// and transferred those `assets_` to `receiver_`.
    event Withdraw(
        address indexed sender_,
        address indexed receiver_,
        uint256 assets_,
        uint256 positions_
    );

    /*////////////////////////////////////////////////////////
                      Vault properties
    ////////////////////////////////////////////////////////*/

    /// @notice The address of the underlying ERC20 token used for
    /// the Vault for accounting, depositing, and withdrawing.
    function asset() external view virtual returns (address asset);

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    function totalassets_()
        external
        view
        virtual
        returns (uint256 totalassets_);

    /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal Logic
    ////////////////////////////////////////////////////////*/

    /// @notice Mints `positions_` Vault positions_ to `receiver_` by
    /// depositing exactly `assets_` of underlying tokens.
    function deposit(
        uint256 assets_,
        address receiver_
    ) external virtual returns (uint256 positions_);

    /// @notice Mints exactly `positions_` Vault positions_ to `receiver_`
    /// by depositing `assets_` of underlying tokens.
    function mint(
        uint256 positions_,
        address receiver_
    ) external virtual returns (uint256 assets_);

    /// @notice Redeems `positions_` from `owner_` and sends `assets_`
    /// of underlying tokens to `receiver_`.
    function withdraw(
        uint256 assets_,
        address receiver_,
        address owner_
    ) external virtual returns (uint256 positions_);

    /// @notice Redeems `positions_` from `owner_` and sends `assets_`
    /// of underlying tokens to `receiver_`.
    function redeem(
        uint256 positions_,
        address receiver_,
        address owner_
    ) external virtual returns (uint256 assets_);

    /*////////////////////////////////////////////////////////
                      Vault Accounting Logic
    ////////////////////////////////////////////////////////*/

    /// @notice The amount of positions_ that the vault would
    /// exchange for the amount of assets_ provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToShares(
        uint256 assets_
    ) external view virtual returns (uint256 positions_);

    /// @notice The amount of assets_ that the vault would
    /// exchange for the amount of positions_ provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToassets_(
        uint256 positions_
    ) external view virtual returns (uint256 assets_);

    /// @notice Total number of underlying assets_ that can
    /// be deposited by `owner_` into the Vault, where `owner_`
    /// corresponds to the input parameter `receiver_` of a
    /// `deposit` call.
    function maxDeposit(
        address owner_
    ) external view virtual returns (uint256 maxassets_);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their deposit at the current block, given
    /// current on-chain conditions.
    function previewDeposit(
        uint256 assets_
    ) external view virtual returns (uint256 positions_);

    /// @notice Total number of underlying positions_ that can be minted
    /// for `owner_`, where `owner_` corresponds to the input
    /// parameter `receiver_` of a `mint` call.
    function maxMint(
        address owner_
    ) external view virtual returns (uint256 maxpositions_);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their mint at the current block, given
    /// current on-chain conditions.
    function previewMint(
        uint256 positions_
    ) external view virtual returns (uint256 assets_);

    /// @notice Total number of underlying assets_ that can be
    /// withdrawn from the Vault by `owner_`, where `owner_`
    /// corresponds to the input parameter of a `withdraw` call.
    function maxWithdraw(
        address owner_
    ) external view virtual returns (uint256 maxassets_);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    function previewWithdraw(
        uint256 assets_
    ) external view virtual returns (uint256 positions_);

    /// @notice Total number of underlying positions_ that can be
    /// redeemed from the Vault by `owner_`, where `owner_` corresponds
    /// to the input parameter of a `redeem` call.
    function maxRedeem(
        address owner_
    ) external view virtual returns (uint256 maxpositions_);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their redeemption at the current block,
    /// given current on-chain conditions.
    function previewRedeem(
        uint256 positions_
    ) external view virtual returns (uint256 assets_);
}
