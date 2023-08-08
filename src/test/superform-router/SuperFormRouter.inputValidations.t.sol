// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {Error} from "../../utils/Error.sol";
import "../utils/ProtocolActions.sol";

contract SuperformRouterTest is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function test_tokenEmergencyWithdraw() public {
        uint256 transferAmount = 1 * 10 ** 18; // 1 token
        address payable token = payable(getContract(ETH, "DAI"));
        address payable superFormRouter = payable(getContract(ETH, "SuperformRouter"));

        /// @dev admin transfers some ETH and DAI tokens to multi tx processor
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        uint256 balanceBefore = MockERC20(token).balanceOf(superFormRouter);
        MockERC20(token).transfer(superFormRouter, transferAmount);
        uint256 balanceAfter = MockERC20(token).balanceOf(superFormRouter);
        assertEq(balanceBefore + transferAmount, balanceAfter);

        balanceBefore = MockERC20(token).balanceOf(superFormRouter);
        SuperformRouter(superFormRouter).emergencyWithdrawToken(token, transferAmount);
        balanceAfter = MockERC20(token).balanceOf(superFormRouter);
        assertEq(balanceBefore - transferAmount, balanceAfter);
    }

    function test_emergencyNativeTokenWithdraw() public {
        uint256 transferAmount = 1e18; // 1 token
        address payable superFormRouter = payable(getContract(ETH, "SuperformRouter"));

        /// @dev admin transfers some ETH and DAI tokens to multi tx processor
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        uint256 balanceBefore = superFormRouter.balance;
        superFormRouter.call{value: transferAmount}("");
        uint256 balanceAfter = superFormRouter.balance;
        assertEq(balanceBefore + transferAmount, balanceAfter);

        balanceBefore = superFormRouter.balance;
        SuperformRouter(superFormRouter).emergencyWithdrawNativeToken(transferAmount);
        balanceAfter = superFormRouter.balance;
        assertEq(balanceBefore - transferAmount, balanceAfter);
    }

    function test_depositToInvalidFormId() public {
        /// scenario: deposit to an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        /// try depositing without approval
        address superForm = getContract(
            ETH,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superForm, FORM_BEACON_IDS[0], ARBI);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            1e18,
            100,
            LiqRequest(1, "", getContract(ETH, "USDT"), 1e18, 0, ""),
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        (address formBeacon, , ) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(formBeacon, 1e18);

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);
    }

    function test_withdrawFromInvalidFormId() public {
        /// scenario: withdraw from an invalid super form id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);

        address superForm = getContract(
            ETH,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superForm, FORM_BEACON_IDS[0], ARBI);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingleSP(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](2);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), 1e18, 0, "");
        liqReq[1] = LiqRequest(1, "", getContract(ARBI, "USDT"), 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superFormIds, amounts, maxSlippages, liqReq, "");

        SingleDirectMultiVaultStateReq memory req = SingleDirectMultiVaultStateReq(data);

        (address formBeacon, , ) = SuperformFactory(getContract(ETH, "SuperformFactory")).getSuperform(superformId);

        vm.expectRevert(Error.INVALID_CHAIN_ID.selector);
        SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectMultiVaultWithdraw(req);
    }

    function test_withdrawWithWrongLiqDataLength() public {
        /// note: unlikely scenario, deposit should fail for such cases
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superForm = getContract(
            ARBI,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superForm, FORM_BEACON_IDS[0], ARBI);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingleSP(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](2);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), 1e18, 0, "");
        liqReq[1] = LiqRequest(1, "", getContract(ARBI, "USDT"), 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superFormIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superFormRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superFormRouter)).singleXChainMultiVaultWithdraw(req);
    }

    function test_withdrawWithWrongSlippageLength() public {
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superForm = getContract(
            ARBI,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superForm, FORM_BEACON_IDS[0], ARBI);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingleSP(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](0);

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superFormIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superFormRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superFormRouter)).singleXChainMultiVaultWithdraw(req);
    }

    function test_depositWithWrongSlippageLength() public {
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superForm = getContract(
            ARBI,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superForm, FORM_BEACON_IDS[0], ARBI);

        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](0);

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superFormIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);
        address superFormRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superFormRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superFormRouter)).singleXChainMultiVaultDeposit(req);
    }

    function test_withdrawWithPausedBeacon() public {
        _pauseFormBeacon();

        /// scenario: withdraw from an paused form beacon id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);

        /// simulating deposits by just minting superPosition
        address superForm = getContract(
            ARBI,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superForm, FORM_BEACON_IDS[0], ARBI);

        vm.startPrank(getContract(ETH, "SuperformRouter"));
        SuperPositions(getContract(ETH, "SuperPositions")).mintSingleSP(deployer, superformId, 1e18);

        vm.startPrank(deployer);

        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superFormIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superFormRouter = getContract(ETH, "SuperformRouter");

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superFormRouter)).singleXChainMultiVaultWithdraw(req);
    }

    function test_depositWithPausedBeacon() public {
        _pauseFormBeacon();

        /// scenario: deposit from an paused form beacon id (which doesn't exist on the chain)
        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        address superForm = getContract(
            ARBI,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superForm, FORM_BEACON_IDS[0], ARBI);

        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e18;

        uint256[] memory maxSlippages = new uint256[](1);
        maxSlippages[0] = 100;

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;

        LiqRequest[] memory liqReq = new LiqRequest[](1);
        liqReq[0] = LiqRequest(1, "", getContract(ARBI, "USDT"), 1e18, 0, "");

        MultiVaultSFData memory data = MultiVaultSFData(superFormIds, amounts, maxSlippages, liqReq, "");

        SingleXChainMultiVaultStateReq memory req = SingleXChainMultiVaultStateReq(ambIds, ARBI, data);

        address superFormRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superFormRouter, 1e18);

        vm.expectRevert(Error.INVALID_SUPERFORMS_DATA.selector);
        SuperformRouter(payable(superFormRouter)).singleXChainMultiVaultDeposit(req);
    }

    function test_depositWithInvalidAmountThanLiqDataAmount() public {
        /// scenario: deposit from an paused form beacon id (which doesn't exist on the chain)

        address superForm = getContract(
            ARBI,
            string.concat("USDT", "VaultMock", "Superform", Strings.toString(FORM_BEACON_IDS[0]))
        );

        uint256 superformId = DataLib.packSuperform(superForm, FORM_BEACON_IDS[0], ARBI);

        vm.selectFork(FORKS[ARBI]);
        (address formBeacon, , ) = SuperformFactory(getContract(ARBI, "SuperformFactory")).getSuperform(superformId);

        vm.selectFork(FORKS[ETH]);
        vm.startPrank(deployer);

        SingleVaultSFData memory data = SingleVaultSFData(
            superformId,
            3e18,
            100,
            LiqRequest(
                1,
                _buildMaliciousTxData(
                    1,
                    getContract(ARBI, "USDT"),
                    formBeacon,
                    ARBI,
                    1e18,
                    getContract(ARBI, "CoreStateRegistry")
                ),
                getContract(ARBI, "USDT"),
                1e18,
                0,
                ""
            ),
            ""
        );

        SingleXChainSingleVaultStateReq memory req = SingleXChainSingleVaultStateReq(ambIds, ARBI, data);

        address superFormRouter = getContract(ETH, "SuperformRouter");
        /// @dev approves before call
        MockERC20(getContract(ETH, "USDT")).approve(superFormRouter, 1e18);

        vm.expectRevert(Error.INVALID_TXDATA_AMOUNTS.selector);
        SuperformRouter(payable(superFormRouter)).singleXChainSingleVaultDeposit(req);
    }

    function _buildMaliciousTxData(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        address receiver_
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
                abi.encode(from_, FORKS[toChainId_])
            );

            /// @dev empty bridge request
            bridgeRequest = ISocketRegistry.BridgeRequest(
                0, /// id
                0,
                address(0),
                abi.encode(receiver_, FORKS[toChainId_])
            );

            userRequest = ISocketRegistry.UserRequest(
                receiver_,
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
                abi.encode(from_, FORKS[toChainId_]),
                false // arbitrary
            );

            bridgeData = ILiFi.BridgeData(
                bytes32("1"), /// request id
                "",
                "",
                address(0),
                underlyingToken_,
                receiver_,
                amount_,
                uint256(toChainId_),
                false,
                true
            );

            txData = abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
        }
    }

    function _pauseFormBeacon() public {
        /// pausing form beacon id 1 from ARBI
        uint32 formBeaconId = 1;

        vm.selectFork(FORKS[ARBI]);
        vm.startPrank(deployer);

        vm.recordLogs();
        SuperformFactory(getContract(ARBI, "SuperformFactory")).changeFormBeaconPauseStatus{value: 800 ether}(
            formBeaconId,
            true,
            generateBroadcastParams(5, 2)
        );

        _broadcastPayloadHelper(ARBI, vm.getRecordedLogs());

        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] != ARBI) {
                vm.selectFork(FORKS[chainIds[i]]);

                bool statusBefore = SuperformFactory(getContract(chainIds[i], "SuperformFactory")).isFormBeaconPaused(
                    formBeaconId
                );
                FactoryStateRegistry(payable(getContract(chainIds[i], "FactoryStateRegistry"))).processPayload(1, "");
                bool statusAfter = SuperformFactory(getContract(chainIds[i], "SuperformFactory")).isFormBeaconPaused(
                    formBeaconId
                );

                /// @dev assert status update before and after processing the payload
                assertEq(statusBefore, false);
                assertEq(statusAfter, true);
            }
        }
    }
}
