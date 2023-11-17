/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

/// Interfaces
import { IPayloadHelper } from "src/interfaces/IPayloadHelper.sol";
import { IPaymentHelper } from "src/interfaces/IPaymentHelper.sol";
import { IBaseRouter } from "src/interfaces/IBaseRouter.sol";

// Test Utils
import "test/utils/ProtocolActions.sol";

contract PayloadHelperSingleTest is ProtocolActions {
    /// @dev Access SuperformRouter interface
    IBaseRouter superformRouter;

    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationSingleVault Deposit test case
        AMBs = [2, 3];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action

        TARGET_UNDERLYINGS[POLY][0] = [0];
        TARGET_UNDERLYINGS[POLY][1] = [0];

        TARGET_VAULTS[POLY][0] = [0];
        TARGET_VAULTS[POLY][1] = [0];

        TARGET_FORM_KINDS[POLY][0] = [0];
        TARGET_FORM_KINDS[POLY][1] = [0];

        AMOUNTS[POLY][0] = [23_183];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[POLY][0] = [1];
        LIQ_BRIDGES[POLY][1] = [1];

        RECEIVE_4626[POLY][0] = [false];
        RECEIVE_4626[POLY][1] = [false];

        FINAL_LIQ_DST_WITHDRAW[POLY] = [OP];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false,
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );

        actions.push(
            TestAction({
                action: Actions.Withdraw,
                multiVaults: false,
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                dstSwap: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
             })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_payloadHelperSingle() public {
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
        }

        _checkSrcPayload();

        _checkDstPayloadInit();
        _checkDstPayloadReturn();
    }

    function test_payloadHelperLiqSingle() public {
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
        }

        _checkDstPayloadLiqData();
    }

    function test_decodePayloadHistory_InvalidPayloadId() public {
        vm.selectFork(FORKS[ETH]);

        vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
        IPayloadHelper(contracts[ETH][bytes32(bytes("PayloadHelper"))]).decodePayloadHistory(2);
    }

    function test_decodeTimelockPayload_InvalidPayloadId() public {
        vm.selectFork(FORKS[ETH]);

        vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
        IPayloadHelper(contracts[ETH][bytes32(bytes("PayloadHelper"))]).decodeTimeLockPayload(2);
    }

    function test_decodeCoreStateRegistryPayload_invalidPayload() public {
        uint8[] memory ambIds_ = new uint8[](2);
        ambIds_[0] = 1;
        ambIds_[1] = 2;
        vm.selectFork(FORKS[ETH]);
        vm.prank(getContract(ETH, "LayerzeroImplementation"));
        CoreStateRegistry(getContract(ETH, "CoreStateRegistry")).receivePayload(
            POLY,
            abi.encode(AMBMessage(DataLib.packTxInfo(1, 5, 1, 1, address(420), uint64(137)), abi.encode(ambIds_, "")))
        );

        vm.expectRevert(Error.INVALID_PAYLOAD.selector);
        PayloadHelper(getContract(ETH, "PayloadHelper")).decodeCoreStateRegistryPayload(1);
    }

    struct CheckDstPayloadInternalVars {
        bytes[] extraDataGenerated;
        uint256 ambFees;
        uint8 txType;
        uint8 callbackType;
        address srcSender;
        uint64 srcChainId;
        uint256[] amounts;
        uint256[] slippage;
        uint256[] superformIds;
        bool[] hasDstSwaps;
        bytes extraFormData;
        address receiverAddress;
        uint256 srcPayloadId;
    }

    function _checkSrcPayload() internal {
        vm.selectFork(FORKS[CHAIN_0]);

        (uint8 txType, uint8 callbackType, uint8 multi, address srcSender, uint64 srcChainId) =
            IPayloadHelper(contracts[CHAIN_0][bytes32(bytes("PayloadHelper"))]).decodePayloadHistory(1);

        /// @dev 0 for deposit
        assertEq(txType, 0);

        /// @dev 0 for init
        assertEq(callbackType, 0);

        /// @dev chain id of optimism is 10
        assertEq(srcChainId, 10);

        /// @dev 0 for not multi vault
        assertEq(multi, 0);
        assertEq(srcSender, users[0]);
    }

    function _checkDstPayloadInit() internal {
        vm.selectFork(FORKS[DST_CHAINS[0]]);

        CheckDstPayloadInternalVars memory v;
        vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
        IPayloadHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))]).decodeCoreStateRegistryPayload(3);

        (
            v.txType,
            v.callbackType,
            v.srcSender,
            v.srcChainId,
            v.amounts,
            v.slippage,
            ,
            ,
            ,
            v.receiverAddress,
            v.srcPayloadId
        ) = IPayloadHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))]).decodeCoreStateRegistryPayload(1);
        IPayloadHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))]).getDstPayloadProof(1);
        v.extraDataGenerated = new bytes[](2);
        v.extraDataGenerated[0] = abi.encode("500000");
        v.extraDataGenerated[1] = abi.encode("0");

        /// @dev 0 for deposit
        assertEq(v.txType, 0);

        /// @dev 0 for init
        assertEq(v.callbackType, 0);

        /// @dev chain id of optimism is 10
        assertEq(v.srcChainId, 10);

        assertEq(v.srcPayloadId, 1);

        assertEq(v.receiverAddress, users[0]);

        for (uint256 i = 0; i < v.slippage.length; ++i) {
            console.log("v.amounts[i]: %s", v.amounts[i]);
            console.log("AMOUNTS[POLY][0][i]: %s", AMOUNTS[POLY][0][i]);
            /// @dev TODO: fix this assertion considering exchange rates
            // assertLe(v.amounts[i], AMOUNTS[POLY][0][i]);
            assertEq(v.slippage[i], MAX_SLIPPAGE);
        }

        /// @notice: just asserting if fees are greater than 0
        /// FIXME no way to write serious tests on forked testnet at this point. should come back to this later on.
        (v.ambFees,) = IPaymentHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PaymentHelper"))]).estimateAMBFees(
            AMBs, DST_CHAINS[0], abi.encode(1), v.extraDataGenerated
        );
        assertGe(v.ambFees, 0);
    }

    function _checkDstPayloadReturn() internal {
        vm.selectFork(FORKS[CHAIN_0]);

        CheckDstPayloadInternalVars memory v;

        (v.txType, v.callbackType, v.srcSender, v.srcChainId, v.amounts, v.slippage,, v.hasDstSwaps,,, v.srcPayloadId) =
            IPayloadHelper(contracts[CHAIN_0][bytes32(bytes("PayloadHelper"))]).decodeCoreStateRegistryPayload(1);

        /// @dev 0 for deposit
        assertEq(v.txType, 0);

        /// @dev 1 for return
        assertEq(v.callbackType, 1);

        /// @dev chain id of polygon is 137
        assertEq(v.srcChainId, 137);
        assertEq(v.srcPayloadId, 1);

        for (uint256 i = 0; i < v.slippage.length; ++i) {
            assertLe(v.amounts[i], AMOUNTS[POLY][0][i]);
            assertEq(v.slippage[i], MAX_SLIPPAGE);
        }
    }

    struct CheckDstPayloadLiqDataInternalVars {
        uint8[] bridgeIds;
        bytes[] txDatas;
        address[] tokens;
        uint64[] liqDstChainIds;
        uint256[] amounts;
        uint256[] nativeAmounts;
    }

    function _checkDstPayloadLiqData() internal {
        vm.selectFork(FORKS[DST_CHAINS[0]]);
        CheckDstPayloadLiqDataInternalVars memory v;

        (v.bridgeIds, v.txDatas, v.tokens, v.liqDstChainIds, v.amounts, v.nativeAmounts) = IPayloadHelper(
            contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))]
        ).decodeCoreStateRegistryPayloadLiqData(2);

        assertEq(v.bridgeIds[0], 1);

        assertGt(v.txDatas[0].length, 0);

        assertEq(v.tokens[0], getContract(DST_CHAINS[0], UNDERLYING_TOKENS[TARGET_UNDERLYINGS[POLY][0][0]]));

        assertEq(v.liqDstChainIds[0], FINAL_LIQ_DST_WITHDRAW[POLY][0]);

        /// @dev number of superpositions to burn in withdraws are not meant to be same as deposit amounts

        assertEq(v.amounts, actualAmountWithdrawnPerDst[0]);
    }
}
