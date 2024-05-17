// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "test/utils/InvariantProtocolActions.sol";
import { VaultSharesStore } from "../stores/VaultSharesStore.sol";
import { TimestampStore } from "../../common/TimestampStore.sol";

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
        string[31] memory contractNames_,
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
        string[31] contractNames;
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
        _preDeploymentSetup(false, true);

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
