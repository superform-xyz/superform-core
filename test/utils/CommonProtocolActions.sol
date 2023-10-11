/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "./BaseSetup.sol";
import { ILiFi } from "src/vendor/lifi/ILiFi.sol";
import { LibSwap } from "src/vendor/lifi/LibSwap.sol";
import { LiFiMock } from "../mocks/LiFiMock.sol";

abstract contract CommonProtocolActions is BaseSetup {
    /// @dev percentage of total slippage that is used for dstSwap
    uint256 MULTI_TX_SLIPPAGE_SHARE;

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
        uint256 finalAmountDst;
        bool withdraw;
        int256 slippage;
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
                    // args.finalAmountDst
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
                    //args.finalAmountDst
                    /// @dev this bytes param is used for testing purposes only and easiness of mocking, does not
                    /// resemble
                    /// mainnet
                    false
                );

                txData = abi.encodeWithSelector(
                    LiFiMock.swapTokensGeneric.selector, bytes32(0), "", "", args.toDst, 0, swapData
                );
            }
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
        // amount_ = (amount_ * uint256(10_000 - slippage_)) / 10_000;

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
                /// @dev _buildLiqBridgeTxDataMultiTx() will only be called when multiTx is true
                /// @dev and multiTx means cross-chain (last arg)
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
        }
    }

    function _buildDummyTxDataUnitTests(
        uint8 liqBridgeKind_,
        address underlyingToken_,
        address underlyingTokenDst_,
        address from_,
        uint64 toChainId_,
        uint256 amount_,
        address receiver_,
        bool sameChain_
    )
        internal
        view
        returns (bytes memory txData)
    {
        vm.selectFork(FORKS[toChainId_]);
        (, int256 USDPerUnderlyingTokenDst,,,) =
            AggregatorV3Interface(tokenPriceFeeds[toChainId_][underlyingTokenDst_]).latestRoundData();

        vm.selectFork(FORKS[ETH]);
        (, int256 USDPerUnderlyingToken,,,) =
            AggregatorV3Interface(tokenPriceFeeds[ETH][underlyingToken_]).latestRoundData();

        if (liqBridgeKind_ == 1) {
            if (!sameChain_) {
                ILiFi.BridgeData memory bridgeData;
                LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);

                swapData[0] = LibSwap.SwapData(
                    address(0),
                    /// callTo (arbitrary)
                    address(0),
                    /// callTo (approveTo)
                    underlyingToken_,
                    underlyingToken_,
                    amount_,
                    abi.encode(
                        from_,
                        FORKS[toChainId_],
                        underlyingTokenDst_,
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
                    underlyingToken_,
                    receiver_,
                    amount_,
                    uint256(toChainId_),
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
                    underlyingToken_,
                    underlyingToken_,
                    amount_,
                    abi.encode(from_, FORKS[toChainId_], underlyingTokenDst_, totalSlippage, false, 0, false),
                    false // arbitrary
                );

                txData = abi.encodeWithSelector(
                    LiFiMock.swapTokensGeneric.selector, bytes32(0), "", "", receiver_, 0, swapData
                );
            }
        }
    }
}
