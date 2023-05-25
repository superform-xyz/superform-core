// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {MultiVaultsSFData, SingleVaultSFData} from "../../types/DataTypes.sol";
import {BridgeValidator} from "../BridgeValidator.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {ILiFi} from "../../vendor/lifi/ILiFi.sol";
import {IBaseForm} from "../../interfaces/IBaseForm.sol";
import {Error} from "../../utils/Error.sol";
import "../../utils/DataPacking.sol";

/// @title lifi verification contract
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract LiFiValidator is BridgeValidator {
    mapping(uint64 => uint256) public lifiChainId;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event ChainIdSet(uint64 superChainId, uint256 lifiChainId);

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) BridgeValidator(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BridgeValidator
    function validateTxDataAmount(bytes calldata txData_, uint256 amount_) external pure override returns (bool) {
        (ILiFi.BridgeData memory bridgeData, ) = _decodeCallData(txData_);

        if ((bridgeData.minAmount != amount_)) {
            return false;
        }

        return true;
    }

    /// @inheritdoc BridgeValidator
    /// @dev FIXME: do we want to disable destination calls?
    function validateTxData(
        bytes calldata txData_,
        uint64 srcChainId_,
        uint64 dstChainId_,
        bool deposit_,
        address superForm_,
        address srcSender_,
        address liqDataToken_
    ) external view override {
        (ILiFi.BridgeData memory bridgeData, ILiFi.SwapData[] memory swapData) = _decodeCallData(txData_);

        address sendingAssetId;
        if (bridgeData.hasSourceSwaps) {
            sendingAssetId = swapData[0].sendingAssetId;
        } else {
            sendingAssetId = bridgeData.sendingAssetId;
        }

        /// @dev 1. chainId validation
        if (lifiChainId[dstChainId_] != bridgeData.destinationChainId) revert Error.INVALID_TXDATA_CHAIN_ID();

        /// @dev 2. receiver address validation

        if (deposit_ && srcChainId_ == dstChainId_) {
            /// @dev If same chain deposits then receiver address must be the superform

            if (bridgeData.receiver != superForm_) revert Error.INVALID_TXDATA_RECEIVER();
        } else if (deposit_ && srcChainId_ != dstChainId_) {
            /// @dev if cross chain deposits, then receiver address must be the token bank
            if (
                !(bridgeData.receiver == superRegistry.coreStateRegistry() ||
                    bridgeData.receiver == superRegistry.multiTxProcessor())
            ) revert Error.INVALID_TXDATA_RECEIVER();
        } else if (!deposit_) {
            /// @dev if withdraws, then receiver address must be the srcSender
            /// @dev what if SrcSender is a contract? can it be used to re-enter somewhere?
            /// https://linear.app/superform/issue/SUP-2024/reentrancy-vulnerability-prevent-crafting-arbitrary-txdata-to-reenter
            if (bridgeData.receiver != srcSender_) revert Error.INVALID_TXDATA_RECEIVER();
        }

        /// @dev 3. token validations
        if (liqDataToken_ != sendingAssetId) revert Error.INVALID_TXDATA_TOKEN();
    }

    /// @dev allows admin to add new chain ids in future
    /// @param superChainIds_ is the identifier of the chain within superform protocol
    /// @param lifiChainIds_ is the identifier of the chain given by the bridge
    function setChainIds(uint64[] memory superChainIds_, uint256[] memory lifiChainIds_) external onlyProtocolAdmin {
        for (uint256 i = 0; i < superChainIds_.length; i++) {
            uint64 superChainIdT = superChainIds_[i];
            uint256 lifiChainIdT = lifiChainIds_[i];
            if (superChainIdT == 0 || lifiChainIdT == 0) {
                revert Error.INVALID_CHAIN_ID();
            }

            lifiChainId[superChainIdT] = lifiChainIdT;

            emit ChainIdSet(superChainIdT, lifiChainIdT);
        }
    }

    /// @notice Decode lifi's calldata
    /// @param data LiFi call data
    /// @return bridgeData LiFi BridgeData
    function _decodeCallData(
        bytes calldata data
    ) internal pure returns (ILiFi.BridgeData memory bridgeData, ILiFi.SwapData[] memory swapData) {
        (bridgeData) = abi.decode(data[4:], (ILiFi.BridgeData));

        if (bridgeData.hasSourceSwaps) {
            (, swapData) = abi.decode(data[4:], (ILiFi.BridgeData, ILiFi.SwapData[]));
        }
    }
}
