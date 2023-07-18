/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../../types/LiquidityTypes.sol";
import "../../types/DataTypes.sol";

// Test Utils
import {MockERC20} from "../mocks/MockERC20.sol";
import "../utils/ProtocolActions.sol";
import "../utils/AmbParams.sol";

/// @dev test CoreStateRegistry.rescueFailedDeposits()
contract SXSVDNormal4626RevertXChainDepositNoMultiTxTokenInputSlippageL1AMB1 is ProtocolActions {
    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/
        AMBs = [1, 3];

        CHAIN_0 = OP;
        DST_CHAINS = [POLY];

        /// @dev define vaults amounts and slippage for every destination chain and for every action
        TARGET_UNDERLYINGS[POLY][0] = [1];
        TARGET_VAULTS[POLY][0] = [3]; /// @dev vault index 3 is failedDepositMock, check VAULT_KINDS

        TARGET_FORM_KINDS[POLY][0] = [0];

        AMOUNTS[POLY][0] = [4121];

        MAX_SLIPPAGE = 1000;

        /// @dev 1 for socket, 2 for lifi
        LIQ_BRIDGES[POLY][0] = [1];

        actions.push(
            TestAction({
                action: Actions.Deposit,
                multiVaults: false, //!!WARNING turn on or off multi vaults
                user: 0,
                testType: TestType.RevertProcessPayload,
                revertError: "",
                revertRole: "",
                slippage: 312, // 0% <- if we are testing a pass this must be below each maxSlippage,
                multiTx: false,
                externalToken: 2 // 0 = DAI, 1 = USDT, 2 = WETH
            })
        );
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_scenario() public {
        for (uint256 act; act < actions.length; act++) {
            TestAction memory action = actions[act];
            MultiVaultsSFData[] memory multiSuperFormsData;
            SingleVaultSFData[] memory singleSuperFormsData;
            MessagingAssertVars[] memory aV;
            StagesLocalVars memory vars;
            bool success;
            _runMainStages(action, act, multiSuperFormsData, singleSuperFormsData, aV, vars, success);
        }

        vm.selectFork(FORKS[OP]);
        console.log("users[0]'s WETH on OP, pre-rescueFailedDeposits:", MockERC20(getContract(CHAIN_0, UNDERLYING_TOKENS[2])).balanceOf(users[0]));

        vm.selectFork(FORKS[POLY]);
        MockERC20 weth = MockERC20(getContract(DST_CHAINS[0], UNDERLYING_TOKENS[2]));
        console.log("users[0]'s WETH on POLY pre-rescueFailedDeposits:", weth.balanceOf(users[0]));

        /// @dev FIXME: don't see any WETH transferred to CoreStateRegistry on POLY
        console.log("CoreStateRegistry's WETH on POLY, pre-rescueFailedDeposits:", weth.balanceOf(0x991bdBB5D32b60aB8ef95ff0cD994ed62289b1E6));

        /// @dev need to manually transfer WETH to CoreStateRegistry on POLY, to simulate the case
        vm.prank(users[0]);
        weth.transfer(0x991bdBB5D32b60aB8ef95ff0cD994ed62289b1E6, 5000);

        LiqRequest[] memory liqRequests = new LiqRequest[](1);
        liqRequests[0] = LiqRequest(
            1, /// @dev socket bridge
            _buildLiqBridgeTxData(
                1,
                getContract(DST_CHAINS[0], UNDERLYING_TOKENS[2]), /// @dev WETH
                getContract(DST_CHAINS[0], UNDERLYING_TOKENS[2]), /// @dev WETH
                0x991bdBB5D32b60aB8ef95ff0cD994ed62289b1E6, /// @dev CoreStateRegistry on dst chain
                CHAIN_0,
                false,
                users[0],
                CHAIN_0,
                4121
            ),
            getContract(DST_CHAINS[0], UNDERLYING_TOKENS[2]), /// @dev WETH,
            4121,
            0,
            ""
        );

        vm.prank(deployer);
        CoreStateRegistry(payable(getContract(DST_CHAINS[0], "CoreStateRegistry")))
            .rescueFailedDeposits(1, liqRequests);

        /// @dev check WETH balance of users[0] on OP
        vm.selectFork(FORKS[OP]);
        console.log("users[0]'s WETH on OP post-rescueFailedDeposits:", MockERC20(getContract(CHAIN_0, UNDERLYING_TOKENS[2])).balanceOf(users[0]));
    }
}
