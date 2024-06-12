// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

import { EIP712Lib } from "./7540MockUtils/EIP712Lib.sol";
import { SignatureLib } from "./7540MockUtils/SignatureLib.sol";
import { SafeTransferLib } from "./7540MockUtils/SafeTransferLib.sol";
import { IERC20Metadata } from "./7540MockUtils/IERC20.sol";
import {
    IERC7540,
    IERC7540Deposit,
    IERC7540Redeem,
    IAuthorizeOperator,
    IERC7540CancelDeposit,
    IERC7540CancelRedeem
} from "src/vendor/centrifuge/IERC7540.sol";
import { IERC7575, IERC165 } from "src/vendor/centrifuge/IERC7575.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { ERC7575Mock } from "./ERC7575Mock.sol";

/// @title  ERC7540Mock
/// @notice Asynchronous Tokenized Vault Mock
contract ERC7540Mock is IERC7540, IAuthorizeOperator {
    using Math for uint256;

    /// @notice The investment asset for this vault.
    address public immutable asset;

    /// @notice The restricted ERC-20 vault share
    address public immutable share;
    uint8 public immutable shareDecimals;

    /// @dev    Requests for Centrifuge pool are non-transferable and all have ID = 0
    uint256 constant REQUEST_ID = 0;

    bytes32 private immutable nameHash;
    bytes32 private immutable versionHash;
    uint256 public immutable deploymentChainId;
    bytes32 private immutable _DOMAIN_SEPARATOR;
    bytes32 public constant AUTHORIZE_OPERATOR_TYPEHASH = keccak256(
        "AuthorizeOperator(address controller,address operator,bool approved,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
    );

    mapping(address controller => mapping(bytes32 nonce => bool used)) authorizations;

    /// @dev state 0 is for pending, state 1 is claimable, state 2 is claimed
    mapping(address controller => mapping(uint8 state => uint256 assetBalance)) assetBalances;

    /// @dev state 0 is for pending, state 1 is claimable, state 2 is claimed
    mapping(address controller => mapping(uint8 state => uint256 shareBalance)) shareBalances;

    /// @inheritdoc IERC7540
    mapping(address => mapping(address => bool)) public isOperator;

    constructor(address asset_) {
        asset = asset_;
        share = address(new ERC7575Mock(18));
        shareDecimals = IERC20Metadata(share).decimals();

        nameHash = keccak256(bytes("7540VaultMock"));
        versionHash = keccak256(bytes("1"));
        deploymentChainId = block.chainid;
        _DOMAIN_SEPARATOR = EIP712Lib.calculateDomainSeparator(nameHash, versionHash);
    }

    // --- ERC-7540 methods ---
    /// @inheritdoc IERC7540Deposit
    function requestDeposit(uint256 assets, address controller, address owner) public returns (uint256) {
        require(owner == msg.sender || isOperator[owner][msg.sender], "ERC7540Vault/invalid-owner");
        require(IERC20(asset).balanceOf(owner) >= assets, "ERC7540Vault/insufficient-balance");
        SafeTransferLib.safeTransferFrom(asset, owner, address(this), assets);

        assetBalances[controller][0] = assets;

        return REQUEST_ID;
    }

    /// @inheritdoc IERC7540Deposit
    function pendingDepositRequest(uint256, address controller) public view returns (uint256 pendingAssets) {
        return assetBalances[controller][0];
    }

    /// @inheritdoc IERC7540Deposit
    function claimableDepositRequest(uint256, address controller) external view returns (uint256 claimableAssets) {
        return assetBalances[controller][1];
    }

    function moveAssetsToClaimable(address controller) public {
        assetBalances[controller][1] = assetBalances[controller][0];
        assetBalances[controller][0] = 0;
    }

    /// @inheritdoc IERC7540Redeem
    function requestRedeem(uint256 shares, address controller, address owner) public returns (uint256) {
        require(IERC20(share).balanceOf(owner) >= shares, "ERC7540Vault/insufficient-balance");

        ERC7575Mock(share).burn(owner, shares);

        shareBalances[controller][0] = shares;

        return REQUEST_ID;
    }

    /// @inheritdoc IERC7540Redeem
    function pendingRedeemRequest(uint256, address controller) public view returns (uint256 pendingShares) {
        return shareBalances[controller][0];
    }

    /// @inheritdoc IERC7540Redeem
    function claimableRedeemRequest(uint256, address controller) external view returns (uint256 claimableShares) {
        return shareBalances[controller][1];
    }

    function moveSharesToClaimable(address controller) public {
        shareBalances[controller][1] = shareBalances[controller][0];
        shareBalances[controller][0] = 0;
    }

    // --- Asynchronous cancellation methods ---
    /// @inheritdoc IERC7540CancelDeposit
    function cancelDepositRequest(uint256, address controller) external {
        revert();
    }

    /// @inheritdoc IERC7540CancelDeposit
    function pendingCancelDepositRequest(uint256, address controller) public view returns (bool isPending) {
        revert();
    }

    /// @inheritdoc IERC7540CancelDeposit
    function claimableCancelDepositRequest(uint256, address controller) public view returns (uint256 claimableAssets) {
        revert();
    }

    /// @inheritdoc IERC7540CancelDeposit
    function claimCancelDepositRequest(
        uint256,
        address receiver,
        address controller
    )
        external
        returns (uint256 assets)
    {
        revert();
    }

    /// @inheritdoc IERC7540CancelRedeem
    function cancelRedeemRequest(uint256, address controller) external {
        revert();
    }

    /// @inheritdoc IERC7540CancelRedeem
    function pendingCancelRedeemRequest(uint256, address controller) public view returns (bool isPending) {
        revert();
    }

    /// @inheritdoc IERC7540CancelRedeem
    function claimableCancelRedeemRequest(uint256, address controller) public view returns (uint256 claimableShares) {
        revert();
    }

    /// @inheritdoc IERC7540CancelRedeem
    function claimCancelRedeemRequest(
        uint256,
        address receiver,
        address controller
    )
        external
        returns (uint256 shares)
    {
        revert();
    }

    /// @inheritdoc IERC7540
    function setOperator(address operator, bool approved) public virtual returns (bool) {
        isOperator[msg.sender][operator] = approved;
        return true;
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == deploymentChainId
            ? _DOMAIN_SEPARATOR
            : EIP712Lib.calculateDomainSeparator(nameHash, versionHash);
    }

    /// @inheritdoc IAuthorizeOperator
    function authorizeOperator(
        address controller,
        address operator,
        bool approved,
        uint256 deadline,
        bytes32 nonce,
        bytes memory signature
    )
        external
        returns (bool)
    {
        require(block.timestamp <= deadline, "ERC7540Vault/authorization-expired");
        require(controller != address(0), "ERC7540Vault/invalid-controller");
        require(!authorizations[controller][nonce], "ERC7540Vault/authorization-used");

        authorizations[controller][nonce] = true;

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(AUTHORIZE_OPERATOR_TYPEHASH, controller, operator, approved, deadline, nonce))
            )
        );

        require(SignatureLib.isValidSignature(controller, digest, signature), "ERC7540Vault/invalid-authorization");

        isOperator[controller][operator] = approved;
        emit OperatorSet(controller, operator, approved);

        return true;
    }

    // --- ERC165 support ---
    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC7540Deposit).interfaceId || interfaceId == type(IERC7540Redeem).interfaceId
            || interfaceId == type(IERC7575).interfaceId || interfaceId == type(IAuthorizeOperator).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    // --- ERC-4626 methods ---
    /// @inheritdoc IERC7575
    function totalAssets() public view returns (uint256) {
        return IERC20Metadata(asset).balanceOf(address(this));
    }

    /// @inheritdoc IERC7575
    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        return assets.mulDiv(IERC20Metadata(share).totalSupply(), totalAssets() + 1, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC7575
    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        return shares.mulDiv(totalAssets() + 1, IERC20Metadata(share).totalSupply(), Math.Rounding.Floor);
    }

    /// @inheritdoc IERC7575
    function maxDeposit(address controller) public view returns (uint256 maxAssets) {
        return type(uint256).max;
    }

    /// @inheritdoc IERC7540
    function deposit(uint256 assets, address receiver, address controller) public returns (uint256 shares) {
        validateController(controller);
        require(assets == assetBalances[controller][1], "ERC7540Vault/invalid-deposit-claim");

        assetBalances[controller][1] = 0;

        shares = convertToShares(assets);
        ERC7575Mock(share).mint(receiver, shares);
    }

    /// @inheritdoc IERC7575
    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        shares = deposit(assets, receiver, msg.sender);
    }

    /// @inheritdoc IERC7575
    function maxMint(address controller) public view returns (uint256 maxShares) {
        return type(uint256).max;
    }

    /// @inheritdoc IERC7540
    function mint(uint256 shares, address receiver, address controller) public returns (uint256 assets) {
        revert();
    }

    /// @inheritdoc IERC7575
    function mint(uint256 shares, address receiver) public returns (uint256 assets) {
        revert();
    }

    /// @inheritdoc IERC7575
    function maxWithdraw(address controller) public view returns (uint256 maxAssets) {
        revert();
    }

    /// @inheritdoc IERC7575
    function withdraw(uint256 assets, address receiver, address controller) public returns (uint256 shares) {
        revert();
    }

    /// @inheritdoc IERC7575
    function maxRedeem(address controller) public view returns (uint256 maxShares) {
        return IERC20Metadata(share).balanceOf(controller);
    }

    /// @inheritdoc IERC7575
    function redeem(uint256 shares, address receiver, address controller) external returns (uint256 assets) {
        validateController(controller);
        require(shares == shareBalances[controller][1], "ERC7540Vault/invalid-redeem-claim");

        shareBalances[controller][1] = 0;

        assets = convertToAssets(shares);

        SafeTransferLib.safeTransfer(asset, receiver, assets);
    }

    /// @dev Preview functions for ERC-7540 vaults revert
    function previewDeposit(uint256) external pure returns (uint256) {
        revert();
    }

    /// @dev Preview functions for ERC-7540 vaults revert
    function previewMint(uint256) external pure returns (uint256) {
        revert();
    }

    /// @dev Preview functions for ERC-7540 vaults revert
    function previewWithdraw(uint256) external pure returns (uint256) {
        revert();
    }

    /// @dev Preview functions for ERC-7540 vaults revert
    function previewRedeem(uint256) external pure returns (uint256) {
        revert();
    }

    // --- Helpers ---

    function validateController(address controller) internal view {
        require(controller == msg.sender || isOperator[controller][msg.sender], "ERC7540Vault/invalid-controller");
    }
}
