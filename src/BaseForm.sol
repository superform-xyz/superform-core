///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {InitSingleVaultData} from "./types/DataTypes.sol";
import {LiqRequest} from "./types/LiquidityTypes.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {ISuperFormFactory} from "./interfaces/ISuperFormFactory.sol";

/// @title BaseForm
/// @author Zeropoint Labs.
/// @dev Abstract contract to be inherited by different form implementations
/// @notice WIP: deposit and withdraw functions' arguments should be made uniform across direct and xchain
abstract contract BaseForm is ERC165, IBaseForm, AccessControl {
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

    /// @dev The superFormFactory address is used to create new SuperForms
    ISuperFormFactory public immutable superFormFactory;

    /// @dev chainId represents the superform chain id of the specific chain.
    uint16 public chainId;

    /// @dev bridge id is mapped to a bridge address (to prevent interaction with unauthorized bridges)
    mapping(uint8 => address) public bridgeAddress;

    /*///////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @param chainId_              Layerzero chain id
    /// @param superFormFactory_         ISuperFormFactory address deployed
    /// @dev sets caller as the admin of the contract.
    /// @dev FIXME: missing means for admin to change implementations
    constructor(uint16 chainId_, ISuperFormFactory superFormFactory_) {
        chainId = chainId_;
        superFormFactory = superFormFactory_;
        /// TODO: add tokenBank also for superRouter role for deposit and withdraw
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
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
        override(AccessControl, ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IBaseForm).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @dev allows admin to set the bridge address for an bridge id.
    /// @param bridgeId_         represents the bridge unqiue identifier.
    /// @param bridgeAddress_    represents the bridge address.
    function setBridgeAddress(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < bridgeId_.length; i++) {
            address x = bridgeAddress_[i];
            uint8 y = bridgeId_[i];
            if (x == address(0)) revert ZERO_BRIDGE_ADDRESS();

            bridgeAddress[y] = x;
            emit SetBridgeAddress(y, x);
        }
    }

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process same chain id deposits
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmount  The amount of tokens deposited in same chain action
    /// @dev NOTE: Should this function return?
    function directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_
    )
        external
        payable
        override
        onlyRole(SUPER_ROUTER_ROLE)
        returns (uint256 dstAmount)
    {
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
    )
        external
        virtual
        override
        onlyRole(TOKEN_BANK_ROLE)
        returns (uint256 dstAmount)
    {
        dstAmount = _xChainDepositIntoVault(singleVaultData_);
    }

    /// @dev PREVILEGED router ONLY FUNCTION.
    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process withdrawal of collateral from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmount  The amount of tokens withdrawn in same chain action
    function directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    )
        external
        override
        onlyRole(SUPER_ROUTER_ROLE)
        returns (uint256 dstAmount)
    {
        dstAmount = _directWithdrawFromVault(singleVaultData_);
    }

    /// @dev Note: At this point the router should know the SuperForm to call (form and chain), so we only need the vault address
    /// @dev process withdrawal of collateral from a vault
    /// @param singleVaultData_  A bytes representation containing all the data required to make a form action
    /// @return dstAmounts  The amount of tokens withdrawn in same chain action
    function xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_
    )
        external
        override
        onlyRole(TOKEN_BANK_ROLE)
        returns (uint256[] memory dstAmounts)
    {
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
    /// @param vault_ Address of ERC20 vault representation
    /// @return The ERC20 name
    function superformYieldTokenName(
        address vault_
    ) external view virtual returns (string memory);

    /// @notice get Superform symbol of the ERC20 vault representation
    /// @param vault_ Address of ERC20 vault representation
    /// @return The ERC20 symbol
    function superformYieldTokenSymbol(
        address vault_
    ) external view virtual returns (string memory);

    /// @notice get Supershare decimals of the ERC20 vault representation
    /// @param vault_ Address of ERC20 vault representation
    function superformYieldTokenDecimals(
        address vault_
    ) external view virtual returns (uint256);

    /// @notice Returns the underlying token of a vault.
    /// @param vault_ The vault to query
    /// @return The underlying token
    function getUnderlyingOfVault(
        address vault_
    ) public view virtual returns (ERC20);

    /// @notice Returns the amount of underlying tokens each share of a vault is worth.
    /// @param vault_ The vault to query
    /// @return The pricePerVaultShare value
    function getPricePerVaultShare(
        address vault_
    ) public view virtual returns (uint256);

    /// @notice Returns the amount of vault shares owned by the form.
    /// @param vault_ The vault to query
    /// @return The form's vault share balance
    function getVaultShareBalance(
        address vault_
    ) public view virtual returns (uint256);

    /// @notice get the total amount of underlying managed in the ERC4626 vault
    /// NOTE: does not exist in timeless implementation
    /// @param vault_ The vault to query
    function getTotalAssets(
        address vault_
    ) public view virtual returns (uint256);

    /// @notice get the total amount of assets received if shares are converted
    /// @param vault_ The vault to query
    function getConvertPricePerVaultShare(
        address vault_
    ) public view virtual returns (uint256);

    /// @notice get the total amount of assets received if shares are actually redeemed
    /// @notice https://eips.ethereum.org/EIPS/eip-4626
    /// @param vault_ The vault to query
    function getPreviewPricePerVaultShare(
        address vault_
    ) public view virtual returns (uint256);

    /// @dev API may need to know state of funds deployed
    function previewDepositTo(
        address vault_,
        uint256 assets_
    ) public view virtual returns (uint256);

    /// @notice positionBalance() -> .vaultIds&destAmounts
    /// @return how much of an asset + interest (accrued) is to withdraw from the Vault
    function previewWithdrawFrom(
        address vault_,
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
        address vault_,
        uint256 vaultSharesAmount_,
        uint256 pricePerVaultShare_
    ) internal view virtual returns (uint256);

    /// @dev Converts a vault share amount into an equivalent underlying asset amount, rounding up
    function _vaultSharesAmountToUnderlyingAmountRoundingUp(
        address vault_,
        uint256 vaultSharesAmount_,
        uint256 pricePerVaultShare_
    ) internal view virtual returns (uint256);

    /// @dev Converts an underlying asset amount into an equivalent vault shares amount
    function _underlyingAmountToVaultSharesAmount(
        address vault_,
        uint256 underlyingAmount_,
        uint256 pricePerVaultShare_
    ) internal view virtual returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            DEV FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @notice should be removed after end-to-end testing.
    /// @dev allows admin to withdraw lost tokens in the smart contract.
    function withdrawToken(
        address tokenContract_,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC20 tokenContract = ERC20(tokenContract_);

        /// note: transfer the token from address of this contract
        /// note: to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, amount);
    }

    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @dev allows admin to withdraw lost native tokens in the smart contract.
    function withdrawNativeToken(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(amount);
    }
}
