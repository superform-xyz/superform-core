/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @dev lib imports
import "./BaseSetup.sol";

import "forge-std/console.sol";

abstract contract ProtocolActions is BaseSetup {
    uint8 public primaryAMB;

    uint8[] public secondaryAMBs;

    uint16 public CHAIN_0;

    uint16[] public DST_CHAINS;

    mapping(uint16 => mapping(uint256 => uint256[]))
        public TARGET_UNDERLYING_VAULTS;

    mapping(uint16 => mapping(uint256 => uint256[])) public AMOUNTS;

    mapping(uint16 => mapping(uint256 => uint256[])) public MAX_SLIPPAGE;

    TestAction[] actions;

    function setUp() public virtual override {
        super.setUp();
    }

    /*///////////////////////////////////////////////////////////////
                            MAIN INTERNAL
    //////////////////////////////////////////////////////////////*/
    function _run_actions() internal returns (bool) {
        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];

            if (
                action.revertError != bytes4(0) &&
                action.testType == TestType.Pass
            ) revert MISMATCH_TEST_TYPE();

            if (
                (action.testType != TestType.RevertUpdateStateRBAC &&
                    action.revertRole != bytes32(0)) ||
                (action.testType == TestType.RevertUpdateStateRBAC &&
                    action.revertRole == bytes32(0))
            ) revert MISMATCH_RBAC_TEST();

            NewActionLocalVars memory vars;

            /// @dev STEP 1: Build Request Data

            vars.lzEndpoint_0 = LZ_ENDPOINTS[CHAIN_0];
            vars.fromSrc = payable(getContract(CHAIN_0, "SuperRouter"));

            vars.nDestinations = DST_CHAINS.length;

            vars.lzEndpoints_1 = new address[](vars.nDestinations);
            vars.toDst = new address[](vars.nDestinations);
            vars.multiSuperFormsData = new MultiVaultsSFData[](
                vars.nDestinations
            );
            vars.singleSuperFormsData = new SingleVaultSFData[](
                vars.nDestinations
            );

            /// @dev FIXME this probably needs to be tailored for NATIVE DEPOSITS
            /// @dev with multi state requests, the entire msg.value is used. Msg.value in that case should cover
            /// @dev the sum of native assets needed in each state request
            action.msgValue =
                (vars.nDestinations + 1) *
                _getPriceMultiplier(CHAIN_0) *
                1e18;

            for (uint256 i = 0; i < vars.nDestinations; i++) {
                vars.lzEndpoints_1[i] = LZ_ENDPOINTS[DST_CHAINS[i]];
                /// @dev action is sameChain, if there is a liquidity swap it should go to the same form
                /// @dev if action is cross chain withdraw, user can select to receive a different kind of underlying from source
                if (
                    CHAIN_0 == DST_CHAINS[i] ||
                    (action.action == Actions.Withdraw &&
                        CHAIN_0 != DST_CHAINS[i])
                ) {
                    /// @dev FIXME: this is only using hardcoded formid 1 (ERC4626Form) for now!!!
                    /// !!WARNING
                    vars.toDst[i] = payable(
                        getContract(DST_CHAINS[i], "ERC4626Form")
                    );
                } else {
                    vars.toDst[i] = payable(
                        getContract(DST_CHAINS[i], "TokenBank")
                    );
                }

                (
                    vars.targetSuperFormIds,
                    vars.underlyingSrcToken,
                    vars.vaultMock
                ) = _targetVaults(CHAIN_0, DST_CHAINS[i], act);

                vars.amounts = AMOUNTS[DST_CHAINS[i]][act];

                vars.maxSlippage = MAX_SLIPPAGE[DST_CHAINS[i]][act];

                if (action.multiVaults) {
                    vars.multiSuperFormsData[i] = _buildMultiVaultCallData(
                        MultiVaultCallDataArgs(
                            action.user,
                            vars.fromSrc,
                            vars.toDst[i],
                            vars.underlyingSrcToken,
                            vars.targetSuperFormIds,
                            vars.amounts,
                            vars.maxSlippage,
                            vars.vaultMock,
                            CHAIN_0,
                            DST_CHAINS[i],
                            action.multiTx,
                            action.actionKind,
                            action.action
                        )
                    );
                } else {
                    if (
                        !((vars.underlyingSrcToken.length ==
                            vars.targetSuperFormIds.length) &&
                            (vars.underlyingSrcToken.length ==
                                vars.amounts.length) &&
                            (vars.underlyingSrcToken.length ==
                                vars.maxSlippage.length) &&
                            (vars.underlyingSrcToken.length == 1))
                    ) revert INVALID_AMOUNTS_LENGTH();

                    SingleVaultCallDataArgs
                        memory singleVaultCallDataArgs = SingleVaultCallDataArgs(
                            action.user,
                            vars.fromSrc,
                            vars.toDst[i],
                            vars.underlyingSrcToken[0],
                            vars.targetSuperFormIds[0],
                            vars.amounts[0],
                            vars.maxSlippage[0],
                            vars.vaultMock[0],
                            CHAIN_0,
                            DST_CHAINS[i],
                            action.multiTx,
                            action.actionKind
                        );

                    if (action.action == Actions.Deposit) {
                        vars.singleSuperFormsData[
                            i
                        ] = _buildSingleVaultDepositCallData(
                            singleVaultCallDataArgs
                        );
                    } else {
                        vars.singleSuperFormsData[
                            i
                        ] = _buildSingleVaultWithdrawCallData(
                            singleVaultCallDataArgs
                        );
                    }
                }
            }

            CoreStateRegistry stateRegistry;

            SuperRouter superRouter = SuperRouter(vars.fromSrc);

            AssertVars memory aV;

            vm.selectFork(FORKS[CHAIN_0]);

            aV.initialFork = vm.activeFork();

            aV.txIdBefore = superRouter.totalTransactions();

            /// @dev STEP 2: Call Apropriate Action

            if (action.testType != TestType.RevertMainAction) {
                vm.prank(action.user);
                /// @dev see pigeon for this implementation
                vm.recordLogs();
                if (action.multiVaults) {
                    if (vars.nDestinations == 1) {
                        vars
                            .singleDstMultiVaultStateReq = SingleDstMultiVaultsStateReq(
                            primaryAMB,
                            secondaryAMBs,
                            DST_CHAINS[0],
                            vars.multiSuperFormsData[0],
                            action.adapterParam,
                            action.msgValue
                        );

                        if (action.action == Actions.Deposit)
                            superRouter.singleDstMultiVaultDeposit{
                                value: action.msgValue
                            }(vars.singleDstMultiVaultStateReq);
                        else if (action.action == Actions.Withdraw)
                            superRouter.singleDstMultiVaultWithdraw{
                                value: action.msgValue
                            }(vars.singleDstMultiVaultStateReq);
                    } else if (vars.nDestinations > 1) {
                        vars
                            .multiDstMultiVaultStateReq = MultiDstMultiVaultsStateReq(
                            primaryAMB,
                            secondaryAMBs,
                            DST_CHAINS,
                            vars.multiSuperFormsData,
                            action.adapterParam,
                            action.msgValue
                        );

                        if (action.action == Actions.Deposit)
                            superRouter.multiDstMultiVaultDeposit{
                                value: action.msgValue
                            }(vars.multiDstMultiVaultStateReq);
                        else if (action.action == Actions.Withdraw)
                            superRouter.multiDstMultiVaultWithdraw{
                                value: action.msgValue
                            }(vars.multiDstMultiVaultStateReq);
                    }
                } else {
                    if (vars.nDestinations == 1) {
                        if (CHAIN_0 != DST_CHAINS[0]) {
                            vars
                                .singleXChainSingleVaultStateReq = SingleXChainSingleVaultStateReq(
                                primaryAMB,
                                secondaryAMBs,
                                DST_CHAINS[0],
                                vars.singleSuperFormsData[0],
                                action.adapterParam,
                                action.msgValue
                            );

                            if (action.action == Actions.Deposit)
                                superRouter.singleXChainSingleVaultDeposit{
                                    value: action.msgValue
                                }(vars.singleXChainSingleVaultStateReq);
                            else if (action.action == Actions.Withdraw)
                                superRouter.singleXChainSingleVaultWithdraw{
                                    value: action.msgValue
                                }(vars.singleXChainSingleVaultStateReq);
                        } else {
                            vars
                                .singleDirectSingleVaultStateReq = SingleDirectSingleVaultStateReq(
                                DST_CHAINS[0],
                                vars.singleSuperFormsData[0],
                                action.adapterParam,
                                action.msgValue
                            );

                            if (action.action == Actions.Deposit)
                                superRouter.singleDirectSingleVaultDeposit{
                                    value: action.msgValue
                                }(vars.singleDirectSingleVaultStateReq);
                            else if (action.action == Actions.Withdraw)
                                superRouter.singleDirectSingleVaultWithdraw{
                                    value: action.msgValue
                                }(vars.singleDirectSingleVaultStateReq);
                        }
                    } else if (vars.nDestinations > 1) {
                        vars
                            .multiDstSingleVaultStateReq = MultiDstSingleVaultStateReq(
                            primaryAMB,
                            secondaryAMBs,
                            DST_CHAINS,
                            vars.singleSuperFormsData,
                            action.adapterParam,
                            action.msgValue
                        );
                    }
                }

                for (uint256 i = 0; i < vars.nDestinations; i++) {
                    aV.toChainId = DST_CHAINS[i];
                    /// @dev STEP 3 (FOR XCHAIN) Use corresponding AMB helper to get the message data and assert

                    if (CHAIN_0 != aV.toChainId) {
                        stateRegistry = CoreStateRegistry(
                            payable(
                                getContract(aV.toChainId, "CoreStateRegistry")
                            )
                        );
                        /// @dev this will probably need to loop given the number of destinations

                        vars.logs = vm.getRecordedLogs();

                        /// @dev see pigeon for this implementation
                        /// @dev PIGEON DOES NOT WORK FOR MULTI DESTINATION (IT NEEDS AN ARRAY OF LZ ENDPOINTS!!!!)
                        LayerZeroHelper(getContract(CHAIN_0, "LayerZeroHelper"))
                            .helpWithEstimates(
                                vars.lzEndpoints_1[i],
                                1000000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                                FORKS[aV.toChainId],
                                vars.logs
                            );

                        HyperlaneHelper(getContract(CHAIN_0, "HyperlaneHelper"))
                            .help(
                                address(HyperlaneMailbox),
                                FORKS[aV.toChainId],
                                vars.logs
                            );
                        vm.selectFork(FORKS[aV.toChainId]);

                        aV.payloadNumberBefore = stateRegistry.payloadsCount();
                        aV.data = abi.decode(
                            stateRegistry.payload(
                                aV.payloadNumberBefore +
                                    1 -
                                    vars.nDestinations +
                                    i
                            ),
                            (AMBMessage)
                        );

                        /// @dev to assert LzMessage hasn't been tampered with (later we can assert tampers of this message)
                        /// @dev - assert the payload reached destination state registry
                        if (action.multiVaults) {
                            aV.expectedMultiVaultsData = vars
                                .multiSuperFormsData[i];
                            aV.receivedMultiVaultData = abi.decode(
                                aV.data.params,
                                (InitMultiVaultData)
                            );

                            assertEq(
                                aV.expectedMultiVaultsData.superFormIds,
                                aV.receivedMultiVaultData.superFormIds
                            );

                            assertEq(
                                aV.expectedMultiVaultsData.amounts,
                                aV.receivedMultiVaultData.amounts
                            );
                        } else {
                            aV.expectedSingleVaultData = vars
                                .singleSuperFormsData[i];

                            aV.receivedSingleVaultData = abi.decode(
                                aV.data.params,
                                (InitSingleVaultData)
                            );

                            assertEq(
                                aV.expectedSingleVaultData.superFormId,
                                aV.receivedSingleVaultData.superFormId
                            );

                            assertEq(
                                aV.expectedSingleVaultData.amount,
                                aV.receivedSingleVaultData.amount
                            );
                        }

                        /// @dev STEP 4 (FOR XCHAIN) Update State and Process Payloads

                        if (action.action == Actions.Deposit) {
                            unchecked {
                                PAYLOAD_ID[aV.toChainId]++;
                            }
                            vars
                                .multiVaultsPayloadArg = UpdateMultiVaultPayloadArgs(
                                PAYLOAD_ID[aV.toChainId],
                                aV.receivedMultiVaultData.amounts,
                                action.slippage,
                                aV.toChainId,
                                action.testType,
                                action.revertError,
                                action.revertRole
                            );

                            vars
                                .singleVaultsPayloadArg = UpdateSingleVaultPayloadArgs(
                                PAYLOAD_ID[aV.toChainId],
                                aV.receivedSingleVaultData.amount,
                                action.slippage,
                                aV.toChainId,
                                action.testType,
                                action.revertError,
                                action.revertRole
                            );
                            if (action.testType == TestType.Pass) {
                                /// @dev multi tx is currently disabled until fixed
                                /*
                                    if (action.multiTx) {
                                        _processMultiTx(
                                            aV.toChainId,
                                            vars.underlyingSrcToken[i][0], /// @dev should be made to support multiple tokens
                                            vars.amounts[i][0] /// @dev should be made to support multiple tokens
                                        );
                                    }
                                */

                                if (action.multiVaults) {
                                    _updateMultiVaultPayload(
                                        vars.multiVaultsPayloadArg
                                    );
                                } else if (
                                    vars.singleSuperFormsData.length > 0
                                ) {
                                    _updateSingleVaultPayload(
                                        vars.singleVaultsPayloadArg
                                    );
                                }

                                vm.recordLogs();
                                _processPayload(
                                    PAYLOAD_ID[aV.toChainId],
                                    aV.toChainId,
                                    action.testType,
                                    action.revertError
                                );

                                vars.logs = vm.getRecordedLogs();

                                LayerZeroHelper(
                                    getContract(aV.toChainId, "LayerZeroHelper")
                                ).helpWithEstimates(
                                        vars.lzEndpoint_0,
                                        1000000, /// (change to 2000000) @dev This is the gas value to send - value needs to be tested and probably be lower
                                        FORKS[CHAIN_0],
                                        vars.logs
                                    );

                                HyperlaneHelper(
                                    getContract(aV.toChainId, "HyperlaneHelper")
                                ).help(
                                        address(HyperlaneMailbox),
                                        FORKS[CHAIN_0],
                                        vars.logs
                                    );

                                unchecked {
                                    PAYLOAD_ID[CHAIN_0]++;
                                }

                                _processPayload(
                                    PAYLOAD_ID[CHAIN_0],
                                    CHAIN_0,
                                    action.testType,
                                    action.revertError
                                );
                            } else if (
                                action.testType == TestType.RevertProcessPayload
                            ) {
                                aV.success = _processPayload(
                                    PAYLOAD_ID[aV.toChainId],
                                    aV.toChainId,
                                    action.testType,
                                    action.revertError
                                );
                                if (!aV.success) {
                                    return false;
                                }
                            } else if (
                                action.testType ==
                                TestType.RevertUpdateStateSlippage ||
                                action.testType ==
                                TestType.RevertUpdateStateRBAC
                            ) {
                                if (action.multiVaults) {
                                    aV.success = _updateMultiVaultPayload(
                                        vars.multiVaultsPayloadArg
                                    );
                                } else {
                                    aV.success = _updateSingleVaultPayload(
                                        vars.singleVaultsPayloadArg
                                    );
                                }

                                if (!aV.success) {
                                    return false;
                                }
                            }
                        } else {
                            unchecked {
                                PAYLOAD_ID[aV.toChainId]++;
                            }
                            _processPayload(
                                PAYLOAD_ID[aV.toChainId],
                                aV.toChainId,
                                action.testType,
                                action.revertError
                            );
                        }
                    }
                    vm.selectFork(aV.initialFork);
                }
            } else {
                /// @dev not done
            }
        }
    }

    function _buildMultiVaultCallData(
        MultiVaultCallDataArgs memory args
    ) internal returns (MultiVaultsSFData memory superFormsData) {
        SingleVaultSFData memory superFormData;
        uint256 len = args.superFormIds.length;
        LiqRequest[] memory liqRequests = new LiqRequest[](len);
        SingleVaultCallDataArgs memory callDataArgs;
        for (uint i = 0; i < len; i++) {
            callDataArgs = SingleVaultCallDataArgs(
                args.user,
                args.fromSrc,
                args.toDst,
                args.underlyingTokens[i],
                args.superFormIds[i],
                args.amounts[i],
                args.maxSlippage[i],
                args.vaultMock[i],
                args.srcChainId,
                args.toChainId,
                args.multiTx,
                args.actionKind
            );
            if (args.action == Actions.Deposit) {
                superFormData = _buildSingleVaultDepositCallData(callDataArgs);
            } else if (args.action == Actions.Withdraw) {
                superFormData = _buildSingleVaultWithdrawCallData(callDataArgs);
            }

            liqRequests[i] = superFormData.liqRequest;
        }

        superFormsData = MultiVaultsSFData(
            args.superFormIds,
            args.amounts,
            args.maxSlippage,
            liqRequests,
            ""
        );
    }

    function _buildSingleVaultDepositCallData(
        SingleVaultCallDataArgs memory args
    ) internal returns (SingleVaultSFData memory superFormData) {
        uint256 initialFork = vm.activeFork();

        address from = args.fromSrc;

        if (args.srcChainId == args.toChainId) {
            /// @dev same chain deposit, from is Form
            /// @dev FIXME: this likely needs to be TOKENBANK now
            from = args.toDst;
        }
        /// @dev check this from down here when contracts are fixed for multi vault
        /// @dev build socket tx data for a mock socket transfer (using new Mock contract because of the two forks)
        bytes memory socketTxData = abi.encodeWithSignature(
            "mockSocketTransfer(address,address,address,uint256,uint256)",
            from,
            args.multiTx
                ? getContract(args.toChainId, "MultiTxProcessor")
                : args.toDst, /// NOTE: TokenBank address / Form address???
            args.underlyingToken,
            args.amount, /// @dev FIXME - not testing sum of amounts (different vaults)
            FORKS[args.toChainId]
        );

        LiqRequest memory liqReq = LiqRequest(
            1, /// @dev FIXME: hardcoded for now
            socketTxData,
            args.underlyingToken,
            getContract(args.srcChainId, "SocketRouterMockFork"),
            args.amount, /// @dev FIXME -  not testing sum of amounts (different vaults)
            0
        );

        vm.selectFork(FORKS[args.srcChainId]);

        /// @dev - APPROVE transfer to SuperRouter (because of Socket)
        vm.prank(args.user);
        MockERC20(args.underlyingToken).approve(from, args.amount);

        vm.selectFork(initialFork);

        superFormData = SingleVaultSFData(
            args.superFormId,
            args.amount,
            args.maxSlippage,
            liqReq,
            ""
        );
    }

    function _buildSingleVaultWithdrawCallData(
        SingleVaultCallDataArgs memory args
    ) internal returns (SingleVaultSFData memory superFormData) {
        uint256 amountToWithdraw;

        if (args.actionKind == LiquidityChange.Full) {
            uint256 sharesBalanceBeforeWithdraw;
            vm.selectFork(FORKS[args.srcChainId]);

            sharesBalanceBeforeWithdraw = SuperRouter(payable(args.fromSrc))
                .balanceOf(args.user, args.superFormId);

            vm.selectFork(FORKS[args.toChainId]);

            /// @dev FIXME likely can be changed to form
            amountToWithdraw = VaultMock(args.vaultMock).previewRedeem(
                sharesBalanceBeforeWithdraw
            );
        } else if (args.actionKind == LiquidityChange.Partial) {
            amountToWithdraw = args.amount;
        }

        /// @dev check this from down here when contracts are fixed for multi vault
        /// @dev build socket tx data for a mock socket transfer (using new Mock contract because of the two forks)
        bytes memory socketTxData = abi.encodeWithSignature(
            "mockSocketTransfer(address,address,address,uint256,uint256)",
            args.toDst,
            args.user,
            args.underlyingToken,
            amountToWithdraw, /// @dev FIXME - not testing sum of amounts (different vaults)
            FORKS[args.toChainId]
        );

        LiqRequest memory liqReq = LiqRequest(
            1, /// @dev FIXME: hardcoded for now
            socketTxData,
            args.underlyingToken,
            getContract(args.srcChainId, "SocketRouterMockFork"),
            amountToWithdraw, /// @dev FIXME -  not testing sum of amounts (different vaults)
            0
        );

        superFormData = SingleVaultSFData(
            args.superFormId,
            amountToWithdraw,
            args.maxSlippage,
            liqReq,
            ""
        );
    }

    /*///////////////////////////////////////////////////////////////
                             HELPERS
    //////////////////////////////////////////////////////////////*/

    struct TargetVaultsVars {
        uint256[] underlyingTokenIds;
        uint256[] superFormIdsTemp;
        uint256 len;
        string underlyingToken;
    }

    /// @dev this function is used to build the 2D arrays in the best way possible
    function _targetVaults(
        uint16 chain0,
        uint16 chain1,
        uint256 action
    )
        internal
        view
        returns (
            uint256[] memory targetSuperFormsMem,
            address[] memory underlyingSrcTokensMem,
            address[] memory vaultMocksMem
        )
    {
        TargetVaultsVars memory vars;
        vars.underlyingTokenIds = TARGET_UNDERLYING_VAULTS[chain1][action];
        vars.superFormIdsTemp = _superFormIds(vars.underlyingTokenIds, chain1);
        vars.len = vars.superFormIdsTemp.length;
        if (vars.len == 0) revert LEN_VAULTS_ZERO();

        targetSuperFormsMem = new uint256[](vars.len);
        underlyingSrcTokensMem = new address[](vars.len);
        vaultMocksMem = new address[](vars.len);

        for (uint256 i = 0; i < vars.len; i++) {
            vars.underlyingToken = UNDERLYING_TOKENS[
                vars.underlyingTokenIds[i]
            ];

            targetSuperFormsMem[i] = vars.superFormIdsTemp[i];
            underlyingSrcTokensMem[i] = getContract(
                chain0,
                vars.underlyingToken
            );
            vaultMocksMem[i] = getContract(
                chain1,
                VAULT_NAMES[vars.underlyingTokenIds[i]]
            );
        }
    }

    function _superFormIds(
        uint256[] memory underlyingTokenIds_,
        uint16 chainId_
    ) internal view returns (uint256[] memory) {
        uint256[] memory superFormIds_ = new uint256[](
            underlyingTokenIds_.length
        );
        for (uint256 i = 0; i < underlyingTokenIds_.length; i++) {
            if (underlyingTokenIds_[i] > UNDERLYING_TOKENS.length)
                revert WRONG_UNDERLYING_ID();

            address vault = getContract(
                chainId_,
                string.concat(
                    UNDERLYING_TOKENS[underlyingTokenIds_[i]],
                    "Vault"
                )
            );

            superFormIds_[i] = _superFormId(
                vault,
                FORMS_FOR_VAULTS[underlyingTokenIds_[i]],
                chainId_
            );
        }
        return superFormIds_;
    }

    function _superFormId(
        address vault_,
        uint256 formId_,
        uint16 chainId_
    ) internal pure returns (uint256 superFormId_) {
        superFormId_ = uint256(uint160(vault_));
        superFormId_ |= formId_ << 160;
        superFormId_ |= uint256(chainId_) << 240;
    }

    /*
    /// @dev keeping this for integration of future assertions
    function deposit(
        TestAction memory action_,
        ActionLocalVars memory vars
    ) public returns (bool) {
        TestAssertionVars memory aV;
        aV.lenRequests = vars.amounts.length;

        
        /// @dev calculate amounts before deposit

        aV.superPositionsAmountBefore = new uint256[][](aV.lenRequests);
        aV.destinationSharesBefore = new uint256[][](aV.lenRequests);

        for (uint256 i = 0; i < aV.lenRequests; i++) {
            aV.tSPAmtBefore = new uint256[](allowedNumberOfVaultsPerRequest);
            aV.tDestinationSharesAmtBefore = new uint256[](
                allowedNumberOfVaultsPerRequest
            );
            for (uint256 j = 0; j < allowedNumberOfVaultsPerRequest; j++) {
                vm.selectFork(FORKS[action_.CHAIN_0]);
                aV.tSPAmtBefore[j] = SuperRouter(vars.fromSrc).balanceOf(
                    action_.user,
                    vars.targetSuperFormIds[i][j]
                );

                vm.selectFork(FORKS[action_.CHAIN_1]);
                /// @dev this should be the balance of FormBank in the future
                aV.tDestinationSharesAmtBefore[j] = VaultMock(
                    vars.vaultMock[i][j]
                ).balanceOf(getContract(action_.CHAIN_1, "ERC4626Form"));
            }
            aV.superPositionsAmountBefore[i] = aV.tSPAmtBefore;
            aV.destinationSharesBefore[i] = aV.tDestinationSharesAmtBefore;
        }

        /// @dev asserts for verification
        for (uint256 i = 0; i < aV.lenRequests; i++) {
            for (uint256 j = 0; j < allowedNumberOfVaultsPerRequest; j++) {
                vm.selectFork(FORKS[action_.CHAIN_0]);

                assertEq(
                    SuperRouter(vars.fromSrc).balanceOf(
                        action_.user,
                        vars.targetSuperFormIds[i][j]
                    ),
                    aV.superPositionsAmountBefore[i][j] + vars.amounts[i][j]
                );

                vm.selectFork(FORKS[action_.CHAIN_1]);

                assertEq(
                    VaultMock(vars.vaultMock[i][j]).balanceOf(
                        getContract(action_.CHAIN_1, "ERC4626Form")
                    ),
                    aV.destinationSharesBefore[i][j] + vars.amounts[i][j]
                );
            }
        }

        return true;
    
    }


    function withdraw(
        TestAction memory action,
        ActionLocalVars memory vars
    ) public returns (bool) {
        TestAssertionVars memory aV;

        aV.lenRequests = vars.amounts.length;
        if (
            vars.targetSuperFormIds.length != aV.lenRequests &&
            aV.lenRequests == 0
        ) revert LEN_MISMATCH();

        vars.stateReqs = new StateReq[](aV.lenRequests);
        vars.liqReqs = new LiqRequest[](aV.lenRequests);

        for (uint256 i = 0; i < aV.lenRequests; i++) {
            (vars.stateReqs[i], vars.liqReqs[i]) = _buildWithdrawCallData(
                BuildWithdrawCallDataArgs(
                    action.user,
                    payable(vars.fromSrc),
                    vars.toDst,
                    vars.underlyingSrcToken[i], /// @dev we probably need to create liq request with both src and dst tokens
                    vars.vaultMock[i],
                    vars.targetSuperFormIds[i],
                    vars.amounts[i],
                    action.maxSlippage,
                    action.actionKind,
                    action.CHAIN_0,
                    action.CHAIN_1
                )
            );
        }

        /// @dev calculate amounts before withdraw
        aV.superPositionsAmountBefore = new uint256[][](aV.lenRequests);
        aV.destinationSharesBefore = new uint256[][](aV.lenRequests);

        for (uint256 i = 0; i < aV.lenRequests; i++) {
            aV.tSPAmtBefore = new uint256[](allowedNumberOfVaultsPerRequest);
            aV.tDestinationSharesAmtBefore = new uint256[](
                allowedNumberOfVaultsPerRequest
            );
            for (uint256 j = 0; j < allowedNumberOfVaultsPerRequest; j++) {
                vm.selectFork(FORKS[action.CHAIN_0]);
                aV.tSPAmtBefore[j] = SuperRouter(vars.fromSrc).balanceOf(
                    action.user,
                    vars.targetSuperFormIds[i][j]
                );

                vm.selectFork(FORKS[action.CHAIN_1]);
                aV.tDestinationSharesAmtBefore[j] = VaultMock(
                    vars.vaultMock[i][j]
                ).balanceOf(getContract(action.CHAIN_1, "ERC4626Form"));
            }
            aV.superPositionsAmountBefore[i] = aV.tSPAmtBefore;
            aV.destinationSharesBefore[i] = aV.tDestinationSharesAmtBefore;
        }

        _actionToSuperRouter(
            InternalActionArgs(
                vars.fromSrc,
                vars.lzEndpoint_1,
                action.user,
                vars.stateReqs,
                vars.liqReqs,
                action.CHAIN_0,
                action.CHAIN_1,
                action.action,
                action.testType,
                action.revertError,
                action.multiTx
            )
        );

        if (action.CHAIN_0 != action.CHAIN_1) {
            for (uint256 i = 0; i < aV.lenRequests; i++) {
                PAYLOAD_ID[action.CHAIN_1]++;
                _processPayload(
                    PAYLOAD_ID[action.CHAIN_1],
                    action.CHAIN_1,
                    action.testType,
                    action.revertError
                );
            }
        }

        /// @dev asserts for verification
        for (uint256 i = 0; i < aV.lenRequests; i++) {
            for (uint256 j = 0; j < allowedNumberOfVaultsPerRequest; j++) {
                vm.selectFork(FORKS[action.CHAIN_0]);

                assertEq(
                    SuperRouter(vars.fromSrc).balanceOf(
                        action.user,
                        vars.targetSuperFormIds[i][j]
                    ),
                    aV.superPositionsAmountBefore[i][j] - vars.amounts[i][j]
                );

                vm.selectFork(FORKS[action.CHAIN_1]);

                assertEq(
                    VaultMock(vars.vaultMock[i][j]).balanceOf(
                        getContract(action.CHAIN_1, "ERC4626Form")
                    ),
                    aV.destinationSharesBefore[i][j] - vars.amounts[i][j]
                );
            }
        }

        return true;
    }

*/

    /// @dev FIXME: only working for updateMultiVaultPayload
    function _updateMultiVaultPayload(
        UpdateMultiVaultPayloadArgs memory args
    ) internal returns (bool) {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[args.targetChainId]);
        uint256 len = args.amounts.length;
        uint256[] memory finalAmounts = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            finalAmounts[i] = args.amounts[i];
            if (args.slippage > 0) {
                finalAmounts[i] =
                    (args.amounts[i] * (10000 - uint256(args.slippage))) /
                    10000;
            } else if (args.slippage < 0) {
                args.slippage = -args.slippage;
                finalAmounts[i] =
                    (args.amounts[i] * (10000 + uint256(args.slippage))) /
                    10000;
            }
        }

        if (args.testType == TestType.Pass) {
            vm.prank(deployer);

            CoreStateRegistry(
                payable(getContract(args.targetChainId, "CoreStateRegistry"))
            ).updateMultiVaultPayload(args.payloadId, finalAmounts);
        } else if (args.testType == TestType.RevertUpdateStateSlippage) {
            vm.prank(deployer);

            vm.expectRevert(args.revertError); /// @dev removed string here: come to this later

            CoreStateRegistry(
                payable(getContract(args.targetChainId, "CoreStateRegistry"))
            ).updateMultiVaultPayload(args.payloadId, finalAmounts);

            return false;
        } else if (args.testType == TestType.RevertUpdateStateRBAC) {
            vm.prank(users[2]);
            bytes memory errorMsg = getAccessControlErrorMsg(
                users[2],
                args.revertRole
            );
            vm.expectRevert(errorMsg);

            CoreStateRegistry(
                payable(getContract(args.targetChainId, "CoreStateRegistry"))
            ).updateMultiVaultPayload(args.payloadId, finalAmounts);

            return false;
        }

        vm.selectFork(initialFork);

        return true;
    }

    function _updateSingleVaultPayload(
        UpdateSingleVaultPayloadArgs memory args
    ) internal returns (bool) {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[args.targetChainId]);
        uint256 finalAmount;

        finalAmount = args.amount;
        if (args.slippage > 0) {
            finalAmount =
                (args.amount * (10000 - uint256(args.slippage))) /
                10000;
        } else if (args.slippage < 0) {
            args.slippage = -args.slippage;
            finalAmount =
                (args.amount * (10000 + uint256(args.slippage))) /
                10000;
        }

        if (args.testType == TestType.Pass) {
            vm.prank(deployer);

            CoreStateRegistry(
                payable(getContract(args.targetChainId, "CoreStateRegistry"))
            ).updateSingleVaultPayload(args.payloadId, finalAmount);
        } else if (args.testType == TestType.RevertUpdateStateSlippage) {
            vm.prank(deployer);

            vm.expectRevert(args.revertError); /// @dev removed string here: come to this later

            CoreStateRegistry(
                payable(getContract(args.targetChainId, "CoreStateRegistry"))
            ).updateSingleVaultPayload(args.payloadId, finalAmount);

            return false;
        } else if (args.testType == TestType.RevertUpdateStateRBAC) {
            vm.prank(users[2]);
            bytes memory errorMsg = getAccessControlErrorMsg(
                users[2],
                args.revertRole
            );
            vm.expectRevert(errorMsg);

            CoreStateRegistry(
                payable(getContract(args.targetChainId, "CoreStateRegistry"))
            ).updateSingleVaultPayload(args.payloadId, finalAmount);

            return false;
        }

        vm.selectFork(initialFork);

        return true;
    }

    function _processPayload(
        uint256 payloadId_,
        uint16 targetChainId_,
        TestType testType,
        bytes4 revertError
    ) internal returns (bool) {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[targetChainId_]);

        uint256 msgValue = 10 * _getPriceMultiplier(targetChainId_) * 1e18;

        vm.prank(deployer);
        if (testType == TestType.Pass) {
            CoreStateRegistry(
                payable(getContract(targetChainId_, "CoreStateRegistry"))
            ).processPayload{value: msgValue}(payloadId_);
        } else if (testType == TestType.RevertProcessPayload) {
            vm.expectRevert();

            CoreStateRegistry(
                payable(getContract(targetChainId_, "CoreStateRegistry"))
            ).processPayload{value: msgValue}(payloadId_);

            return false;
        }

        vm.selectFork(initialFork);
        return true;
    }

    function _processMultiTx(
        uint16 targetChainId_,
        address underlyingToken_,
        uint256 amount_
    ) internal {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[targetChainId_]);

        vm.prank(deployer);
        /// @dev builds the data to be processed by the keeper contract.
        /// @dev at this point the tokens are delivered to the multi-tx processor on the destination chain.
        bytes memory socketTxData = abi.encodeWithSignature(
            "mockSocketTransfer(address,address,address,uint256,uint256)",
            getContract(targetChainId_, "MultiTxProcessor"),
            getContract(targetChainId_, "TokenBank"),
            underlyingToken_, /// @dev FIXME - needs fix because it should have an array of underlying like state req
            amount_, /// @dev FIXME - 1 amount is sent, not testing sum of amounts (different vaults)
            FORKS[targetChainId_]
        );

        MultiTxProcessor(
            payable(getContract(targetChainId_, "MultiTxProcessor"))
        ).processTx(
                bridgeIds[0],
                socketTxData,
                underlyingToken_,
                getContract(targetChainId_, "SocketRouterMockFork"),
                amount_
            );
        vm.selectFork(initialFork);
    }
}
