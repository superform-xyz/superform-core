// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IFeeHelper} from "../../interfaces/IFeeHelper.sol";
import {ISuperRBAC} from "../../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IBridgeValidator} from "../../interfaces/IBridgeValidator.sol";
import {IBaseStateRegistry} from "../../interfaces/IBaseStateRegistry.sol";
import {IAmbImplementation} from "../../interfaces/IAmbImplementation.sol";
import {Error} from "../../utils/Error.sol";
import {DataLib} from "../../libraries/DataLib.sol";
import {ArrayCastLib} from "../../libraries/ArrayCastLib.sol";
import "../../types/DataTypes.sol";
import "../../types/LiquidityTypes.sol";

/// @title IPayloadHelper
/// @author ZeroPoint Labs
/// @dev helps estimating the cost for the entire transaction lifecycle
contract FeeHelper is IFeeHelper {
    using DataLib for uint256;
    using ArrayCastLib for LiqRequest;

    /*///////////////////////////////////////////////////////////////
                                DATA TYPES
    //////////////////////////////////////////////////////////////*/
    struct FeeConfig {
        address nativePriceFeed;
        uint64 swapGasUsed;
        uint64 updateGasUsed;
        uint64 depositGasUsed;
        uint64 superPositionGasUsed;
    }

    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 public constant TIMELOCK_FORM_ID = 1;

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev is the address of the superRegistry on the chain
    ISuperRegistry public immutable superRegistry;

    /// @dev is the configuration for each individual chain
    mapping(uint64 chainId => FeeConfig config) public feeConfig;

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
                        PREVILAGES ADMIN ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev admin intialize a new destination chain for estimation
    function setFeeConfig(
        uint64 chainId,
        address nativePriceFeed,
        uint64 swapGasUsed,
        uint64 updateGasUsed,
        uint64 depositGasUsed,
        uint64 superPositionGasUsed
    ) external onlyProtocolAdmin {
        feeConfig[chainId] = FeeConfig(
            nativePriceFeed,
            swapGasUsed,
            updateGasUsed,
            depositGasUsed,
            superPositionGasUsed
        );
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IFeeHelper
    function estimateMultiDstMultiVault(
        MultiDstMultiVaultsStateReq calldata req_,
        bool isDeposit
    ) external view override returns (uint256 totalFees) {
        for (uint256 i; i < req_.dstChainIds.length; ) {
            uint256 totalDstGas;
            /// @dev step 1: estimate amb costs

            /// @dev step 2: estimate if swap costs are involved
            totalDstGas += _estimateSwapFees(req_.dstChainIds[i], req_.superFormsData[i].liqRequests);

            /// @dev step 3: estimate update cost (only for deposit)
            if (isDeposit)
                totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], req_.superFormsData[i].superFormIds.length);

            /// @dev step 4: estimate execution costs in dst
            /// @dev step 5: estimation execution cost of acknowledgement

            /// @dev step 6: convert all dst gas estimates to src chain estimate

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IFeeHelper
    function estimateSingleDstMultiVault(
        SingleDstMultiVaultsStateReq memory req_,
        bool isDeposit
    ) external view override returns (uint256 totalFees) {
        uint256 totalDstGas;
        /// @dev step 1: estimate amb costs

        /// @dev step 2: estimate if swap costs are involved
        totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superFormsData.liqRequests);

        /// @dev step 3: estimate update cost (only for deposit)
        if (isDeposit) totalDstGas += _estimateUpdateCost(req_.dstChainId, req_.superFormsData.superFormIds.length);

        /// @dev step 4: estimate execution costs in dst
        /// @dev step 5: estimation execution cost of acknowledgement

        /// @dev step 6: convert all dst gas estimates to src chain estimate
    }

    /// @inheritdoc IFeeHelper
    function estimateMultiDstSingleVault(
        MultiDstSingleVaultStateReq calldata req_,
        bool isDeposit
    ) external view override returns (uint256 totalFees) {
        for (uint256 i; i < req_.dstChainIds.length; ) {
            uint256 totalDstGas;
            /// @dev step 1: estimate amb costs

            /// @dev step 2: estimate if swap costs are involved
            totalDstGas += _estimateSwapFees(req_.dstChainIds[i], req_.superFormsData[i].liqRequest.castToArray());

            /// @dev step 3: estimate update cost (only for deposit)
            if (isDeposit) totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], 1);

            /// @dev step 4: estimate execution costs in dst
            /// @dev step 5: estimation execution cost of acknowledgement

            /// @dev step 6: convert all dst gas estimates to src chain estimate
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IFeeHelper
    function estimateSingleXChainSingleVault(
        SingleXChainSingleVaultStateReq memory req_,
        bool isDeposit
    ) external view override returns (uint256 totalFees) {
        uint256 totalDstGas;
        /// @dev step 1: estimate amb costs

        /// @dev step 2: estimate if swap costs are involved
        totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superFormData.liqRequest.castToArray());

        /// @dev step 3: estimate update cost (only for deposit)
        if (isDeposit) totalDstGas += _estimateUpdateCost(req_.dstChainId, 1);

        /// @dev step 4: estimate execution costs in dst
        /// @dev step 5: estimation execution cost of acknowledgement

        /// @dev step 6: convert all dst gas estimates to src chain estimate
    }

    /// @inheritdoc IFeeHelper
    function estimateSingleDirectSingleVault(
        SingleDirectSingleVaultStateReq memory req_,
        bool isDeposit
    ) external view override returns (uint256 totalFees) {
        /// @dev only if timelock form is involved estimate the two step cost
        if (req_.superFormData.superFormId == TIMELOCK_FORM_ID) {}
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

    /*///////////////////////////////////////////////////////////////
                        INTERNAL/HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev helps estimate the dst chain swap fee for multi vault data
    function _estimateSwapFees(
        uint64 dstChainId_,
        LiqRequest[] memory liqReq_
    ) internal view returns (uint256 gasUsed) {
        FeeConfig memory config = feeConfig[dstChainId_];

        uint256 totalSwaps;

        for (uint256 i; i < liqReq_.length; ) {
            /// @dev checks if tx_data receiver is multiTxProcessor
            if (
                IBridgeValidator(superRegistry.getBridgeAddress(liqReq_[i].bridgeId)).decodeReceiver(
                    liqReq_[i].txData
                ) == superRegistry.multiTxProcessor()
            ) {
                ++totalSwaps;
            }

            unchecked {
                ++i;
            }
        }

        return totalSwaps * config.swapGasUsed;
    }

    /// @dev helps estimate the dst chain update payload fee
    function _estimateUpdateCost(uint64 dstChainId_, uint256 vaultsCount_) internal view returns (uint256 gasUsed) {
        FeeConfig memory config = feeConfig[dstChainId_];

        return vaultsCount_ * config.updateGasUsed;
    }
}
