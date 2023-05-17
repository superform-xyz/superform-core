// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC165Upgradeable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

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

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL WRITE FUNCTONS
    //////////////////////////////////////////////////////////////*/

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
    /// @return dstAmount The amount of tokens withdrawn 
    function xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) external returns (uint256 dstAmount);

    function getUnderlyingOfVault() external view returns (ERC20);
}
