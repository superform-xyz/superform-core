/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "../utils/ProtocolActions.sol";

import { TimestampStore } from "./stores/TimestampStore.sol";

contract BaseInvariantTest is ProtocolActions {
    TimestampStore internal timestampStore;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/
    /// @dev uses the warped timestamp from the handler
    modifier useCurrentTimestamp() {
        vm.selectFork(FORKS[0]);

        vm.warp(timestampStore.currentTimestamp());
        _;
    }

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(FORKS[0]);

        timestampStore = new TimestampStore();

        vm.label({ account: address(timestampStore), newLabel: "TimestampStore" });

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(timestampStore));
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _grabStateForHandler()
        internal
        view
        returns (
            address[][] memory coreAddresses,
            address[][] memory underlyingAddresses,
            address[][][] memory vaultAddresses,
            address[][][] memory superformAddresses,
            uint256[] memory forksArray
        )
    {
        coreAddresses = new address[][](chainIds.length);
        underlyingAddresses = new address[][](chainIds.length);
        vaultAddresses = new address[][][](chainIds.length);
        superformAddresses = new address[][][](chainIds.length);
        forksArray = new uint256[](chainIds.length);
        for (uint256 i = 0; i < chainIds.length; i++) {
            /// @dev grab core addresses
            address[] memory addresses = new address[](contractNames.length);
            for (uint256 j = 0; j < contractNames.length; j++) {
                addresses[j] = getContract(chainIds[i], contractNames[j]);
            }
            coreAddresses[i] = addresses;

            addresses = new address[](UNDERLYING_TOKENS.length);

            /// @dev grab underlying asset addresses

            for (uint256 j = 0; j < UNDERLYING_TOKENS.length; j++) {
                addresses[j] = getContract(chainIds[i], UNDERLYING_TOKENS[j]);
            }
            underlyingAddresses[i] = addresses;

            address[] memory superformAddressesT;
            address[][] memory vaultAddressesPerBeacon = new address[][](FORM_BEACON_IDS.length);
            address[][] memory superformAddressesPerBeacon = new address[][](FORM_BEACON_IDS.length);

            /// @dev grab vaults and superforms
            for (uint32 j = 0; j < FORM_BEACON_IDS.length; j++) {
                uint256 lenBytecodes = vaultBytecodes2[FORM_BEACON_IDS[j]].vaultBytecode.length;

                addresses = new address[](UNDERLYING_TOKENS.length * lenBytecodes);
                superformAddressesT = new address[](UNDERLYING_TOKENS.length * lenBytecodes);

                uint256 counter;

                for (uint256 k = 0; k < UNDERLYING_TOKENS.length; k++) {
                    for (uint256 l = 0; l < lenBytecodes; l++) {
                        addresses[counter] = getContract(chainIds[i], string.concat(VAULT_NAMES[l][k]));
                        superformAddressesT[counter] = getContract(
                            chainIds[i],
                            string.concat(
                                UNDERLYING_TOKENS[k], VAULT_KINDS[l], "Superform", Strings.toString(FORM_BEACON_IDS[j])
                            )
                        );
                        ++counter;
                    }
                }
                vaultAddressesPerBeacon[j] = addresses;
                superformAddressesPerBeacon[j] = superformAddressesT;
            }

            vaultAddresses[i] = vaultAddressesPerBeacon;
            superformAddresses[i] = superformAddressesPerBeacon;

            forksArray[i] = FORKS[chainIds[i]];
        }
    }
}
