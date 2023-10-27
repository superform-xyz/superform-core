/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { DataLib } from "../libraries/DataLib.sol";
import { IBaseForm } from "../interfaces/IBaseForm.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";
import { IEmergencyQueue } from "../interfaces/IEmergencyQueue.sol";
import { Error } from "../utils/Error.sol";
import { ISuperformFactory } from "../interfaces/ISuperformFactory.sol";
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

    /*///////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier onlySuperform(uint256 superformId) {
        if (!ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).isSuperform(superformId)) {
            revert Error.SUPERFORM_ID_NONEXISTENT();
        }
        (address superform,,) = superformId.getSuperform();
        if (msg.sender != superform) revert Error.NOT_SUPERFORM();

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

    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_) {
        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

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
            srcSender_,
            data_.dstRefundAddress == address(0) ? srcSender_ : data_.dstRefundAddress,
            data_.superformId,
            data_.amount,
            data_.payloadId,
            false
        );

        emit WithdrawalQueued(
            srcSender_, data_.dstRefundAddress, queueCounter, data_.superformId, data_.amount, data_.payloadId
        );
    }

    /// @inheritdoc IEmergencyQueue
    function executeQueuedWithdrawal(uint256 id_) external override onlyEmergencyAdmin {
        _executeQueuedWithdrawal(id_);
    }

    function batchExecuteQueuedWithdrawal(uint256[] memory ids_) external override onlyEmergencyAdmin {
        for (uint256 i; i < ids_.length;) {
            _executeQueuedWithdrawal(ids_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        VIEW/HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEmergencyQueue
    function queuedWithdrawalStatus(uint256 id) external view override returns (bool) {
        return queuedWithdrawal[id].isProcessed;
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _executeQueuedWithdrawal(uint256 id_) internal {
        QueuedWithdrawal storage data = queuedWithdrawal[id_];
        if (data.superformId == 0) revert Error.EMERGENCY_WITHDRAW_NOT_QUEUED();

        if (data.isProcessed) {
            revert Error.EMERGENCY_WITHDRAW_PROCESSED_ALREADY();
        }

        data.isProcessed = true;

        (address superform,,) = data.superformId.getSuperform();
        IBaseForm(superform).emergencyWithdraw(data.srcSender, data.refundAddress, data.amount);

        emit WithdrawalProcessed(data.refundAddress, id_, data.superformId, data.amount);
    }
}
