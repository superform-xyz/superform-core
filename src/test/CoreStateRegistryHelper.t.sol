/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../types/LiquidityTypes.sol";
import "../types/DataTypes.sol";

/// Interfaces
import {ICoreStateRegistryHelper} from "../interfaces/ICoreStateRegistryHelper.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/ProtocolActions.sol";
import "./utils/AmbParams.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract CoreStateRegistryHelperTest is ProtocolActions {
    /// @dev Access SuperFormRouter interface
    ISuperFormRouter superRouter;

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

        MAX_SLIPPAGE[POLY][0] = [1000];

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[POLY][0] = [1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                timelocked: false,
                user: 0,
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                ambParams: generateAmbParams(DST_CHAINS.length, 2),
                msgValue: 50 * 10 ** 18,
                externalToken: 0 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_payload_helper() public {
        address _superRouter = contracts[CHAIN_0][bytes32(bytes("SuperFormRouter"))];
        superRouter = ISuperFormRouter(_superRouter);

        for (uint256 act = 0; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultsSFData[] memory multiSuperFormsData;
            SingleVaultSFData[] memory singleSuperFormsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;

            _runMainStages(action, act, multiSuperFormsData, singleSuperFormsData, aV, vars, success);
        }

        vm.selectFork(FORKS[DST_CHAINS[0]]);

        address _coreStateRegistryHelper = contracts[DST_CHAINS[0]][bytes32(bytes("CoreStateRegistryHelper"))];
        ICoreStateRegistryHelper helper = ICoreStateRegistryHelper(_coreStateRegistryHelper);

        (
            uint8 txType,
            uint8 callbackType,
            address srcSender,
            uint64 srcChainId,
            uint256[] memory amounts,
            uint256[] memory slippage,
            uint256[] memory superformIds,
            uint256 srcPayloadId
        ) = helper.decodePayload(1);

        bytes[] memory extraDataGenerated = new bytes[](2);
        extraDataGenerated[0] = abi.encode("500000");
        extraDataGenerated[1] = abi.encode("0");

        assertEq(txType, 0); /// 0 for deposit
        assertEq(callbackType, 0); /// 0 for init
        assertEq(srcChainId, 10); /// chain id of optimism is 10
        assertEq(srcPayloadId, 1);
        assertEq(amounts, AMOUNTS[POLY][0]);
        assertEq(slippage, MAX_SLIPPAGE[POLY][0] = [1000]);

        /// @notice: just asserting if fees are greater than 0
        /// no way to write serious tests on forked testnet at this point. should come back to this later on.
        (uint256 totalFees, ) = helper.estimateFees(AMBs, DST_CHAINS[0], abi.encode(1), extraDataGenerated);
        assertGe(totalFees, 0);
    }
}
