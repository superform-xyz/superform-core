// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { IEmergencyQueue } from "src/interfaces/IEmergencyQueue.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { Error } from "src/libraries/Error.sol";
import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { ERC165 } from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

/// @title BaseForm
/// @dev Abstract contract to be inherited by different Form implementations
/// @author Zeropoint Labs
abstract contract BaseForm is IBaseForm, Initializable, ERC165 {
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
        if (superRegistry_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

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

    /// @inheritdoc IBaseForm
    function getTotalSupply() public view virtual override returns (uint256);

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

    /// @param superRegistry_  ISuperRegistry address deployed
    /// @param vault_ The vault address this form pertains to
    /// @param asset_ The underlying asset address of the vault this form pertains to
    function initialize(address superRegistry_, address vault_, address asset_) external initializer {
        if (ISuperRegistry(superRegistry_) != superRegistry) revert Error.NOT_SUPER_REGISTRY();
        if (vault_ == address(0) || asset_ == address(0)) revert Error.ZERO_ADDRESS();
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
        returns (uint256 shares)
    {
        shares = _directDepositIntoVault(singleVaultData_, srcSender_);
    }

    /// @inheritdoc IBaseForm
    function directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        external
        override
        onlySuperRouter
        returns (uint256 assets)
    {
        if (!_isPaused(singleVaultData_.superformId)) {
            assets = _directWithdrawFromVault(singleVaultData_, srcSender_);
        } else {
            IEmergencyQueue(superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(singleVaultData_);
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
        returns (uint256 shares)
    {
        if (srcChainId_ != 0 && srcChainId_ != CHAIN_ID) {
            shares = _xChainDepositIntoVault(singleVaultData_, srcSender_, srcChainId_);
        } else {
            revert Error.INVALID_CHAIN_ID();
        }
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
        returns (uint256 assets)
    {
        if (srcChainId_ != 0 && srcChainId_ != CHAIN_ID) {
            if (!_isPaused(singleVaultData_.superformId)) {
                assets = _xChainWithdrawFromVault(singleVaultData_, srcSender_, srcChainId_);
            } else {
                IEmergencyQueue(superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(
                    singleVaultData_
                );
            }
        } else {
            revert Error.INVALID_CHAIN_ID();
        }
    }

    /// @inheritdoc IBaseForm
    function emergencyWithdraw(address receiverAddress_, uint256 amount_) external override onlyEmergencyQueue {
        _emergencyWithdraw(receiverAddress_, amount_);
    }

    /// @inheritdoc IBaseForm
    function forwardDustToPaymaster(address token_) external override {
        if (token_ == vault) revert Error.CANNOT_FORWARD_4646_TOKEN();
        _forwardDustToPaymaster(token_);
    }

    /// @dev Checks if the Form implementation has the appropriate interface support
    /// @param interfaceId_ is the interfaceId to check
    function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId_ == type(IBaseForm).interfaceId || super.supportsInterface(interfaceId_);
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
        returns (uint256 shares);

    /// @dev Deposits underlying tokens into a vault
    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        virtual
        returns (uint256 shares);

    /// @dev Withdraws underlying tokens from a vault
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        internal
        virtual
        returns (uint256 assets);

    /// @dev Withdraws underlying tokens from a vault
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        virtual
        returns (uint256 assets);

    /// @dev withdraws vault shares from form during emergency
    function _emergencyWithdraw(address receiverAddress_, uint256 amount_) internal virtual;

    /// @dev forwards dust to paymaster
    function _forwardDustToPaymaster(address token_) internal virtual;

    /// @dev returns if a form id is paused
    function _isPaused(uint256 superformId) internal view returns (bool) {
        address factory = superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"));
        if (!ISuperformFactory(factory).isSuperform(superformId)) {
            revert Error.SUPERFORM_ID_NONEXISTENT();
        }

        (, uint32 formImplementationId_,) = superformId.getSuperform();

        return ISuperformFactory(factory).isFormImplementationPaused(formImplementationId_);
    }
}
