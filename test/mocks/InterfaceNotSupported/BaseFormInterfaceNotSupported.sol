// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { ERC165 } from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { Error } from "src/libraries/Error.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { IEmergencyQueue } from "src/interfaces/IEmergencyQueue.sol";

/// @title BaseForm
/// @author Zeropoint Labs.
/// @dev Abstract contract to be inherited by different form implementations
abstract contract BaseForm is Initializable, ERC165, IBaseForm {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev The superRegistry address is used to access relevant protocol addresses
    ISuperRegistry public immutable superRegistry;

    /// @dev The emergency queue is used to help users exit after forms are paused
    IEmergencyQueue public emergencyQueue;

    /// @dev the vault this form pertains to
    address internal vault;

    uint32 public formImplementationId;

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier notPaused(InitSingleVaultData memory singleVaultData_) {
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
        if (msg.sender != address(emergencyQueue)) {
            revert Error.NOT_EMERGENCY_QUEUE();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);

        _disableInitializers();
    }

    /// @param superRegistry_        ISuperRegistry address deployed
    /// @param vault_         The vault address this form pertains to
    /// @dev sets caller as the admin of the contract.
    function initialize(address superRegistry_, address vault_, uint32 formImplementationId_) external initializer {
        if (ISuperRegistry(superRegistry_) != superRegistry) revert Error.NOT_SUPER_REGISTRY();

        address emergencyQueue_ = superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"));
        if (emergencyQueue_ == address(0)) revert Error.ZERO_ADDRESS();

        emergencyQueue = IEmergencyQueue(emergencyQueue_);
        formImplementationId = formImplementationId_;
        vault = vault_;
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/
    receive() external payable { }

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
        notPaused(singleVaultData_)
        returns (uint256 assets)
    {
        assets = _directWithdrawFromVault(singleVaultData_, srcSender_);
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
        shares = _xChainDepositIntoVault(singleVaultData_, srcSender_, srcChainId_);
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
        notPaused(singleVaultData_)
        returns (uint256 assets)
    {
        assets = _xChainWithdrawFromVault(singleVaultData_, srcSender_, srcChainId_);
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
    function forwardDustToPaymaster(address token_) external override {
        if (token_ == vault) revert Error.CANNOT_FORWARD_4646_TOKEN();
        _forwardDustToPaymaster(token_);
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
        return vault;
    }

    /// @inheritdoc IBaseForm
    function getPricePerVaultShare() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function getVaultShareBalance() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function getTotalAssets() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function getTotalSupply() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function getStateRegistryId() external view virtual override returns (uint8);

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
        returns (uint256 shares);

    /// @dev Withdraws underlying tokens from a vault
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        internal
        virtual
        returns (uint256 assets);

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
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        virtual
        returns (uint256 assets);

    /// @dev withdraws vault shares from form during emergency
    function _emergencyWithdraw(address srcSender_, address refundAddress_, uint256 amount_) internal virtual;

    /// @dev forwards dust to paymaster
    function _forwardDustToPaymaster(address token_) internal virtual;
}
