// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title IPayloadHelper
/// @author ZeroPoint Labs
/// @dev helps decoding the bytes payload and returns meaningful information
interface IPayloadHelper {
    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev reads the payload from the core state registry and decodes it in a more detailed manner.
    /// @param dstPayloadId_ is the unique identifier of the payload received in dst core state registry
    /// @return txType is the type of transaction. check {TransactionType} enum in DataTypes.sol
    /// @return callbackType is the type of payload. check {CallbackType} enum in DataTypes.sol
    /// @return srcSender is the user who initiated the transaction on the srcChain
    /// @return srcChainId is the unique identifier of the srcChain
    /// @return amounts are the amounts to deposit/withdraw
    /// @return slippages are the max slippages configured by the user (only for deposits)
    /// @return superformIds are the unique identifiers of the superforms
    /// @return hasDstSwaps are the array of flags indicating if the original liqData has a dstSwaps
    /// @return extraFormData is the extra form data (optional: passed for forms with special needs)
    /// @return receiverAddress is the address to be used for refunds
    /// @return srcPayloadId is the identifier of the corresponding payload on srcChain
    function decodeCoreStateRegistryPayload(uint256 dstPayloadId_)
        external
        view
        returns (
            uint8 txType,
            uint8 callbackType,
            address srcSender,
            uint64 srcChainId,
            uint256[] memory amounts,
            uint256[] memory slippages,
            uint256[] memory superformIds,
            bool[] memory hasDstSwaps,
            bytes memory extraFormData,
            address receiverAddress,
            uint256 srcPayloadId
        );

    /// @dev reads the payload from the core state registry and decodes liqData for it (to be used in withdraw cases)
    /// @param dstPayloadId_ is the unique identifier of the payload received in dst core state registry
    /// @return bridgeIds are the ids of the bridges to be used
    /// @return txDatas are the array of txData to be sent to the bridges
    /// @return tokens are the tokens to be used in the liqData
    /// @return liqDstChainIds are the final destination chain id for the underlying token (can be arbitrary on
    /// withdraws)
    /// @return amountsIn are the from amounts to the liquidity bridge
    /// @return nativeAmounts are the native amounts to be used in the liqData
    function decodeCoreStateRegistryPayloadLiqData(uint256 dstPayloadId_)
        external
        view
        returns (
            uint8[] memory bridgeIds,
            bytes[] memory txDatas,
            address[] memory tokens,
            uint64[] memory liqDstChainIds,
            uint256[] memory amountsIn,
            uint256[] memory nativeAmounts
        );

    /// @dev reads the payload header from superPositions and decodes it.
    /// @param srcPayloadId_ is the unique identifier of the payload allocated by superform router
    /// @return txType is the type of transaction. check {TransactionType} enum in DataTypes.sol
    /// @return callbackType is the type of payload. check {CallbackType} enum in DataTypes.sol
    /// @return isMulti indicates if the transaction involves operations to multiple vaults
    /// @return srcSender is the user who initiated the transaction on the srcChain
    /// @return srcChainId is the unique identifier of the srcChain
    function decodePayloadHistory(uint256 srcPayloadId_)
        external
        view
        returns (uint8 txType, uint8 callbackType, uint8 isMulti, address srcSender, uint64 srcChainId);

    /// @dev returns decoded timelock form payloads
    /// @param timelockPayloadId_ is the unique identifier of payload in timelock state registry
    function decodeTimeLockPayload(uint256 timelockPayloadId_)
        external
        view
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount);

    /// @dev returns decoded failed timelock form payloads
    /// @param timelockPayloadId_ is the unique identifier of payload in timelock state registry
    function decodeTimeLockFailedPayload(uint256 timelockPayloadId_)
        external
        view
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount);

    /// @dev returns proof for payloads
    /// @param dstPayloadId_ is the unique identifier of payload in dst core state registry
    /// @return proof is the proof for the payload
    function getDstPayloadProof(uint256 dstPayloadId_) external view returns (bytes32);
}
