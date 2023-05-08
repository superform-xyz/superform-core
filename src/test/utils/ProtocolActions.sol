/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @dev lib imports
import "./BaseSetup.sol";
import "../../utils/DataPacking.sol";
import {IPermit2} from "../../interfaces/IPermit2.sol";
import {ISocketRegistry} from "../../interfaces/ISocketRegistry.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SocketRouterMock} from "../mocks/SocketRouterMock.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

abstract contract ProtocolActions is BaseSetup {
    uint8[] public AMBs;

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
            action.msgValue +
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
                        getContract(DST_CHAINS[i], "CoreStateRegistry")
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
                        getContract(
                            CHAIN_0,
                            UNDERLYING_TOKENS[action.externalToken]
                        ),
                        vars.toDst,
                        vars.underlyingSrcToken,
                        vars.targetSuperFormIds,
                        vars.amounts,
                        vars.maxSlippage,
                        vars.vaultMock,
                        CHAIN_0,
                        DST_CHAINS[i],
                        socketChainIds[CHAIN_0 - 1], /// @dev HACK to get socket src and dst chain ids
                        socketChainIds[DST_CHAINS[i] - 1],
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
                        getContract(
                            CHAIN_0,
                            UNDERLYING_TOKENS[action.externalToken]
                        ),
                        vars.toDst[0],
                        vars.underlyingSrcToken[0],
                        vars.targetSuperFormIds[0],
                        vars.amounts[0],
                        vars.maxSlippage[0],
                        vars.vaultMock[0],
                        CHAIN_0,
                        DST_CHAINS[i],
                        socketChainIds[CHAIN_0 - 1], /// @dev HACK to get socket src and dst chain ids
                        socketChainIds[DST_CHAINS[i] - 1],
                        action.multiTx,
                        vars.amounts[0], /// @dev copying amount to total amount for the externalToken hack in _buildSingleVaultDepositCallData
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
                        AMBs,
                        DST_CHAINS[0],
                        multiSuperFormsData[0],
                        action.ambParams[0]
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
                        AMBs,
                        DST_CHAINS,
                        multiSuperFormsData,
                        action.ambParams
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
                            AMBs,
                            DST_CHAINS[0],
                            singleSuperFormsData[0],
                            action.ambParams[0]
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
                            action.ambParams[0]
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
                        AMBs,
                        DST_CHAINS,
                        singleSuperFormsData,
                        action.ambParams
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
        uint64[] celerChainIds;
        address[] celerBusses;
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

        internalVars.celerBusses = new address[](vars.nDestinations);
        internalVars.celerChainIds = new uint64[](vars.nDestinations);

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

                    internalVars.celerChainIds[internalVars.k] = celer_chainIds[
                        i
                    ];
                    internalVars.celerBusses[
                        internalVars.k
                    ] = celerMessageBusses[i];

                    internalVars.forkIds[internalVars.k] = FORKS[chainIds[i]];

                    internalVars.k++;
                }
            }
        }
        vars.logs = vm.getRecordedLogs();

        for (uint256 index; index < AMBs.length; index++) {
            if (AMBs[index] == 1) {
                LayerZeroHelper(getContract(CHAIN_0, "LayerZeroHelper")).help(
                    internalVars.endpoints,
                    internalVars.lzChainIds,
                    2500000, /// (change to 2000000) @dev FIXME: should be calculated automatically - This is the gas value to send - value needs to be tested and probably be lower
                    internalVars.forkIds,
                    vars.logs
                );
            }

            if (AMBs[index] == 2) {
                /// @dev see pigeon for this implementation
                HyperlaneHelper(getContract(CHAIN_0, "HyperlaneHelper")).help(
                    address(HyperlaneMailbox),
                    internalVars.toMailboxes,
                    internalVars.expDstDomains,
                    internalVars.forkIds,
                    vars.logs
                );
            }

            if (AMBs[index] == 3) {
                CelerHelper(getContract(CHAIN_0, "CelerHelper")).help(
                    CELER_CHAIN_IDS[CHAIN_0],
                    CELER_BUSSES[CHAIN_0],
                    internalVars.celerBusses,
                    internalVars.celerChainIds,
                    internalVars.forkIds,
                    vars.logs
                );
            }
        }

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
                            (, vars.underlyingSrcToken, ) = _targetVaults(
                                CHAIN_0,
                                DST_CHAINS[i],
                                actionIndex
                            );
                            if (action.multiVaults) {
                                vars.amounts = AMOUNTS[DST_CHAINS[i]][
                                    actionIndex
                                ];
                                _batchProcessMultiTx(
                                    CHAIN_0,
                                    aV[i].toChainId,
                                    socketChainIds[aV[i].toChainId - 1],
                                    vars.underlyingSrcToken,
                                    vars.amounts
                                );
                            } else {
                                _processMultiTx(
                                    CHAIN_0,
                                    aV[i].toChainId,
                                    socketChainIds[aV[i].toChainId - 1],
                                    vars.underlyingSrcToken[0],
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

                        _payloadDeliveryHelper(
                            CHAIN_0,
                            aV[i].toChainId,
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

                    vm.recordLogs();
                    /// note: this is high-lvl processPayload function, even if this happens outside of the user view
                    /// we need to manually process payloads by invoking sending actual messages
                    success = _processPayload(
                        PAYLOAD_ID[aV[i].toChainId],
                        aV[i].toChainId,
                        action.testType,
                        action.revertError
                    );

                    vars.logs = vm.getRecordedLogs();

                    _payloadDeliveryHelper(CHAIN_0, aV[i].toChainId, vars.logs);
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

    /// NOTE: For 2-way comms we need to now process payload on Source again
    function _stage6_process_superPositions_withdraw(
        TestAction memory action,
        StagesLocalVars memory vars
    ) internal returns (bool success) {
        /// assume it will pass by default
        success = true;

        unchecked {
            PAYLOAD_ID[CHAIN_0]++;
        }

        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[CHAIN_0]);

        _processPayload(
            PAYLOAD_ID[CHAIN_0],
            CHAIN_0,
            action.testType,
            action.revertError
        );
        vm.selectFork(initialFork);

        return true;
    }

    function _stage7_process_unlock_withdraw(
        TestAction memory action,
        StagesLocalVars memory vars
    ) internal returns (bool success) {
        vm.prank(deployer);
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
                args.externalToken,
                args.toDst[i],
                args.underlyingTokens[i],
                args.superFormIds[i],
                args.amounts[i],
                args.maxSlippage[i],
                args.vaultMock[i],
                args.srcChainId,
                args.toChainId,
                args.liquidityBridgeSrcChainId,
                args.liquidityBridgeToChainId,
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

                address liqRequestToken = args.externalToken !=
                    args.underlyingTokens[i]
                    ? args.externalToken
                    : args.underlyingTokens[i];

                vm.selectFork(FORKS[args.srcChainId]);

                /// @dev - APPROVE transfer to SuperRouter (because of Socket)
                vm.prank(users[args.user]);

                if (args.action == Actions.DepositPermit2) {
                    MockERC20(liqRequestToken).approve(
                        getContract(args.srcChainId, "CanonicalPermit2"),
                        type(uint256).max
                    );
                } else if (args.action == Actions.Deposit) {
                    MockERC20(liqRequestToken).increaseAllowance(
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

    function _buildSocketTxData(
        address externalToken_,
        address underlyingToken_,
        address from_,
        uint16 toChainId_,
        bool multiTx_,
        address toDst_,
        uint256 liqBridgeToChainId_,
        address sameUnderlyingCheck_,
        uint256 totalAmount_,
        uint256 amount_
    ) internal returns (bytes memory socketTxData) {
        ISocketRegistry.BridgeRequest memory bridgeRequest;
        ISocketRegistry.MiddlewareRequest memory middlewareRequest;
        ISocketRegistry.UserRequest memory userRequest;
        /// @dev middlware request is used if there is a swap involved before the bridging action
        /// @dev the input token should be the token the user deposits, which will be swapped to the input token of bridging request
        if (externalToken_ != underlyingToken_) {
            middlewareRequest = ISocketRegistry.MiddlewareRequest(
                1, /// request id
                0, /// FIXME optional native amount
                externalToken_,
                abi.encode(from_)
            );

            bridgeRequest = ISocketRegistry.BridgeRequest(
                1, /// request id
                0, /// FIXME optional native amount
                underlyingToken_,
                abi.encode(from_, FORKS[toChainId_])
            );
        } else {
            bridgeRequest = ISocketRegistry.BridgeRequest(
                1, /// request id
                0, /// FIXME optional native amount
                underlyingToken_,
                abi.encode(from_, FORKS[toChainId_])
            );
        }

        userRequest = ISocketRegistry.UserRequest(
            multiTx_ ? getContract(toChainId_, "MultiTxProcessor") : toDst_,
            liqBridgeToChainId_,
            sameUnderlyingCheck_ != address(0) ? totalAmount_ : amount_,
            middlewareRequest,
            bridgeRequest
        );

        socketTxData = abi.encodeWithSelector(
            SocketRouterMock.outboundTransferTo.selector,
            userRequest
        );
    }

    struct SingleVaultDepositLocalVars {
        uint256 initialFork;
        address from;
        IPermit2.PermitTransferFrom permit;
        bytes txData;
        bytes sig;
        bytes permit2Calldata;
        LiqRequest liqReq;
    }

    function _buildSingleVaultDepositCallData(
        SingleVaultCallDataArgs memory args,
        Actions action
    ) internal returns (SingleVaultSFData memory superFormData) {
        SingleVaultDepositLocalVars memory v;
        v.initialFork = vm.activeFork();

        v.from = args.fromSrc;

        if (args.srcChainId == args.toChainId) {
            /// @dev same chain deposit, from is Form
            v.from = args.toDst;
        }

        v.txData = _buildSocketTxData(
            args.externalToken,
            args.underlyingToken,
            v.from,
            args.toChainId,
            args.multiTx,
            args.toDst,
            args.liquidityBridgeToChainId,
            args.sameUnderlyingCheck,
            args.totalAmount,
            args.amount
        );

        address liqRequestToken = args.externalToken != args.underlyingToken
            ? args.externalToken
            : args.underlyingToken;

        /// @dev permit2 calldata
        if (action == Actions.DepositPermit2) {
            v.permit = IPermit2.PermitTransferFrom({
                permitted: IPermit2.TokenPermissions({
                    token: IERC20(address(liqRequestToken)),
                    amount: args.sameUnderlyingCheck != address(0)
                        ? args.totalAmount
                        : args.amount
                }),
                nonce: _randomUint256(),
                deadline: block.timestamp
            });
            v.sig = _signPermit(
                v.permit,
                v.from,
                userKeys[args.user],
                args.srcChainId
            ); /// @dev from is either SuperRouter (xchain) or the form (direct deposit)

            v.permit2Calldata = abi.encode(
                v.permit.nonce,
                v.permit.deadline,
                v.sig
            );
        }

        /// @dev FIXME: currently only producing liqRequests for non-permit2 ERC20 transfers!!!
        /// @dev TODO: need to test native requests and permit2 requests
        v.liqReq = LiqRequest(
            1, /// @dev FIXME: hardcoded for now - but this should be a different bridge per type of transaction
            v.txData,
            liqRequestToken,
            args.sameUnderlyingCheck != address(0)
                ? args.totalAmount
                : args.amount,
            0,
            v.permit2Calldata /// @dev will be empty if action == Actions.Deposit
        );

        /// @dev FIXME: we are using underlying token and not swapping it to a different token kind
        /// @dev FIXME: tests should have src / input token field (can we assume the same for all vaults and destinations?)
        if (args.sameUnderlyingCheck == address(0)) {
            vm.selectFork(FORKS[args.srcChainId]);

            /// @dev - APPROVE transfer to SuperRouter (because of Socket)
            vm.prank(users[args.user]);

            if (action == Actions.DepositPermit2) {
                MockERC20(liqRequestToken).approve(
                    getContract(args.srcChainId, "CanonicalPermit2"),
                    type(uint256).max
                );
            } else if (
                action == Actions.Deposit &&
                liqRequestToken != args.externalToken
            ) {
                /// @dev this assumes that if same underlying is present in >1 vault in a multi vault, that the amounts are ordered from lowest to highest,
                /// @dev this is because the approves override each other and may lead to Arithmetic over/underflow
                MockERC20(liqRequestToken).increaseAllowance(
                    v.from,
                    args.amount
                );
            } else if (
                action == Actions.Deposit &&
                liqRequestToken == args.externalToken
            ) {
                /// @dev this assumes that external token has a 1:1 exchange rate with underlying tokens
                /// @dev
                MockERC20(liqRequestToken).increaseAllowance(
                    v.from,
                    args.totalAmount
                );
            }

            vm.selectFork(v.initialFork);
        }

        superFormData = SingleVaultSFData(
            args.superFormId,
            args.amount,
            args.maxSlippage,
            v.liqReq,
            ""
        );
    }

    struct SingleVaultWithdrawLocalVars {
        ISocketRegistry.MiddlewareRequest middlewareRequest;
        ISocketRegistry.BridgeRequest bridgeRequest;
        address superRouter;
        address stateRegistry;
        IERC1155 superPositions;
        bytes txData;
        LiqRequest liqReq;
    }

    function _buildSingleVaultWithdrawCallData(
        SingleVaultCallDataArgs memory args
    ) internal returns (SingleVaultSFData memory superFormData) {
        SingleVaultWithdrawLocalVars memory vars;

        vars.superRouter = contracts[CHAIN_0][bytes32(bytes("SuperRouter"))];
        vars.stateRegistry = contracts[CHAIN_0][
            bytes32(bytes("SuperRegistry"))
        ];
        vars.superPositions = IERC1155(
            ISuperRegistry(vars.stateRegistry).superPositions()
        );
        vm.prank(users[args.user]);
        vars.superPositions.setApprovalForAll(vars.superRouter, true);

        vars.txData = _buildSocketTxData(
            args.underlyingToken,
            args.externalToken,
            args.toDst,
            args.srcChainId,
            false,
            users[args.user],
            args.liquidityBridgeSrcChainId,
            address(0),
            0,
            args.amount
        );

        vars.liqReq = LiqRequest(
            1, /// @dev FIXME: hardcoded for now
            vars.txData,
            args.underlyingToken,
            args.amount,
            0,
            ""
        );

        superFormData = SingleVaultSFData(
            args.superFormId,
            args.amount,
            args.maxSlippage,
            vars.liqReq,
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
        bytes4
    ) internal returns (bool) {
        uint256 initialFork = vm.activeFork();

        vm.selectFork(FORKS[targetChainId_]);
        uint256 msgValue = 240 * 1e18; /// @FIXME: try more accurate estimations

        vm.prank(deployer);
        if (testType == TestType.Pass) {
            CoreStateRegistry(
                payable(getContract(targetChainId_, "CoreStateRegistry"))
            ).processPayload{value: msgValue}(
                payloadId_,
                generateAckParams(AMBs)
            );
        } else if (testType == TestType.RevertProcessPayload) {
            vm.expectRevert();

            CoreStateRegistry(
                payable(getContract(targetChainId_, "CoreStateRegistry"))
            ).processPayload{value: msgValue}(
                payloadId_,
                generateAckParams(AMBs)
            );

            return false;
        }

        vm.selectFork(initialFork);
        return true;
    }

    /// @dev FIXME: only works for socket
    /// @dev - assumption to only use MultiTxProcessor for destination chain swaps (middleware requests)
    function _processMultiTx(
        uint16 srcChainId_,
        uint16 targetChainId_,
        uint256 liquidityBridgeDstChainId_,
        address underlyingToken_,
        uint256 amount_
    ) internal {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[targetChainId_]);

        vm.prank(deployer);

        ISocketRegistry.MiddlewareRequest memory middlewareRequest;
        ISocketRegistry.BridgeRequest memory bridgeRequest;

        middlewareRequest = ISocketRegistry.MiddlewareRequest(
            1, /// id
            0, /// FIXME optional native amount
            underlyingToken_,
            abi.encode(
                getContract(targetChainId_, "MultiTxProcessor"),
                FORKS[targetChainId_]
            )
        );
        /// @dev empty bridge request
        bridgeRequest = ISocketRegistry.BridgeRequest(
            0, /// id
            0, /// FIXME optional native amount
            address(0),
            abi.encode(
                getContract(targetChainId_, "MultiTxProcessor"),
                FORKS[targetChainId_]
            )
        );

        ISocketRegistry.UserRequest memory userRequest = ISocketRegistry
            .UserRequest(
                getContract(targetChainId_, "CoreStateRegistry"),
                liquidityBridgeDstChainId_,
                amount_,
                middlewareRequest,
                bridgeRequest
            );

        bytes memory socketTxDataV2 = abi.encodeWithSelector(
            SocketRouterMock.outboundTransferTo.selector,
            userRequest
        );

        MultiTxProcessor(
            payable(getContract(targetChainId_, "MultiTxProcessor"))
        ).processTx(bridgeIds[0], socketTxDataV2, underlyingToken_, amount_);
        vm.selectFork(initialFork);
    }

    function _batchProcessMultiTx(
        uint16 srcChainId_,
        uint16 targetChainId_,
        uint256 liquidityBridgeDstChainId_,
        address[] memory underlyingTokens_,
        uint256[] memory amounts_
    ) internal {
        uint256 initialFork = vm.activeFork();
        vm.selectFork(FORKS[targetChainId_]);

        vm.prank(deployer);

        ISocketRegistry.MiddlewareRequest memory middlewareRequest;
        ISocketRegistry.BridgeRequest memory bridgeRequest;
        bytes[] memory socketTxDatasV2 = new bytes[](underlyingTokens_.length);

        for (uint256 i = 0; i < underlyingTokens_.length; i++) {
            middlewareRequest = ISocketRegistry.MiddlewareRequest(
                1, /// id
                0, /// FIXME optional native amount
                underlyingTokens_[i],
                abi.encode( /// @dev this abi.encode is only used for the mock purposes
                    getContract(targetChainId_, "MultiTxProcessor"),
                    FORKS[targetChainId_]
                )
            );
            bridgeRequest = ISocketRegistry.BridgeRequest(
                0, /// id
                0, /// FIXME optional native amount
                address(0),
                abi.encode( /// @dev this abi.encode is only used for the mock purposes
                    getContract(targetChainId_, "MultiTxProcessor"),
                    FORKS[targetChainId_]
                )
            );

            ISocketRegistry.UserRequest memory userRequest = ISocketRegistry
                .UserRequest(
                    getContract(targetChainId_, "CoreStateRegistry"),
                    liquidityBridgeDstChainId_,
                    amounts_[i],
                    middlewareRequest,
                    bridgeRequest
                );

            socketTxDatasV2[i] = abi.encodeWithSelector(
                SocketRouterMock.outboundTransferTo.selector,
                userRequest
            );
        }

        MultiTxProcessor(
            payable(getContract(targetChainId_, "MultiTxProcessor"))
        ).batchProcessTx(
                bridgeIds[0],
                socketTxDatasV2,
                underlyingTokens_,
                amounts_
            );
        vm.selectFork(initialFork);
    }

    function _payloadDeliveryHelper(
        uint16 FROM_CHAIN,
        uint16 TO_CHAIN,
        Vm.Log[] memory logs
    ) internal {
        for (uint256 i; i < AMBs.length; i++) {
            /// @notice ID: 1 Layerzero
            if (AMBs[i] == 1) {
                LayerZeroHelper(getContract(TO_CHAIN, "LayerZeroHelper"))
                    .helpWithEstimates(
                        LZ_ENDPOINTS[FROM_CHAIN],
                        1000000, /// (change to 2000000) @dev This is the gas value to send - value needs to be tested and probably be lower
                        FORKS[FROM_CHAIN],
                        logs
                    );
            }

            /// @notice ID: 2 Hyperlane
            if (AMBs[i] == 2) {
                HyperlaneHelper(getContract(TO_CHAIN, "HyperlaneHelper")).help(
                    address(HyperlaneMailbox),
                    address(HyperlaneMailbox),
                    FORKS[FROM_CHAIN],
                    logs
                );
            }

            /// @notice ID: 3 Celer
            if (AMBs[i] == 3) {
                CelerHelper(getContract(TO_CHAIN, "CelerHelper")).help(
                    CELER_CHAIN_IDS[TO_CHAIN],
                    CELER_BUSSES[TO_CHAIN],
                    CELER_BUSSES[FROM_CHAIN],
                    CELER_CHAIN_IDS[FROM_CHAIN],
                    FORKS[FROM_CHAIN],
                    logs
                );
            }
        }
    }
}
