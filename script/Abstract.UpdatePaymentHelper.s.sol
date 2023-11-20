// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import "./Abstract.Deploy.Single.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    address paymentHelper;
}

abstract contract AbstractUpdatePaymentHelper is AbstractDeploySingle {
    function _updatePaymentHelper(
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory targetDeploymentChains,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        UpdateVars memory vars;

        vars.chainId = targetDeploymentChains[i];
        vm.startBroadcast(deployerPrivateKey);

        vars.paymentHelper = _readContract(chainNames[trueIndex], vars.chainId, "PaymentHelper");

        PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.chainId, 9, abi.encode(750));

        /// @dev Set all trusted remotes for each chain & configure amb chains ids
        for (uint256 j = 0; j < finalDeployedChains.length; j++) {
            if (j != i) {
                vars.dstChainId = finalDeployedChains[j];

                PaymentHelper(payable(vars.paymentHelper)).updateRemoteChain(vars.dstChainId, 9, abi.encode(750));
            }
        }
        vm.stopBroadcast();
    }
}
