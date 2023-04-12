///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC165Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol";
import {IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC165Upgradeable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {InitSingleVaultData} from "./types/DataTypes.sol";
import {LiqRequest} from "./types/LiquidityTypes.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {Error} from "./utils/Error.sol";

/// @title BaseForm
/// @author Zeropoint Labs.
/// @dev Abstract contract to be inherited by different form implementations
/// @notice WIP: deposit and withdraw functions' arguments should be made uniform across direct and xchain
abstract contract BaseForm is Initializable, ERC165Upgradeable, IBaseForm {
    /*///////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant PRECISION_DECIMALS = 27;

    uint256 internal constant PRECISION = 10 ** PRECISION_DECIMALS;

    bytes32 public constant SUPER_ROUTER_ROLE = keccak256("SUPER_ROUTER_ROLE");

    bytes32 public constant TOKEN_BANK_ROLE = keccak256("TOKEN_BANK_ROLE");

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice state variable are all declared public to avoid creating functions to expose.

    /// @dev The superRegistry address is used to access relevant protocol addresses
    ISuperRegistry public immutable superRegistry;

    /// @dev the vault this form pertains to
    address public vault;

    /// @dev chainId represents the superform chain id of the specific chain.
    uint16 public chainId;

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlySuperRouter() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasSuperRouterRole(
                msg.sender
            )
        ) revert Error.NOT_SUPER_ROUTER();
        _;
    }

    modifier onlyTokenBank() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasTokenBankRole(msg.sender))
            revert Error.NOT_TOKEN_BANK();
        _;
    }

    modifier onlyProtocolAdmin() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(
                msg.sender
            )
        ) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);

        _disableInitializers();
    }

    /// @param chainId_              Layerzero chain id
    /// @param superRegistry_        ISuperRegistry address deployed
    /// @param vault_         The vault address this form pertains to
    /// @dev sets caller as the admin of the contract.
    /// @dev FIXME: missing means for admin to change implementations
    function initialize(
        uint16 chainId_,
        address superRegistry_,
        address vault_
    ) external initializer {
        if (chainId_ == 0) revert Error.INVALID_INPUT_CHAIN_ID();
        if (ISuperRegistry(superRegistry_) != superRegistry)
            revert Error.NOT_SUPER_REGISTRY();
        chainId = chainId_;
        vault = vault_;
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IBaseForm).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmount  The amount of tokens deposited in same chain action
    /// @dev NOTE: Should this function return?
    function directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) external payable override onlySuperRouter returns (uint256 dstAmount) {
        dstAmount = _directDepositIntoVault(singleVaultData_);
    }

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmount  The amount of tokens deposited in same chain action
    /// @dev NOTE: Should this function return?
    function xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) external override onlyTokenBank returns (uint256 dstAmount) {
        dstAmount = _xChainDepositIntoVault(singleVaultData_);
    }

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process withdrawal of collateral from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmount  The amount of tokens withdrawn in same chain action
    function directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) external override onlySuperRouter returns (uint256 dstAmount) {
        dstAmount = _directWithdrawFromVault(singleVaultData_);
    }

    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process withdrawal of collateral from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmounts  The amount of tokens withdrawn in same chain action
    function xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) external override onlyTokenBank returns (uint256[] memory dstAmounts) {
        /// @dev FIXME: not returning anything YET
        _xChainWithdrawFromVault(singleVaultData_);
    }

    /*///////////////////////////////////////////////////////////////
                    PURE/VIEW VIRTUAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @return True if the vaults supported by this form use transferrable ERC20 tokens
    /// to represent shares, false otherwise.
    function vaultSharesIsERC20() public pure virtual returns (bool);

    /// @return True if the vaults supported by this form use transferrable ERC20 tokens
    /// to represent shares, false otherwise.
    function vaultSharesIsERC4626() public pure virtual returns (bool);

    /// @return True if the vaults supported by this form use transferrable ERC20 tokens
    /// to represent shares, false otherwise.
    function vaultSharesIsERC721() public pure virtual returns (bool);

    /// @notice get Superform name of the ERC20 vault representation
    /// @return The ERC20 name
    function superformYieldTokenName()
        external
        view
        virtual
        returns (string memory);

    /// @notice get Superform symbol of the ERC20 vault representation
    /// @return The ERC20 symbol
    function superformYieldTokenSymbol()
        external
        view
        virtual
        returns (string memory);

    /// @notice get Supershare decimals of the ERC20 vault representation
    function superformYieldTokenDecimals()
        external
        view
        virtual
        returns (uint256);

    /// @notice Returns the underlying token of a vault.
    /// @return The underlying token
    function getUnderlyingOfVault() public view virtual returns (ERC20);

    /// @notice Returns the amount of underlying tokens each share of a vault is worth.
    /// @return The pricePerVaultShare value
    function getPricePerVaultShare() public view virtual returns (uint256);

    /// @notice Returns the amount of vault shares owned by the form.
    /// @return The form's vault share balance
    function getVaultShareBalance() public view virtual returns (uint256);

    /// @notice get the total amount of underlying managed in the ERC4626 vault
    /// NOTE: does not exist in timeless implementation
    function getTotalAssets() public view virtual returns (uint256);

    /// @notice get the total amount of assets received if shares are converted
    function getConvertPricePerVaultShare()
        public
        view
        virtual
        returns (uint256);

    /// @notice get the total amount of assets received if shares are actually redeemed
    /// @notice https://eips.ethereum.org/EIPS/eip-4626
    function getPreviewPricePerVaultShare()
        public
        view
        virtual
        returns (uint256);

    /// @dev API may need to know state of funds deployed
    function previewDepositTo(
        uint256 assets_
    ) public view virtual returns (uint256);

    /// @notice positionBalance() -> .vaultIds&destAmounts
    /// @return how much of an asset + interest (accrued) is to withdraw from the Vault
    function previewWithdrawFrom(
        uint256 assets_
    ) public view virtual returns (uint256);

    /*///////////////////////////////////////////////////////////////
                INTERNAL STATE CHANGING VIRTUAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Deposits underlying tokens into a vault
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual returns (uint256 dstAmount);

    /// @dev Withdraws underlying tokens from a vault
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual returns (uint256 dstAmount);

    /// @dev Deposits underlying tokens into a vault
    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual returns (uint256 dstAmount);

    /// @dev Withdraws underlying tokens from a vault
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    ) internal virtual;

    /*///////////////////////////////////////////////////////////////
                    INTERNAL VIEW VIRTUAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Converts a vault share amount into an equivalent underlying asset amount
    function _vaultSharesAmountToUnderlyingAmount(
        uint256 vaultSharesAmount_,
        uint256 pricePerVaultShare_
    ) internal view virtual returns (uint256);

    /// @dev Converts a vault share amount into an equivalent underlying asset amount, rounding up
    function _vaultSharesAmountToUnderlyingAmountRoundingUp(
        uint256 vaultSharesAmount_,
        uint256 pricePerVaultShare_
    ) internal view virtual returns (uint256);

    /// @dev Converts an underlying asset amount into an equivalent vault shares amount
    function _underlyingAmountToVaultSharesAmount(
        uint256 underlyingAmount_,
        uint256 pricePerVaultShare_
    ) internal view virtual returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            DEV FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev FIXME Decide to keep this?
    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @notice should be removed after end-to-end testing.
    /// @dev allows admin to withdraw lost tokens in the smart contract.
    function emergencyWithdrawToken(
        address tokenContract_,
        uint256 amount
    ) external onlyProtocolAdmin {
        ERC20 tokenContract = ERC20(tokenContract_);

        /// note: transfer the token from address of this contract
        /// note: to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, amount);
    }

    /// @dev FIXME Decide to keep this?
    /// TODO: transfer may not work in zkSync - careful
    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @dev allows admin to withdraw lost native tokens in the smart contract.
    function emergencyWithdrawNativeToken(
        uint256 amount
    ) external onlyProtocolAdmin {
        payable(msg.sender).transfer(amount);
    }
}
