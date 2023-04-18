/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @dev lib imports
import "./BaseSetup.sol";
import "forge-std/console.sol";
import "../../utils/DataPacking.sol";
import {IPermit2} from "../../interfaces/IPermit2.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

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

                if (
                    action.action == Actions.Deposit ||
                    action.action == Actions.DepositPermit2
                ) {
                    singleSuperFormsData[i] = _buildSingleVaultDepositCallData(
                        singleVaultCallDataArgs,
                        action.action
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
    ) internal returns (StagesLocalVars memory) {
        SuperRouter superRouter = SuperRouter(vars.fromSrc);

        vm.selectFork(FORKS[CHAIN_0]);

        if (action.testType != TestType.RevertMainAction) {
            vm.prank(users[action.user]);
            /// @dev see @pigeon for this implementation
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

                    if (
                        action.action == Actions.Deposit ||
                        action.action == Actions.DepositPermit2
                    )
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

                    if (
                        action.action == Actions.Deposit ||
                        action.action == Actions.DepositPermit2
                    )
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

                        if (
                            action.action == Actions.Deposit ||
                            action.action == Actions.DepositPermit2
                        )
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

                        if (
                            action.action == Actions.Deposit ||
                            action.action == Actions.DepositPermit2
                        )
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
                    if (
                        action.action == Actions.Deposit ||
                        action.action == Actions.DepositPermit2
                    )
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

        return vars;
    }

    struct Stage3InternalVars {
        address[] toMailboxes;
        uint32[] expDstDomains;
        address[] endpoints;
        uint16[] lzChainIds;
        uint256[] forkIds;
        uint256 k;
    }

    /// @dev STEP 3 (FOR XCHAIN) Use corresponding AMB helper to get the message data and assert
    function _stage3_src_to_dst_amb_delivery(
        TestAction memory action,
        StagesLocalVars memory vars,
        MultiVaultsSFData[] memory multiSuperFormsData,
        SingleVaultSFData[] memory singleSuperFormsData
    ) internal returns (MessagingAssertVars[] memory) {
        Stage3InternalVars memory internalVars;
        MessagingAssertVars[] memory aV = new MessagingAssertVars[](
            vars.nDestinations
        );

        /// @dev STEP 3 (FOR XCHAIN) Use corresponding AMB helper to get the message data and assert
        internalVars.toMailboxes = new address[](vars.nDestinations);
        internalVars.expDstDomains = new uint32[](vars.nDestinations);

        internalVars.endpoints = new address[](vars.nDestinations);
        internalVars.lzChainIds = new uint16[](vars.nDestinations);

        internalVars.forkIds = new uint256[](vars.nDestinations);

        internalVars.k = 0;
        for (uint256 i = 0; i < chainIds.length; i++) {
            for (uint256 j = 0; j < vars.nDestinations; j++) {
                if (DST_CHAINS[j] == chainIds[i]) {
                    internalVars.toMailboxes[
                        internalVars.k
                    ] = hyperlaneMailboxes[i];
                    internalVars.expDstDomains[
                        internalVars.k
                    ] = hyperlane_chainIds[i];

                    internalVars.endpoints[internalVars.k] = lzEndpoints[i];
                    internalVars.lzChainIds[internalVars.k] = lz_chainIds[i];

                    internalVars.forkIds[internalVars.k] = FORKS[chainIds[i]];

                    internalVars.k++;
                }
            }
        }
        vars.logs = vm.getRecordedLogs();

        /// @dev see pigeon for this implementation
        HyperlaneHelper(getContract(CHAIN_0, "HyperlaneHelper")).help(
            address(HyperlaneMailbox),
            internalVars.toMailboxes,
            internalVars.expDstDomains,
            internalVars.forkIds,
            vars.logs
        );

        LayerZeroHelper(getContract(CHAIN_0, "LayerZeroHelper")).help(
            internalVars.endpoints,
            internalVars.lzChainIds,
            2000000, /// (change to 2000000) @dev FIXME: should be calculated automatically - This is the gas value to send - value needs to be tested and probably be lower
            internalVars.forkIds,
            vars.logs
        );

        CoreStateRegistry stateRegistry;
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            aV[i].initialFork = vm.activeFork();
            aV[i].toChainId = DST_CHAINS[i];
            vm.selectFork(FORKS[aV[i].toChainId]);

            if (CHAIN_0 != aV[i].toChainId) {
                stateRegistry = CoreStateRegistry(
                    payable(getContract(aV[i].toChainId, "CoreStateRegistry"))
                );

                /// @dev NOTE: it's better to assert here inside the loop
                aV[i].receivedPayloadId = stateRegistry.payloadsCount();
                aV[i].data = abi.decode(
                    stateRegistry.payload(aV[i].receivedPayloadId),
                    (AMBMessage)
                );

                /// @dev to assert LzMessage hasn't been tampered with (later we can assert tampers of this message)
                /// @dev - assert the payload reached destination state registry
                if (action.multiVaults) {
                    aV[i].expectedMultiVaultsData = multiSuperFormsData[i];
                    aV[i].receivedMultiVaultData = abi.decode(
                        aV[i].data.params,
                        (InitMultiVaultData)
                    );

                    assertEq(
                        aV[i].expectedMultiVaultsData.superFormIds,
                        aV[i].receivedMultiVaultData.superFormIds
                    );

                    assertEq(
                        aV[i].expectedMultiVaultsData.amounts,
                        aV[i].receivedMultiVaultData.amounts
                    );
                } else {
                    aV[i].expectedSingleVaultData = singleSuperFormsData[i];

                    aV[i].receivedSingleVaultData = abi.decode(
                        aV[i].data.params,
                        (InitSingleVaultData)
                    );

                    assertEq(
                        aV[i].expectedSingleVaultData.superFormId,
                        aV[i].receivedSingleVaultData.superFormId
                    );

                    assertEq(
                        aV[i].expectedSingleVaultData.amount,
                        aV[i].receivedSingleVaultData.amount
                    );
                }
            }
            //vm.selectFork(aV.initialFork);
        }
        return aV;
    }

    /// @dev STEP 4 Update state and process src to dst payload
    function _stage4_process_src_dst_payload(
        TestAction memory action,
        StagesLocalVars memory vars,
        MessagingAssertVars[] memory aV,
        SingleVaultSFData[] memory singleSuperFormsData,
        uint256 actionIndex
    ) internal returns (bool success) {
        /// assume it will pass by default
        success = true;
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            aV[i].toChainId = DST_CHAINS[i];
            if (CHAIN_0 != aV[i].toChainId) {
                if (
                    action.action == Actions.Deposit ||
                    action.action == Actions.DepositPermit2
                ) {
                    unchecked {
                        PAYLOAD_ID[aV[i].toChainId]++;
                    }

                    vars.multiVaultsPayloadArg = UpdateMultiVaultPayloadArgs(
                        PAYLOAD_ID[aV[i].toChainId],
                        aV[i].receivedMultiVaultData.amounts,
                        action.slippage,
                        aV[i].toChainId,
                        action.testType,
                        action.revertError,
                        action.revertRole
                    );

                    vars.singleVaultsPayloadArg = UpdateSingleVaultPayloadArgs(
                        PAYLOAD_ID[aV[i].toChainId],
                        aV[i].receivedSingleVaultData.amount,
                        action.slippage,
                        aV[i].toChainId,
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
                                    aV[i].toChainId,
                                    vars.underlyingSrcToken,
                                    vars.amounts
                                );
                            } else {
                                _processMultiTx(
                                    aV[i].toChainId,
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
                        success = _processPayload(
                            PAYLOAD_ID[aV[i].toChainId],
                            aV[i].toChainId,
                            action.testType,
                            action.revertError
                        );

                        vars.logs = vm.getRecordedLogs();

                        LayerZeroHelper(
                            getContract(aV[i].toChainId, "LayerZeroHelper")
                        ).helpWithEstimates(
                                vars.lzEndpoint_0,
                                1000000, /// (change to 2000000) @dev This is the gas value to send - value needs to be tested and probably be lower
                                FORKS[CHAIN_0],
                                vars.logs
                            );

                        HyperlaneHelper(
                            getContract(aV[i].toChainId, "HyperlaneHelper")
                        ).help(
                                address(HyperlaneMailbox),
                                address(HyperlaneMailbox),
                                FORKS[CHAIN_0],
                                vars.logs
                            );
                    } else if (
                        action.testType == TestType.RevertProcessPayload
                    ) {
                        success = _processPayload(
                            PAYLOAD_ID[aV[i].toChainId],
                            aV[i].toChainId,
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
                        PAYLOAD_ID[aV[i].toChainId]++;
                    }
                    _processPayload(
                        PAYLOAD_ID[aV[i].toChainId],
                        aV[i].toChainId,
                        action.testType,
                        action.revertError
                    );
                }
            }
            vm.selectFork(aV[i].initialFork);
        }
    }

    /// @dev STEP 5 Process dst to src payload (mint of SuperPositions for deposits)
    function _stage5_process_superPositions_mint(
        TestAction memory action,
        StagesLocalVars memory vars
    ) internal returns (bool success) {
        /// assume it will pass by default
        success = true;
        uint256 toChainId;
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            toChainId = DST_CHAINS[i];

            if (CHAIN_0 != toChainId) {
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
            if (
                args.action == Actions.Deposit ||
                args.action == Actions.DepositPermit2
            ) {
                superFormData = _buildSingleVaultDepositCallData(
                    callDataArgs,
                    args.action
                );
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
                vm.prank(users[args.user]);

                if (args.action == Actions.DepositPermit2) {
                    MockERC20(args.underlyingTokens[i]).approve(
                        getContract(args.srcChainId, "CanonicalPermit2"),
                        type(uint256).max
                    );
                } else if (args.action == Actions.Deposit) {
                    MockERC20(args.underlyingTokens[i]).approve(
                        from,
                        totalAmount
                    );
                }

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
        SingleVaultCallDataArgs memory args,
        Actions action
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

        /// @dev permit2 calldata
        IPermit2.PermitTransferFrom memory permit;
        bytes memory sig;
        bytes memory permit2Calldata;
        if (action == Actions.DepositPermit2) {
            permit = IPermit2.PermitTransferFrom({
                permitted: IPermit2.TokenPermissions({
                    token: IERC20(address(args.underlyingToken)),
                    amount: args.sameUnderlyingCheck != address(0)
                        ? args.totalAmount
                        : args.amount
                }),
                nonce: _randomUint256(),
                deadline: block.timestamp
            });
            sig = _signPermit(
                permit,
                from,
                userKeys[args.user],
                args.srcChainId
            ); /// @dev from is either SuperRouter (xchain) or the form (direct deposit)

            permit2Calldata = abi.encode(permit.nonce, permit.deadline, sig);
        }

        /// @dev FIXME: currently only producing liqRequests for non-permit2 ERC20 transfers!!!
        /// @dev TODO: need to test native requests and permit2 requests
        LiqRequest memory liqReq = LiqRequest(
            1, /// @dev FIXME: hardcoded for now
            socketTxData,
            args.underlyingToken,
            true,
            args.sameUnderlyingCheck != address(0)
                ? args.totalAmount
                : args.amount,
            0,
            permit2Calldata /// @dev will be empty if action == Actions.Deposit
        );

        if (args.sameUnderlyingCheck == address(0)) {
            vm.selectFork(FORKS[args.srcChainId]);

            /// @dev - APPROVE transfer to SuperRouter (because of Socket)
            vm.prank(users[args.user]);

            if (action == Actions.DepositPermit2) {
                MockERC20(args.underlyingToken).approve(
                    getContract(args.srcChainId, "CanonicalPermit2"),
                    type(uint256).max
                );
            } else {
                MockERC20(args.underlyingToken).approve(from, args.amount);
            }

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
            true,
            args.amount,
            0,
            ""
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
