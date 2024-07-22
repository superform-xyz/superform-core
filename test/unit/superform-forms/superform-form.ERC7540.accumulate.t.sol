// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/ProtocolActions.sol";
import "src/libraries/DataLib.sol";

contract SuperformERC7540AccumulationTest is ProtocolActions {
    function setUp() public override {
        chainIds = [BSC_TESTNET, SEPOLIA];
        LAUNCH_TESTNETS = true;

        AMBs = [2, 5];
        super.setUp();
    }

    function test_7540AccumulateXChain() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId);

        _performSameChainDeposit(dstChainId, user, depositAmount, superformId);
        _performCrossChainDeposit(srcChainId, dstChainId, user, depositAmount, superformId);

        _processCrossChainDeposit(dstChainId);

        _checkAndClaimAccumulatedAmounts(
            dstChainId,
            srcChainId,
            getContract(dstChainId, string.concat("tUSDERC7540FullyAsyncMockSuperform5")),
            user,
            superformId,
            true
        );
    }

    function test_7540AccumulateSameChain() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId);

        _performCrossChainDeposit(srcChainId, dstChainId, user, depositAmount, superformId);
        _processCrossChainDeposit(dstChainId);

        _performSameChainDeposit(dstChainId, user, depositAmount, superformId);

        _checkAndClaimAccumulatedAmounts(
            dstChainId,
            srcChainId,
            getContract(dstChainId, string.concat("tUSDERC7540FullyAsyncMockSuperform5")),
            user,
            superformId,
            false
        );
    }

    function test_7540AccumulateOnlySameChain() external {
        uint64 srcChainId = BSC_TESTNET;
        uint64 dstChainId = SEPOLIA;

        address user = users[0];
        uint256 depositAmount = 1e18;
        uint256 superformId = _getSuperformId(dstChainId);

        _performSameChainDeposit(dstChainId, user, depositAmount, superformId);
        _performSameChainDeposit(dstChainId, user, depositAmount, superformId);

        _checkAndClaimAccumulatedAmounts(
            dstChainId,
            srcChainId,
            getContract(dstChainId, string.concat("tUSDERC7540FullyAsyncMockSuperform5")),
            user,
            superformId,
            false
        );
    }

    function _getSuperformId(uint64 dstChainId) internal view returns (uint256) {
        address superform = getContract(dstChainId, string.concat("tUSDERC7540FullyAsyncMockSuperform5"));
        uint256 superformId = DataLib.packSuperform(superform, uint32(5), dstChainId);
        return superformId;
    }

    function _performSameChainDeposit(
        uint64 dstChainId,
        address user,
        uint256 depositAmount,
        uint256 superformId
    )
        internal
    {
        vm.selectFork(FORKS[dstChainId]);
        vm.startPrank(user);

        address dstSuperformRouter = getContract(dstChainId, "SuperformRouter");
        MockERC20(getContract(dstChainId, "tUSD")).approve(dstSuperformRouter, depositAmount);

        SuperformRouter(payable(dstSuperformRouter)).singleDirectSingleVaultDeposit(
            SingleDirectSingleVaultStateReq(
                SingleVaultSFData(
                    superformId,
                    depositAmount,
                    depositAmount,
                    100,
                    LiqRequest(bytes(""), getContract(dstChainId, "tUSD"), address(0), 0, dstChainId, 0),
                    bytes(""),
                    false,
                    false,
                    user,
                    user,
                    abi.encode(superformId, new uint8[](0))
                )
            )
        );

        vm.stopPrank();
    }

    struct LocalVars {
        address srcSuperformRouter;
        uint8[] ambIds;
        bytes[] extraFormData;
    }

    function _performCrossChainDeposit(
        uint64 srcChainId,
        uint64 dstChainId,
        address user,
        uint256 depositAmount,
        uint256 superformId
    )
        internal
    {
        LocalVars memory v;

        vm.selectFork(FORKS[srcChainId]);
        vm.startPrank(user);

        v.srcSuperformRouter = getContract(srcChainId, "SuperformRouter");
        v.ambIds = new uint8[](2);
        v.ambIds[0] = 2;
        v.ambIds[1] = 5;

        MockERC20(getContract(srcChainId, "DAI")).approve(v.srcSuperformRouter, depositAmount);
        vm.recordLogs();

        v.extraFormData = new bytes[](1);
        v.extraFormData[0] = abi.encode(superformId, abi.encode(v.ambIds));

        SuperformRouter(payable(v.srcSuperformRouter)).singleXChainSingleVaultDeposit{ value: 0.5 ether }(
            SingleXChainSingleVaultStateReq(
                v.ambIds,
                dstChainId,
                SingleVaultSFData(
                    superformId,
                    depositAmount,
                    depositAmount,
                    100,
                    _createLiqRequest(srcChainId, dstChainId, depositAmount, user),
                    bytes(""),
                    false,
                    false,
                    user,
                    user,
                    abi.encode(1, v.extraFormData)
                )
            )
        );
        vm.stopPrank();

        _payloadDeliveryHelper(dstChainId, srcChainId, vm.getRecordedLogs());
    }

    function _createLiqRequest(
        uint64 srcChainId,
        uint64 dstChainId,
        uint256 depositAmount,
        address user
    )
        internal
        view
        returns (LiqRequest memory)
    {
        return LiqRequest(
            abi.encodeWithSelector(
                DeBridgeMock.createSaltedOrder.selector,
                DlnOrderLib.OrderCreation(
                    getContract(srcChainId, "DAI"),
                    depositAmount,
                    abi.encodePacked(getContract(dstChainId, "tUSD")),
                    depositAmount,
                    uint256(dstChainId),
                    abi.encodePacked(getContract(dstChainId, "CoreStateRegistry")),
                    address(user),
                    abi.encodePacked(deployer),
                    bytes(""),
                    bytes(""),
                    abi.encodePacked(user)
                ),
                uint64(block.timestamp),
                bytes(""),
                uint32(0),
                bytes(""),
                abi.encode(user, FORKS[srcChainId], FORKS[dstChainId])
            ),
            getContract(srcChainId, "DAI"),
            address(0),
            7,
            dstChainId,
            0
        );
    }

    function _processCrossChainDeposit(uint64 dstChainId) internal {
        vm.selectFork(FORKS[dstChainId]);
        address csr = getContract(dstChainId, "CoreStateRegistry");

        address[] memory finalTokens = new address[](1);
        finalTokens[0] = getContract(dstChainId, "tUSD");

        uint256[] memory finalAmounts = new uint256[](1);
        finalAmounts[0] = MockERC20(finalTokens[0]).balanceOf(csr);

        vm.prank(deployer);
        CoreStateRegistry(csr).updateDepositPayload(1, finalTokens, finalAmounts);

        vm.prank(deployer);
        CoreStateRegistry(csr).processPayload(1);
    }

    function _checkAndClaimAccumulatedAmounts(
        uint64 dstChainId,
        uint64 srcChainId,
        address superform,
        address user,
        uint256 superformId,
        bool xChain
    )
        internal
    {
        vm.selectFork(FORKS[dstChainId]);

        address vault = IBaseForm(superform).getVaultAddress();
        address investmentManager = ERC7540VaultLike(vault).manager();
        address asset = IBaseForm(superform).getVaultAsset();

        _authorizeOperator(superform, 0);

        vm.startPrank(InvestmentManagerLike(investmentManager).root());
        _fulfillDepositRequest(investmentManager, vault, asset, 2e18, user);
        vm.stopPrank();

        vm.startPrank(deployer);
        vm.recordLogs();
        AsyncStateRegistry(getContract(dstChainId, "AsyncStateRegistry")).claimAvailableDeposits{ value: 0.5 ether }(
            ClaimAvailableDepositsArgs(user, superformId)
        );
        vm.stopPrank();

        if (xChain) {
            _payloadDeliveryHelper(srcChainId, dstChainId, vm.getRecordedLogs());

            vm.selectFork(FORKS[srcChainId]);
            vm.startPrank(deployer);
            AsyncStateRegistry(getContract(srcChainId, "AsyncStateRegistry")).processPayload(1);
            vm.stopPrank();
        }
    }
}
