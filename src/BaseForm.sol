///SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { ERC165 } from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import { InitSingleVaultData } from "./types/DataTypes.sol";
import { IBaseForm } from "./interfaces/IBaseForm.sol";
import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";
import { Error } from "./utils/Error.sol";
import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";
import { IEmergencyQueue } from "./interfaces/IEmergencyQueue.sol";
import { DataLib } from "./libraries/DataLib.sol";

/// @title BaseForm
/// @author Zeropoint Labs.
/// @dev Abstract contract to be inherited by different form implementations
abstract contract BaseForm is Initializable, ERC165, IBaseForm {
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev the address of the vault that was added
    address public vault;

    /// @dev underlying asset of vault this form pertains to
    address public asset;

    /// @dev form which this vault was added to
    uint32 public formImplementationId;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier notPaused(InitSingleVaultData memory singleVaultData_) {
        if (
            !ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).isSuperform(
                singleVaultData_.superformId
            )
        ) {
            revert Error.SUPERFORM_ID_NONEXISTENT();
        }
        (, uint32 formImplementationId_,) = singleVaultData_.superformId.getSuperform();

        if (formImplementationId != formImplementationId_) revert Error.INVALID_SUPERFORMS_DATA();

        if (
            ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).isFormImplementationPaused(
                formImplementationId_
            )
        ) revert Error.PAUSED();
        _;
    }

    modifier onlySuperRouter() {
        if (superRegistry.getAddress(keccak256("SUPERFORM_ROUTER")) != msg.sender) revert Error.NOT_SUPERFORM_ROUTER();
        _;
    }

    modifier onlyCoreStateRegistry() {
        if (superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY")) != msg.sender) {
            revert Error.NOT_CORE_STATE_REGISTRY();
        }
        _;
    }

    modifier onlyEmergencyQueue() {
        if (msg.sender != superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"))) {
            revert Error.NOT_EMERGENCY_QUEUE();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) {
        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);
        superRegistry = ISuperRegistry(superRegistry_);

        _disableInitializers();
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId_ == type(IBaseForm).interfaceId || super.supportsInterface(interfaceId_);
    }

    /// @inheritdoc IBaseForm
    function superformYieldTokenName() external view virtual override returns (string memory);

    /// @inheritdoc IBaseForm
    function superformYieldTokenSymbol() external view virtual override returns (string memory);

    /// @inheritdoc IBaseForm
    function getStateRegistryId() external view virtual override returns (uint8);

    // @inheritdoc IBaseForm
    function getVaultAddress() external view override returns (address) {
        return vault;
    }

    // @inheritdoc IBaseForm
    function getVaultAsset() public view override returns (address) {
        return asset;
    }

    /// @inheritdoc IBaseForm
    function getVaultName() public view virtual override returns (string memory);

    /// @inheritdoc IBaseForm
    function getVaultSymbol() public view virtual override returns (string memory);

    /// @inheritdoc IBaseForm
    function getVaultDecimals() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function getPricePerVaultShare() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function getVaultShareBalance() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function getTotalAssets() public view virtual override returns (uint256);

    // @inheritdoc IBaseForm
    function getPreviewPricePerVaultShare() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function previewDepositTo(uint256 assets_) public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function previewWithdrawFrom(uint256 assets_) public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function previewRedeemFrom(uint256 shares_) public view virtual override returns (uint256);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    receive() external payable { }

    /// @param superRegistry_        ISuperRegistry address deployed
    /// @param vault_         The vault address this form pertains to
    /// @dev sets caller as the admin of the contract.
    function initialize(
        address superRegistry_,
        address vault_,
        uint32 formImplementationId_,
        address asset_
    )
        external
        initializer
    {
        if (ISuperRegistry(superRegistry_) != superRegistry) revert Error.NOT_SUPER_REGISTRY();

        formImplementationId = formImplementationId_;
        vault = vault_;
        asset = asset_;
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
            IEmergencyQueue(superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(
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
            IEmergencyQueue(superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(
                singleVaultData_, srcSender_
            );
        }
    }

    /// @inheritdoc IBaseForm
    function emergencyWithdraw(
        address srcSender_,
        address refundAddress_,
        uint256 amount_
    )
        external
        override
        onlyEmergencyQueue
    {
        _emergencyWithdraw(srcSender_, refundAddress_, amount_);
    }

    /// @inheritdoc IBaseForm
    function forwardDustToPaymaster() external override {
        _forwardDustToPaymaster();
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev Deposits underlying tokens into a vault
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        internal
        virtual
        returns (uint256 dstAmount);

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
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        internal
        virtual
        returns (uint256 dstAmount_);

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
    function _emergencyWithdraw(address srcSender_, address refundAddress_, uint256 amount_) internal virtual;

    /// @dev forwards dust to paymaster
    function _forwardDustToPaymaster() internal virtual;

    /// @dev returns if a form id is paused
    function _isPaused(uint256 superformId) internal view returns (bool) {
        if (!ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).isSuperform(superformId)) {
            revert Error.SUPERFORM_ID_NONEXISTENT();
        }
        (, uint32 formImplementationId_,) = superformId.getSuperform();

        if (formImplementationId != formImplementationId_) revert Error.INVALID_SUPERFORMS_DATA();

        return ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).isFormImplementationPaused(
            formImplementationId_
        );
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
}
