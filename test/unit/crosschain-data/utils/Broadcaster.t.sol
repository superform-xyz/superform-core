// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

// import "test/utils/BaseSetup.sol";
// import { TransactionType, CallbackType, AMBMessage } from "src/types/DataTypes.sol";
// import { DataLib } from "src/libraries/DataLib.sol";
// import { FactoryStateRegistry } from "src/crosschain-data/extensions/FactoryStateRegistry.sol";
// import { Error } from "src/utils/Error.sol";

// contract BroadcasterTest is BaseSetup {
//     FactoryStateRegistry public factoryStateRegistry;
//     address public bond;

//     function setUp() public override {
//         super.setUp();

//         vm.selectFork(FORKS[ETH]);
//         factoryStateRegistry = FactoryStateRegistry(payable(getContract(ETH, "FactoryStateRegistry")));

//         /// @dev malicious caller
//         bond = address(7);
//         /// @dev (who's a brokie)
//         vm.deal(bond, 1 ether);
//     }

//     function test_callBroadcastUsingInvalidAmbId() public {
//         vm.selectFork(FORKS[ETH]);

//         uint8[] memory ambIds = new uint8[](1);
//         ambIds[0] = 9;

//         uint256[] memory gasPerAMB = new uint256[](1);
//         bytes[] memory extraDataPerAMB = new bytes[](1);

//         vm.expectRevert(Error.INVALID_BRIDGE_ID.selector);
//         vm.prank(getContract(ETH, "SuperformFactory"));
//         factoryStateRegistry.broadcastPayload(
//             bond, ambIds, abi.encode(420), abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB))
//         );
//     }

//     function test_callBroadcastUsingInvalidProofAmbId() public {
//         vm.selectFork(FORKS[ETH]);

//         uint8[] memory ambIds = new uint8[](2);
//         ambIds[0] = 2;
//         ambIds[1] = 2;

//         uint256[] memory gasPerDst = new uint256[](5);
//         gasPerDst[0] = 1 wei;
//         gasPerDst[1] = 1 wei;
//         gasPerDst[2] = 1 wei;
//         gasPerDst[3] = 1 wei;
//         gasPerDst[4] = 1 wei;

//         bytes[] memory extraDataPerDst = new bytes[](5);

//         uint256[] memory gasPerAMB = new uint256[](2);
//         gasPerAMB[0] = 5 wei;
//         gasPerAMB[1] = 5 wei;

//         bytes[] memory extraDataPerAMB = new bytes[](2);

//         extraDataPerAMB[0] = abi.encode(BroadCastAMBExtraData(gasPerDst, extraDataPerDst));
//         extraDataPerAMB[1] = abi.encode(BroadCastAMBExtraData(gasPerDst, extraDataPerDst));

//         vm.expectRevert(Error.INVALID_PROOF_BRIDGE_ID.selector);
//         vm.prank(getContract(ETH, "SuperformFactory"));
//         vm.deal(getContract(ETH, "SuperformFactory"), 10 wei);

//         factoryStateRegistry.broadcastPayload{ value: 10 wei }(
//             bond,
//             ambIds,
//             abi.encode(AMBMessage(420, bytes("whatif"))),
//             abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB))
//         );

//         ambIds[1] = 9;
//         vm.expectRevert(Error.INVALID_BRIDGE_ID.selector);
//         vm.prank(getContract(ETH, "SuperformFactory"));
//         vm.deal(getContract(ETH, "SuperformFactory"), 10 wei);

//         factoryStateRegistry.broadcastPayload{ value: 10 wei }(
//             bond,
//             ambIds,
//             abi.encode(AMBMessage(420, bytes("whatif"))),
//             abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB))
//         );
//     }
// }
