// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.23;

import { SafeTransferLib } from "./7540MockUtils/SafeTransferLib.sol";
import { IERC7540Redeem, IERC7540Operator, IAuthorizeOperator } from "src/vendor/centrifuge/IERC7540.sol";
import { IERC7575, IERC165 } from "src/vendor/centrifuge/IERC7575.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { ERC7575Mock } from "./ERC7575Mock.sol";
import { BaseERC7540Mock } from "./BaseERC7540Mock.sol";

/// @title  ERC7540AsyncRedeemMock
/// @notice Asynchronous Tokenized Vault Mock
contract ERC7540AsyncRedeemMock is IERC7540Redeem, BaseERC7540Mock {
    using Math for uint256;

    constructor(address asset_, bool requestIdFungible) BaseERC7540Mock(asset_, requestIdFungible) { }

    /// @inheritdoc IERC7540Redeem
    function requestRedeem(uint256 shares, address controller, address owner) public returns (uint256) {
        require(IERC20(share).balanceOf(owner) >= shares, "ERC7540Vault/insufficient-balance");

        ERC7575Mock(share).burn(owner, shares);
        uint256 requestId = REQUEST_IDS;

        shareBalances[controller][requestId][0] = shares;

        if (REQUEST_ID_FUNGIBLE) ++REQUEST_IDS;

        return requestId;
    }

    /// @inheritdoc IERC7540Redeem
    function pendingRedeemRequest(uint256 requestId, address controller) public view returns (uint256 pendingShares) {
        return shareBalances[controller][requestId][0];
    }

    /// @inheritdoc IERC7540Redeem
    function claimableRedeemRequest(
        uint256 requestId,
        address controller
    )
        external
        view
        returns (uint256 claimableShares)
    {
        return shareBalances[controller][requestId][1];
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC7540Redeem).interfaceId || interfaceId == type(IERC7575).interfaceId
            || interfaceId == type(IERC7540Operator).interfaceId || interfaceId == type(IAuthorizeOperator).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    function deposit(uint256 assets, address receiver) external override returns (uint256 shares) {
        require(IERC20(asset).balanceOf(msg.sender) >= assets, "ERC7540Vault/insufficient-balance");
        shares = convertToShares(assets);

        SafeTransferLib.safeTransferFrom(asset, msg.sender, address(this), assets);

        ERC7575Mock(share).mint(receiver, shares);

        return shares;
    }

    /// @inheritdoc IERC7575
    function redeem(uint256 shares, address receiver, address controller) external override returns (uint256 assets) {
        if (REQUEST_ID_FUNGIBLE) revert("ERC7540Vault/invalid-deposit-rid-fungible");

        validateController(controller);
        require(shares == shareBalances[controller][0][1], "ERC7540Vault/invalid-redeem-claim");

        shareBalances[controller][0][1] = 0;

        assets = convertToAssets(shares);

        SafeTransferLib.safeTransfer(asset, receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address controller,
        uint256 requestId
    )
        external
        returns (uint256 assets)
    {
        if (!REQUEST_ID_FUNGIBLE) revert("ERC7540Vault/invalid-deposit-rid-non-fungible");

        validateController(controller);
        require(shares == shareBalances[controller][requestId][1], "ERC7540Vault/invalid-redeem-claim");

        shareBalances[controller][requestId][1] = 0;

        assets = convertToAssets(shares);

        SafeTransferLib.safeTransfer(asset, receiver, assets);
    }
}
