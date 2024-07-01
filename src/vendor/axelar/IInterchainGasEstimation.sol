// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IInterchainGasEstimation Interface
 * @notice This is an interface for the InterchainGasEstimation contract
 * which allows for estimating gas fees for cross-chain communication on the Axelar network.
 */
interface IInterchainGasEstimation {
    error UnsupportedEstimationType(GasEstimationType gasEstimationType);

    /**
     * @notice Event emitted when the gas price for a specific chain is updated.
     * @param chain The name of the chain
     * @param info The gas info for the chain
     */
    event GasInfoUpdated(string chain, GasInfo info);

    enum GasEstimationType {
        Default,
        OptimismEcotone
    }

    struct GasInfo {
        GasEstimationType gasEstimationType; // Custom gas pricing rule, such as L1 data fee on L2s
        uint128 axelarBaseFee; // axelar base fee for cross-chain message approval (in terms of src native gas token)
        uint128 expressFee; // axelar express fee for cross-chain message approval and express execution
        uint128 relativeGasPrice; // dest_gas_price * dest_token_market_price / src_token_market_price
        uint128 relativeBlobBaseFee; // dest_blob_base_fee * dest_token_market_price / src_token_market_price
    }

    /**
     * @notice Returns the gas price for a specific chain.
     * @param chain The name of the chain
     * @return gasInfo The gas info for the chain
     */
    function getGasInfo(string calldata chain) external view returns (GasInfo memory);

    /**
     * @notice Estimates the gas fee for a cross-chain contract call.
     * @param destinationChain Axelar registered name of the destination chain
     * @param destinationAddress Destination contract address being called
     * @param executionGasLimit The gas limit to be used for the destination contract execution,
     *        e.g. pass in 200k if your app consumes needs upto 200k for this contract call
     * @param params Additional parameters for the gas estimation
     * @return gasEstimate The cross-chain gas estimate, in terms of source chain's native gas token that should be
     * forwarded to the gas service.
     */
    function estimateGasFee(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        uint256 executionGasLimit,
        bytes calldata params
    )
        external
        view
        returns (uint256 gasEstimate);
}
