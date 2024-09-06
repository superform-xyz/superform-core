// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IPaymentHelperV2 as IPaymentHelper } from "src/interfaces/IPaymentHelperV2.sol";
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
    uint8 private constant MIN_FEED_PRECISION = 8;
    uint8 private constant MAX_FEED_PRECISION = 18;
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
    mapping(uint64 chainId => uint256 gasForUpdateDeposit) public updateDepositGasUsed;
    mapping(uint64 chainId => uint256 gasForUpdateWithdraw) public updateWithdrawGasUsed;
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
        uint256 totalGas;
        uint256 ambFees;
        bool paused;
    }

    struct CalculateAmountsReq {
        uint256 i;
        uint64[] dstChainIds;
        uint8[] ambIds;
        MultiVaultSFData[] superformsData;
        SingleVaultSFData[] superformData;
        ISuperformFactory factory;
        bool isDeposit;
    }

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(_getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    modifier onlyPaymentAdmin() {
        if (
            !ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(
                keccak256("PAYMENT_ADMIN_ROLE"), msg.sender
            )
        ) {
            revert Error.NOT_PAYMENT_ADMIN();
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
        uint256 len = req_.dstChainIds.length;
        uint256 liqAmountIndex;
        uint256 srcAmountIndex;
        uint256 dstAmountIndex;

        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));
        SingleVaultSFData[] memory temp;

        for (uint256 i; i < len; ++i) {
            (liqAmountIndex, srcAmountIndex, dstAmountIndex) = _calculateAmounts(
                CalculateAmountsReq(i, req_.dstChainIds, req_.ambIds[i], req_.superformsData, temp, factory, isDeposit_)
            );
            liqAmount += liqAmountIndex;
            srcAmount += srcAmountIndex;
            dstAmount += dstAmountIndex;
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
        uint256 liqAmountIndex;
        uint256 srcAmountIndex;
        uint256 dstAmountIndex;
        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));
        MultiVaultSFData[] memory temp;
        for (uint256 i; i < len; ++i) {
            (liqAmountIndex, srcAmountIndex, dstAmountIndex) = _calculateAmounts(
                CalculateAmountsReq(i, req_.dstChainIds, req_.ambIds[i], temp, req_.superformsData, factory, isDeposit_)
            );
            liqAmount += liqAmountIndex;
            srcAmount += srcAmountIndex;
            dstAmount += dstAmountIndex;
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
        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));

        uint64[] memory dstChainIds = new uint64[](1);
        dstChainIds[0] = req_.dstChainId;

        SingleVaultSFData[] memory temp;

        MultiVaultSFData[] memory sfData = new MultiVaultSFData[](1);
        sfData[0] = req_.superformsData;

        (liqAmount, srcAmount, dstAmount) =
            _calculateAmounts(CalculateAmountsReq(0, dstChainIds, req_.ambIds, sfData, temp, factory, isDeposit_));

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
        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));

        uint64[] memory dstChainIds = new uint64[](1);
        dstChainIds[0] = req_.dstChainId;

        MultiVaultSFData[] memory temp;

        SingleVaultSFData[] memory sfData = new SingleVaultSFData[](1);
        sfData[0] = req_.superformData;

        (liqAmount, srcAmount, dstAmount) =
            _calculateAmounts(CalculateAmountsReq(0, dstChainIds, req_.ambIds, temp, sfData, factory, isDeposit_));

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
        returns (uint256 liqAmount, uint256 dstOrSameChainAmt, uint256 totalAmount)
    {
        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));

        uint64[] memory dstChainIds = new uint64[](1);
        dstChainIds[0] = CHAIN_ID;

        SingleVaultSFData[] memory sfData = new SingleVaultSFData[](1);
        sfData[0] = req_.superformData;

        MultiVaultSFData[] memory temp;

        uint8[] memory ambIds;

        (liqAmount,, dstOrSameChainAmt) =
            _calculateAmounts(CalculateAmountsReq(0, dstChainIds, ambIds, temp, sfData, factory, isDeposit_));

        totalAmount = liqAmount + dstOrSameChainAmt;
    }

    /// @inheritdoc IPaymentHelper
    function estimateSingleDirectMultiVault(
        SingleDirectMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 dstOrSameChainAmt, uint256 totalAmount)
    {
        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));

        uint64[] memory dstChainIds = new uint64[](1);
        dstChainIds[0] = CHAIN_ID;

        SingleVaultSFData[] memory temp;

        MultiVaultSFData[] memory sfData = new MultiVaultSFData[](1);
        sfData[0] = req_.superformData;

        uint8[] memory ambIds;

        (liqAmount,, dstOrSameChainAmt) =
            _calculateAmounts(CalculateAmountsReq(0, dstChainIds, ambIds, sfData, temp, factory, isDeposit_));

        totalAmount = liqAmount + dstOrSameChainAmt;
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
        override
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

    /// @inheritdoc IPaymentHelper
    function estimateAckCost(uint256 payloadId_) external view override returns (uint256 totalFees) {
        EstimateAckCostVars memory v;
        IBaseStateRegistry coreStateRegistry = IBaseStateRegistry(_getAddress(keccak256("CORE_STATE_REGISTRY")));
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

    /// @inheritdoc IPaymentHelper
    function estimateAckCostDefault(
        bool multi,
        uint8[] memory ackAmbIds,
        uint64 srcChainId
    )
        public
        view
        override
        returns (uint256 totalFees)
    {
        bytes memory payloadBody;
        if (multi) {
            uint256 vaultLimitPerDst = superRegistry.getVaultLimitPerDestination(srcChainId);
            uint256[] memory maxUints = new uint256[](vaultLimitPerDst);

            for (uint256 i; i < vaultLimitPerDst; ++i) {
                maxUints[i] = type(uint256).max;
            }
            payloadBody = abi.encode(ReturnMultiData(type(uint256).max, maxUints, maxUints));
        } else {
            payloadBody = abi.encode(ReturnSingleData(type(uint256).max, type(uint256).max, type(uint256).max));
        }

        return _estimateAMBFees(ackAmbIds, srcChainId, abi.encode(AMBMessage(type(uint256).max, payloadBody)));
    }

    /// @inheritdoc IPaymentHelper
    function estimateAckCostDefaultNativeSource(
        bool multi,
        uint8[] memory ackAmbIds,
        uint64 srcChainId
    )
        external
        view
        override
        returns (uint256)
    {
        return _convertToSrcNativeAmount(srcChainId, estimateAckCostDefault(multi, ackAmbIds, srcChainId));
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IPaymentHelper
    function addRemoteChain(uint64 chainId_, PaymentHelperConfig calldata config_) public override onlyProtocolAdmin {
        _addRemoteChain(chainId_, config_);
    }

    /// @inheritdoc IPaymentHelper
    function addRemoteChains(
        uint64[] calldata chainIds_,
        PaymentHelperConfig[] calldata configs_
    )
        external
        override
        onlyProtocolAdmin
    {
        uint256 len = chainIds_.length;

        if (len == 0) revert Error.ZERO_INPUT_VALUE();

        if (len != configs_.length) revert Error.ARRAY_LENGTH_MISMATCH();

        for (uint256 i; i < len; ++i) {
            _addRemoteChain(chainIds_[i], configs_[i]);
        }
    }

    /// @inheritdoc IPaymentHelper
    function updateRemoteChain(
        uint64 chainId_,
        uint256 configType_,
        bytes memory config_
    )
        external
        override
        onlyPaymentAdmin
    {
        _updateRemoteChain(chainId_, configType_, config_);
    }

    /// @inheritdoc IPaymentHelper
    function batchUpdateRemoteChain(
        uint64 chainId_,
        uint256[] calldata configTypes_,
        bytes[] calldata configs_
    )
        external
        override
        onlyPaymentAdmin
    {
        _batchUpdateRemoteChain(chainId_, configTypes_, configs_);
    }

    /// @inheritdoc IPaymentHelper
    function batchUpdateRemoteChains(
        uint64[] calldata chainIds_,
        uint256[][] calldata configTypes_,
        bytes[][] calldata configs_
    )
        external
        override
        onlyPaymentAdmin
    {
        uint256 len = chainIds_.length;

        if (len == 0) revert Error.ZERO_INPUT_VALUE();

        if (!(len == configTypes_.length && len == configs_.length)) revert Error.ARRAY_LENGTH_MISMATCH();

        for (uint256 i; i < len; ++i) {
            _batchUpdateRemoteChain(chainIds_[i], configTypes_[i], configs_[i]);
        }
    }

    /// @inheritdoc IPaymentHelper
    function updateRegisterAERC20Params(bytes memory extraDataForTransmuter_) external onlyPaymentAdmin {
        extraDataForTransmuter = extraDataForTransmuter_;
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    function _getOracleDecimals(AggregatorV3Interface oracle_) internal view returns (uint8) {
        return oracle_.decimals();
    }

    /// @dev PROTOCOL_ADMIN can perform the configuration of a remote chain for the first time
    function _addRemoteChain(uint64 chainId_, PaymentHelperConfig calldata config_) internal {
        if (config_.nativeFeedOracle != address(0)) {
            AggregatorV3Interface nativeFeedOracleContract = AggregatorV3Interface(config_.nativeFeedOracle);

            uint256 oraclePrecision = _getOracleDecimals(nativeFeedOracleContract);
            if (oraclePrecision < MIN_FEED_PRECISION || oraclePrecision > MAX_FEED_PRECISION) {
                revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
            }

            nativeFeedOracle[chainId_] = nativeFeedOracleContract;
        }

        if (config_.gasPriceOracle != address(0)) {
            AggregatorV3Interface gasPriceOracleContract = AggregatorV3Interface(config_.gasPriceOracle);

            uint256 oraclePrecision = _getOracleDecimals(gasPriceOracleContract);

            if (oraclePrecision < MIN_FEED_PRECISION || oraclePrecision > MAX_FEED_PRECISION) {
                revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
            }

            gasPriceOracle[chainId_] = gasPriceOracleContract;
        }

        swapGasUsed[chainId_] = config_.swapGasUsed;
        updateDepositGasUsed[chainId_] = config_.updateDepositGasUsed;
        depositGasUsed[chainId_] = config_.depositGasUsed;
        withdrawGasUsed[chainId_] = config_.withdrawGasUsed;
        nativePrice[chainId_] = config_.defaultNativePrice;
        gasPrice[chainId_] = config_.defaultGasPrice;
        gasPerByte[chainId_] = config_.dstGasPerByte;
        ackGasCost[chainId_] = config_.ackGasCost;
        timelockCost[chainId_] = config_.timelockCost;
        emergencyCost[chainId_] = config_.emergencyCost;
        updateWithdrawGasUsed[chainId_] = config_.updateWithdrawGasUsed;

        emit ChainConfigAdded(chainId_, config_);
    }

    /// @dev PAYMENT_ADMIN can update the configuration of a remote chain on a need basis
    function _updateRemoteChain(uint64 chainId_, uint256 configType_, bytes memory config_) internal {
        /// @dev Type 1: DST TOKEN PRICE FEED ORACLE
        if (configType_ == 1) {
            AggregatorV3Interface nativeFeedOracleContract = AggregatorV3Interface(abi.decode(config_, (address)));

            /// @dev allows setting price feed to address(0), equivalent for resetting native price
            if (address(nativeFeedOracleContract) != address(0)) {
                uint256 oraclePrecision = _getOracleDecimals(nativeFeedOracleContract);
                if (oraclePrecision < MIN_FEED_PRECISION || oraclePrecision > MAX_FEED_PRECISION) {
                    revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
                }
            }

            nativeFeedOracle[chainId_] = nativeFeedOracleContract;
        }

        /// @dev Type 2: DST GAS PRICE ORACLE
        if (configType_ == 2) {
            AggregatorV3Interface gasPriceOracleContract = AggregatorV3Interface(abi.decode(config_, (address)));

            /// @dev allows setting gas price to address(0), equivalent for resetting gas price
            if (address(gasPriceOracleContract) != address(0)) {
                uint256 oraclePrecision = _getOracleDecimals(gasPriceOracleContract);
                if (oraclePrecision < MIN_FEED_PRECISION || oraclePrecision > MAX_FEED_PRECISION) {
                    revert Error.CHAINLINK_UNSUPPORTED_DECIMAL();
                }
            }

            gasPriceOracle[chainId_] = gasPriceOracleContract;
        }

        /// @dev Type 3: SWAP GAS USED
        if (configType_ == 3) {
            swapGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        /// @dev Type 4: PAYLOAD UPDATE DEPOSIT GAS COST PER TX
        if (configType_ == 4) {
            updateDepositGasUsed[chainId_] = abi.decode(config_, (uint256));
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

        /// @dev Type 13: PAYLOAD UPDATE WITHDRAW GAS COST PER TX
        if (configType_ == 13) {
            updateWithdrawGasUsed[chainId_] = abi.decode(config_, (uint256));
        }

        emit ChainConfigUpdated(chainId_, configType_, config_);
    }

    /// @dev batch updates the configuration of a remote chain. Performed by PAYMENT_ADMIN
    function _batchUpdateRemoteChain(
        uint64 chainId_,
        uint256[] calldata configTypes_,
        bytes[] calldata configs_
    )
        internal
    {
        uint256 len = configTypes_.length;

        if (len == 0) revert Error.ZERO_INPUT_VALUE();

        if (len != configs_.length) revert Error.ARRAY_LENGTH_MISMATCH();

        for (uint256 i; i < len; ++i) {
            _updateRemoteChain(chainId_, configTypes_[i], configs_[i]);
        }
    }

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
            extraDataPerAMB[i] = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).generateExtraData(gasReq);
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
    function _estimateUpdateDepositCost(
        uint64 dstChainId_,
        uint256 vaultsCount_
    )
        internal
        view
        returns (uint256 gasUsed)
    {
        return vaultsCount_ * updateDepositGasUsed[dstChainId_];
    }

    /// @dev helps estimate the dst chain update payload gas limit
    function _estimateUpdateWithdrawCost(
        uint64 dstChainId_,
        LiqRequest[] memory liqRequests_
    )
        internal
        view
        returns (uint256 gasUsed)
    {
        uint256 len = liqRequests_.length;
        for (uint256 i; i < len; i++) {
            /// @dev liqRequests[i].token on withdraws is the desired token
            /// @dev if token is address(0) -> user wants settlement without any liq data
            /// @dev this means that if no txData is present and token is different than address(0) an update is
            /// required in destination
            if (liqRequests_[i].txData.length == 0 && liqRequests_[i].token != address(0)) {
                gasUsed += updateWithdrawGasUsed[dstChainId_];
            }
        }
    }

    /// @dev helps estimate the dst chain processing cost including the dst->src message cost
    /// @dev assumes that withdrawals optimisically succeed
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
        gasUsed = executionGasPerVault * vaultsCount_;
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
    function _convertToNativeFee(
        uint64 dstChainId_,
        uint256 dstGas_,
        bool xChain_
    )
        internal
        view
        returns (uint256 nativeFee)
    {
        /// @dev gas fee * gas price (to get the gas amounts in dst chain's native token)
        /// @dev gas price is 9 decimal (in gwei)
        /// @dev assumption: all evm native tokens are 18 decimals
        uint256 dstNativeFee = dstGas_ * _getGasPrice(dstChainId_);

        if (dstNativeFee == 0) {
            return 0;
        }
        if (!xChain_) {
            return dstNativeFee;
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
        nativeFee = (dstUsdValue) / nativeTokenPrice;
    }

    /// @dev helps convert a native token of one chain to another
    /// @dev https://docs.soliditylang.org/en/v0.8.4/units-and-global-variables.html#ether-units
    /// @dev all native tokens should be 18 decimals across all EVMs
    function _convertToSrcNativeAmount(
        uint64 srcChainId_,
        uint256 dstAmount_
    )
        internal
        view
        returns (uint256 nativeFee)
    {
        if (dstAmount_ == 0) {
            return 0;
        }

        /// @dev converts the native token value to usd value
        /// @dev dstAmount_ is 18 decimal
        /// @dev native token price is 8 decimal
        uint256 dstUsdValue = dstAmount_ * _getNativeTokenPrice(CHAIN_ID);

        if (dstUsdValue == 0) {
            return 0;
        }

        /// @dev converts the usd value to source chain's native token
        /// @dev native token price is 8 decimal which cancels the 8 decimal multiplied in previous step
        uint256 nativeTokenPrice = _getNativeTokenPrice(srcChainId_);
        if (nativeTokenPrice == 0) revert Error.INVALID_NATIVE_TOKEN_PRICE();

        nativeFee = dstUsdValue / nativeTokenPrice;
    }

    /// @dev helps generate the new payload id
    /// @dev next payload id = current payload id + 1
    function _getNextPayloadId() internal view returns (uint256 nextPayloadId) {
        nextPayloadId = ReadOnlyBaseRegistry(_getAddress(keccak256("CORE_STATE_REGISTRY"))).payloadsCount();
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

                uint256 oraclePrecision = _getOracleDecimals(AggregatorV3Interface(oracleAddr));

                if (oraclePrecision == MIN_FEED_PRECISION) return uint256(value);
                else return uint256(value) / (10 ** (oraclePrecision - MIN_FEED_PRECISION));
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

                uint256 oraclePrecision = _getOracleDecimals(AggregatorV3Interface(oracleAddr));

                if (oraclePrecision == MIN_FEED_PRECISION) return uint256(dstTokenPrice);
                else return uint256(dstTokenPrice) / (10 ** (oraclePrecision - MIN_FEED_PRECISION));
            } catch {
                /// @dev do nothing and return the default price at the end of the function
            }
        }

        return nativePrice[chainId_];
    }

    /// @dev returns the address from super registry
    function _getAddress(bytes32 id_) internal view returns (address) {
        return superRegistry.getAddress(id_);
    }

    /// @dev calculates different cost amounts involved in the tx
    function _calculateAmounts(CalculateAmountsReq memory req_)
        internal
        view
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstOrSameChainAmt)
    {
        LocalEstimateVars memory v;

        bool xChain = req_.dstChainIds[req_.i] != CHAIN_ID;

        /// @dev in xChain this is gas on the destination chain and in !xChain this is gas on the same chain
        v.totalGas = 0;

        bool multiVaults = req_.superformsData.length > 0;
        bytes memory message = multiVaults
            ? _generateMultiVaultMessage(req_.superformsData[req_.i])
            : _generateSingleVaultMessage(req_.superformData[req_.i]);

        /// @dev step 1: estimate amb costs
        v.ambFees = xChain ? _estimateAMBFees(req_.ambIds, req_.dstChainIds[req_.i], message) : 0;

        v.superformIdsLen = multiVaults ? req_.superformsData[req_.i].superformIds.length : 1;

        srcAmount += v.ambFees;
        LiqRequest[] memory liqRequests = multiVaults
            ? req_.superformsData[req_.i].liqRequests
            : req_.superformData[req_.i].liqRequest.castLiqRequestToArray();

        if (req_.isDeposit) {
            /// @dev step 2: estimate liq amount
            liqAmount += _estimateLiqAmount(liqRequests);

            if (xChain) {
                /// @dev step 3: estimate update cost (only for deposit)
                v.totalGas += _estimateUpdateDepositCost(req_.dstChainIds[req_.i], v.superformIdsLen);

                uint256 ackLen;
                if (multiVaults) {
                    for (uint256 j; j < v.superformIdsLen; ++j) {
                        if (!req_.superformsData[req_.i].retain4626s[j]) ++ackLen;
                    }
                } else {
                    if (!req_.superformData[req_.i].retain4626) ++ackLen;
                }

                /// @dev step 4: estimation processing cost of acknowledgement on source
                srcAmount += _estimateAckProcessingCost(ackLen);
                bool[] memory hasDstSwaps = multiVaults
                    ? req_.superformsData[req_.i].hasDstSwaps
                    : req_.superformData[req_.i].hasDstSwap.castBoolToArray();
                /// @dev step 5: estimate dst swap cost if it exists
                v.totalGas += _estimateSwapFees(req_.dstChainIds[req_.i], hasDstSwaps);
            }
        } else {
            if (multiVaults) {
                /// @dev step 6: estimate if timelock form processing costs are involved
                for (uint256 j; j < v.superformIdsLen; ++j) {
                    v.totalGas += _calculateTotalDstGasTimelockEmergency(
                        req_.superformsData[req_.i].superformIds[j], req_.dstChainIds[req_.i], req_.factory
                    );
                }
            } else {
                v.totalGas += _calculateTotalDstGasTimelockEmergency(
                    req_.superformData[req_.i].superformId, req_.dstChainIds[req_.i], req_.factory
                );
            }
            if (xChain) {
                /// @dev step 7: estimate update withdraw cost if no txData is present
                v.totalGas += _estimateUpdateWithdrawCost(req_.dstChainIds[req_.i], liqRequests);
            }
        }

        /// @dev step 7: estimate execution costs in destination including sending acknowledgement to source
        /// @dev ensure that acknowledgement costs from dst to src are not double counted
        v.totalGas +=
            xChain ? _estimateDstExecutionCost(req_.isDeposit, req_.dstChainIds[req_.i], v.superformIdsLen) : 0;

        /// @dev step 8: convert all dst/same chain gas estimates to src chain estimate  (withdraw / deposit)
        dstOrSameChainAmt += _convertToNativeFee(req_.dstChainIds[req_.i], v.totalGas, xChain);
    }

    /// @dev calculates the srcAmount cost for single direct withdrawal
    function _calculateTotalDstGasTimelockEmergency(
        uint256 superformId_,
        uint64 dstChainId_,
        ISuperformFactory factory_
    )
        internal
        view
        returns (uint256 totalDstGas)
    {
        (, uint32 formId,) = superformId_.getSuperform();
        bool paused = factory_.isFormImplementationPaused(formId);

        if (!paused && formId == TIMELOCK_FORM_ID) {
            totalDstGas += timelockCost[dstChainId_];
        } else if (paused) {
            totalDstGas += emergencyCost[dstChainId_];
        }
    }
}
