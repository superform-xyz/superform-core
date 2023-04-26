// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {BridgeValidator} from "../BridgeValidator.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {ILiFi} from "../../interfaces/ILiFi.sol";
import {IBaseForm} from "../../interfaces/IBaseForm.sol";
import {Error} from "../../utils/Error.sol";

/// @title lifi verification contract
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract LiFiValidator is BridgeValidator {
    mapping(uint16 => uint256) public lifiChainId;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event ChainIdSet(uint16 superChainId, uint256 lifiChainId);

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) BridgeValidator(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    function validateTxData(
        bytes calldata txData_,
        uint16 srcChainId_,
        uint16 dstChainId_,
        bool deposit_,
        address superForm_,
        address srcSender_
    ) external view override returns (bool) {
        ILiFi.BridgeData memory bridgeData = _decodeCallData(txData_);

        /// @dev 1. chainId validation
        if (lifiChainId[dstChainId_] != bridgeData.destinationChainId)
            revert Error.INVALID_CHAIN_ID();

        /// @dev 2. receiver address validation

        if (deposit_ && srcChainId_ == dstChainId_) {
            /// @dev If action is same chain or cross chain withdraw, then receiver address must be the superform

            if (bridgeData.receiver != superForm_)
                revert Error.INVALID_RECEIVER();
        } else if (deposit_ && srcChainId_ != dstChainId_) {
            /// @dev if cross chain deposits, then receiver address must be the token bank
            if (
                !(bridgeData.receiver == superRegistry.tokenBank() ||
                    bridgeData.receiver == superRegistry.multiTxProcessor())
            ) revert Error.INVALID_RECEIVER();
        } else if (!deposit_) {
            /// @dev what if SrcSender is a contract? can it be used to re-enter somewhere?
            /// https://linear.app/superform/issue/SUP-2024/reentrancy-vulnerability-prevent-crafting-arbitrary-txdata-to-reenter
            if (bridgeData.receiver != srcSender_)
                revert Error.INVALID_RECEIVER();
        }

        return true;
    }

    /// @dev allows admin to add new chain ids in future
    /// @param superChainIds_ is the identifier of the chain within superform protocol
    /// @param lifiChainIds_ is the identifier of the chain given by the bridge
    function setChainIds(
        uint16[] memory superChainIds_,
        uint256[] memory lifiChainIds_
    ) external onlyProtocolAdmin {
        for (uint256 i = 0; i < superChainIds_.length; i++) {
            uint16 superChainIdT = superChainIds_[i];
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
    ) internal pure returns (ILiFi.BridgeData memory bridgeData) {
        (bridgeData) = abi.decode(data[4:], (ILiFi.BridgeData));
    }
}
