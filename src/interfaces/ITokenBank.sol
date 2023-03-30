// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {LiqRequest} from "../types/LiquidityTypes.sol";
import {InitSingleVaultData, InitMultiVaultData} from "../types/DataTypes.sol";
import {IERC4626} from "../interfaces/IERC4626.sol";

interface ITokenBank {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev is emitted when layerzero safe gas params are updated.
    event SafeGasParamUpdated(bytes oldParam, bytes newParam);

    /// @dev is emitted when the super registry is updated.
    event SuperRegistryUpdated(address indexed superRegistry);
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev error thrown when the bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /// @dev error thrown when the safe gas param is incorrectly set
    error INVALID_GAS_OVERRIDE();

    /// @dev is emitted when an address is being set to 0
    error ZERO_ADDRESS();

    /// @dev is emitted when the chain id input is invalid.
    error INVALID_INPUT_CHAIN_ID();

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev handles the state when received from the source chain.
    /// @param multiVaultData_     represents the struct with the associated multi vault data
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function depositMultiSync(
        InitMultiVaultData memory multiVaultData_
    ) external payable;

    /// @dev handles the state when received from the source chain.
    /// @param singleVaultData_       represents the struct with the associated single vault data
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function depositSync(
        InitSingleVaultData memory singleVaultData_
    ) external payable;

    /// @dev handles the state when received from the source chain.
    /// @param multiVaultData_       represents the struct with the associated multi vault data
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function withdrawMultiSync(
        InitMultiVaultData memory multiVaultData_
    ) external payable;

    /// @dev handles the state when received from the source chain.
    /// @param singleVaultData_       represents the struct with the associated single vault data
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function withdrawSync(
        InitSingleVaultData memory singleVaultData_
    ) external payable;

    /// set super registry
    /// @dev allows an admin to set the super registry
    /// @param superRegistry_ is the address of the super registry
    function setSuperRegistry(address superRegistry_) external;
}
