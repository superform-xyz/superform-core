// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";
import { DataLib } from "../../libraries/DataLib.sol";
import { Error } from "../../utils/Error.sol";
import "../../interfaces/ICoreStateRegistry.sol";
import "../../interfaces/IBaseStateRegistry.sol";
import "../../interfaces/IRescueRegistry.sol";

/// @title RescueRegistry
/// @author Zeropoint Labs
/// @dev handles propose and dispute of failed deposits rescuals
contract RescueRegistry is IRescueRegistry {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                    Constants
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyCoreStateRegistryRescuer() {
        if (!_hasRole(keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"), msg.sender)) {
            revert Error.NOT_RESCUER();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRescueRegistry
    function proposeRescueFailedDeposits(
        uint256 payloadId_,
        uint256[] memory proposedAmounts_
    )
        external
        override
        onlyCoreStateRegistryRescuer
    {
        ICoreStateRegistry coreStateReistry = ICoreStateRegistry(_getAddress(keccak256("CORE_STATE_REGISTRY")));
        IBaseStateRegistry baseStateReistry = IBaseStateRegistry(_getAddress(keccak256("CORE_STATE_REGISTRY")));
        ICoreStateRegistry.FailedDeposit memory failedDeposits_ = coreStateReistry.getFailedDeposits(payloadId_);

        if (
            failedDeposits_.superformIds.length == 0 || proposedAmounts_.length == 0
                || failedDeposits_.superformIds.length != proposedAmounts_.length
        ) {
            revert Error.INVALID_RESCUE_DATA();
        }

        if (failedDeposits_.lastProposedTimestamp != 0) {
            revert Error.RESCUE_ALREADY_PROPOSED();
        }

        (,, uint8 multi,,,) = DataLib.decodeTxInfo(baseStateReistry.payloadHeader(payloadId_));

        address refundAddress_;
        if (multi == 1) {
            refundAddress_ =
                (abi.decode(baseStateReistry.payloadBody(payloadId_), (InitMultiVaultData))).dstRefundAddress;
        } else {
            refundAddress_ =
                (abi.decode(baseStateReistry.payloadBody(payloadId_), (InitSingleVaultData))).dstRefundAddress;
        }

        /// @dev note: should set this value to dstSwapper.failedSwap().amount for interim rescue
        coreStateReistry.setFailedDeposits(payloadId_, proposedAmounts_, refundAddress_, block.timestamp);

        emit RescueProposed(payloadId_, failedDeposits_.superformIds, proposedAmounts_, block.timestamp);
    }

    /// @inheritdoc IRescueRegistry
    function disputeRescueFailedDeposits(uint256 payloadId_) external override {
        ICoreStateRegistry coreStateReistry = ICoreStateRegistry(_getAddress(keccak256("CORE_STATE_REGISTRY")));
        ICoreStateRegistry.FailedDeposit memory failedDeposits_ = coreStateReistry.getFailedDeposits(payloadId_);

        /// @dev the msg sender should be the refund address (or) the disputer
        if (
            msg.sender != failedDeposits_.refundAddress
                || !_hasRole(keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE"), msg.sender)
        ) {
            revert Error.INVALID_DISUPTER();
        }

        /// @dev the timelock is already elapsed to dispute
        if (
            failedDeposits_.lastProposedTimestamp == 0
                || block.timestamp > failedDeposits_.lastProposedTimestamp + _getDelay()
        ) {
            revert Error.DISPUTE_TIME_ELAPSED();
        }

        /// @dev just can reset last proposed time here, since amounts should be updated again to
        /// pass the lastProposedTimestamp zero check in finalize
        coreStateReistry.setFailedDeposits(payloadId_, failedDeposits_.amounts, failedDeposits_.refundAddress, 0);

        emit RescueDisputed(payloadId_);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev returns if an address has a specific role
    function _hasRole(bytes32 id_, address addressToCheck_) internal view returns (bool) {
        return ISuperRBAC(_getSuperRBAC()).hasRole(id_, addressToCheck_);
    }

    /// @dev returns the address from super registry
    function _getAddress(bytes32 id_) internal view returns (address) {
        return superRegistry.getAddress(id_);
    }

    /// @dev returns the current timelock delay
    function _getDelay() internal view returns (uint256) {
        return superRegistry.delay();
    }

    /// @dev returns the superRBAC address
    function _getSuperRBAC() internal view returns (address) {
        return _getAddress(keccak256("SUPER_RBAC"));
    }
}
