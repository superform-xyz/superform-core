// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IStandardizedYield } from "src/vendor/pendle/IStandardizedYield.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";

/// @title IERC5115Form
/// @dev Interface for ERC5115 Form
/// @author Zeropoint Labs
interface IERC5115Form {
    //////////////////////////////////////////////////////////////
    //                           ERRORS                         //
    //////////////////////////////////////////////////////////////

    /// @dev Thrown when a function not part of the EIP-5115 is called
    error FUNCTION_NOT_IMPLEMENTED();

    /// @dev Thrown when the tokenIn is not encoded in the extraFormData
    error ERC5115FORM_TOKEN_IN_NOT_ENCODED();

    /// @dev Thrown when the tokenOut is not set as the interimToken
    error ERC5115FORM_TOKEN_OUT_NOT_SET();

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

    struct DirectDepositLocalVars {
        IERC20 vaultTokenIn;
        IERC20 sendingToken;
        IBridgeValidator bridgeValidator;
        uint64 chainId;
        uint256 shares;
        uint256 balanceBefore;
        uint256 assetDifference;
        uint256 inputAmount;
    }

    //////////////////////////////////////////////////////////////
    //                       EVENTS                             //
    //////////////////////////////////////////////////////////////

    /// @dev Emitted when retain 4626 flag is used
    event Retain4626();

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @notice Claims reward tokens for the caller
    function claimRewardTokens() external;

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice Returns the accrued rewards for a given user
    /// @param user The address of the user
    /// @return rewards An array of accrued reward amounts
    function getAccruedRewards(address user) external view returns (uint256[] memory rewards);

    /// @notice Returns the stored reward indexes
    /// @return indexes An array of stored reward indexes
    function getRewardIndexesStored() external view returns (uint256[] memory indexes);

    /// @notice Returns the addresses of reward tokens
    /// @return rewardTokens An array of reward token addresses
    function getRewardTokens() external view returns (address[] memory rewardTokens);

    /// @notice Returns the address of the yield token
    /// @return yieldToken The address of the yield token
    function getYieldToken() external view returns (address yieldToken);

    /// @notice Returns the addresses of tokens that can be deposited
    /// @return tokensIn An array of token addresses accepted for deposit
    function getTokensIn() external view returns (address[] memory tokensIn);

    /// @notice Returns the addresses of tokens that can be withdrawn
    /// @return tokensOut An array of token addresses available for withdrawal
    function getTokensOut() external view returns (address[] memory tokensOut);

    /// @notice Checks if a given token is valid for deposit
    /// @param token The address of the token to check
    /// @return True if the token is valid for deposit, false otherwise
    function isValidTokenIn(address token) external view returns (bool);

    /// @notice Checks if a given token is valid for withdrawal
    /// @param token The address of the token to check
    /// @return True if the token is valid for withdrawal, false otherwise
    function isValidTokenOut(address token) external view returns (bool);

    /// @notice Returns information about the asset
    /// @return assetType The type of the asset
    /// @return assetAddress The address of the asset
    /// @return assetDecimals The number of decimals for the asset
    function getAssetInfo()
        external
        view
        returns (IStandardizedYield.AssetType assetType, address assetAddress, uint8 assetDecimals);
}
