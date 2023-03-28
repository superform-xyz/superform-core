// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC165Upgradeable} from "@openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC165Upgradeable.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

import {InitSingleVaultData} from "../types/DataTypes.sol";
import {LiqRequest} from "../types/LiquidityTypes.sol";
import {IERC4626} from "./IERC4626.sol";

interface IBaseForm is IERC165Upgradeable {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a new vault is added by the admin.
    event VaultAdded(uint256 id, IERC4626 vault);

    /// @dev is emitted when a payload is processed by the destination contract.
    event Processed(
        uint16 srcChainID,
        uint16 dstChainId,
        uint80 txId,
        uint256 amount,
        address vault
    );

    /// @dev is emitted when a new token bridge is configured.
    event SetBridgeAddress(uint256 bridgeId, address bridgeAddress);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when the chain id brought in the cross chain message is invalid
    error INVALID_CHAIN_ID();

    /// @dev is emitted when the bridge address being set is 0
    error ZERO_BRIDGE_ADDRESS();

    /// @dev is emitted when the allowance in direct deposit is not correct
    error DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();

    /// @dev is emitted when the amount in direct deposit is not correct
    error DIRECT_DEPOSIT_INVALID_DATA();

    /// @dev is emitted when the collateral in direct deposit is not correct
    error DIRECT_DEPOSIT_INVALID_COLLATERAL();

    /// @dev is emitted when the collateral in direct withdraw is not correct
    error DIRECT_WITHDRAW_INVALID_COLLATERAL();

    /// @dev is emitted when the amount in direct withdraw is not correct
    error DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

    /// @dev is emitted when the amount in xchain withdraw is not correct
    error XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL WRITE FUNCTONS
    //////////////////////////////////////////////////////////////*/

    /// @dev allows admin to set the bridge address for an bridge id.
    /// @param bridgeId_         represents the bridge unqiue identifier.
    /// @param bridgeAddress_    represents the bridge address.
    function setBridgeAddress(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_
    ) external;

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmount  The amount of tokens deposited in same chain action
    /// @dev NOTE: Should this function return?
    function directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) external payable returns (uint256 dstAmount);

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmount  The amount of tokens deposited in same chain action
    /// @dev NOTE: Should this function return?
    function xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) external returns (uint256 dstAmount);

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process withdrawal of collateral from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmount  The amount of tokens withdrawn in same chain action
    function directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) external returns (uint256 dstAmount);

    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process withdrawal of collateral from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmounts  The amount of tokens withdrawn in same chain action
    function xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) external returns (uint256[] memory dstAmounts);

    function getUnderlyingOfVault() external view returns (ERC20);
}
