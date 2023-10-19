// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";
import { IPaymentHelper } from "../interfaces/IPaymentHelper.sol";
import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";
import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";
import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";
import { Error } from "../utils/Error.sol";
import { DataLib } from "../libraries/DataLib.sol";
import { ProofLib } from "../libraries/ProofLib.sol";
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
    using ProofLib for bytes;
    using ProofLib for AMBMessage;

    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is the address of the superRegistry on the chain
    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint32 public constant TIMELOCK_FORM_ID = 1;

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

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
        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                        PREVILAGES ADMIN ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPaymentHelper
    function addChain(uint64 chainId_, PaymentHelperConfig calldata config_) external override onlyProtocolAdmin {
        if (config_.nativeFeedOracle != address(0)) {
            nativeFeedOracle[chainId_] = AggregatorV3Interface(config_.nativeFeedOracle);
        }

        if (config_.gasPriceOracle != address(0)) {
            gasPriceOracle[chainId_] = AggregatorV3Interface(config_.gasPriceOracle);
        }

        updateGasUsed[chainId_] = config_.updateGasUsed;
        depositGasUsed[chainId_] = config_.depositGasUsed;
        withdrawGasUsed[chainId_] = config_.withdrawGasUsed;
        nativePrice[chainId_] = config_.defaultNativePrice;
        gasPrice[chainId_] = config_.defaultGasPrice;
        gasPerKB[chainId_] = config_.dstGasPerKB;
        ackGasCost[chainId_] = config_.ackGasCost;
        twoStepCost[chainId_] = config_.twoStepCost;
        swapGasUsed[chainId_] = config_.swapGasUsed;
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

        /// @dev Type 3: PAYLOAD UPDATE GAS COST PER TX FOR DEPOSIT
        if (configType_ == 3) {
            updateGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 4: DEPOSIT GAS COST PER TX
        if (configType_ == 4) {
            depositGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 5: WITHDRAW GAS COST PER TX
        if (configType_ == 5) {
            withdrawGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 6: DEFAULT NATIVE PRICE
        if (configType_ == 6) {
            nativePrice[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 7: DEFAULT GAS PRICE
        if (configType_ == 7) {
            gasPrice[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 8: GAS PRICE PER KB of Message
        if (configType_ == 8) {
            gasPerKB[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 9: ACK GAS COST
        if (configType_ == 9) {
            ackGasCost[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 10: TWO STEP PROCESSING COST
        if (configType_ == 10) {
            twoStepCost[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 11: SWAP GAS USED
        if (configType_ == 11) {
            swapGasUsed[chainId_] = abi.decode(config_, (uint256));
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
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 len = req_.dstChainIds.length;
        uint256 superformIdsLen;
        for (uint256 i; i < len;) {
            uint256 totalDstGas;

            /// @dev step 1: estimate amb costs
            (, uint256 ambFees) = _estimateAMBFees(
                req_.ambIds[i], req_.dstChainIds[i], _generateMultiVaultMessage(req_.superformsData[i])
            );

            superformIdsLen = req_.superformsData[i].superformIds.length;

            srcAmount += ambFees;

            if (isDeposit_) {
                /// @dev step 2: estimate update cost (only for deposit)
                totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], superformIdsLen);

                /// @dev step 3: estimation processing cost of acknowledgement
                /// @notice optimistically estimating. (Ideal case scenario: no failed deposits / withdrawals)
                srcAmount += _estimateAckProcessingCost(req_.dstChainIds.length, superformIdsLen);

                /// @dev step 4: estimate liq amount
                liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequests);

                /// @dev step 5: estimate dst swap cost if it exists
                totalDstGas += _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].liqRequests);
            }

            /// @dev step 6: estimate execution costs in dst (withdraw / deposit)
            /// note: execution cost includes acknowledgement messaging cost
            totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainIds[i], superformIdsLen);

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
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 len = req_.dstChainIds.length;
        for (uint256 i; i < len;) {
            uint256 totalDstGas;

            /// @dev step 1: estimate amb costs
            (, uint256 ambFees) = _estimateAMBFees(
                req_.ambIds[i], req_.dstChainIds[i], _generateSingleVaultMessage(req_.superformsData[i])
            );

            srcAmount += ambFees;

            if (isDeposit_) {
                /// @dev step 2: estimate update cost (only for deposit)
                totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], 1);

                /// @dev step 3: estimation execution cost of acknowledgement
                srcAmount += _estimateAckProcessingCost(len, 1);

                /// @dev step 4: estimate the liqAmount
                liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequest.castToArray());

                /// @dev step 5: estimate if swap costs are involved
                totalDstGas += _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].liqRequest.castToArray());
            }

            /// @dev step 5: estimate execution costs in dst
            /// note: execution cost includes acknowledgement messaging cost
            totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainIds[i], 1);

            /// @dev step 6: convert all dst gas estimates to src chain estimate
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
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 totalDstGas;
        uint256 superformIdsLen = req_.superformsData.superformIds.length;

        /// @dev step 1: estimate amb costs
        (, uint256 ambFees) =
            _estimateAMBFees(req_.ambIds, req_.dstChainId, _generateMultiVaultMessage(req_.superformsData));

        srcAmount += ambFees;

        /// @dev step 2: estimate update cost (only for deposit)
        if (isDeposit_) totalDstGas += _estimateUpdateCost(req_.dstChainId, superformIdsLen);

        /// @dev step 3: estimate execution costs in dst
        /// note: execution cost includes acknowledgement messaging cost
        totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainId, superformIdsLen);

        /// @dev step 4: estimation execution cost of acknowledgement
        if (isDeposit_) srcAmount += _estimateAckProcessingCost(1, superformIdsLen);

        /// @dev step 5: estimate liq amount
        if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformsData.liqRequests);

        /// @dev step 6: estimate if swap costs are involved
        if (isDeposit_) totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superformsData.liqRequests);

        /// @dev step 7: convert all dst gas estimates to src chain estimate
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
        /// @dev step 1: estimate amb costs
        (, uint256 ambFees) =
            _estimateAMBFees(req_.ambIds, req_.dstChainId, _generateSingleVaultMessage(req_.superformData));

        srcAmount += ambFees;

        /// @dev step 2: estimate update cost (only for deposit)
        if (isDeposit_) totalDstGas += _estimateUpdateCost(req_.dstChainId, 1);

        /// @dev step 3: estimate execution costs in dst
        /// note: execution cost includes acknowledgement messaging cost
        totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainId, 1);

        /// @dev step 4: estimation execution cost of acknowledgement
        if (isDeposit_) srcAmount += _estimateAckProcessingCost(1, 1);

        /// @dev step 5: estimate the liq amount
        if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformData.liqRequest.castToArray());

        /// @dev step 6: estimate if swap costs are involved
        if (isDeposit_) totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superformData.liqRequest.castToArray());

        /// @dev step 7: convert all dst gas estimates to src chain estimate
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
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        (, uint32 formId,) = req_.superformData.superformId.getSuperform();
        /// @dev only if timelock form withdrawal is involved
        if (!isDeposit_ && formId == TIMELOCK_FORM_ID) {
            srcAmount += twoStepCost[CHAIN_ID] * _getGasPrice(CHAIN_ID);
        }

        if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformData.liqRequest.castToArray());

        /// @dev not adding dstAmount to save some GAS
        totalAmount = liqAmount + srcAmount;

        dstAmount = 0;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleDirectMultiVault(
        SingleDirectMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 len = req_.superformData.superformIds.length;
        for (uint256 i; i < len;) {
            (, uint32 formId,) = req_.superformData.superformIds[i].getSuperform();
            /// @dev only if timelock form withdrawal is involved
            if (!isDeposit_ && formId == TIMELOCK_FORM_ID) {
                srcAmount += twoStepCost[CHAIN_ID] * _getGasPrice(CHAIN_ID);
            }

            unchecked {
                ++i;
            }
        }

        if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformData.liqRequests);

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
        uint8[] memory ambIds_,
        bytes memory message_
    )
        public
        view
        returns (bytes[] memory extraDataPerAMB)
    {
        uint256 len = ambIds_.length;
        uint256 totalDstGasReqInWei = message_.length * gasPerKB[dstChainId_];

        AMBMessage memory decodedMessage = abi.decode(message_, (AMBMessage));
        decodedMessage.params = message_.computeProofBytes();

        uint256 totalDstGasReqInWeiForProof = abi.encode(decodedMessage).length * gasPerKB[dstChainId_];

        extraDataPerAMB = new bytes[](len);

        for (uint256 i; i < len;) {
            uint256 gasReq = i != 0 ? totalDstGasReqInWeiForProof : totalDstGasReqInWei;

            if (ambIds_[i] == 1) {
                extraDataPerAMB[i] = abi.encodePacked(uint16(2), gasReq, uint256(0), address(0));
            } else if (ambIds_[i] == 2) {
                extraDataPerAMB[i] = abi.encode(gasReq);
            } else if (ambIds_[i] == 3) {
                extraDataPerAMB[i] = abi.encode(0, gasReq);
            }

            unchecked {
                ++i;
            }
        }
    }

    struct EstimateAckCostVars {
        uint256 currPayloadId;
        uint256 payloadHeader;
        uint8 callbackType;
        bytes payloadBody;
        bytes32 proof;
        uint8[] ackAmbIds;
        uint8[] proofIds;
        uint8 isMulti;
        uint64 srcChainId;
        bytes message;
    }

    /// @dev helps estimate the acknowledgement costs for amb processing
    function estimateAckCost(uint256 payloadId_) external view returns (uint256 totalFees, uint256[] memory) {
        EstimateAckCostVars memory v;
        IBaseStateRegistry coreStateRegistry =
            IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY")));
        v.currPayloadId = coreStateRegistry.payloadsCount();

        if (payloadId_ > v.currPayloadId) revert Error.INVALID_PAYLOAD_ID();

        v.payloadHeader = coreStateRegistry.payloadHeader(payloadId_);
        v.payloadBody = coreStateRegistry.payloadBody(payloadId_);

        v.proof = AMBMessage(v.payloadHeader, v.payloadBody).computeProof();

        (, v.callbackType, v.isMulti,,, v.srcChainId) = DataLib.decodeTxInfo(v.payloadHeader);

        /// if callback type is return then return 0
        if (v.callbackType != 0) return (0, new uint256[](0));

        if (v.isMulti == 1) {
            InitMultiVaultData memory data = abi.decode(v.payloadBody, (InitMultiVaultData));
            v.payloadBody =
                abi.encode(ReturnMultiData(data.superformRouterId, v.currPayloadId, data.superformIds, data.amounts));
        } else {
            InitSingleVaultData memory data = abi.decode(v.payloadBody, (InitSingleVaultData));
            v.payloadBody =
                abi.encode(ReturnSingleData(data.superformRouterId, v.currPayloadId, data.superformId, data.amount));
        }

        v.proofIds = coreStateRegistry.getProofAMB(v.proof);
        v.ackAmbIds = new uint8[](v.proofIds.length + 1);
        v.ackAmbIds[0] = coreStateRegistry.msgAMB(payloadId_);

        for (uint256 i; i < v.proofIds.length; i++) {
            v.ackAmbIds[i + 1] = v.proofIds[i];
        }

        v.message = abi.encode(AMBMessage(coreStateRegistry.payloadHeader(payloadId_), v.payloadBody));

        return estimateAMBFees(
            v.ackAmbIds, v.srcChainId, v.message, _generateExtraData(v.srcChainId, v.ackAmbIds, v.message)
        );
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

        bytes memory proof_ = abi.encode(AMBMessage(type(uint256).max, abi.encode(keccak256(message_))));

        /// @dev just checks the estimate for sending message from src -> dst
        /// @dev only ambIds_[0] = primary amb (rest of the ambs send only the proof)
        for (uint256 i; i < len;) {
            uint256 tempFee = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                dstChainId_, i != 0 ? proof_ : message_, extraDataPerAMB[i]
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

        bytes memory proof_ = abi.encode(AMBMessage(type(uint256).max, abi.encode(keccak256(message_))));

        /// @dev just checks the estimate for sending message from src -> dst
        for (uint256 i; i < len;) {
            uint256 tempFee = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
                dstChainId_, i != 0 ? proof_ : message_, extraDataPerAMB[i]
            );

            totalFees += tempFee;
            feeSplitUp[i] = tempFee;

            unchecked {
                ++i;
            }
        }
    }

    /// @dev helps estimate the liq amount involved in the tx
    function _estimateLiqAmount(LiqRequest[] memory req_) internal view returns (uint256 liqAmount) {
        for (uint256 i; i < req_.length;) {
            if (req_[i].token == NATIVE) {
                liqAmount += IBridgeValidator(superRegistry.getBridgeValidator(req_[i].bridgeId)).decodeAmountIn(
                    req_[i].txData, false
                );
            }

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

        if (CHAIN_ID == dstChainId_) {
            return 0;
        }

        for (uint256 i; i < liqReq_.length;) {
            /// @dev checks if tx_data receiver is dstSwapProcessor
            if (
                liqReq_[i].bridgeId != 0
                    && IBridgeValidator(superRegistry.getBridgeValidator(liqReq_[i].bridgeId)).validateReceiver(
                        liqReq_[i].txData, superRegistry.getAddress(keccak256("DST_SWAPPER"))
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
        uint256 gasCost = dstChainCount_ * vaultsCount_ * ackGasCost[CHAIN_ID];

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
                1,
                /// @dev sample router id for estimation
                _getNextPayloadId(),
                sfData_.superformId,
                sfData_.amount,
                sfData_.maxSlippage,
                sfData_.hasDstSwap,
                sfData_.liqRequest,
                sfData_.dstRefundAddress,
                sfData_.extraFormData
            )
        );
        message_ = abi.encode(AMBMessage(type(uint256).max, ambData));
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
                sfData_.hasDstSwaps,
                sfData_.liqRequests,
                sfData_.dstRefundAddress,
                sfData_.extraFormData
            )
        );
        message_ = abi.encode(AMBMessage(type(uint256).max, ambData));
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
        if (address(gasPriceOracle[chainId_]) != address(0)) {
            (, int256 value,, uint256 updatedAt,) = gasPriceOracle[chainId_].latestRoundData();
            if (value <= 0) revert Error.CHAINLINK_MALFUNCTION();
            if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
            return uint256(value);
        }

        return gasPrice[chainId_];
    }

    /// @dev helps return the dst chain token price of different networks
    /// @return native token price
    function _getNativeTokenPrice(uint64 chainId_) internal view returns (uint256) {
        if (address(nativeFeedOracle[chainId_]) != address(0)) {
            (, int256 dstTokenPrice,, uint256 updatedAt,) = nativeFeedOracle[chainId_].latestRoundData();
            if (dstTokenPrice <= 0) revert Error.CHAINLINK_MALFUNCTION();
            if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
            return uint256(dstTokenPrice);
        }

        return nativePrice[chainId_];
    }
}
