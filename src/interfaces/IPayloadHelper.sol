// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title IPayloadHelper
/// @author ZeroPoint Labs
/// @dev helps decoding the bytes payload and returns meaningful information
interface IPayloadHelper {
    /// @dev reads the payload from the core state registry and decodes it in a more detailed manner.
    /// @param dstPayloadId_ is the unique identifier of the payload received in dst core state registry
    /// @return txType is the type of transaction. check {TransactionType} enum in DataTypes.sol
    /// @return callbackType is the type of payload. check {CallbackType} enum in DataTypes.sol
    /// @return srcSender is the user who initiated the transaction on the srcChain
    /// @return srcChainId is the unique identifier of the srcChain
    /// @return amounts is the amount to deposit/withdraw
    /// @return slippage is the max slippage configured by the user (only for deposits)
    /// @return superformIds is the unique identifiers of the superforms
    /// @return srcPayloadId is the identifier of the corresponding payload on srcChain
    /// @return superformRouterId is the identifier of the superform router
    function decodeCoreStateRegistryPayload(uint256 dstPayloadId_)
        external
        view
        returns (
            uint8 txType,
            uint8 callbackType,
            address srcSender,
            uint64 srcChainId,
            uint256[] memory amounts,
            uint256[] memory slippage,
            uint256[] memory superformIds,
            uint256 srcPayloadId,
            uint8 superformRouterId
        );

    /// @dev reads the payload from the core state registry and decodes liqData for it (to be used in withdraw cases)
    /// @param dstPayloadId_ is the unique identifier of the payload received in dst core state registry
    /// @return bridgeIds is the ids of the bridges to be used
    /// @return txDatas is the array of txData to be sent to the bridges
    /// @return tokens is the tokens to be used in the liqData
    /// @return liqDstChainId is the destination chain id for the underlying token
    /// @return amounts is the amounts to be used in the liqData
    /// @return nativeAmounts is the native amounts to be used in the liqData
    /// @return permit2datas is the permit2 datas to be used in the liqData
    function decodeDstPayloadLiqData(uint256 dstPayloadId_)
        external
        view
        returns (
            uint8[] memory bridgeIds,
            bytes[] memory txDatas,
            address[] memory tokens,
            uint64[] memory liqDstChainId,
            uint256[] memory amounts,
            uint256[] memory nativeAmounts,
            bytes[] memory permit2datas
        );

    /// @dev reads the payload from the core state registry and decodes it in a more detailed manner.
    /// @param srcPayloadId_ is the unique identifier of the payload allocated by super router
    /// @param superformRouterId_ is the unique identifier of the superform router
    /// @return txType is the type of transaction. check {TransactionType} enum in DataTypes.sol
    /// @return callbackType is the type of payload. check {CallbackType} enum in DataTypes.sol
    /// @return isMulti indicates if the transaction involves operations to multiple vaults
    /// @return srcSender is the user who initiated the transaction on the srcChain
    /// @return srcChainId is the unique identifier of the srcChain
    function decodePayloadHistoryOnSrc(
        uint256 srcPayloadId_,
        uint8 superformRouterId_
    )
        external
        view
        returns (uint8 txType, uint8 callbackType, uint8 isMulti, address srcSender, uint64 srcChainId);

    /// @dev returns decoded two step form payloads
    /// @param timelockPayloadId_ is the unique identifier of payload in two step registry
    function decodeTimeLockPayload(uint256 timelockPayloadId_)
        external
        view
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount);

    /// @dev returns decoded failed two step form payloads
    /// @param timelockPayloadId_ is the unique identifier of payload in two step registry
    function decodeTimeLockFailedPayload(uint256 timelockPayloadId_)
        external
        view
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount);
}
