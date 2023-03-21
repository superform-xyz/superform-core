/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

// Contracts
import "../types/LiquidityTypes.sol";
import "../types/DataTypes.sol";
// import "forge-std/console.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/BaseSetup.sol";

/// @dev TODO - we should do assertions on final balances of users at the end of each test scenario
/// @dev FIXME - using unoptimized multiDstMultivault function
contract Scenario1Test is BaseSetup {
    uint8 public primaryAMB;

    uint8[] public secondaryAMBs;

    uint16 public CHAIN_0;

    uint16[] public DST_CHAINS;

    mapping(uint16 => uint256[]) public TARGET_UNDERLYING_VAULTS;

    mapping(uint16 => uint256[]) public TARGET_FORMS; /// @dev must conform to the above

    mapping(uint16 => uint256[]) public AMOUNTS;

    mapping(uint16 => uint256[]) public MAX_SLIPPAGE;

    TestAction action;

    function setUp() public override {
        super.setUp();
        /*//////////////////////////////////////////////////////////////
                !! WARNING !!  DEFINE TEST SETTINGS HERE
    //////////////////////////////////////////////////////////////*/

        primaryAMB = 1;

        secondaryAMBs = [1];

        CHAIN_0 = FTM;
        DST_CHAINS = [BSC, POLY];

        TARGET_UNDERLYING_VAULTS[BSC] = [0];
        TARGET_UNDERLYING_VAULTS[POLY] = [1, 2];

        /// @dev - only one form kind exists for now (id 0)
        TARGET_FORMS[BSC] = [0];
        TARGET_FORMS[POLY] = [0, 0];

        AMOUNTS[BSC] = [1000];
        AMOUNTS[POLY] = [1000, 2000];

        MAX_SLIPPAGE[BSC] = [1000];
        MAX_SLIPPAGE[POLY] = [1000, 1000];

        uint256 msgValue = 1 * _getPriceMultiplier(CHAIN_0) * 1e18;

        action = TestAction({
            action: Actions.SingleVaultDeposit,
            user: users[0],
            testType: TestType.Pass,
            revertError: "",
            revertRole: "",
            slippage: 0, // 0% <- if we are testing a pass this must be below each maxSlippage,
            multiTx: false,
            adapterParam: "",
            msgValue: msgValue
        });
    }

    /*///////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    function test_actions() public {
        /// @dev do the test actions in order

        if (action.revertError != bytes4(0) && action.testType == TestType.Pass)
            revert MISMATCH_TEST_TYPE();

        if (
            (action.testType != TestType.RevertUpdateStateRBAC &&
                action.revertRole != bytes32(0)) ||
            (action.testType == TestType.RevertUpdateStateRBAC &&
                action.revertRole == bytes32(0))
        ) revert MISMATCH_RBAC_TEST();

        NewActionLocalVars memory vars;

        vars.lzEndpoint_0 = LZ_ENDPOINTS[CHAIN_0];
        vars.fromSrc = payable(getContract(CHAIN_0, "SuperRouter"));

        vars.nDestinations = DST_CHAINS.length;
        for (uint256 i = 0; i < vars.nDestinations; i++) {
            vars.lzEndpoints_1[i] = LZ_ENDPOINTS[DST_CHAINS[i]];

            /// @dev action is sameChain, if there is a liquidity swap it should go to the same form
            /// @dev if action is cross chain withdraw, user can select to receive a different kind of underlying from source
            if (
                CHAIN_0 == DST_CHAINS[i] ||
                ((action.action == Actions.MultiVaultWithdraw ||
                    action.action == Actions.SingleVaultWithdraw) &&
                    CHAIN_0 != DST_CHAINS[i])
            ) {
                /// @dev FIXME: this is only using hardcoded formid 1 (ERC4626Form) for now!!!
                /// !!WARNING
                vars.toDst[i] = payable(
                    getContract(DST_CHAINS[i], "ERC4626Form")
                );
            } else {
                vars.toDst[i] = payable(
                    getContract(DST_CHAINS[i], "TokenBank")
                );
            }

            (
                vars.targetSuperFormIds,
                vars.underlyingSrcToken,
                vars.vaultMock
            ) = _targetVaults(CHAIN_0, DST_CHAINS[i]);

            vars.amounts = AMOUNTS[DST_CHAINS[i]];

            vars.maxSlippage = MAX_SLIPPAGE[DST_CHAINS[i]];

            if (action.action == Actions.MultiVaultDeposit) {
                vars.superFormsData[i] = _buildMultiVaultDepositCallData(
                    MultiVaultDepositArgs(
                        action.user,
                        vars.fromSrc,
                        vars.toDst[i],
                        vars.underlyingSrcToken, ///!!!WARNING !!! @dev we probably need to create liq request with both src and dst tokens
                        vars.targetSuperFormIds,
                        vars.amounts,
                        vars.maxSlippage,
                        CHAIN_0,
                        DST_CHAINS[i],
                        action.multiTx
                    )
                );

                /// @dev multiDstMultiVaultDeposit
            }

            if (vars.nDestinations == 1) {
                vars.singleDstMultiVaultStateReq = SingleDstMultiVaultsStateReq(
                    primaryAMB,
                    secondaryAMBs,
                    DST_CHAINS[i],
                    vars.superFormsData[0],
                    action.adapterParam,
                    action.msgValue
                );
                /// @dev singleDstMultiVaultDeposit
            } else if (vars.nDestinations > 1) {
                vars.multiDstMultiVaultStateReq = MultiDstMultiVaultsStateReq(
                    primaryAMB,
                    secondaryAMBs,
                    DST_CHAINS,
                    vars.superFormsData,
                    action.adapterParam,
                    action.msgValue
                );
            }
        }
    }

    function _buildMultiVaultDepositCallData(
        MultiVaultDepositArgs memory args
    ) internal returns (MultiVaultsSFData memory superFormsData) {
        bytes memory adapterParam;
        /*
            adapterParam = abi.encodePacked(version, gasLimit);
        */
        SingleVaultSFData memory superFormData;
        uint256 len = args.superFormIds.length;
        LiqRequest[] memory liqRequests = new LiqRequest[](len);

        for (uint i = 0; i < len; i++) {
            superFormData = _buildSingleVaultDepositCallData(
                SingleVaultDepositArgs(
                    args.user,
                    args.fromSrc,
                    args.toDst,
                    args.underlyingTokens[i],
                    args.superFormIds[i],
                    args.amounts[i],
                    args.maxSlippage[i],
                    args.srcChainId,
                    args.toChainId,
                    args.multiTx
                )
            );
            liqRequests[i] = superFormData.liqRequest;
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
        SingleVaultDepositArgs memory args
    ) internal returns (SingleVaultSFData memory superFormData) {
        uint256 initialFork = vm.activeFork();

        address from = args.fromSrc;

        if (args.srcChainId == args.toChainId) {
            /// @dev same chain deposit, from is Form
            /// @dev FIXME: this likely needs to be TOKENBANK now
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
            args.amount, /// @dev FIXME - not testing sum of amounts (different vaults)
            FORKS[args.toChainId]
        );

        LiqRequest memory liqReq = LiqRequest(
            1, /// @dev FIXME: hardcoded for now
            socketTxData,
            args.underlyingToken,
            getContract(args.srcChainId, "SocketRouterMockFork"),
            args.amount, /// @dev FIXME -  not testing sum of amounts (different vaults)
            0
        );

        vm.selectFork(FORKS[args.srcChainId]);

        /// @dev - APPROVE transfer to SuperRouter (because of Socket)
        vm.prank(args.user);
        MockERC20(args.underlyingToken).approve(from, args.amount);

        vm.selectFork(initialFork);

        superFormData = SingleVaultSFData(
            args.superFormId,
            args.amount,
            args.maxSlippage,
            liqReq,
            ""
        );
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    struct TargetVaultsVars {
        uint256[] underlyingTokenIds;
        uint256[] superFormIdsTemp;
        uint256 len;
        string underlyingToken;
    }

    /// @dev this function is used to build the 2D arrays in the best way possible
    function _targetVaults(
        uint16 chain0,
        uint16 chain1
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
        vars.underlyingTokenIds = TARGET_UNDERLYING_VAULTS[chain1];
        vars.superFormIdsTemp = _superFormIds(vars.underlyingTokenIds, chain1);
        vars.len = vars.superFormIdsTemp.length;
        if (vars.len == 0) revert LEN_VAULTS_ZERO();

        targetSuperFormsMem = new uint256[](vars.len);
        underlyingSrcTokensMem = new address[](vars.len);
        vaultMocksMem = new address[](vars.len);

        for (uint256 i = 0; i < vars.len; i++) {
            vars.underlyingToken = UNDERLYING_TOKENS[
                vars.underlyingTokenIds[i]
            ];

            targetSuperFormsMem[i] = vars.superFormIdsTemp[i];
            underlyingSrcTokensMem[i] = getContract(
                chain0,
                vars.underlyingToken
            );
            vaultMocksMem[i] = getContract(
                chain1,
                VAULT_NAMES[vars.underlyingTokenIds[i]]
            );
        }
    }

    function _superFormIds(
        uint256[] memory underlyingTokenIds_,
        uint16 chainId_
    ) internal view returns (uint256[] memory) {
        uint256[] memory superFormIds_ = new uint256[](
            underlyingTokenIds_.length
        );
        for (uint256 i = 0; i < underlyingTokenIds_.length; i++) {
            if (underlyingTokenIds_[i] > UNDERLYING_TOKENS.length)
                revert WRONG_UNDERLYING_ID();

            address vault = getContract(
                chainId_,
                string.concat(
                    UNDERLYING_TOKENS[underlyingTokenIds_[i]],
                    "Vault"
                )
            );

            superFormIds_[i] = _superFormId(
                vault,
                FORMS_FOR_VAULTS[underlyingTokenIds_[i]],
                chainId_
            );
        }
        return superFormIds_;
    }

    function _superFormId(
        address vault_,
        uint256 formId_,
        uint80 chainId_
    ) internal pure returns (uint256 superFormId_) {
        superFormId_ = uint256(uint160(vault_));
        superFormId_ |= formId_ << 160;
        superFormId_ |= uint256(chainId_) << 176;
    }
}
