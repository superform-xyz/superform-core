// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ICoreStateRegistry } from "src/interfaces/ICoreStateRegistry.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { IERC1155Receiver } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import { PayloadState, AMBMessage } from "src/types/DataTypes.sol";

interface ICoreStateRegistryExtended is ICoreStateRegistry {
    function payloadsCount() external view returns (uint256);
    function payloadTracking(uint256) external view returns (PayloadState);
    function payloadBody(uint256) external view returns (bytes memory);
    function payloadHeader(uint256) external view returns (uint256);
}

contract SuperformRouterWrapper is IERC1155Receiver {
    //////////////////////////////////////////////////////////////
    //                       CONSTANTS                          //
    //////////////////////////////////////////////////////////////

    ICoreStateRegistryExtended public immutable CORE_STATE_REGISTRY;
    address public immutable SUPERFORM_ROUTER;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    mapping(uint256 payloadId => address user) public msgSenderMap;
    mapping(uint256 payloadId => bool processed) public statusMap;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superformRouter_, ICoreStateRegistryExtended coreStateRegistry_) {
        SUPERFORM_ROUTER = superformRouter_;
        CORE_STATE_REGISTRY = coreStateRegistry_;
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @dev helps user deposit 4626 vault shares into superform
    /// @param vault_ the 4626 vault to redeem from
    /// @param amount_ the 4626 vault share amount to redeem
    /// @param callData_ the encoded superform router request
    function deposit4626(IERC4626 vault_, uint256 amount_, bytes memory callData_) external payable {
        uint256 payloadStartCount = CORE_STATE_REGISTRY.payloadsCount();

        IERC20 asset = IERC20(IERC4626(vault_).asset());

        /// @dev moves user shares to the user
        vault_.transferFrom(msg.sender, address(this), amount_);

        /// @dev collateral balance before
        uint256 collateralBalanceBefore = asset.balanceOf(address(this));

        /// @dev redeem the vault shares and receive collateral
        vault_.redeem(amount_, address(this), address(this));

        /// @dev collateral balance after
        uint256 collateralBalanceAfter = asset.balanceOf(address(this));
        uint256 collateralAdjusted = collateralBalanceAfter - collateralBalanceBefore;

        /// @dev approves superform router on demand
        asset.approve(SUPERFORM_ROUTER, collateralAdjusted);

        /// @dev processes the deposit to a random superform
        (bool success,) = SUPERFORM_ROUTER.call{ value: msg.value }(callData_);

        /// @dev revert if not `success`
        if (!success) {
            revert();
        }

        uint256 payloadEndCount = CORE_STATE_REGISTRY.payloadsCount();

        if (payloadEndCount - payloadStartCount > 0) {
            for (uint256 i = payloadStartCount; i < payloadEndCount; i++) {
                msgSenderMap[i] = msg.sender;
            }
        }

        /// @dev refund any unused funds
        _processRefunds(asset);
    }

    /// @dev helps user deposit ERC20 tokens into superform using smart contract wallets
    /// @param asset_ the ERC20 asset to deposit
    /// @param amount_ the ERC20 amount to deposit
    /// @param callData_ the encoded superform router deposit request
    function deposit20(IERC20 asset_, uint256 amount_, bytes memory callData_) external payable {
        uint256 payloadStartCount = CORE_STATE_REGISTRY.payloadsCount();

        /// @dev moves user tokens to this address
        asset_.transferFrom(msg.sender, address(this), amount_);

        /// @dev collateral balance before
        uint256 collateralBalanceBefore = asset_.balanceOf(address(this));

        /// @dev collateral balance after
        uint256 collateralBalanceAfter = asset_.balanceOf(address(this));
        uint256 collateralAdjusted = collateralBalanceAfter - collateralBalanceBefore;

        /// @dev approves superform router on demand
        asset_.approve(SUPERFORM_ROUTER, collateralAdjusted);

        /// @dev processes the deposit to a random superform
        (bool success,) = SUPERFORM_ROUTER.call{ value: msg.value }(callData_);

        /// @dev revert if not `success`
        if (!success) {
            revert();
        }

        uint256 payloadEndCount = CORE_STATE_REGISTRY.payloadsCount();

        if (payloadEndCount - payloadStartCount > 0) {
            for (uint256 i = payloadStartCount; i < payloadEndCount; i++) {
                msgSenderMap[i] = msg.sender;
            }
        }

        /// @dev refund any unused funds
        _processRefunds(asset_);
    }

    /// @dev this is callback payload id
    function completeDisbursement(uint256 payloadId) external {
        AMBMessage memory message_ =
            AMBMessage(CORE_STATE_REGISTRY.payloadHeader(payloadId), CORE_STATE_REGISTRY.payloadBody(payloadId));

        /// make sure the callback type is return
        if (statusMap[payloadId]) {
            revert();
        }

        statusMap[payloadId] = true;
    }

    /// @dev overrides receive functions
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        override
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        override
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    //////////////////////////////////////////////////////////////
    //                   INTERNAL FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev refunds any unused refunds
    function _processRefunds(IERC20 asset_) internal {
        uint256 balance = asset_.balanceOf(address(this));

        if (balance > 0) {
            asset_.transfer(msg.sender, balance);
        }
    }
}
