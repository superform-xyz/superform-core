// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IERC5115To4626Wrapper } from "../interfaces/IERC5115To4626Wrapper.sol";
import { IStandardizedYield } from "src/vendor/pendle/IStandardizedYield.sol";
import { IERC20Metadata, IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Error } from "src/libraries/Error.sol";

/// @title ERC5115To4626Wrapper
/// @dev Wrapper contract for ERC5115 to ERC4626 conversion
/// @author Zeropoint Labs
contract ERC5115To4626Wrapper is IERC5115To4626Wrapper {
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////
    //                      ERRORS                              //
    //////////////////////////////////////////////////////////////

    /// @dev Emitted when the receiver is this contract
    error INVALID_RECEIVER();

    /// @dev Emitted when the tokenIn is not valid
    error INVALID_TOKEN_IN();

    /// @dev Emitted when the tokenOut is not valid
    error INVALID_TOKEN_OUT();

    //////////////////////////////////////////////////////////////
    //                      STORAGE                             //
    //////////////////////////////////////////////////////////////

    /// @dev The address of the underlying ERC5115 vault
    address public immutable vault;

    /// @dev The address of the token used for deposits
    address public immutable asset;

    /// @dev The address of the token used for withdrawals
    address public immutable mainTokenOut;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    /// @notice Initializes the wrapper contract
    /// @param vault_ The address of the ERC5115 vault
    /// @param tokenIn_ The address of the token used for deposits
    /// @param tokenOut_ The address of the token used for withdrawals
    constructor(address vault_, address tokenIn_, address tokenOut_) {
        if (vault_ == address(0) || tokenIn_ == address(0) || tokenOut_ == address(0)) revert Error.ZERO_ADDRESS();

        _validateTokenIn(tokenIn_, vault_);
        _validateTokenOut(tokenOut_, vault_);

        vault = vault_;
        asset = tokenIn_;
        mainTokenOut = tokenOut_;
    }

    //////////////////////////////////////////////////////////////
    //                    EXTERNAL FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IERC5115To4626Wrapper
    function deposit(
        address receiver,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut
    )
        external
        returns (uint256 amountSharesOut)
    {
        address tokenIn = asset;

        if (receiver == address(this)) revert INVALID_RECEIVER();

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountTokenToDeposit);
        IERC20(tokenIn).safeIncreaseAllowance(vault, amountTokenToDeposit);

        amountSharesOut = IStandardizedYield(vault).deposit(receiver, tokenIn, amountTokenToDeposit, minSharesOut);

        if (IERC20(tokenIn).allowance(address(this), vault) > 0) IERC20(tokenIn).forceApprove(vault, 0);
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        uint256 minTokenOut
    )
        external
        returns (uint256 amountTokenOut)
    {
        if (receiver == address(this)) revert INVALID_RECEIVER();

        IERC20(vault).safeTransferFrom(msg.sender, address(this), amountSharesToRedeem);

        return IStandardizedYield(vault).redeem(receiver, amountSharesToRedeem, mainTokenOut, minTokenOut, false);
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function claimRewards(address user) external returns (uint256[] memory rewardAmounts) {
        return IStandardizedYield(vault).claimRewards(user);
    }

    //////////////////////////////////////////////////////////////
    //                 EXTERNAL VIEW FUNCTIONS                  //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IERC5115To4626Wrapper
    function getUnderlying5115Vault() external view returns (address) {
        return vault;
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function getMainTokenIn() external view returns (address) {
        return asset;
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function getMainTokenOut() external view returns (address) {
        return mainTokenOut;
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function exchangeRate() external view returns (uint256 res) {
        return IStandardizedYield(vault).exchangeRate();
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function accruedRewards(address user) external view returns (uint256[] memory rewardAmounts) {
        return IStandardizedYield(vault).accruedRewards(user);
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function rewardIndexesCurrent() external returns (uint256[] memory indexes) {
        return IStandardizedYield(vault).rewardIndexesCurrent();
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function rewardIndexesStored() external view returns (uint256[] memory indexes) {
        return IStandardizedYield(vault).rewardIndexesStored();
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function getRewardTokens() external view returns (address[] memory) {
        return IStandardizedYield(vault).getRewardTokens();
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function yieldToken() external view returns (address) {
        return IStandardizedYield(vault).yieldToken();
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function getTokensIn() external view returns (address[] memory res) {
        return IStandardizedYield(vault).getTokensIn();
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function getTokensOut() external view returns (address[] memory res) {
        return IStandardizedYield(vault).getTokensOut();
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function isValidTokenIn(address token) public view returns (bool) {
        return IStandardizedYield(vault).isValidTokenIn(token);
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function isValidTokenOut(address token) public view returns (bool) {
        return IStandardizedYield(vault).isValidTokenOut(token);
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    )
        external
        view
        returns (uint256 amountSharesOut)
    {
        return IStandardizedYield(vault).previewDeposit(tokenIn, amountTokenToDeposit);
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    )
        external
        view
        returns (uint256 amountTokenOut)
    {
        return IStandardizedYield(vault).previewRedeem(tokenOut, amountSharesToRedeem);
    }

    /// @inheritdoc IERC5115To4626Wrapper
    function assetInfo()
        external
        view
        returns (IStandardizedYield.AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return IStandardizedYield(vault).assetInfo();
    }

    /// @notice Returns the allowance of the wrapped 5115 vault token
    /// @param owner The address of the account owning vault tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return The number of remaining tokens allowed to spent
    function allowance(address owner, address spender) external view returns (uint256) {
        return IStandardizedYield(vault).allowance(owner, spender);
    }

    /// @notice Returns the balance of the wrapped 5115 vault token
    /// @param account The address of the account to query
    /// @return The amount of tokens owned by the account
    function balanceOf(address account) external view returns (uint256) {
        return IStandardizedYield(vault).balanceOf(account);
    }

    /// @notice Returns the decimals of the wrapped 5115 vault token
    /// @return The number of decimals
    function decimals() external view returns (uint8) {
        return IStandardizedYield(vault).decimals();
    }

    /// @notice Returns the name of the wrapped 5115 vault token
    /// @return The name of the token
    function name() external view returns (string memory) {
        return IStandardizedYield(vault).name();
    }

    /// @notice Returns the symbol of the wrapped 5115 vault token
    /// @return The symbol of the token
    function symbol() external view returns (string memory) {
        return IStandardizedYield(vault).symbol();
    }

    /// @notice Returns the total token supply of the wrapped 5115 vault token
    /// @return The total supply of tokens
    function totalSupply() external view returns (uint256) {
        return IStandardizedYield(vault).totalSupply();
    }

    /// @notice Not implemented, reverts when called
    function approve(address, uint256) external pure returns (bool) {
        revert Error.NOT_IMPLEMENTED();
    }

    /// @notice Not implemented, reverts when called
    function transfer(address, uint256) external pure returns (bool) {
        revert Error.NOT_IMPLEMENTED();
    }

    /// @notice Not implemented, reverts when called
    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert Error.NOT_IMPLEMENTED();
    }

    //////////////////////////////////////////////////////////////
    //                    INTERNAL FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev Validates if the given token is a valid input token for the vault
    /// @param token_ The address of the token to validate
    /// @param vault_ The address of the vault
    function _validateTokenIn(address token_, address vault_) internal view {
        try IStandardizedYield(vault_).isValidTokenIn(token_) returns (bool isValid) {
            if (!isValid) {
                revert INVALID_TOKEN_IN();
            }
        } catch {
            address[] memory tokensIn = IStandardizedYield(vault_).getTokensIn();
            bool found;
            for (uint256 i = 0; i < tokensIn.length; i++) {
                if (tokensIn[i] == token_) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                revert INVALID_TOKEN_IN();
            }
        }
    }

    /// @dev Validates if the given token is a valid output token for the vault
    /// @param token_ The address of the token to validate
    /// @param vault_ The address of the vault
    function _validateTokenOut(address token_, address vault_) internal view {
        try IStandardizedYield(vault_).isValidTokenOut(token_) returns (bool isValid) {
            if (!isValid) {
                revert INVALID_TOKEN_OUT();
            }
        } catch {
            address[] memory tokensOut = IStandardizedYield(vault_).getTokensOut();
            bool found;
            for (uint256 i = 0; i < tokensOut.length; i++) {
                if (tokensOut[i] == token_) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                revert INVALID_TOKEN_OUT();
            }
        }
    }
}
