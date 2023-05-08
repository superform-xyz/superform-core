///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {ISuperPositions} from "./interfaces/ISuperPositions.sol";
import {ISuperRouter} from "./interfaces/ISuperRouter.sol";
import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {ISuperPositionBank} from "./interfaces/ISuperPositionBank.sol";
import {TransactionType, ReturnMultiData, ReturnSingleData, CallbackType, InitMultiVaultData, InitSingleVaultData, AMBMessage} from "./types/DataTypes.sol";
import "./utils/DataPacking.sol";

import {Error} from "./utils/Error.sol";

/// @title SuperPosition Bank
/// @author Zeropoint Labs.
/// @dev FIXME: why does it need to import erc165?
contract SuperPositionBank is ISuperPositionBank, ERC165 {
    ISuperRegistry public immutable superRegistry;

    mapping(address owner => mapping(uint256 id => PositionBatch))
        private queueBatch;
    mapping(address owner => mapping(uint256 id => PositionSingle))
        private queueSingle;

    mapping(address owner => uint256 id) public queueCounter;

    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint80 => AMBMessage) public txHistory;

    modifier onlyRouter() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasSuperRouterRole(
                msg.sender
            )
        ) revert Error.NOT_SUPER_ROUTER();
        _;
    }

    modifier onlyCoreStateRegistry() {
        if (msg.sender != superRegistry.coreStateRegistry())
            revert Error.NOT_CORE_STATE_REGISTRY();
        _;
    }

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /// @dev Could call SuperRouter.deposit() function from here, first transfering tokens to this contract, thus saving gas
    /// NOTE: What if we open this function to deposit here and then only make a check from SuperRouter.withdraw() if returned index matches caller of SuperRouter?
    /// NOTE: Would require users to call two separate contracts and fragments flow
    // function depositToSourceDirectly() external;

    /// @notice Create a new position in the queue for withdrawal. owner_ can have multiple positions in the queue
    function acceptPositionSingle(
        uint256 tokenId_,
        uint256 amount_,
        address owner_
    ) external override onlyRouter returns (uint256 index) {
        ISuperPositions(superRegistry.superPositions()).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId_,
            amount_,
            ""
        );

        index = queueCounter[owner_]++;
        queueSingle[owner_][index] = PositionSingle({
            tokenId: tokenId_,
            amount: amount_
        });
    }

    /// @notice Create a new position in the queue for withdrawal. owner_ can have multiple positions in the queue
    function acceptPositionBatch(
        uint256[] memory tokenIds_,
        uint256[] memory amounts_,
        address owner_
    ) external override onlyRouter returns (uint256 index) {
        if (tokenIds_.length != amounts_.length)
            revert Error.SPBANK_TOKEN_AMOUNT_LENGTH_MISMATCH();
        ISuperPositions(superRegistry.superPositions()).safeBatchTransferFrom(
            msg.sender,
            address(this),
            tokenIds_,
            amounts_,
            ""
        );

        index = queueCounter[owner_]++;
        queueBatch[owner_][index] = PositionBatch({
            tokenIds: tokenIds_,
            amounts: amounts_
        });
    }

    function mintSingleSP(
        address owner_,
        uint256 superFormId_,
        uint256 amount_
    ) external override onlyRouter {
        ISuperPositions(superRegistry.superPositions()).mintSingleSP(
            owner_,
            superFormId_,
            amount_,
            ""
        );
    }

    function mintBatchSP(
        address owner_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_
    ) external override onlyRouter {
        ISuperPositions(superRegistry.superPositions()).mintBatchSP(
            owner_,
            superFormIds_,
            amounts_,
            ""
        );
    }

    function burnSingleSP(
        address owner_,
        uint256 superFormId_,
        uint256 amount_
    ) external override onlyRouter {
        ISuperPositions(superRegistry.superPositions()).burnSingleSP(
            owner_,
            superFormId_,
            amount_
        );
    }

    function burnBatchSP(
        address owner_,
        uint256[] memory superFormIds_,
        uint256[] memory amounts_
    ) external override onlyRouter {
        ISuperPositions(superRegistry.superPositions()).burnBatchSP(
            owner_,
            superFormIds_,
            amounts_
        );
    }

    /// @notice Intended to be called in case Withdraw succeds and we can safely burn SuperPositions for owner
    function holdPositionSingle(
        address owner_,
        uint256 positionIndex
    ) public onlyRouter {}

    /// @notice Intended to be called in case Withdraw succeds and we can safely burn SuperPositions for owner
    function holdPositionBatch(
        address owner_,
        uint256 positionIndex
    ) public onlyRouter {}

    function updateTxHistory(
        uint80 messageId_,
        AMBMessage memory message_
    ) external override onlyRouter {
        txHistory[messageId_] = message_;
    }

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param data_ is the received information to be processed.
    /// TODO: ASSES WHAT HAPPENS FOR MULTISYNC WITH CALLBACKTYPE.FAIL IN ONE OF THE IDS!!!
    function stateMultiSync(
        AMBMessage memory data_
    ) external payable override onlyCoreStateRegistry {
        (uint256 txType, uint256 callbackType, , ) = _decodeTxInfo(
            data_.txInfo
        );

        /// @dev NOTE: some optimization ideas? suprisingly, you can't use || here!
        if (callbackType != uint256(CallbackType.RETURN))
            if (callbackType != uint256(CallbackType.FAIL))
                revert Error.INVALID_PAYLOAD();

        ReturnMultiData memory returnData = abi.decode(
            data_.params,
            (ReturnMultiData)
        );

        (
            uint16 status,
            uint16 returnDataSrcChainId,
            uint16 returnDataDstChainId,
            uint80 returnDataTxId
        ) = _decodeReturnTxInfo(returnData.returnTxInfo);

        AMBMessage memory stored = txHistory[returnDataTxId];

        (, , bool multi, ) = _decodeTxInfo(stored.txInfo);

        if (!multi) revert Error.INVALID_PAYLOAD();

        InitMultiVaultData memory multiVaultData = abi.decode(
            stored.params,
            (InitMultiVaultData)
        );
        (address srcSender, uint16 srcChainId, ) = _decodeTxData(
            multiVaultData.txData
        );

        if (returnDataSrcChainId != srcChainId)
            revert Error.SRC_CHAIN_IDS_MISMATCH();

        if (
            returnDataDstChainId !=
            _getDestinationChain(multiVaultData.superFormIds[0])
        ) revert Error.DST_CHAIN_IDS_MISMATCH();

        if (txType == uint256(TransactionType.DEPOSIT)) {
            ISuperPositions(superRegistry.superPositions()).mintBatchSP(
                srcSender,
                multiVaultData.superFormIds,
                returnData.amounts,
                ""
            );
        } else if (txType == uint256(TransactionType.WITHDRAW)) {
            bytes memory extraData = multiVaultData.extraFormData; // TODO read customForm type here
            uint256 index = abi.decode(extraData, (uint256));

            _burnPositionBatch(srcSender, index);
        } else if (callbackType == uint256(CallbackType.FAIL)) {
            bytes memory extraData = multiVaultData.extraFormData; // TODO read customForm type here
            uint256 index = abi.decode(extraData, (uint256));

            _returnPositionBatch(srcSender, index);
        } else {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnDataTxId);
    }

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param data_ is the received information to be processed.
    /// NOTE: Shouldn't this be ACCESS CONTROLed?
    function stateSync(
        AMBMessage memory data_
    ) external payable override onlyCoreStateRegistry {
        (uint256 txType, uint256 callbackType, , ) = _decodeTxInfo(
            data_.txInfo
        );

        /// @dev NOTE: some optimization ideas? suprisingly, you can't use || here!
        if (callbackType != uint256(CallbackType.RETURN))
            if (callbackType != uint256(CallbackType.FAIL))
                revert Error.INVALID_PAYLOAD();

        ReturnSingleData memory returnData = abi.decode(
            data_.params,
            (ReturnSingleData)
        );

        (
            uint16 status,
            uint16 returnDataSrcChainId,
            uint16 returnDataDstChainId,
            uint80 returnDataTxId
        ) = _decodeReturnTxInfo(returnData.returnTxInfo);

        AMBMessage memory stored = txHistory[returnDataTxId];
        (, , bool multi, ) = _decodeTxInfo(stored.txInfo);

        if (multi) revert Error.INVALID_PAYLOAD();

        InitSingleVaultData memory singleVaultData = abi.decode(
            stored.params,
            (InitSingleVaultData)
        );
        (address srcSender, uint16 srcChainId, ) = _decodeTxData(
            singleVaultData.txData
        );

        if (returnDataSrcChainId != srcChainId)
            revert Error.SRC_CHAIN_IDS_MISMATCH();

        if (
            returnDataDstChainId !=
            _getDestinationChain(singleVaultData.superFormId)
        ) revert Error.DST_CHAIN_IDS_MISMATCH();

        if (txType == uint256(TransactionType.DEPOSIT)) {
            ISuperPositions(superRegistry.superPositions()).mintSingleSP(
                srcSender,
                singleVaultData.superFormId,
                returnData.amount,
                ""
            );
        } else if (txType == uint256(TransactionType.WITHDRAW)) {
            bytes memory extraData = singleVaultData.extraFormData; // TODO read customForm type here
            uint256 index = abi.decode(extraData, (uint256));

            /// FIXME: We can pack status into extraData, modify it on destination, but... should we modify it?
            /// Everything has a drawback. Current solution with uint16 status packing is PoC.
            if (status == 0) {
                _burnPositionSingle(srcSender, index);
            } else if (status == 1) {
                /// requestUnlock happened on DST, we already hold position in superBank
                /// TODO: NOTE: SO, now what? We need to verify _owner balance against another withdraw call!
                emit Status(returnDataTxId, status);
            } else {
                /// @dev TODO: Placeholder
                emit Status(returnDataTxId, status);
            }

            /// TODO: Address discrepancy between using and not using status, check TokenBank._dispatchPayload()
        } else if (callbackType == uint256(CallbackType.FAIL)) {
            bytes memory extraData = singleVaultData.extraFormData; // TODO read customForm type here
            uint256 index = abi.decode(extraData, (uint256));

            _returnPositionSingle(srcSender, index);
        } else {
            revert Error.INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnDataTxId);
    }

    /// @notice Intended to be called in case of failure to perform Withdraw, we just return SuperPositions to owner
    function _returnPositionSingle(
        address owner_,
        uint256 positionIndex
    ) internal {
        PositionSingle memory position = queueSingle[owner_][positionIndex];
        /// @dev owner_ is arbitrary argument, re-think this
        delete queueSingle[owner_][positionIndex];
        ISuperPositions(superRegistry.superPositions()).safeTransferFrom(
            address(this),
            owner_,
            position.tokenId,
            position.amount,
            ""
        );
    }

    /// @notice Intended to be called in case of failure to perform Withdraw, we just return SuperPositions to owner
    /// TODO: Implement at the SuperRouter side!
    /// NOTE: Relevant for Try/catch arc when messaging is solved
    function _returnPositionBatch(
        address owner_,
        uint256 positionIndex
    ) internal {
        PositionBatch memory position = queueBatch[owner_][positionIndex];
        /// @dev owner_ is arbitrary argument, re-think this
        delete queueBatch[owner_][positionIndex];
        ISuperPositions(superRegistry.superPositions()).safeBatchTransferFrom(
            address(this),
            owner_,
            position.tokenIds,
            position.amounts,
            ""
        );
    }

    /// @notice Intended to be called in case Withdraw succeds and we can safely burn SuperPositions for owner
    function _burnPositionSingle(
        address owner_,
        uint256 positionIndex
    ) internal {
        PositionSingle memory position = queueSingle[owner_][positionIndex];
        /// alternative is to transfer back to source and burn there
        delete queueSingle[owner_][positionIndex];

        ISuperPositions(superRegistry.superPositions()).burnSingleSP(
            address(this),
            position.tokenId,
            position.amount
        );
    }

    /// @notice Intended to be called in case Withdraw succeds and we can safely burn SuperPositions for owner
    function _burnPositionBatch(
        address owner_,
        uint256 positionIndex
    ) internal {
        PositionBatch memory position = queueBatch[owner_][positionIndex];
        delete queueBatch[owner_][positionIndex];

        ISuperPositions(superRegistry.superPositions()).burnBatchSP(
            address(this),
            position.tokenIds,
            position.amounts
        );
    }

    /// @dev Private queue requires public getter
    function getPositionSingle(
        address owner_,
        uint256 positionIndex
    ) public view returns (uint256 tokenId, uint256 amount) {
        PositionSingle memory position = queueSingle[owner_][positionIndex];
        return (position.tokenId, position.amount);
    }

    /// @dev Private queue requires public getter
    function getPositionBatch(
        address owner_,
        uint256 positionIndex
    ) public view returns (uint256[] memory tokenIds, uint256[] memory amount) {
        PositionBatch memory position = queueBatch[owner_][positionIndex];
        return (position.tokenIds, position.amounts);
    }

    /// @dev See {ERC1155s-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
