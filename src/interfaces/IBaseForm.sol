// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { IERC165Upgradeable } from
    "openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC165Upgradeable.sol";
import { InitSingleVaultData } from "../types/DataTypes.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

/// @title IBaseForm
/// @author ZeroPoint Labs
/// @notice Interface for Base Form
interface IBaseForm is IERC165Upgradeable {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a new vault is added by the admin.
    event VaultAdded(uint256 id, IERC4626 vault);

    /// @dev is emitted when a payload is processed by the destination contract.
    event Processed(uint64 srcChainID, uint64 dstChainId, uint256 srcPayloadId, uint256 amount, address vault);

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL WRITE FUNCTONS
    //////////////////////////////////////////////////////////////*/

    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @return dstAmount  The amount of tokens deposited in same chain action
    function directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        external
        payable
        returns (uint256 dstAmount);

    /// @dev process withdrawal of collateral from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @return dstAmount  The amount of tokens withdrawn in same chain action
    function directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        external
        returns (uint256 dstAmount);

    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @param srcChainId_ The chain id of the source chain
    /// @return dstAmount  The amount of tokens deposited in same chain action
    function xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        external
        returns (uint256 dstAmount);

    /// @dev process withdrawal of collateral from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @param srcChainId_ The chain id of the source chain
    /// @return dstAmount The amount of tokens withdrawn
    function xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        external
        returns (uint256 dstAmount);

    /// @notice get Superform name of the ERC20 vault representation
    /// @return The ERC20 name
    function superformYieldTokenName() external view returns (string memory);

    /// @notice get Superform symbol of the ERC20 vault representation
    /// @return The ERC20 symbol
    function superformYieldTokenSymbol() external view returns (string memory);

    /// @notice Returns the underlying token of a vault.
    /// @return The asset being deposited into the vault used for accounting, depositing, and withdrawing
    function getVaultAsset() external view returns (address);

    /// @notice Returns the name of the vault.
    /// @return The name of the vault
    function getVaultName() external view returns (string memory);

    /// @notice Returns the symbol of a vault.
    /// @return The symbol associated with a vault
    function getVaultSymbol() external view returns (string memory);

    /// @notice Returns the number of decimals in a vault for accounting purposes
    /// @return The number of decimals in the vault balance
    function getVaultDecimals() external view returns (uint256);

    /// @dev returns the vault address
    function getVaultAddress() external view returns (address);

    /// @notice Returns the amount of underlying tokens each share of a vault is worth.
    /// @return The pricePerVaultShare value
    function getPricePerVaultShare() external view returns (uint256);

    /// @notice Returns the amount of vault shares owned by the form.
    /// @return The form's vault share balance
    function getVaultShareBalance() external view returns (uint256);

    /// @notice get the total amount of underlying managed in the ERC4626 vault
    function getTotalAssets() external view returns (uint256);

    /// @notice get the total amount of assets received if shares are actually redeemed
    /// @notice https://eips.ethereum.org/EIPS/eip-4626
    function getPreviewPricePerVaultShare() external view returns (uint256);

    /// @notice get the state registry id
    function getStateRegistryId() external view returns (uint256);

    /// @dev API may need to know state of funds deployed
    function previewDepositTo(uint256 assets_) external view returns (uint256);

    /// @dev API may need to know state of user redemption
    function previewRedeemFrom(uint256 shares_) external view returns (uint256);

    /// @notice positionBalance() -> .vaultIds&destAmounts
    /// @return how much of an asset + interest (accrued) is to withdraw from the Vault
    function previewWithdrawFrom(uint256 assets_) external view returns (uint256);
}
