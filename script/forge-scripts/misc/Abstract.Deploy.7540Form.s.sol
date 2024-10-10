/// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
    SuperformFactory superformFactory;
}

abstract contract AbstractDeploy7540Form is EnvironmentUtils {
    function _deploy7540Form(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = finalDeployedChains[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        address superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        address expectedSr;
        if (env == 0) {
            expectedSr = vars.chainId == 250
                ? 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4
                : 0x17A332dC7B40aE701485023b219E9D6f493a2514;
        } else {
            expectedSr = vars.chainId == 250
                ? 0x7B8d68f90dAaC67C577936d3Ce451801864EF189
                : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        }

        assert(superRegistry == expectedSr);

        address newStateRegistry = address(new AsyncStateRegistry{ salt: salt }(ISuperRegistry(superRegistry)));
        contracts[vars.chainId][bytes32(bytes("AsyncStateRegistry"))] = newStateRegistry;

        address newForm = address(new ERC7540Form{ salt: salt }(superRegistry, 4));
        contracts[vars.chainId][bytes32(bytes("ERC7540Form"))] = newForm;

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j = 0; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _configureSettingsStaging(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        _preDeploymentSetup();

        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = finalDeployedChains[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr = vars.chainId == 250
            ? 0x7B8d68f90dAaC67C577936d3Ce451801864EF189
            : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);

        address erc7540Form = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "ERC7540Form");
        address asyncStateRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "AsyncStateRegistry");

        vars.superformFactory =
            SuperformFactory(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperformFactory")));

        address expectedFactory = vars.chainId == 250
            ? 0x730A06A3195060D15d5fF04685514c9da16C89db
            : 0x9CA4480B65E5F3d57cFb942ac44A0A6Ab0B2C843;

        assert(address(vars.superformFactory) == expectedFactory);

        vars.superformFactory.addFormImplementation(erc7540Form, STAGING_FORM_IMPLEMENTATION_IDS[2], 4);

        address[] memory registryAddresses = new address[](1);
        registryAddresses[0] = asyncStateRegistry;

        uint8[] memory registryIds = new uint8[](1);
        registryIds[0] = 4;

        vars.superRegistryC.setStateRegistryAddress(registryIds, registryAddresses);

        vm.stopBroadcast();
    }

    function _configureSettingsProd(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        _preDeploymentSetup();

        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = finalDeployedChains[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr = vars.chainId == 250
            ? 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4
            : 0x17A332dC7B40aE701485023b219E9D6f493a2514;
        assert(address(vars.superRegistryC) == expectedSr);

        address erc7540Form = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "ERC7540Form");
        address asyncStateRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "AsyncStateRegistry");

        vars.superformFactory =
            SuperformFactory(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperformFactory")));

        address expectedFactory = vars.chainId == 250
            ? 0xbc85043544CC2b3Fd095d54b6431822979BBB62A
            : 0xD85ec15A9F814D6173bF1a89273bFB3964aAdaEC;

        assert(address(vars.superformFactory) == expectedFactory);

        address[] memory registryAddresses = new address[](1);
        registryAddresses[0] = asyncStateRegistry;

        uint8[] memory registryIds = new uint8[](1);
        registryIds[0] = 4;

        vars.superRegistryC.setStateRegistryAddress(registryIds, registryAddresses);
        vars.superformFactory.addFormImplementation(erc7540Form, FORM_IMPLEMENTATION_IDS[1], 4);

        vm.stopBroadcast();
    }
}
