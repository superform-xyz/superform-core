// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "../../vendor/chainlink/AggregatorV3Interface.sol";
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
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 public constant TIMELOCK_FORM_ID = 1;

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev is the address of the superRegistry on the chain
    ISuperRegistry public immutable superRegistry;

    /// @dev is the configuration for each individual chain

    /// same chain params
    AggregatorV3Interface public srcNativeFeedOracle;
    AggregatorV3Interface public srcGasPriceOracle;
    uint256 public ackNativeGasCost;

    /// xchain params
    mapping(uint64 chainId => AggregatorV3Interface) public dstNativeFeedOracle;
    mapping(uint64 chainId => AggregatorV3Interface) public dstGasPriceOracle;
    mapping(uint64 chainId => uint256 gasForSwap) public swapGasUsed;
    mapping(uint64 chainId => uint256 gasForUpdate) public updateGasUsed;
    mapping(uint64 chainId => uint256 gasForOps) public depositGasUsed;
    mapping(uint64 chainId => uint256 gasForOps) public withdrawGasUsed;

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
    ) external onlyProtocolAdmin {}

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
            /// note: only execution cost (not acknowledgement messaging cost)
            totalDstGas += _estimateDstExecutionCost(
                isDeposit,
                req_.dstChainIds[i],
                req_.superFormsData[i].superFormIds.length
            );

            /// @dev step 5: estimation processing cost of acknowledgement
            /// @notice optimistically estimating. (Ideal case scenario: no failed deposits / withdrawals)
            if (isDeposit)
                totalFees += _estimateAckProcessingCost(
                    req_.dstChainIds.length,
                    req_.superFormsData[i].superFormIds.length
                );

            /// @dev step 6: convert all dst gas estimates to src chain estimate
            totalFees += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);

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
        /// note: only execution cost (not acknowledgement messaging cost)
        totalDstGas += _estimateDstExecutionCost(isDeposit, req_.dstChainId, req_.superFormsData.superFormIds.length);

        /// @dev step 5: estimation execution cost of acknowledgement
        if (isDeposit) totalFees += _estimateAckProcessingCost(1, req_.superFormsData.superFormIds.length);

        /// @dev step 6: convert all dst gas estimates to src chain estimate
        totalFees += _convertToNativeFee(req_.dstChainId, totalDstGas);
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
            /// note: only execution cost (not acknowledgement messaging cost)
            totalDstGas += _estimateDstExecutionCost(isDeposit, req_.dstChainIds[i], 1);

            /// @dev step 5: estimation execution cost of acknowledgement
            if (isDeposit) totalFees += _estimateAckProcessingCost(req_.dstChainIds.length, 1);

            /// @dev step 6: convert all dst gas estimates to src chain estimate
            totalFees += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);

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
        /// note: only execution cost (not acknowledgement messaging cost)
        totalDstGas += _estimateDstExecutionCost(isDeposit, req_.dstChainId, 1);

        /// @dev step 5: estimation execution cost of acknowledgement
        if (isDeposit) totalFees += _estimateAckProcessingCost(1, 1);

        /// @dev step 6: convert all dst gas estimates to src chain estimate
        totalFees += _convertToNativeFee(req_.dstChainId, totalDstGas);
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

    /// @dev helps estimate the dst chain swap gas limit (if multi-tx is involved)
    function _estimateSwapFees(
        uint64 dstChainId_,
        LiqRequest[] memory liqReq_
    ) internal view returns (uint256 gasUsed) {
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

        return totalSwaps * swapGasUsed[dstChainId_];
    }

    /// @dev helps estimate the dst chain update payload gas limit
    function _estimateUpdateCost(uint64 dstChainId_, uint256 vaultsCount_) internal view returns (uint256 gasUsed) {
        return vaultsCount_ * updateGasUsed[dstChainId_];
    }

    /// @dev helps estimate the dst chain processing gas limit
    function _estimateDstExecutionCost(
        bool isDeposit_,
        uint64 dstChainId_,
        uint256 vaultsCount_
    ) internal view returns (uint256 gasUsed) {
        uint256 executionGasPerVault = isDeposit_ ? depositGasUsed[dstChainId_] : withdrawGasUsed[dstChainId_];

        return executionGasPerVault * vaultsCount_;
    }

    /// @dev helps estimate the src chain processing fee
    function _estimateAckProcessingCost(
        uint256 dstChainCount_,
        uint256 vaultsCount_
    ) internal view returns (uint256 nativeFee) {
        uint256 gasCost = dstChainCount_ * vaultsCount_ * ackNativeGasCost;
        (, int256 gasPrice, , , ) = srcGasPriceOracle.latestRoundData();

        return gasCost * uint256(gasPrice);
    }

    /// @dev helps convert the dst gas fee into src chain native fee
    /// note: check decimals (not validated yet)
    /// note: https://docs.soliditylang.org/en/v0.8.4/units-and-global-variables.html#ether-units
    /// all native tokens should be 18 decimals across all EVMs
    function _convertToNativeFee(uint64 dstChainId_, uint256 dstGas) internal view returns (uint256 nativeFee) {
        (, int256 gasPrice, , , ) = dstGasPriceOracle[dstChainId_].latestRoundData();

        /// @dev is the native dst chain gas used
        uint256 dstNativeFee = dstGas * uint256(gasPrice);

        (, int256 dstNativeTokenPrice, , , ) = dstNativeFeedOracle[dstChainId_].latestRoundData();

        /// @dev is the conversion of dst native tokens to usd equivalent (26 decimal)
        uint256 dstUsdValue = dstNativeFee * uint256(dstNativeTokenPrice);

        /// @dev is the final native tokens
        (, int256 srcNativeTokenPrice, , , ) = srcNativeFeedOracle.latestRoundData();

        nativeFee = (dstUsdValue / uint256(srcNativeTokenPrice));
    }
}
