///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { Initializable } from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import { ERC165Upgradeable } from
    "openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol";
import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { Error } from "src/utils/Error.sol";
import { IFormBeacon } from "src/interfaces/IFormBeacon.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { DataLib } from "src/libraries/DataLib.sol";

/// @title BaseForm
/// @author Zeropoint Labs.
/// @dev Abstract contract to be inherited by different form implementations
abstract contract BaseForm is Initializable, ERC165Upgradeable, IBaseForm {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant PRECISION_DECIMALS = 27;

    uint256 internal constant PRECISION = 10 ** PRECISION_DECIMALS;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev The superRegistry address is used to access relevant protocol addresses
    ISuperRegistry public immutable superRegistry;

    /// @dev the vault this form pertains to
    address internal vault;

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier notPaused(InitSingleVaultData memory singleVaultData_) {
        (, uint32 formBeaconId_,) = singleVaultData_.superformId.getSuperform();

        if (
            IFormBeacon(
                ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).getFormBeacon(formBeaconId_)
            ).paused() == 2
        ) revert Error.PAUSED();
        _;
    }

    modifier onlySuperRouter() {
        if (superRegistry.getAddress(keccak256("SUPERFORM_ROUTER")) != msg.sender) revert Error.NOT_SUPER_ROUTER();
        _;
    }

    modifier onlyCoreStateRegistry() {
        if (superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY")) != msg.sender) {
            revert Error.NOT_CORE_STATE_REGISTRY();
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
    function initialize(address superRegistry_, address vault_) external initializer {
        if (ISuperRegistry(superRegistry_) != superRegistry) revert Error.NOT_SUPER_REGISTRY();
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
        notPaused(singleVaultData_)
        returns (uint256 dstAmount)
    {
        dstAmount = _directWithdrawFromVault(singleVaultData_, srcSender_);
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
        notPaused(singleVaultData_)
        returns (uint256 dstAmount)
    {
        dstAmount = _xChainWithdrawFromVault(singleVaultData_, srcSender_, srcChainId_);
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
    function getStateRegistryId() external view virtual override returns (uint256);

    // @inheritdoc IBaseForm
    function getPreviewPricePerVaultShare() public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function previewDepositTo(uint256 assets_) public view virtual override returns (uint256);

    /// @inheritdoc IBaseForm
    function previewWithdrawFrom(uint256 assets_) public view virtual override returns (uint256);

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

    /*///////////////////////////////////////////////////////////////
                    INTERNAL VIEW VIRTUAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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
