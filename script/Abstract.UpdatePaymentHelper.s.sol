// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "./Abstract.Deploy.Single.s.sol";
import "forge-std/console.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    address paymentHelper;
    address superRegistry;
    SuperRegistry superRegistryC;
}

abstract contract AbstractUpdatePaymentHelper is AbstractDeploySingle {
    function _updatePaymentHelper(
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory targetDeploymentChains,
        uint64[] memory finalDeployedChains,
        bytes32 salt
    )
        internal
        setEnvDeploy(cycle)
    {
        UpdateVars memory vars;

        vars.chainId = targetDeploymentChains[i];
        vm.startBroadcast();
        vars.superRegistry = _readContract(chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.paymentHelper = address(new PaymentHelper{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("PaymentHelper"))] = vars.paymentHelper;

        console.log("vars.paymentHelper", vars.paymentHelper);
        vars.superRegistryC = SuperRegistry(vars.superRegistry);

        vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_HELPER(), vars.paymentHelper, vars.chainId);

        /// @dev  configure payment helper
        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(
            vars.chainId, 1, abi.encode(PRICE_FEEDS[vars.chainId][vars.chainId])
        );
        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(
            vars.chainId, 7, abi.encode(nativePrices[trueIndex])
        );

        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 8, abi.encode(gasPrices[trueIndex]));

        /// @dev gas per byte
        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 9, abi.encode(750));

        /// @dev ackGasCost to mint superPositions
        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(
            vars.chainId, 10, abi.encode(vars.chainId == ARBI ? 500_000 : 150_000)
        );

        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 11, abi.encode(50_000));

        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 12, abi.encode(10_000));

        /// @dev Set all trusted remotes for each chain & configure amb chains ids
        for (uint256 j = 0; j < finalDeployedChains.length; j++) {
            if (j != i) {
                vars.dstChainId = finalDeployedChains[j];

                for (uint256 k = 0; k < chainIds.length; k++) {
                    if (vars.dstChainId == chainIds[k]) {
                        vars.dstTrueIndex = k;

                        break;
                    }
                }
                PaymentHelper(payable(vars.paymentHelper)).addRemoteChain(
                    vars.dstChainId,
                    IPaymentHelper.PaymentHelperConfig(
                        PRICE_FEEDS[vars.chainId][vars.dstChainId],
                        address(0),
                        vars.dstChainId == ARBI ? 2_000_000 : 1_000_000,
                        vars.dstChainId == ARBI ? 1_000_000 : 200_000,
                        vars.dstChainId == ARBI ? 1_000_000 : 200_000,
                        vars.dstChainId == ARBI ? 750_000 : 150_000,
                        nativePrices[vars.dstTrueIndex],
                        gasPrices[vars.dstTrueIndex],
                        750,
                        2_000_000,
                        10_000,
                        10_000
                    )
                );

                PaymentHelper(payable(vars.paymentHelper)).updateRegisterAERC20Params(abi.encode(4, abi.encode(0, "")));
                address dstPaymentHelper =
                    _readContract(chainNames[vars.dstTrueIndex], vars.dstChainId, "PaymentHelper");

                vars.superRegistryC.setAddress(vars.superRegistryC.PAYMENT_HELPER(), dstPaymentHelper, vars.dstChainId);
            }
        }
        vm.stopBroadcast();

        /// @dev Exports
        for (uint256 j = 0; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }
}
