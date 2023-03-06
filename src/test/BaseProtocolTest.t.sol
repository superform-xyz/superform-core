/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../types/LiquidityTypes.sol";
import "../types/DataTypes.sol";
import "forge-std/console.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/BaseSetup.sol";

contract BaseProtocolTest is BaseSetup {
    mapping(uint256 => uint256[]) internal VAULTS_ACTIONS;
    mapping(uint256 => mapping(LiquidityChange => uint256[]))
        internal AMOUNTS_ACTIONS;

    /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant numberOfTestActions = 11; /// @dev <- change this whenever you add/remove test cases

    function setUp() public override {
        super.setUp();

        /*//////////////////////////////////////////////////////////////
                    !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/
        /// @dev Define Vault-Amount pairs for each type of test case you want to test
        /// @dev These have been done with state variables for direct inline input
        /// @dev You can modify the amounts/vaults at will and create more kinds
        /// @dev LiquidityChange partial vs full are only defined for cosmetic purposes in the test for now
        /// !! WARNING - only 3 vaults/underlyings exist, Ids 1,2,3 !!

        // Type 0 - Single Vault x One StateReq/LiqReq
        VAULTS_ACTIONS[0] = [uint256(1)];
        AMOUNTS_ACTIONS[0][LiquidityChange.Full] = [uint256(1000)];

        // Type 1 - Single Vault x Two StateReq/LiqReq
        VAULTS_ACTIONS[1] = [uint256(1), 3];
        // With Full withdrawal (note, deposits are always full)
        AMOUNTS_ACTIONS[1][LiquidityChange.Full] = [uint256(1000), 5000];
        // With Partial withdrawal
        AMOUNTS_ACTIONS[1][LiquidityChange.Partial] = [uint256(500), 2000];
    }

    function _getTestAction(uint256 index_)
        internal
        view
        returns (TestAction memory)
    {
        /*//////////////////////////////////////////////////////////////
                    !! WARNING !!  DEFINE TEST SETTINGS HERE
        //////////////////////////////////////////////////////////////*/
        TestAction[numberOfTestActions] memory testActionCases = [
            /// FTM=>BSC: user depositing to a vault on BSC from Fantom
            TestAction({
                action: Actions.Deposit,
                actionType: 0,
                actionKind: LiquidityChange.Full,
                CHAIN_0: FTM,
                CHAIN_1: BSC,
                user: users[0],
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                maxSlippage: 1000, // 10%,
                slippage: 0, // 0% <- if we are testing a pass this must be below maxSlippage,
                multiTx: false
            }),
            /// FTM=>BSC: user withdrawing tokens from a vault on BSC from/to Fantom
            TestAction({
                action: Actions.Withdraw,
                actionType: 0,
                actionKind: LiquidityChange.Full,
                CHAIN_0: FTM,
                CHAIN_1: BSC,
                user: users[0],
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                maxSlippage: 1000, // 10%,
                slippage: 0, // 0% <- if we are testing a pass this must be below maxSlippage
                multiTx: false
            }),
            /// FTM=>BSC: user depositing to a vault on BSC from Fantom with MultiTx
            TestAction({
                action: Actions.Deposit,
                actionType: 0,
                actionKind: LiquidityChange.Full,
                CHAIN_0: FTM,
                CHAIN_1: BSC,
                user: users[0],
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                maxSlippage: 1000, // 10%,
                slippage: 0, // 0% <- if we are testing a pass this must be below maxSlippage,
                multiTx: true
            }),
            /// BSC=>FTM: multiple LiqReq/StateReq for multi-deposit
            /// BSC=>FTM: user depositing to a vault on Fantom from BSC
            TestAction({
                action: Actions.Deposit,
                actionType: 1,
                actionKind: LiquidityChange.Full,
                CHAIN_0: BSC,
                CHAIN_1: FTM,
                user: users[2],
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                maxSlippage: 1000, // 10%,
                slippage: 0, // 0% <- if we are testing a pass this must be below maxSlippage
                multiTx: false
            }),
            /// BSC=>FTM: multiple LiqReq/StateReq for multi-deposit
            /// BSC=>FTM: partial withdraw tokens from a vault on Fantom from/to BSC
            TestAction({
                action: Actions.Withdraw,
                actionType: 1,
                actionKind: LiquidityChange.Partial,
                CHAIN_0: BSC,
                CHAIN_1: FTM,
                user: users[2],
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                maxSlippage: 1000, // 10%,
                slippage: 0, // 0% <- if we are testing a pass this must be below maxSlippage
                multiTx: false
            }),
            /// FTM=>BSC: user depositing to a vault requiring swap (stays pending)
            TestAction({
                action: Actions.Deposit,
                actionType: 0,
                actionKind: LiquidityChange.Full,
                CHAIN_0: FTM,
                CHAIN_1: BSC,
                user: users[1],
                testType: TestType.RevertProcessPayload,
                revertError: IStateRegistry.INVALID_PAYLOAD_STATE.selector, // @dev to a find how to use reverts here
                revertRole: "",
                maxSlippage: 1000, // 10%,
                slippage: 0, // 0% <- if we are testing a pass this must be below maxSlippage
                multiTx: false
            }),
            /// FTM=>BSC: cross-chain slippage update beyond max slippage
            TestAction({
                action: Actions.Deposit,
                actionType: 0,
                actionKind: LiquidityChange.Full,
                CHAIN_0: FTM,
                CHAIN_1: BSC,
                user: users[0],
                testType: TestType.RevertUpdateStateSlippage,
                revertError: IStateRegistry.SLIPPAGE_OUT_OF_BOUNDS.selector, // @dev to a find how to use reverts here
                revertRole: "",
                maxSlippage: 1000, // 10%,
                slippage: 1200, // 12%
                multiTx: false
            }),
            /// ARBI=>OP: cross-chain slippage update above received value
            TestAction({
                action: Actions.Deposit,
                actionType: 1,
                actionKind: LiquidityChange.Full,
                CHAIN_0: ARBI,
                CHAIN_1: OP,
                user: users[2],
                testType: TestType.RevertUpdateStateSlippage,
                revertError: IStateRegistry.NEGATIVE_SLIPPAGE.selector, // @dev to a find how to use reverts here
                revertRole: "",
                maxSlippage: 1000, // 10%,
                slippage: -100,
                multiTx: false
            }),
            /// POLY=>POLY: SAMECHAIN deposit()
            /// @dev NOTE: this is being made with non native assets
            /// @dev NOTE: untested edge case: if doing a native token vault deposit (sent as msg.value) multiple state requests do not work
            TestAction({
                action: Actions.Deposit,
                actionType: 1,
                actionKind: LiquidityChange.Full,
                CHAIN_0: POLY,
                CHAIN_1: POLY,
                user: users[0],
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                maxSlippage: 1000, // 10%,
                slippage: 100,
                multiTx: false
            }),
            /// POLY=>POLY: SAMECHAIN withdraw()
            /// @dev NOTE: this is being made with non native assets
            TestAction({
                action: Actions.Withdraw,
                actionType: 1,
                actionKind: LiquidityChange.Full,
                CHAIN_0: POLY,
                CHAIN_1: POLY,
                user: users[0],
                testType: TestType.Pass,
                revertError: "",
                revertRole: "",
                maxSlippage: 1000, // 10%,
                slippage: 200,
                multiTx: false
            }),
            /// OP=>AVAX: cross-chain slippage update from unauthorized wallet
            //revertError: "AccessControl: account 0x0000000000000000000000000000000000000003 is missing role 0x2030565476ef23eb21f6c1f68075f5a89b325631df98f5793acd3297f9b80123",
            TestAction({
                action: Actions.Deposit,
                actionType: 0,
                actionKind: LiquidityChange.Full,
                CHAIN_0: OP,
                CHAIN_1: AVAX,
                user: users[1],
                testType: TestType.RevertUpdateStateRBAC,
                revertError: "",
                revertRole: keccak256("UPDATER_ROLE"),
                maxSlippage: 1000, // 10%,
                slippage: 0,
                multiTx: false
            })
        ];

        return testActionCases[index_];
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_actions() public {
        /// @dev do the test actions in order

        for (uint256 i = 0; i < numberOfTestActions; i++) {
            TestAction memory action = _getTestAction(i);

            if (
                action.revertError != bytes4(0) &&
                action.testType == TestType.Pass
            ) revert MISMATCH_TEST_TYPE();

            if (
                (action.testType != TestType.RevertUpdateStateRBAC &&
                    action.revertRole != bytes32(0)) ||
                (action.testType == TestType.RevertUpdateStateRBAC &&
                    action.revertRole == bytes32(0))
            ) revert MISMATCH_RBAC_TEST();

            ActionLocalVars memory vars;

            vars.lzEndpoint_0 = LZ_ENDPOINTS[action.CHAIN_0];
            vars.lzEndpoint_1 = LZ_ENDPOINTS[action.CHAIN_1];
            vars.fromSrc = payable(getContract(action.CHAIN_0, "SuperRouter"));
            vars.toDst = payable(
                getContract(action.CHAIN_1, "SuperDestination")
            );

            (
                vars.targetVaultIds,
                vars.underlyingSrcToken,
                vars.vaultMock,
                vars.TARGET_VAULTS
            ) = _targetVaults(
                action.actionType,
                action.CHAIN_0,
                action.CHAIN_1
            );
            vars.amounts = _amounts(action.actionType, action.actionKind);

            if (action.action == Actions.Deposit) {
                deposit(action, vars);
            } else if (action.action == Actions.Withdraw) {
                withdraw(action, vars);
            }
        }
        _resetPayloadIDs();
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev this function is used to build the 2D arrays in the best way possible
    function _targetVaults(
        uint256 action,
        uint16 chain0,
        uint16 chain1
    )
        internal
        view
        returns (
            uint256[][] memory targetVaultsMem,
            address[][] memory underlyingSrcTokensMem,
            address[][] memory vaultMocksMem,
            MockERC20[][] memory TARGET_VAULTSMem
        )
    {
        uint256[] memory vaultIdsTemp = VAULTS_ACTIONS[action];
        uint256 len = vaultIdsTemp.length;
        if (len == 0) revert LEN_VAULTS_ZERO();

        targetVaultsMem = new uint256[][](len);
        underlyingSrcTokensMem = new address[][](len);
        vaultMocksMem = new address[][](len);
        TARGET_VAULTSMem = new MockERC20[][](len);

        for (uint256 i = 0; i < len; i++) {
            uint256[] memory tVaults = new uint256[](
                allowedNumberOfVaultsPerRequest
            );
            address[] memory tUnderlyingSrcTokens = new address[](
                allowedNumberOfVaultsPerRequest
            );
            address[] memory tVaultMocks = new address[](
                allowedNumberOfVaultsPerRequest
            );
            MockERC20[] memory tTARGET_VAULTS = new MockERC20[](
                allowedNumberOfVaultsPerRequest
            );

            for (uint256 j = 0; j < allowedNumberOfVaultsPerRequest; j++) {
                tVaults[j] = vaultIdsTemp[i];
                string memory underlyingToken = UNDERLYING_TOKENS[
                    vaultIdsTemp[i] - 1
                ];
                tUnderlyingSrcTokens[j] = getContract(chain0, underlyingToken);
                tVaultMocks[j] = getContract(
                    chain1,
                    VAULT_NAMES[vaultIdsTemp[i] - 1]
                );
                tTARGET_VAULTS[j] = MockERC20(
                    getContract(chain1, underlyingToken)
                );
            }
            targetVaultsMem[i] = tVaults;
            underlyingSrcTokensMem[i] = tUnderlyingSrcTokens;
            vaultMocksMem[i] = tVaultMocks;
            TARGET_VAULTSMem[i] = tTARGET_VAULTS;
        }
    }

    /// @dev this function is used to build the 2D arrays in the best way possible
    function _amounts(uint256 action, LiquidityChange actionKind)
        internal
        view
        returns (uint256[][] memory targetAmountsMem)
    {
        uint256[] memory amountsTemp = AMOUNTS_ACTIONS[action][actionKind];
        uint256 len = amountsTemp.length;
        if (len == 0) revert LEN_AMOUNTS_ZERO();

        targetAmountsMem = new uint256[][](len);

        for (uint256 i = 0; i < len; i++) {
            uint256[] memory tAmounts = new uint256[](
                allowedNumberOfVaultsPerRequest
            );

            for (uint256 j = 0; j < allowedNumberOfVaultsPerRequest; j++) {
                tAmounts[j] = amountsTemp[i];
            }
            targetAmountsMem[i] = tAmounts;
        }
    }
}
