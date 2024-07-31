// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IERC5115To4626WrapperFactory, WrapperMetadata } from "../interfaces/IERC5115To4626WrapperFactory.sol";
import "./ERC5115To4626Wrapper.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { Error } from "src/libraries/Error.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";

contract ERC5115To4626WrapperFactory is IERC5115To4626WrapperFactory {
    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    mapping(bytes32 wrapperKey => WrapperMetadata metadata) public wrappers;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyEmergencyAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasEmergencyAdminRole(msg.sender)) {
            revert Error.NOT_EMERGENCY_ADMIN();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_) {
        if (superRegistry_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);
        superRegistry = ISuperRegistry(superRegistry_);
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL  FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IERC5115To4626WrapperFactory
    function createWrapper(
        address underlyingVaultAddress_,
        address tokenIn_,
        address tokenOut_
    )
        external
        override
        returns (address wrapper)
    {
        bytes32 wrapperKey = keccak256(abi.encodePacked(underlyingVaultAddress_, tokenIn_, tokenOut_));

        WrapperMetadata storage metadata = wrappers[wrapperKey];
        if (metadata.wrapper != address(0)) revert WRAPPER_ALREADY_EXISTS();

        wrapper = address(new ERC5115To4626Wrapper(underlyingVaultAddress_, tokenIn_, tokenOut_));

        metadata.formImplementation = address(0);
        metadata.underlyingVaultAddress = underlyingVaultAddress_;
        metadata.tokenIn = tokenIn_;
        metadata.tokenOut = tokenOut_;
        metadata.wrapper = wrapper;

        emit WrapperCreated(wrapper, wrapperKey);
    }

    /// @inheritdoc IERC5115To4626WrapperFactory
    function createWrapperWithSuperform(
        uint32 formImplementationId_,
        address underlyingVaultAddress_,
        address tokenIn_,
        address tokenOut_
    )
        external
        override
        returns (address wrapper)
    {
        wrapper = _createWrapperWithSuperform(formImplementationId_, underlyingVaultAddress_, tokenIn_, tokenOut_);
    }

    /// @inheritdoc IERC5115To4626WrapperFactory
    function batchCreateWrapperWithSuperform(
        uint32[] calldata formImplementationIds_,
        address[] calldata underlyingVaultAddresses,
        address[] calldata tokenIns,
        address[] calldata tokenOuts
    )
        external
        override
        returns (address[] memory wrappers_)
    {
        uint256 len = underlyingVaultAddresses.length;

        if (
            len != tokenIns.length || tokenIns.length != tokenOuts.length
                || tokenOuts.length != formImplementationIds_.length
        ) {
            revert Error.ARRAY_LENGTH_MISMATCH();
        }

        wrappers_ = new address[](len);
        for (uint256 i; i < len; i++) {
            wrappers_[i] = _createWrapperWithSuperform(
                formImplementationIds_[i], underlyingVaultAddresses[i], tokenIns[i], tokenOuts[i]
            );
        }
    }

    /// @inheritdoc IERC5115To4626WrapperFactory
    function createSuperformForWrapper(
        bytes32 wrapperKey,
        uint32 formImplementationId_
    )
        external
        override
        returns (uint256 superformId, address superform)
    {
        WrapperMetadata storage metadata = wrappers[wrapperKey];

        if (metadata.wrapper == address(0)) revert WRAPPER_DOES_NOT_EXIST();
        ISuperformFactory sf = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")));

        address formImplementation = sf.getFormImplementation(formImplementationId_);
        if (formImplementation == address(0)) revert Error.FORM_DOES_NOT_EXIST();

        if (metadata.formImplementation != address(0)) revert WRAPPER_ALREADY_HAS_FORM();
        metadata.formImplementation = formImplementation;

        (superformId, superform) = sf.createSuperform(formImplementationId_, metadata.wrapper);
        emit CreatedSuperformForExistingWrapper(metadata.wrapper, wrapperKey, superformId, superform);
    }

    /// @inheritdoc IERC5115To4626WrapperFactory
    function batchUpdateWrapperFormImplementation(
        bytes32[] calldata wrapperKeys,
        uint32[] calldata formImplementationIds
    )
        external
        override
        onlyEmergencyAdmin
    {
        if (wrapperKeys.length != formImplementationIds.length) revert Error.ARRAY_LENGTH_MISMATCH();
        ISuperformFactory sf = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")));

        address newFormImpl;
        for (uint256 i = 0; i < wrapperKeys.length; i++) {
            WrapperMetadata storage metadata = wrappers[wrapperKeys[i]];

            if (metadata.formImplementation == address(0)) revert WRAPPER_DOES_NOT_EXIST();

            newFormImpl = sf.getFormImplementation(formImplementationIds[i]);
            if (newFormImpl == address(0)) revert Error.FORM_DOES_NOT_EXIST();

            metadata.formImplementation = newFormImpl;

            emit WrapperUpdatedWithImplementation(metadata.wrapper, wrapperKeys[i], newFormImpl);
        }
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL  FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    function _createWrapperWithSuperform(
        uint32 formImplementationId_,
        address underlyingVaultAddress_,
        address tokenIn_,
        address tokenOut_
    )
        internal
        returns (address wrapper)
    {
        bytes32 wrapperKey = keccak256(abi.encodePacked(underlyingVaultAddress_, tokenIn_, tokenOut_));

        WrapperMetadata storage metadata = wrappers[wrapperKey];
        if (metadata.wrapper != address(0)) revert WRAPPER_ALREADY_EXISTS();

        ISuperformFactory sf = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")));

        address formImplementation = sf.getFormImplementation(formImplementationId_);
        if (formImplementation == address(0)) revert Error.FORM_DOES_NOT_EXIST();

        wrapper = address(new ERC5115To4626Wrapper(underlyingVaultAddress_, tokenIn_, tokenOut_));

        metadata.formImplementation = formImplementation;
        metadata.underlyingVaultAddress = underlyingVaultAddress_;
        metadata.tokenIn = tokenIn_;
        metadata.tokenOut = tokenOut_;
        metadata.wrapper = wrapper;

        (uint256 superformId, address superform) = sf.createSuperform(formImplementationId_, wrapper);

        emit WrapperCreatedWithSuperform(wrapper, wrapperKey, superformId, superform);
    }
}
