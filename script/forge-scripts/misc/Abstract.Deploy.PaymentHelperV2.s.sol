// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
}

abstract contract AbstractDeployPaymentHelperV2 is EnvironmentUtils {
    function _deployPaymentHelper(
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
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(superRegistry == expectedSr);

        address paymentHelper = address(new PaymentHelper{ salt: salt }(superRegistry));
        contracts[vars.chainId][bytes32(bytes("PaymentHelper"))] = paymentHelper;

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j = 0; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _configurePaymentHelper(
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
        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);

        address paymentHelper = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PaymentHelper");

        vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_HELPER(), paymentHelper, vars.chainId);

        uint256[] memory configTypes = new uint256[](7);
        configTypes[0] = 1;
        configTypes[1] = 7;
        configTypes[2] = 8;
        configTypes[3] = 9;
        configTypes[4] = 10;
        configTypes[5] = 11;
        configTypes[6] = 12;

        bytes[] memory configs = new bytes[](7);
        configs[0] = abi.encode(PRICE_FEEDS[vars.chainId][vars.chainId]);
        configs[1] = abi.encode(nativePrices[trueIndex]);
        configs[2] = abi.encode(gasPrices[trueIndex]);
        configs[3] = abi.encode(750);
        configs[4] = abi.encode(vars.chainId == ARBI ? 500_000 : 150_000);
        configs[5] = abi.encode(50_000);
        configs[6] = abi.encode(10_000);

        PaymentHelper(payable(paymentHelper)).batchUpdateRemoteChain(vars.chainId, configTypes, configs);

        PaymentHelper(payable(paymentHelper)).updateRegisterAERC20Params(abi.encode(4, abi.encode(0, "")));

        uint64[] memory remoteChainIds = new uint64[](finalDeployedChains.length - 1);
        for (uint256 j = 0; j < finalDeployedChains.length; j++) {
            if (j != i) {
                remoteChainIds[j] = finalDeployedChains[j];
            }
        }

        IPaymentHelper.PaymentHelperConfig[] memory addRemoteConfigs =
            new IPaymentHelper.PaymentHelperConfig[](remoteChainIds.length);

        for (uint256 j = 0; j < remoteChainIds.length; j++) {
            for (uint256 k = 0; k < chainIds.length; k++) {
                if (remoteChainIds[j] == chainIds[k]) {
                    vars.dstTrueIndex = k;

                    break;
                }
            }

            assert(PRICE_FEEDS[vars.chainId][remoteChainIds[j]] != address(0));
            assert(abi.decode(GAS_USED[remoteChainIds[j]][3], (uint256)) > 0);
            assert(abi.decode(GAS_USED[remoteChainIds[j]][4], (uint256)) > 0);
            assert(abi.decode(GAS_USED[remoteChainIds[j]][6], (uint256)) > 0);
            assert(abi.decode(GAS_USED[remoteChainIds[j]][13], (uint256)) > 0);

            addRemoteConfigs[j] = IPaymentHelper.PaymentHelperConfig(
                PRICE_FEEDS[vars.chainId][remoteChainIds[j]],
                address(0),
                abi.decode(GAS_USED[remoteChainIds[j]][3], (uint256)),
                abi.decode(GAS_USED[remoteChainIds[j]][4], (uint256)),
                remoteChainIds[j] == ARBI ? 1_000_000 : 200_000,
                abi.decode(GAS_USED[remoteChainIds[j]][6], (uint256)),
                nativePrices[vars.dstTrueIndex],
                gasPrices[vars.dstTrueIndex],
                750,
                2_000_000,
                /// @dev ackGasCost to move a msg from dst to source
                10_000,
                10_000,
                abi.decode(GAS_USED[remoteChainIds[j]][13], (uint256))
            );
        }

        PaymentHelper(payable(paymentHelper)).addRemoteChains(remoteChainIds, addRemoteConfigs);

        vm.stopBroadcast();
    }

    function _configureSuperRegistryStaging(
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

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);

        address paymentHelper = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PaymentHelper");

        vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_HELPER(), paymentHelper, vars.chainId);

        /// @dev configure remotes based on source chain
        for (uint256 j = 0; j < finalDeployedChains.length; j++) {
            if (j != i) {
                vars.dstChainId = finalDeployedChains[j];

                for (uint256 k = 0; k < chainIds.length; k++) {
                    if (vars.dstChainId == chainIds[k]) {
                        vars.dstTrueIndex = k;

                        break;
                    }
                }

                vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_HELPER(), paymentHelper, vars.dstChainId);
            }
        }
        vm.stopBroadcast();
    }

    function _configureSuperRegistryProd(
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

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);

        address paymentHelper = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PaymentHelper");

        bytes memory txn = abi.encodeWithSelector(
            vars.superRegistryC.setAddress.selector, vars.superRegistryC.PAYMENT_HELPER(), paymentHelper, vars.chainId
        );
        addToBatch(address(vars.superRegistryC), 0, txn);

        /// @dev configure remotes based on source chain
        for (uint256 j = 0; j < finalDeployedChains.length; j++) {
            if (j != i) {
                vars.dstChainId = finalDeployedChains[j];

                for (uint256 k = 0; k < chainIds.length; k++) {
                    if (vars.dstChainId == chainIds[k]) {
                        vars.dstTrueIndex = k;

                        break;
                    }
                }

                txn = abi.encodeWithSelector(
                    vars.superRegistryC.setAddress.selector,
                    vars.superRegistryC.PAYMENT_HELPER(),
                    paymentHelper,
                    vars.dstChainId
                );

                addToBatch(address(vars.superRegistryC), 0, txn);
            }
        }
        /// Send to Safe to sign
        executeBatch(vars.chainId, env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i], false);
    }
}
