// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../utils/BaseSetup.sol";
import "../utils/Utilities.sol";

import {DataLib} from "../../libraries/DataLib.sol";
import {ISuperformFactory} from "../../interfaces/ISuperformFactory.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {SuperPositions} from "../../SuperPositions.sol";
import {Error} from "../../utils/Error.sol";

contract SuperPositionTest is BaseSetup {
    bytes4 INTERFACE_ID_ERC165 = 0x01ffc9a7;

    string public URI = "https://superform.xyz/metadata/";
    SuperPositions public superPositions;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);
        superPositions = SuperPositions(payable(getContract(ETH, "SuperPositions")));
    }

    /// Test dynamic url addition without freeze
    function test_addDynamicURI() public {
        vm.startPrank(deployer);
        superPositions.setDynamicURI(URI, false);

        assertEq(superPositions.dynamicURI(), URI);
    }

    /// Test uri freeze
    function test_freezeDynamicURI() public {
        vm.startPrank(deployer);
        superPositions.setDynamicURI(URI, true);

        vm.expectRevert(Error.DYNAMIC_URI_FROZEN.selector);
        superPositions.setDynamicURI(URI, true);
    }

    /// Test uri returned for id
    function test_readURI() public {
        vm.startPrank(deployer);
        superPositions.setDynamicURI(URI, false);

        assertEq(superPositions.uri(1), "https://superform.xyz/metadata/1");
    }

    /// Test support interface
    function test_SupportsInterface() public {
        assertEq(superPositions.supportsInterface(INTERFACE_ID_ERC165), true);
    }

    /// Test revert for invalid txType (single)
    function test_InvalidTxTypeSingle() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 0, 1, address(0), ETH);
        ReturnSingleData memory maliciousReturnData = ReturnSingleData(0, 1, 100);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
        superPositions.stateSync(maliciousMessage);
    }

    /// Test revert for invalid txType (multi)
    /// case: accidental messaging back for failed withdrawals with CallBackType FAIL
    function test_InvalidTxTypeMulti() public {
        uint256 txInfo = DataLib.packTxInfo(0, 2, 1, 1, address(0), ETH);

        uint256[] memory x = new uint256[](1);
        x[0] = 100;

        ReturnMultiData memory maliciousReturnData = ReturnMultiData(0, x, x);
        AMBMessage memory maliciousMessage = AMBMessage(txInfo, abi.encode(maliciousReturnData));

        vm.broadcast(getContract(ETH, "CoreStateRegistry"));
        vm.expectRevert(Error.INVALID_PAYLOAD_STATUS.selector);
        superPositions.stateMultiSync(maliciousMessage);
    }
}
