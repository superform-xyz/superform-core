// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface IFactoryStateRegistry {
    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when factory contracts are updated
    event FactoryContractsUpdated(address factoryContract);

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows accounts with {DEFAULT_ADMIN_ROLE} to update the factory contracts
    /// @param factoryContract_ is the address of the factory on the chain
    function setFactoryContract(address factoryContract_) external;
}
