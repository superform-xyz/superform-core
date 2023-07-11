// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {IFeeHelper} from "../../interfaces/IFeeHelper.sol";
import {AMBMessage, CallbackType, ReturnMultiData, ReturnSingleData, InitMultiVaultData, InitSingleVaultData} from "../../types/DataTypes.sol";
import {DataLib} from "../../libraries/DataLib.sol";

/// @title IPayloadHelper
/// @author ZeroPoint Labs
/// @dev helps estimating the cost for the entire transaction lifecycle
contract FeeHelper is IFeeHelper {
    using DataLib for uint256;

    ISuperRegistry public immutable superRegistry;

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /// @inheritdoc IFeeHelper
    function estimateFees(
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes[] memory extraData_
    ) external view returns (uint256 totalFees, uint256[] memory) {
        uint256 len = ambIds_.length;
        uint256[] memory fees = new uint256[](len);

        /// @dev just checks the estimate for sending message from src -> dst
        for (uint256 i; i < len; ) {
            fees[i] = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                dstChainId_,
                message_,
                extraData_[i]
            );

            totalFees += fees[i];

            unchecked {
                ++i;
            }
        }

        return (totalFees, fees);
    }
}
