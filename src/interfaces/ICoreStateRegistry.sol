// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
interface ICoreStateRegistry {
    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when core contracts are updated
    event CoreContractsUpdated(
        address routerContract,
        address tokenBankContract
    );

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows accounts with {DEFAULT_ADMIN_ROLE} to update the core contracts
    /// @param routerContract_ is the address of the router
    /// @param tokenBankContract_ is the address of the token bank
    function setCoreContracts(
        address routerContract_,
        address tokenBankContract_
    ) external;

}