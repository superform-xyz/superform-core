/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IBaseRouter } from "./interfaces/IBaseRouter.sol";
import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";
import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";
import { Error } from "./utils/Error.sol";
import "./types/DataTypes.sol";

/// @title BaseRouter
/// @author Zeropoint Labs.
/// @dev Routes users funds and action information to a remote execution chain.
/// @dev abstract implementation that allows inheriting routers to implement their own logic
abstract contract BaseRouter is IBaseRouter {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        CONSTANT/IMMUTABLE
    //////////////////////////////////////////////////////////////*/

    uint8 public immutable STATE_REGISTRY_TYPE;
    uint8 public immutable ROUTER_TYPE;

    ISuperRegistry public immutable superRegistry;

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyEmergencyAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasEmergencyAdminRole(msg.sender)) {
            revert Error.NOT_EMERGENCY_ADMIN();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superRegistry_ the superform registry contract
    /// @param stateRegistryType_ the state registry type
    /// @param routerType_ the router type
    constructor(address superRegistry_, uint8 stateRegistryType_, uint8 routerType_) {
        superRegistry = ISuperRegistry(superRegistry_);
        STATE_REGISTRY_TYPE = stateRegistryType_;
        ROUTER_TYPE = routerType_;
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables processing native token transfers into the smart contract.
    /// @notice liquidity bridge fails without a native receive function.
    receive() external payable { }

    /// @inheritdoc IBaseRouter
    function multiDstMultiVaultDeposit(MultiDstMultiVaultStateReq calldata req) external payable virtual override;

    /// @inheritdoc IBaseRouter
    function multiDstSingleVaultDeposit(MultiDstSingleVaultStateReq calldata req) external payable virtual override;

    /// @inheritdoc IBaseRouter
    function singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req)
        external
        payable
        virtual
        override;

    /// @inheritdoc IBaseRouter
    function singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req)
        external
        payable
        virtual
        override;

    /// @inheritdoc IBaseRouter
    function singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req)
        external
        payable
        virtual
        override;

    /// @inheritdoc IBaseRouter
    function singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req)
        external
        payable
        virtual
        override;

    /// @inheritdoc IBaseRouter
    function multiDstMultiVaultWithdraw(MultiDstMultiVaultStateReq calldata req) external payable virtual override;

    /// @inheritdoc IBaseRouter
    function multiDstSingleVaultWithdraw(MultiDstSingleVaultStateReq calldata req) external payable virtual override;

    /// @inheritdoc IBaseRouter
    function singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq memory req)
        external
        payable
        virtual
        override;
    /// @inheritdoc IBaseRouter
    function singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req)
        external
        payable
        virtual
        override;

    /// @inheritdoc IBaseRouter
    function singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq memory req)
        external
        payable
        virtual
        override;

    /// @inheritdoc IBaseRouter
    function singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq memory req)
        external
        payable
        virtual
        override;

    /*///////////////////////////////////////////////////////////////
                            EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev EMERGENCY_ADMIN ONLY FUNCTION.
    /// @dev allows admin to withdraw lost tokens in the smart contract.
    function emergencyWithdrawToken(address tokenContract_, uint256 amount_) external onlyEmergencyAdmin {
        IERC20 tokenContract = IERC20(tokenContract_);

        /// note: transfer the token from address of this contract
        /// note: to address of the user (executing the withdrawToken() function)
        tokenContract.safeTransfer(msg.sender, amount_);
    }

    /// @dev EMERGENCY_ADMIN ONLY FUNCTION.
    /// @dev allows admin to withdraw lost native tokens in the smart contract.
    function emergencyWithdrawNativeToken(uint256 amount_) external onlyEmergencyAdmin {
        (bool success,) = payable(msg.sender).call{ value: amount_ }("");
        if (!success) revert Error.NATIVE_TOKEN_TRANSFER_FAILURE();
    }
}
