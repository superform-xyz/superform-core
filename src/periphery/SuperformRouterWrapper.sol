// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { SignatureChecker } from "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
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
import { EIP712Lib } from "src/libraries/EIP712Lib.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { Error } from "src/libraries/Error.sol";

contract SuperformRouterWrapper is IERC1155Receiver {
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

    event RebalanceCompleted(uint256 indexed id, uint256 amount, address indexed receiver);

    event RebalanceMultiCompleted(uint256[] indexed ids, uint256[] amounts, address indexed receiver);

    event Deposit4626Completed(address indexed receiver);

    event DepositUsingSmartWalletCompleted(address indexed receiver);

    //////////////////////////////////////////////////////////////
    //                       CONSTANTS                          //
    //////////////////////////////////////////////////////////////
    ISuperRegistry public immutable superRegistry;

    IBaseStateRegistry public immutable CORE_STATE_REGISTRY;
    address public immutable SUPERFORM_ROUTER;
    address public immutable SUPER_POSITIONS;
    bytes32 public constant REBALANCE_SUPERPOSITIONS_TYPEHASH = keccak256(
        "MetaRebalancePositions(uint256 id_,uint256 amount_,address receiver_,bytes calldata callData_,uint256 deadline_,bytes32 nonce_,bytes memory signature_,uint256 deadline_,bytes32 nonce_)"
    );
    bytes32 public constant REBALANCE_MULTI_SUPERPOSITIONS_TYPEHASH = keccak256(
        "MetaRebalancePositions(uint256[] id_,uint256[] amount_,address receiver_,bytes calldata callData_,uint256 deadline_,bytes32 nonce_,bytes memory signature_,uint256 deadline_,bytes32 nonce_)"
    );
    bytes32 public constant DEPOSIT_4626_TYPEHASH = keccak256(
        "MetaDeposit4626(address vault_,uint256 amount_,address receiver_,bytes calldata callData_,uint256 deadline_,bytes32 nonce_,bytes memory signature_,uint256 deadline_,bytes32 nonce_)"
    );
    bytes32 public constant DEPOSIT_SMARTWALLET_TYPEHASH = keccak256(
        "MetaDepositUsingSmartWallet(address asset_,uint256 amount_,address receiver_,bytes calldata callData_,uint256 deadline_,bytes32 nonce_,bytes memory signature_,uint256 deadline_,bytes32 nonce_)"
    );

    bytes32 private immutable nameHash;
    bytes32 private immutable versionHash;
    uint256 public immutable CHAIN_ID;
    bytes32 private immutable _DOMAIN_SEPARATOR;
    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    mapping(uint256 payloadId => address user) public msgSenderMap;
    mapping(uint256 payloadId => bool processed) public statusMap;
    mapping(address => mapping(bytes32 => bool)) public authorizations;

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
        nameHash = keccak256(bytes("Superform"));
        versionHash = keccak256(bytes("1"));
        CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = EIP712Lib.calculateDomainSeparator(nameHash, versionHash);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == CHAIN_ID ? _DOMAIN_SEPARATOR : EIP712Lib.calculateDomainSeparator(nameHash, versionHash);
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @dev helps user rebalance a Single SuperPosition
    /// @dev this covers the goal "1 Exiting a vault and entering another in one step for same chain operations and
    /// cross chain operations where the source vault’s chain is the same as the users’ SuperPositions chain"
    function rebalancePositions(
        uint256 id_,
        uint256 amount_,
        address receiver_,
        bytes calldata callData_
    )
        external
        payable
    {
        _transferSuperPositions(receiver_, id_, amount_);

        _callSuperformRouter(callData_);

        emit RebalanceCompleted(id_, amount_, receiver_);
    }

    /// @dev batch version of rebalancePositions
    function rebalanceMultiPositions(
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        address receiver_,
        bytes calldata callData_
    )
        external
        payable
    {
        _transferBatchSuperPositions(receiver_, ids_, amounts_);

        _callSuperformRouter(callData_);

        emit RebalanceMultiCompleted(ids_, amounts_, receiver_);
    }

    /// @dev allows gasless transactions for the function 'rebalancePositions'
    /// @notice misses logic to covert a portion of SPs to native tokens for the keeper
    /// @dev this helps with goal "4 Allow for gasless transactions where tx costs are deducted from funding tokens (or
    /// from SuperPositions) OR subsidized by Superform team."
    /// @dev user could set infinite allowance to move SuperPositions to this contract to help with UX
    function metaRebalancePositions(
        uint256 id_,
        uint256 amount_,
        address receiver_,
        bytes calldata callData_,
        uint256 deadline_,
        bytes32 nonce_,
        bytes memory signature_
    )
        external
        onlyRouterWrapperProcessor
    {
        _setAuthorizationNonce(deadline_, receiver_, nonce_);

        _checkSignature(
            receiver_,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            REBALANCE_SUPERPOSITIONS_TYPEHASH, id_, amount_, receiver_, callData_, deadline_, nonce_
                        )
                    )
                )
            ),
            signature_
        );

        _transferSuperPositions(receiver_, id_, amount_);

        /// @dev logic to convert a portion SuperPositions sent here to native tokens (can we use superPools for this?)

        _callSuperformRouter(callData_);

        emit RebalanceCompleted(id_, amount_, receiver_);
    }

    /// @dev batch version of the function above
    function metaRebalanceMultiPositions(
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        address receiver_,
        bytes calldata callData_,
        uint256 deadline_,
        bytes32 nonce_,
        bytes memory signature_
    )
        external
        onlyRouterWrapperProcessor
    {
        _setAuthorizationNonce(deadline_, receiver_, nonce_);

        _checkSignature(
            receiver_,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            REBALANCE_MULTI_SUPERPOSITIONS_TYPEHASH,
                            ids_,
                            amounts_,
                            receiver_,
                            callData_,
                            deadline_,
                            nonce_
                        )
                    )
                )
            ),
            signature_
        );

        _transferBatchSuperPositions(receiver_, ids_, amounts_);

        /// @dev logic to convert a portion SuperPositions sent here to native tokens (can we use superPools for this?)

        _callSuperformRouter(callData_);

        emit RebalanceMultiCompleted(ids_, amounts_, receiver_);
    }

    /// NOTE: add function for same chain action
    /// NOTE: just 4626 shares
    /// NOTE: currently hard to handle entering with multiple 4626 shares due to having to redeem. if we avoid redeem it
    /// is possible (requires MetaStateRegistry)
    /// @dev helps user deposit 4626 vault shares into superform
    /// @dev this helps with goal "2 Entering Superform via any 4626 share in one step by transfering the share to the
    /// specific superform"
    /// @dev however does not conform exactly to the intended because the share is redeemed first
    /// @param vault_ the 4626 vault to redeem from
    /// @param amount_ the 4626 vault share amount to redeem
    /// @param callData_ the encoded superform router request
    function deposit4626(
        address vault_,
        uint256 amount_,
        address receiver_,
        bytes calldata callData_
    )
        external
        payable
    {
        IERC4626 vault = IERC4626(vault_);

        IERC20 asset = IERC20(vault.asset());
        _transferERC20In(asset, receiver_, amount_);

        _deposit4626(asset, vault, amount_, asset.balanceOf(address(this)), receiver_, callData_);

        emit Deposit4626Completed(receiver_);
    }

    /// @dev allows gasless transactions for the function above
    /// @notice misses logic to covert a portion of amount to native tokens for the keeper
    /// @dev this helps with goal "4 Allow for gasless transactions where tx costs are deducted from funding tokens (or
    /// from SuperPositions) OR subsidized by Superform team."
    /// @dev user needs to set infinite allowance of vault shares to wrapper to allow this in smooth ux
    function metaDeposit4626(
        address vault_,
        uint256 amount_,
        address receiver_,
        bytes calldata callData_,
        uint256 deadline_,
        bytes32 nonce_,
        bytes memory signature_
    )
        external
        onlyRouterWrapperProcessor
    {
        _setAuthorizationNonce(deadline_, receiver_, nonce_);

        _checkSignature(
            receiver_,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(DEPOSIT_4626_TYPEHASH, vault_, amount_, receiver_, callData_, deadline_, nonce_)
                    )
                )
            ),
            signature_
        );
        IERC4626 vault = IERC4626(vault_);
        IERC20 asset = IERC20(vault.asset());
        _transferERC20In(asset, receiver_, amount_);

        /// add logic to take a portion of shares as native for keeper
        /// @dev e.g
        uint256 amountToRedeem = amount_ - (amount_ / 10);

        _deposit4626(asset, vault, amountToRedeem, asset.balanceOf(address(this)), receiver_, callData_);

        emit Deposit4626Completed(receiver_);
    }

    /// @dev helps user deposit into superform using smart contract wallets
    /// @dev should only allow a single asset to be deposited (because this is similar to a normal deposit)
    /// @dev this covers the goal "3 Providing better compatibility with smart contract wallets such as coinbase smart
    /// wallet"
    /// @param asset_ the ERC20 asset to deposit
    /// @param amount_ the ERC20 amount to deposit
    /// @param callData_ the encoded superform router deposit request
    function depositUsingSmartWallet(
        IERC20 asset_,
        uint256 amount_,
        address receiver_,
        bytes calldata callData_
    )
        external
        payable
    {
        _transferERC20In(asset_, receiver_, amount_);

        _depositUsingSmartWallet(asset_, amount_, asset_.balanceOf(address(this)), receiver_, callData_);

        emit DepositUsingSmartWalletCompleted(receiver_);
    }

    /// @dev allows gasless transactions for the function above
    /// @notice misses logic to covert a portion of amount to native tokens for the keeper
    /// @dev this helps with goal "4 Allow for gasless transactions where tx costs are deducted from funding tokens (or
    /// from SuperPositions) OR subsidized by Superform team."
    /// @dev user needs to set infinite allowance of assets to wrapper to allow this in smooth ux
    function metaDepositUsingSmartWallet(
        address asset_,
        uint256 amount_,
        address receiver_,
        bytes calldata callData_,
        uint256 deadline_,
        bytes32 nonce_,
        bytes memory signature_
    )
        external
        onlyRouterWrapperProcessor
    {
        _setAuthorizationNonce(deadline_, receiver_, nonce_);

        _checkSignature(
            receiver_,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            DEPOSIT_SMARTWALLET_TYPEHASH, asset_, amount_, receiver_, callData_, deadline_, nonce_
                        )
                    )
                )
            ),
            signature_
        );

        IERC20 asset = IERC20(asset_);

        _transferERC20In(asset, receiver_, amount_);

        /// add logic to take a portion of shares as native for keeper
        /// @dev e.g
        uint256 amountToDeposit = amount_ - (amount_ / 10);

        _depositUsingSmartWallet(asset, amountToDeposit, asset.balanceOf(address(this)), receiver_, callData_);

        emit DepositUsingSmartWalletCompleted(receiver_);
    }

    /// @dev this is callback payload id
    /// @dev this covers the goal "3 Providing better compatibility with smart contract wallets such as coinbase smart
    /// wallet"
    function completeDisbursement(uint256 returnPayloadId) external {
        _completeDisbursement(returnPayloadId);
    }

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

    function _transferERC20In(IERC20 asset_, address user_, uint256 amount_) internal {
        asset_.transferFrom(user_, address(this), amount_);
    }

    function _deposit4626(
        IERC20 asset_,
        IERC4626 vault_,
        uint256 amountToRedeem_,
        uint256 collateralBalanceBefore_,
        address receiver_,
        bytes calldata callData_
    )
        internal
    {
        /// @dev redeem the vault shares and receive collateral
        vault_.redeem(amountToRedeem_, address(this), address(this));

        /// @dev collateral balance after
        uint256 collateralBalanceAfter = asset_.balanceOf(address(this));
        uint256 collateralAdjusted = collateralBalanceAfter - collateralBalanceBefore_;

        /// @dev approves superform router on demand
        asset_.approve(SUPERFORM_ROUTER, collateralAdjusted);

        uint256 payloadStartCount = CORE_STATE_REGISTRY.payloadsCount();

        _callSuperformRouter(callData_);

        uint256 payloadEndCount = CORE_STATE_REGISTRY.payloadsCount();

        if (payloadEndCount - payloadStartCount > 0) {
            for (uint256 i = payloadStartCount; i < payloadEndCount; i++) {
                msgSenderMap[i] = receiver_;
            }
        }

        /// @dev refund any unused funds
        _processRefunds(asset_, receiver_);
    }

    function _depositUsingSmartWallet(
        IERC20 asset_,
        uint256 amountToDeposit_,
        uint256 collateralBalanceBefore_,
        address receiver_,
        bytes calldata callData_
    )
        internal
    {
        /// @dev collateral balance after
        uint256 collateralBalanceAfter = asset_.balanceOf(address(this));
        uint256 collateralAdjusted = collateralBalanceAfter - collateralBalanceBefore_;

        /// @dev approves superform router on demand
        asset_.approve(SUPERFORM_ROUTER, collateralAdjusted);
        uint256 payloadStartCount = CORE_STATE_REGISTRY.payloadsCount();

        _callSuperformRouter(callData_);

        uint256 payloadEndCount = CORE_STATE_REGISTRY.payloadsCount();

        if (payloadEndCount - payloadStartCount > 0) {
            for (uint256 i = payloadStartCount; i < payloadEndCount; i++) {
                msgSenderMap[i] = receiver_;
            }
        }

        /// @dev refund any unused funds
        _processRefunds(asset_, receiver_);
    }

    function _completeDisbursement(uint256 returnPayloadId) internal {
        uint256 txInfo = CORE_STATE_REGISTRY.payloadHeader(returnPayloadId);

        (uint256 returnTxType, uint256 callbackType, uint8 multi,,,) = txInfo.decodeTxInfo();

        if (returnTxType != uint256(TransactionType.DEPOSIT) || callbackType != uint256(CallbackType.RETURN)) {
            revert();
        }

        uint256 payloadId;
        if (multi != 0) {
            ReturnMultiData memory returnData =
                abi.decode(CORE_STATE_REGISTRY.payloadBody(returnPayloadId), (ReturnMultiData));

            payloadId = returnData.payloadId;
            IERC1155(SUPER_POSITIONS).safeBatchTransferFrom(
                address(this), msgSenderMap[payloadId], returnData.superformIds, returnData.amounts, ""
            );
        } else {
            ReturnSingleData memory returnData =
                abi.decode(CORE_STATE_REGISTRY.payloadBody(returnPayloadId), (ReturnSingleData));

            payloadId = returnData.payloadId;
            IERC1155(SUPER_POSITIONS).safeTransferFrom(
                address(this), msgSenderMap[payloadId], returnData.superformId, returnData.amount, ""
            );
        }

        if (statusMap[payloadId]) {
            revert();
        }

        statusMap[payloadId] = true;
    }
}
