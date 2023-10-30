// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { InitSingleVaultData, InitMultiVaultData } from "../types/DataTypes.sol";
import { LiqRequest } from "../types/LiquidityTypes.sol";

/// @dev library to cast single values into array for streamlining helper functions
/// @notice not gas optimized, suggested for usage only in view/pure functions
library ArrayCastLib {
    function castLiqRequestToArray(LiqRequest memory value_) internal pure returns (LiqRequest[] memory values) {
        values = new LiqRequest[](1);

        values[0] = value_;
    }

    function castBoolToArray(bool value_) internal pure returns (bool[] memory values) {
        values = new bool[](1);

        values[0] = value_;
    }

    function castToMultiVaultData(InitSingleVaultData memory data_)
        internal
        pure
        returns (InitMultiVaultData memory castedData_)
    {
        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = data_.superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = data_.amount;

        uint256[] memory maxSlippage = new uint256[](1);
        maxSlippage[0] = data_.maxSlippage;

        LiqRequest[] memory liqData = new LiqRequest[](1);
        liqData[0] = data_.liqData;

        castedData_ = InitMultiVaultData(
            data_.payloadId,
            superformIds,
            amounts,
            maxSlippage,
            new bool[](superformIds.length),
            new bool[](superformIds.length),
            liqData,
            data_.receiverAddress,
            data_.extraFormData
        );
    }
}
