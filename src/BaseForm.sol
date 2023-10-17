///SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { ERC165 } from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import { InitSingleVaultData } from "./types/DataTypes.sol";
import { IBaseForm } from "./interfaces/IBaseForm.sol";
import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";
import { Error } from "./utils/Error.sol";
import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";
import { IEmergencyQueue } from "./interfaces/IEmergencyQueue.sol";
import { DataLib } from "./libraries/DataLib.sol";
import { Clone } from "clones-with-immutable-args/Clone.sol";

/// @title BaseForm
/// @author Zeropoint Labs.
/// @dev Abstract contract to be inherited by different form implementations
abstract contract BaseForm is Clone, ERC165, IBaseForm {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant PRECISION_DECIMALS = 27;

    uint256 internal constant PRECISION = 10 ** PRECISION_DECIMALS;

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier notPaused(InitSingleVaultData memory singleVaultData_) {
        (, uint32 formImplementationId_,) = singleVaultData_.superformId.getSuperform();

        if (formImplementationId() != formImplementationId_) revert Error.INVALID_SUPERFORMS_DATA();

        if (
            ISuperformFactory(ISuperRegistry(superRegistry()).getAddress(keccak256("SUPERFORM_FACTORY")))
                .isFormImplementationPaused(formImplementationId_)
        ) revert Error.PAUSED();
        _;
    }

    modifier onlySuperRouter() {
        if (ISuperRegistry(superRegistry()).getSuperformRouterId(msg.sender) == 0) revert Error.NOT_SUPER_ROUTER();
        _;
    }

    modifier onlyCoreStateRegistry() {
        if (ISuperRegistry(superRegistry()).getAddress(keccak256("CORE_STATE_REGISTRY")) != msg.sender) {
            revert Error.NOT_CORE_STATE_REGISTRY();
        }
        _;
    }

    modifier onlyEmergencyQueue() {
        if (msg.sender != ISuperRegistry(superRegistry()).getAddress(keccak256("EMERGENCY_QUEUE"))) {
            revert Error.NOT_EMERGENCY_QUEUE();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev The superRegistry address is used to access relevant protocol addresses
    function superRegistry() public pure returns (address) {
        return _getArgAddress(0);
    }

    /// @dev the vault this form pertains to
    function vault() public pure returns (address) {
        return _getArgAddress(20);
    }

    /// @dev The chainId
    function CHAIN_ID() public pure returns (uint64) {
        return _getArgUint64(40);
    }

    /// @dev The formImplementationId
    function formImplementationId() public pure returns (uint32) {
        return _getArgUint32(48);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/
    receive() external payable { }

    function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId_ == type(IBaseForm).interfaceId || super.supportsInterface(interfaceId_);
    }

    /// @inheritdoc IBaseForm
    function directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        external
        payable
        override
        onlySuperRouter
        notPaused(singleVaultData_)
        returns (uint256 dstAmount)
    {
        dstAmount = _directDepositIntoVault(singleVaultData_, srcSender_);
    }

    /// @inheritdoc IBaseForm
    function directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        external
        override
        onlySuperRouter
        returns (uint256 dstAmount)
    {
        if (!_isPaused(singleVaultData_.superformId)) {
            dstAmount = _directWithdrawFromVault(singleVaultData_, srcSender_);
        } else {
            IEmergencyQueue(ISuperRegistry(superRegistry()).getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(
                singleVaultData_, srcSender_
            );
        }
    }

    /// @inheritdoc IBaseForm
    function xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        external
        override
        onlyCoreStateRegistry
        notPaused(singleVaultData_)
        returns (uint256 dstAmount)
    {
        dstAmount = _xChainDepositIntoVault(singleVaultData_, srcSender_, srcChainId_);
    }

    /// @inheritdoc IBaseForm
    function xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        external
        override
        onlyCoreStateRegistry
        returns (uint256 dstAmount)
    {
        if (!_isPaused(singleVaultData_.superformId)) {
            dstAmount = _xChainWithdrawFromVault(singleVaultData_, srcSender_, srcChainId_);
        } else {
            IEmergencyQueue(ISuperRegistry(superRegistry()).getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(
                singleVaultData_, srcSender_
            );
        }
    }

    /// @inheritdoc IBaseForm
    function emergencyWithdraw(address refundAddress_, uint256 amount_) external override onlyEmergencyQueue {
        _emergencyWithdraw(refundAddress_, amount_);
    }

    /*///////////////////////////////////////////////////////////////
                    PURE/VIEW VIRTUAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBaseForm
    function superformYieldTokenName() external view virtual override returns (string memory);

    /// @inheritdoc IBaseForm
    function superformYieldTokenSymbol() external view virtual override returns (string memory);

    /// @inheritdoc IBaseForm
    function getVaultAsset() public view virtual override returns (address);

    /// @inheritdoc IBaseForm
    function getVaultName() public view virtual override returns (string memory);

    /// @inheritdoc IBaseForm
    function getVaultSymbol() public view virtual override returns (string memory);

    /// @inheritdoc IBaseForm
    function getVaultDecimals() public view virtual override returns (uint256);

    // @inheritdoc IBaseForm
    function getVaultAddress() external view override returns (address) {
        return vault();
    }

    /// @inheritdoc IBaseForm
    function getPricePerVaultShare() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function getVaultShareBalance() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function getTotalAssets() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function getStateRegistryId() external view virtual override returns (uint256);

    // @inheritdoc IBaseForm
    function getPreviewPricePerVaultShare() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function previewDepositTo(uint256 assets_) public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function previewWithdrawFrom(uint256 assets_) public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function previewRedeemFrom(uint256 shares_) public view virtual override returns (uint256);

    /*///////////////////////////////////////////////////////////////
                INTERNAL STATE CHANGING VIRTUAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Deposits underlying tokens into a vault
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        internal
        virtual
        returns (uint256 dstAmount);

    /// @dev Withdraws underlying tokens from a vault
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        internal
        virtual
        returns (uint256 dstAmount_);

    /// @dev Deposits underlying tokens into a vault
    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        virtual
        returns (uint256 dstAmount);

    /// @dev Withdraws underlying tokens from a vault
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        virtual
        returns (uint256 dstAmount);

    /// @dev withdraws vault shares from form during emergency
    function _emergencyWithdraw(address refundAddress_, uint256 amount_) internal virtual;

    /*///////////////////////////////////////////////////////////////
                    INTERNAL VIEW VIRTUAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev returns if a form id is paused
    function _isPaused(uint256 superformId) internal view returns (bool) {
        (, uint32 formImplementationId_,) = superformId.getSuperform();

        if (formImplementationId() != formImplementationId_) revert Error.INVALID_SUPERFORMS_DATA();

        return ISuperformFactory(ISuperRegistry(superRegistry()).getAddress(keccak256("SUPERFORM_FACTORY")))
            .isFormImplementationPaused(formImplementationId_);
    }

    /// @dev Converts a vault share amount into an equivalent underlying asset amount
    function _vaultSharesAmountToUnderlyingAmount(
        uint256 vaultSharesAmount_,
        uint256 pricePerVaultShare_
    )
        internal
        view
        virtual
        returns (uint256);

    /// @dev Converts a vault share amount into an equivalent underlying asset amount, rounding up
    function _vaultSharesAmountToUnderlyingAmountRoundingUp(
        uint256 vaultSharesAmount_,
        uint256 pricePerVaultShare_
    )
        internal
        view
        virtual
        returns (uint256);

    /// @dev Converts an underlying asset amount into an equivalent vault shares amount
    function _underlyingAmountToVaultSharesAmount(
        uint256 underlyingAmount_,
        uint256 pricePerVaultShare_
    )
        internal
        view
        virtual
        returns (uint256);

    /*///////////////////////////////////////////////////////////////
                    INTERNAL EXTENSION TO CLONES
    //////////////////////////////////////////////////////////////*/

    /// @notice Reads an immutable arg with type uint32
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint32(uint256 argOffset) internal pure returns (uint32 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xe0, calldataload(add(offset, argOffset)))
        }
    }
}
