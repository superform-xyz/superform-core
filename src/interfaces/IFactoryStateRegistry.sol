// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title IFactoryStateRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Factory State Registry
interface IFactoryStateRegistry {
    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when factory contracts are updated
    event FactoryContractsUpdated(address factoryContract);
}
