// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IFeeHelper} from "../../interfaces/IFeeHelper.sol";
import {ISuperRBAC} from "../../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {Error} from "../../utils/Error.sol";
import {DataLib} from "../../libraries/DataLib.sol";
import "../../types/DataTypes.sol";

/// @title IPayloadHelper
/// @author ZeroPoint Labs
/// @dev helps estimating the cost for the entire transaction lifecycle
contract FeeHelper is IFeeHelper {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev is the address of the superRegistry on the chain
    ISuperRegistry public immutable superRegistry;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IFeeHelper
    function estimateMultiDstMultiVault(
        MultiDstMultiVaultsStateReq calldata req_
    ) external view override returns (uint256 totalFees) {}

    /// @inheritdoc IFeeHelper
    function estimateSingleDstMultiVault(
        SingleDstMultiVaultsStateReq memory req_
    ) external view override returns (uint256 totalFees) {
        /// @dev step 1: estimate amb costs
        /// @dev step 2: estimate if swap costs are involved
        /// @dev step 3: estimate update cost (only for deposit)
        /// @dev step 4: estimate execution costs in dst
        /// @dev step 5: estimation execution cost of acknowledgement
    }

    /// @inheritdoc IFeeHelper
    function estimateMultiDstSingleVault(
        MultiDstSingleVaultStateReq calldata req_
    ) external view override returns (uint256 totalFees) {}

    /// @inheritdoc IFeeHelper
    function estimateSingleXChainSingleVault(
        SingleXChainSingleVaultStateReq memory req_
    ) external view override returns (uint256 totalFees) {}

    /// @inheritdoc IFeeHelper
    function estimateSingleDirectSingleVault(
        SingleDirectSingleVaultStateReq memory req_
    ) external view override returns (uint256 totalFees) {
        /// @dev only if timelock form is involved estimate the two step cost
    }

    /// @inheritdoc IFeeHelper
    /// @dev OUTDATED!! might change and use for just amb gas estimation
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
