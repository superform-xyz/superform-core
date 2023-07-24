// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../utils/BaseSetup.sol";
import {TransactionType, CallbackType, AMBMessage} from "../../types/DataTypes.sol";
import {DataLib} from "../../libraries/DataLib.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {LayerzeroImplementation} from "../../crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import {CoreStateRegistry} from "../../crosschain-data/extensions/CoreStateRegistry.sol";
import {Error} from "../../utils/Error.sol";

contract LayerzeroImplementationTest is BaseSetup {
    /// @dev event emitted from CelerMessageBus on ETH (LZ_ENDPOINT)
    event UaSendVersionSet(address ua, uint16 version);
    event UaReceiveVersionSet(address ua, uint16 version);
    event UaForceResumeReceive(uint16 chainId, bytes srcAddress);

    address public constant LZ_ENDPOINT = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address public constant CHAINLINK_lzOracle = 0x150A58e9E6BF69ccEb1DBA5ae97C166DC8792539;
    ISuperRegistry public superRegistry;
    LayerzeroImplementation layerzeroImplementation;
    address public bond;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        layerzeroImplementation = LayerzeroImplementation(payable(superRegistry.getAmbAddress(1)));
        /// @dev malicious caller
        bond = address(7);
        /// @dev (who's a brokie)
        vm.deal(bond, 1 ether);

        vm.startPrank(deployer);
    }

    function test_setChainId() public {
        layerzeroImplementation.setChainId(10, 10); /// optimism
        layerzeroImplementation.setChainId(137, 137); /// polygon

        assertEq(layerzeroImplementation.ambChainId(10), 10);
        assertEq(layerzeroImplementation.superChainId(137), 137);
    }

    function test_revert_setChainId_invalidChainId_invalidCaller() public {
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        layerzeroImplementation.setChainId(10, 0); /// optimism

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        layerzeroImplementation.setChainId(0, 10); /// optimism

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        layerzeroImplementation.setChainId(137, 137); /// polygon
    }

    function test_setConfig_getConfig_and_revert_invalidCaller() public {
        layerzeroImplementation.setConfig(0, 10, 6, abi.encode(CHAINLINK_lzOracle));

        bytes memory response = layerzeroImplementation.getConfig(0, 10, address(0), 6);
        assertEq(abi.encode(CHAINLINK_lzOracle), response);

        /// @dev testing revert here and not separately, to avoid making the call above twice and facing 
        /// the error, 'You cannot overwrite `prank` until it is applied at least once' otherwise
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        layerzeroImplementation.setConfig(0, 10, 6, abi.encode(CHAINLINK_lzOracle));
    }

    function test_setSendVersion_and_revert_invalidCaller() public {
        vm.expectEmit(false, false, false, true, LZ_ENDPOINT);
        emit UaSendVersionSet(address(layerzeroImplementation), 2);

        layerzeroImplementation.setSendVersion(2);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        layerzeroImplementation.setSendVersion(5);
    }

    function test_setReceiveVersion_and_revert_invalidCaller() public {
        vm.expectEmit(false, false, false, true, LZ_ENDPOINT);
        emit UaReceiveVersionSet(address(layerzeroImplementation), 2);

        layerzeroImplementation.setReceiveVersion(2);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        layerzeroImplementation.setReceiveVersion(5);
    }

    function test_forceResumeReceive_and_revert_invalidCaller() public {
        vm.expectEmit(false, false, false, true, LZ_ENDPOINT);
        emit UaForceResumeReceive(uint16(ETH), abi.encode(address(layerzeroImplementation)));

        layerzeroImplementation.forceResumeReceive(uint16(ETH), abi.encode(address(layerzeroImplementation)));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        layerzeroImplementation.forceResumeReceive(uint16(ETH), abi.encode(address(layerzeroImplementation)));
    }

    function test_setTrustedRemote_isTrustedRemote_and_revert_invalidCaller() public {
        bytes memory srcAddressOP = abi.encodePacked(getContract(OP, "LayerzeroImplementation"), address(layerzeroImplementation));
        layerzeroImplementation.setTrustedRemote(uint16(OP), srcAddressOP);

        assertEq(layerzeroImplementation.isTrustedRemote(uint16(OP), srcAddressOP), true);

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(bond);
        bytes memory srcAddressPOLY = abi.encodePacked(getContract(POLY, "LayerzeroImplementation"), address(layerzeroImplementation));
        layerzeroImplementation.setTrustedRemote(uint16(POLY), srcAddressPOLY);
    }
}
