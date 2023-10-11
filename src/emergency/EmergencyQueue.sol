/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import { DataLib } from "../libraries/DataLib.sol";
import { IBaseForm } from "../interfaces/IBaseForm.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";
import { IEmergencyQueue } from "../interfaces/IEmergencyQueue.sol";
import "../types/DataTypes.sol";

/// @title EmergencyQueue
/// @author Zeropoint Labs
/// @dev stores withdrawal requests when forms are paused
contract EmergencyQueue is IEmergencyQueue {
    using DataLib for uint256;

    /// @dev is the chain id
    uint64 public immutable CHAIN_ID;

    /// @dev is the address of super registry
    ISuperRegistry public immutable superRegistry;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev is the count of actions queued
    uint256 public queueCounter;

    /// @dev is the queue of pending actions
    mapping(uint256 id => QueuedWithdrawal) public queuedWithdrawal;

    /// @dev is the status of the queued action
    mapping(uint256 id => bool processed) public queuedWithdrawalStatus;

    /*///////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier onlySuperform(uint256 superformId_) {
        (address superform, uint32 formId, uint64 chainId) = superformId_.getSuperform();

        /// FIXME: add revert message here
        if (msg.sender != superform) {
            revert();
        }

        /// FIXME: add revert message here
        if (chainId != CHAIN_ID) {
            revert();
        }

        /// FIXME: add revert message here
        if (IBaseForm(superform).formImplementationId() != formId) {
            revert();
        }

        _;
    }

    modifier onlyEmergencyAdmin() {
        /// FIXME: add revert message here
        if (!ISuperRBAC(superRegistry.getAddress("SUPER_RBAC")).hasEmergencyAdminRole(msg.sender)) {
            revert();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
        CHAIN_ID = uint64(block.chainid);
    }

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEmergencyQueue
    function queueWithdrawal(
        InitSingleVaultData memory data_,
        address srcSender_
    )
        external
        override
        onlySuperform(data_.superformId)
    {
        ++queueCounter;

        queuedWithdrawal[queueCounter] = QueuedWithdrawal(
            data_.dstRefundAddress == address(0) ? srcSender_ : data_.dstRefundAddress,
            data_.superformId,
            data_.amount,
            data_.payloadId
        );

        emit WithdrawalQueued(
            srcSender_, data_.dstRefundAddress, queueCounter, data_.superformId, data_.amount, data_.payloadId
        );
    }

    /// @inheritdoc IEmergencyQueue
    function executeQueuedWithdrawal(uint256 id_) external override onlyEmergencyAdmin {
        /// FIXME: add revert message here
        if (queuedWithdrawalStatus[id_]) {
            revert();
        }

        queuedWithdrawalStatus[id_] = true;
        QueuedWithdrawal memory data = queuedWithdrawal[id_];

        (address superform,,) = data.superformId.getSuperform();
        IBaseForm(superform).emergencyWithdraw(data.refundAddress, data.amount);

        emit WithdrawalProcessed(data.refundAddress, id_, data.superformId, data.amount);
    }
}
