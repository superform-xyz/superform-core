// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IStandardizedYield } from "src/vendor/pendle/IStandardizedYield.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title IERC5115To4626Wrapper
/// @dev Interface for ERC5115To4626Wrapper
/// @author Zeropoint Labs
interface IERC5115To4626Wrapper is IERC20Metadata {
    //////////////////////////////////////////////////////////////
    //                   EXTERNAL FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice Deposits tokens and mints shares
    /// @param receiver The address that will receive the minted shares
    /// @param amountTokenToDeposit The amount of tokens to deposit
    /// @param minSharesOut The minimum amount of shares that must be minted for the transaction to be successful
    /// @return amountSharesOut The actual amount of shares minted
    function deposit(
        address receiver,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut
    )
        external
        returns (uint256 amountSharesOut);

    /// @notice Redeems shares for tokens
    /// @param receiver The address that will receive the redeemed tokens
    /// @param amountSharesToRedeem The amount of shares to redeem
    /// @param minTokenOut The minimum amount of tokens that must be received for the transaction to be successful
    /// @return amountTokenOut The actual amount of tokens received
    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        uint256 minTokenOut
    )
        external
        returns (uint256 amountTokenOut);

    /// @notice Claims rewards for a user
    /// @param user The user receiving their rewards
    /// @return rewardAmounts An array of reward amounts in the same order as `getRewardTokens`
    function claimRewards(address user) external returns (uint256[] memory rewardAmounts);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice Returns the 5115 vault wrapped
    /// @return The address of the underlying 5115 vault
    function getUnderlying5115Vault() external view returns (address);

    /// @notice Returns the token used for deposits to the underlying 5115
    /// @return The address of the main token in
    function getMainTokenIn() external view returns (address);

    /// @notice Returns the token used for redemptions
    /// @return The address of the main token out
    function getMainTokenOut() external view returns (address);

    /// @notice Returns the current exchange rate
    /// @dev exchangeRate * syBalance / 1e18 must return the asset balance of the account
    /// @return res The current exchange rate
    function exchangeRate() external view returns (uint256 res);

    /// @notice Returns the amount of unclaimed rewards for a user
    /// @param user The user to check for
    /// @return rewardAmounts An array of reward amounts in the same order as `getRewardTokens`
    function accruedRewards(address user) external view returns (uint256[] memory rewardAmounts);

    /// @notice Returns the current reward indexes
    /// @return indexes The current reward indexes
    function rewardIndexesCurrent() external returns (uint256[] memory indexes);

    /// @notice Returns the stored reward indexes
    /// @return indexes The stored reward indexes
    function rewardIndexesStored() external view returns (uint256[] memory indexes);

    /// @notice Returns the list of reward token addresses
    /// @return The addresses of reward tokens
    function getRewardTokens() external view returns (address[] memory);

    /// @notice Returns the address of the underlying yield token
    /// @return The address of the yield token
    function yieldToken() external view returns (address);

    /// @notice Returns all tokens that can mint this SY
    /// @return res The addresses of tokens that can be used for minting
    function getTokensIn() external view returns (address[] memory res);

    /// @notice Returns all tokens that can be redeemed by this SY
    /// @return res The addresses of tokens that can be redeemed
    function getTokensOut() external view returns (address[] memory res);

    /// @notice Checks if a token is valid for deposit
    /// @param token The address of the token to check
    /// @return True if the token is valid for deposit, false otherwise
    function isValidTokenIn(address token) external view returns (bool);

    /// @notice Checks if a token is valid for redemption
    /// @param token The address of the token to check
    /// @return True if the token is valid for redemption, false otherwise
    function isValidTokenOut(address token) external view returns (bool);

    /// @notice Previews the amount of shares received for a deposit
    /// @param tokenIn The address of the token to deposit
    /// @param amountTokenToDeposit The amount of tokens to deposit
    /// @return amountSharesOut The amount of shares that would be minted
    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    )
        external
        view
        returns (uint256 amountSharesOut);

    /// @notice Previews the amount of tokens received for a redemption
    /// @param tokenOut The address of the token to receive
    /// @param amountSharesToRedeem The amount of shares to redeem
    /// @return amountTokenOut The amount of tokens that would be received
    function previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    )
        external
        view
        returns (uint256 amountTokenOut);

    /// @notice Returns information about the asset
    /// @return assetType The type of the asset
    /// @return assetAddress The address of the asset
    /// @return assetDecimals The decimals of the asset
    function assetInfo()
        external
        view
        returns (IStandardizedYield.AssetType assetType, address assetAddress, uint8 assetDecimals);
}
