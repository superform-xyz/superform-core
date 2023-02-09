// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Contracts
import {Attack} from "contracts/attack/Attack.sol";
import "contracts/types/socketTypes.sol";
import "contracts/types/lzTypes.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/BaseSetup.sol";

contract AttackTest is BaseSetup {
    Attack internal attackFTM;
    Attack internal attackBSC;

    address internal alice = address(0x1);
    address internal bob = address(0x2);
    address internal carol = address(0x3);

    /// @dev reference for chain ids https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    uint16 constant ETH = 101;
    uint16 constant POLY = 109;

    address constant ETH_lzEndpoint =
        0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address constant POLY_lzEndpoint =
        0x3c2269811836af69497E5F486A85D7316753cf62;

    string ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL");
    string POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL");

    function setUp() public override {
        super.setUp();

        /// @dev Call deploy protocol with intended src and dst chains for simulation
        _deployProtocol(
            ETHEREUM_RPC_URL,
            POLYGON_RPC_URL,
            ETH_lzEndpoint,
            POLY_lzEndpoint,
            ETH,
            POLY
        );

        /// @dev deploy contract on source chain
        /// @notice this should be done for both chains with create2?

        address payable ftmSuperRouter = payable(
            getContract(ETH, "SuperRouter")
        );

        address payable bscStateHandler = payable(
            getContract(POLY, "StateHandler")
        );

        address payable bscSuperDestination = payable(
            getContract(POLY, "SuperDestination")
        );

        address bscDAI = getContract(POLY, "DAI");

        address bscDAIVault = getContract(POLY, "DAIVault");

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        attackFTM = new Attack(
            ftmSuperRouter,
            bscStateHandler,
            bscSuperDestination,
            bscDAI,
            bscDAIVault
        );

        MockERC20 ftmDAI = MockERC20(super.getContract(ETH, "DAI"));

        ftmDAI.transfer(address(attackFTM), milionTokensE18 / 100);

        vm.selectFork(FORKS[POLY]);

        attackBSC = new Attack(
            ftmSuperRouter,
            bscStateHandler,
            bscSuperDestination,
            bscDAI,
            bscDAIVault
        );

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: Same address deployment
    //////////////////////////////////////////////////////////////*/

    function test_attack_contract_same_address() public {
        assertEq(address(attackFTM), address(attackBSC));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: Attack
    //////////////////////////////////////////////////////////////*/

    /// @dev This is a test of an end to end possibçe attack. Testing individual parts (unit tests) can be taken from here
    function test_attack() public {
        uint256 victimVault = 1; // should correspond to DAI vault
        uint256 amountsToDeposit = 1000;
        uint256 ETH_PAYLOAD_ID;
        uint256 POLY_PAYLOAD_ID;
        address underlyingSrcToken = getContract(ETH, "DAI");
        address payable fromSrc = payable(getContract(ETH, "SuperRouter"));
        address payable toDst = payable(getContract(POLY, "SuperDestination"));

        /// @dev Create liqRequest and stateReq for a couple users to deposit in target vault
        (
            StateReq memory stateReq,
            LiqRequest memory liqReq
        ) = _buildDepositCallData(
                fromSrc,
                toDst,
                underlyingSrcToken,
                victimVault,
                amountsToDeposit,
                1 ether,
                ETH,
                POLY
            );
        MockERC20 POLY_DAI = MockERC20(getContract(POLY, "DAI"));
        vm.selectFork(FORKS[POLY]);
        assertEq(POLY_DAI.balanceOf(getContract(POLY, "SuperDestination")), 0);

        /// @dev fund the vault with 10000 DAI
        for (uint256 i = 0; i < users.length; i++) {
            _depositToVaultMultiple(
                DepositMultipleArgs(
                    underlyingSrcToken,
                    fromSrc,
                    toDst,
                    stateReq,
                    liqReq,
                    amountsToDeposit,
                    i,
                    ETH,
                    POLY,
                    POLY_lzEndpoint
                )
            );
        }

        vm.selectFork(FORKS[POLY]);
        assertEq(POLY_DAI.balanceOf(toDst), amountsToDeposit * users.length);

        /// @dev Update state on src and dst and process payload on dst
        /// @notice this will mint to the users the super positions
        for (uint256 i = 0; i < users.length; i++) {
            unchecked {
                POLY_PAYLOAD_ID++;
            }
            _updateState(POLY_PAYLOAD_ID, amountsToDeposit, POLY);

            vm.recordLogs();
            _processPayload(POLY_PAYLOAD_ID, POLY);

            /*
            Vm.Log[] memory logs = vm.getRecordedLogs();
            LayerZeroHelper(getContract(POLY, "LayerZeroHelper")).help(
                ETH_lzEndpoint,
                1500000, /// @dev This is the gas value to send - value needs to be tested and probably be lower
                FORKS[ETH],
                logs
            );

            unchecked {
                ETH_PAYLOAD_ID++;
            }

            _processPayload(ETH_PAYLOAD_ID, ETH);
            */
        }
    }
}
