// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "test/utils/MainnetBaseSetup.sol";

contract SmokeTest is MainnetBaseSetup {
    function setUp() public override {
        folderToRead = "/script/launch_deployment/";

        uint64[] memory chains = new uint64[](7);
        chains[0] = ETH;
        chains[1] = BSC;
        chains[2] = AVAX;
        chains[3] = POLY;
        chains[4] = ARBI;
        chains[5] = OP;
        chains[6] = BASE;

        TARGET_DEPLOYMENT_CHAINS = chains;

        salt = "SunNeverSetsOnSuperformEmpire";

        super.setUp();
    }

    /*///////////////////////////////////////////////////////////////
                     TESTS
    //////////////////////////////////////////////////////////////*/

    function test_superRegistryAddresses() public {
        SuperRegistry sr;
        bytes32[] memory ids = new bytes32[](9);

        ids[0] = keccak256("PAYMENT_ADMIN");
        ids[1] = keccak256("CORE_REGISTRY_PROCESSOR");
        ids[2] = keccak256("BROADCAST_REGISTRY_PROCESSOR");
        ids[3] = keccak256("TIMELOCK_REGISTRY_PROCESSOR");
        ids[4] = keccak256("CORE_REGISTRY_UPDATER");
        ids[5] = keccak256("CORE_REGISTRY_RESCUER");
        ids[6] = keccak256("CORE_REGISTRY_DISPUTER");
        ids[7] = keccak256("DST_SWAPPER_PROCESSOR");
        ids[8] = keccak256("SUPERFORM_RECEIVER");

        address[] memory newAddresses = new address[](9);
        newAddresses[0] = 0xD911673eAF0D3e15fe662D58De15511c5509bAbB;
        newAddresses[1] = 0x23c658FE050B4eAeB9401768bF5911D11621629c;
        newAddresses[2] = EMERGENCY_ADMIN;
        newAddresses[3] = EMERGENCY_ADMIN;
        newAddresses[4] = 0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f;
        newAddresses[5] = 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5;
        newAddresses[6] = 0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a;
        newAddresses[7] = 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C;
        newAddresses[8] = 0x1a6805487322565202848f239C1B5bC32303C2FE;
        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            vm.selectFork(FORKS[TARGET_DEPLOYMENT_CHAINS[i]]);
            sr = SuperRegistry(getContract(TARGET_DEPLOYMENT_CHAINS[i], "SuperRegistry"));

            for (uint256 j = 0; j < ids.length; ++j) {
                assertEq(sr.getAddress(ids[j]), newAddresses[j]);
            }
        }
    }
}
