// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { SignatureChecker } from "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import { EIP712 } from "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
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
import { Error } from "src/libraries/Error.sol";

contract SuperformRouterWrapper is IERC1155Receiver, EIP712 {
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                       ERRORS                             //
    //////////////////////////////////////////////////////////////

    error EXPIRED();
    error AUTHORIZATION_USED();
    error INVALID_AUTHORIZATION();
    error NOT_ROUTER_WRAPPER_PROCESSOR();

    //////////////////////////////////////////////////////////////
    //                       EVENTS                             //
    //////////////////////////////////////////////////////////////

    event RebalanceCompleted(address indexed receiver, uint256 indexed id, uint256 amount, bool smartWallet);

    event XChainRebalanceInitiated(
        address indexed receiver,
        uint256 indexed id,
        uint256 amount,
        bool smartWallet,
        address interimAsset,
        uint256 finalizeSlippage,
        uint256 expectedAmountInterimAsset
    );
    event XChainRebalanceFailed(address indexed receiver, uint256 indexed firstStepLastCSRPayloadId);

    event XChainRebalanceComplete(address indexed receiver, uint256 indexed firstStepLastCSRPayloadId);

    event WithdrawCompleted(address indexed receiver, uint256 indexed id, uint256 amount);

    event WithdrawMultiCompleted(address indexed receiver, uint256[] indexed ids, uint256[] amounts);

    event Deposit4626Completed(address indexed receiver, address indexed vault);

    event DepositCompleted(address indexed receiver, bool smartWallet, bool meta);

    event DisbursementCompleted(address indexed receiver, uint256 indexed payloadId);

    //////////////////////////////////////////////////////////////
    //                       CONSTANTS                          //
    //////////////////////////////////////////////////////////////
    ISuperRegistry public immutable superRegistry;
    uint256 internal constant ENTIRE_SLIPPAGE = 10_000;

    IBaseStateRegistry public immutable CORE_STATE_REGISTRY;
    address public immutable SUPERFORM_ROUTER;
    address public immutable SUPER_POSITIONS;

    bytes32 public constant DEPOSIT_TYPEHASH = keccak256(
        "MetaDeposit(address asset_,uint256 amount_,address receiverAddressSP_,bool smartWallet_,bytes calldata callData_,uint256 deadline_,bytes32 nonce_,bytes memory signature_,uint256 deadline_,bytes32 nonce_)"
    );

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    struct XChainRebalanceData {
        bytes rebalanceCalldata;
        bool smartWallet;
        address interimAsset;
    }

    mapping(uint256 payloadId => address user) public msgSenderMap;
    mapping(uint256 payloadId => bool processed) public statusMap;
    mapping(address => mapping(bytes32 => bool)) public authorizations;
    mapping(address receiverAddressSP => mapping(uint256 firstStepLastCSRPayloadId => XChainRebalanceData data)) public
        xChainRebalanceCallData;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyRouterWrapperProcessor() {
        if (
            !ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(
                keccak256("ROUTER_WRAPPER_PROCESSOR"), msg.sender
            )
        ) {
            revert NOT_ROUTER_WRAPPER_PROCESSOR();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(
        address superRegistry_,
        address superformRouter_,
        address superPositions_,
        IBaseStateRegistry coreStateRegistry_
    )
        EIP712("SuperformRouterWrapper", "1")
    {
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
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @dev helps user rebalance a single SuperPosition in a synchronous way
    /// @param id_ the superform id to redeem from
    /// @param sharesToRedeem_ the amount of superform shares to redeem
    /// @param previewRedeemAmount_ the amount of asset to receive after redeeming
    /// @param slippage_ the slippage to allow for the rebalance
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param vaultAsset the asset to receive after redeeming
    /// @param smartWallet_ whether to use smart wallet or not
    /// @param callData_ the encoded superform router request
    /// @param rebalanceCallData_ the encoded superform router request for the rebalance
    function rebalancePositionsSync(
        uint256 id_,
        uint256 sharesToRedeem_,
        uint256 previewRedeemAmount_,
        uint256 slippage_,
        address receiverAddressSP_,
        address vaultAsset,
        bool smartWallet_,
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        payable
    {
        _rebalancePositionsSync(
            id_,
            sharesToRedeem_,
            previewRedeemAmount_,
            slippage_,
            receiverAddressSP_,
            vaultAsset,
            smartWallet_,
            callData_,
            rebalanceCallData_
        );
    }

    /// @dev initiates the rebalance process for when the vault to redeem from is on a different chain
    /// @param id_ the superform id to redeem from
    /// @param sharesToRedeem_ the amount of superform shares to redeem
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param interimAsset_ the asset to receive on the other chain
    /// @param finalizeSlippage_ the slippage to allow for the finalize step
    /// @param expectedAmountInterimAsset_ the expected amount of interim asset to receive
    /// @param smartWallet_ whether to use smart wallet or not
    /// @param callData_ the encoded superform router request
    /// @param rebalanceCallData_ the encoded superform router request for the rebalance
    function initiateXChainRebalance(
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
    {
        /// @dev step 1: send SPs to wrapper
        _transferSuperPositions(receiverAddressSP_, id_, sharesToRedeem_);

        /// @dev step 2: send SPs to router
        _callSuperformRouter(callData_);

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

    /// @dev completes the rebalance process for when the vault to redeem from is on a different chain
    /// @notice rebalanceCalldata can contain multiple destinations or vaults, but external asset remains one
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param firstStepLastCSRPayloadId_ the first step payload id
    /// @param amountReceivedInterimAsset_ the amount of interim asset received
    function finalizeXChainRebalance(
        address receiverAddressSP_,
        uint256 firstStepLastCSRPayloadId_,
        uint256 amountReceivedInterimAsset_
    )
        external
        payable
        returns (bool rebalanceSuccessful)
    {
        XChainRebalanceData memory data = xChainRebalanceCallData[receiverAddressSP_][firstStepLastCSRPayloadId_];

        IERC20 interimAsset = IERC20(data.interimAsset);
        if (
            ENTIRE_SLIPPAGE * amountReceivedInterimAsset_
                < ((data.expectedAmountInterimAsset * (ENTIRE_SLIPPAGE - data.slippage)))
        ) {
            interimAsset.safeTransferFrom(address(this), receiverAddressSP_, amountReceivedInterimAsset_);

            emit XChainRebalanceFailed(receiverAddressSP_, firstStepLastCSRPayloadId_);
            return false;
        }

        data.smartWallet
            ? _depositUsingSmartWallet(
                interimAsset, amountReceivedInterimAsset_, receiverAddressSP_, data.rebalanceCalldata
            )
            : _deposit(interimAsset, amountReceivedInterimAsset_, receiverAddressSP_, data.rebalanceCalldata);

        emit XChainRebalanceComplete(receiverAddressSP_, firstStepLastCSRPayloadId_);

        return true;
    }

    /// NOTE: add function for same chain action
    /// NOTE: just 4626 shares
    /// @dev helps user deposit 4626 vault shares into superform
    /// @dev this helps with goal "2 Entering Superform via any 4626 share in one step by transfering the share to the
    /// specific superform"
    /// @param vault_ the 4626 vault to redeem from
    /// @param amount_ the 4626 vault share amount to redeem
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param smartWallet_ whether to use smart wallet or not
    /// @param callData_ the encoded superform router request
    function deposit4626(
        address vault_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata callData_
    )
        external
        payable
    {
        _transferERC20In(IERC20(vault_), receiverAddressSP_, amount_);

        uint256 amountRedeemed = _redeemShare(IERC4626(vault_), amount_);

        IERC20 asset = IERC4626(vault_).asset();

        smartWallet_
            ? _depositUsingSmartWallet(asset, amountRedeemed, receiverAddressSP_, callData_)
            : _deposit(asset, amountRedeemed, receiverAddressSP_, callData_);

        emit Deposit4626Completed(receiverAddressSP_, vault_);
    }

    /// @dev helps user deposit into superform
    /// @dev should only allow a single asset to be deposited (because this is similar to a normal deposit)
    /// @dev adds smart wallet support
    /// @dev this covers the goal "3 Providing better compatibility with smart contract wallets such as coinbase smart
    /// wallet"
    /// @param asset_ the ERC20 asset to deposit
    /// @param amount_ the ERC20 amount to deposit
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param smartWallet_ whether to use smart wallet or not
    /// @param callData_ the encoded superform router deposit request
    function deposit(
        IERC20 asset_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata callData_
    )
        external
        payable
    {
        _transferERC20In(asset_, receiverAddressSP_, amount_);

        smartWallet_
            ? _depositUsingSmartWallet(asset_, amount_, receiverAddressSP_, callData_)
            : _deposit(asset_, amount_, receiverAddressSP_, callData_);

        emit DepositCompleted(receiverAddressSP_, smartWallet_, false);
    }

    /// @dev allows gasless transactions for the function above
    /// @notice misses logic to covert a portion of amount to native tokens for the keeper
    /// @dev this helps with goal "4 Allow for gasless transactions where tx costs are deducted from funding tokens (or
    /// from SuperPositions) OR subsidized by Superform team."
    /// @dev user needs to set infinite allowance of assets to wrapper to allow this in smooth ux
    /// @param asset_ the ERC20 asset to deposit
    /// @param amount_ the ERC20 amount to deposit
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param smartWallet_ whether to use smart wallet or not
    /// @param callData_ the encoded superform router deposit request
    /// @param deadline_ the deadline for the authorization
    /// @param nonce_ the nonce for the authorization
    /// @param signature_ the signature for the authorization
    function metaDeposit(
        address asset_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata callData_,
        uint256 deadline_,
        bytes32 nonce_,
        bytes memory signature_
    )
        external
        onlyRouterWrapperProcessor
    {
        _setAuthorizationNonce(deadline_, receiverAddressSP_, nonce_);

        _checkSignature(
            receiverAddressSP_,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _domainSeparatorV4(),
                    keccak256(
                        abi.encode(
                            DEPOSIT_TYPEHASH,
                            asset_,
                            amount_,
                            receiverAddressSP_,
                            smartWallet_,
                            callData_,
                            deadline_,
                            nonce_
                        )
                    )
                )
            ),
            signature_
        );

        IERC20 asset = IERC20(asset_);

        _transferERC20In(asset, receiverAddressSP_, amount_);

        /// add logic to take a portion of shares as native for keeper
        /// @dev e.g
        uint256 amountToDeposit = amount_ - (amount_ / 10);

        smartWallet_
            ? _depositUsingSmartWallet(asset_, amountToDeposit, receiverAddressSP_, callData_)
            : _deposit(asset_, amountToDeposit, receiverAddressSP_, callData_);

        emit DepositCompleted(receiverAddressSP_, smartWallet_, true);
    }

    /// @dev this is callback payload id
    /// @dev this covers the goal "3 Providing better compatibility with smart contract wallets such as coinbase smart
    /// wallet"
    /// @param csrAckPayloadId_ the payload id to complete the disbursement
    function completeDisbursement(uint256 csrAckPayloadId_) external {
        _completeDisbursement(csrAckPayloadId_);
    }

    /// @dev batch version of the function above
    /// @param csrAckPayloadIds_ the payload ids to complete the disbursement
    function batchCompleteDisbursement(uint256[] calldata csrAckPayloadIds_) external {
        uint256 len = csrAckPayloadIds_.length;
        if (len == 0) revert Error.ZERO_LENGTH();
        for (uint256 i = 0; i < len; i++) {
            _completeDisbursement(csrAckPayloadIds_[i]);
        }
    }

    /// @dev helps user exit SuperPositions
    /// @dev TODO decide if needed
    /// @dev TODO can decode callData to obtain dstChains and message wrapper accordingly to allow rebalances in dsts
    /// (advanced)
    function withdraw(
        uint256 id_,
        uint256 amount_,
        address receiverAddressSP_,
        bytes calldata callData_
    )
        external
        payable
    {
        _transferSuperPositions(receiverAddressSP_, id_, amount_);

        _callSuperformRouter(callData_);

        emit WithdrawCompleted(receiverAddressSP_, id_, amount_);
    }

    /// @dev batch version of the function above
    /// @dev TODO decide if needed
    function withdrawMulti(
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        address receiverAddressSP_,
        bytes calldata callData_
    )
        external
        payable
    {
        _transferBatchSuperPositions(receiverAddressSP_, ids_, amounts_);

        _callSuperformRouter(callData_);

        emit WithdrawMultiCompleted(receiverAddressSP_, ids_, amounts_);
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
        uint256 id_,
        uint256 sharesToRedeem_,
        uint256 previewRedeemAmount_,
        uint256 slippage_,
        address receiverAddressSP_,
        address vaultAsset,
        bool smartWallet_,
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        internal
    {
        /// @dev step 1: send SPs to wrapper
        _transferSuperPositions(receiverAddressSP_, id_, sharesToRedeem_);

        IERC20 asset = IERC20(vaultAsset);

        uint256 balanceBefore = asset.balanceOf(address(this));

        /// @dev step 2: send SPs to router
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

        emit RebalanceCompleted(receiverAddressSP_, id_, sharesToRedeem_, smartWallet_);
    }

    function _setAuthorizationNonce(uint256 deadline_, address user_, bytes32 nonce_) internal {
        if (block.timestamp > deadline_) revert EXPIRED();
        if (authorizations[user_][nonce_]) revert AUTHORIZATION_USED();

        authorizations[user_][nonce_] = true;
    }

    function _checkSignature(address user_, bytes32 digest_, bytes memory signature_) internal {
        if (!SignatureChecker.isValidSignatureNow(user_, digest_, signature_)) revert INVALID_AUTHORIZATION();
    }

    /// @dev refunds any unused refunds
    function _processRefunds(IERC20 asset_, address user_) internal {
        uint256 balance = asset_.balanceOf(address(this));

        if (balance > 0) {
            asset_.transfer(user_, balance);
        }
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
    function _callSuperformRouter(bytes calldata callData_) internal {
        (bool success, bytes memory returndata) = SUPERFORM_ROUTER.call{ value: msg.value }(callData_);

        Address.verifyCallResult(success, returndata);
    }

    function _transferERC20In(IERC20 erc20_, address user_, uint256 amount_) internal {
        erc20_.transferFrom(user_, address(this), amount_);
    }

    function _redeemShare(IERC4626 vault_, uint256 amountToRedeem_) internal returns (uint256 balanceDifference) {
        IERC20 asset = vault_.asset();
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
        bytes calldata callData_
    )
        internal
    {
        /// @dev approves superform router on demand
        asset_.approve(SUPERFORM_ROUTER, amountToDeposit_);

        _callSuperformRouter(callData_);

        /// @dev refund any unused funds
        _processRefunds(asset_, receiverAddressSP_);
    }

    function _depositUsingSmartWallet(
        IERC20 asset_,
        uint256 amountToDeposit_,
        address receiverAddressSP_,
        bytes calldata callData_
    )
        internal
    {
        /// @dev approves superform router on demand
        asset_.approve(SUPERFORM_ROUTER, amountToDeposit_);
        uint256 payloadStartCount = CORE_STATE_REGISTRY.payloadsCount();

        _callSuperformRouter(callData_);

        uint256 payloadEndCount = CORE_STATE_REGISTRY.payloadsCount();

        if (payloadEndCount - payloadStartCount > 0) {
            for (uint256 i = payloadStartCount; i < payloadEndCount; i++) {
                msgSenderMap[i] = receiverAddressSP_;
            }
        }

        /// @dev refund any unused funds
        _processRefunds(asset_, receiverAddressSP_);
    }

    function _completeDisbursement(uint256 csrAckPayloadId) internal {
        address receiverAddressSP = msgSenderMap[payloadId];

        if (receiverAddressSP == address(0)) revert Error.INVALID_PAYLOAD_ID();
        mapping(uint256 => bool) storage statusMapLoc = statusMap;

        if (statusMapLoc[payloadId]) revert Error.PAYLOAD_ALREADY_PROCESSED();

        statusMapLoc = true;

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

        emit DisbursementCompleted(receiverAddressSP, payloadId);
    }
}
