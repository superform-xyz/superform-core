/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "../VaultShares.invariant.t.sol";
import "test/utils/InvariantProtocolActions.sol";
import { VaultSharesStore } from "../stores/VaultSharesStore.sol";
import { TimestampStore } from "../stores/TimestampStore.sol";
import { CommonBase } from "forge-std/Base.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

contract VaultSharesHandler is CommonBase, StdCheats, StdUtils, InvariantProtocolActions {
    VaultSharesStore public vaultSharesStore;
    TimestampStore public timestampStore;

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
        uint64[] memory chainIds,
        string[28] memory contractNames,
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
                chainIds,
                contractNames,
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
        uint256 underlying1,
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
        HandlerLocalVars memory v;
        v.AMBs = new uint8[](2);
        v.AMBs[0] = 1;
        v.AMBs[1] = 2;

        v.chain0Index = bound(chain0, 0, chainIds.length - 1);
        v.CHAIN_0 = chainIds[v.chain0Index];

        v.DST_CHAINS = new uint64[](1);
        v.DST_CHAINS[0] = v.CHAIN_0;

        v.targetVaultsPerDst = new uint256[](1);
        v.targetFormKindsPerDst = new uint32[](1);
        v.targetUnderlyingsPerDst = new uint256[](1);
        v.amountsPerDst = new uint256[](1);
        v.liqBridgesPerDst = new uint8[](1);

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

        for (uint256 act = 0; act < v.actionsMem.length; act++) {
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
        vaultSharesStore.setInvariantToAssert(v.superPositionsSum, v.vaultShares);
    }

    function singleXChainSingleVaultDeposit(
        uint256 timeJumpSeed,
        uint256 amount1,
        uint256 underlying1,
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

        for (uint256 act = 0; act < v.actionsMem.length; act++) {
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
        vaultSharesStore.setInvariantToAssert(v.superPositionsSum, v.vaultShares);
    }
    /*
    function singleDirectSingleVaultWithdraw() public {
        AMBs = [2, 3];
        CHAIN_0 = ETH;
        DST_CHAINS = [ETH];
        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][0] = [2];
        TARGET_VAULTS[ETH][0] = [0];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][0] = [0];
        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[ETH][1] = [2];
        TARGET_VAULTS[ETH][1] = [0];
        /// @dev id 0 is normal 4626
        TARGET_FORM_KINDS[ETH][1] = [0];
        LIQ_BRIDGES[ETH][0] = [1];
        LIQ_BRIDGES[ETH][1] = [1];
        FINAL_LIQ_DST_WITHDRAW[ETH] = [ETH];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 421, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        actions.push(
            TestAction({
                action: Actions.Withdraw,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 421, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        AMOUNTS[ETH][0] = [9_000_000];

        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            if (act == 1) {
                for (uint256 i = 0; i < DST_CHAINS.length; i++) {
                    uint256[] memory superPositions = _getSuperpositionsForDstChain(
                        actions[1].user,
                        TARGET_UNDERLYINGS[DST_CHAINS[i]][1],
                        TARGET_VAULTS[DST_CHAINS[i]][1],
                        TARGET_FORM_KINDS[DST_CHAINS[i]][1],
                        DST_CHAINS[i]
                    );

                    AMOUNTS[DST_CHAINS[i]][1] = [superPositions[0]];
                }
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
            console.log("depwith");
        }
        actions.pop();
        actions.pop();
    }

    function singleXChainRescueFailedDeposit() public {
        AMBs = [1, 3];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[POLY][0] = [2];
        TARGET_VAULTS[POLY][0] = [3];
        /// @dev vault index 3 is failedDepositMock, check VAULT_KINDS
        TARGET_FORM_KINDS[POLY][0] = [0];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[OP][1] = [2];
        TARGET_VAULTS[OP][1] = [3];
        /// @dev vault index 3 is failedDepositMock, check VAULT_KINDS
        TARGET_FORM_KINDS[OP][1] = [0];


        LIQ_BRIDGES[POLY][0] = [1];
        LIQ_BRIDGES[OP][1] = [1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.RevertProcessPayload,
                revertError: "",
                revertRole: "",
                slippage: 312, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        actions.push(
            TestAction({
                action: Actions.RescueFailedDeposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 312, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        AMOUNTS[POLY][0] = [7_000_000];
        /// @dev specifying the amount that was deposited earlier, as the amount to be rescued
        AMOUNTS[POLY][1] = [7_000_000];

        for (uint256 act; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;
            if (action.action == Actions.RescueFailedDeposit) _rescueFailedDeposits(action, act);
            else _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
    }
    */

    /*///////////////////////////////////////////////////////////////
                    INTERNAL HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    struct InitHandlerSetupVars {
        uint64[] chainIds;
        string[28] contractNames;
        address[][] coreContracts;
        address[][] underlyingAddresses;
        address[][][] vaultAddresses;
        address[][][] superformAddresses;
        uint256[] forksArray;
    }

    function _initHandler(InitHandlerSetupVars memory vars) internal {
        mapping(uint64 => uint256) storage forks = FORKS;

        for (uint256 i = 0; i < vars.chainIds.length; i++) {
            forks[vars.chainIds[i]] = vars.forksArray[i];
        }
        _preDeploymentSetup();

        for (uint256 i = 0; i < vars.chainIds.length; i++) {
            for (uint256 j = 0; j < vars.contractNames.length; j++) {
                contracts[vars.chainIds[i]][bytes32(bytes(vars.contractNames[j]))] = vars.coreContracts[i][j];
            }

            for (uint256 j = 0; j < UNDERLYING_TOKENS.length; j++) {
                contracts[vars.chainIds[i]][bytes32(bytes(UNDERLYING_TOKENS[j]))] = vars.underlyingAddresses[i][j];
            }

            for (uint256 j = 0; j < FORM_IMPLEMENTATION_IDS.length; j++) {
                uint256 lenBytecodes = vaultBytecodes2[FORM_IMPLEMENTATION_IDS[j]].vaultBytecode.length;
                uint256 counter;

                for (uint256 k = 0; k < UNDERLYING_TOKENS.length; k++) {
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
        //rpcURLs[FTM] = FANTOM_RPC_URL;

        mapping(uint64 => address) storage lzEndpointsStorage = LZ_ENDPOINTS;
        lzEndpointsStorage[ETH] = ETH_lzEndpoint;
        lzEndpointsStorage[BSC] = BSC_lzEndpoint;
        lzEndpointsStorage[AVAX] = AVAX_lzEndpoint;
        lzEndpointsStorage[POLY] = POLY_lzEndpoint;
        lzEndpointsStorage[ARBI] = ARBI_lzEndpoint;
        lzEndpointsStorage[OP] = OP_lzEndpoint;
        //lzEndpointsStorage[FTM] = FTM_lzEndpoint;

        mapping(uint64 => uint16) storage wormholeChainIdsStorage = WORMHOLE_CHAIN_IDS;

        for (uint256 i = 0; i < chainIds.length; i++) {
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

        /// BSC
        priceFeeds[BSC][BSC] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        priceFeeds[BSC][ETH] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][AVAX] = address(0);
        priceFeeds[BSC][POLY] = 0x7CA57b0cA6367191c94C8914d7Df09A57655905f;
        priceFeeds[BSC][OP] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        priceFeeds[BSC][ARBI] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;

        /// AVAX
        priceFeeds[AVAX][AVAX] = 0x0A77230d17318075983913bC2145DB16C7366156;
        priceFeeds[AVAX][BSC] = address(0);
        priceFeeds[AVAX][ETH] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][POLY] = address(0);
        priceFeeds[AVAX][OP] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        priceFeeds[AVAX][ARBI] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;

        /// POLYGON
        priceFeeds[POLY][POLY] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        priceFeeds[POLY][AVAX] = address(0);
        priceFeeds[POLY][BSC] = 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e;
        priceFeeds[POLY][ETH] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][OP] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
        priceFeeds[POLY][ARBI] = 0xF9680D99D6C9589e2a93a78A04A279e509205945;

        /// OPTIMISM
        priceFeeds[OP][OP] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][POLY] = address(0);
        priceFeeds[OP][AVAX] = address(0);
        priceFeeds[OP][BSC] = address(0);
        priceFeeds[OP][ETH] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        priceFeeds[OP][ARBI] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;

        /// ARBITRUM
        priceFeeds[ARBI][ARBI] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][OP] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        priceFeeds[ARBI][POLY] = 0x52099D4523531f678Dfc568a7B1e5038aadcE1d6;
        priceFeeds[ARBI][AVAX] = address(0);
        priceFeeds[ARBI][BSC] = address(0);
        priceFeeds[ARBI][ETH] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

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
        for (uint256 i = 0; i < VAULT_KINDS.length; i++) {
            for (uint256 j = 0; j < underlyingTokens.length; j++) {
                VAULT_NAMES[i].push(string.concat(underlyingTokens[j], VAULT_KINDS[i]));
            }
        }
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

        for (uint256 i = 0; i < superformIds.length; i++) {
            for (uint256 j = 0; j < users.length; j++) {
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
        returns (uint256 superPositionsSum)
    {
        /// @dev sum up superposition owned by all users on all chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            uint256[] memory superPositions = _getSuperpositionsForDstChainFromSrcChain(
                underlyingTokens_, vaultIds_, formKinds_, chainIds[i], dstChain
            );

            if (superPositions.length > 0) {
                superPositionsSum += superPositions[0];
            }
        }
    }

    function _getSingleVaultShares(
        uint64 dstChain,
        uint256[] memory underlyingTokens_
    )
        internal
        returns (uint256 vaultShares)
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

        vaultShares = IBaseForm(superform).getVaultShareBalance();
    }
}