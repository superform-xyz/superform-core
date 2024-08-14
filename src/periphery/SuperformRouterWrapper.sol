// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { SignatureChecker } from "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { IERC1155 } from "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import { IERC1155Receiver } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {
    PayloadState,
    AMBMessage,
    CallbackType,
    TransactionType,
    ReturnSingleData,
    ReturnMultiData
} from "src/types/DataTypes.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { SuperPositions } from "src/SuperPositions.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { ISuperformRouterWrapper, IERC20 } from "src/interfaces/ISuperformRouterWrapper.sol";
import { Error } from "src/libraries/Error.sol";

contract SuperformRouterWrapper is ISuperformRouterWrapper, IERC1155Receiver {
    using DataLib for uint256;
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////
    //                       CONSTANTS                          //
    //////////////////////////////////////////////////////////////
    ISuperRegistry public immutable superRegistry;
    uint256 internal constant ENTIRE_SLIPPAGE = 10_000;

    IBaseStateRegistry public immutable CORE_STATE_REGISTRY;
    address public immutable SUPERFORM_ROUTER;
    address public immutable SUPER_POSITIONS;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    mapping(uint256 payloadId => address user) public msgSenderMap;
    mapping(uint256 payloadId => bool processed) public statusMap;
    mapping(address => mapping(bytes32 => bool)) public authorizations;
    mapping(address receiverAddressSP => mapping(uint256 firstStepLastCSRPayloadId => XChainRebalanceData data)) public
        xChainRebalanceCallData;
    mapping(Actions => mapping(bytes4 => bool)) public whitelistedSelectors;
    mapping(uint256 lastPayloadId => Refund) public refunds;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyRouterWrapperProcessor() {
        if (!_hasRole(keccak256("ROUTER_WRAPPER_PROCESSOR"), msg.sender)) {
            revert NOT_ROUTER_WRAPPER_PROCESSOR();
        }
        _;
    }

    /// @dev refunds any unused refunds
    modifier refundUnused(address asset_, address user_) {
        uint256 balanceBefore = IERC20(asset_).balanceOf(address(this));

        _;

        uint256 balanceDiff = IERC20(asset_).balanceOf(address(this)) - balanceBefore;

        if (balanceDiff > 0) {
            IERC20(asset_).transfer(user_, balanceDiff);
        }
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(
        address superRegistry_,
        address superformRouter_,
        address superPositions_,
        IBaseStateRegistry coreStateRegistry_
    ) {
        if (
            superRegistry_ == address(0) || superformRouter_ == address(0) || superPositions_ == address(0)
                || address(coreStateRegistry_) == address(0)
        ) {
            revert Error.ZERO_ADDRESS();
        }

        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }
        superRegistry = ISuperRegistry(superRegistry_);

        SUPERFORM_ROUTER = superformRouter_;
        SUPER_POSITIONS = superPositions_;
        CORE_STATE_REGISTRY = coreStateRegistry_;
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL PROTECTED FUNCTIONS            //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperformRouterWrapper
    function finalizeDisbursement(uint256 csrAckPayloadId_) external override onlyRouterWrapperProcessor {
        address receiverAddressSP = _completeDisbursement(csrAckPayloadId_);

        emit DisbursementCompleted(receiverAddressSP, csrAckPayloadId_);
    }

    /// @inheritdoc ISuperformRouterWrapper
    function finalizeBatchDisbursement(uint256[] calldata csrAckPayloadIds_)
        external
        override
        onlyRouterWrapperProcessor
    {
        uint256 len = csrAckPayloadIds_.length;
        if (len == 0) revert Error.ARRAY_LENGTH_MISMATCH();
        address receiverAddressSP;
        for (uint256 i; i < len; i++) {
            receiverAddressSP = _completeDisbursement(csrAckPayloadIds_[i]);
            emit DisbursementCompleted(receiverAddressSP, csrAckPayloadIds_[i]);
        }
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperformRouterWrapper
    function rebalanceSinglePosition(
        uint256 id_,
        uint256 sharesToRedeem_,
        uint256 previewRedeemAmount_,
        address vaultAsset_,
        uint256 slippage_,
        address receiverAddressSP_,
        bytes calldata callData_,
        bytes calldata rebalanceCallData_,
        bool smartWallet_
    )
        external
        payable
        override
        refundUnused(vaultAsset_, receiverAddressSP_)
    {
        _transferSuperPositions(receiverAddressSP_, id_, sharesToRedeem_);

        _rebalancePositionsSync(
            previewRedeemAmount_,
            vaultAsset_,
            slippage_,
            receiverAddressSP_,
            smartWallet_,
            callData_,
            rebalanceCallData_,
            false
        );

        emit RebalanceSyncCompleted(receiverAddressSP_, id_, sharesToRedeem_, smartWallet_);
    }

    /// @inheritdoc ISuperformRouterWrapper
    function rebalanceMultiPositions(RebalanceMultiPositionsSyncArgs memory args) external payable override {
        uint256 len = args.ids.length;
        if (len != args.sharesToRedeem.length) {
            revert Error.ARRAY_LENGTH_MISMATCH();
        }

        for (uint256 i; i < len; ++i) {
            /// @dev step 1: send SPs to wrapper
            _transferSuperPositions(args.receiverAddressSP, args.ids[i], args.sharesToRedeem[i]);
        }

        _rebalancePositionsSync(
            args.previewRedeemAmount,
            args.interimAsset,
            args.slippage,
            args.receiverAddressSP,
            args.smartWallet,
            args.callData,
            args.rebalanceCallData,
            true
        );

        emit RebalanceMultiSyncCompleted(args.receiverAddressSP, args.ids, args.sharesToRedeem, args.smartWallet);
    }

    /// @inheritdoc ISuperformRouterWrapper
    function startCrossChainRebalance(
        uint256 id_,
        uint256 sharesToRedeem_,
        address receiverAddressSP_,
        address interimAsset_,
        uint256 finalizeSlippage_,
        uint256 expectedAmountInterimAsset_,
        bool smartWallet_,
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        payable
        override
    {
        /// @dev step 1: send SPs to wrapper
        _transferSuperPositions(receiverAddressSP_, id_, sharesToRedeem_);

        if (!whitelistedSelectors[Actions.WITHDRAWAL][_parseSelectorMem(callData_)]) {
            revert INVALID_REDEEM_SELECTOR();
        }
        /// @dev step 2: send SPs to router
        _callSuperformRouter(callData_);

        if (!whitelistedSelectors[Actions.DEPOSIT][_parseSelectorMem(rebalanceCallData_)]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }
        /// notice rebalanceCallData can be multi Dst / multi vault
        xChainRebalanceCallData[receiverAddressSP_][CORE_STATE_REGISTRY.payloadsCount()] = XChainRebalanceData({
            rebalanceCalldata: rebalanceCallData_,
            smartWallet: smartWallet_,
            interimAsset: interimAsset_,
            slippage: finalizeSlippage_,
            expectedAmountInterimAsset: expectedAmountInterimAsset_
        });

        emit XChainRebalanceInitiated(
            receiverAddressSP_,
            id_,
            sharesToRedeem_,
            smartWallet_,
            interimAsset_,
            finalizeSlippage_,
            expectedAmountInterimAsset_
        );
    }

    /// @inheritdoc ISuperformRouterWrapper
    function startCrossChainRebalanceMulti(InitiateXChainRebalanceMultiArgs memory args) external payable override {
        uint256 len = args.ids.length;
        if (len != args.sharesToRedeem.length) {
            revert Error.ARRAY_LENGTH_MISMATCH();
        }

        for (uint256 i; i < len; ++i) {
            /// @dev step 1: send SPs to wrapper
            _transferSuperPositions(args.receiverAddressSP, args.ids[i], args.sharesToRedeem[i]);
        }

        if (!whitelistedSelectors[Actions.WITHDRAWAL][_parseSelectorMem(args.callData)]) {
            revert INVALID_REDEEM_SELECTOR();
        }

        /// @dev step 2: send SPs to router
        _callSuperformRouter(args.callData);

        if (!whitelistedSelectors[Actions.DEPOSIT][_parseSelectorMem(args.rebalanceCallData)]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }
        /// notice rebalanceCallData can be multi Dst / multi vault
        xChainRebalanceCallData[args.receiverAddressSP][CORE_STATE_REGISTRY.payloadsCount()] = XChainRebalanceData({
            rebalanceCalldata: args.rebalanceCallData,
            smartWallet: args.smartWallet,
            interimAsset: args.interimAsset,
            slippage: args.finalizeSlippage,
            expectedAmountInterimAsset: args.expectedAmountInterimAsset
        });

        emit XChainRebalanceMultiInitiated(
            args.receiverAddressSP,
            args.ids,
            args.sharesToRedeem,
            args.smartWallet,
            args.interimAsset,
            args.finalizeSlippage,
            args.expectedAmountInterimAsset
        );
    }

    /// @inheritdoc ISuperformRouterWrapper
    function completeCrossChainRebalance(
        address receiverAddressSP_,
        uint256 firstStepLastCSRPayloadId_,
        uint256 amountReceivedInterimAsset_
    )
        external
        payable
        override
        returns (bool rebalanceSuccessful)
    {
        XChainRebalanceData memory data = xChainRebalanceCallData[receiverAddressSP_][firstStepLastCSRPayloadId_];

        if (
            ENTIRE_SLIPPAGE * amountReceivedInterimAsset_
                < ((data.expectedAmountInterimAsset * (ENTIRE_SLIPPAGE - data.slippage)))
        ) {
            refunds[firstStepLastCSRPayloadId_] =
                Refund(receiverAddressSP_, data.interimAsset, amountReceivedInterimAsset_, block.timestamp);

            emit RefundInitiated(
                firstStepLastCSRPayloadId_, receiverAddressSP_, data.interimAsset, amountReceivedInterimAsset_
            );
            emit XChainRebalanceFailed(receiverAddressSP_, firstStepLastCSRPayloadId_);
            return false;
        }

        IERC20 interimAsset = IERC20(data.interimAsset);
        data.smartWallet
            ? _depositUsingSmartWallet(
                interimAsset, amountReceivedInterimAsset_, receiverAddressSP_, data.rebalanceCalldata
            )
            : _deposit(interimAsset, amountReceivedInterimAsset_, receiverAddressSP_, data.rebalanceCalldata);

        emit XChainRebalanceComplete(receiverAddressSP_, firstStepLastCSRPayloadId_);

        return true;
    }

    /// @inheritdoc ISuperformRouterWrapper
    function deposit4626(
        address vault_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata callData_
    )
        external
        payable
        override
    {
        _transferERC20In(IERC20(vault_), receiverAddressSP_, amount_);
        IERC4626 vault = IERC4626(vault_);
        uint256 amountRedeemed = _redeemShare(vault, amount_);

        IERC20 asset = IERC20(vault.asset());

        smartWallet_
            ? _depositUsingSmartWallet(asset, amountRedeemed, receiverAddressSP_, callData_)
            : _deposit(asset, amountRedeemed, receiverAddressSP_, callData_);

        emit Deposit4626Completed(receiverAddressSP_, vault_);
    }

    /// @inheritdoc ISuperformRouterWrapper
    function deposit(
        IERC20 asset_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata callData_
    )
        public
        payable
        override
    {
        _transferERC20In(asset_, receiverAddressSP_, amount_);

        smartWallet_
            ? _depositUsingSmartWallet(asset_, amount_, receiverAddressSP_, callData_)
            : _deposit(asset_, amount_, receiverAddressSP_, callData_);

        emit DepositCompleted(receiverAddressSP_, smartWallet_, false);
    }

    /// @inheritdoc ISuperformRouterWrapper
    function batchDeposit(
        IERC20[] calldata asset_,
        uint256[] calldata amount_,
        address[] calldata receiverAddressSP_,
        bool[] calldata smartWallet_,
        bytes[] calldata callData_
    )
        external
        payable
        override
    {
        uint256 len = asset_.length;

        if (
            len == 0 || len != amount_.length || len != receiverAddressSP_.length || len != smartWallet_.length
                || len != callData_.length
        ) {
            revert Error.ARRAY_LENGTH_MISMATCH();
        }

        for (uint256 i; i < len; ++i) {
            deposit(asset_[i], amount_[i], receiverAddressSP_[i], smartWallet_[i], callData_[i]);
        }
    }

    /// @inheritdoc ISuperformRouterWrapper
    function withdrawSinglePosition(
        uint256 id_,
        uint256 amount_,
        address receiverAddressSP_,
        bytes calldata callData_
    )
        external
        payable
        override
    {
        _transferSuperPositions(receiverAddressSP_, id_, amount_);

        _callSuperformRouter(callData_);

        emit WithdrawCompleted(receiverAddressSP_, id_, amount_);
    }

    /// @inheritdoc ISuperformRouterWrapper
    function withdrawMultiPositions(
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        address receiverAddressSP_,
        bytes calldata callData_
    )
        external
        payable
        override
    {
        _transferBatchSuperPositions(receiverAddressSP_, ids_, amounts_);

        _callSuperformRouter(callData_);

        emit WithdrawMultiCompleted(receiverAddressSP_, ids_, amounts_);
    }

    /// @inheritdoc ISuperformRouterWrapper
    function disputeRefund(uint256 finalPayloadId_) external override {
        Refund storage r = refunds[finalPayloadId_];

        /// TODO: check if a new role is needed here
        if (!(msg.sender == r.receiver || _hasRole(keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE"), msg.sender))) {
            revert Error.NOT_VALID_DISPUTER();
        }

        if (r.proposedTime == 0 || block.timestamp > r.proposedTime + _getDelay()) revert Error.DISPUTE_TIME_ELAPSED();

        /// @dev just can reset the last proposed time, since amounts should be updated again to
        /// pass the proposedTime zero check in finalize
        r.proposedTime = 0;

        emit RefundDisputed(finalPayloadId_, msg.sender);
    }

    /// @inheritdoc ISuperformRouterWrapper
    function proposeRefund(uint256 finalPayloadId_, uint256 refundAmount_) external {
        /// TODO: check if a new role is needed here
        if (!_hasRole(keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"), msg.sender)) revert INVALID_PROPOSER();

        Refund storage r = refunds[finalPayloadId_];

        if (r.interimToken == address(0) || r.receiver == address(0)) revert INVALID_REFUND_DATA();
        if (r.proposedTime != 0) revert REFUND_ALREADY_PROPOSED();

        r.proposedTime = block.timestamp;
        r.amount = refundAmount_;

        emit NewRefundAmountProposed(finalPayloadId_, refundAmount_);
    }

    /// @inheritdoc ISuperformRouterWrapper
    function finalizeRefund(uint256 finalPayloadId_) external {
        Refund memory r = refunds[finalPayloadId_];

        if (r.proposedTime == 0 || block.timestamp <= r.proposedTime + _getDelay()) revert IN_DISPUTE_PHASE();

        /// @dev deleting to prevent re-entrancy
        delete refunds[finalPayloadId_];

        IERC20(r.interimToken).safeTransfer(r.receiver, r.amount);

        emit RefundCompleted(finalPayloadId_, msg.sender);
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL PURE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @dev overrides receive functions
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    )
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    )
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    //////////////////////////////////////////////////////////////
    //                   INTERNAL FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    function _rebalancePositionsSync(
        uint256 previewRedeemAmount_,
        address asset_,
        uint256 slippage_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes memory callData_,
        bytes memory rebalanceCallData_,
        bool multi
    )
        internal
    {
        IERC20 asset = IERC20(asset_);

        uint256 balanceBefore = asset.balanceOf(address(this));

        if (!whitelistedSelectors[Actions.WITHDRAWAL][_parseSelectorMem(callData_)]) revert INVALID_REDEEM_SELECTOR();
        /// @dev step 2: send SPs to router
        /// @dev TODO: final asset of multi vault must be "interimAsset" otherwise funds can be lost (validations
        /// needed)
        _callSuperformRouter(callData_);

        uint256 balanceAfter = asset.balanceOf(address(this));

        uint256 amountToDeposit = balanceAfter - balanceBefore;

        if (amountToDeposit == 0) revert Error.ZERO_AMOUNT();

        if (ENTIRE_SLIPPAGE * amountToDeposit < ((previewRedeemAmount_ * (ENTIRE_SLIPPAGE - slippage_)))) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }

        /// @dev step 3: rebalance into a new superform with rebalanceCallData_
        /// @dev this can be same chain or cross chain
        smartWallet_
            ? _depositUsingSmartWallet(asset, amountToDeposit, receiverAddressSP_, rebalanceCallData_)
            : _deposit(asset, amountToDeposit, receiverAddressSP_, rebalanceCallData_);
    }

    function _setAuthorizationNonce(uint256 deadline_, address user_, bytes32 nonce_) internal {
        if (block.timestamp > deadline_) revert EXPIRED();
        if (authorizations[user_][nonce_]) revert AUTHORIZATION_USED();

        authorizations[user_][nonce_] = true;
    }

    function _checkSignature(address user_, bytes32 digest_, bytes memory signature_) internal view {
        if (!SignatureChecker.isValidSignatureNow(user_, digest_, signature_)) revert INVALID_AUTHORIZATION();
    }

    function _transferSuperPositions(address user_, uint256 id_, uint256 amount_) internal {
        SuperPositions(SUPER_POSITIONS).safeTransferFrom(user_, address(this), id_, amount_, "");
        SuperPositions(SUPER_POSITIONS).setApprovalForOne(SUPERFORM_ROUTER, id_, amount_);
    }

    function _transferBatchSuperPositions(
        address user_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_
    )
        internal
    {
        SuperPositions(SUPER_POSITIONS).safeBatchTransferFrom(user_, address(this), ids_, amounts_, "");
        SuperPositions(SUPER_POSITIONS).setApprovalForAll(SUPERFORM_ROUTER, true);
    }

    /// @dev how to ensure call data only calls certain functions?
    function _callSuperformRouter(bytes memory callData_) internal {
        (bool success, bytes memory returndata) = SUPERFORM_ROUTER.call{ value: msg.value }(callData_);

        Address.verifyCallResult(success, returndata);
    }

    function _transferERC20In(IERC20 erc20_, address user_, uint256 amount_) internal {
        erc20_.transferFrom(user_, address(this), amount_);
    }

    function _redeemShare(IERC4626 vault_, uint256 amountToRedeem_) internal returns (uint256 balanceDifference) {
        IERC20 asset = IERC20(vault_.asset());
        uint256 collateralBalanceBefore = asset.balanceOf(address(this));

        /// @dev redeem the vault shares and receive collateral
        vault_.redeem(amountToRedeem_, address(this), address(this));

        /// @dev collateral balance after
        uint256 collateralBalanceAfter = asset.balanceOf(address(this));

        balanceDifference = collateralBalanceAfter - collateralBalanceBefore;
    }

    function _deposit(
        IERC20 asset_,
        uint256 amountToDeposit_,
        address receiverAddressSP_,
        bytes memory callData_
    )
        internal
    {
        /// @dev approves superform router on demand
        asset_.approve(SUPERFORM_ROUTER, amountToDeposit_);

        if (!whitelistedSelectors[Actions.DEPOSIT][_parseSelectorMem(callData_)]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }
        _callSuperformRouter(callData_);
    }

    function _depositUsingSmartWallet(
        IERC20 asset_,
        uint256 amountToDeposit_,
        address receiverAddressSP_,
        bytes memory callData_
    )
        internal
    {
        /// @dev approves superform router on demand
        asset_.approve(SUPERFORM_ROUTER, amountToDeposit_);
        uint256 payloadStartCount = CORE_STATE_REGISTRY.payloadsCount();

        if (!whitelistedSelectors[Actions.DEPOSIT][_parseSelectorMem(callData_)]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }
        _callSuperformRouter(callData_);

        uint256 payloadEndCount = CORE_STATE_REGISTRY.payloadsCount();

        if (payloadEndCount - payloadStartCount > 0) {
            for (uint256 i = payloadStartCount; i < payloadEndCount; i++) {
                msgSenderMap[i] = receiverAddressSP_;
            }
        }
    }

    function _completeDisbursement(uint256 csrAckPayloadId) internal returns (address receiverAddressSP) {
        receiverAddressSP = msgSenderMap[csrAckPayloadId];

        if (receiverAddressSP == address(0)) revert Error.INVALID_PAYLOAD_ID();
        mapping(uint256 => bool) storage statusMapLoc = statusMap;

        if (statusMapLoc[csrAckPayloadId]) revert Error.PAYLOAD_ALREADY_PROCESSED();

        statusMapLoc[csrAckPayloadId] = true;

        uint256 txInfo = CORE_STATE_REGISTRY.payloadHeader(csrAckPayloadId);

        (uint256 returnTxType, uint256 callbackType, uint8 multi,,,) = txInfo.decodeTxInfo();

        if (returnTxType != uint256(TransactionType.DEPOSIT) || callbackType != uint256(CallbackType.RETURN)) {
            revert();
        }

        uint256 payloadId;
        if (multi != 0) {
            ReturnMultiData memory returnData =
                abi.decode(CORE_STATE_REGISTRY.payloadBody(csrAckPayloadId), (ReturnMultiData));

            payloadId = returnData.payloadId;
            IERC1155(SUPER_POSITIONS).safeBatchTransferFrom(
                address(this), receiverAddressSP, returnData.superformIds, returnData.amounts, ""
            );
        } else {
            ReturnSingleData memory returnData =
                abi.decode(CORE_STATE_REGISTRY.payloadBody(csrAckPayloadId), (ReturnSingleData));

            payloadId = returnData.payloadId;
            IERC1155(SUPER_POSITIONS).safeTransferFrom(
                address(this), receiverAddressSP, returnData.superformId, returnData.amount, ""
            );
        }
    }

    /// @dev helps parse bytes memory selector
    function _parseSelectorMem(bytes memory data) internal pure returns (bytes4 selector) {
        assembly {
            selector := mload(add(data, 0x20))
        }
    }

    /// @dev returns the current dispute delay
    function _getDelay() internal view returns (uint256) {
        uint256 delay = superRegistry.delay();
        if (delay == 0) {
            revert Error.DELAY_NOT_SET();
        }
        return delay;
    }

    /// @dev returns if an address has a specific role
    function _hasRole(bytes32 id_, address addressToCheck_) internal view returns (bool) {
        return ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(id_, addressToCheck_);
    }
}
