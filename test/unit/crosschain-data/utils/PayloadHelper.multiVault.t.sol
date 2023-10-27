/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

/// Interfaces
import { IPayloadHelper } from "src/interfaces/IPayloadHelper.sol";
import { IPaymentHelper } from "src/interfaces/IPaymentHelper.sol";
import { DataLib } from "src/libraries/DataLib.sol";

// Test Utils
import "test/utils/ProtocolActions.sol";

contract PayloadHelperMultiTest is ProtocolActions {
    /// @dev Access SuperformRouter interface
    using DataLib for uint256;

    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        /// @dev singleDestinationSingleVault Deposit test case
        AMBs = [1, 2];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY];

        TARGET_UNDERLYINGS[POLY][0] = [0, 0];
        TARGET_UNDERLYINGS[POLY][1] = [0, 0];

        TARGET_VAULTS[POLY][0] = [0, 0];
        TARGET_VAULTS[POLY][1] = [0, 0];

        TARGET_FORM_KINDS[POLY][0] = [0, 0];
        TARGET_FORM_KINDS[POLY][1] = [0, 0];

        AMOUNTS[POLY][0] = [23_183, 213];
        // AMOUNTS[POLY][1] = [23_183, 213];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[POLY][0] = [1, 1];
        LIQ_BRIDGES[POLY][1] = [1, 1];

        FINAL_LIQ_DST_WITHDRAW[POLY] = [OP, OP];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: true,
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
                multiVaults: true,
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

    function test_payloadHelperMulti() public {
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

                    AMOUNTS[DST_CHAINS[i]][1] = [superPositions[0] / 2, superPositions[0] / 2];
                }
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }

        _checkSrcPayload();

        vm.selectFork(FORKS[POLY]);
        (, int256 USDPerDAIonPOLY,,,) =
            AggregatorV3Interface(tokenPriceFeeds[POLY][getContract(POLY, "DAI")]).latestRoundData();

        vm.selectFork(FORKS[OP]);
        (, int256 USDPerETHonOP,,,) = AggregatorV3Interface(tokenPriceFeeds[OP][NATIVE_TOKEN]).latestRoundData();
        (, int256 USDPerDAIonOP,,,) =
            AggregatorV3Interface(tokenPriceFeeds[OP][getContract(OP, "DAI")]).latestRoundData();
        _checkDstPayloadInit(uint256(USDPerDAIonPOLY), uint256(USDPerETHonOP), uint256(USDPerDAIonOP));

        _checkDstPayloadReturn();
    }

    function test_payloadHelperLiqMulti() public {
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

                    AMOUNTS[DST_CHAINS[i]][1] = [superPositions[0] / 2, superPositions[0] / 2];
                }
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }

        _checkDstPayloadLiqData();
    }

    function _checkSrcPayload() internal {
        vm.selectFork(FORKS[CHAIN_0]);

        address _PayloadHelper = contracts[CHAIN_0][bytes32(bytes("PayloadHelper"))];
        IPayloadHelper helper = IPayloadHelper(_PayloadHelper);

        (uint8 txType, uint8 callbackType, uint8 multi, address srcSender, uint64 srcChainId) =
            helper.decodePayloadHistory(1);

        assertEq(txType, 0);

        /// 0 for deposit
        assertEq(callbackType, 0);
        /// 0 for init
        assertEq(srcChainId, 10);
        /// chain id of optimism is 10
        assertEq(multi, 1);
        /// 0 for not multi vault
        assertEq(srcSender, users[0]);
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
        uint256 srcPayloadId;
    }

    function _checkDstPayloadInit(uint256 USDPerDAIonPOLY_, uint256 USDPerETHonOP_, uint256 USDPerDAIonOP_) internal {
        vm.selectFork(FORKS[DST_CHAINS[0]]);
        CheckDstPayloadInternalVars memory v;

        (v.txType, v.callbackType, v.srcSender, v.srcChainId, v.amounts, v.slippage,, v.srcPayloadId) =
            IPayloadHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))]).decodeCoreStateRegistryPayload(1);

        v.extraDataGenerated = new bytes[](2);
        v.extraDataGenerated[0] = abi.encode("500000");
        v.extraDataGenerated[1] = abi.encode("0");

        assertEq(v.txType, 0);

        /// 0 for deposit
        assertEq(v.callbackType, 0);
        /// 0 for init
        assertEq(v.srcChainId, 10);
        /// chain id of optimism is 10
        assertEq(v.srcPayloadId, 1);

        for (uint256 i; i < v.amounts.length; i++) {
            /// @dev ETH<>DAI swap on OP
            uint256 daiAfterFirstSwap = (AMOUNTS[POLY][0][i] * USDPerETHonOP_) / USDPerDAIonOP_;
            /// @dev DAI on OP <> DAI on POLY
            uint256 daiAfterSecondSwap = (daiAfterFirstSwap * USDPerDAIonOP_) / USDPerDAIonPOLY_;
            /// @dev daiAfterSecondSwap doesn't include bridge slippage hence should be greater
            assertLe(v.amounts[i], daiAfterSecondSwap);
        }

        for (uint256 i = 0; i < v.slippage.length; ++i) {
            assertEq(v.slippage[i], MAX_SLIPPAGE);
        }

        /// @notice: just asserting if fees are greater than 0
        /// no way to write serious tests on forked testnet at this point. should come back to this later on.
        (v.ambFees,) = IPaymentHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PaymentHelper"))]).estimateAMBFees(
            AMBs, DST_CHAINS[0], abi.encode(1), v.extraDataGenerated
        );
        assertGe(v.ambFees, 0);
    }

    struct CheckDstPayloadLiqDataInternalVars {
        uint8[] bridgeIds;
        bytes[] txDatas;
        address[] tokens;
        uint64[] liqDstChainIds;
        uint256[] amounts;
        uint256[] nativeAmounts;
        bool[] hasDstSwaps;
        address dstRefundAddress;
    }

    function _checkDstPayloadLiqData() internal {
        vm.selectFork(FORKS[DST_CHAINS[0]]);
        CheckDstPayloadLiqDataInternalVars memory v;

        (
            v.bridgeIds,
            v.txDatas,
            v.tokens,
            v.liqDstChainIds,
            v.amounts,
            v.nativeAmounts,
            v.hasDstSwaps,
            v.dstRefundAddress
        ) = IPayloadHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))])
            .decodeCoreStateRegistryPayloadLiqData(2);

        assertEq(v.bridgeIds[0], 1);

        assertGt(v.txDatas[0].length, 0);

        assertEq(v.tokens[0], getContract(DST_CHAINS[0], UNDERLYING_TOKENS[TARGET_UNDERLYINGS[POLY][1][0]]));

        assertEq(v.liqDstChainIds[0], FINAL_LIQ_DST_WITHDRAW[POLY][0]);

        /// @dev number of superpositions to burn in withdraws are not meant to be same as deposit amounts

        assertEq(v.amounts, actualAmountWithdrawnPerDst[0]);

        assertEq(v.dstRefundAddress, users[0]);

        assertEq(v.hasDstSwaps[0], false);
    }

    function _checkDstPayloadReturn() internal {
        vm.selectFork(FORKS[CHAIN_0]);

        CheckDstPayloadInternalVars memory v;

        (v.txType, v.callbackType,, v.srcChainId, v.amounts, v.slippage,, v.srcPayloadId) =
            IPayloadHelper(contracts[CHAIN_0][bytes32(bytes("PayloadHelper"))]).decodeCoreStateRegistryPayload(1);

        assertEq(v.txType, 0);

        /// 0 for deposit
        assertEq(v.callbackType, 1);
        /// 1 for return
        assertEq(v.srcChainId, 137);
        /// chain id of polygon is 137
        assertEq(v.srcPayloadId, 1);

        for (uint256 i = 0; i < v.slippage.length; ++i) {
            assertLe(v.amounts[i], AMOUNTS[POLY][0][i]);
            assertEq(v.slippage[i], MAX_SLIPPAGE);
        }
    }
}
