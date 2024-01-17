// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IPaymentHelper } from "src/interfaces/IPaymentHelper.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";
import { Error } from "src/libraries/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { ArrayCastLib } from "src/libraries/ArrayCastLib.sol";
import {
    SingleDirectSingleVaultStateReq,
    SingleXChainSingleVaultStateReq,
    SingleDirectMultiVaultStateReq,
    SingleXChainMultiVaultStateReq,
    MultiDstSingleVaultStateReq,
    MultiDstMultiVaultStateReq,
    LiqRequest,
    AMBMessage,
    MultiVaultSFData,
    SingleVaultSFData,
    AMBExtraData,
    InitMultiVaultData,
    InitSingleVaultData,
    ReturnMultiData,
    ReturnSingleData
} from "src/types/DataTypes.sol";
import { AggregatorV3Interface } from "src/vendor/chainlink/AggregatorV3Interface.sol";

/// @dev interface to read public variable from state registry
interface ReadOnlyBaseRegistry is IBaseStateRegistry {
    function payloadsCount() external view returns (uint256);
}

/// @title PaymentHelper
/// @dev Helps estimate the cost for the entire transaction lifecycle
/// @author ZeroPoint Labs
contract PaymentHelper is IPaymentHelper {
    using DataLib for uint256;
    using ArrayCastLib for LiqRequest;
    using ArrayCastLib for bool;
    using ProofLib for bytes;
    using ProofLib for AMBMessage;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    uint256 private constant PROOF_LENGTH = 160;
    uint8 private constant SUPPORTED_FEED_PRECISION = 8;
    uint32 private constant TIMELOCK_FORM_ID = 2;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev xchain params
    mapping(uint64 chainId => AggregatorV3Interface) public nativeFeedOracle;
    mapping(uint64 chainId => AggregatorV3Interface) public gasPriceOracle;
    mapping(uint64 chainId => uint256 gasForSwap) public swapGasUsed;
    mapping(uint64 chainId => uint256 gasForUpdate) public updateGasUsed;
    mapping(uint64 chainId => uint256 gasForDeposit) public depositGasUsed;
    mapping(uint64 chainId => uint256 gasForWithdraw) public withdrawGasUsed;
    mapping(uint64 chainId => uint256 defaultNativePrice) public nativePrice;
    mapping(uint64 chainId => uint256 defaultGasPrice) public gasPrice;
    mapping(uint64 chainId => uint256 gasPerByte) public gasPerByte;
    mapping(uint64 chainId => uint256 gasForAck) public ackGasCost;
    mapping(uint64 chainId => uint256 gasForTimelock) public timelockCost;
    mapping(uint64 chainId => uint256 gasForEmergency) public emergencyCost;

    /// @dev register transmuter params
    bytes public extraDataForTransmuter;

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

    struct EstimateAckCostVars {
        uint256 currPayloadId;
        uint256 payloadHeader;
        uint8 callbackType;
        bytes payloadBody;
        uint8[] ackAmbIds;
        uint8 isMulti;
        uint64 srcChainId;
        bytes message;
    }

    struct LocalEstimateVars {
        uint256 len;
        uint256 superformIdsLen;
        uint256 totalDstGas;
        uint256 ambFees;
        bool paused;
    }

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

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

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) {
        if (superRegistry_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);
        superRegistry = ISuperRegistry(superRegistry_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

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
    function getRegisterTransmuterAMBData() external view override returns (bytes memory) {
        return extraDataForTransmuter;
    }

    /// @inheritdoc IPaymentHelper
    function estimateMultiDstMultiVault(
        MultiDstMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        LocalEstimateVars memory v;
        v.len = req_.dstChainIds.length;

        ISuperformFactory factory = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")));
        for (uint256 i; i < v.len; ++i) {
            bool xChain = req_.dstChainIds[i] != CHAIN_ID;

            v.totalDstGas = 0;

            /// @dev step 1: estimate amb costs
            v.ambFees = xChain
                ? _estimateAMBFees(req_.ambIds[i], req_.dstChainIds[i], _generateMultiVaultMessage(req_.superformsData[i]))
                : 0;

            v.superformIdsLen = req_.superformsData[i].superformIds.length;

            srcAmount += v.ambFees;

            if (isDeposit_) {
                /// @dev step 2: estimate liq amount
                liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequests);

                if (xChain) {
                    /// @dev step 3: estimate update cost (only for deposit)
                    v.totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], v.superformIdsLen);

                    uint256 ackLen;
                    for (uint256 j; j < v.superformIdsLen; ++j) {
                        if (!req_.superformsData[i].retain4626s[j]) ++ackLen;
                    }
                    /// @dev step 4: estimation processing cost of acknowledgement on source
                    srcAmount += _estimateAckProcessingCost(v.superformIdsLen);

                    /// @dev step 5: estimate dst swap cost if it exists
                    v.totalDstGas += _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].hasDstSwaps);
                }
            } else {
                /// @dev step 6: estimate if timelock form processing costs are involved
                for (uint256 j; j < v.superformIdsLen; ++j) {
                    (, uint32 formId,) = req_.superformsData[i].superformIds[j].getSuperform();
                    v.paused = factory.isFormImplementationPaused(formId);

                    if (!v.paused && formId == TIMELOCK_FORM_ID) {
                        v.totalDstGas += timelockCost[req_.dstChainIds[i]];
                    } else if (v.paused) {
                        v.totalDstGas += emergencyCost[req_.dstChainIds[i]];
                    }
                }
            }

            /// @dev step 7: estimate execution costs in destination including sending acknowledgement to source
            /// @dev ensure that acknowledgement costs from dst to src are not double counted
            bool hasRetain4626;
            for (uint256 j; j < v.superformIdsLen; ++j) {
                if (!req_.superformsData[i].retain4626s[j]) {
                    hasRetain4626 = true;
                    break;
                }
            }
            if (hasRetain4626 && xChain) {
                v.totalDstGas += _estimateDstExecutionCost(isDeposit_, false, req_.dstChainIds[i], v.superformIdsLen);
            } else {
                v.totalDstGas +=
                    xChain ? _estimateDstExecutionCost(isDeposit_, true, req_.dstChainIds[i], v.superformIdsLen) : 0;
            }

            /// @dev step 8: convert all dst gas estimates to src chain estimate  (withdraw / deposit)
            dstAmount += _convertToNativeFee(req_.dstChainIds[i], v.totalDstGas);
        }

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateMultiDstSingleVault(
        MultiDstSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 len = req_.dstChainIds.length;
        ISuperformFactory factory = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")));

        for (uint256 i; i < len; ++i) {
            bool xChain = req_.dstChainIds[i] != CHAIN_ID;
            uint256 totalDstGas;

            /// @dev step 1: estimate amb costs
            uint256 ambFees = xChain
                ? _estimateAMBFees(req_.ambIds[i], req_.dstChainIds[i], _generateSingleVaultMessage(req_.superformsData[i]))
                : 0;

            srcAmount += ambFees;

            if (isDeposit_) {
                /// @dev step 2: estimate the liqAmount
                liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequest.castLiqRequestToArray());

                if (xChain) {
                    /// @dev step 3: estimate update cost (only for deposit)
                    totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], 1);

                    /// @dev step 4: estimation execution cost of acknowledgement on source
                    if (!req_.superformsData[i].retain4626) {
                        srcAmount += _estimateAckProcessingCost(1);
                    }

                    /// @dev step 5: estimate if swap costs are involved
                    totalDstGas +=
                        _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].hasDstSwap.castBoolToArray());
                }
            } else {
                /// @dev step 6: estimate if timelock form processing costs are involved
                (, uint32 formId,) = req_.superformsData[i].superformId.getSuperform();

                bool paused = factory.isFormImplementationPaused(formId);

                if (!paused && formId == TIMELOCK_FORM_ID) {
                    totalDstGas += timelockCost[req_.dstChainIds[i]];
                } else if (paused) {
                    totalDstGas += emergencyCost[req_.dstChainIds[i]];
                }
            }

            /// @dev step 7: estimate execution costs in destination including sending acknowledgement to source
            totalDstGas += xChain
                ? _estimateDstExecutionCost(isDeposit_, req_.superformsData[i].retain4626, req_.dstChainIds[i], 1)
                : 0;

            /// @dev step 8: convert all dst gas estimates to src chain estimate
            dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);
        }

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleXChainMultiVault(
        SingleXChainMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 totalDstGas;
        uint256 superformIdsLen = req_.superformsData.superformIds.length;

        ISuperformFactory factory = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")));

        /// @dev step 1: estimate AMB costs
        uint256 ambFees =
            _estimateAMBFees(req_.ambIds, req_.dstChainId, _generateMultiVaultMessage(req_.superformsData));
        srcAmount += ambFees;

        if (isDeposit_) {
            /// @dev step 2: estimate the liqAmount
            liqAmount += _estimateLiqAmount(req_.superformsData.liqRequests);

            /// @dev step 3: estimate update cost (only for deposit)
            totalDstGas += _estimateUpdateCost(req_.dstChainId, superformIdsLen);

            uint256 ackLen;
            for (uint256 i; i < superformIdsLen; ++i) {
                if (!req_.superformsData.retain4626s[i]) ++ackLen;
            }

            /// @dev step 4: estimation execution cost of acknowledgement on source
            srcAmount += _estimateAckProcessingCost(ackLen);

            /// @dev step 5: estimate if swap costs are involved
            totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superformsData.hasDstSwaps);
        } else {
            /// @dev step 6: process non-deposit logic for timelock form processing costs
            for (uint256 i; i < superformIdsLen; ++i) {
                (, uint32 formId,) = req_.superformsData.superformIds[i].getSuperform();

                bool paused = factory.isFormImplementationPaused(formId);

                if (!paused && formId == TIMELOCK_FORM_ID) {
                    totalDstGas += timelockCost[req_.dstChainId];
                } else if (paused) {
                    totalDstGas += emergencyCost[req_.dstChainId];
                }
            }
        }

        /// @dev step 7: estimate execution costs in destination including sending acknowledgement to source
        /// @dev ensure that acknowledgement costs from dst to src are not double counted
        bool hasRetain4626;
        for (uint256 i; i < superformIdsLen; ++i) {
            if (!req_.superformsData.retain4626s[i]) {
                hasRetain4626 = true;
                break;
            }
        }
        if (hasRetain4626) {
            totalDstGas += _estimateDstExecutionCost(isDeposit_, false, req_.dstChainId, superformIdsLen);
        } else {
            totalDstGas += _estimateDstExecutionCost(isDeposit_, true, req_.dstChainId, superformIdsLen);
        }

        /// @dev step 8: convert all destination gas estimates to source chain estimate
        dstAmount += _convertToNativeFee(req_.dstChainId, totalDstGas);

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleXChainSingleVault(
        SingleXChainSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 totalDstGas;
        ISuperformFactory factory = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")));

        /// @dev step 1: estimate AMB costs
        uint256 ambFees =
            _estimateAMBFees(req_.ambIds, req_.dstChainId, _generateSingleVaultMessage(req_.superformData));
        srcAmount += ambFees;

        if (isDeposit_) {
            /// @dev step 2: estimate the liqAmount
            liqAmount += _estimateLiqAmount(req_.superformData.liqRequest.castLiqRequestToArray());

            /// @dev step 3: estimate update cost (only for deposit)
            totalDstGas += _estimateUpdateCost(req_.dstChainId, 1);

            /// @dev step 4: estimation execution cost of acknowledgement on source
            if (!req_.superformData.retain4626) {
                srcAmount += _estimateAckProcessingCost(1);
            }

            /// @dev step 5: estimate if swap costs are involved
            totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superformData.hasDstSwap.castBoolToArray());
        } else {
            /// @dev step 6: process non-deposit logic for timelock form processing costs
            (, uint32 formId,) = req_.superformData.superformId.getSuperform();

            bool paused = factory.isFormImplementationPaused(formId);

            if (!paused && formId == TIMELOCK_FORM_ID) {
                totalDstGas += timelockCost[req_.dstChainId];
            } else if (paused) {
                totalDstGas += emergencyCost[req_.dstChainId];
            }
        }

        /// @dev step 7: estimate execution costs in destination including sending acknowledgement to source
        totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.superformData.retain4626, req_.dstChainId, 1);

        /// @dev step 8: convert all destination gas estimates to source chain estimate
        dstAmount += _convertToNativeFee(req_.dstChainId, totalDstGas);

        totalAmount = srcAmount + dstAmount + liqAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleDirectSingleVault(
        SingleDirectSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 totalAmount)
    {
        ISuperformFactory factory = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")));

        if (!isDeposit_) {
            /// @dev only if timelock form withdrawal is involved
            (, uint32 formId,) = req_.superformData.superformId.getSuperform();

            bool paused = factory.isFormImplementationPaused(formId);

            if (!paused && formId == TIMELOCK_FORM_ID) {
                srcAmount += timelockCost[CHAIN_ID] * _getGasPrice(CHAIN_ID);
            } else if (paused) {
                srcAmount += emergencyCost[CHAIN_ID] * _getGasPrice(CHAIN_ID);
            }
        } else {
            liqAmount = _estimateLiqAmount(req_.superformData.liqRequest.castLiqRequestToArray());
        }

        /// @dev not adding dstAmount to save some GAS
        totalAmount = liqAmount + srcAmount;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleDirectMultiVault(
        SingleDirectMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 totalAmount)
    {
        ISuperformFactory factory = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")));

        if (!isDeposit_) {
            uint256 len = req_.superformData.superformIds.length;
            uint256 timelockPrice = timelockCost[CHAIN_ID] * _getGasPrice(CHAIN_ID);
            uint256 emergencyPrice = emergencyCost[CHAIN_ID] * _getGasPrice(CHAIN_ID);
            for (uint256 i; i < len; ++i) {
                (, uint32 formId,) = req_.superformData.superformIds[i].getSuperform();
                bool paused = factory.isFormImplementationPaused(formId);

                if (!paused && formId == TIMELOCK_FORM_ID) {
                    srcAmount += timelockPrice;
                } else if (paused) {
                    srcAmount += emergencyPrice;
                }
            }
        } else {
            liqAmount += _estimateLiqAmount(req_.superformData.liqRequests);
        }

        /// @dev not adding dstAmount to save some GAS
        totalAmount = liqAmount + srcAmount;
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
        if (CHAIN_ID != dstChainId_) {
            for (uint256 i; i < len; ++i) {
                fees[i] = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                    dstChainId_, message_, extraData_[i]
                );

                totalFees += fees[i];
            }
        }

        return (totalFees, fees);
    }

    /// @dev helps estimate the acknowledgement costs for amb processing
    function estimateAckCost(uint256 payloadId_) external view returns (uint256 totalFees) {
        EstimateAckCostVars memory v;
        IBaseStateRegistry coreStateRegistry =
            IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY")));
        v.currPayloadId = coreStateRegistry.payloadsCount();

        if (payloadId_ > v.currPayloadId) revert Error.INVALID_PAYLOAD_ID();

        v.payloadHeader = coreStateRegistry.payloadHeader(payloadId_);
        v.payloadBody = coreStateRegistry.payloadBody(payloadId_);

        (, v.callbackType, v.isMulti,,, v.srcChainId) = DataLib.decodeTxInfo(v.payloadHeader);

        /// if callback type is return then return 0
        if (v.callbackType != 0) return 0;

        if (v.isMulti == 1) {
            InitMultiVaultData memory data = abi.decode(v.payloadBody, (InitMultiVaultData));
            v.payloadBody = abi.encode(ReturnMultiData(v.currPayloadId, data.superformIds, data.amounts));
        } else {
            InitSingleVaultData memory data = abi.decode(v.payloadBody, (InitSingleVaultData));
            v.payloadBody = abi.encode(ReturnSingleData(v.currPayloadId, data.superformId, data.amount));
        }

        v.ackAmbIds = coreStateRegistry.getMessageAMB(payloadId_);

        v.message = abi.encode(AMBMessage(coreStateRegistry.payloadHeader(payloadId_), v.payloadBody));

        return _estimateAMBFees(v.ackAmbIds, v.srcChainId, v.message);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IPaymentHelper
    function addRemoteChain(
        uint64 chainId_,
        PaymentHelperConfig calldata config_
    )
        external
        override
        onlyProtocolAdmin
    {
        if (config_.nativeFeedOracle != address(0)) {
            AggregatorV3Interface nativeFeedOracleContract = AggregatorV3Interface(config_.nativeFeedOracle);
            if (nativeFeedOracleContract.decimals() != SUPPORTED_FEED_PRECISION) {
                revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
            }

            nativeFeedOracle[chainId_] = nativeFeedOracleContract;
        }

        if (config_.gasPriceOracle != address(0)) {
            AggregatorV3Interface gasPriceOracleContract = AggregatorV3Interface(config_.nativeFeedOracle);
            if (gasPriceOracleContract.decimals() != SUPPORTED_FEED_PRECISION) {
                revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
            }

            gasPriceOracle[chainId_] = gasPriceOracleContract;
        }

        swapGasUsed[chainId_] = config_.swapGasUsed;
        updateGasUsed[chainId_] = config_.updateGasUsed;
        depositGasUsed[chainId_] = config_.depositGasUsed;
        withdrawGasUsed[chainId_] = config_.withdrawGasUsed;
        nativePrice[chainId_] = config_.defaultNativePrice;
        gasPrice[chainId_] = config_.defaultGasPrice;
        gasPerByte[chainId_] = config_.dstGasPerByte;
        ackGasCost[chainId_] = config_.ackGasCost;
        timelockCost[chainId_] = config_.timelockCost;
        emergencyCost[chainId_] = config_.emergencyCost;

        emit ChainConfigAdded(chainId_, config_);
    }

    /// @inheritdoc IPaymentHelper
    function updateRemoteChain(
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
            AggregatorV3Interface nativeFeedOracleContract = AggregatorV3Interface(abi.decode(config_, (address)));

            /// @dev allows setting price feed to address(0), equivalent for resetting native price
            if (
                address(nativeFeedOracleContract) != address(0)
                    && nativeFeedOracleContract.decimals() != SUPPORTED_FEED_PRECISION
            ) {
                revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
            }

            nativeFeedOracle[chainId_] = nativeFeedOracleContract;
        }

        /// @dev Type 2: DST GAS PRICE ORACLE
        if (configType_ == 2) {
            AggregatorV3Interface gasPriceOracleContract = AggregatorV3Interface(abi.decode(config_, (address)));

            /// @dev allows setting gas price to address(0), equivalent for resetting gas price
            if (
                address(gasPriceOracleContract) != address(0)
                    && gasPriceOracleContract.decimals() != SUPPORTED_FEED_PRECISION
            ) {
                revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
            }

            gasPriceOracle[chainId_] = gasPriceOracleContract;
        }

        /// @dev Type 3: SWAP GAS USED
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

        /// @dev Type 7: DEFAULT NATIVE PRICE
        if (configType_ == 7) {
            nativePrice[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 8: DEFAULT GAS PRICE
        if (configType_ == 8) {
            gasPrice[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 9: GAS PRICE PER Byte of Message
        if (configType_ == 9) {
            gasPerByte[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 10: ACK GAS COST
        if (configType_ == 10) {
            ackGasCost[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 11: TIMELOCK PROCESSING COST
        if (configType_ == 11) {
            timelockCost[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 12: EMERGENCY PROCESSING COST
        if (configType_ == 12) {
            emergencyCost[chainId_] = abi.decode(config_, (uint256));
        }

        emit ChainConfigUpdated(chainId_, configType_, config_);
    }

    /// @inheritdoc IPaymentHelper
    function updateRegisterAERC20Params(bytes memory extraDataForTransmuter_) external onlyEmergencyAdmin {
        extraDataForTransmuter = extraDataForTransmuter_;
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev helps generate extra data per amb
    function _generateExtraData(
        uint64 dstChainId_,
        uint8[] memory ambIds_,
        bytes memory message_
    )
        internal
        view
        returns (bytes[] memory extraDataPerAMB)
    {
        AMBMessage memory ambIdEncodedMessage = abi.decode(message_, (AMBMessage));
        ambIdEncodedMessage.params = abi.encode(ambIds_, ambIdEncodedMessage.params);

        uint256 len = ambIds_.length;
        uint256 gasReqPerByte = gasPerByte[dstChainId_];
        uint256 totalDstGasReqInWei = abi.encode(ambIdEncodedMessage).length * gasReqPerByte;

        /// @dev proof length is always of fixed length
        uint256 totalDstGasReqInWeiForProof = PROOF_LENGTH * gasReqPerByte;

        extraDataPerAMB = new bytes[](len);

        for (uint256 i; i < len; ++i) {
            uint256 gasReq = i != 0 ? totalDstGasReqInWeiForProof : totalDstGasReqInWei;
            /// @dev amb id 1: layerzero
            /// @dev amb id 2: hyperlane
            /// @dev amb id 3: wormhole

            /// @notice id 1: encoded layerzero adapter params (version 2). Other values are not used atm.
            /// @notice id 2: encoded dst gas limit
            /// @notice id 3: encoded dst gas limit
            if (ambIds_[i] == 1) {
                extraDataPerAMB[i] = abi.encodePacked(uint16(2), gasReq, uint256(0), address(0));
            } else if (ambIds_[i] == 2) {
                extraDataPerAMB[i] = abi.encode(gasReq);
            } else if (ambIds_[i] == 3) {
                extraDataPerAMB[i] = abi.encode(0, gasReq);
            }
        }
    }

    /// @dev helps estimate the cross-chain message costs
    function _estimateAMBFees(
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_
    )
        internal
        view
        returns (uint256 totalFees)
    {
        uint256 len = ambIds_.length;

        bytes[] memory extraDataPerAMB = _generateExtraData(dstChainId_, ambIds_, message_);

        AMBMessage memory ambIdEncodedMessage = abi.decode(message_, (AMBMessage));
        ambIdEncodedMessage.params = abi.encode(ambIds_, ambIdEncodedMessage.params);

        bytes memory proof_ = abi.encode(AMBMessage(MAX_UINT256, abi.encode(keccak256(message_))));

        /// @dev just checks the estimate for sending message from src -> dst
        /// @dev only ambIds_[0] = primary amb (rest of the ambs send only the proof)
        if (CHAIN_ID != dstChainId_) {
            for (uint256 i; i < len; ++i) {
                uint256 tempFee = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                    dstChainId_, i != 0 ? proof_ : abi.encode(ambIdEncodedMessage), extraDataPerAMB[i]
                );

                totalFees += tempFee;
            }
        }
    }

    /// @dev helps estimate the cross-chain message costs
    function _estimateAMBFeesReturnExtraData(
        uint64 dstChainId_,
        uint8[] calldata ambIds_,
        bytes memory message_
    )
        internal
        view
        returns (uint256[] memory feeSplitUp, bytes[] memory extraDataPerAMB, uint256 totalFees)
    {
        AMBMessage memory ambIdEncodedMessage = abi.decode(message_, (AMBMessage));
        ambIdEncodedMessage.params = abi.encode(ambIds_, ambIdEncodedMessage.params);

        uint256 len = ambIds_.length;

        extraDataPerAMB = _generateExtraData(dstChainId_, ambIds_, message_);

        feeSplitUp = new uint256[](len);

        bytes memory proof_ = abi.encode(AMBMessage(MAX_UINT256, abi.encode(keccak256(message_))));

        /// @dev just checks the estimate for sending message from src -> dst
        if (CHAIN_ID != dstChainId_) {
            for (uint256 i; i < len; ++i) {
                uint256 tempFee = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                    dstChainId_, i != 0 ? proof_ : abi.encode(ambIdEncodedMessage), extraDataPerAMB[i]
                );

                totalFees += tempFee;
                feeSplitUp[i] = tempFee;
            }
        }
    }

    /// @dev helps estimate the liq amount involved in the tx
    function _estimateLiqAmount(LiqRequest[] memory req_) internal pure returns (uint256 liqAmount) {
        uint256 len = req_.length;
        for (uint256 i; i < len; ++i) {
            liqAmount += req_[i].nativeAmount;
        }
    }

    /// @dev helps estimate the dst chain swap gas limit (if multi-tx is involved)
    function _estimateSwapFees(
        uint64 dstChainId_,
        bool[] memory hasDstSwaps_
    )
        internal
        view
        returns (uint256 gasUsed)
    {
        uint256 totalSwaps;

        if (CHAIN_ID == dstChainId_) {
            return 0;
        }

        uint256 len = hasDstSwaps_.length;
        for (uint256 i; i < len; ++i) {
            /// @dev checks if hasDstSwap is true
            if (hasDstSwaps_[i]) {
                ++totalSwaps;
            }
        }

        if (totalSwaps == 0) {
            return 0;
        }

        return totalSwaps * swapGasUsed[dstChainId_];
    }

    /// @dev helps estimate the dst chain update payload gas limit
    function _estimateUpdateCost(uint64 dstChainId_, uint256 vaultsCount_) internal view returns (uint256 gasUsed) {
        return vaultsCount_ * updateGasUsed[dstChainId_];
    }

    /// @dev helps estimate the dst chain processing cost including the dst->src message cost
    /// @dev assumes that withdrawals optimisically succeed
    function _estimateDstExecutionCost(
        bool isDeposit_,
        bool retain4626_,
        uint64 dstChainId_,
        uint256 vaultsCount_
    )
        internal
        view
        returns (uint256 gasUsed)
    {
        uint256 executionGasPerVault = isDeposit_ ? depositGasUsed[dstChainId_] : withdrawGasUsed[dstChainId_];
        gasUsed = executionGasPerVault * vaultsCount_;

        /// @dev add ackGasCost only if it's a deposit and retain4626 is false
        if (isDeposit_ && !retain4626_) {
            gasUsed += ackGasCost[dstChainId_];
        }
    }

    /// @dev helps estimate the src chain processing fee
    function _estimateAckProcessingCost(uint256 vaultsCount_) internal view returns (uint256 nativeFee) {
        uint256 gasCost = vaultsCount_ * ackGasCost[CHAIN_ID];

        return gasCost * _getGasPrice(CHAIN_ID);
    }

    /// @dev generates the amb message for single vault data
    function _generateSingleVaultMessage(SingleVaultSFData memory sfData_)
        internal
        view
        returns (bytes memory message_)
    {
        bytes memory ambData = abi.encode(
            InitSingleVaultData(
                _getNextPayloadId(),
                sfData_.superformId,
                sfData_.amount,
                sfData_.outputAmount,
                sfData_.maxSlippage,
                sfData_.liqRequest,
                sfData_.hasDstSwap,
                sfData_.retain4626,
                sfData_.receiverAddress,
                sfData_.extraFormData
            )
        );
        message_ = abi.encode(AMBMessage(MAX_UINT256, ambData));
    }

    /// @dev generates the amb message for multi vault data
    function _generateMultiVaultMessage(MultiVaultSFData memory sfData_)
        internal
        view
        returns (bytes memory message_)
    {
        bytes memory ambData = abi.encode(
            InitMultiVaultData(
                _getNextPayloadId(),
                sfData_.superformIds,
                sfData_.amounts,
                sfData_.outputAmounts,
                sfData_.maxSlippages,
                sfData_.liqRequests,
                sfData_.hasDstSwaps,
                sfData_.retain4626s,
                sfData_.receiverAddress,
                sfData_.extraFormData
            )
        );
        message_ = abi.encode(AMBMessage(MAX_UINT256, ambData));
    }

    /// @dev helps convert the dst gas fee into src chain native fee
    /// @dev https://docs.soliditylang.org/en/v0.8.4/units-and-global-variables.html#ether-units
    /// @dev all native tokens should be 18 decimals across all EVMs
    function _convertToNativeFee(uint64 dstChainId_, uint256 dstGas_) internal view returns (uint256 nativeFee) {
        /// @dev gas fee * gas price (to get the gas amounts in dst chain's native token)
        /// @dev gas price is 9 decimal (in gwei)
        /// @dev assumption: all evm native tokens are 18 decimals
        uint256 dstNativeFee = dstGas_ * _getGasPrice(dstChainId_);

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
        uint256 nativeTokenPrice = _getNativeTokenPrice(CHAIN_ID); // native token price - 8 decimal
        if (nativeTokenPrice == 0) revert Error.INVALID_NATIVE_TOKEN_PRICE();
        nativeFee = (dstUsdValue) / _getNativeTokenPrice(CHAIN_ID);
    }

    /// @dev helps generate the new payload id
    /// @dev next payload id = current payload id + 1
    function _getNextPayloadId() internal view returns (uint256 nextPayloadId) {
        nextPayloadId = ReadOnlyBaseRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY"))).payloadsCount();
        ++nextPayloadId;
    }

    /// @dev helps return the current gas price of different networks
    /// @return native token price
    function _getGasPrice(uint64 chainId_) internal view returns (uint256) {
        address oracleAddr = address(gasPriceOracle[chainId_]);
        if (oracleAddr != address(0)) {
            try AggregatorV3Interface(oracleAddr).latestRoundData() returns (
                uint80, int256 value, uint256, uint256 updatedAt, uint80
            ) {
                if (value <= 0) revert Error.CHAINLINK_MALFUNCTION();
                if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
                return uint256(value);
            } catch {
                /// @dev do nothing and return the default price at the end of the function
            }
        }

        return gasPrice[chainId_];
    }

    /// @dev helps return the dst chain token price of different networks
    /// @return native token price
    function _getNativeTokenPrice(uint64 chainId_) internal view returns (uint256) {
        address oracleAddr = address(nativeFeedOracle[chainId_]);
        if (oracleAddr != address(0)) {
            try AggregatorV3Interface(oracleAddr).latestRoundData() returns (
                uint80, int256 dstTokenPrice, uint256, uint256 updatedAt, uint80
            ) {
                if (dstTokenPrice <= 0) revert Error.CHAINLINK_MALFUNCTION();
                if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
                return uint256(dstTokenPrice);
            } catch {
                /// @dev do nothing and return the default price at the end of the function
            }
        }

        return nativePrice[chainId_];
    }
}
