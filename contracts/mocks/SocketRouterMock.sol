// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.14;

/// NPM Imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Types Imports
import {UserRequest} from "../types/socketTypes.sol";

/// @title Socket Router Mock
contract SocketRouterMock {
    receive() external payable {}

    function mockSocketTransfer(
        address from,
        address to,
        address token,
        uint256 amount
    ) external returns (bool) {
        IERC20(token).transferFrom(from, address(this), amount);
        IERC20(token).transfer(to, amount);

        return true;
    }

    function mockSocketTransferNative(
        address from,
        address to,
        address token,
        uint256 amount
    ) external payable returns (bool) {
        IERC20(token).transferFrom(from, address(this), amount);

        // Example of an exchange rate
        uint256 ethToTransfer = address(this).balance / 10;

        (bool success, ) = payable(to).call{value: ethToTransfer}("");

        require(success, "Transfer failed.");

        return true;
    }

    /* 
     proof that this works in a single chain of calls with socket.tech
     https://api.socket.tech/v2/swagger/#/Quote/QuoteController_getQuote

     fromChainId: 137 (polygon)
     0x2791bca1f2de4661ed88a30c99a7a9449aa84174 <- USDC on polygon
     toChainId: 137
     0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee <- ETH on polygon
     USDC amount 100000000
     0x3e8cB4bd04d81498aB4b94a392c334F5328b237b <- sample account

    Example of the succesful output route within same chain using one inch
    {
        "success": true,
        "result": {
            "routes": [
            {
                "routeId": "75f991b8-68dd-4f04-a596-d82ac1fdf2e2",
                "isOnlySwapRoute": true,
                "fromAmount": "100000000",
                "toAmount": "106146584716748706519",
                "sender": "0x3e8cB4bd04d81498aB4b94a392c334F5328b237b",
                "recipient": "0x3e8cB4bd04d81498aB4b94a392c334F5328b237b",
                "totalUserTx": 1,
                "totalGasFeesInUsd": 0.01783990806356101,
                "userTxs": [
                {
                    "userTxType": "dex-swap",
                    "txType": "eth_sendTransaction",
                    "swapSlippage": 2,
                    "chainId": 137,
                    "protocol": {
                    "name": "oneinch",
                    "displayName": "1Inch",
                    "icon": "https://bridgelogos.s3.ap-south-1.amazonaws.com/1inch.png"
                    },
                    "fromAsset": {
                    "chainId": 137,
                    "address": "0x2791bca1f2de4661ed88a30c99a7a9449aa84174",
                    "symbol": "USDC",
                    "name": "USDCoin",
                    "decimals": 6,
                    "icon": "https://maticnetwork.github.io/polygon-token-assets/assets/usdc.svg",
                    "logoURI": "https://maticnetwork.github.io/polygon-token-assets/assets/usdc.svg",
                    "chainAgnosticId": "USDC"
                    },
                    "approvalData": {
                    "minimumApprovalAmount": "100000000",
                    "approvalTokenAddress": "0x2791bca1f2de4661ed88a30c99a7a9449aa84174",
                    "allowanceTarget": "0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0",
                    "owner": "0x3e8cB4bd04d81498aB4b94a392c334F5328b237b"
                    },
                    "fromAmount": "100000000",
                    "toAsset": {
                    "chainId": 137,
                    "address": "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
                    "symbol": "MATIC",
                    "name": "MATIC",
                    "decimals": 18,
                    "icon": "https://maticnetwork.github.io/polygon-token-assets/assets/matic.svg",
                    "logoURI": "https://maticnetwork.github.io/polygon-token-assets/assets/matic.svg",
                    "chainAgnosticId": null
                    },
                    "toAmount": "106146584716748706519",
                    "minAmountOut": "104023653022413732388",
                    "gasFees": {
                    "gasAmount": "18968112422328694",
                    "gasLimit": 292762,
                    "asset": {
                        "chainId": 137,
                        "address": "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
                        "symbol": "MATIC",
                        "name": "MATIC",
                        "decimals": 18,
                        "icon": "https://maticnetwork.github.io/polygon-token-assets/assets/matic.svg",
                        "logoURI": "https://maticnetwork.github.io/polygon-token-assets/assets/matic.svg",
                        "chainAgnosticId": null
                    },
                    "feesInUsd": 0.01783990806356101
                    },
                    "sender": "0x3e8cB4bd04d81498aB4b94a392c334F5328b237b",
                    "recipient": "0x3e8cB4bd04d81498aB4b94a392c334F5328b237b",
                    "userTxIndex": 0
                }
                ],
                "usedDexName": "oneinch"
            }
            ],
            "fromChainId": 137,
            "fromAsset": {
                "chainId": 137,
                "address": "0x2791bca1f2de4661ed88a30c99a7a9449aa84174",
                "symbol": "USDC",
                "name": "USDCoin",
                "decimals": 6,
                "icon": "https://maticnetwork.github.io/polygon-token-assets/assets/usdc.svg",
                "logoURI": "https://maticnetwork.github.io/polygon-token-assets/assets/usdc.svg",
                "chainAgnosticId": "USDC"
            },
            "toChainId": 137,
            "toAsset": {
                "chainId": 137,
                "address": "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
                "symbol": "MATIC",
                "name": "MATIC",
                "decimals": 18,
                "icon": "https://maticnetwork.github.io/polygon-token-assets/assets/matic.svg",
                "logoURI": "https://maticnetwork.github.io/polygon-token-assets/assets/matic.svg",
                "chainAgnosticId": null
            }
        }
    }
    */
}
