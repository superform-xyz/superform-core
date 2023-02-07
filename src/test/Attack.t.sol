// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Contracts
import {Attack} from "contracts/attack/Attack.sol";
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

    function setUp(
        string memory RPC_URL_0,
        string memory RPC_URL_1,
        uint16 chainId0,
        uint16 chainId1
    ) public override {
        super.setUp(FANTOM_RPC_URL, BSC_RPC_URL, FTM, BSC);

        /// @dev deploy contract on source chain
        /// @notice this should be done for both chains with create2?
        vm.selectFork(forks[chainId0]);

        attackFTM = new Attack(
            payable(super.getContract(FTM, "SuperRouter")),
            payable(super.getContract(BSC, "StateHandler")),
            payable(super.getContract(BSC, "SuperDestination")),
            super.getContract(BSC, "USDC"),
            super.getContract(BSC, "USDCVault")
        );
        MockERC20(super.getContract(FTM, "USDC")).transfer(
            address(attackFTM),
            milionTokensE18 / 100
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: Postgame posting
    //////////////////////////////////////////////////////////////*/

    function test_revert_end_match_invalid_root() public {}
}
