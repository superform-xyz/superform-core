// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {AbstractDeploySingle} from "../Abstract.Deploy.Single.s.sol";
import {LayerzeroImplementation} from "../../src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import {CelerImplementation} from "../../src/crosschain-data/adapters/celer/CelerImplementation.sol";

contract Fix is Script {
    //Chains[] SELECTED_CHAIN_NAMES = [Chains.Bsc, Chains.Arbitrum, Chains.Avalanche];

    /// @notice The main script entrypoint
    function deploy() external {
        vm.startBroadcast(vm.envUint("DEPLOYER_KEY"));

        LayerzeroImplementation(payable(0x7319f5443c84f1e130603094997E26D1C08250dc)).setLzEndpoint(
            0x3c2269811836af69497E5F486A85D7316753cf62
        );

        CelerImplementation(payable(0x651B484c7c42aCc5C70dE7749B5F0e0C68cA6A10)).setCelerBus(
            0x95714818fdd7a5454F73Da9c777B3ee6EbAEEa6B
        );

        vm.stopBroadcast();
    }
}
