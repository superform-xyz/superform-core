// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface IFactoryStateRegistry {
    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when factory contracts are updated
    event FactoryContractsUpdated(address factoryContract);
}
