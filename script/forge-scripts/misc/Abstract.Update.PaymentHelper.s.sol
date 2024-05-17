// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
}

abstract contract AbstractUpdatePaymentHelper is EnvironmentUtils {
    function _setGasUsed() internal {
        mapping(uint64 => mapping(uint256 => bytes)) storage gasUsed = GAS_USED;

        // swapGasUsed = 3
        gasUsed[ETH][3] = abi.encode(400_000);
        gasUsed[BSC][3] = abi.encode(650_000);
        gasUsed[AVAX][3] = abi.encode(850_000);
        gasUsed[POLY][3] = abi.encode(700_000);
        gasUsed[OP][3] = abi.encode(550_000);
        gasUsed[ARBI][3] = abi.encode(2_500_000);
        gasUsed[BASE][3] = abi.encode(600_000);

        // updateDepositGasUsed == 4 (only used on deposits for now)
        gasUsed[ETH][4] = abi.encode(225_000);
        gasUsed[BSC][4] = abi.encode(225_000);
        gasUsed[AVAX][4] = abi.encode(200_000);
        gasUsed[POLY][4] = abi.encode(200_000);
        gasUsed[OP][4] = abi.encode(200_000);
        gasUsed[ARBI][4] = abi.encode(1_400_000);
        gasUsed[BASE][4] = abi.encode(200_000);

        // withdrawGasUsed == 6 (incl. cost to update)
        gasUsed[ETH][6] = abi.encode(600_000);
        gasUsed[BSC][6] = abi.encode(1_500_000);
        gasUsed[AVAX][6] = abi.encode(1_000_000);
        gasUsed[POLY][6] = abi.encode(1_000_000);
        gasUsed[OP][6] = abi.encode(1_000_000);
        gasUsed[ARBI][6] = abi.encode(2_500_000);
        gasUsed[BASE][6] = abi.encode(1_500_000);
    }

    function _updatePaymentHelper(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        _setGasUsed();
        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = s_superFormChainIds[i];

        /// price feeds that will be updated
        mapping(uint64 => mapping(uint64 => address)) storage priceFeeds = PRICE_FEEDS;

        /// BSC
        priceFeeds[BSC][AVAX] = 0x5974855ce31EE8E1fff2e76591CbF83D7110F151;

        /// AVAX
        /// @dev warning - this is missing still
        //priceFeeds[AVAX][BSC] = address(0);
        priceFeeds[AVAX][POLY] = 0x1db18D41E4AD2403d9f52b5624031a2D9932Fd73;

        /// POLYGON
        priceFeeds[POLY][AVAX] = 0xe01eA2fbd8D76ee323FbEd03eB9a8625EC981A10;

        /// OPTIMISM
        priceFeeds[OP][POLY] = 0x0ded608AFc23724f614B76955bbd9dFe7dDdc828;
        priceFeeds[OP][AVAX] = 0x5087Dc69Fd3907a016BD42B38022F7f024140727;
        priceFeeds[OP][BSC] = 0xD38579f7cBD14c22cF1997575eA8eF7bfe62ca2c;

        /// ARBITRUM
        priceFeeds[ARBI][AVAX] = 0x8bf61728eeDCE2F32c456454d87B5d6eD6150208;
        priceFeeds[ARBI][BSC] = 0x6970460aabF80C5BE983C6b74e5D06dEDCA95D4A;

        /// BASE
        /// @dev warning - all these three missing still
        //priceFeeds[BASE][POLY] = address(0);
        //priceFeeds[BASE][AVAX] = address(0);
        //priceFeeds[BASE][BSC] = address(0);

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        address superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(superRegistry == expectedSr);

        address paymentHelper = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PaymentHelper");
        address expectedPaymentHelper =
            env == 0 ? 0xaDcA2c82D7A05b9E84F75AeAc466bE74B34066d9 : 0xfbdCa870c9878d71e6a3A0a312220De153404eA2;
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
                if (GAS_USED[vars.dstChainId][3].length != 0) {
                    console.log("Updating gas used for destination ", vars.dstChainId);

                    console.log("New gas used", abi.decode(GAS_USED[vars.dstChainId][3], (uint256)));
                    IPaymentHelper(payable(paymentHelper)).updateRemoteChain(
                        vars.dstChainId, 3, GAS_USED[vars.dstChainId][3]
                    );
                }
                if (GAS_USED[vars.dstChainId][4].length != 0) {
                    console.log("Updating gas used for destination ", vars.dstChainId);

                    console.log("New gas used", abi.decode(GAS_USED[vars.dstChainId][4], (uint256)));

                    IPaymentHelper(payable(paymentHelper)).updateRemoteChain(
                        vars.dstChainId, 4, GAS_USED[vars.dstChainId][4]
                    );
                }
                if (GAS_USED[vars.dstChainId][6].length != 0) {
                    console.log("Updating gas used for destination ", vars.dstChainId);

                    console.log("New gas used", abi.decode(GAS_USED[vars.dstChainId][6], (uint256)));
                    IPaymentHelper(payable(paymentHelper)).updateRemoteChain(
                        vars.dstChainId, 6, GAS_USED[vars.dstChainId][6]
                    );
                }
            }
        }
        console.log("Updated %d feeds", countFeeds);
        vm.stopBroadcast();
    }
}
