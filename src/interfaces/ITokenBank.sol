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
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev handles the state when received from the source chain.
    /// @param multiVaultData_     represents the struct with the associated multi vault data\
    /// @param ackExtraData_ represents the override data for acknowledgement
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function depositMultiSync(
        InitMultiVaultData memory multiVaultData_,
        bytes memory ackExtraData_
    ) external payable;

    /// @dev handles the state when received from the source chain.
    /// @param singleVaultData_ represents the struct with the associated single vault data
    /// @param ackExtraData_ represents the override data for acknowledgement
    /// note: called by external keepers when state is ready.
    /// note: state registry sorts by deposit/withdraw txType before calling this function.
    function depositSync(
        InitSingleVaultData memory singleVaultData_,
        bytes memory ackExtraData_
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
}
