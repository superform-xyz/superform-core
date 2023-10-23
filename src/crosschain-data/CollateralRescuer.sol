// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { DataLib } from "../libraries/DataLib.sol";
import { Error } from "../utils/Error.sol";
import "../interfaces/ICoreStateRegistry.sol";
import "../interfaces/IBaseStateRegistry.sol";
import "../interfaces/ICollateralRescuer.sol";

/// @title CollateralRescuer
/// @author Zeropoint Labs
/// @dev handles propose and dispute of failed deposits rescuals
contract CollateralRescuer is ICollateralRescuer {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                    Constants
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev just stores the superformIds that failed in a specific payload id
    mapping(uint256 payloadId => FailedDeposit) internal failedDeposits;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyCoreStateRegistryRescuer() {
        if (!_hasRole(keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"), msg.sender)) {
            revert Error.NOT_RESCUER();
        }
        _;
    }

    modifier onlyCoreStateRegistry() {
        if (msg.sender != superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY"))) {
            revert Error.NOT_CORE_STATE_REGISTRY();
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

    /// @inheritdoc ICollateralRescuer
    function proposeRescueFailedDeposits(
        uint256 payloadId_,
        uint256[] memory proposedAmounts_
    )
        external
        override
        onlyCoreStateRegistryRescuer
    {
        IBaseStateRegistry baseStateRegistry = IBaseStateRegistry(_getAddress(keccak256("CORE_STATE_REGISTRY")));
        FailedDeposit memory failedDeposits_ = failedDeposits[payloadId_];

        if (
            failedDeposits_.superformIds.length == 0 || proposedAmounts_.length == 0
                || failedDeposits_.superformIds.length != proposedAmounts_.length
        ) {
            revert Error.INVALID_RESCUE_DATA();
        }

        if (failedDeposits_.lastProposedTimestamp != 0) {
            revert Error.RESCUE_ALREADY_PROPOSED();
        }

        /// @dev note: should set this value to dstSwapper.failedSwap().amount for interim rescue
        failedDeposits[payloadId_].amounts = proposedAmounts_;
        failedDeposits[payloadId_].lastProposedTimestamp = block.timestamp;

        (,, uint8 multi,,,) = DataLib.decodeTxInfo(baseStateRegistry.payloadHeader(payloadId_));

        address refundAddress_;
        if (multi == 1) {
            refundAddress_ =
                (abi.decode(baseStateRegistry.payloadBody(payloadId_), (InitMultiVaultData))).dstRefundAddress;
        } else {
            refundAddress_ =
                (abi.decode(baseStateRegistry.payloadBody(payloadId_), (InitSingleVaultData))).dstRefundAddress;
        }

        failedDeposits[payloadId_].refundAddress = refundAddress_;

        emit RescueProposed(payloadId_, failedDeposits_.superformIds, proposedAmounts_, block.timestamp);
    }

    /// @inheritdoc ICollateralRescuer
    function disputeRescueFailedDeposits(uint256 payloadId_) external override {
        FailedDeposit memory failedDeposits_ = failedDeposits[payloadId_];

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
        failedDeposits[payloadId_].lastProposedTimestamp = 0;

        emit RescueDisputed(payloadId_);
    }

    /// @inheritdoc ICollateralRescuer
    function addFailedDeposit(uint256 payloadId_, uint256 superformId_) external override onlyCoreStateRegistry {
        /// @dev payloadId_ validations done in CoreStateRegistry, and superformId_ is derived from payloadId_
        failedDeposits[payloadId_].superformIds.push(superformId_);
    }

    /// @inheritdoc ICollateralRescuer
    function deleteFailedDeposits(uint256 payloadId_) external override onlyCoreStateRegistry {
        delete failedDeposits[payloadId_];
    }

    /// @inheritdoc ICollateralRescuer
    function getFailedDeposits(uint256 payloadId_) external view override returns (FailedDeposit memory) {
        return failedDeposits[payloadId_];
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
