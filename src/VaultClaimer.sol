// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IVaultClaimer } from "./interfaces/IVaultClaimer.sol";

/// @title VaultClaimer
/// @author Zeropoint Labs
contract VaultClaimer is IVaultClaimer {
    //////////////////////////////////////////////////////////////
    //                      EXTERNAL FUNCTIONS                  //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IVaultClaimer
    function claimProtocolOwnership(string calldata protocolId_) external override {
        emit Claimed(msg.sender, protocolId_);
    }
}
