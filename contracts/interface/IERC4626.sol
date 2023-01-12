// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.14;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

/// @title ERC4626 interface
/// See: https://eips.ethereum.org/EIPS/eip-4626
abstract contract IERC4626 is ERC20 {
    /*////////////////////////////////////////////////////////
                      Events
    ////////////////////////////////////////////////////////*/

    /// @notice `sender` has exchanged `assets` for `positions`,
    /// and transferred those `positions` to `receiver`.
    event Deposit(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 positions
    );

    /// @notice `sender` has exchanged `positions` for `assets`,
    /// and transferred those `assets` to `receiver`.
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 positions
    );

    /*////////////////////////////////////////////////////////
                      Vault properties
    ////////////////////////////////////////////////////////*/

    /// @notice The address of the underlying ERC20 token used for
    /// the Vault for accounting, depositing, and withdrawing.
    function asset() external view virtual returns (address asset);

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    function totalAssets() external view virtual returns (uint256 totalAssets);

    /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal Logic
    ////////////////////////////////////////////////////////*/

    /// @notice Mints `positions` Vault positions to `receiver` by
    /// depositing exactly `assets` of underlying tokens.
    function deposit(uint256 assets, address receiver)
        external
        virtual
        returns (uint256 positions);

    /// @notice Mints exactly `positions` Vault positions to `receiver`
    /// by depositing `assets` of underlying tokens.
    function mint(uint256 positions, address receiver)
        external
        virtual
        returns (uint256 assets);

    /// @notice Redeems `positions` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual returns (uint256 positions);

    /// @notice Redeems `positions` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function redeem(
        uint256 positions,
        address receiver,
        address owner
    ) external virtual returns (uint256 assets);

    /*////////////////////////////////////////////////////////
                      Vault Accounting Logic
    ////////////////////////////////////////////////////////*/

    /// @notice The amount of positions that the vault would
    /// exchange for the amount of assets provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToShares(uint256 assets)
        external
        view
        virtual
        returns (uint256 positions);

    /// @notice The amount of assets that the vault would
    /// exchange for the amount of positions provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToAssets(uint256 positions)
        external
        view
        virtual
        returns (uint256 assets);

    /// @notice Total number of underlying assets that can
    /// be deposited by `owner` into the Vault, where `owner`
    /// corresponds to the input parameter `receiver` of a
    /// `deposit` call.
    function maxDeposit(address owner)
        external
        view
        virtual
        returns (uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their deposit at the current block, given
    /// current on-chain conditions.
    function previewDeposit(uint256 assets)
        external
        view
        virtual
        returns (uint256 positions);

    /// @notice Total number of underlying positions that can be minted
    /// for `owner`, where `owner` corresponds to the input
    /// parameter `receiver` of a `mint` call.
    function maxMint(address owner)
        external
        view
        virtual
        returns (uint256 maxPositions);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their mint at the current block, given
    /// current on-chain conditions.
    function previewMint(uint256 positions)
        external
        view
        virtual
        returns (uint256 assets);

    /// @notice Total number of underlying assets that can be
    /// withdrawn from the Vault by `owner`, where `owner`
    /// corresponds to the input parameter of a `withdraw` call.
    function maxWithdraw(address owner)
        external
        view
        virtual
        returns (uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    function previewWithdraw(uint256 assets)
        external
        view
        virtual
        returns (uint256 positions);

    /// @notice Total number of underlying positions that can be
    /// redeemed from the Vault by `owner`, where `owner` corresponds
    /// to the input parameter of a `redeem` call.
    function maxRedeem(address owner)
        external
        view
        virtual
        returns (uint256 maxPositions);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their redeemption at the current block,
    /// given current on-chain conditions.
    function previewRedeem(uint256 positions)
        external
        view
        virtual
        returns (uint256 assets);
}
