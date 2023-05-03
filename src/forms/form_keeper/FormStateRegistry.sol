// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperRBAC} from "../../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IERC4626Timelock} from ".././interfaces/IERC4626Timelock.sol";
import {Error} from "../../utils/Error.sol";
import "../../utils/DataPacking.sol";

contract FormStateRegistry {

    mapping(uint256 payloadId => uint256 superFormId) public payloadStore;

    bytes32 public constant TOKEN_BANK_ROLE = keccak256("FORM_KEEPER_ROLE");

    ISuperRegistry public superRegistry;

    modifier onlyFormKeeper() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasFormStateRegistryRole(msg.sender)
        ) revert Error.NOT_FORM_KEEPER();
        _;
    }

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    function receivePayload(uint256 payloadId, uint256 superFormId) external onlyFormKeeper {
        payloadStore[payloadId] = superFormId;
    }

    function initPayload(uint256 payloadId) external onlyFormKeeper {
        (address form_, , ) = _getSuperForm(payloadStore[payloadId]);
        IERC4626Timelock(form_).processUnlock(payloadId);
        delete payloadStore[payloadId];
    }

}
