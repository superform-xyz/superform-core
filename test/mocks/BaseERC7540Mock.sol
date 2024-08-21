// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

import { EIP712Lib } from "./7540MockUtils/EIP712Lib.sol";
import { SignatureLib } from "./7540MockUtils/SignatureLib.sol";
import { SafeTransferLib } from "./7540MockUtils/SafeTransferLib.sol";
import { IERC20Metadata } from "./7540MockUtils/IERC20.sol";
import { IERC7540Operator, IAuthorizeOperator } from "src/vendor/centrifuge/IERC7540.sol";
import { IERC7575, IERC165 } from "src/vendor/centrifuge/IERC7575.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { ERC7575Mock } from "./ERC7575Mock.sol";

/// @title  ERC7540FullyAsyncMock
/// @notice Asynchronous Tokenized Vault Mock
abstract contract BaseERC7540Mock is IAuthorizeOperator, IERC7540Operator, IERC7575 {
    using Math for uint256;

    uint128 public constant defaultPrice = 1_014_955_188_668_023_222;

    address public immutable asset;
    address public immutable share;
    uint8 public immutable shareDecimals;

    uint256 public REQUEST_IDS;
    bool immutable REQUEST_ID_FUNGIBLE;

    bytes32 private immutable nameHash;
    bytes32 private immutable versionHash;
    uint256 public immutable deploymentChainId;
    bytes32 private immutable _DOMAIN_SEPARATOR;
    bytes32 public constant AUTHORIZE_OPERATOR_TYPEHASH =
        keccak256("AuthorizeOperator(address controller,address operator,bool approved,bytes32 nonce,uint256 deadline)");

    mapping(address controller => mapping(bytes32 nonce => bool used)) authorizations;

    /// @dev state 0 is for pending, state 1 is claimable, state 2 is claimed
    mapping(address controller => mapping(uint256 requestId => mapping(uint8 state => uint256 assetBalance)))
        assetBalances;

    /// @dev state 0 is for pending, state 1 is claimable, state 2 is claimed
    mapping(address controller => mapping(uint256 requestId => mapping(uint8 state => uint256 shareBalance)))
        shareBalances;

    /// @inheritdoc IERC7540Operator
    mapping(address => mapping(address => bool)) public isOperator;

    constructor(address asset_, bool requestIdFungible) {
        asset = asset_;
        REQUEST_ID_FUNGIBLE = requestIdFungible;
        share = address(new ERC7575Mock(18));
        shareDecimals = IERC20Metadata(share).decimals();

        nameHash = keccak256(bytes("Centrifuge"));
        versionHash = keccak256(bytes("1"));
        deploymentChainId = block.chainid;
        _DOMAIN_SEPARATOR = EIP712Lib.calculateDomainSeparator(nameHash, versionHash);
    }

    function moveAssetsToClaimable(uint256 requestId, address controller) public {
        assetBalances[controller][requestId][1] = assetBalances[controller][requestId][0];
        assetBalances[controller][requestId][0] = 0;
    }

    function moveSharesToClaimable(uint256 requestId, address controller) public {
        shareBalances[controller][requestId][1] = shareBalances[controller][requestId][0];
        shareBalances[controller][requestId][0] = 0;
    }

    /// @inheritdoc IERC7540Operator
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
        bytes32 nonce,
        uint256 deadline,
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
                keccak256(abi.encode(AUTHORIZE_OPERATOR_TYPEHASH, controller, operator, approved, nonce, deadline))
            )
        );

        require(SignatureLib.isValidSignature(controller, digest, signature), "ERC7540Vault/invalid-authorization");

        isOperator[controller][operator] = approved;
        emit OperatorSet(controller, operator, approved);

        return true;
    }

    /// @inheritdoc IERC7575
    function totalAssets() public view returns (uint256) {
        return IERC20Metadata(asset).balanceOf(address(this));
    }

    /// @inheritdoc IERC7575
    function convertToShares(uint256 assets) public pure returns (uint256 shares) {
        return assets.mulDiv(10 ** 18, defaultPrice, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC7575
    function convertToAssets(uint256 shares) public pure returns (uint256 assets) {
        return shares.mulDiv(defaultPrice, 10 ** 18, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC7575
    function maxDeposit(address) public pure returns (uint256 maxAssets) {
        return type(uint256).max;
    }

    /// @inheritdoc IERC7575
    function maxMint(address) public pure returns (uint256) {
        revert();
    }

    /// @inheritdoc IERC7575
    function mint(uint256, address) public pure returns (uint256) {
        revert();
    }

    /// @inheritdoc IERC7575
    function maxWithdraw(address) public pure returns (uint256) {
        revert();
    }

    /// @inheritdoc IERC7575
    function withdraw(uint256, address, address) public pure returns (uint256) {
        revert();
    }

    /// @inheritdoc IERC7575
    function maxRedeem(address controller) public view returns (uint256 maxShares) {
        return IERC20Metadata(share).balanceOf(controller);
    }

    /// @inheritdoc IERC7575
    function deposit(uint256 assets, address receiver) external virtual returns (uint256 shares) { }

    /// @inheritdoc IERC7575
    function redeem(uint256 shares, address receiver, address controller) external virtual returns (uint256 assets) { }

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
    function previewRedeem(uint256) external pure virtual returns (uint256) {
        revert();
    }

    function validateController(address controller) internal view {
        require(controller == msg.sender || isOperator[controller][msg.sender], "ERC7540Vault/invalid-controller");
    }
}
