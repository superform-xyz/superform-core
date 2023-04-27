// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {MultiVaultsSFData, SingleVaultSFData} from "../../types/DataTypes.sol";
import {BridgeValidator} from "../BridgeValidator.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {ILiFi} from "../../interfaces/ILiFi.sol";
import {IBaseForm} from "../../interfaces/IBaseForm.sol";
import {Error} from "../../utils/Error.sol";
import "../../utils/DataPacking.sol";

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

    /// @inheritdoc BridgeValidator
    function validateTxDataDepositMultiVaultAmounts(
        MultiVaultsSFData calldata superFormsData_
    ) external view override returns (bool) {
        uint256 len = superFormsData_.amounts.length;
        uint256 liqRequestsLen = superFormsData_.liqRequests.length;

        uint256 sumAmounts;

        (address firstSuperForm, , ) = _getSuperForm(
            superFormsData_.superFormIds[0]
        );
        address collateral = address(
            IBaseForm(firstSuperForm).getUnderlyingOfVault()
        );

        if (collateral == address(0)) return false;

        for (uint256 i = 0; i < len; i++) {
            sumAmounts += superFormsData_.amounts[i];

            /// @dev compare underlyings with the first superForm. If there is at least one different mark collateral as 0
            if (collateral != address(0) && i + 1 < len) {
                (address superForm, , ) = _getSuperForm(
                    superFormsData_.superFormIds[i + 1]
                );

                if (
                    collateral !=
                    address(IBaseForm(superForm).getUnderlyingOfVault())
                ) collateral = address(0);
            }
        }

        /// @dev In multiVaults, if there is only one liqRequest, then the sum of the amounts must be equal to the amount in the liqRequest and all underlyings must be equal
        if (
            liqRequestsLen == 1 &&
            (liqRequestsLen != len) &&
            (_decodeCallData(superFormsData_.liqRequests[0].txData).minAmount ==
                sumAmounts) &&
            collateral == address(0)
        ) {
            return false;
        } else if (liqRequestsLen > 1 && collateral != address(0)) {
            /// @dev else if number of liq request >1, length must be equal to the number of superForms sent in this request (and all colaterals are different)
            if (liqRequestsLen != len) {
                return false;

                /// @dev else if number of liq request >1 and  length is equal to the number of superForms sent in this request, then all amounts in liqRequest must be equal to the amounts in superformsdata
            } else if (liqRequestsLen == len) {
                ILiFi.BridgeData memory bridgeData;

                for (uint256 i = 0; i < len; i++) {
                    bridgeData = _decodeCallData(
                        superFormsData_.liqRequests[i].txData
                    );
                    if (bridgeData.minAmount != superFormsData_.amounts[i]) {
                        return false;
                    }
                }
            }
            /// @dev else if number of liq request >1 and all colaterals are the same, then this request should be invalid (?)
            /// @notice we could allow it but would imply multiple bridging of the same tokens
        } else if (liqRequestsLen > 1 && collateral == address(0)) {
            return false;
        }

        return true;
    }

    /// @inheritdoc BridgeValidator
    function validateTxDataDepositSingleVaultAmount(
        SingleVaultSFData calldata superFormData_
    ) external view override returns (bool) {
        if (
            (_decodeCallData(superFormData_.liqRequest.txData).minAmount !=
                superFormData_.amount)
        ) {
            return false;
        }

        return true;
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(
        bytes calldata txData_,
        uint16 srcChainId_,
        uint16 dstChainId_,
        bool deposit_,
        address superForm_,
        address srcSender_,
        address liqDataToken_
    ) external view override {
        ILiFi.BridgeData memory bridgeData = _decodeCallData(txData_);

        /// @dev 1. chainId validation
        if (lifiChainId[dstChainId_] != bridgeData.destinationChainId)
            revert Error.INVALID_TXDATA_CHAIN_ID();

        /// @dev 2. receiver address validation

        if (deposit_ && srcChainId_ == dstChainId_) {
            /// @dev If same chain deposits then receiver address must be the superform

            if (bridgeData.receiver != superForm_)
                revert Error.INVALID_TXDATA_RECEIVER();
        } else if (deposit_ && srcChainId_ != dstChainId_) {
            /// @dev if cross chain deposits, then receiver address must be the token bank
            if (
                !(bridgeData.receiver == superRegistry.tokenBank() ||
                    bridgeData.receiver == superRegistry.multiTxProcessor())
            ) revert Error.INVALID_TXDATA_RECEIVER();
        } else if (!deposit_) {
            /// @dev if withdraws, then receiver address must be the srcSender
            /// @dev what if SrcSender is a contract? can it be used to re-enter somewhere?
            /// https://linear.app/superform/issue/SUP-2024/reentrancy-vulnerability-prevent-crafting-arbitrary-txdata-to-reenter
            if (bridgeData.receiver != srcSender_)
                revert Error.INVALID_TXDATA_RECEIVER();
        }

        /// @dev 3. token validations
        if (liqDataToken_ != bridgeData.sendingAssetId)
            revert Error.INVALID_TXDATA_TOKEN();
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
