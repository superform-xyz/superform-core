// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "test/utils/InvariantProtocolActions.sol";
import { VaultSharesStore } from "../stores/VaultSharesStore.sol";
import { TimestampStore } from "../stores/TimestampStore.sol";

contract VaultSharesHandler is InvariantProtocolActions {
    VaultSharesStore public vaultSharesStore;
    TimestampStore public timestampStore;

    uint256 public vaultShares;
    uint256 public superPositionsSum;

    /// @dev Simulates the passage of time.
    /// See https://github.com/foundry-rs/foundry/issues/4994.
    /// @dev taken from
    /// https://github.com/sablier-labs/v2-core/blob/main/test/invariant/handlers/BaseHandler.sol#L60C1-L69C1
    /// @param timeJumpSeed A fuzzed value needed for generating random time warps.
    modifier adjustTimestamp(uint256 timeJumpSeed) {
        uint256 timeJump = _bound(timeJumpSeed, 2 minutes, 30 minutes);
        vm.selectFork(FORKS[0]);
        timestampStore.increaseCurrentTimestamp(timeJump);
        vm.warp(TimestampStore(timestampStore).currentTimestamp());
        _;
    }

    constructor(
        uint64[] memory chainIds_,
        string[34] memory contractNames_,
        address[][] memory coreContracts,
        address[][] memory underlyingAddresses,
        address[][][] memory vaultAddresses,
        address[][][] memory superformAddresses,
        uint256[] memory forksArray,
        VaultSharesStore _vaultSharesStore,
        TimestampStore _timestampStore
    ) {
        vaultSharesStore = _vaultSharesStore;
        timestampStore = _timestampStore;

        _initHandler(
            InitHandlerSetupVars(
                chainIds_,
                contractNames_,
                coreContracts,
                underlyingAddresses,
                vaultAddresses,
                superformAddresses,
                forksArray
            )
        );

        console.log("Handler setup done!");
    }

    /*///////////////////////////////////////////////////////////////
                    HANDLER PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    struct HandlerLocalVars {
        uint256 chain0Index;
        uint256 dstChainIndex;
        uint256[] targetVaultsPerDst;
        uint32[] targetFormKindsPerDst;
        uint256[] targetUnderlyingsPerDst;
        uint256[] amountsPerDst;
        uint8[] liqBridgesPerDst;
        bool[] receive4626PerDst;
        uint256 superPositionsSum;
        uint256 vaultShares;
        TestAction[] actionsMem;
        TestAction singleAction;
        MultiVaultSFData[] multiSuperformsData;
        SingleVaultSFData[] singleSuperformsData;
        MessagingAssertVars[] aV;
        StagesLocalVars vars;
        uint8[] AMBs;
        uint64 CHAIN_0;
        uint64[] DST_CHAINS;
    }

    function singleDirectSingleVaultDeposit(
        uint256 timeJumpSeed,
        uint256 amount1,
        uint256, /*underlying1*/
        uint256 inputToken,
        uint256 slippage,
        uint64 chain0,
        uint256 actionType,
        uint256 user
    )
        public
        adjustTimestamp(timeJumpSeed)
    {
        console.log("## Handler call direct ##");
        HandlerLocalVars memory v;
        v.AMBs = new uint8[](2);
        v.AMBs[0] = 1;
        v.AMBs[1] = 2;

        v.chain0Index = bound(chain0, 0, chainIds.length - 1);
        v.dstChainIndex = v.chain0Index;
        v.CHAIN_0 = chainIds[v.chain0Index];

        v.DST_CHAINS = new uint64[](1);
        v.DST_CHAINS[0] = v.CHAIN_0;

        v.targetVaultsPerDst = new uint256[](1);
        v.targetFormKindsPerDst = new uint32[](1);
        v.targetUnderlyingsPerDst = new uint256[](1);
        v.amountsPerDst = new uint256[](1);
        v.liqBridgesPerDst = new uint8[](1);
        v.receive4626PerDst = new bool[](1);

        v.targetVaultsPerDst[0] = 0;
        v.targetFormKindsPerDst[0] = 0;
        /// @dev this bound is currently disabled because there is an issue with one of the vaults and we are not
        /// reminting
        //v.targetUnderlyingsPerDst[0] = bound(underlying1, 0, 2);
        v.targetUnderlyingsPerDst[0] = 1;
        inputToken = bound(inputToken, 0, 2);

        vm.selectFork(FORKS[v.CHAIN_0]);
        address input = getContract(v.CHAIN_0, UNDERLYING_TOKENS[inputToken]);
        console.log("inputToken", input);
        uint256 inputDecimals = MockERC20(input).decimals();
        console.log("A");
        if (inputToken == 0) {
            amount1 = bound(amount1, 1 * 10 ** inputDecimals, 1 * 10 ** (inputDecimals + 2));
            console.log("amount1 dai", amount1);
        } else if (inputToken == 1) {
            amount1 = bound(amount1, 12 * 10 ** inputDecimals, 12 * 10 ** (inputDecimals + 2));
            console.log("amount1 usdc", amount1);
        } else if (inputToken == 2) {
            amount1 = bound(amount1, 11 * 10 ** inputDecimals, 11 * 10 ** (inputDecimals + 2));
            console.log("amount1 weth", amount1);
        }

        v.amountsPerDst[0] = amount1;

        v.liqBridgesPerDst[0] = 1;

        v.receive4626PerDst[0] = false;

        v.actionsMem = new TestAction[](1);

        v.actionsMem[0] = TestAction({
            action: Actions(bound(actionType, 0, 1)), //Deposit or permit2 deposit
            multiVaults: false, //!!WARNING turn on or off multi vaults
            user: bound(user, 0, 2),
            testType: TestType.Pass,
            revertError: "",
            revertRole: "",
            slippage: int256(bound(slippage, 0, 1000)),
            dstSwap: false,
            externalToken: inputToken
        });

        for (uint256 act = 0; act < v.actionsMem.length; ++act) {
            v.singleAction = v.actionsMem[act];

            /// @dev this is per destination (hardcoding 1 here)
            v.vars.targetVaults = new uint256[][](1);
            v.vars.targetVaults[0] = v.targetVaultsPerDst;
            v.vars.targetFormKinds = new uint32[][](1);
            v.vars.targetFormKinds[0] = v.targetFormKindsPerDst;
            v.vars.targetUnderlyings = new uint256[][](1);
            v.vars.targetUnderlyings[0] = v.targetUnderlyingsPerDst;
            v.vars.targetAmounts = new uint256[][](1);
            v.vars.targetAmounts[0] = v.amountsPerDst;
            v.vars.targetLiqBridges = new uint8[][](1);
            v.vars.targetLiqBridges[0] = v.liqBridgesPerDst;
            v.vars.targetReceive4626 = new bool[][](1);
            v.vars.targetReceive4626[0] = v.receive4626PerDst;
            v.vars.AMBs = v.AMBs;
            v.vars.CHAIN_0 = v.CHAIN_0;
            v.vars.DST_CHAINS = v.DST_CHAINS;

            _runMainStages(v.singleAction, v.multiSuperformsData, v.singleSuperformsData, v.aV, v.vars, false);
        }

        v.superPositionsSum = _getSingleVaultSuperpositionsSum(
            chainIds[v.dstChainIndex], v.targetUnderlyingsPerDst, v.targetVaultsPerDst, v.targetFormKindsPerDst
        );
        v.vaultShares = _getSingleVaultShares(chainIds[v.dstChainIndex], v.targetUnderlyingsPerDst);
        vm.selectFork(FORKS[0]);

        vaultSharesStore.setSuperPositions(v.superPositionsSum);
        vaultSharesStore.setVaultShares(v.vaultShares);
    }

    function singleXChainSingleVaultDeposit(
        uint256 timeJumpSeed,
        uint256 amount1,
        uint256, /*underlying1*/
        uint256 inputToken,
        uint256 slippage,
        uint64 chain0,
        uint64 dstChain1,
        uint256 actionType,
        uint256 user
    )
        public
        adjustTimestamp(timeJumpSeed)
    {
        console.log("## Handler call xChain ##");

        HandlerLocalVars memory v;
        v.AMBs = new uint8[](2);
        v.AMBs[0] = 1;
        v.AMBs[1] = 2;

        v.chain0Index = bound(chain0, 0, chainIds.length - 1);
        v.CHAIN_0 = chainIds[v.chain0Index];
        v.dstChainIndex = bound(dstChain1, 0, chainIds.length - 1);
        if (v.dstChainIndex == v.chain0Index && v.dstChainIndex != chainIds.length - 1) {
            v.dstChainIndex++;
        } else if (v.dstChainIndex == v.chain0Index && v.dstChainIndex == chainIds.length - 1) {
            v.dstChainIndex--;
        }
        v.DST_CHAINS = new uint64[](1);
        v.DST_CHAINS[0] = chainIds[v.dstChainIndex];

        v.targetVaultsPerDst = new uint256[](1);
        v.targetFormKindsPerDst = new uint32[](1);
        v.targetUnderlyingsPerDst = new uint256[](1);
        v.amountsPerDst = new uint256[](1);
        v.liqBridgesPerDst = new uint8[](1);
        v.receive4626PerDst = new bool[](1);

        v.targetVaultsPerDst[0] = 0;
        v.targetFormKindsPerDst[0] = 0;
        /// @dev this bound is currently disabled because there is an issue with one of the vaults and we are not
        /// reminting
        //v.targetUnderlyingsPerDst[0] = bound(underlying1, 0, 2);
        v.targetUnderlyingsPerDst[0] = 1;
        inputToken = bound(inputToken, 0, 2);

        vm.selectFork(FORKS[v.CHAIN_0]);
        uint256 inputDecimals = MockERC20(getContract(v.CHAIN_0, UNDERLYING_TOKENS[inputToken])).decimals();
        if (inputToken == 0) {
            amount1 = bound(amount1, 1 * 10 ** inputDecimals, 1 * 10 ** (inputDecimals + 2));
            console.log("amount1 dai", amount1);
        } else if (inputToken == 1) {
            amount1 = bound(amount1, 12 * 10 ** inputDecimals, 12 * 10 ** (inputDecimals + 2));
            console.log("amount1 usdc", amount1);
        } else if (inputToken == 2) {
            amount1 = bound(amount1, 11 * 10 ** inputDecimals, 11 * 10 ** (inputDecimals + 2));
            console.log("amount1 weth", amount1);
        }

        v.amountsPerDst[0] = amount1;

        v.liqBridgesPerDst[0] = 1;

        v.receive4626PerDst[0] = false;

        v.actionsMem = new TestAction[](1);

        v.actionsMem[0] = TestAction({
            action: Actions(bound(actionType, 0, 1)), //Deposit or permit2 deposit
            multiVaults: false, //!!WARNING turn on or off multi vaults
            user: bound(user, 0, 2),
            testType: TestType.Pass,
            revertError: "",
            revertRole: "",
            slippage: int256(bound(slippage, 0, 1000)),
            dstSwap: false,
            externalToken: inputToken
        });

        for (uint256 act = 0; act < v.actionsMem.length; ++act) {
            v.singleAction = v.actionsMem[act];

            /// @dev this is per destination (hardcoding 1 here)
            v.vars.targetVaults = new uint256[][](1);
            v.vars.targetVaults[0] = v.targetVaultsPerDst;
            v.vars.targetFormKinds = new uint32[][](1);
            v.vars.targetFormKinds[0] = v.targetFormKindsPerDst;
            v.vars.targetUnderlyings = new uint256[][](1);
            v.vars.targetUnderlyings[0] = v.targetUnderlyingsPerDst;
            v.vars.targetAmounts = new uint256[][](1);
            v.vars.targetAmounts[0] = v.amountsPerDst;
            v.vars.targetLiqBridges = new uint8[][](1);
            v.vars.targetLiqBridges[0] = v.liqBridgesPerDst;
            v.vars.targetReceive4626 = new bool[][](1);
            v.vars.targetReceive4626[0] = v.receive4626PerDst;
            v.vars.AMBs = v.AMBs;
            v.vars.CHAIN_0 = v.CHAIN_0;
            v.vars.DST_CHAINS = v.DST_CHAINS;

            _runMainStages(v.singleAction, v.multiSuperformsData, v.singleSuperformsData, v.aV, v.vars, false);
        }

        v.superPositionsSum = _getSingleVaultSuperpositionsSum(
            chainIds[v.dstChainIndex], v.targetUnderlyingsPerDst, v.targetVaultsPerDst, v.targetFormKindsPerDst
        );
        v.vaultShares = _getSingleVaultShares(chainIds[v.dstChainIndex], v.targetUnderlyingsPerDst);
        vm.selectFork(FORKS[0]);

        vaultSharesStore.setSuperPositions(v.superPositionsSum);
        vaultSharesStore.setVaultShares(v.vaultShares);
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    struct InitHandlerSetupVars {
        uint64[] chainIds;
        string[34] contractNames;
        address[][] coreContracts;
        address[][] underlyingAddresses;
        address[][][] vaultAddresses;
        address[][][] superformAddresses;
        uint256[] forksArray;
    }

    function _initHandler(InitHandlerSetupVars memory vars) internal {
        mapping(uint64 => uint256) storage forks = FORKS;

        for (uint256 i = 0; i < vars.chainIds.length; ++i) {
            forks[vars.chainIds[i]] = vars.forksArray[i];
        }
        _preDeploymentSetup();

        for (uint256 i = 0; i < vars.chainIds.length; ++i) {
            for (uint256 j = 0; j < vars.contractNames.length; ++j) {
                contracts[vars.chainIds[i]][bytes32(bytes(vars.contractNames[j]))] = vars.coreContracts[i][j];
            }

            for (uint256 j = 0; j < UNDERLYING_TOKENS.length; ++j) {
                contracts[vars.chainIds[i]][bytes32(bytes(UNDERLYING_TOKENS[j]))] = vars.underlyingAddresses[i][j];
            }

            for (uint256 j = 0; j < FORM_IMPLEMENTATION_IDS.length; ++j) {
                uint256 lenBytecodes = vaultBytecodes2[FORM_IMPLEMENTATION_IDS[j]].vaultBytecode.length;
                uint256 counter;

                for (uint256 k = 0; k < UNDERLYING_TOKENS.length; ++k) {
                    for (uint256 l = 0; l < lenBytecodes; l++) {
                        contracts[vars.chainIds[i]][bytes32(bytes(VAULT_NAMES[l][k]))] =
                            vars.vaultAddresses[i][j][counter];
                        contracts[vars.chainIds[i]][bytes32(
                            bytes(
                                string.concat(
                                    UNDERLYING_TOKENS[k],
                                    VAULT_KINDS[l],
                                    "Superform",
                                    Strings.toString(FORM_IMPLEMENTATION_IDS[j])
                                )
                            )
                        )] = vars.superformAddresses[i][j][counter];
                        counter++;
                    }
                }
            }
        }
        _setTokenPriceFeeds();
    }

    /// @dev overrides basesetup _preDeploymentSetup so that forks are not created again
    function _preDeploymentSetup() internal override {
        mapping(uint64 => string) storage rpcURLs = RPC_URLS;
        rpcURLs[ETH] = ETHEREUM_RPC_URL;
        rpcURLs[BSC] = BSC_RPC_URL;
        rpcURLs[AVAX] = AVALANCHE_RPC_URL;
        rpcURLs[POLY] = POLYGON_RPC_URL;
        rpcURLs[ARBI] = ARBITRUM_RPC_URL;
        rpcURLs[OP] = OPTIMISM_RPC_URL;
        rpcURLs[BASE] = BASE_RPC_URL;
        rpcURLs[FANTOM] = FANTOM_RPC_URL;

        mapping(uint64 => mapping(uint256 => bytes)) storage gasUsed = GAS_USED;

        // swapGasUsed = 3
        gasUsed[ETH][3] = abi.encode(400_000);
        gasUsed[BSC][3] = abi.encode(650_000);
        gasUsed[AVAX][3] = abi.encode(850_000);
        gasUsed[POLY][3] = abi.encode(700_000);
        gasUsed[OP][3] = abi.encode(550_000);
        gasUsed[ARBI][3] = abi.encode(2_500_000);
        gasUsed[BASE][3] = abi.encode(600_000);
        gasUsed[FANTOM][3] = abi.encode(600_000);

        // updateDepositGasUsed == 4 (only used on deposits for now)
        gasUsed[ETH][4] = abi.encode(225_000);
        gasUsed[BSC][4] = abi.encode(225_000);
        gasUsed[AVAX][4] = abi.encode(200_000);
        gasUsed[POLY][4] = abi.encode(200_000);
        gasUsed[OP][4] = abi.encode(200_000);
        gasUsed[ARBI][4] = abi.encode(1_400_000);
        gasUsed[BASE][4] = abi.encode(200_000);
        gasUsed[FANTOM][4] = abi.encode(200_000);

        // withdrawGasUsed == 6
        gasUsed[ETH][6] = abi.encode(1_272_330);
        gasUsed[BSC][6] = abi.encode(837_167);
        gasUsed[AVAX][6] = abi.encode(1_494_028);
        gasUsed[POLY][6] = abi.encode(1_119_242);
        gasUsed[OP][6] = abi.encode(1_716_146);
        gasUsed[ARBI][6] = abi.encode(1_654_955);
        gasUsed[BASE][6] = abi.encode(1_178_778);
        gasUsed[FANTOM][6] = abi.encode(1_500_000);

        mapping(uint64 => address) storage lzEndpointsStorage = LZ_ENDPOINTS;
        lzEndpointsStorage[ETH] = ETH_lzEndpoint;
        lzEndpointsStorage[BSC] = BSC_lzEndpoint;
        lzEndpointsStorage[AVAX] = AVAX_lzEndpoint;
        lzEndpointsStorage[POLY] = POLY_lzEndpoint;
        lzEndpointsStorage[ARBI] = ARBI_lzEndpoint;
        lzEndpointsStorage[OP] = OP_lzEndpoint;
        lzEndpointsStorage[FANTOM] = FANTOM_lzEndpoint;

        mapping(uint64 => address) storage hyperlaneMailboxesStorage = HYPERLANE_MAILBOXES;
        hyperlaneMailboxesStorage[ETH] = hyperlaneMailboxes[0];
        hyperlaneMailboxesStorage[BSC] = hyperlaneMailboxes[1];
        hyperlaneMailboxesStorage[AVAX] = hyperlaneMailboxes[2];
        hyperlaneMailboxesStorage[POLY] = hyperlaneMailboxes[3];
        hyperlaneMailboxesStorage[ARBI] = hyperlaneMailboxes[4];
        hyperlaneMailboxesStorage[OP] = hyperlaneMailboxes[5];
        hyperlaneMailboxesStorage[BASE] = hyperlaneMailboxes[6];
        hyperlaneMailboxesStorage[FANTOM] = hyperlaneMailboxes[7];

        mapping(uint64 => uint16) storage wormholeChainIdsStorage = WORMHOLE_CHAIN_IDS;

        for (uint256 i = 0; i < chainIds.length; ++i) {
            wormholeChainIdsStorage[chainIds[i]] = wormhole_chainIds[i];
        }

        /// price feeds on all chains, for paymentHelper
        mapping(uint64 => mapping(uint64 => address)) storage priceFeeds = PRICE_FEEDS;

        /// ETH
        priceFeeds[ETH][ETH] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][BSC] = 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A;
        priceFeeds[ETH][AVAX] = 0xFF3EEb22B5E3dE6e705b44749C2559d704923FD7;
        priceFeeds[ETH][POLY] = 0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676;
        priceFeeds[ETH][OP] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][ARBI] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][BASE] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeeds[ETH][FANTOM] = address(0);

        /// BSC
        priceFeeds[BSC][BSC] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        priceFeeds[BSC][ETH] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][AVAX] = 0x5974855ce31EE8E1fff2e76591CbF83D7110F151;
        priceFeeds[BSC][POLY] = 0x7CA57b0cA6367191c94C8914d7Df09A57655905f;
        priceFeeds[BSC][OP] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][ARBI] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][BASE] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][FANTOM] = 0xe2A47e87C0f4134c8D06A41975F6860468b2F925;

        /// AVAX
        priceFeeds[AVAX][AVAX] = 0x0A77230d17318075983913bC2145DB16C7366156;
        priceFeeds[AVAX][BSC] = address(0);
        priceFeeds[AVAX][ETH] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][POLY] = 0x1db18D41E4AD2403d9f52b5624031a2D9932Fd73;
        priceFeeds[AVAX][OP] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][ARBI] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][BASE] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][FANTOM] = 0x2dD517B2f9ba49CedB0573131FD97a5AC19ff648;

        /// POLYGON
        priceFeeds[POLY][POLY] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        priceFeeds[POLY][AVAX] = 0xe01eA2fbd8D76ee323FbEd03eB9a8625EC981A10;
        priceFeeds[POLY][BSC] = 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e;
        priceFeeds[POLY][ETH] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][OP] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][ARBI] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][BASE] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][FANTOM] = 0x58326c0F831b2Dbf7234A4204F28Bba79AA06d5f;

        /// OPTIMISM
        priceFeeds[OP][OP] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][POLY] = 0x0ded608AFc23724f614B76955bbd9dFe7dDdc828;
        priceFeeds[OP][AVAX] = 0x5087Dc69Fd3907a016BD42B38022F7f024140727;
        priceFeeds[OP][BSC] = 0xD38579f7cBD14c22cF1997575eA8eF7bfe62ca2c;
        priceFeeds[OP][ETH] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][ARBI] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][BASE] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][FANTOM] = 0xc19d58652d6BfC6Db6FB3691eDA6Aa7f3379E4E9;

        /// ARBITRUM
        priceFeeds[ARBI][ARBI] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][OP] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][POLY] = 0x52099D4523531f678Dfc568a7B1e5038aadcE1d6;
        priceFeeds[ARBI][AVAX] = address(0);
        priceFeeds[ARBI][BSC] = address(0);
        priceFeeds[ARBI][ETH] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][BASE] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][FANTOM] = 0xFeaC1A3936514746e70170c0f539e70b23d36F19;

        /// BASE
        priceFeeds[BASE][BASE] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][OP] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][POLY] = address(0);
        priceFeeds[BASE][AVAX] = address(0);
        priceFeeds[BASE][BSC] = address(0);
        priceFeeds[BASE][ETH] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][ARBI] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        priceFeeds[BASE][FANTOM] = address(0);

        /// FANTOM
        priceFeeds[FANTOM][FANTOM] = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;
        priceFeeds[FANTOM][OP] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][POLY] = address(0);
        priceFeeds[FANTOM][AVAX] = address(0);
        priceFeeds[FANTOM][BSC] = 0x6dE70f4791C4151E00aD02e969bD900DC961f92a;
        priceFeeds[FANTOM][ETH] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][BASE] = 0x11DdD3d147E5b83D01cee7070027092397d63658;
        priceFeeds[FANTOM][ARBI] = 0x11DdD3d147E5b83D01cee7070027092397d63658;

        /// @dev setup bridges. 1 is lifi
        bridgeIds.push(1);

        /// @dev setup users
        userKeys.push(1);
        userKeys.push(2);
        userKeys.push(3);

        users.push(vm.addr(userKeys[0]));
        users.push(vm.addr(userKeys[1]));
        users.push(vm.addr(userKeys[2]));

        /// @dev setup vault bytecodes
        /// @dev NOTE: do not change order of these pushes
        /// @dev WARNING: Must fill VAULT_NAMES with exact same names as here!!!!!
        /// @dev form 1 (normal 4626)
        vaultBytecodes2[1].vaultBytecode.push(type(VaultMock).creationCode);
        vaultBytecodes2[1].vaultBytecode.push(type(VaultMockRevertDeposit).creationCode);
        vaultBytecodes2[1].vaultBytecode.push(type(VaultMockRevertWithdraw).creationCode);
        vaultBytecodes2[1].vaultKinds.push("VaultMock");
        vaultBytecodes2[1].vaultKinds.push("VaultMockRevertDeposit");
        vaultBytecodes2[1].vaultKinds.push("VaultMockRevertWithdraw");

        /// @dev form 2 (timelocked 4626)
        vaultBytecodes2[2].vaultBytecode.push(type(ERC4626TimelockMock).creationCode);
        vaultBytecodes2[2].vaultKinds.push("ERC4626TimelockMock");
        vaultBytecodes2[2].vaultBytecode.push(type(ERC4626TimelockMockRevertWithdrawal).creationCode);
        vaultBytecodes2[2].vaultKinds.push("ERC4626TimelockMockRevertWithdrawal");
        vaultBytecodes2[2].vaultBytecode.push(type(ERC4626TimelockMockRevertDeposit).creationCode);
        vaultBytecodes2[2].vaultKinds.push("ERC4626TimelockMockRevertDeposit");

        /// @dev form 3 (kycdao 4626)
        vaultBytecodes2[3].vaultBytecode.push(type(kycDAO4626).creationCode);
        vaultBytecodes2[3].vaultKinds.push("kycDAO4626");
        vaultBytecodes2[3].vaultBytecode.push(type(kycDAO4626RevertDeposit).creationCode);
        vaultBytecodes2[3].vaultKinds.push("kycDAO4626RevertDeposit");
        vaultBytecodes2[3].vaultBytecode.push(type(kycDAO4626RevertWithdraw).creationCode);
        vaultBytecodes2[3].vaultKinds.push("kycDAO4626RevertWithdraw");

        /// @dev populate VAULT_NAMES state arg with tokenNames + vaultKinds names
        string[] memory underlyingTokens = UNDERLYING_TOKENS;
        for (uint256 i = 0; i < VAULT_KINDS.length; ++i) {
            for (uint256 j = 0; j < underlyingTokens.length; ++j) {
                VAULT_NAMES[i].push(string.concat(underlyingTokens[j], VAULT_KINDS[i]));
            }
        }

        mapping(uint64 chainId => mapping(string underlying => address realAddress)) storage existingTokens =
            UNDERLYING_EXISTING_TOKENS;

        existingTokens[43_114]["DAI"] = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
        existingTokens[43_114]["USDC"] = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
        existingTokens[43_114]["WETH"] = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;

        existingTokens[42_161]["DAI"] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        existingTokens[42_161]["USDC"] = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
        existingTokens[42_161]["WETH"] = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

        existingTokens[10]["DAI"] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        existingTokens[10]["USDC"] = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
        existingTokens[10]["WETH"] = 0x4200000000000000000000000000000000000006;

        existingTokens[1]["DAI"] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        existingTokens[1]["USDC"] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        existingTokens[1]["WETH"] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        existingTokens[137]["DAI"] = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
        existingTokens[137]["USDC"] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        existingTokens[137]["WETH"] = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

        existingTokens[56]["DAI"] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        existingTokens[56]["USDC"] = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
        existingTokens[56]["WETH"] = address(0);

        existingTokens[8453]["DAI"] = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
        existingTokens[8453]["USDC"] = address(0);
        existingTokens[8453]["WETH"] = address(0);

        existingTokens[250]["DAI"] = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
        existingTokens[250]["USDC"] = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
        existingTokens[250]["WETH"] = address(0);

        mapping(
            uint64 chainId
                => mapping(
                    uint32 formImplementationId
                        => mapping(string underlying => mapping(uint256 vaultKindIndex => address realVault))
                )
            ) storage existingVaults = REAL_VAULT_ADDRESS;

        existingVaults[43_114][1]["DAI"][0] = 0x75A8cFB425f366e424259b114CaeE5f634C07124;
        existingVaults[43_114][1]["USDC"][0] = 0xB4001622c02F1354A3CfF995b7DaA15b1d47B0fe;
        existingVaults[43_114][1]["WETH"][0] = 0x1a225008efffB6e07D01671127c9E40f6f787c8C;

        existingVaults[42_161][1]["DAI"][0] = 0x105bdc0990947318FA1c873623730F332A6f6203;
        existingVaults[42_161][1]["USDC"][0] = address(0);
        existingVaults[42_161][1]["WETH"][0] = 0xe4c2A17f38FEA3Dcb3bb59CEB0aC0267416806e2;

        existingVaults[1][1]["DAI"][0] = 0x36F8d0D0573ae92326827C4a82Fe4CE4C244cAb6;
        existingVaults[1][1]["USDC"][0] = 0x6bAD6A9BcFdA3fd60Da6834aCe5F93B8cFed9598;
        existingVaults[1][1]["WETH"][0] = 0x490BBbc2485e99989Ba39b34802faFa58e26ABa4;

        existingVaults[10][1]["DAI"][0] = address(0);
        existingVaults[10][1]["USDC"][0] = 0x81C9A7B55A4df39A9B7B5F781ec0e53539694873;
        existingVaults[10][1]["WETH"][0] = 0xc4d4500326981eacD020e20A81b1c479c161c7EF;

        existingVaults[137][1]["DAI"][0] = 0x4A7CfE3ccE6E88479206Fefd7b4dcD738971e723;
        existingVaults[137][1]["USDC"][0] = 0x277ba089b4CF2AF32589D98aA839Bf8c35A30Da3;
        existingVaults[137][1]["WETH"][0] = 0x0D0188268D0693e2494989dc3DA5e64F0D6BA972;

        existingVaults[56][1]["DAI"][0] = 0x6A354D50fC2476061F378390078e30F9782C5266;
        existingVaults[56][1]["USDC"][0] = 0x32307B89a1c59Ea4EBaB1Fde6bD37b1139D06759;
        existingVaults[56][1]["WETH"][0] = address(0);

        existingVaults[8453][1]["DAI"][0] = 0x88510ced6F82eFd3ddc4599B72ad8ac2fF172043;
        existingVaults[8453][1]["USDC"][0] = address(0);
        existingVaults[8453][1]["WETH"][0] = address(0);

        existingVaults[250][1]["DAI"][0] = 0xd0b072360aDB8318467CD9686a71e361096273Ed;
        existingVaults[250][1]["USDC"][0] = 0x469DcDD58F6Eda8Cc0e909220Cea57F61088F79a;
        existingVaults[250][1]["WETH"][0] = address(0);
    }

    function _getSuperpositionsForDstChainFromSrcChain(
        uint256[] memory underlyingTokens_,
        uint256[] memory vaultIds_,
        uint32[] memory formKinds_,
        uint64 srcChain_,
        uint64 dstChain_
    )
        internal
        returns (uint256[] memory superPositionBalances)
    {
        uint256[] memory superformIds = _superformIds(underlyingTokens_, vaultIds_, formKinds_, dstChain_);
        address superRegistryAddress = getContract(srcChain_, "SuperRegistry");
        vm.selectFork(FORKS[srcChain_]);

        superPositionBalances = new uint256[](superformIds.length);
        address superPositionsAddress =
            ISuperRegistry(superRegistryAddress).getAddress(ISuperRegistry(superRegistryAddress).SUPER_POSITIONS());

        IERC1155A superPositions = IERC1155A(superPositionsAddress);

        for (uint256 i = 0; i < superformIds.length; ++i) {
            for (uint256 j = 0; j < users.length; ++j) {
                superPositionBalances[i] += superPositions.balanceOf(users[j], superformIds[i]);
            }
        }
    }

    function _getSingleVaultSuperpositionsSum(
        uint64 dstChain,
        uint256[] memory underlyingTokens_,
        uint256[] memory vaultIds_,
        uint32[] memory formKinds_
    )
        internal
        returns (uint256 superPositionsSum_)
    {
        /// @dev sum up superposition owned by all users on all chains
        for (uint256 i = 0; i < chainIds.length; ++i) {
            uint256[] memory superPositions = _getSuperpositionsForDstChainFromSrcChain(
                underlyingTokens_, vaultIds_, formKinds_, chainIds[i], dstChain
            );

            if (superPositions.length > 0) {
                superPositionsSum_ += superPositions[0];
            }
        }
    }

    function _getSingleVaultShares(
        uint64 dstChain,
        uint256[] memory underlyingTokens_
    )
        internal
        returns (uint256 vaultShares_)
    {
        /// @dev FIXME currently hardcoded to vault kind and form beacon id 0
        address superform = getContract(
            dstChain,
            string.concat(
                UNDERLYING_TOKENS[underlyingTokens_[0]],
                VAULT_KINDS[0],
                "Superform",
                Strings.toString(FORM_IMPLEMENTATION_IDS[0])
            )
        );

        vm.selectFork(FORKS[dstChain]);

        vaultShares_ = IBaseForm(superform).getVaultShareBalance();
    }
}
