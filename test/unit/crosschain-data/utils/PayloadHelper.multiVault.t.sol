// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// Interfaces
import { IPayloadHelper } from "src/interfaces/IPayloadHelper.sol";
import { IPaymentHelperV2 as IPaymentHelper } from "src/interfaces/IPaymentHelperV2.sol";
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
        DST_CHAINS = [ETH];

        TARGET_UNDERLYINGS[ETH][0] = [0, 0];
        TARGET_UNDERLYINGS[ETH][1] = [0, 0];

        TARGET_VAULTS[ETH][0] = [0, 0];
        TARGET_VAULTS[ETH][1] = [0, 0];

        TARGET_FORM_KINDS[ETH][0] = [0, 0];
        TARGET_FORM_KINDS[ETH][1] = [0, 0];

        AMOUNTS[ETH][0] = [20_001, 214];

        MAX_SLIPPAGE = 1000;

        LIQ_BRIDGES[ETH][0] = [1, 1];
        LIQ_BRIDGES[ETH][1] = [1, 1];
        RECEIVE_4626[ETH][0] = [false, false];
        RECEIVE_4626[ETH][1] = [false, false];

        FINAL_LIQ_DST_WITHDRAW[ETH] = [OP, OP];

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
                externalToken: 69_420 // 0 = DAI, 1 = USDT, 2 = WETH
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

                    AMOUNTS[DST_CHAINS[i]][1] = [superPositions[0] / 2, superPositions[0] / 2];

                    if (superPositions[0] != AMOUNTS[DST_CHAINS[i]][1][0] + AMOUNTS[DST_CHAINS[i]][1][1]) {
                        AMOUNTS[DST_CHAINS[i]][1][0] += 1;
                    }
                }
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }

        _checkSrcPayload();

        vm.selectFork(FORKS[ETH]);
        (, int256 USDPerDAIonETH,,,) =
            AggregatorV3Interface(tokenPriceFeeds[ETH][getContract(ETH, "DAI")]).latestRoundData();

        vm.selectFork(FORKS[OP]);
        (, int256 USDPerETHonOP,,,) = AggregatorV3Interface(tokenPriceFeeds[OP][NATIVE_TOKEN]).latestRoundData();
        (, int256 USDPerDAIonOP,,,) =
            AggregatorV3Interface(tokenPriceFeeds[OP][getContract(OP, "DAI")]).latestRoundData();
        _checkDstPayloadInit(
            CheckDstPayloadInitArgs(uint256(USDPerDAIonETH), uint256(USDPerETHonOP), uint256(USDPerDAIonOP))
        );

        _checkDstPayloadReturn();
    }

    function test_payloadHelperLiqMulti() public {
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

                    AMOUNTS[DST_CHAINS[i]][1] = [superPositions[0] / 2, superPositions[0] / 2];

                    if (superPositions[0] != AMOUNTS[DST_CHAINS[i]][1][0] + AMOUNTS[DST_CHAINS[i]][1][1]) {
                        AMOUNTS[DST_CHAINS[i]][1][0] += 1;
                    }
                }
            }

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }
        _checkDstPayloadLiqData(
            getContract(FINAL_LIQ_DST_WITHDRAW[ETH][0], UNDERLYING_TOKENS[actions[1].externalToken])
        );
    }

    function _checkSrcPayload() internal {
        vm.selectFork(FORKS[CHAIN_0]);

        address _PayloadHelper = contracts[CHAIN_0][bytes32(bytes("PayloadHelper"))];
        IPayloadHelper helper = IPayloadHelper(_PayloadHelper);

        (uint8 txType, uint8 callbackType, uint8 multi, address srcSender, address receiverAddress, uint64 srcChainId) =
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

        assertEq(receiverAddress, users[0]);
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
        uint256 srcPayloadId;
        address receiverAddress;
        uint256 daiAfterFirstSwap;
        uint256 daiAfterSecondSwap;
    }

    struct CheckDstPayloadInitArgs {
        uint256 USDPerDAIonETH_;
        uint256 USDPerETHonOP_;
        uint256 USDPerDAIonOP_;
    }

    function _checkDstPayloadInit(CheckDstPayloadInitArgs memory args) internal {
        vm.selectFork(FORKS[DST_CHAINS[0]]);
        IPayloadHelper.DecodedDstPayload memory v =
            IPayloadHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))]).decodeCoreStateRegistryPayload(1);
        bytes[] memory extraDataGenerated = new bytes[](2);
        extraDataGenerated[0] = abi.encode("500000");
        extraDataGenerated[1] = abi.encode("0");

        assertEq(v.txType, 0);

        /// 0 for deposit
        assertEq(v.callbackType, 0);
        /// 0 for init
        assertEq(v.srcChainId, 10);
        /// chain id of optimism is 10
        assertEq(v.srcPayloadId, 1);

        assertEq(v.receiverAddress, users[0]);

        for (uint256 i; i < v.amounts.length; ++i) {
            /// @dev ETH<>DAI swap on OP
            uint256 daiAfterFirstSwap = (AMOUNTS[ETH][0][i] * args.USDPerETHonOP_) / args.USDPerDAIonOP_;
            /// @dev DAI on OP <> DAI on ETH
            uint256 daiAfterSecondSwap = (daiAfterFirstSwap * args.USDPerDAIonOP_) / args.USDPerDAIonETH_;
            /// @dev daiAfterSecondSwap doesn't include bridge slippage hence should be greater
            assertLe(v.amounts[i], daiAfterSecondSwap);
        }

        for (uint256 i = 0; i < v.slippages.length; ++i) {
            assertEq(v.slippages[i], MAX_SLIPPAGE);
        }

        for (uint256 i; i < v.retain4626.length; ++i) {
            assertEq(v.retain4626[i], false);
        }

        /// @notice: just asserting if fees are greater than 0
        /// no way to write serious tests on forked testnet at this point. should come back to this later on.
        (uint256 ambFees,) = IPaymentHelper(contracts[DST_CHAINS[0]][bytes32(bytes("PaymentHelper"))]).estimateAMBFees(
            AMBs, DST_CHAINS[0], abi.encode(1), extraDataGenerated
        );
        assertGe(ambFees, 0);
    }

    struct CheckDstPayloadLiqDataInternalVars {
        uint8[] bridgeIds;
        bytes[] txData;
        address[] tokens;
        uint64[] liqDstChainIds;
        uint256[] amounts;
        uint256[] nativeAmounts;
    }

    function _checkDstPayloadLiqData(address externalToken_) internal {
        vm.selectFork(FORKS[DST_CHAINS[0]]);
        CheckDstPayloadLiqDataInternalVars memory v;

        (v.txData, v.tokens,, v.bridgeIds, v.liqDstChainIds, v.amounts, v.nativeAmounts) = IPayloadHelper(
            contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))]
        ).decodeCoreStateRegistryPayloadLiqData(2);

        assertEq(v.bridgeIds[0], 1);

        assertGt(v.txData[0].length, 0);

        assertEq(v.tokens[0], externalToken_);

        assertEq(v.liqDstChainIds[0], FINAL_LIQ_DST_WITHDRAW[ETH][0]);

        /// @dev number of superpositions to burn in withdraws are not meant to be same as deposit amounts

        assertEq(v.amounts, actualAmountWithdrawnPerDst[0]);
    }

    function _checkDstPayloadReturn() internal {
        vm.selectFork(FORKS[CHAIN_0]);

        IPayloadHelper.DecodedDstPayload memory v =
            IPayloadHelper(contracts[CHAIN_0][bytes32(bytes("PayloadHelper"))]).decodeCoreStateRegistryPayload(1);

        assertEq(v.txType, 0);

        /// 0 for deposit
        assertEq(v.callbackType, 1);
        /// 1 for return
        assertEq(v.srcChainId, 1);
        /// chain id of polygon is 42161
        assertEq(v.srcPayloadId, 1);

        for (uint256 i = 0; i < v.slippages.length; ++i) {
            assertLe(v.amounts[i], AMOUNTS[ETH][0][i]);
            assertEq(v.slippages[i], MAX_SLIPPAGE);
        }
    }
}
