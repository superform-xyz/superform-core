// SPDX-License-Identifier: ISC
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

/**
 * @title Liquidity Handler.
 * @author Zeropoint Labs.
 * @dev bridges tokens from Chain A -> Chain B
 */
abstract contract LiquidityBank {
    using SafeTransferLib for ERC20;

    /* ================ Write Functions =================== */

    /**
     * @dev dispatches tokens via the socket bridge.
     *
     * Note: refer https://docs.socket.tech/socket-api/v2/guides/socket-smart-contract-integration
     * Note: All the inputs are in array for processing multiple transactions.
     */
    function dispatchTokens(
        address _bridge, /// @dev Bridge address to pass tokens to
        bytes memory _txData, /// @dev Socket data
        address _token, /// @dev Token caller deposits into superform
        bool _isERC20, /// address _allowanceTarget NOT NEEDED / RE-WORK TO NATIVE/NON-NATIVE CHECK
        uint256 _amount, /// @dev Amount of tokens to deposit
        address _owner, /// @dev Owner of tokens
        uint256 _nativeAmount /// @dev LayerZero Gas Costs
    ) internal virtual {
        if (_isERC20) {
            ERC20 token = ERC20(_token);
            /// Don't break the flow. User approves only Router, but Router doesn't get to hold tokens
            /// Here, transfer from the caller to the LiquidityBank
            /// Should work because caller is the Router which has allowance from _owner
            token.safeTransferFrom(_owner, address(this), _amount);
            /// NOTE: Investiage if this can be consolidated in 1 op (maybe bridge has permit?)
            token.safeApprove(_bridge, _amount);
            
            unchecked {
                (bool success, ) = payable(_bridge).call{value: _nativeAmount}(
                    _txData
                );
                require(success, "Bridge Error: Failed To Execute Tx Data (1)");
            
            }
        } else {
            
            /// NOTE: Test if this is reachable
            require(msg.value >= _amount, "Liq Handler: Insufficient Amount");
            
            unchecked {
                (bool success, ) = payable(_bridge).call{value: _nativeAmount}(
                    _txData
                );
                require(success, "Bridge Error: Failed To Execute Tx Data (1)");
            }
        }
    }
}
