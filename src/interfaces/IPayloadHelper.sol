// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title IPayloadHelper
/// @dev Interface for PayloadHelper
/// @author ZeroPoint Labs
interface IPayloadHelper {
    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

    /// @notice txType is the type of transaction. check {TransactionType} enum in DataTypes.sol
    /// @notice callbackType is the type of payload. check {CallbackType} enum in DataTypes.sol
    /// @notice srcSender is the user who initiated the transaction on the srcChain
    /// @notice srcChainId is the unique identifier of the srcChain
    /// @notice amounts are the amounts to deposit/withdraw
    /// @notice outputAmounts are the expected outputAmounts specified by user
    /// @notice slippages are the max slippages configured by the user (only for deposits)
    /// @notice superformIds are the unique identifiers of the superforms
    /// @notice hasDstSwaps are the array of flags indicating if the original liqData has a dstSwaps
    /// @notice extraFormData is the extra form data (optional: passed for forms with special needs)
    /// @notice receiverAddress is the address to be used for refunds
    /// @notice srcPayloadId is the identifier of the corresponding payload on srcChain
    struct DecodedDstPayload {
        uint8 txType;
        uint8 callbackType;
        address srcSender;
        uint64 srcChainId;
        uint256[] amounts;
        uint256[] outputAmounts;
        uint256[] slippages;
        uint256[] superformIds;
        bool[] hasDstSwaps;
        address receiverAddress;
        uint256 srcPayloadId;
        bytes extraFormData;
        uint8 multi;
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev reads the payload from the core state registry and decodes it in a more detailed manner.
    /// @param dstPayloadId_ is the unique identifier of the payload received in dst core state registry
    /// @return decodedDstPayload is the details of the payload, refer DecodedDstPayload struct for info
    function decodeCoreStateRegistryPayload(uint256 dstPayloadId_)
        external
        view
        returns (DecodedDstPayload memory decodedDstPayload);

    /// @dev reads the payload from the core state registry and decodes liqData for it (to be used in withdraw cases)
    /// @param dstPayloadId_ is the unique identifier of the payload received in dst core state registry
    /// @return txDatas are the array of txData to be sent to the bridges
    /// @return tokens are the tokens to be used in the liqData
    /// @return interimTokens are the interim tokens to be used in the liqData
    /// @return bridgeIds are the ids of the bridges to be used
    /// @return liqDstChainIds are the final destination chain id for the underlying token (can be arbitrary on
    /// withdraws)
    /// @return amountsIn are the from amounts to the liquidity bridge
    /// @return nativeAmounts are the native amounts to be used in the liqData
    function decodeCoreStateRegistryPayloadLiqData(uint256 dstPayloadId_)
        external
        view
        returns (
            bytes[] memory txDatas,
            address[] memory tokens,
            address[] memory interimTokens,
            uint8[] memory bridgeIds,
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
    /// @return receiverAddressSP is the address to be used for receiving Super Positions
    /// @return srcChainId is the unique identifier of the srcChain
    function decodePayloadHistory(uint256 srcPayloadId_)
        external
        view
        returns (
            uint8 txType,
            uint8 callbackType,
            uint8 isMulti,
            address srcSender,
            address receiverAddressSP,
            uint64 srcChainId
        );

    /// @dev returns decoded timelock form payloads
    /// @param timelockPayloadId_ is the unique identifier of payload in timelock state registry
    function decodeTimeLockPayload(uint256 timelockPayloadId_)
        external
        view
        returns (address receiverAddress, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount);

    /// @dev returns decoded async deposit form payloads
    /// @param asyncDepositPayloadId_ is the unique identifier of payload in async deposit state registry
    function decodeAsyncDepositPayload(uint256 asyncDepositPayloadId_)
        external
        view
        returns (address receiverAddress, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount);

    /// @dev returns decoded async withdraw form payloads
    /// @param asyncWithdrawPayloadId_ is the unique identifier of payload in async withdraw state registry
    function decodeAsyncWithdrawPayload(uint256 asyncWithdrawPayloadId_)
        external
        view
        returns (address receiverAddress, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount);

    /// @dev returns decoded failed timelock form payloads
    /// @param timelockPayloadId_ is the unique identifier of payload in timelock state registry
    function decodeTimeLockFailedPayload(uint256 timelockPayloadId_)
        external
        view
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount);

    /// @dev returns decoded successful async deposit payloads
    /// @param payloadId_ is the unique identifier of payload in async state registry
    function decodeAsyncDepositAckPayload(uint256 payloadId_)
        external
        view
        returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount);

    /// @dev returns proof for payloads
    /// @param dstPayloadId_ is the unique identifier of payload in dst core state registry
    /// @return proof is the proof for the payload
    function getDstPayloadProof(uint256 dstPayloadId_) external view returns (bytes32);
}
