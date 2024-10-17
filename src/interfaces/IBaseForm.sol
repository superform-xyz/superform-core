// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

/// @title IBaseForm
/// @dev Interface for BaseForm
/// @author ZeroPoint Labs
interface IBaseForm is IERC165 {
    
    //////////////////////////////////////////////////////////////
    //                          EVENTS                           //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a new vault is added by the admin.
    event VaultAdded(uint256 indexed id, IERC4626 indexed vault);

    /// @dev is emitted when a payload is processed by the destination contract.
    event Processed(
        uint64 indexed srcChainID,
        uint64 indexed dstChainId,
        uint256 indexed srcPayloadId,
        uint256 amount,
        address vault
    );

    /// @dev is emitted when an emergency withdrawal is processed
    event EmergencyWithdrawalProcessed(address indexed refundAddress, uint256 indexed amount);

    /// @dev is emitted when dust is forwarded to the paymaster
    event FormDustForwardedToPaymaster(address indexed token, uint256 indexed amount);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice get Superform name of the ERC20 vault representation
    /// @return The ERC20 name
    function superformYieldTokenName() external view returns (string memory);

    /// @notice get Superform symbol of the ERC20 vault representation
    /// @return The ERC20 symbol
    function superformYieldTokenSymbol() external view returns (string memory);

    /// @notice get the state registry id associated with the vault
    function getStateRegistryId() external view returns (uint8);

    /// @notice Returns the vault address
    /// @return The address of the vault
    function getVaultAddress() external view returns (address);

    /// @notice Returns the vault address
    /// @return The address of the vault asset
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

    /// @notice Returns the amount of underlying tokens each share of a vault is worth.
    /// @return The pricePerVaultShare value
    function getPricePerVaultShare() external view returns (uint256);

    /// @notice Returns the amount of vault shares owned by the form.
    /// @return The form's vault share balance
    function getVaultShareBalance() external view returns (uint256);

    /// @notice get the total amount of underlying managed in the ERC4626 vault
    function getTotalAssets() external view returns (uint256);

    /// @notice get the total amount of unredeemed vault shares in circulation
    function getTotalSupply() external view returns (uint256);

    /// @notice get the total amount of assets received if shares are actually redeemed
    /// @notice https://eips.ethereum.org/EIPS/eip-4626
    function getPreviewPricePerVaultShare() external view returns (uint256);

    /// @dev API may need to know state of funds deployed
    function previewDepositTo(uint256 assets_) external view returns (uint256);

    /// @notice positionBalance() -> .vaultIds&destAmounts
    /// @return how much of an asset + interest (accrued) is to withdraw from the Vault
    function previewWithdrawFrom(uint256 assets_) external view returns (uint256);

    /// @dev API may need to know state of funds deployed
    function previewRedeemFrom(uint256 shares_) external view returns (uint256);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @return shares  The amount of vault shares received
    function directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        external
        payable
        returns (uint256 shares);

    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @param srcChainId_ The chain id of the source chain
    /// @return shares  The amount of vault shares received
    /// @dev is shares is `0` then no further action/acknowledgement needs to be sent
    function xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        external
        returns (uint256 shares);

    /// @dev process withdrawal of asset from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @return assets  The amount of assets received
    function directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        external
        returns (uint256 assets);

    /// @dev process withdrawal of asset from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @param srcChainId_ The chain id of the source chain
    /// @return assets The amount of assets received
    function xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        external
        returns (uint256 assets);

    /// @dev process withdrawal of shares if form is paused
    /// @param receiverAddress_ The address to refund the shares to
    /// @param amount_ The amount of vault shares to refund
    function emergencyWithdraw(address receiverAddress_, uint256 amount_) external;

    /// @dev moves all dust in the contract to Paymaster contract
    /// @param token_ The address of the token to forward
    function forwardDustToPaymaster(address token_) external;
}