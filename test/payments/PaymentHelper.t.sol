// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {Error} from "src/utils/Error.sol";
import "../utils/ProtocolActions.sol";

contract PaymentHelperTest is BaseSetup {
    PaymentHelper public paymentHelper;
    address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[ETH]);
        paymentHelper = PaymentHelper(getContract(ETH, "PaymentHelper"));
    }

    function test_estimateSingleDirectSingleVault() public {
        /// @dev scenario: single vault withdrawal involving timelock
        /// expected fees to be greater than zero
        bytes memory emptyBytes;
        (, , , uint256 fees) = paymentHelper.estimateSingleDirectSingleVault(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    _generateSuperformPackWithShift(), /// timelock
                    420,
                    420,
                    LiqRequest(1, emptyBytes, address(0), 420, 420, emptyBytes),
                    emptyBytes
                )
            ),
            false
        );

        assertGt(fees, 0);
    }

    function test_estimateSingleDirectMultiVault() public {
        /// @dev scenario: single vault withdrawal involving timelock
        /// expected fees to be greater than zero
        bytes memory emptyBytes;
        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = _generateSuperformPackWithShift();

        uint256[] memory uint256MemoryArray = new uint256[](1);
        uint256MemoryArray[0] = 420;

        LiqRequest[] memory liqRequestMemoryArray = new LiqRequest[](1);
        liqRequestMemoryArray[0] = LiqRequest(1, emptyBytes, address(0), 420, 420, emptyBytes);

        (, , , uint256 fees) = paymentHelper.estimateSingleDirectMultiVault(
            SingleDirectMultiVaultStateReq(
                MultiVaultSFData(
                    superFormIds, /// timelock
                    uint256MemoryArray,
                    uint256MemoryArray,
                    liqRequestMemoryArray,
                    emptyBytes
                )
            ),
            false
        );

        assertGt(fees, 0);
    }

    function test_ifZeroIsReturnedWhenDstValueIsZero() public {
        /// @dev scenario: single vault withdrawal involving timelock
        /// expected fees to be greater than zero

        /// step 1: setSrcNativePriceOracle to address(0)
        vm.prank(deployer);
        vm.selectFork(FORKS[ETH]);
        paymentHelper.setSameChainConfig(1, abi.encode(address(0)));

        /// step 2: estimate fees
        bytes memory emptyBytes;
        bytes memory txData = _buildTxData(1, native, getContract(ETH, "CoreStateRegistry"), ETH, 1e18);

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        (, , uint256 fees, ) = paymentHelper.estimateSingleXChainSingleVault(
            SingleXChainSingleVaultStateReq(
                ambIds,
                137,
                SingleVaultSFData(
                    _generateSuperformPackWithShift(), /// timelock
                    420,
                    420,
                    LiqRequest(1, txData, address(0), 420, 420, emptyBytes),
                    emptyBytes
                )
            ),
            true
        );

        assertEq(fees, 0);
    }

    function test_setSameChainConfig() public {
        /// set config type: 1
        vm.prank(deployer);
        paymentHelper.setSameChainConfig(1, abi.encode(address(420)));

        address result1 = address(paymentHelper.srcNativeFeedOracle());
        assertEq(result1, address(420));

        /// set config type: 2
        vm.prank(deployer);
        paymentHelper.setSameChainConfig(2, abi.encode(address(421)));

        address result2 = address(paymentHelper.srcGasPriceOracle());
        assertEq(result2, address(421));

        /// set config type: 3
        vm.prank(deployer);
        paymentHelper.setSameChainConfig(3, abi.encode(422));

        uint256 result3 = paymentHelper.ackNativeGasCost();
        assertEq(result3, 422);

        /// set config type: 4
        vm.prank(deployer);
        paymentHelper.setSameChainConfig(4, abi.encode(423));

        uint256 result4 = paymentHelper.twoStepFeeCost();
        assertEq(result4, 423);

        /// set config type: 5
        vm.prank(deployer);
        paymentHelper.setSameChainConfig(5, abi.encode(424));

        uint256 result5 = paymentHelper.srcNativePrice();
        assertEq(result5, 424);

        /// set config type: 6
        vm.prank(deployer);
        paymentHelper.setSameChainConfig(6, abi.encode(425));

        uint256 result6 = paymentHelper.srcGasPrice();
        assertEq(result6, 425);
    }

    function test_addChain() public {
        vm.prank(deployer);
        paymentHelper.addChain(420, address(420), address(421), 422, 423, 424, 425, 426, 427, 428);
    }

    function test_setDstChainConfig() public {
        /// chain id used: 420

        /// set config type: 1
        vm.prank(deployer);
        paymentHelper.setDstChainConfig(420, 1, abi.encode(address(420)));

        address result1 = address(paymentHelper.dstNativeFeedOracle(420));
        assertEq(result1, address(420));

        /// set config type: 2
        vm.prank(deployer);
        paymentHelper.setDstChainConfig(420, 2, abi.encode(address(421)));

        address result2 = address(paymentHelper.dstGasPriceOracle(420));
        assertEq(result2, address(421));

        /// set config type: 3
        vm.prank(deployer);
        paymentHelper.setDstChainConfig(420, 3, abi.encode(422));

        uint256 result3 = paymentHelper.swapGasUsed(420);
        assertEq(result3, 422);

        /// set config type: 4
        vm.prank(deployer);
        paymentHelper.setDstChainConfig(420, 4, abi.encode(423));

        uint256 result4 = paymentHelper.updateGasUsed(420);
        assertEq(result4, 423);

        /// set config type: 5
        vm.prank(deployer);
        paymentHelper.setDstChainConfig(420, 5, abi.encode(424));

        uint256 result5 = paymentHelper.depositGasUsed(420);
        assertEq(result5, 424);

        /// set config type: 6
        vm.prank(deployer);
        paymentHelper.setDstChainConfig(420, 6, abi.encode(425));

        uint256 result6 = paymentHelper.withdrawGasUsed(420);
        assertEq(result6, 425);

        /// set config type: 7
        vm.prank(deployer);
        paymentHelper.setDstChainConfig(420, 7, abi.encode(426));

        uint256 result7 = paymentHelper.dstNativePrice(420);
        assertEq(result7, 426);

        /// set config type: 8
        vm.prank(deployer);
        paymentHelper.setDstChainConfig(420, 8, abi.encode(427));

        uint256 result8 = paymentHelper.dstGasPrice(420);
        assertEq(result8, 427);

        /// set config type: 8
        vm.prank(deployer);
        paymentHelper.setDstChainConfig(420, 9, abi.encode(428));

        uint256 result9 = paymentHelper.dstGasPerKB(420);
        assertEq(result9, 428);
    }

    function _generateSuperformPackWithShift() internal pure returns (uint256 superformId_) {
        address superform_ = address(111);
        uint32 formBeaconId_ = 1;
        uint64 chainId_ = 1;

        superformId_ = uint256(uint160(superform_));
        superformId_ |= uint256(formBeaconId_) << 160;
        superformId_ |= uint256(chainId_) << 192;
    }

    function _buildTxData(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address from_,
        uint64 toChainId_,
        uint256 amount_
    ) internal returns (bytes memory txData) {
        if (liqBridgeKind_ == 1) {
            ISocketRegistry.BridgeRequest memory bridgeRequest;
            ISocketRegistry.MiddlewareRequest memory middlewareRequest;
            ISocketRegistry.UserRequest memory userRequest;
            /// @dev middlware request is used if there is a swap involved before the bridging action
            /// @dev the input token should be the token the user deposits, which will be swapped to the input token of bridging request
            middlewareRequest = ISocketRegistry.MiddlewareRequest(
                1, /// request id
                0,
                underlyingToken_,
                abi.encode(getContract(toChainId_, "MultiTxProcessor"), FORKS[toChainId_], underlyingToken_)
            );

            /// @dev empty bridge request
            bridgeRequest = ISocketRegistry.BridgeRequest(
                0, /// id
                0,
                underlyingToken_,
                abi.encode(getContract(toChainId_, "MultiTxProcessor"), FORKS[toChainId_], underlyingToken_)
            );

            userRequest = ISocketRegistry.UserRequest(
                getContract(toChainId_, "CoreStateRegistry"),
                uint256(toChainId_),
                amount_,
                middlewareRequest,
                bridgeRequest
            );

            txData = abi.encodeWithSelector(SocketRouterMock.outboundTransferTo.selector, userRequest);
        } else if (liqBridgeKind_ == 2) {
            ILiFi.BridgeData memory bridgeData;
            ILiFi.SwapData[] memory swapData = new ILiFi.SwapData[](1);

            swapData[0] = ILiFi.SwapData(
                address(0), /// callTo (arbitrary)
                address(0), /// callTo (approveTo)
                underlyingToken_,
                underlyingToken_,
                amount_,
                abi.encode(from_, FORKS[toChainId_], underlyingToken_),
                false // arbitrary
            );

            bridgeData = ILiFi.BridgeData(
                bytes32("1"), /// request id
                "",
                "",
                address(0),
                underlyingToken_,
                getContract(toChainId_, "CoreStateRegistry"),
                amount_,
                uint256(toChainId_),
                false,
                true
            );

            txData = abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
        }
    }
}
