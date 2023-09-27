/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "../utils/ProtocolActions.sol";

import { TimestampStore } from "./stores/TimestampStore.sol";

contract BaseInvariantTest is ProtocolActions {
    TimestampStore internal timestampStore;

    address[][] coreAddresses;
    address[][] underlyingAddresses;
    address[][][] vaultAddresses;
    address[][][] superformAddresses;
    address[] superRegistries;
    uint256[] forksArray;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/
    /// @dev uses the warped timestamp from the handler
    modifier useCurrentTimestamp() {
        console.log("sr ", getContract(ETH, "SuperRegistry"));

        console.log("timestampStore ", address(timestampStore));

        vm.warp(timestampStore.currentTimestamp());
        _;
    }

    function setUp() public virtual override {
        ProtocolActions.setUp();
        _grabStateForHandler();

        timestampStore = new TimestampStore();

        //vm.label({ account: address(timestampStore), newLabel: "TimestampStore" });

        console.log("timestampStore ", address(timestampStore));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        //excludeSender(address(timestampStore));
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _grabStateForHandler() internal {
        for (uint256 i = 0; i < chainIds.length; i++) {
            /// @dev grab core addresses
            address[] memory addresses = new address[](contractNames.length);
            for (uint256 j = 0; j < contractNames.length; j++) {
                addresses[j] = getContract(chainIds[i], contractNames[j]);
                if (keccak256(abi.encodePacked((contractNames[j]))) == keccak256(abi.encodePacked(("SuperRegistry")))) {
                    superRegistries.push(addresses[j]);
                }
            }
            coreAddresses.push(addresses);

            addresses = new address[](UNDERLYING_TOKENS.length);

            /// @dev grab underlying asset addresses

            for (uint256 j = 0; j < UNDERLYING_TOKENS.length; j++) {
                addresses[j] = getContract(chainIds[i], UNDERLYING_TOKENS[j]);
            }
            underlyingAddresses.push(addresses);

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

            vaultAddresses.push(vaultAddressesPerBeacon);
            superformAddresses.push(superformAddressesPerBeacon);

            forksArray.push(FORKS[chainIds[i]]);
        }
    }
}
