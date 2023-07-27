// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {LayerZeroHelper} from "pigeon/src/layerzero/LayerZeroHelper.sol";
import "pigeon/src/layerzero/lib/LZPacket.sol";

import "../utils/BaseSetup.sol";
import "../../libraries/DataLib.sol";
import "../../types/DataTypes.sol";

import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {CoreStateRegistry} from "../../crosschain-data/extensions/CoreStateRegistry.sol";
import {LayerzeroImplementation} from "../../crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";

contract LayerZeroImplementationRevampTest is BaseSetup {
    ISuperRegistry public superRegistry;
    address public bond;

    function setUp() public override {
        super.setUp();
        vm.selectFork(FORKS[ETH]);

        superRegistry = ISuperRegistry(getContract(ETH, "SuperRegistry"));
        bond = getContract(ETH, "CoreStateRegistry");

        vm.deal(bond, 1 ether);
    }

    function test_fafafafafa() public {
        address payable lzImplementation = payable(superRegistry.getAmbAddress(1));
        bytes memory crossChainMsg = abi.encode(AMBMessage(DataLib.packTxInfo(0, 1, 1, 1, deployer, ETH), bytes("")));

        _setResetCoreStateRegistry(FORKS[OP], false);

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(bond);

        vm.recordLogs();
        LayerzeroImplementation(lzImplementation).dispatchPayload{value: 1 ether}(bond, OP, crossChainMsg, bytes(""));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        vm.stopPrank();

        /// @dev payload will fail in _nonblockLzReceive
        LayerZeroHelper(getContract(ETH, "LayerZeroHelper")).help(
            LZ_ENDPOINTS[OP],
            500000, /// note: using `0` to get the payload stored
            FORKS[OP],
            logs
        );

        _setResetCoreStateRegistry(FORKS[OP], true);

        bytes memory payload;
        for (uint256 i; i < logs.length; i++) {
            Vm.Log memory log = logs[i];

            if (log.topics[0] == 0xe9bded5f24a4168e4f3bf44e00298c993b22376aad8c58c7dda9718a54cbea82) {
                bytes memory _data = abi.decode(log.data, (bytes));
                LayerZeroPacket.Packet memory _packet = LayerZeroPacket.getPacket(_data);
                payload = _packet.payload;
            }
        }

        bytes memory srcAddressOP = abi.encodePacked(
            getContract(ETH, "LayerzeroImplementation"),
            getContract(OP, "LayerzeroImplementation")
        );

        LayerzeroImplementation(lzImplementation).retryMessage(101, srcAddressOP, 2, payload);
    }

    function _setResetCoreStateRegistry(uint256 forkId, bool isReset) internal {
        vm.selectFork(forkId);
        vm.startPrank(deployer);

        uint8[] memory registryId_ = new uint8[](1);
        registryId_[0] = 1;

        address[] memory registryAddress_ = new address[](1);
        registryAddress_[0] = isReset ? getContract(OP, "CoreStateRegistry") : address(1);
        superRegistry.setStateRegistryAddress(registryId_, registryAddress_);
    }
}
