```
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";
import { ICoreStateRegistry } from "src/interfaces/ICoreStateRegistry.sol";
import { IPriceOracle } from "src/interfaces/IPriceOracle.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { DataLib } from "src/libraries/DataLib.sol";

contract CoreStateRegistry is ICoreStateRegistry {
    using DataLib for bytes;

    // ... существующий код ...

    function _validateBridgePayload(
        address[] calldata bridgedTokens,
        uint256[] calldata amounts,
        uint256 payloadId
    ) internal {
        for (uint i = 0; i < bridgedTokens.length; i++) {
            IBridgeValidator validator = _getBridgeValidator(bridgedTokens[i]);
            bool isValid = validator.validatePayload(
                payloadId,
                bridgedTokens[i],
                amounts[i]
            );

            require(isValid, Error.INVALID_BRIDGE_VALIDATION);
        }
    }

    function _checkOracleStaleness(IPriceOracle oracle) internal view {
        uint256 lastUpdated = oracle.lastUpdated();
        require(
            block.timestamp - lastUpdated <= 3600, // 1 hour max staleness
            Error.ORACLE_STALE
        );
    }

    // ... остальной код контракта ...
}