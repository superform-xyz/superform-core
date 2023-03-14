///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {StateData, FormData, FormCommonData, TransactionType} from "./types/DataTypes.sol";
import {IStateRegistry} from "./interfaces/IStateRegistry.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {ISuperFormFactory} from "./interfaces/ISuperFormFactory.sol";
import {ITokenBank} from "./interfaces/ITokenBank.sol";

/// @title Token Bank
/// @author Zeropoint Labs.
/// @dev Temporary area for underlying tokens to wait until they are ready to be sent to the form vault
contract TokenBank is ITokenBank, AccessControl {
    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                    Access Control Role Constants
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant STATE_REGISTRY_ROLE =
        keccak256("STATE_REGISTRY_ROLE");

    /*///////////////////////////////////////////////////////////////
                     State Variables
    //////////////////////////////////////////////////////////////*/

    /// @notice state variable are all declared public to avoid creating functions to expose.

    /// @dev stateRegistry points to the state registry interface deployed in the respective chain.
    address public stateRegistry;

    /// @dev chainId represents the superform chain id of the specific chain.
    uint80 public chainId;

    /// @dev superFormFactory address is used to query for forms based on Id received in the state sync data.
    ISuperFormFactory public superFormFactory;

    /// TODO: add bridge id to bridge address mapping
    /// @notice deploy stateRegistry before SuperDestination
    /// @param chainId_              Superform chain id
    /// @param stateRegistry_         State Registry address deployed
    /// @param superFormFactory_     SuperFormFactory address deployed
    /// @dev sets caller as the admin of the contract.
    /// @dev FIXME: missing means for admin to change implementations
    constructor(
        uint80 chainId_,
        address stateRegistry_,
        ISuperFormFactory superFormFactory_
    ) {
        chainId = chainId_;
        stateRegistry = stateRegistry_;
        superFormFactory = superFormFactory_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(STATE_REGISTRY_ROLE, stateRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}

    /// @dev handles the state when received from the source chain.
    /// @param payload_     represents the payload id associated with the transaction.
    /// note: called by external keepers when state is ready.
    function stateSync(
        bytes memory payload_
    ) external payable override onlyRole(STATE_REGISTRY_ROLE) {
        StateData memory stateData = abi.decode(payload_, (StateData));
        FormData memory data = abi.decode(stateData.params, (FormData));
        FormCommonData memory commonData = abi.decode(
            data.commonData,
            (FormCommonData)
        );

        for (uint256 i = 0; i < commonData.superFormIds.length; i++) {
            (address vault_, uint256 formId_, ) = superFormFactory.getSuperForm(
                commonData.superFormIds[i]
            );
            address form = superFormFactory.getForm(formId_);
            if (stateData.txType == TransactionType.DEPOSIT) {
                ERC20 underlying = IBaseForm(form).getUnderlyingOfVault(vault_);
                if (
                    /// @dev TODO: generalise a way to check for balance for all types of formIds, for now works for ERC4626 and ERC20's
                    underlying.balanceOf(address(this)) >= commonData.amounts[i]
                ) {
                    /// @dev this means it currently only supports single vault deposit as we are checking for balance of the first vault
                    /// @dev TODO: we have to optimize this flow for multi-vault deposits that would need changes to baseForms and how they handle deposits/withdraws in loop.
                    IBaseForm(form).xChainDepositIntoVault(stateData.params);
                } else {
                    revert BRIDGE_TOKENS_PENDING();
                }
            } else {
                IBaseForm(form).xChainWithdrawFromVault(stateData.params);
            }
        }
    }
}
