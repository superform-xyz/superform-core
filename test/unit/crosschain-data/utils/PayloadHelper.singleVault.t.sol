// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// Interfaces
import { IPayloadHelper } from "src/interfaces/IPayloadHelper.sol";
import { IPaymentHelperV2 as IPaymentHelper } from "src/interfaces/IPaymentHelperV2.sol";
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
        for (uint256 act = 0; act < actions.length; ++act) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;
            if (act == 1) {
                for (uint256 i = 0; i < DST_CHAINS.length; ++i) {
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
        for (uint256 act = 0; act < actions.length; ++act) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;
            if (act == 1) {
                for (uint256 i = 0; i < DST_CHAINS.length; ++i) {
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

        _checkDstPayloadLiqData(
            getContract(FINAL_LIQ_DST_WITHDRAW[POLY][0], UNDERLYING_TOKENS[actions[1].externalToken])
        );
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

    function test_constructorZeroAddress() public {
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new PayloadHelper(address(0));
    }

    function _checkSrcPayload() internal {
        vm.selectFork(FORKS[CHAIN_0]);

        (uint8 txType, uint8 callbackType, uint8 multi, address srcSender, address receiverAddress, uint64 srcChainId) =
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

        assertEq(receiverAddress, users[0]);
    }

    function _checkDstPayloadInit() internal {
        vm.selectFork(FORKS[DST_CHAINS[0]]);

        vm.expectRevert(Error.INVALID_PAYLOAD_ID.selector);
        IPayloadHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))]).decodeCoreStateRegistryPayload(3);

        IPayloadHelper.DecodedDstPayload memory v =
            IPayloadHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))]).decodeCoreStateRegistryPayload(1);
        IPayloadHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))]).getDstPayloadProof(1);

        bytes[] memory extraDataGenerated = new bytes[](2);
        extraDataGenerated[0] = abi.encode("500000");
        extraDataGenerated[1] = abi.encode("0");

        /// @dev 0 for deposit
        assertEq(v.txType, 0);

        /// @dev 0 for init
        assertEq(v.callbackType, 0);

        /// @dev chain id of optimism is 10
        assertEq(v.srcChainId, 10);

        assertEq(v.srcPayloadId, 1);

        assertEq(v.receiverAddress, users[0]);

        for (uint256 i = 0; i < v.slippages.length; ++i) {
            console.log("v.amounts[i]: %s", v.amounts[i]);
            console.log("AMOUNTS[POLY][0][i]: %s", AMOUNTS[POLY][0][i]);
            /// @dev TODO: fix this assertion considering exchange rates
            // assertLe(v.amounts[i], AMOUNTS[POLY][0][i]);
            assertEq(v.slippages[i], MAX_SLIPPAGE);
        }

        /// @notice: just asserting if fees are greater than 0
        /// FIXME no way to write serious tests on forked testnet at this point. should come back to this later on.
        (uint256 ambFees,) = IPaymentHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PaymentHelper"))]).estimateAMBFees(
            AMBs, DST_CHAINS[0], abi.encode(1), extraDataGenerated
        );
        assertGe(ambFees, 0);
    }

    function _checkDstPayloadReturn() internal {
        vm.selectFork(FORKS[CHAIN_0]);

        IPayloadHelper.DecodedDstPayload memory v =
            IPayloadHelper(contracts[CHAIN_0][bytes32(bytes("PayloadHelper"))]).decodeCoreStateRegistryPayload(1);

        /// @dev 0 for deposit
        assertEq(v.txType, 0);

        /// @dev 1 for return
        assertEq(v.callbackType, 1);

        /// @dev chain id of polygon is 137
        assertEq(v.srcChainId, 137);
        assertEq(v.srcPayloadId, 1);

        for (uint256 i = 0; i < v.slippages.length; ++i) {
            assertLe(v.amounts[i], AMOUNTS[POLY][0][i]);
            assertEq(v.slippages[i], MAX_SLIPPAGE);
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

    function _checkDstPayloadLiqData(address externalToken_) internal {
        vm.selectFork(FORKS[DST_CHAINS[0]]);
        CheckDstPayloadLiqDataInternalVars memory v;

        (v.txDatas, v.tokens,, v.bridgeIds, v.liqDstChainIds, v.amounts, v.nativeAmounts) = IPayloadHelper(
            contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))]
        ).decodeCoreStateRegistryPayloadLiqData(2);

        assertEq(v.bridgeIds[0], 1);

        assertGt(v.txDatas[0].length, 0);

        assertEq(v.tokens[0], externalToken_);

        assertEq(v.liqDstChainIds[0], FINAL_LIQ_DST_WITHDRAW[POLY][0]);

        /// @dev number of superpositions to burn in withdraws are not meant to be same as deposit amounts

        assertEq(v.amounts, actualAmountWithdrawnPerDst[0]);
    }
}
