// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Contracts
import {Attack} from "../../contracts/attack/Attack.sol";

// Test Utils
import {MockERC20} from "./mocks/MockERC20.sol";
import "./utils/BaseSetup.sol";

contract AttackTest is BaseSetup {
    Attack internal attackFTM;
    Attack internal attackBSC;

    address internal alice = address(0x1);
    address internal bob = address(0x2);
    address internal carol = address(0x3);

    // chainIds
    uint16 FTM = 250;
    uint16 BSC = 56;

    string FANTOM_RPC_URL = vm.envString("FANTOM_RPC_URL");
    string BSC_RPC_URL = vm.envString("BSC_RPC_URL");

    function setUp() public override {
        super.setUp();

        _deployProtocol(FANTOM_RPC_URL, BSC_RPC_URL, FTM, BSC);

        /// @dev deploy contract on source chain
        /// @notice this should be done for both chains with create2?

        address payable ftmSuperRouter = payable(
            getContract(FTM, "SuperRouter")
        );

        address payable bscStateHandler = payable(
            getContract(BSC, "StateHandler")
        );

        address payable bscSuperDestination = payable(
            getContract(BSC, "SuperDestination")
        );

        address bscDAI = getContract(BSC, "DAI");

        address bscDAIVault = getContract(BSC, "DAIVault");

        vm.selectFork(forks[FTM]);
        vm.startPrank(deployer);

        attackFTM = new Attack(
            ftmSuperRouter,
            bscStateHandler,
            bscSuperDestination,
            bscDAI,
            bscDAIVault
        );

        MockERC20 ftmDAI = MockERC20(super.getContract(FTM, "DAI"));

        ftmDAI.transfer(address(attackFTM), milionTokensE18 / 100);

        vm.selectFork(forks[BSC]);

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

    function test_attack() public {}
}
