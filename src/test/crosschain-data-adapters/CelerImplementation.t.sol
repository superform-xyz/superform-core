// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "../utils/BaseSetup.sol";
import {TransactionType, CallbackType, AMBMessage} from "../../types/DataTypes.sol";
import {DataLib} from "../../libraries/DataLib.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {CelerImplementation} from "../../crosschain-data/adapters/celer/CelerImplementation.sol";
import {CoreStateRegistry} from "../../crosschain-data/extensions/CoreStateRegistry.sol";

contract CelerImplementationTest is BaseSetup {
    /// @dev event emitted from CelerMessageBus on ETH (CELER_BUS)
    event Message(address indexed sender, address receiver, uint256 dstChainId, bytes message, uint256 fee);

    address public constant CELER_BUS = 0x4066D196A423b2b3B8B054f4F40efB47a74E200C;
    uint64 internal chainId = ETH;
    ISuperRegistry public superRegistry;
    CelerImplementation celerImplementation;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        superRegistry = ISuperRegistry(getContract(chainId, "SuperRegistry"));
        celerImplementation = CelerImplementation(payable(superRegistry.getAmbAddress(3)));
        vm.startPrank(deployer);
    }

    function test_setCelerBus() public {
        celerImplementation.setCelerBus(CELER_BUS);
        assertEq(address(celerImplementation.messageBus()), CELER_BUS);
    }

    function test_setReceiver() public {
        celerImplementation.setReceiver(10, getContract(10, "CelerImplementation")); /// optimism
        celerImplementation.setReceiver(137, getContract(137, "CelerImplementation")); /// polygon

        assertEq(celerImplementation.authorizedImpl(10), getContract(10, "CelerImplementation"));
        assertEq(celerImplementation.authorizedImpl(137), getContract(137, "CelerImplementation"));
    }

    function test_setChainId() public {
        celerImplementation.setChainId(10, 10); /// optimism
        celerImplementation.setChainId(137, 137); /// polygon

        assertEq(celerImplementation.ambChainId(10), 10);
        assertEq(celerImplementation.superChainId(137), 137);
    }

    function test_broadcastPayload() public {
        /// @dev need to call setCelerBus(), setReceiver(), setChainId() before calling broadcastPayload(), 
        /// but we don't need to, as it's already done in BaseSetup

        AMBMessage memory ambMessage = AMBMessage(
            DataLib.packTxInfo(
                uint8(TransactionType.DEPOSIT), /// @dev TransactionType
                uint8(CallbackType.INIT),
                0, /// @dev isMultiVaults
                1, /// @dev STATE_REGISTRY_TYPE,
                users[0], /// @dev srcSender,
                chainId /// @dev srcChainId
            ),
            "" /// ambData
        );

        /// @dev gasFees for chainIds = [56, 43114, 137, 42161, 10]; 
        /// @dev excluding chainId = 1 as no point broadcasting to same chain
        uint256[] memory gasPerDst = new uint256[](5);
        for (uint i = 0; i < gasPerDst.length; i++) {
            gasPerDst[i] = 0.1 ether;
        }

        /// @dev keeping extraDataPerDst empty for now
        bytes[] memory extraDataPerDst = new bytes[](5);

        BroadCastAMBExtraData memory ambExtraData = BroadCastAMBExtraData(
          gasPerDst,
          extraDataPerDst
        );

        address coreStateRegistry = getContract(1, "CoreStateRegistry");
        /// @dev bcoz we're simulating celerImplementation.broadcastPayload() from CoreStateRegistry (below),
        /// we need sufficient ETH in CoreStateRegistry and CelerImplementation. On mainnet, these funds will 
        /// come from the user via SuperFormRouter
        vm.deal(coreStateRegistry, 10 ether);
        vm.deal(address(celerImplementation), 10 ether);

        /// @dev need to stop unused deployer prank, to use new prank, AND changePrank() doesn't work smh
        vm.stopPrank();

        /// @dev only checking topic1 as it is the only one indexed in the Message event
        vm.expectEmit(true, false, false, true, CELER_BUS);

        /// @dev chainIds = [1, 56, 43114, 137, 42161, 10]; 
        for (uint i = 1; i < chainIds.length; i++) {
            emit Message(
                address(celerImplementation),
                celerImplementation.authorizedImpl(chainIds[i]),
                chainIds[i],
                abi.encode(ambMessage),
                0.1 ether
            );
        }

        vm.prank(coreStateRegistry);
        celerImplementation.broadcastPayload{value: 0.1 ether}(users[0], abi.encode(ambMessage), abi.encode(ambExtraData));
    }

}
