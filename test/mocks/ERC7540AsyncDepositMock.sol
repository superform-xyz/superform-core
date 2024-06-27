// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

import { SafeTransferLib } from "./7540MockUtils/SafeTransferLib.sol";
import { IERC7540Deposit, IERC7540Operator, IAuthorizeOperator } from "src/vendor/centrifuge/IERC7540.sol";
import { IERC7575, IERC165 } from "src/vendor/centrifuge/IERC7575.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { ERC7575Mock } from "./ERC7575Mock.sol";
import { BaseERC7540Mock } from "./BaseERC7540Mock.sol";

/// @title  ERC7540AsyncDepositMock
/// @notice Asynchronous Tokenized Vault Mock
contract ERC7540AsyncDepositMock is IERC7540Deposit, BaseERC7540Mock {
    using Math for uint256;

    constructor(address asset_, bool requestIdFungible) BaseERC7540Mock(asset_, requestIdFungible) { }

    /// @inheritdoc IERC7540Deposit
    function requestDeposit(uint256 assets, address controller, address owner) public returns (uint256) {
        require(owner == msg.sender || isOperator[owner][msg.sender], "ERC7540Vault/invalid-owner");
        require(IERC20(asset).balanceOf(owner) >= assets, "ERC7540Vault/insufficient-balance");
        SafeTransferLib.safeTransferFrom(asset, owner, address(this), assets);
        uint256 requestId = REQUEST_IDS;

        assetBalances[controller][requestId][0] = assets;

        if (REQUEST_ID_FUNGIBLE) ++REQUEST_IDS;

        return requestId;
    }

    /// @inheritdoc IERC7540Deposit
    function pendingDepositRequest(uint256 requestId, address controller) public view returns (uint256 pendingAssets) {
        return assetBalances[controller][requestId][0];
    }

    /// @inheritdoc IERC7540Deposit
    function claimableDepositRequest(
        uint256 requestId,
        address controller
    )
        external
        view
        returns (uint256 claimableAssets)
    {
        return assetBalances[controller][requestId][1];
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC7540Deposit).interfaceId || interfaceId == type(IERC7575).interfaceId
            || interfaceId == type(IERC7540Operator).interfaceId || interfaceId == type(IAuthorizeOperator).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    /// @inheritdoc IERC7540Deposit
    function deposit(uint256 assets, address receiver, address controller) public returns (uint256 shares) {
        if (REQUEST_ID_FUNGIBLE) revert("ERC7540Vault/invalid-deposit-rid-fungible");
        validateController(controller);
        require(assets == assetBalances[controller][0][1], "ERC7540Vault/invalid-deposit-claim");

        assetBalances[controller][0][1] = 0;

        shares = convertToShares(assets);
        ERC7575Mock(share).mint(receiver, shares);
    }

    function deposit(
        uint256 assets,
        address receiver,
        address controller,
        uint256 requestId
    )
        public
        returns (uint256 shares)
    {
        if (!REQUEST_ID_FUNGIBLE) revert("ERC7540Vault/invalid-deposit-rid-non-fungible");

        validateController(controller);
        require(assets == assetBalances[controller][requestId][1], "ERC7540Vault/invalid-deposit-claim");

        assetBalances[controller][requestId][1] = 0;

        shares = convertToShares(assets);
        ERC7575Mock(share).mint(receiver, shares);
    }

    /// @inheritdoc IERC7575
    function deposit(uint256 assets, address receiver) external override returns (uint256 shares) {
        shares = deposit(assets, receiver, msg.sender);
    }

    /// @inheritdoc IERC7575
    function redeem(uint256 shares, address receiver, address controller) external override returns (uint256 assets) {
        require(IERC20(share).balanceOf(controller) >= shares, "ERC7540Vault/insufficient-balance");

        assets = convertToAssets(shares);

        ERC7575Mock(share).burn(controller, shares);

        SafeTransferLib.safeTransfer(asset, receiver, assets);

        return assets;
    }

    /// @inheritdoc IERC7540Deposit
    function mint(uint256, address, address) public pure returns (uint256) {
        revert();
    }

    function previewRedeem(uint256 shares) external pure override returns (uint256) {
        return shares.mulDiv(defaultPrice, 10 ** 18, Math.Rounding.Floor);
    }
}
