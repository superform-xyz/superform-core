        /// @dev for e.g. externalToken = DAI, underlyingTokenDst = USDC, daiAmount = 100
        /// => usdcAmount = ((USDPerDai / 10e18) / (USDPerUsdc / 10e6)) * daiAmount
        console.log("test withdraw amount pre-swap", args.amount);
        /// @dev src swaps simulation if any
        if (args.externalToken != args.underlyingToken) {
            vm.selectFork(FORKS[args.srcChainId]);
            uint256 decimal1 = v.decimal1;
            uint256 decimal2 = args.underlyingToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
                ? 18
                : MockERC20(args.underlyingToken).decimals();

            /// @dev decimal1 = decimals of args.externalToken (src chain), decimal2 = decimals of args.underlyingToken
            /// (src chain)
            if (decimal1 > decimal2) {
                args.amount = (args.amount * uint256(USDPerExternalToken))
                    / (uint256(USDPerUnderlyingToken) * 10 ** (decimal1 - decimal2));
            } else {
                args.amount = ((args.amount * uint256(USDPerExternalToken)) * 10 ** (decimal2 - decimal1))
                    / uint256(USDPerUnderlyingToken);
            }
            console.log("test withdraw amount post-swap", args.amount);
        }

        int256 slippage = args.slippage;
        if (args.srcChainId == args.toChainId) slippage = 0;
        // else if (args.dstSwap) slippage = (slippage * int256(MULTI_TX_SLIPPAGE_SHARE)) / 100;
        // else slippage = (slippage * int256(100 - MULTI_TX_SLIPPAGE_SHARE)) / 100;

        /// @dev applying 100% x-chain slippage at once i.e. bridge + dstSwap slippage (as opposed to 2 steps in
        /// LiFiMock) coz this code will only be executed once (as opposed to twice in LiFiMock, once for bridge and
        /// other for dstSwap)
        args.amount = (args.amount * uint256(10_000 - slippage)) / 10_000;
        console.log("test withdraw amount pre-bridge, post-slippage", v.amount);

        /// @dev if args.externalToken == args.underlyingToken, USDPerExternalToken == USDPerUnderlyingToken
        /// @dev v.decimal3 = decimals of args.underlyingToken (args.externalToken too if above holds true) (src chain),
        /// v.decimal2 = decimals of args.underlyingTokenDst (dst chain)
        if (v.decimal3 > v.decimal2) {
            v.amount = (args.amount * uint256(USDPerUnderlyingToken))
                / (uint256(USDPerUnderlyingTokenDst) * 10 ** (v.decimal3 - v.decimal2));
        } else {
            v.amount = (args.amount * uint256(USDPerUnderlyingToken) * 10 ** (v.decimal2 - v.decimal3))
                / uint256(USDPerUnderlyingTokenDst);
        }
        console.log("test withdraw amount post-bridge", v.amount);
