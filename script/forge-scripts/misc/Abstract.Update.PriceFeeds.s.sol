// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
}

abstract contract AbstractUpdatePriceFeeds is EnvironmentUtils {
    function _updatePriceFeeds(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = s_superFormChainIds[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        address superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(superRegistry == expectedSr);

        address paymentHelper = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PaymentHelper");
        address expectedPaymentHelper =
            env == 0 ? 0x69c531E5bdf2458FFb4f5E0dB3DE41745151b2Bd : 0xb69929AC813125EdFaCFad366643c3787C0d1500;
        assert(paymentHelper == expectedPaymentHelper);
        uint256 countFeeds;
        for (uint256 j = 0; j < s_superFormChainIds.length; j++) {
            if (j != i) {
                vars.dstChainId = s_superFormChainIds[j];

                for (uint256 k = 0; k < chainIds.length; k++) {
                    if (vars.dstChainId == chainIds[k]) {
                        vars.dstTrueIndex = k;

                        break;
                    }
                }
                if (PRICE_FEEDS[vars.chainId][vars.dstChainId] != address(0)) {
                    IPaymentHelper(payable(paymentHelper)).updateRemoteChain(
                        vars.dstChainId, 1, abi.encode(PRICE_FEEDS[vars.chainId][vars.dstChainId])
                    );
                    countFeeds++;
                }
            }
        }
        console.log("Updated %d feeds", countFeeds);
        vm.stopBroadcast();
    }
}
