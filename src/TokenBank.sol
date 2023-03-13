///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "./interfaces/IERC4626.sol";
import {LiquidityHandler} from "./crosschain-liquidity/LiquidityHandler.sol";
import {StateData, TransactionType, CallbackType, InitData, ReturnData} from "./types/DataTypes.sol";
import {LiqRequest} from "./types/LiquidityTypes.sol";
import {IStateRegistry} from "./interfaces/IStateRegistry.sol";

/// @title Token Bank
/// @author Zeropoint Labs.
/// @dev Receives underlying tokens while in flight to forms
contract TokenBank {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                     State Variables
    //////////////////////////////////////////////////////////////*/

    /// @notice state variable are all declared public to avoid creating functions to expose.

    /// @dev stateRegistry points to the state registry interface deployed in the respective chain.
    IStateRegistry public stateRegistry;

    /// @notice deploy stateRegistry before SuperDestination
    /// @param chainId_              Layerzero chain id
    /// @param stateRegistry_         State Registry address deployed
    /// @dev sets caller as the admin of the contract.
    constructor(uint256 chainId_, IStateRegistry stateRegistry_) {
        chainId = chainId_;
        stateRegistry = stateRegistry_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev handles the state when received from the source chain.
    /// @param payload_     represents the payload id associated with the transaction.
    /// note: called by external keepers when state is ready.
    function stateSync(bytes memory payload_) external payable override {
        require(
            msg.sender == address(stateRegistry),
            "Destination: request denied"
        );
        StateData memory stateData = abi.decode(payload_, (StateData));
        InitData memory data = abi.decode(stateData.params, (InitData));

        for (uint256 i = 0; i < data.vaultIds.length; i++) {
            if (stateData.txType == TransactionType.DEPOSIT) {
                if (
                    IERC20(vault[data.vaultIds[i]].asset()).balanceOf(
                        address(this)
                    ) >= data.amounts[i]
                ) {
                    /// @dev this should call IBaseForm
                    processDeposit(data);
                } else {
                    revert("Destination: Bridge Tokens Pending");
                }
            } else {
                /// @dev this should call IBaseForm

                processWithdrawal(data);
            }
        }
    }
}
