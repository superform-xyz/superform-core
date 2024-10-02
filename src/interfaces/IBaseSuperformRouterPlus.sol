// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

interface IBaseSuperformRouterPlus {
    //////////////////////////////////////////////////////////////
    //                       ERRORS                             //
    //////////////////////////////////////////////////////////////

    /// @notice thrown if the provided selector is invalid
    error INVALID_REBALANCE_SELECTOR();

    //////////////////////////////////////////////////////////////
    //                       STRUCTS                             //
    //////////////////////////////////////////////////////////////

    struct XChainRebalanceData {
        bytes4 rebalanceSelector;
        address interimAsset;
        uint256 slippage;
        uint256 expectedAmountInterimAsset;
        uint8[][] rebalanceToAmbIds;
        uint64[] rebalanceToDstChainIds;
        bytes rebalanceToSfData;
    }

    //////////////////////////////////////////////////////////////
    //                       ENUMS                             //
    //////////////////////////////////////////////////////////////

    enum Actions {
        DEPOSIT,
        REBALANCE_FROM_SINGLE,
        REBALANCE_FROM_MULTI,
        REBALANCE_X_CHAIN_FROM_SINGLE,
        REBALANCE_X_CHAIN_FROM_MULTI
    }
}
