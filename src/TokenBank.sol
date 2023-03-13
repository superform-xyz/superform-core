///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "./interfaces/IERC4626.sol";
import {StateData, FormData, FormCommonData, FormXChainData, XChainActionArgs, TransactionType} from "./types/DataTypes.sol";
import {LiqRequest} from "./types/LiquidityTypes.sol";
import {IStateRegistry} from "./interfaces/IStateRegistry.sol";
import {LiqRequest} from "./types/LiquidityTypes.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {ISuperFormFactory} from "./interfaces/ISuperFormFactory.sol";

/// @title Super Destination
/// @author Zeropoint Labs.
/// @dev Deposits/Withdraw users funds from an input valid vault.
/// extends Socket's Liquidity Handler.
/// @notice access controlled is expected to be removed due to contract sizing.
contract SuperDestination is
    AccessControl
{
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                    Access Control Role Constants
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");

    /*///////////////////////////////////////////////////////////////
                     State Variables
    //////////////////////////////////////////////////////////////*/

    /// @notice state variable are all declared public to avoid creating functions to expose.

    /// @dev stateRegistry points to the state registry interface deployed in the respective chain.
    IStateRegistry public stateRegistry;

    /// @dev chainId represents the layerzero chain id of the specific chain.
    uint256 public chainId;

    /// @dev superFormFactory address is used to query for forms based on Id received in the state sync data.
    ISuperFormFactory public superFormFactory;

    /// @dev bridge id is mapped to a bridge address (to prevent interaction with unauthorized bridges)
    mapping(uint8 => address) public bridgeAddress;
    /// TODO: add bridge id to bridge address mapping
    /// @notice deploy stateRegistry before SuperDestination
    /// @param chainId_              Layerzero chain id
    /// @param stateRegistry_         State Registry address deployed
    /// @param superFormFactory_     SuperFormFactory address deployed
    /// @dev sets caller as the admin of the contract.
    constructor(uint256 chainId_, IStateRegistry stateRegistry_, ISuperFormFactory superFormFactory_) {
        chainId = chainId_;
        stateRegistry = stateRegistry_;
        superFormFactory = superFormFactory_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}

    /// @dev handles the state when received from the source chain.
    /// @param payload_     represents the payload id associated with the transaction.
    /// note: called by external keepers when state is ready.
    function stateSync(bytes memory payload_) external payable {
        require(
            msg.sender == address(stateRegistry),
            "Destination: request denied"
        );
        StateData memory stateData = abi.decode(payload_, (StateData));
        FormData memory data = abi.decode(stateData.params, (FormData));
        FormCommonData memory commonData = abi.decode(
            data.commonData,
            (FormCommonData)
        );
        /// @notice we dont need to decode xChainData as it is decided directly on the BaseForm implementation for now.
        // FormXChainData memory xChainData = abi.decode(
        //     data.xChainData,
        //     (FormXChainData)
        // );
        for (uint256 i = 0; i < commonData.vaults.length; i++) {
            (address vault_,address formId_, ) = superFormFactory.getSuperForm(commonData.vaults[i]);
            if (stateData.txType == TransactionType.DEPOSIT) {
                if (
                    /// TODO: generalise a way to check for balance for all types of formIds, for now works for ERC4626 and ERC20's
                    IERC20(IBaseForm(formId_).getUnderlyingOfVault(vault_)).balanceOf(
                        address(this)
                    ) >= commonData.amounts[i]
                ) {
                    /// @notice this means it currently only supports single vault deposit as we are checking for balance of the first vault
                    /// TODO: we have to optimize this flow for multi-vault deposits that would need changes to baseForms and how they handle deposits/withdraws in loop.
                    IBaseForm(formId_).depositIntoVault(data);
                } else {
                    revert("Destination: Bridge Tokens Pending");
                }
            } else {
                IBaseForm(formId_).withdrawFromVault(data);
            }
        }
    }

}