// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

//////////////////////////////////////////////////////////////
//                          STRUCTS                          //
//////////////////////////////////////////////////////////////

struct WrapperMetadata {
    address formImplementation;
    address underlyingVaultAddress;
    address tokenIn;
    address tokenOut;
    address wrapper;
}

/// @title IERC5115To4626WrapperFactory
/// @dev Interface for 5115 to 4626 wrapper factory
/// @author ZeroPoint Labs
interface IERC5115To4626WrapperFactory {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////
    /// @notice Emitted when a new wrapper is created
    /// @param wrapper the address of the wrapper
    /// @param wrapperKey the key of the wrapper
    event WrapperCreated(address indexed wrapper, bytes32 wrapperKey);

    /// @notice Emitted when a new wrapper is created with a superform
    /// @param wrapper the address of the wrapper
    /// @param wrapperKey the key of the wrapper
    /// @param superformId the id of the superform
    /// @param superform the address of the superform
    event WrapperCreatedWithSuperform(
        address indexed wrapper, bytes32 wrapperKey, uint256 superformId, address superform
    );

    /// @notice Emitted when a superform is created for an existing wrapper
    /// @param wrapper the address of the wrapper
    /// @param wrapperKey the key of the wrapper
    /// @param superformId the id of the superform
    /// @param superform the address of the superform
    event CreatedSuperformForExistingWrapper(
        address indexed wrapper, bytes32 wrapperKey, uint256 superformId, address superform
    );

    /// @notice Emitted when a wrapper is updated with a form implementation
    /// @param wrapper the address of the wrapper
    /// @param wrapperKey the key of the wrapper
    /// @param formImplementation the address of the form implementation
    event WrapperUpdatedWithImplementation(address indexed wrapper, bytes32 wrapperKey, address formImplementation);

    //////////////////////////////////////////////////////////////
    //                          ERRORS                          //
    //////////////////////////////////////////////////////////////

    /// @notice Reverts if a wrapper already exists for the given parameters
    error WRAPPER_ALREADY_EXISTS();

    /// @notice Reverts if the wrapper does not exist
    error WRAPPER_DOES_NOT_EXIST();

    /// @notice Revert if the wrapper already has a form implementation associated with it
    error WRAPPER_ALREADY_HAS_FORM();

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL  FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice Creates a new wrapper contract without creating a superform
    /// @param underlyingVaultAddress_ the address of the underlying vault
    /// @param tokenIn_ the address of the token to be deposited
    /// @param tokenOut_ the address of the token to be withdrawn
    function createWrapper(
        address underlyingVaultAddress_,
        address tokenIn_,
        address tokenOut_
    )
        external
        returns (address wrapper);

    /// @notice Creates a new wrapper contract with a superform
    /// @param formImplementationId_ the form implementation id
    /// @param underlyingVaultAddress_ the address of the underlying vault
    /// @param tokenIn_ the address of the token to be deposited
    /// @param tokenOut_ the address of the token to be withdrawn
    function createWrapperWithSuperform(
        uint32 formImplementationId_,
        address underlyingVaultAddress_,
        address tokenIn_,
        address tokenOut_
    )
        external
        returns (address wrapper);

    /// @notice Batch creates wrappers with superforms
    /// @param formImplementationIds_ the form implementation ids
    /// @param underlyingVaultAddresses the addresses of the underlying vaults
    /// @param tokenIns the addresses of the tokens to be deposited
    /// @param tokenOuts the addresses of the tokens to be withdrawn
    function batchCreateWrappersWithSuperform(
        uint32[] calldata formImplementationIds_,
        address[] calldata underlyingVaultAddresses,
        address[] calldata tokenIns,
        address[] calldata tokenOuts
    )
        external
        returns (address[] memory wrappers_);

    /// @notice Creates a superform for an existing wrapper
    /// @param wrapperKey the key of the wrapper
    /// @param formImplementationId_ the form implementation id
    function createSuperformForWrapper(
        bytes32 wrapperKey,
        uint32 formImplementationId_
    )
        external
        returns (uint256 superformId, address superform);

    /// @notice Batch updates the form implementation of multiple wrappers
    /// @param wrapperKeys the keys of the wrappers to update
    /// @param formImplementationIds the form implementation ids
    function batchUpdateWrapperFormImplementation(
        bytes32[] calldata wrapperKeys,
        uint32[] calldata formImplementationIds
    )
        external;
}
