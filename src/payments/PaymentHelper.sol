// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";
import { IPaymentHelper } from "../interfaces/IPaymentHelper.sol";
import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";
import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";
import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";
import { Error } from "../utils/Error.sol";
import { DataLib } from "../libraries/DataLib.sol";
import { ArrayCastLib } from "../libraries/ArrayCastLib.sol";
import "../types/DataTypes.sol";

import "../types/LiquidityTypes.sol";

/// @dev interface to read public variable from state registry
interface ReadOnlyBaseRegistry is IBaseStateRegistry {
    function payloadsCount() external view returns (uint256);
}

/// @title PaymentHelper
/// @author ZeroPoint Labs
/// @dev helps estimating the cost for the entire transaction lifecycle
contract PaymentHelper is IPaymentHelper {
    using DataLib for uint256;
    using ArrayCastLib for LiqRequest;

    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint32 public constant TIMELOCK_FORM_ID = 1;

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev is the address of the superRegistry on the chain
    ISuperRegistry public immutable superRegistry;

    /// @dev xchain params
    mapping(uint64 chainId => AggregatorV3Interface) public nativeFeedOracle;
    mapping(uint64 chainId => AggregatorV3Interface) public gasPriceOracle;
    mapping(uint64 chainId => uint256 gasForSwap) public swapGasUsed;
    mapping(uint64 chainId => uint256 gasForUpdate) public updateGasUsed;
    mapping(uint64 chainId => uint256 gasForOps) public depositGasUsed;
    mapping(uint64 chainId => uint256 gasForOps) public withdrawGasUsed;
    mapping(uint64 chainId => uint256 defaultNativePrice) public nativePrice;
    mapping(uint64 chainId => uint256 defaultGasPrice) public gasPrice;
    mapping(uint64 chainId => uint256 gasPerKB) public gasPerKB;
    mapping(uint64 chainId => uint256 gasForOps) public ackGasCost;
    mapping(uint64 chainId => uint256 gasForOps) public twoStepCost;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    modifier onlyEmergencyAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasEmergencyAdminRole(msg.sender)) {
            revert Error.NOT_EMERGENCY_ADMIN();
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

    /// @inheritdoc IPaymentHelper
    function addChain(
        uint64 chainId_,
        address nativeFeedOracle_,
        address gasPriceOracle_,
        uint256 swapGasUsed_,
        uint256 updateGasUsed_,
        uint256 depositGasUsed_,
        uint256 withdrawGasUsed_,
        uint256 defaultNativePrice_,
        uint256 defaultGasPrice_,
        uint256 gasPerKB_
    )
        external
        override
        onlyProtocolAdmin
    {
        if (nativeFeedOracle_ != address(0)) {
            nativeFeedOracle[chainId_] = AggregatorV3Interface(nativeFeedOracle_);
        }

        if (gasPriceOracle_ != address(0)) {
            gasPriceOracle[chainId_] = AggregatorV3Interface(gasPriceOracle_);
        }

        swapGasUsed[chainId_] = swapGasUsed_;
        updateGasUsed[chainId_] = updateGasUsed_;
        depositGasUsed[chainId_] = depositGasUsed_;
        withdrawGasUsed[chainId_] = withdrawGasUsed_;
        nativePrice[chainId_] = defaultNativePrice_;
        gasPrice[chainId_] = defaultGasPrice_;
        gasPerKB[chainId_] = gasPerKB_;
    }

    /// @inheritdoc IPaymentHelper
    function updateChainConfig(
        uint64 chainId_,
        uint256 configType_,
        bytes memory config_
    )
        external
        override
        onlyEmergencyAdmin
    {
        /// @dev Type 1: DST TOKEN PRICE FEED ORACLE
        if (configType_ == 1) {
            nativeFeedOracle[chainId_] = AggregatorV3Interface(abi.decode(config_, (address)));
        }

        /// @dev Type 2: DST GAS PRICE ORACLE
        if (configType_ == 2) {
            gasPriceOracle[chainId_] = AggregatorV3Interface(abi.decode(config_, (address)));
        }

        /// @dev Type 3: SWAP GAS COST PER TX FOR MULTI-TX
        if (configType_ == 3) {
            swapGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 4: PAYLOAD UPDATE GAS COST PER TX FOR DEPOSIT
        if (configType_ == 4) {
            updateGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 5: DEPOSIT GAS COST PER TX
        if (configType_ == 5) {
            depositGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 6: WITHDRAW GAS COST PER TX
        if (configType_ == 6) {
            withdrawGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 7: NATIVE PRICE
        if (configType_ == 7) {
            nativePrice[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 8: GAS PRICE
        if (configType_ == 8) {
            gasPrice[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 9: GAS PRICE PER KB of Message
        if (configType_ == 9) {
            gasPerKB[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 10: ACK GAS COST
        if (configType_ == 10) {
            ackGasCost[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 11: TWO STEP PROCESSING COST
        if (configType_ == 11) {
            twoStepCost[chainId_] = abi.decode(config_, (uint256));
        }

        emit ChainConfigUpdated(chainId_, configType_, config_);
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPaymentHelper
    function calculateAMBData(
        uint64 dstChainId_,
        uint8[] calldata ambIds_,
        bytes memory message_
    )
        external
        view
        override
        returns (uint256 totalFees, bytes memory extraData)
    {
        (uint256[] memory gasPerAMB, bytes[] memory extraDataPerAMB, uint256 fees) =
            _estimateAMBFeesReturnExtraData(dstChainId_, ambIds_, message_);

        extraData = abi.encode(AMBExtraData(gasPerAMB, extraDataPerAMB));
        totalFees = fees;
    }

    /// @inheritdoc IPaymentHelper
    function estimateMultiDstMultiVault(
        MultiDstMultiVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 dstNativeFeeExplicit;

        for (uint256 i; i < req_.dstChainIds.length;) {
            uint256 totalDstGas;

            /// @dev step 1: estimate amb costs
            (, uint256 ambFees) = _estimateAMBFees(
                req_.ambIds[i], req_.dstChainIds[i], _generateMultiVaultMessage(req_.superformsData[i])
            );

            srcAmount += ambFees;

            if (isDeposit) {
                /// @dev step 2: estimate if swap costs are involved
                totalDstGas += _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].liqRequests);

                /// @dev step 3: estimate update cost (only for deposit)
                totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], req_.superformsData[i].superformIds.length);

                /// @dev step 4: estimation processing cost of acknowledgement
                /// @notice optimistically estimating. (Ideal case scenario: no failed deposits / withdrawals)
                srcAmount +=
                    _estimateAckProcessingCost(req_.dstChainIds.length, req_.superformsData[i].superformIds.length);

                /// @dev step 5: estimate liq amount
                liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequests);
            }

            /// @dev step 6: estimate execution costs in dst (withdraw / deposit)
            /// note: execution cost includes acknowledgement messaging cost
            totalDstGas +=
                _estimateDstExecutionCost(isDeposit, req_.dstChainIds[i], req_.superformsData[i].superformIds.length);

            /// @dev step 7: convert all dst gas estimates to src chain estimate  (withdraw / deposit)
            dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);

            unchecked {
                ++i;
            }
        }

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateMultiDstSingleVault(
        MultiDstSingleVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        for (uint256 i; i < req_.dstChainIds.length;) {
            uint256 totalDstGas;

            /// @dev step 1: estimate amb costs
            (, uint256 ambFees) = _estimateAMBFees(
                req_.ambIds[i], req_.dstChainIds[i], _generateSingleVaultMessage(req_.superformsData[i])
            );

            srcAmount += ambFees;

            if (isDeposit) {
                /// @dev step 2: estimate if swap costs are involved
                totalDstGas += _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].liqRequest.castToArray());

                /// @dev step 3: estimate update cost (only for deposit)
                totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], 1);

                /// @dev step 4: estimation execution cost of acknowledgement
                srcAmount += _estimateAckProcessingCost(req_.dstChainIds.length, 1);

                /// @dev step 5: estimate the liqAmount
                liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequest.castToArray());
            }

            /// @dev step 6: estimate execution costs in dst
            /// note: execution cost includes acknowledgement messaging cost
            totalDstGas += _estimateDstExecutionCost(isDeposit, req_.dstChainIds[i], 1);

            /// @dev step 7: convert all dst gas estimates to src chain estimate
            dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);

            unchecked {
                ++i;
            }
        }

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleXChainMultiVault(
        SingleXChainMultiVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 totalDstGas;

        /// @dev step 1: estimate amb costs
        (, uint256 ambFees) =
            _estimateAMBFees(req_.ambIds, req_.dstChainId, _generateMultiVaultMessage(req_.superformsData));

        srcAmount += ambFees;

        /// @dev step 2: estimate if swap costs are involved
        if (isDeposit) totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superformsData.liqRequests);

        /// @dev step 3: estimate update cost (only for deposit)
        if (isDeposit) totalDstGas += _estimateUpdateCost(req_.dstChainId, req_.superformsData.superformIds.length);

        /// @dev step 4: estimate execution costs in dst
        /// note: execution cost includes acknowledgement messaging cost
        totalDstGas += _estimateDstExecutionCost(isDeposit, req_.dstChainId, req_.superformsData.superformIds.length);

        /// @dev step 5: estimation execution cost of acknowledgement
        if (isDeposit) srcAmount += _estimateAckProcessingCost(1, req_.superformsData.superformIds.length);

        /// @dev step 6: estimate liq amount
        if (isDeposit) liqAmount += _estimateLiqAmount(req_.superformsData.liqRequests);

        /// @dev step 7: convert all dst gas estimates to src chain estimate
        dstAmount += _convertToNativeFee(req_.dstChainId, totalDstGas);

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleXChainSingleVault(
        SingleXChainSingleVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 totalDstGas;
        /// @dev step 1: estimate amb costs
        (, uint256 ambFees) =
            _estimateAMBFees(req_.ambIds, req_.dstChainId, _generateSingleVaultMessage(req_.superformData));

        srcAmount += ambFees;

        /// @dev step 2: estimate if swap costs are involved
        if (isDeposit) totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superformData.liqRequest.castToArray());

        /// @dev step 3: estimate update cost (only for deposit)
        if (isDeposit) totalDstGas += _estimateUpdateCost(req_.dstChainId, 1);

        /// @dev step 4: estimate execution costs in dst
        /// note: execution cost includes acknowledgement messaging cost
        totalDstGas += _estimateDstExecutionCost(isDeposit, req_.dstChainId, 1);

        /// @dev step 5: estimation execution cost of acknowledgement
        if (isDeposit) srcAmount += _estimateAckProcessingCost(1, 1);

        /// @dev step 6: estimate the liq amount
        if (isDeposit) liqAmount += _estimateLiqAmount(req_.superformData.liqRequest.castToArray());

        /// @dev step 7: convert all dst gas estimates to src chain estimate
        dstAmount += _convertToNativeFee(req_.dstChainId, totalDstGas);

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleDirectSingleVault(
        SingleDirectSingleVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        (, uint32 formId,) = req_.superformData.superformId.getSuperform();
        /// @dev only if timelock form withdrawal is involved
        if (!isDeposit && formId == TIMELOCK_FORM_ID) {
            srcAmount += twoStepCost[superRegistry.chainId()] * _getGasPrice(superRegistry.chainId());
        }

        if (isDeposit) liqAmount += _estimateLiqAmount(req_.superformData.liqRequest.castToArray());

        /// @dev not adding dstAmount to save some GAS
        totalAmount = liqAmount + srcAmount;

        dstAmount = 0;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleDirectMultiVault(
        SingleDirectMultiVaultStateReq calldata req_,
        bool isDeposit
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        for (uint256 i; i < req_.superformData.superformIds.length;) {
            (, uint32 formId,) = req_.superformData.superformIds[i].getSuperform();
            /// @dev only if timelock form withdrawal is involved
            if (!isDeposit && formId == TIMELOCK_FORM_ID) {
                srcAmount += twoStepCost[superRegistry.chainId()] * _getGasPrice(superRegistry.chainId());
            }

            unchecked {
                ++i;
            }
        }

        if (isDeposit) liqAmount += _estimateLiqAmount(req_.superformData.liqRequests);

        /// @dev not adding dstAmount to save some GAS
        totalAmount = liqAmount + srcAmount;

        dstAmount = 0;
    }

    /// @inheritdoc IPaymentHelper
    function estimateAMBFees(
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes[] memory extraData_
    )
        public
        view
        returns (uint256 totalFees, uint256[] memory)
    {
        uint256 len = ambIds_.length;
        uint256[] memory fees = new uint256[](len);

        /// @dev just checks the estimate for sending message from src -> dst
        for (uint256 i; i < len;) {
            fees[i] = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                dstChainId_, message_, extraData_[i]
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

    /// @dev helps generate extra data per amb
    function _generateExtraData(
        uint64 dstChainId_,
        uint8[] calldata ambIds_,
        bytes memory message_
    )
        public
        view
        returns (bytes[] memory extraDataPerAMB)
    {
        uint256 len = ambIds_.length;
        uint256 totalDstGasReqInWei = message_.length * gasPerKB[dstChainId_];

        extraDataPerAMB = new bytes[](len);

        for (uint256 i; i < len;) {
            if (ambIds_[i] == 1) {
                extraDataPerAMB[i] = abi.encodePacked(uint16(2), totalDstGasReqInWei, uint256(0), address(0));
            }

            if (ambIds_[i] == 2) {
                extraDataPerAMB[i] = abi.encode(totalDstGasReqInWei);
            }

            if (ambIds_[i] == 4) {
                extraDataPerAMB[i] = abi.encode(0, totalDstGasReqInWei);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @dev helps estimate the cross-chain message costs
    function _estimateAMBFees(
        uint8[] calldata ambIds_,
        uint64 dstChainId_,
        bytes memory message_
    )
        public
        view
        returns (uint256[] memory feeSplitUp, uint256 totalFees)
    {
        uint256 len = ambIds_.length;

        bytes[] memory extraDataPerAMB = _generateExtraData(dstChainId_, ambIds_, message_);

        feeSplitUp = new uint256[](len);

        /// @dev just checks the estimate for sending message from src -> dst
        for (uint256 i; i < len;) {
            uint256 tempFee = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                dstChainId_, message_, extraDataPerAMB[i]
            );

            totalFees += tempFee;
            feeSplitUp[i] = tempFee;

            unchecked {
                ++i;
            }
        }
    }

    /// @dev helps estimate the cross-chain message costs
    function _estimateAMBFeesReturnExtraData(
        uint64 dstChainId_,
        uint8[] calldata ambIds_,
        bytes memory message_
    )
        public
        view
        returns (uint256[] memory feeSplitUp, bytes[] memory extraDataPerAMB, uint256 totalFees)
    {
        uint256 len = ambIds_.length;

        extraDataPerAMB = _generateExtraData(dstChainId_, ambIds_, message_);

        feeSplitUp = new uint256[](len);

        /// @dev just checks the estimate for sending message from src -> dst
        for (uint256 i; i < len;) {
            uint256 tempFee = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                dstChainId_, message_, extraDataPerAMB[i]
            );

            totalFees += tempFee;
            feeSplitUp[i] = tempFee;

            unchecked {
                ++i;
            }
        }
    }

    /// @dev helps estimate the dst chain swap gas limit (if multi-tx is involved)
    function _estimateSwapFees(
        uint64 dstChainId_,
        LiqRequest[] memory liqReq_
    )
        internal
        view
        returns (uint256 gasUsed)
    {
        uint256 totalSwaps;

        for (uint256 i; i < liqReq_.length;) {
            /// @dev checks if tx_data receiver is multiTxProcessor
            if (
                liqReq_[i].bridgeId != 0
                    && IBridgeValidator(superRegistry.getBridgeValidator(liqReq_[i].bridgeId)).validateReceiver(
                        liqReq_[i].txData, superRegistry.getAddress(keccak256("MULTI_TX_PROCESSOR"))
                    )
            ) {
                ++totalSwaps;
            }

            unchecked {
                ++i;
            }
        }

        if (totalSwaps == 0) {
            return 0;
        }

        return totalSwaps * swapGasUsed[dstChainId_];
    }

    /// @dev helps estimate the liq amount involved in the tx
    function _estimateLiqAmount(LiqRequest[] memory req_) internal view returns (uint256 liqAmount) {
        for (uint256 i; i < req_.length;) {
            if (req_[i].token == NATIVE) {
                liqAmount +=
                    IBridgeValidator(superRegistry.getBridgeValidator(req_[i].bridgeId)).decodeAmount(req_[i].txData);
            }

            unchecked {
                ++i;
            }
        }
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
    )
        internal
        view
        returns (uint256 gasUsed)
    {
        uint256 executionGasPerVault = isDeposit_ ? depositGasUsed[dstChainId_] : withdrawGasUsed[dstChainId_];

        return executionGasPerVault * vaultsCount_;
    }

    /// @dev helps estimate the src chain processing fee
    function _estimateAckProcessingCost(
        uint256 dstChainCount_,
        uint256 vaultsCount_
    )
        internal
        view
        returns (uint256 nativeFee)
    {
        uint256 gasCost = dstChainCount_ * vaultsCount_ * ackGasCost[superRegistry.chainId()];

        return gasCost * _getGasPrice(superRegistry.chainId());
    }

    /// @dev generates the amb message for single vault data
    function _generateSingleVaultMessage(SingleVaultSFData memory sfData_)
        internal
        view
        returns (bytes memory message_)
    {
        bytes memory ambData = abi.encode(
            InitSingleVaultData(
                1,
                /// @dev sample router id for estimation
                _getNextPayloadId(),
                sfData_.superformId,
                sfData_.amount,
                sfData_.maxSlippage,
                sfData_.liqRequest,
                sfData_.extraFormData
            )
        );
        message_ = abi.encode(AMBMessage(2 * 256 - 1, ambData));
    }

    /// @dev generates the amb message for multi vault data
    function _generateMultiVaultMessage(MultiVaultSFData memory sfData_)
        internal
        view
        returns (bytes memory message_)
    {
        bytes memory ambData = abi.encode(
            InitMultiVaultData(
                1,
                /// @dev sample router id for estimation
                _getNextPayloadId(),
                sfData_.superformIds,
                sfData_.amounts,
                sfData_.maxSlippages,
                sfData_.liqRequests,
                sfData_.extraFormData
            )
        );
        message_ = abi.encode(AMBMessage(2 * 256 - 1, ambData));
    }

    /// @dev helps convert the dst gas fee into src chain native fee
    /// @dev https://docs.soliditylang.org/en/v0.8.4/units-and-global-variables.html#ether-units
    /// @dev all native tokens should be 18 decimals across all EVMs
    function _convertToNativeFee(uint64 dstChainId_, uint256 dstGas) internal view returns (uint256 nativeFee) {
        /// @dev gas fee * gas price (to get the gas amounts in dst chain's native token)
        /// @dev gas price is 9 decimal (in gwei)
        /// @dev assumption: all evm native tokens are 18 decimals
        uint256 dstNativeFee = dstGas * _getGasPrice(dstChainId_);

        if (dstNativeFee == 0) {
            return 0;
        }

        /// @dev converts the gas to pay in terms of native token to usd value
        /// @dev native token price is 8 decimal
        uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

        if (dstUsdValue == 0) {
            return 0;
        }

        /// @dev converts the usd value to source chain's native token
        /// @dev native token price is 8 decimal which cancels the 8 decimal multiplied in previous step
        nativeFee = (dstUsdValue) / _getNativeTokenPrice(superRegistry.chainId());
    }

    /// @dev helps generate the new payload id
    /// @dev next payload id = current payload id + 1
    function _getNextPayloadId() internal view returns (uint256 nextPayloadId) {
        nextPayloadId = ReadOnlyBaseRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY"))).payloadsCount();
        ++nextPayloadId;
    }

    /// @dev helps return the current gas price of different networks
    /// @dev returns default set values if an oracle is not configured for the network
    function _getGasPrice(uint64 chainId_) internal view returns (uint256) {
        if (address(gasPriceOracle[chainId_]) != address(0)) {
            (, int256 value,,,) = gasPriceOracle[chainId_].latestRoundData();
            return uint256(value);
        }

        return gasPrice[chainId_];
    }

    /// @dev helps return the dst chain token price of different networks
    /// @dev returns `0` - if no oracle is set
    function _getNativeTokenPrice(uint64 chainId_) internal view returns (uint256) {
        if (address(nativeFeedOracle[chainId_]) != address(0)) {
            (, int256 dstTokenPrice,,,) = nativeFeedOracle[chainId_].latestRoundData();
            return uint256(dstTokenPrice);
        }

        return nativePrice[chainId_];
    }
}
