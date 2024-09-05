// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IPaymentHelperV2 as IPaymentHelper } from "src/interfaces/IPaymentHelperV2.sol";
import { IPaymentHelperExtn } from "src/interfaces/IPaymentHelperExtn.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { Error } from "src/libraries/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import {
    SingleDirectSingleVaultStateReq,
    SingleXChainSingleVaultStateReq,
    SingleDirectMultiVaultStateReq,
    SingleXChainMultiVaultStateReq,
    SingleVaultSFData,
    MultiVaultSFData
} from "src/types/DataTypes.sol";

/// @title PaymentHelperExtn (Payment Helper Extension)
/// @dev Helps estimate the cost for the entire transaction lifecycle when using router wrapper
/// @author ZeroPoint Labs
contract PaymentHelperExtn is IPaymentHelperExtn {
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;

    /// @dev uses payment helper to estimate the router calls
    IPaymentHelper public paymentHelper;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////
    constructor(address superRegistry_, address paymentHelper_) {
        if (superRegistry_ == address(0) || paymentHelper_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);
        superRegistry = ISuperRegistry(superRegistry_);
        paymentHelper = IPaymentHelper(paymentHelper_);
    }

    //////////////////////////////////////////////////////////////
    //                      EXTERNAL FUNCTIONS                  //
    //////////////////////////////////////////////////////////////
    function estimateRebalanceSinglePosition(
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        view
        override
        returns (uint256 msgValue)
    {
        /// @dev estimate withdrawal
        SingleDirectSingleVaultStateReq memory withdrawReq =
            SingleDirectSingleVaultStateReq({ superformData: _decodeSingleVaultData(callData_) });
        (,, uint256 withdrawCost) = paymentHelper.estimateSingleDirectSingleVault(withdrawReq, false);

        /// @dev estimate deposit
        SingleDirectSingleVaultStateReq memory depositReq =
            SingleDirectSingleVaultStateReq({ superformData: _decodeSingleVaultData(rebalanceCallData_) });
        (,, uint256 depositCost) = paymentHelper.estimateSingleDirectSingleVault(depositReq, true);

        msgValue = withdrawCost + depositCost;
    }

    function estimateRebalanceMultiPositions(
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        view
        override
        returns (uint256 msgValue)
    {
        /// @dev estimate withdrawal
        SingleDirectMultiVaultStateReq memory withdrawReq =
            SingleDirectMultiVaultStateReq({ superformData: _decodeMultiVaultData(callData_) });
        (,, uint256 withdrawCost) = paymentHelper.estimateSingleDirectMultiVault(withdrawReq, false);

        /// @dev estimate deposit
        SingleDirectMultiVaultStateReq memory depositReq =
            SingleDirectMultiVaultStateReq({ superformData: _decodeMultiVaultData(rebalanceCallData_) });
        (,, uint256 depositCost) = paymentHelper.estimateSingleDirectMultiVault(depositReq, true);

        msgValue = withdrawCost + depositCost;
    }

    function estimateCrossChainRebalance(
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        view
        override
        returns (uint256 msgValue)
    {
        /// @dev estimate withdrawal
        SingleXChainSingleVaultStateReq memory withdrawReq = SingleXChainSingleVaultStateReq({
            superformData: _decodeSingleVaultData(callData_),
            dstChainId: _extractDstChainId(callData_),
            ambIds: _extractAmbIds(callData_)
        });
        (,,, uint256 withdrawalCost) = paymentHelper.estimateSingleXChainSingleVault(withdrawReq, false);

        /// @dev estimate deposit
        SingleXChainSingleVaultStateReq memory depositReq = SingleXChainSingleVaultStateReq({
            superformData: _decodeSingleVaultData(rebalanceCallData_),
            dstChainId: _extractDstChainId(rebalanceCallData_),
            ambIds: _extractAmbIds(rebalanceCallData_)
        });
        (,,, uint256 depositCost) = paymentHelper.estimateSingleXChainSingleVault(depositReq, true);

        msgValue = withdrawalCost + depositCost;
    }

    function estimateCrossChainRebalanceMulti(
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        view
        override
        returns (uint256 msgValue)
    {
        /// @dev estimate withdrawal
        SingleXChainMultiVaultStateReq memory withdrawReq = SingleXChainMultiVaultStateReq({
            superformsData: _decodeMultiVaultData(callData_),
            dstChainId: _extractDstChainId(callData_),
            ambIds: _extractAmbIds(callData_)
        });
        (,,, uint256 withdrawalCost) = paymentHelper.estimateSingleXChainMultiVault(withdrawReq, false);

        /// @dev estimate deposit
        SingleXChainMultiVaultStateReq memory depositReq = SingleXChainMultiVaultStateReq({
            superformsData: _decodeMultiVaultData(rebalanceCallData_),
            dstChainId: _extractDstChainId(rebalanceCallData_),
            ambIds: _extractAmbIds(rebalanceCallData_)
        });
        (,,, uint256 depositCost) = paymentHelper.estimateSingleXChainMultiVault(depositReq, true);

        msgValue = withdrawalCost + depositCost;
    }

    function estimateDeposit4626(bytes calldata callData_) external view override returns (uint256 msgValue) {
        SingleDirectSingleVaultStateReq memory req =
            SingleDirectSingleVaultStateReq({ superformData: _decodeSingleVaultData(callData_) });
        (,, msgValue) = paymentHelper.estimateSingleDirectSingleVault(req, true);
    }

    function estimateDeposit(bytes calldata callData_) external view override returns (uint256 msgValue) {
        SingleDirectSingleVaultStateReq memory req =
            SingleDirectSingleVaultStateReq({ superformData: _decodeSingleVaultData(callData_) });
        (,, msgValue) = paymentHelper.estimateSingleDirectSingleVault(req, true);
    }

    function estimateBatchDeposit(bytes[] calldata callData_) external view override returns (uint256 msgValue) {
        uint256 len = callData_.length;
        for (uint256 i = 0; i < len; i++) {
            SingleDirectSingleVaultStateReq memory req =
                SingleDirectSingleVaultStateReq({ superformData: _decodeSingleVaultData(callData_[i]) });
            (,, uint256 depositCost) = paymentHelper.estimateSingleDirectSingleVault(req, true);
            msgValue += depositCost;
        }
    }

    //////////////////////////////////////////////////////////////
    //                      INTERNAL FUNCTIONS                  //
    //////////////////////////////////////////////////////////////

    function _decodeSingleVaultData(bytes calldata data_) internal pure returns (SingleVaultSFData memory) {
        // Implement decoding logic based on your data structure
    }

    function _decodeMultiVaultData(bytes calldata data_) internal pure returns (MultiVaultSFData memory) {
        // Implement decoding logic based on your data structure
    }

    function _extractDstChainId(bytes calldata data_) internal pure returns (uint64) {
        // Implement logic to extract destination chain ID from calldata
    }

    function _extractAmbIds(bytes calldata data_) internal pure returns (uint8[] memory) {
        // Implement logic to extract AMB IDs from calldata
    }
}
