// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { IERC1155Receiver } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IBaseSuperformRouterPlus } from "src/interfaces/IBaseSuperformRouterPlus.sol";
import { IBaseRouter } from "src/interfaces/IBaseRouter.sol";
import { Error } from "src/libraries/Error.sol";
import {
    SingleDirectSingleVaultStateReq,
    SingleDirectMultiVaultStateReq,
    SingleXChainSingleVaultStateReq,
    SingleXChainMultiVaultStateReq,
    MultiDstMultiVaultStateReq,
    MultiDstSingleVaultStateReq
} from "src/types/DataTypes.sol";

abstract contract BaseSuperformRouterPlus is IBaseSuperformRouterPlus, IERC1155Receiver {
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////
    //                       CONSTANTS                          //
    //////////////////////////////////////////////////////////////
    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;
    uint256 internal constant ENTIRE_SLIPPAGE = 10_000;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    mapping(Actions => mapping(bytes4 selector => bool whitelisted)) public whitelistedSelectors;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) {
        if (superRegistry_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);

        superRegistry = ISuperRegistry(superRegistry_);

        whitelistedSelectors[Actions.REBALANCE_FROM_SINGLE][IBaseRouter.singleDirectSingleVaultWithdraw.selector] = true;
        whitelistedSelectors[Actions.REBALANCE_FROM_MULTI][IBaseRouter.singleDirectMultiVaultWithdraw.selector] = true;
        whitelistedSelectors[Actions.REBALANCE_X_CHAIN_FROM_SINGLE][IBaseRouter.singleXChainSingleVaultWithdraw.selector]
        = true;
        whitelistedSelectors[Actions.REBALANCE_X_CHAIN_FROM_MULTI][IBaseRouter.singleXChainMultiVaultWithdraw.selector]
        = true;
        whitelistedSelectors[Actions.REBALANCE_X_CHAIN_FROM_MULTI][IBaseRouter.multiDstSingleVaultWithdraw.selector] =
            true;
        whitelistedSelectors[Actions.REBALANCE_X_CHAIN_FROM_MULTI][IBaseRouter.multiDstMultiVaultWithdraw.selector] =
            true;

        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.singleDirectSingleVaultDeposit.selector] = true;
        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.singleXChainSingleVaultDeposit.selector] = true;
        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.singleDirectMultiVaultDeposit.selector] = true;
        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.singleXChainMultiVaultDeposit.selector] = true;
        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.multiDstSingleVaultDeposit.selector] = true;
        whitelistedSelectors[Actions.DEPOSIT][IBaseRouter.multiDstMultiVaultDeposit.selector] = true;
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

    function _callSuperformRouter(address router_, bytes memory callData_, uint256 msgValue_) internal {
        (bool success, bytes memory returndata) = router_.call{ value: msgValue_ }(callData_);

        Address.verifyCallResult(success, returndata);
    }

    function _deposit(
        address router_,
        IERC20 asset_,
        uint256 amountToDeposit_,
        uint256 msgValue_,
        bytes memory callData_
    )
        internal
    {
        /// @dev approves superform router on demand
        asset_.forceApprove(router_, amountToDeposit_);

        /// TODO confirm if we should validate depositCallData with receiverAddressSP and other parameters?
        /// @notice this is used in all actions. In cross chain rebalances, most key data is validated, but not on
        /// @notice same chain rebalances or deposits

        _callSuperformRouter(router_, callData_, msgValue_);
    }

    /// @dev returns the address from super registry
    function _getAddress(bytes32 id_) internal view returns (address) {
        return superRegistry.getAddress(id_);
    }
}
