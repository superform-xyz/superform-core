```
// SPDX-Lice
pragma solidity ^0.8.23;

import { Error } from "./Error.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { IDEXRouter } from "../interfaces/IDEXRouter.sol";

library PaymentHelper {
    uint256 public constant MAX_STALENESS = 3600; // 1 hour
    uint256 public constant MAX_PRICE_DEVIATION = 5; // 5% max deviation

    function estimateAckCost(
        uint256 payloadId,
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        IPriceOracle oracle = IPriceOracle(token);
        _checkOracleStaleness(oracle);

        uint256 oraclePrice = oracle.getPrice();
        uint256 dexPrice = _getDEXPrice(token, amount);

        require(
            _priceWithinBounds(oraclePrice, dexPrice),
            Error.PRICE_DEVIATION_TOO_HIGH
        );

        return _calculateCost(oraclePrice, amount);
    }

    function _checkOracleStaleness(IPriceOracle oracle) internal view {
        require(
            block.timestamp - oracle.lastUpdated() <= MAX_STALENESS,
            Error.ORACLE_STALE
        );
    }

    function _priceWithinBounds(uint256 oraclePrice, uint256 dexPrice)
        internal
        pure
        returns (bool)
    {
        uint256 lowerBound = oraclePrice * 95 / 100;
        uint256 upperBound = oraclePrice * 105 / 100;
        return (dexPrice >= lowerBound && dexPrice <= upperBound);
    }

    // ... остальные функции ...
}