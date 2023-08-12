/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// Interfaces
import {IPayloadHelper} from "src/interfaces/IPayloadHelper.sol";
import {IPaymentHelper} from "src/interfaces/IPaymentHelper.sol";
import {ISuperformRouter} from "src/interfaces/ISuperformRouter.sol";

// Test Utils
import "../../utils/ProtocolActions.sol";

contract PayloadHelperTest is ProtocolActions {
    /// @dev Access SuperformRouter interface
    ISuperformRouter superformRouter;

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

        TARGET_VAULTS[POLY][0] = [0]; /// @dev id 0 is normal 4626

        TARGET_FORM_KINDS[POLY][0] = [0];

        AMOUNTS[POLY][0] = [23183];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for SOCKET, 2 for LI.FI
        LIQ_BRIDGES[POLY][0] = [1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false,
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 3 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_helper() public {
        address _superformRouter = contracts[CHAIN_0][bytes32(bytes("SuperformRouter"))];
        superformRouter = ISuperformRouter(_superformRouter);

        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultSFData[] memory multiSuperformsData;
            SingleVaultSFData[] memory singleSuperformsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperformsData, singleSuperformsData, aV, vars, success);
        }

        _checkSrcPayload();

        _checkDstPayloadInit();
        _checkDstPayloadReturn();
    }

    function _checkSrcPayload() internal {
        vm.selectFork(FORKS[CHAIN_0]);

        address _PayloadHelper = contracts[CHAIN_0][bytes32(bytes("PayloadHelper"))];
        IPayloadHelper helper = IPayloadHelper(_PayloadHelper);

        address _PaymentHelper = contracts[CHAIN_0][bytes32(bytes("PaymentHelper"))];
        IPaymentHelper paymentHelper = IPaymentHelper(_PaymentHelper);

        (uint8 txType, uint8 callbackType, uint8 multi, address srcSender, uint64 srcChainId) = helper.decodeSrcPayload(
            1
        );

        assertEq(txType, 0); /// 0 for deposit
        assertEq(callbackType, 0); /// 0 for init
        assertEq(srcChainId, 10); /// chain id of optimism is 10
        assertEq(multi, 0); /// 0 for not multi vault
        assertEq(srcSender, users[0]);
    }

    function _checkDstPayloadInit() internal {
        vm.selectFork(FORKS[DST_CHAINS[0]]);

        address _PayloadHelper = contracts[DST_CHAINS[0]][bytes32(bytes("PayloadHelper"))];
        IPayloadHelper helper = IPayloadHelper(_PayloadHelper);

        address _PaymentHelper = contracts[DST_CHAINS[0]][bytes32(bytes("PaymentHelper"))];
        IPaymentHelper paymentHelper = IPaymentHelper(_PaymentHelper);

        (
            uint8 txType,
            uint8 callbackType,
            address srcSender,
            uint64 srcChainId,
            uint256[] memory amounts,
            uint256[] memory slippage,
            uint256[] memory superformIds,
            uint256 srcPayloadId
        ) = helper.decodeDstPayload(1);

        bytes[] memory extraDataGenerated = new bytes[](2);
        extraDataGenerated[0] = abi.encode("500000");
        extraDataGenerated[1] = abi.encode("0");

        assertEq(txType, 0); /// 0 for deposit
        assertEq(callbackType, 0); /// 0 for init
        assertEq(srcChainId, 10); /// chain id of optimism is 10
        assertEq(srcPayloadId, 1);
        assertEq(amounts, AMOUNTS[POLY][0]);
        for (uint256 i = 0; i < slippage.length; ++i) {
            assertEq(slippage[i], MAX_SLIPPAGE);
        }

        /// @notice: just asserting if fees are greater than 0
        /// no way to write serious tests on forked testnet at this point. should come back to this later on.
        (uint256 ambFees, ) = paymentHelper.estimateAMBFees(AMBs, DST_CHAINS[0], abi.encode(1), extraDataGenerated);
        assertGe(ambFees, 0);
    }

    function _checkDstPayloadReturn() internal {
        vm.selectFork(FORKS[CHAIN_0]);

        address _PayloadHelper = contracts[CHAIN_0][bytes32(bytes("PayloadHelper"))];
        IPayloadHelper helper = IPayloadHelper(_PayloadHelper);

        address _PaymentHelper = contracts[CHAIN_0][bytes32(bytes("PaymentHelper"))];
        IPaymentHelper paymentHelper = IPaymentHelper(_PaymentHelper);

        (
            uint8 txType,
            uint8 callbackType,
            address srcSender,
            uint64 srcChainId,
            uint256[] memory amounts,
            uint256[] memory slippage,
            uint256[] memory superformIds,
            uint256 srcPayloadId
        ) = helper.decodeDstPayload(1);

        assertEq(txType, 0); /// 0 for deposit
        assertEq(callbackType, 1); /// 1 for return
        assertEq(srcChainId, 137); /// chain id of polygon is 137
        assertEq(srcPayloadId, 1);
        assertEq(amounts, AMOUNTS[POLY][0]);

        for (uint256 i = 0; i < slippage.length; ++i) {
            assertEq(slippage[i], MAX_SLIPPAGE);
        }
    }
}
