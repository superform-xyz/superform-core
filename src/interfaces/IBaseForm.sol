// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC165Upgradeable.sol";
import {InitSingleVaultData} from "../types/DataTypes.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

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
    event Processed(uint64 srcChainID, uint64 dstChainId, uint256 payloadId, uint256 amount, address vault);

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL WRITE FUNCTONS
    //////////////////////////////////////////////////////////////*/

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @return dstAmount  The amount of tokens deposited in same chain action
    function directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    ) external payable returns (uint256 dstAmount);

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process withdrawal of collateral from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @return dstAmount  The amount of tokens withdrawn in same chain action
    function directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    ) external returns (uint256 dstAmount);

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @param srcChainId_ The chain id of the source chain
    /// @return dstAmount  The amount of tokens deposited in same chain action
    function xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    ) external returns (uint256 dstAmount);

    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process withdrawal of collateral from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @param srcSender_ The address of the sender of the transaction
    /// @param srcChainId_ The chain id of the source chain
    /// @return dstAmount The amount of tokens withdrawn
    function xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    ) external returns (uint256 dstAmount);

    /// @notice Returns the underlying token of a vault.
    /// @return The underlying token
    function getUnderlyingOfVault() external view returns (address);

    /// @dev API may need to know state of funds deployed
    function previewDepositTo(uint256 assets_) external view returns (uint256);
}
