// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BaseStateRegistry } from "src/crosschain-data/BaseStateRegistry.sol";
import { SignatureChecker } from "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IQuorumManager } from "src/interfaces/IQuorumManager.sol";
import { ISuperPositions } from "src/interfaces/ISuperPositions.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { IPaymentHelperV2 as IPaymentHelper } from "src/interfaces/IPaymentHelperV2.sol";
import { Error } from "src/libraries/Error.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { AMBMessage, CallbackType, PayloadState, ReturnSingleData, TransactionType } from "src/types/DataTypes.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { EIP712Lib } from "src/libraries/EIP712Lib.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

/// @title RebalanceStateRegistry
/// @author Zeropoint Labs
contract RebalanceStateRegistry is BaseStateRegistry {
    using DataLib for uint256;
    using ProofLib for AMBMessage;
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////
    //                       ERRORS                             //
    //////////////////////////////////////////////////////////////

    error NOT_REBALANCE_STATE_REGISTRY_PROCESSOR();
    error EXPIRED();
    error AUTHORIZATION_USED();
    error INVALID_AUTHORIZATION();
    //////////////////////////////////////////////////////////////
    //                       CONSTANTS                          //
    //////////////////////////////////////////////////////////////

    bytes32 private immutable nameHash;
    bytes32 private immutable versionHash;
    bytes32 private immutable _DOMAIN_SEPARATOR;

    bytes32 public constant ENTER_SUPERFORM_TYPEHASH = keccak256(
        "EnterSuperform(uint256 targetSuperformId_,address receiverAddressSP_,uint256 amount_,uint256 returnPayloadId_,uint64 targetChainId_,uint8[] memory ambIds_,uint256 deadline_,bytes32 nonce_)"
    );
    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    mapping(address => mapping(bytes32 => bool)) public authorizations;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyRebalanceRegistryProcessor() {
        if (
            !ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(
                keccak256("REBALANCE_STATE_REGISTRY_ROLE"), msg.sender
            )
        ) {
            revert NOT_REBALANCE_STATE_REGISTRY_PROCESSOR();
        }
        _;
    }

    /// @dev ensures only valid payloads are processed
    /// @param payloadId_ is the payloadId to check
    modifier isValidPayloadId(uint256 payloadId_) {
        if (payloadId_ > payloadsCount) {
            revert Error.INVALID_PAYLOAD_ID();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(ISuperRegistry superRegistry_) BaseStateRegistry(superRegistry_) {
        nameHash = keccak256(bytes("Superform"));
        versionHash = keccak256(bytes("1"));
        _DOMAIN_SEPARATOR = EIP712Lib.calculateDomainSeparator(nameHash, versionHash);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == CHAIN_ID ? _DOMAIN_SEPARATOR : EIP712Lib.calculateDomainSeparator(nameHash, versionHash);
    }
    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev keeper would call this with a valid user returnPayloadId referring to the user's home chain
    /// @dev crude implementation, with no slippage checks and ability to recover
    /// @dev note: this function is very powerful and can snatch tokens in transit just like in CSR updateDeposit /
    /// processPayload
    /// @dev note: currently only working for 4626 vaults
    /// @dev ux flow: user signs a message with a valid returnPayloadId referring to their receiverAddressSP_ if they
    /// intend to receive superPositions back in their home chain
    /// @dev ux flow2: user calls router wrapper and initiates redeem of existing superPositions to a new superform
    /// @notice security issue: how to validate that the funds that arrived here actually belong to the user?
    function rebalanceSuperPositionsTo(
        uint256 targetSuperformId_,
        address receiverAddressSP_,
        uint256 amountRedeemed_,
        uint256 returnPayloadId_,
        uint64 targetChainId_,
        uint8[] memory ambIds_,
        uint256 deadline_,
        bytes32 nonce_,
        bytes memory signature_
    )
        external
        onlyRebalanceRegistryProcessor
    {
        _rebalanceSuperPositionsTo(
            targetSuperformId_,
            receiverAddressSP_,
            amountRedeemed_,
            returnPayloadId_,
            targetChainId_,
            ambIds_,
            deadline_,
            nonce_,
            signature_
        );
    }

    /// @dev batch version of the function above
    function batchRebalanceSuperPositionsTo(
        uint256[] memory targetSuperformIds_,
        address[] memory receiverAddressSPs_,
        uint256[] memory amountsRedeemed_,
        uint256[] memory returnPayloadIds_,
        uint64[] memory targetChainIds_,
        uint8[][] memory ambIds_,
        uint256 deadline_,
        bytes32 nonce_,
        bytes memory signature_
    )
        external
        onlyRebalanceRegistryProcessor
    {
        uint256 len = targetSuperformIds_.length;
        if (
            len != receiverAddressSPs_.length || len != amountsRedeemed_.length || len != returnPayloadIds_.length
                || len != targetChainIds_.length || len != ambIds_.length
        ) {
            revert Error.ARRAY_LENGTH_MISMATCH();
        }
        for (uint256 i = 0; i < len; ++i) {
            _rebalanceSuperPositionsTo(
                targetSuperformIds_[i],
                receiverAddressSPs_[i],
                amountsRedeemed_[i],
                returnPayloadIds_[i],
                targetChainIds_[i],
                ambIds_[i],
                deadline_,
                nonce_,
                signature_
            );
        }
    }

    /// @dev users of this functionality are typically not superform users (therefore, don't have any returnPayloadId)
    /// @dev this function currently works same chain only.
    function enterSuperformWithSharesDirect(
        uint256 targetSuperformId_,
        address receiverAddressSP_,
        uint256 shares_,
        address srcSender_
    )
        external
    {
        if (targetSuperformId_ == 0) revert Error.SUPERFORM_ID_NONEXISTENT();

        if (shares_ == 0) revert Error.ZERO_AMOUNT();

        if (srcSender_ == address(0) || receiverAddressSP_ == address(0)) revert Error.ZERO_ADDRESS();

        (address superformAddress,,) = targetSuperformId_.getSuperform();
        IERC20 share = IERC20(IBaseForm(superformAddress).getVaultAddress());

        _transferERC20In(share, srcSender_, shares_);

        share.safeIncreaseAllowance(superformAddress, shares_);

        share.transferFrom(address(this), superformAddress, shares_);

        ISuperPositions(_getSuperRegistryAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
            receiverAddressSP_, targetSuperformId_, shares_
        );
    }

    /// @dev for this to work three requisites are necessary:
    /// @dev 1: at least one cross chain deposit must have gone through
    /// @dev 2: user must approve their respective vault share to this contract
    /// @dev 3: user must sign a message so that the returnPayloadId can be validated off chain to exist in
    /// targetChainId_
    function enterSuperformWithShares(
        uint256 targetSuperformId_,
        address receiverAddressSP_,
        uint256 amount_,
        address srcSender_,
        uint256 returnPayloadId_,
        uint64 targetChainId_,
        uint8[] memory ambIds_,
        uint256 deadline_,
        bytes32 nonce_,
        bytes memory signature_
    )
        external
        onlyRebalanceRegistryProcessor
    {
        if (targetSuperformId_ == 0) revert Error.SUPERFORM_ID_NONEXISTENT();

        if (amount_ == 0) revert Error.ZERO_AMOUNT();

        if (srcSender_ == address(0) || receiverAddressSP_ == address(0)) revert Error.ZERO_ADDRESS();

        if (targetChainId_ == 0) revert Error.INVALID_CHAIN_ID();

        if (returnPayloadId_ != 0 && targetChainId_ != CHAIN_ID) {
            _setAuthorizationNonce(deadline_, receiverAddressSP_, nonce_);

            _checkSignature(
                receiverAddressSP_,
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                ENTER_SUPERFORM_TYPEHASH,
                                targetSuperformId_,
                                receiverAddressSP_,
                                amount_,
                                returnPayloadId_,
                                targetChainId_,
                                ambIds_,
                                deadline_,
                                nonce_
                            )
                        )
                    )
                ),
                signature_
            );
        } else if (
            returnPayloadId_ != 0 && targetChainId_ == CHAIN_ID || returnPayloadId_ == 0 && targetChainId_ != CHAIN_ID
        ) {
            revert Error.INVALID_PAYLOAD_ID();
        }
        (address superformAddress,,) = targetSuperformId_.getSuperform();
        IERC20 share = IERC20(IBaseForm(superformAddress).getVaultAddress());

        _transferERC20In(share, srcSender_, amount_);

        share.safeIncreaseAllowance(superformAddress, amount_);

        share.transferFrom(address(this), superformAddress, amount_);

        _dispatchAcknowledgement(
            targetChainId_,
            ambIds_,
            abi.encode(
                AMBMessage(
                    DataLib.packTxInfo(
                        uint8(TransactionType.DEPOSIT),
                        uint8(CallbackType.RETURN),
                        0,
                        _getStateRegistryId(),
                        receiverAddressSP_,
                        CHAIN_ID
                    ),
                    abi.encode(ReturnSingleData(returnPayloadId_, targetSuperformId_, amount_))
                )
            )
        );
    }

    /// @inheritdoc BaseStateRegistry
    function processPayload(uint256 payloadId_)
        external
        payable
        virtual
        override
        onlyRebalanceRegistryProcessor
        isValidPayloadId(payloadId_)
    {
        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        /// @dev sets status as processed to prevent re-entrancy
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        uint256 _payloadHeader = payloadHeader[payloadId_];

        (, uint256 callbackType,,,, uint64 srcChainId) = _payloadHeader.decodeTxInfo();
        AMBMessage memory _message = AMBMessage(_payloadHeader, payloadBody[payloadId_]);

        /// @dev validates quorum
        if (messageQuorum[_message.computeProof()] < _getRequiredMessagingQuorum(srcChainId)) {
            revert Error.INSUFFICIENT_QUORUM();
        }

        if (callbackType == uint256(CallbackType.RETURN)) {
            ISuperPositions(_getSuperRegistryAddress(keccak256("SUPER_POSITIONS"))).stateSync(_message);
        }
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    function _setAuthorizationNonce(uint256 deadline_, address user_, bytes32 nonce_) internal {
        if (block.timestamp > deadline_) revert EXPIRED();
        if (authorizations[user_][nonce_]) revert AUTHORIZATION_USED();

        authorizations[user_][nonce_] = true;
    }

    function _checkSignature(address user_, bytes32 digest_, bytes memory signature_) internal {
        if (!SignatureChecker.isValidSignatureNow(user_, digest_, signature_)) revert INVALID_AUTHORIZATION();
    }

    function _rebalanceSuperPositionsTo(
        uint256 targetSuperformId_,
        address receiverAddressSP_,
        uint256 amount_,
        uint256 returnPayloadId_,
        uint64 targetChainId_,
        uint8[] memory ambIds_,
        uint256 deadline_,
        bytes32 nonce_,
        bytes memory signature_
    )
        internal
    {
        if (amount_ == 0) revert Error.ZERO_AMOUNT();

        if (targetSuperformId_ == 0) revert Error.SUPERFORM_ID_NONEXISTENT();

        if (targetChainId_ == 0) revert Error.INVALID_CHAIN_ID();

        if (receiverAddressSP_ == address(0)) revert Error.ZERO_ADDRESS();

        if (returnPayloadId_ != 0 && targetChainId_ != CHAIN_ID) {
            _setAuthorizationNonce(deadline_, receiverAddressSP_, nonce_);

            _checkSignature(
                receiverAddressSP_,
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                ENTER_SUPERFORM_TYPEHASH,
                                targetSuperformId_,
                                receiverAddressSP_,
                                amount_,
                                returnPayloadId_,
                                targetChainId_,
                                ambIds_,
                                deadline_,
                                nonce_
                            )
                        )
                    )
                ),
                signature_
            );
        } else if (
            returnPayloadId_ != 0 && targetChainId_ == CHAIN_ID || returnPayloadId_ == 0 && targetChainId_ != CHAIN_ID
        ) {
            revert Error.INVALID_PAYLOAD_ID();
        }

        (address superformAddress,,) = targetSuperformId_.getSuperform();
        IBaseForm form = IBaseForm(superformAddress);
        address vault = form.getVaultAddress();
        IERC4626 v = IERC4626(vault);

        IERC20(form.getVaultAsset()).safeIncreaseAllowance(vault, amount_);

        uint256 sharesBalanceBefore = v.balanceOf(superformAddress);
        uint256 shares = v.deposit(amount_, superformAddress);
        uint256 sharesBalanceAfter = v.balanceOf(superformAddress);

        if (sharesBalanceAfter - sharesBalanceBefore != shares) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }

        if (targetChainId_ == CHAIN_ID) {
            ISuperPositions(_getSuperRegistryAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
                receiverAddressSP_, targetSuperformId_, shares
            );
        } else {
            _dispatchAcknowledgement(
                targetChainId_,
                ambIds_,
                abi.encode(
                    AMBMessage(
                        DataLib.packTxInfo(
                            uint8(TransactionType.DEPOSIT),
                            uint8(CallbackType.RETURN),
                            0,
                            _getStateRegistryId(),
                            receiverAddressSP_,
                            CHAIN_ID
                        ),
                        abi.encode(ReturnSingleData(returnPayloadId_, targetSuperformId_, shares))
                    )
                )
            );
        }
    }

    /// @dev returns the required quorum for the src chain id from super registry
    /// @param chainId is the src chain id
    /// @return the quorum configured for the chain id
    function _getRequiredMessagingQuorum(uint64 chainId) internal view returns (uint256) {
        return IQuorumManager(address(superRegistry)).getRequiredMessagingQuorum(chainId);
    }

    /// @dev allows users to read the ids of ambs that delivered a payload
    function _getDeliveryAMB(uint256 payloadId_) internal view returns (uint8[] memory ambIds_) {
        IBaseStateRegistry coreStateRegistry =
            IBaseStateRegistry(_getSuperRegistryAddress(keccak256("CORE_STATE_REGISTRY")));

        ambIds_ = coreStateRegistry.getMessageAMB(payloadId_);
    }

    function _dispatchAcknowledgement(uint64 dstChainId_, uint8[] memory ambIds_, bytes memory message_) internal {
        (, bytes memory extraData) = IPaymentHelper(_getSuperRegistryAddress(keccak256("PAYMENT_HELPER")))
            .calculateAMBData(dstChainId_, ambIds_, message_);

        _dispatchPayload(msg.sender, ambIds_, dstChainId_, message_, extraData);
    }

    function _getStateRegistryId() internal view returns (uint8) {
        return superRegistry.getStateRegistryId(address(this));
    }

    function _getSuperRegistryAddress(bytes32 id) internal view returns (address) {
        return superRegistry.getAddress(id);
    }

    function _transferERC20In(IERC20 asset_, address user_, uint256 amount_) internal {
        asset_.transferFrom(user_, address(this), amount_);
    }
}
