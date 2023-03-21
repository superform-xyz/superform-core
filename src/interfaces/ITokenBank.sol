// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {LiqRequest} from "../types/LiquidityTypes.sol";
import {IERC4626} from "../interfaces/IERC4626.sol";

interface ITokenBank {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @dev is emitted when layerzero safe gas params are updated.
    event SafeGasParamUpdated(bytes oldParam, bytes newParam);
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev error thrown when the bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /// @dev error thrown when the safe gas param is incorrectly set
    error INVALID_GAS_OVERRIDE();

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    function withdrawSync(bytes memory payload_) external payable;

    function depositSync(bytes memory payload_) external payable;

    /// @dev allows state registry contract to send payload for processing to the form contract.
    /// @param payload_ is the received information to be processed.
    // function stateSync(bytes memory payload_) external payable;
}
