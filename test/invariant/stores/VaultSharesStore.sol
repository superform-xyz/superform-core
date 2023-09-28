/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

/// @dev Storage variables needed by all vault shares handlers.
contract VaultSharesStore {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public superPositionsSum;
    uint256 public vaultShares;

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function setInvariantToAssert(uint256 _superPositionsSum, uint256 _vaultShares) external {
        // Store the results
        superPositionsSum = _superPositionsSum;
        vaultShares = _vaultShares;
    }
}
