/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import { DataLib } from "../libraries/DataLib.sol";
import { IBaseForm } from "../interfaces/IBaseForm.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";
import "../types/DataTypes.sol";

/// @title EmergencyQueue
/// @author Zeropoint Labs
/// @dev stores withdrawal requests when forms are paused
contract EmergencyQueue {
    using DataLib for uint256;

    struct QueuedWithdrawal {
        address refundAddress;
        uint256 superformId;
        uint256 amount;
        uint256 srcPayloadId;
    }

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev is the chain id
    uint64 public immutable CHAIN_ID;

    /// @dev is the address of super registry
    ISuperRegistry public immutable superRegistry;

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
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event WithdrawalQueued(
        address indexed srcAddress,
        address indexed refundAddress,
        uint256 indexed id,
        uint256 superformId,
        uint256 amount,
        uint256 srcPayloadId
    );

    event WithdrawalProcessed(address indexed refundAddress, uint256 indexed id, uint256 superformId, uint256 amount);

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

    /// @dev called by paused forms to queue up withdrawals for exit
    /// @param data_ is the single vault data passed by the user
    function queueWithdrawal(
        InitSingleVaultData memory data_,
        address srcSender
    )
        external
        onlySuperform(data_.superformId)
    {
        ++queueCounter;

        queuedWithdrawal[queueCounter] = QueuedWithdrawal(
            data_.dstRefundAddress == address(0) ? srcSender : data_.dstRefundAddress,
            data_.superformId,
            data_.amount,
            data_.payloadId
        );

        emit WithdrawalQueued(
            srcSender, data_.dstRefundAddress, queueCounter, data_.superformId, data_.amount, data_.payloadId
        );
    }

    function executeQueuedWithdrawal(uint256 id) external onlyEmergencyAdmin {
        /// FIXME: add revert message here
        if (queuedWithdrawalStatus[id]) {
            revert();
        }

        queuedWithdrawalStatus[id] = true;
        QueuedWithdrawal memory data = queuedWithdrawal[id];

        (address superform,,) = data.superformId.getSuperform();
        IBaseForm(superform).emergencyWithdraw(data.refundAddress, data.amount);

        emit WithdrawalProcessed(data.refundAddress, id, data.superformId, data.amount);
    }
}
