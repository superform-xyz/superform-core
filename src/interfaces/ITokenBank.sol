// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {LiqRequest} from "../types/LiquidityTypes.sol";
import {IERC4626} from "../interfaces/IERC4626.sol";

interface ITokenBank {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev error thrown when the bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    function withdrawSync(
        bytes memory payload_
    ) external payable;

    function depositSync(
        bytes memory payload_
    ) external payable;

    /// @dev allows state registry contract to send payload for processing to the form contract.
    /// @param payload_ is the received information to be processed.
    // function stateSync(bytes memory payload_) external payable;
}
