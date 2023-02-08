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

    function test_attack() public {
        uint256 victimVault = 1; // should correspond to DAI vault
        uint256 amountsToDeposit = 1000;
        uint256 msgValue = 1e18;
        address underlyingSrcToken = getContract(ETH, "DAI");
        address underlyingDstToken = getContract(POLY, "DAI");
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
                msgValue,
                ETH,
                POLY
            );
        MockERC20 BSC_DAI = MockERC20(underlyingDstToken);
        assertEq(BSC_DAI.balanceOf(getContract(POLY, "SuperDestination")), 0);

        /// @dev single deposit test
        _depositToVault(
            underlyingSrcToken,
            fromSrc,
            toDst,
            stateReq,
            liqReq,
            amountsToDeposit,
            1,
            ETH,
            POLY,
            POLY_lzEndpoint
        );
        assertEq(BSC_DAI.balanceOf(toDst), amountsToDeposit);
        /*
        for (uint256 i = 1; i <= users.length; i++) {
            _depositToVault(
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
            );
        }
        //assertEq(BSC_DAI.balanceOf(toDst), amountsToDeposit * users.length);
    */
    }
}
