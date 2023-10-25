/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "./BaseSetup.sol";
import { ILiFi } from "src/vendor/lifi/ILiFi.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
import { ISocketRegistry } from "src/vendor/socket/ISocketRegistry.sol";

import { LiFiMock } from "../mocks/LiFiMock.sol";
import { SocketMock } from "../mocks/SocketMock.sol";
import { SocketOneInchMock } from "../mocks/SocketOneInchMock.sol";

abstract contract CommonProtocolActions is BaseSetup {
    /// @dev percentage of total slippage that is used for dstSwap
    uint256 MULTI_TX_SLIPPAGE_SHARE;
    /// out of 10000
    int256 totalSlippage = 200;

    struct LiqBridgeTxDataArgs {
        uint256 liqBridgeKind;
        address externalToken; // this is underlyingTokenDst for withdraws
        address underlyingToken;
        address underlyingTokenDst; // this is external token (to receive in the end) for withdraws
        address from;
        uint64 srcChainId;
        uint64 toChainId;
        uint64 liqDstChainId;
        bool dstSwap;
        address toDst;
        uint256 liqBridgeToChainId;
        uint256 amount;
        //uint256 finalAmountDst;
        bool withdraw;
        int256 slippage;
        uint256 USDPerExternalToken;
        uint256 USDPerUnderlyingTokenDst;
        uint256 USDPerUnderlyingToken;
    }

    function _buildLiqBridgeTxData(
        LiqBridgeTxDataArgs memory args,
        bool sameChain
    )
        internal
        view
        returns (bytes memory txData)
    {
        if (args.liqBridgeKind == 1) {
            if (!sameChain) {
                ILiFi.BridgeData memory bridgeData;
                LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

                swapData[0] = LibSwap.SwapData(
                    address(0),
                    /// @dev  callTo (arbitrary)
                    address(0),
                    /// @dev  callTo (approveTo)
                    args.externalToken,
                    args.withdraw ? args.externalToken : args.underlyingToken,
                    /// @dev initial token to extract will be externalToken in args, which is the actual
                    /// underlyingTokenDst
                    /// for withdraws (check how the call is made in _buildSingleVaultWithdrawCallData )
                    args.amount,
                    abi.encode(
                        args.from,
                        FORKS[args.liqDstChainId],
                        args.underlyingTokenDst,
                        args.slippage,
                        false,
                        MULTI_TX_SLIPPAGE_SHARE,
                        args.srcChainId == args.toChainId,
                        args.USDPerExternalToken,
                        args.USDPerUnderlyingToken,
                        args.USDPerUnderlyingTokenDst
                    ),
                    //decimalsDstUnderlyingToken
                    /// @dev this bytes param is used for testing purposes only and easiness of mocking, does not
                    /// resemble
                    /// mainnet
                    false
                );
                /// @dev  arbitrary

                if (args.externalToken != args.underlyingToken) {
                    bridgeData = ILiFi.BridgeData(
                        bytes32("1"),
                        /// @dev request id, arbitrary number
                        "",
                        /// @dev unused in tests
                        "",
                        /// @dev unused in tests
                        address(0),
                        /// @dev unused in tests
                        args.withdraw ? args.externalToken : args.underlyingToken,
                        /// @dev initial token to extract will be externalToken in args, which is the actual
                        /// underlyingTokenDst for withdraws (check how the call is made in
                        /// _buildSingleVaultWithdrawCallData )
                        args.dstSwap && args.srcChainId != args.toChainId
                            ? getContract(args.toChainId, "DstSwapper")
                            : args.toDst,
                        args.amount,
                        args.liqBridgeToChainId,
                        true,
                        /// @dev if external != underlying, this is true
                        false
                    );
                    /// @dev always false for mocking purposes
                } else {
                    bridgeData = ILiFi.BridgeData(
                        bytes32("1"),
                        /// @dev request id, arbitrary number
                        "",
                        /// @dev unused in tests
                        "",
                        /// @dev unused in tests
                        address(0),
                        args.withdraw ? args.externalToken : args.underlyingToken,
                        /// @dev initial token to extract will be externalToken in args, which is the actual
                        /// underlyingTokenDst for withdraws (check how the call is made in
                        /// _buildSingleVaultWithdrawCallData )
                        args.dstSwap && args.srcChainId != args.toChainId
                            ? getContract(args.toChainId, "DstSwapper")
                            : args.toDst,
                        args.amount,
                        args.liqBridgeToChainId,
                        false,
                        false
                    );
                    /// @dev always false for mocking purposes
                }

                txData =
                    abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
            } else {
                LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

                swapData[0] = LibSwap.SwapData(
                    address(0),
                    /// @dev  callTo (arbitrary)
                    address(0),
                    /// @dev  callTo (approveTo)
                    args.externalToken,
                    args.withdraw ? args.externalToken : args.underlyingToken,
                    /// @dev initial token to extract will be externalToken in args, which is the actual
                    /// underlyingTokenDst
                    /// for withdraws (check how the call is made in _buildSingleVaultWithdrawCallData )
                    args.amount,
                    abi.encode(
                        args.from,
                        FORKS[args.liqDstChainId],
                        args.underlyingTokenDst,
                        args.slippage,
                        false,
                        MULTI_TX_SLIPPAGE_SHARE,
                        args.srcChainId == args.toChainId,
                        args.USDPerExternalToken,
                        args.USDPerUnderlyingToken,
                        args.USDPerUnderlyingTokenDst
                    ),
                    /// @dev this bytes param is used for testing purposes only and easiness of mocking, does not
                    /// resemble
                    /// mainnet
                    false
                );

                txData = abi.encodeWithSelector(
                    LiFiMock.swapTokensGeneric.selector, bytes32(0), "", "", args.toDst, 0, swapData
                );
            }
        } else if (args.liqBridgeKind == 2) {
            /// @notice bridge id 2 doesn't support same chain swaps
            if (args.toChainId == args.srcChainId) {
                revert();
            }

            ISocketRegistry.BridgeRequest memory bridgeRequest;
            ISocketRegistry.MiddlewareRequest memory middlewareRequest;
            ISocketRegistry.UserRequest memory userRequest;

            /// @dev middlware request is used if there is a swap involved before the bridging action (external !=
            /// underlying)
            /// @dev the input token should be the token the user deposits, which will be swapped to the input token of
            /// bridging request
            if (args.externalToken != args.underlyingToken) {
                middlewareRequest = ISocketRegistry.MiddlewareRequest(
                    1,
                    /// @dev request id, arbitrary number, but using 0 or 1 for mocking purposes
                    0,
                    /// @dev unused in tests
                    args.externalToken,
                    abi.encode(args.from, args.USDPerExternalToken, args.USDPerUnderlyingToken)
                );
                /// @dev this bytes param is used for testing purposes only and easiness of mocking, does not resemble
                /// mainnet

                bridgeRequest = ISocketRegistry.BridgeRequest(
                    1,
                    /// @dev request id, arbitrary number, but using 0 or 1 for mocking purposes
                    0,
                    /// @dev unused in tests
                    args.withdraw ? args.externalToken : args.underlyingToken,
                    /// @dev initial token to extract will be externalToken in args, which is the actual
                    /// underlyingTokenDst for withdraws (check how the call is made in
                    /// _buildSingleVaultWithdrawCallData )
                    abi.encode(
                        args.from,
                        FORKS[args.liqDstChainId],
                        args.underlyingTokenDst,
                        args.slippage,
                        args.dstSwap,
                        MULTI_TX_SLIPPAGE_SHARE,
                        args.USDPerExternalToken,
                        args.USDPerUnderlyingToken,
                        args.USDPerUnderlyingTokenDst
                    )
                );
                /// @dev this bytes param is used for testing purposes only and easiness of mocking, does not resemble
                /// mainnet
            } else {
                bridgeRequest = ISocketRegistry.BridgeRequest(
                    1,
                    /// @dev request id, arbitrary number, but using 0 or 1 for mocking purposes
                    0,
                    args.externalToken,
                    /// @dev initial token to extract will be externalToken in args, which is the actual
                    /// underlyingTokenDst for withdraws (check how the call is made in
                    /// _buildSingleVaultWithdrawCallData )
                    abi.encode(
                        args.from,
                        FORKS[args.liqDstChainId],
                        args.underlyingTokenDst,
                        args.slippage,
                        args.dstSwap,
                        MULTI_TX_SLIPPAGE_SHARE,
                        args.USDPerExternalToken,
                        args.USDPerUnderlyingToken,
                        args.USDPerUnderlyingTokenDst
                    )
                );
                /// @dev this bytes param is used for testing purposes only and easiness of mocking, does not resemble
                /// mainnet
            }

            /// @dev for cross-chain dstSwap actions, 1st liquidity dst is DstSwapper
            userRequest = ISocketRegistry.UserRequest(
                args.dstSwap ? getContract(args.toChainId, "DstSwapper") : args.toDst,
                args.toChainId,
                args.amount,
                middlewareRequest,
                bridgeRequest
            );

            txData = abi.encodeWithSelector(SocketMock.outboundTransferTo.selector, userRequest);
        } else if (args.liqBridgeKind == 3) {
            txData = abi.encodeWithSelector(
                SocketOneInchMock.performDirectAction.selector,
                args.externalToken,
                args.underlyingToken,
                args.toDst,
                args.amount,
                abi.encode(args.from, args.USDPerExternalToken, args.USDPerUnderlyingToken)
            );
        }
    }

    function _buildLiqBridgeTxDataDstSwap(
        uint8 liqBridgeKind_,
        address sendingTokenDst_,
        address receivingTokenDst_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        int256 slippage_
    )
        internal
        view
        returns (bytes memory txData)
    {
        /// @dev amount_ adjusted after swap slippage
        int256 swapSlippage = (slippage_ * int256(MULTI_TX_SLIPPAGE_SHARE)) / 100;
        amount_ = (amount_ * uint256(10_000 - swapSlippage)) / 10_000;

        /// @dev already on target chain, so need to vm.selectFork() to it
        (, int256 USDPerSendingTokenDst,,,) =
            AggregatorV3Interface(tokenPriceFeeds[toChainId_][sendingTokenDst_]).latestRoundData();
        (, int256 USDPerReceivingTokenDst,,,) =
            AggregatorV3Interface(tokenPriceFeeds[toChainId_][receivingTokenDst_]).latestRoundData();

        if (liqBridgeKind_ == 1) {
            /// @dev for lifi
            LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

            swapData[0] = LibSwap.SwapData(
                address(0),
                ///  @dev  callTo (arbitrary)
                address(0),
                ///  @dev  callTo (approveTo)
                sendingTokenDst_,
                /// @dev in dst swap, assumes a swap between same token - FIXME
                receivingTokenDst_,
                /// @dev in dst swap, assumes a swap between same token - FIXME
                amount_,
                /// @dev _buildLiqBridgeTxDataDstSwap() will only be called when DstSwap is true
                /// @dev and dstswap means cross-chain (last arg)
                abi.encode(
                    from_,
                    FORKS[toChainId_],
                    receivingTokenDst_,
                    slippage_,
                    true,
                    MULTI_TX_SLIPPAGE_SHARE,
                    false,
                    uint256(USDPerSendingTokenDst),
                    uint256(USDPerReceivingTokenDst),
                    1
                ),
                false // arbitrary
            );

            txData = abi.encodeWithSelector(
                LiFiMock.swapTokensGeneric.selector,
                bytes32(0),
                "",
                "",
                getContract(toChainId_, "CoreStateRegistry"),
                0,
                swapData
            );
        } else if (liqBridgeKind_ == 3) {
            txData = abi.encodeWithSelector(
                SocketOneInchMock.performDirectAction.selector,
                sendingTokenDst_,
                receivingTokenDst_,
                getContract(toChainId_, "CoreStateRegistry"),
                amount_,
                abi.encode(from_, uint256(USDPerSendingTokenDst), uint256(USDPerReceivingTokenDst))
            );
        }
    }

    struct BuildDummyTxDataUnitTestsVars {
        uint8 liqBridgeKind_;
        address underlyingToken_;
        address underlyingTokenDst_;
        address from_;
        uint64 srcChainId_;
        uint64 toChainId_;
        uint256 amount_;
        address receiver_;
        bool sameChain_;
    }

    function _buildDummyTxDataUnitTests(BuildDummyTxDataUnitTestsVars memory v)
        internal
        returns (bytes memory txData)
    {
        int256 USDPerUnderlyingTokenDst;
        int256 USDPerUnderlyingToken;

        if (v.underlyingTokenDst_ != address(0)) {
            vm.selectFork(FORKS[v.toChainId_]);
            (, USDPerUnderlyingTokenDst,,,) =
                AggregatorV3Interface(tokenPriceFeeds[v.toChainId_][v.underlyingTokenDst_]).latestRoundData();
        } else {
            USDPerUnderlyingTokenDst = 1;
        }

        if (v.underlyingToken_ != address(0)) {
            vm.selectFork(FORKS[v.srcChainId_]);
            (, USDPerUnderlyingToken,,,) =
                AggregatorV3Interface(tokenPriceFeeds[v.srcChainId_][v.underlyingToken_]).latestRoundData();
        } else {
            USDPerUnderlyingToken = 1;
        }

        if (v.liqBridgeKind_ == 1) {
            if (!v.sameChain_) {
                ILiFi.BridgeData memory bridgeData;
                LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

                swapData[0] = LibSwap.SwapData(
                    address(0),
                    /// callTo (arbitrary)
                    address(0),
                    /// callTo (approveTo)
                    v.underlyingToken_,
                    v.underlyingToken_,
                    v.amount_,
                    abi.encode(
                        v.from_,
                        FORKS[v.toChainId_],
                        v.underlyingTokenDst_,
                        totalSlippage,
                        false,
                        0,
                        false,
                        uint256(USDPerUnderlyingToken),
                        uint256(USDPerUnderlyingToken),
                        uint256(USDPerUnderlyingTokenDst)
                    ),
                    false // arbitrary
                );

                bridgeData = ILiFi.BridgeData(
                    bytes32("1"),
                    /// request id
                    "",
                    "",
                    address(0),
                    v.underlyingToken_,
                    v.receiver_,
                    v.amount_,
                    uint256(v.toChainId_),
                    false,
                    false
                );

                txData =
                    abi.encodeWithSelector(LiFiMock.swapAndStartBridgeTokensViaBridge.selector, bridgeData, swapData);
            } else {
                LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

                swapData[0] = LibSwap.SwapData(
                    address(0),
                    /// callTo (arbitrary)
                    address(0),
                    /// callTo (approveTo)
                    v.underlyingToken_,
                    v.underlyingToken_,
                    v.amount_,
                    abi.encode(
                        v.from_,
                        FORKS[v.toChainId_],
                        v.underlyingTokenDst_,
                        totalSlippage,
                        false,
                        0,
                        false,
                        uint256(USDPerUnderlyingToken),
                        uint256(USDPerUnderlyingToken),
                        uint256(USDPerUnderlyingTokenDst)
                    ),
                    false // arbitrary
                );

                txData = abi.encodeWithSelector(
                    LiFiMock.swapTokensGeneric.selector, bytes32(0), "", "", v.receiver_, 0, swapData
                );
            }
        } else if (v.liqBridgeKind_ == 2) {
            /// @notice bridge id 2 doesn't support same chain swaps
            if (v.sameChain_) {
                revert();
            }

            ISocketRegistry.BridgeRequest memory bridgeRequest;
            ISocketRegistry.MiddlewareRequest memory middlewareRequest;

            /// @dev middlware request is used if there is a swap involved before the bridging action (external !=
            /// underlying)
            /// @dev the input token should be the token the user deposits, which will be swapped to the input token of
            /// bridging request
            middlewareRequest = ISocketRegistry.MiddlewareRequest(
                1,
                /// @dev request id, arbitrary number, but using 0 or 1 for mocking purposes
                0,
                /// @dev unused in tests
                v.underlyingToken_,
                abi.encode(v.from_)
            );

            /// @dev this bytes param is used for testing purposes only and easiness of mocking, does not resemble
            /// mainnet
            bridgeRequest = ISocketRegistry.BridgeRequest(
                1,
                /// @dev request id, arbitrary number, but using 0 or 1 for mocking purposes
                0,
                /// @dev unused in tests
                v.underlyingToken_,
                /// @dev initial token to extract will be externalToken in args, which is the actual
                /// underlyingTokenDst for withdraws (check how the call is made in
                /// _buildSingleVaultWithdrawCallData )
                abi.encode(
                    v.from_,
                    FORKS[v.toChainId_],
                    v.underlyingToken_,
                    totalSlippage,
                    false,
                    0,
                    false,
                    uint256(USDPerUnderlyingToken),
                    uint256(USDPerUnderlyingToken),
                    uint256(USDPerUnderlyingTokenDst)
                )
            );

            txData = abi.encodeWithSelector(
                SocketMock.outboundTransferTo.selector,
                ISocketRegistry.UserRequest(v.receiver_, v.toChainId_, v.amount_, middlewareRequest, bridgeRequest)
            );
        } else if (v.liqBridgeKind_ == 3) {
            txData = abi.encodeWithSelector(
                SocketOneInchMock.performDirectAction.selector,
                v.underlyingToken_,
                v.underlyingToken_,
                v.receiver_,
                v.amount_,
                abi.encode(v.from_, USDPerUnderlyingToken, USDPerUnderlyingTokenDst)
            );
        }
    }
}
