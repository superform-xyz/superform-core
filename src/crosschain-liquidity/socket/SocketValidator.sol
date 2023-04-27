// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {MultiVaultsSFData, SingleVaultSFData} from "../../types/DataTypes.sol";
import {BridgeValidator} from "../BridgeValidator.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {ISocketRegistry} from "../../interfaces/ISocketRegistry.sol";
import {IBaseForm} from "../../interfaces/IBaseForm.sol";
import {Error} from "../../utils/Error.sol";
import "../../utils/DataPacking.sol";

/// @title Socket verification contract
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract SocketValidator is BridgeValidator {
    mapping(uint16 => uint256) public socketChainId;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event ChainIdSet(uint16 superChainId, uint256 socketChainId);

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
            (_decodeCallData(superFormsData_.liqRequests[0].txData).amount ==
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
                ISocketRegistry.UserRequest memory userRequest;

                for (uint256 i = 0; i < len; i++) {
                    userRequest = _decodeCallData(
                        superFormsData_.liqRequests[i].txData
                    );
                    if (userRequest.amount != superFormsData_.amounts[i]) {
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
            (_decodeCallData(superFormData_.liqRequest.txData).amount !=
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
        address srcSender_
    ) external view override {
        ISocketRegistry.UserRequest memory userRequest = _decodeCallData(
            txData_
        );

        /// @dev 1. chainId validation
        if (socketChainId[dstChainId_] != userRequest.toChainId)
            revert Error.INVALID_CHAIN_ID();

        /// @dev 2. receiver address validation

        if (deposit_ && srcChainId_ == dstChainId_) {
            /// @dev If action is same chain or cross chain withdraw, then receiver address must be the superform

            if (userRequest.receiverAddress != superForm_)
                revert Error.INVALID_RECEIVER();
        } else if (deposit_ && srcChainId_ != dstChainId_) {
            /// @dev if cross chain deposits, then receiver address must be the token bank
            if (
                !(userRequest.receiverAddress == superRegistry.tokenBank() ||
                    userRequest.receiverAddress ==
                    superRegistry.multiTxProcessor())
            ) revert Error.INVALID_RECEIVER();
        } else if (!deposit_) {
            /// @dev what if SrcSender is a contract? can it be used to re-enter somewhere?
            /// https://linear.app/superform/issue/SUP-2024/reentrancy-vulnerability-prevent-crafting-arbitrary-txdata-to-reenter
            if (userRequest.receiverAddress != srcSender_)
                revert Error.INVALID_RECEIVER();
        }
    }

    /// @dev allows admin to add new chain ids in future
    /// @param superChainIds_ is the identifier of the chain within superform protocol
    /// @param socketChainIds_ is the identifier of the chain given by the bridge
    function setChainIds(
        uint16[] memory superChainIds_,
        uint256[] memory socketChainIds_
    ) external onlyProtocolAdmin {
        for (uint256 i = 0; i < superChainIds_.length; i++) {
            uint16 superChainIdT = superChainIds_[i];
            uint256 socketChainIdT = socketChainIds_[i];
            if (superChainIdT == 0 || socketChainIdT == 0) {
                revert Error.INVALID_CHAIN_ID();
            }

            socketChainId[superChainIdT] = socketChainIdT;

            emit ChainIdSet(superChainIdT, socketChainIdT);
        }
    }

    /// @notice Decode the socket v2 calldata
    /// @param data Socket V2 outboundTransferTo call data
    /// @return userRequest socket UserRequest
    function _decodeCallData(
        bytes calldata data
    ) internal pure returns (ISocketRegistry.UserRequest memory userRequest) {
        (userRequest) = abi.decode(data[4:], (ISocketRegistry.UserRequest));
    }
}
