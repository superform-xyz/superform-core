/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

/// @dev Storage variables needed by all vault shares handlers.
contract VaultSharesStore {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public vaultShares;
    uint256 public superPositionsSum;

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function setSuperPositions(uint256 _superPositionsSum) external {
        // Store the results
        superPositionsSum = _superPositionsSum;
    }

    function setVaultShares(uint256 _vaultShares) external {
        vaultShares = _vaultShares;
    }
}
