/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @dev lib imports
import "./BaseSetup.sol";
import "forge-std/console.sol";
import "../../utils/DataPacking.sol";

abstract contract ProtocolActions is BaseSetup {
    uint8 public primaryAMB;

    uint8[] public secondaryAMBs;

    uint16 public CHAIN_0;

    uint16[] public DST_CHAINS;

    mapping(uint16 chainId => mapping(uint256 action => uint256[] underlyingTokenIds))
        public TARGET_UNDERLYING_VAULTS;

    mapping(uint16 chainId => mapping(uint256 action => uint256[] formKinds))
        public TARGET_FORM_KINDS;

    mapping(uint16 chainId => mapping(uint256 index => uint256[] action))
        public AMOUNTS;

    mapping(uint16 chainId => mapping(uint256 index => uint256[] action))
        public MAX_SLIPPAGE;

    /// NOTE: Now that we can pass individual actions, this array is only useful for more extended simulations
    TestAction[] public actions;

    function setUp() public virtual override {
        super.setUp();
    }

    /*///////////////////////////////////////////////////////////////
                            MAIN INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev STEP 1: Build Request Data
    /// NOTE: This whole step should be looked upon as PROTOCOL action, not USER action
    /// Request is built for user, but all of operations here would be performed by protocol and not even it's smart contracts
    /// It's worth checking out if we are not making to many of the assumptions here too.
    function _stage1_buildReqData(
        TestAction memory action,
        uint256 actionIndex
    )
        internal
        returns (
            MultiVaultsSFData[] memory multiSuperFormsData,
            SingleVaultSFData[] memory singleSuperFormsData,
            StagesLocalVars memory vars
        )
    {
        if (action.revertError != bytes4(0) && action.testType == TestType.Pass)
            revert MISMATCH_TEST_TYPE();

        /// FIXME: Separate concerns in tests, this revert is for protocol level operation
        if (
            (action.testType != TestType.RevertUpdateStateRBAC &&
                action.revertRole != bytes32(0)) ||
            (action.testType == TestType.RevertUpdateStateRBAC &&
                action.revertRole == bytes32(0))
        ) revert MISMATCH_RBAC_TEST();

        vars.lzEndpoint_0 = LZ_ENDPOINTS[CHAIN_0];
        vars.fromSrc = payable(getContract(CHAIN_0, "SuperRouter"));

        vars.nDestinations = DST_CHAINS.length;

        vars.lzEndpoints_1 = new address[](vars.nDestinations);
        vars.toDst = new address[](vars.nDestinations);
        multiSuperFormsData = new MultiVaultsSFData[](vars.nDestinations);
        singleSuperFormsData = new SingleVaultSFData[](vars.nDestinations);

        /// @dev FIXME this probably needs to be tailored for NATIVE DEPOSITS
        /// @dev with multi state requests, the entire msg.value is used. Msg.value in that case should cover
        /// @dev the sum of native assets needed in each state request
        action.msgValue =
            (vars.nDestinations + 1) *
            _getPriceMultiplier(CHAIN_0) *
            1e18;

        for (uint256 i = 0; i < vars.nDestinations; i++) {
            vars.lzEndpoints_1[i] = LZ_ENDPOINTS[DST_CHAINS[i]];
            (
                vars.targetSuperFormIds,
                vars.underlyingSrcToken,
                vars.vaultMock
            ) = _targetVaults(CHAIN_0, DST_CHAINS[i], actionIndex);
            vars.toDst = new address[](vars.targetSuperFormIds.length);

            /// @dev action is sameChain, if there is a liquidity swap it should go to the same form
            /// @dev if action is cross chain withdraw, user can select to receive a different kind of underlying from source
            
            for (uint256 k = 0; k < vars.targetSuperFormIds.length; k++) {
                if (
                    CHAIN_0 == DST_CHAINS[i] ||
                    (action.action == Actions.Withdraw &&
                        CHAIN_0 != DST_CHAINS[i])
                ) {
                    (vars.superFormT, , ) = _getSuperForm(
                        vars.targetSuperFormIds[k]
                    );
                    vars.toDst[k] = payable(vars.superFormT);
                } else {
                    vars.toDst[k] = payable(
                        getContract(DST_CHAINS[i], "TokenBank")
                    );
                }
            }

            vars.amounts = AMOUNTS[DST_CHAINS[i]][actionIndex];

            vars.maxSlippage = MAX_SLIPPAGE[DST_CHAINS[i]][actionIndex];

            if (action.multiVaults) {
                multiSuperFormsData[i] = _buildMultiVaultCallData(
                    MultiVaultCallDataArgs(
                        action.user,
                        vars.fromSrc,
                        vars.toDst,
                        vars.underlyingSrcToken,
                        vars.targetSuperFormIds,
                        vars.amounts,
                        vars.maxSlippage,
                        vars.vaultMock,
                        CHAIN_0,
                        DST_CHAINS[i],
                        action.multiTx,
                        action.action
                    )
                );
            } else {

                /// FIXME: NOTE: Shouldn't we validate that at contract level?
                /// This reverting may give us invalid sense of security. Contract should revert here, not test.
                
                // if (
                //     !((vars.underlyingSrcToken.length ==
                //         vars.targetSuperFormIds.length) &&

                //         (vars.underlyingSrcToken.length ==
                //             vars.amounts.length) &&

                //         (vars.underlyingSrcToken.length ==
                //             vars.maxSlippage.length) &&

                //         (vars.underlyingSrcToken.length == 1))
                // ) revert INVALID_AMOUNTS_LENGTH();

                SingleVaultCallDataArgs
                    memory singleVaultCallDataArgs = SingleVaultCallDataArgs(
                        action.user,
                        vars.fromSrc,
                        vars.toDst[0],
                        vars.underlyingSrcToken[0],
                        vars.targetSuperFormIds[0],
                        vars.amounts[0],
                        vars.maxSlippage[0],
                        vars.vaultMock[0],
                        CHAIN_0,
                        DST_CHAINS[i],
                        action.multiTx,
                        0,
                        address(0)
                    );

                if (action.action == Actions.Deposit) {
                    singleSuperFormsData[i] = _buildSingleVaultDepositCallData(
                        singleVaultCallDataArgs
                    );
                } else {
                    singleSuperFormsData[i] = _buildSingleVaultWithdrawCallData(
                        singleVaultCallDataArgs
                    );
                }
            }
        }
    }

    /// @dev STEP 2: Run Source Chain Action
    function _stage2_run_src_action(
        TestAction memory action,
        MultiVaultsSFData[] memory multiSuperFormsData,
        SingleVaultSFData[] memory singleSuperFormsData,
        StagesLocalVars memory vars
    ) internal returns (StagesLocalVars memory, MessagingAssertVars memory) {
        MessagingAssertVars memory aV;

        SuperRouter superRouter = SuperRouter(vars.fromSrc);

        vm.selectFork(FORKS[CHAIN_0]);

        aV.initialFork = vm.activeFork();

        aV.txIdBefore = superRouter.totalTransactions();

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
                        multiSuperFormsData[0],
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
                        multiSuperFormsData,
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
                            singleSuperFormsData[0],
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
                            singleSuperFormsData[0],
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
                        singleSuperFormsData,
                        action.adapterParam,
                        action.msgValue
                    );
                    if (action.action == Actions.Deposit)
                        superRouter.multiDstSingleVaultDeposit{
                            value: action.msgValue
                        }(vars.multiDstSingleVaultStateReq);
                    else if (action.action == Actions.Withdraw)
                        superRouter.multiDstSingleVaultWithdraw{
                            value: action.msgValue
                        }(vars.multiDstSingleVaultStateReq);
                }
            }
        } else {
            /// @dev not done
        }

        return (vars, aV);
    }

    /// @dev STEP 3 (FOR XCHAIN) Use corresponding AMB helper to get the message data and assert
    function _stage3_src_to_dst_amb_delivery(
        TestAction memory action,
        StagesLocalVars memory vars,
        MessagingAssertVars memory aV,
        MultiVaultsSFData[] memory multiSuperFormsData,
        SingleVaultSFData[] memory singleSuperFormsData
    ) internal {
        CoreStateRegistry stateRegistry;

        for (uint256 i = 0; i < vars.nDestinations; i++) {
            aV.toChainId = DST_CHAINS[i];

            if (CHAIN_0 != aV.toChainId) {
                stateRegistry = CoreStateRegistry(
                    payable(getContract(aV.toChainId, "CoreStateRegistry"))
                );
                /// @dev this will probably need to loop given the number of destinations

                vars.logs = vm.getRecordedLogs();

                /// @dev see pigeon for this implementation
                /// @dev PIGEON DOES NOT WORK FOR MULTI DESTINATION (IT NEEDS AN ARRAY OF LZ ENDPOINTS!!!!)
                LayerZeroHelper(getContract(CHAIN_0, "LayerZeroHelper"))
                    .helpWithEstimates(
                        vars.lzEndpoints_1[i],
                        2000000, /// @dev FIXME This needs to use a real gas amount!!
                        FORKS[aV.toChainId],
                        vars.logs
                    );

                HyperlaneHelper(getContract(CHAIN_0, "HyperlaneHelper")).help(
                    address(HyperlaneMailbox),
                    FORKS[aV.toChainId],
                    vars.logs
                );
                vm.selectFork(FORKS[aV.toChainId]);

                /// @dev NOTE: it's better to assert here inside the loop
                aV.payloadNumberBefore = stateRegistry.payloadsCount();
                aV.data = abi.decode(
                    stateRegistry.payload(
                        aV.payloadNumberBefore + 1 - vars.nDestinations + i
                    ),
                    (AMBMessage)
                );

                /// @dev to assert LzMessage hasn't been tampered with (later we can assert tampers of this message)
                /// @dev - assert the payload reached destination state registry
                if (action.multiVaults) {
                    aV.expectedMultiVaultsData = multiSuperFormsData[i];
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
                    aV.expectedSingleVaultData = singleSuperFormsData[i];

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
            }
            vm.selectFork(aV.initialFork);
        }
    }

    /// @dev STEP 4 Update state and process src to dst payload
    function _stage4_process_src_dst_payload(
        TestAction memory action,
        StagesLocalVars memory vars,
        MessagingAssertVars memory aV,
        SingleVaultSFData[] memory singleSuperFormsData,
        uint256 actionIndex
    ) internal returns (bool success) {
        /// assume it will pass by default
        success = true;
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            aV.toChainId = DST_CHAINS[i];

            if (CHAIN_0 != aV.toChainId) {
                if (action.action == Actions.Deposit) {
                    unchecked {
                        PAYLOAD_ID[aV.toChainId]++;
                    }
                    vars.multiVaultsPayloadArg = UpdateMultiVaultPayloadArgs(
                        PAYLOAD_ID[aV.toChainId],
                        aV.receivedMultiVaultData.amounts,
                        action.slippage,
                        aV.toChainId,
                        action.testType,
                        action.revertError,
                        action.revertRole
                    );

                    vars.singleVaultsPayloadArg = UpdateSingleVaultPayloadArgs(
                        PAYLOAD_ID[aV.toChainId],
                        aV.receivedSingleVaultData.amount,
                        action.slippage,
                        aV.toChainId,
                        action.testType,
                        action.revertError,
                        action.revertRole
                    );
                    if (action.testType == TestType.Pass) {
                        if (action.multiTx) {
                            if (action.multiVaults) {
                                (, vars.underlyingSrcToken, ) = _targetVaults(
                                    CHAIN_0,
                                    DST_CHAINS[i],
                                    actionIndex
                                );

                                vars.amounts = AMOUNTS[DST_CHAINS[i]][
                                    actionIndex
                                ];
                                _batchProcessMultiTx(
                                    aV.toChainId,
                                    vars.underlyingSrcToken,
                                    vars.amounts
                                );
                            } else {
                                _processMultiTx(
                                    aV.toChainId,
                                    singleSuperFormsData[i].liqRequest.token,
                                    singleSuperFormsData[i].amount
                                );
                            }
                        }

                        if (action.multiVaults) {
                            _updateMultiVaultPayload(
                                vars.multiVaultsPayloadArg
                            );
                        } else if (singleSuperFormsData.length > 0) {
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
                    } else if (
                        action.testType == TestType.RevertProcessPayload
                    ) {
                        success = _processPayload(
                            PAYLOAD_ID[aV.toChainId],
                            aV.toChainId,
                            action.testType,
                            action.revertError
                        );
                        if (!success) {
                            return success;
                        }
                    } else if (
                        action.testType == TestType.RevertUpdateStateSlippage ||
                        action.testType == TestType.RevertUpdateStateRBAC
                    ) {
                        if (action.multiVaults) {
                            success = _updateMultiVaultPayload(
                                vars.multiVaultsPayloadArg
                            );
                        } else {
                            success = _updateSingleVaultPayload(
                                vars.singleVaultsPayloadArg
                            );
                        }

                        if (!success) {
                            return success;
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
    }

    /// @dev STEP 5 Process dst to src payload (mint of SuperPositions for deposits)
    function _stage5_process_superPositions_mint(
        TestAction memory action,
        StagesLocalVars memory vars,
        MessagingAssertVars memory aV
    ) internal returns (bool success) {
        /// assume it will pass by default
        success = true;
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            aV.toChainId = DST_CHAINS[i];

            if (CHAIN_0 != aV.toChainId) {
                if (action.testType == TestType.Pass) {
                    unchecked {
                        PAYLOAD_ID[CHAIN_0]++;
                    }

                    success = _processPayload(
                        PAYLOAD_ID[CHAIN_0],
                        CHAIN_0,
                        action.testType,
                        action.revertError
                    );
                }

                vm.selectFork(aV.initialFork);
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

        if (len == 0) revert LEN_MISMATCH();

        uint256 totalAmount;
        address sameUnderlyingCheck = args.action == Actions.Deposit
            ? args.underlyingTokens[0]
            : address(0);

        for (uint i = 0; i < len; i++) {
            totalAmount += args.amounts[i];
            if (i + 1 < len) {
                if (sameUnderlyingCheck != args.underlyingTokens[i + 1]) {
                    sameUnderlyingCheck = address(0);
                }
            }
        }

        if (sameUnderlyingCheck != address(0)) {
            liqRequests = new LiqRequest[](1);
        }

        for (uint i = 0; i < len; i++) {
            callDataArgs = SingleVaultCallDataArgs(
                args.user,
                args.fromSrc,
                args.toDst[i],
                args.underlyingTokens[i],
                args.superFormIds[i],
                args.amounts[i],
                args.maxSlippage[i],
                args.vaultMock[i],
                args.srcChainId,
                args.toChainId,
                args.multiTx,
                totalAmount,
                sameUnderlyingCheck
            );
            if (args.action == Actions.Deposit) {
                superFormData = _buildSingleVaultDepositCallData(callDataArgs);
            } else if (args.action == Actions.Withdraw) {
                superFormData = _buildSingleVaultWithdrawCallData(callDataArgs);
            }
            /// @dev if it is a same underlying deposit  - only one liqRequest is needed with the sum of amounts. We also need to only approve total amount of the underlying token
            if (
                i == 0 &&
                args.action == Actions.Deposit &&
                sameUnderlyingCheck != address(0)
            ) {
                liqRequests[0] = superFormData.liqRequest;

                uint256 initialFork = vm.activeFork();

                address from = args.fromSrc;

                if (args.srcChainId == args.toChainId) {
                    /// @dev same chain deposit, from is Form
                    from = args.toDst[i];
                }

                vm.selectFork(FORKS[args.srcChainId]);

                /// @dev - APPROVE transfer to SuperRouter (because of Socket)
                vm.prank(args.user);
                MockERC20(args.underlyingTokens[i]).approve(from, totalAmount);

                vm.selectFork(initialFork);
            } else if (sameUnderlyingCheck == address(0)) {
                liqRequests[i] = superFormData.liqRequest;
            }
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
            args.sameUnderlyingCheck != address(0)
                ? args.totalAmount
                : args.amount,
            FORKS[args.toChainId]
        );

        LiqRequest memory liqReq = LiqRequest(
            1, /// @dev FIXME: hardcoded for now
            socketTxData,
            args.underlyingToken,
            getContract(args.srcChainId, "SocketRouterMockFork"),
            args.sameUnderlyingCheck != address(0)
                ? args.totalAmount
                : args.amount,
            0
        );

        if (args.sameUnderlyingCheck == address(0)) {
            vm.selectFork(FORKS[args.srcChainId]);

            /// @dev - APPROVE transfer to SuperRouter (because of Socket)
            vm.prank(args.user);
            MockERC20(args.underlyingToken).approve(from, args.amount);

            vm.selectFork(initialFork);
        }

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
    ) internal view returns (SingleVaultSFData memory superFormData) {
        /// @dev check this from down here when contracts are fixed for multi vault
        /// @dev build socket tx data for a mock socket transfer (using new Mock contract because of the two forks)
        bytes memory socketTxData = abi.encodeWithSignature(
            "mockSocketTransfer(address,address,address,uint256,uint256)",
            args.toDst,
            args.user,
            args.underlyingToken,
            args.amount,
            FORKS[args.toChainId]
        );

        LiqRequest memory liqReq = LiqRequest(
            1, /// @dev FIXME: hardcoded for now
            socketTxData,
            args.underlyingToken,
            getContract(args.srcChainId, "SocketRouterMockFork"),
            args.amount,
            0
        );

        superFormData = SingleVaultSFData(
            args.superFormId,
            args.amount,
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
        uint256[] formKinds;
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
        vars.formKinds = TARGET_FORM_KINDS[chain1][action];
        vars.superFormIdsTemp = _superFormIds(
            vars.underlyingTokenIds,
            vars.formKinds,
            chain1
        );

        vars.len = vars.superFormIdsTemp.length;

        if (vars.len == 0) revert LEN_VAULTS_ZERO();

        targetSuperFormsMem = new uint256[](vars.len);
        underlyingSrcTokensMem = new address[](vars.len);
        vaultMocksMem = new address[](vars.len);

        for (uint256 i = 0; i < vars.len; i++) {
            vars.underlyingToken = UNDERLYING_TOKENS[
                vars.underlyingTokenIds[i] // 1
            ];

            targetSuperFormsMem[i] = vars.superFormIdsTemp[i];
            underlyingSrcTokensMem[i] = getContract(
                chain0,
                vars.underlyingToken
            );
            vaultMocksMem[i] = getContract(
                chain1,
                VAULT_NAMES[vars.formKinds[i]][vars.underlyingTokenIds[i]]
            );
        }
    }

    function _superFormIds(
        uint256[] memory underlyingTokenIds_,
        uint256[] memory formKinds_,
        uint16 chainId_
    ) internal view returns (uint256[] memory) {
        uint256[] memory superFormIds_ = new uint256[](
            underlyingTokenIds_.length
        );
        if (underlyingTokenIds_.length != formKinds_.length)
            revert INVALID_TARGETS();

        for (uint256 i = 0; i < underlyingTokenIds_.length; i++) {
            /// NOTE/FIXME: This should be allowed to revert (or not) at the core level.
            /// Can produce false positive. (What if we revert here, but not in the core)
            if (formKinds_[i] > FORM_BEACON_IDS.length)
                revert WRONG_FORMBEACON_ID();
            if (underlyingTokenIds_[i] > UNDERLYING_TOKENS.length)
                revert WRONG_UNDERLYING_ID();

            address superForm = getContract(
                chainId_,
                string.concat(
                    UNDERLYING_TOKENS[underlyingTokenIds_[i]],
                    "SuperForm",
                    Strings.toString(FORM_BEACON_IDS[formKinds_[i]])
                )
            );

            superFormIds_[i] = _packSuperForm(
                superForm,
                FORM_BEACON_IDS[formKinds_[i]],
                chainId_
            );
        }

        return superFormIds_;
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
            underlyingToken_,
            amount_, /// @dev FIXME -  not testing sum of amounts (different vaults)
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

    function _batchProcessMultiTx(
        uint16 targetChainId_,
        address[] memory underlyingTokens_,
        uint256[] memory amounts_
    ) internal {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[targetChainId_]);

        vm.prank(deployer);
        /// @dev builds the data to be processed by the keeper contract.
        /// @dev at this point the tokens are delivered to the multi-tx processor on the destination chain.
        bytes[] memory socketTxDatas = new bytes[](underlyingTokens_.length);

        for (uint256 i = 0; i < underlyingTokens_.length; i++) {
            socketTxDatas[i] = abi.encodeWithSignature(
                "mockSocketTransfer(address,address,address,uint256,uint256)",
                getContract(targetChainId_, "MultiTxProcessor"),
                getContract(targetChainId_, "TokenBank"),
                underlyingTokens_[i],
                amounts_[i], /// @dev FIXME -  not testing sum of amounts (different vaults)
                FORKS[targetChainId_]
            );
        }

        MultiTxProcessor(
            payable(getContract(targetChainId_, "MultiTxProcessor"))
        ).batchProcessTx(
                bridgeIds[0],
                socketTxDatas,
                underlyingTokens_,
                getContract(targetChainId_, "SocketRouterMockFork"),
                amounts_
            );
        vm.selectFork(initialFork);
    }
}
