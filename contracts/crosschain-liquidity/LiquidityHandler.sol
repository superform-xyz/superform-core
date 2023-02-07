// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Liquidity Handler.
 * @author Zeropoint Labs.
 * @dev bridges tokens from Chain A -> Chain B
 */
abstract contract LiquidityHandler {
    /* ================ Write Functions =================== */

    /**
     * @dev dispatches tokens via the socket bridge.
     *
     * @param _txData           represents the api response data from socket api.
     * @param _to               represents the socket registry implementation address.
     * @param _allowanceTarget  represents the allowance target (zero address for native tokens)
     * @param _token            represents the ERC20 token to be transferred (zero address for native tokens)
     * @param _amount           represents the amount of tokens to be bridged.
     *
     * Note: refer https://docs.socket.tech/socket-api/v2/guides/socket-smart-contract-integration
     * Note: All the inputs are in array for processing multiple transactions.
     */
    function dispatchTokens(
        address _to,
        bytes memory _txData,
        address _token,
        address _allowanceTarget,
        uint256 _amount,
        address _owner,
        uint256 _nativeAmount
    ) internal virtual {
        /// @dev if allowance target is zero address represents non-native tokens.
        if (_allowanceTarget != address(0)) {
            if (_owner != address(this)) {
                require(
                    IERC20(_token).allowance(_owner, address(this)) >= _amount,
                    "Bridge Error: Insufficient approvals"
                );
                IERC20(_token).transferFrom(_owner, address(this), _amount);
            }
            IERC20(_token).approve(_allowanceTarget, _amount);
            unchecked {
                (bool success, ) = payable(_to).call{value: _nativeAmount}(
                    _txData
                );
                require(success, "Bridge Error: Failed To Execute Tx Data (1)");
            }
        } else {
            require(msg.value >= _amount, "Liq Handler: Insufficient Amount");
            unchecked {
                (bool success, ) = payable(_to).call{
                    value: _amount + _nativeAmount
                }(_txData);
                require(success, "Bridge Error: Failed To Execute Tx Data (2)");
            }
        }
    }
}
