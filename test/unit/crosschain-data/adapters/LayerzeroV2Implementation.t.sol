// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../../../utils/BaseSetup.sol";

import "src/crosschain-data/adapters/layerzero-v2/LayerzeroV2Implementation.sol";
import "src/interfaces/ISuperRegistry.sol";
import "src/types/DataTypes.sol";

contract LayerzeroV2ImplementationTest is BaseSetup {
    LayerzeroV2Implementation layerzeroImpl;
    ISuperRegistry superRegistry;

    address lzEndpoint;
    address stateRegistry;
    address nonAdmin = address(2);

    uint64 chainId = ETH;
    uint32 eid = 30101;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[POLY]);
        superRegistry = ISuperRegistry(getContract(POLY, "SuperRegistry"));
        layerzeroImpl = LayerzeroV2Implementation(getContract(POLY, "LayerzeroV2Implementation"));
        stateRegistry = getContract(POLY, "CoreStateRegistry");
        lzEndpoint = lzV2Endpoint;
    }

    function testSetChainIdInvalidChainId() public {
        vm.prank(deployer);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        layerzeroImpl.setChainId(0, 0);
    }

    function testSetChainIdExistingChainId() public {
        vm.prank(deployer);
        layerzeroImpl.setChainId(chainId, 301001);
    }
    
    function testSetChainIdExistingAmbChainId() public {
        vm.prank(deployer);
        layerzeroImpl.setChainId(chainId, 30101);
    }

    function testSetPeer() public {
        bytes32 peer = bytes32(uint256(uint160(1)));

        vm.prank(deployer);
        layerzeroImpl.setPeer(eid, peer);
        assertEq(layerzeroImpl.peers(eid), peer);
    }

    function testSetPeerNotProtocolAdmin() public {
        bytes32 peer = bytes32(uint256(uint160(420)));

        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        layerzeroImpl.setPeer(eid, peer);
    }

    function testSetLzEndpointReverts() public {
        vm.selectFork(FORKS[ETH]);

        address newEndpoint = address(5);

        vm.prank(deployer);
        vm.expectRevert(LayerzeroV2Implementation.ENDPOINT_EXISTS.selector);
        layerzeroImpl.setLzEndpoint(newEndpoint);
    }

    function testSetDelegate() public {
        address delegate = address(6);

        vm.expectEmit(false, false, false, true);
        emit LayerzeroV2Implementation.DelegateUpdated(delegate);
        
        layerzeroImpl.endpoint();
        vm.prank(deployer);
        layerzeroImpl.setDelegate(delegate);
    }

    function testSetDelegateEndpointNotSet() public {
        LayerzeroV2Implementation newImpl = new LayerzeroV2Implementation(superRegistry);

        vm.expectRevert(LayerzeroV2Implementation.ENDPOINT_NOT_SET.selector);
        vm.prank(deployer);
        newImpl.setDelegate(address(6));
    }

    function testDispatchPayload() public {
        uint128 gas = 200_000;

        bytes memory message = abi.encode(AMBMessage(DataLib.packTxInfo(0, 0, 0, 0, address(0), 0), new bytes(0)));
        
        bytes memory optionEncoded = layerzeroImpl.generateExtraData(gas);
        uint256 fees = layerzeroImpl.estimateFees(chainId, message, optionEncoded);

        vm.deal(stateRegistry, fees);
        vm.prank(stateRegistry);
        layerzeroImpl.dispatchPayload{value: fees}(stateRegistry, chainId, message, optionEncoded);
    }

    function testEstimateFees() public {
        uint256 gas = 200_000;
        bytes memory optionEncoded = layerzeroImpl.generateExtraData(gas);
        bytes memory message = abi.encode(AMBMessage(DataLib.packTxInfo(0, 0, 0, 0, address(0), 0), new bytes(0)));
        uint256 fees = layerzeroImpl.estimateFees(chainId, message, optionEncoded);
        assertGt(fees, 0);
    }

    function testGenerateExtraData() public {
        uint256 gasLimit = 100000;
        bytes memory extraData = layerzeroImpl.generateExtraData(gasLimit);

        /// 2 bytes for type 
        /// 32 bytes for gas limit
        assertEq(extraData.length, 34);
    }

    function testLzReceive() public {
        bytes memory message = abi.encode(AMBMessage(DataLib.packTxInfo(0, 0, 0, 1, address(0), 0), abi.encode(bytes32(0))));
        bytes32 guid = bytes32(uint256(1));
        Origin memory origin = Origin(eid, bytes32(uint256(uint160(address(layerzeroImpl)))), 0);
        vm.mockCall(
            address(superRegistry),
            abi.encodeWithSelector(superRegistry.getStateRegistry.selector, 0),
            abi.encode(stateRegistry)
        );

        vm.prank(lzEndpoint);
        layerzeroImpl.lzReceive(origin, guid, message, address(0), bytes(""));
    }

    function testLzReceiveAmbMessage() public {
        bytes memory message = abi.encode(AMBMessage(DataLib.packTxInfo(0, 0, 0, 1, address(0), 0), abi.encode(new uint8[](0), "")));
        bytes32 guid = bytes32(uint256(1));
        Origin memory origin = Origin(eid, bytes32(uint256(uint160(address(layerzeroImpl)))), 0);
        vm.mockCall(
            address(superRegistry),
            abi.encodeWithSelector(superRegistry.getStateRegistry.selector, 0),
            abi.encode(stateRegistry)
        );

        vm.prank(lzEndpoint);
        layerzeroImpl.lzReceive(origin, guid, message, address(0), bytes(""));
    }

    function testRevertSetLzEndpointZeroAddress() public {
        LayerzeroV2Implementation newImpl = new LayerzeroV2Implementation(superRegistry);

        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        vm.prank(deployer);
        newImpl.setLzEndpoint(address(0));
    }

    function testRevertSetLzEndpointNotProtocolAdmin() public {
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(nonAdmin);
        layerzeroImpl.setLzEndpoint(address(5));
    }

    function testRevertSetDelegateZeroAddress() public {
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        vm.prank(deployer);
        layerzeroImpl.setDelegate(address(0));
    }

    function testRevertSetDelegateNotProtocolAdmin() public {
        vm.expectRevert(Error.NOT_PROTOCOL_ADMIN.selector);
        vm.prank(nonAdmin);
        layerzeroImpl.setDelegate(address(6));
    }

    function testRevertDispatchPayloadNotStateRegistry() public {
        bytes memory message = abi.encode(AMBMessage(DataLib.packTxInfo(0, 0, 0, 0, address(0), 0), new bytes(0)));
        bytes memory extraData = abi.encode(bytes(""), MessagingFee(0, 0));
        vm.expectRevert(Error.NOT_STATE_REGISTRY.selector);
        vm.prank(nonAdmin);
        layerzeroImpl.dispatchPayload(address(0), chainId, message, extraData);
    }

    function testRevertDispatchPayloadInvalidChainId() public {
        bytes memory message = abi.encode(AMBMessage(DataLib.packTxInfo(0, 0, 0, 0, address(0), 0), new bytes(0)));
        bytes memory extraData = abi.encode(bytes(""), MessagingFee(0, 0));
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        vm.prank(stateRegistry);
        layerzeroImpl.dispatchPayload(address(0), 2, message, extraData);
    }

    function testRevertEstimateFeesInvalidChainId() public {
        bytes memory message = abi.encode(AMBMessage(DataLib.packTxInfo(0, 0, 0, 0, address(0), 0), new bytes(0)));
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        layerzeroImpl.estimateFees(2, message, bytes(""));
    }

    function testRevertLzReceiveInvalidChainId() public { 
        vm.prank(deployer);
        layerzeroImpl.setPeer(102, bytes32(uint256(uint160(address(layerzeroImpl)))));

        bytes memory message = abi.encode(AMBMessage(DataLib.packTxInfo(0, 0, 0, 1, address(0), 0), abi.encode(bytes32(0))));
        bytes32 guid = bytes32(uint256(1));
        Origin memory origin = Origin(102, bytes32(uint256(uint160(address(layerzeroImpl)))), 0);
        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        vm.prank(lzEndpoint);
        layerzeroImpl.lzReceive(origin, guid, message, address(0), bytes(""));
    }

    function testRevertLzReceiveDuplicatePayload() public {
        bytes memory message = abi.encode(AMBMessage(DataLib.packTxInfo(0, 0, 0, 1, address(0), 0), abi.encode(bytes32(0))));
        bytes32 guid = bytes32(uint256(1));
        Origin memory origin = Origin(eid, bytes32(uint256(uint160(address(layerzeroImpl)))), 0);
        vm.mockCall(
            address(superRegistry),
            abi.encodeWithSelector(superRegistry.getStateRegistry.selector, 0),
            abi.encode(stateRegistry)
        );
        vm.prank(lzEndpoint);
        layerzeroImpl.lzReceive(origin, guid, message, address(0), bytes(""));
        
        vm.expectRevert(Error.DUPLICATE_PAYLOAD.selector);
        vm.prank(lzEndpoint);
        layerzeroImpl.lzReceive(origin, guid, message, address(0), bytes(""));
    }
}