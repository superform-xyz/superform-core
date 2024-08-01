// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/ProtocolActions.sol";
import { ERC5115To4626WrapperFactory } from "src/forms/wrappers/ERC5115To4626WrapperFactory.sol";
import { IERC5115To4626WrapperFactory } from "src/forms/interfaces/IERC5115To4626WrapperFactory.sol";
import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";
import { Error } from "src/libraries/Error.sol";

// Mock contract to simulate a 5115 vault
contract Mock5115Vault {
    address public constant asset = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    function isValidTokenIn(address) external pure returns (bool isValid) {
        isValid = true;
    }

    function isValidTokenOut(address) external pure returns (bool isValid) {
        isValid = true;
    }
}

contract ERC5115To4626WrapperTest is ProtocolActions {
    uint64 internal chainId = ARBI;
    uint32 FORM_ID = 4;

    ERC5115To4626WrapperFactory wrapperFactory;
    SuperRegistry superRegistry;
    SuperRBAC superRBAC;

    Mock5115Vault mockVault;
    address tokenIn = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address tokenIn2 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address tokenOut = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    function setUp() public override {
        super.setUp();

        vm.selectFork(FORKS[chainId]);
        superRegistry = SuperRegistry(getContract(chainId, "SuperRegistry"));
        superRBAC = SuperRBAC(getContract(chainId, "SuperRBAC"));
        wrapperFactory = ERC5115To4626WrapperFactory(getContract(chainId, "ERC5115To4626WrapperFactory"));

        mockVault = new Mock5115Vault();
    }

    /// Test constructor validation
    /// This test verifies if constructor validates input
    function test_constructorValidations() public {
        vm.expectRevert(Error.ZERO_ADDRESS.selector);
        new ERC5115To4626WrapperFactory(address(0));
    }

    // Test creating a wrapper
    // This test verifies that a wrapper can be created successfully and its details are stored correctly
    function test_CreateWrapper() public {
        address wrapper = wrapperFactory.createWrapper(address(mockVault), tokenIn, tokenOut);

        bytes32 wrapperKey = keccak256(abi.encodePacked(address(mockVault), tokenIn, tokenOut));
        (
            address formImpl,
            address underlyingVault,
            address wrapperTokenIn,
            address wrapperTokenOut,
            address wrapperAddr
        ) = wrapperFactory.wrappers(wrapperKey);

        assertEq(formImpl, address(0));
        assertEq(underlyingVault, address(mockVault));
        assertEq(wrapperTokenIn, tokenIn);
        assertEq(wrapperTokenOut, tokenOut);
        assertEq(wrapperAddr, wrapper);
    }

    // Test creating a duplicate wrapper
    // This test ensures that attempting to create a duplicate wrapper results in a revert
    function test_CreateWrapperDuplicate() public {
        wrapperFactory.createWrapper(address(mockVault), tokenIn, tokenOut);

        vm.expectRevert(IERC5115To4626WrapperFactory.WRAPPER_ALREADY_EXISTS.selector);
        wrapperFactory.createWrapper(address(mockVault), tokenIn, tokenOut);
    }

    // Test creating a wrapper with a superform
    // This test verifies that a wrapper can be created with an associated superform
    function test_CreateWrapperWithSuperform() public {
        address wrapper = wrapperFactory.createWrapperWithSuperform(FORM_ID, address(mockVault), tokenIn, tokenOut);

        vm.expectRevert(IERC5115To4626WrapperFactory.WRAPPER_ALREADY_EXISTS.selector);
        wrapperFactory.createWrapperWithSuperform(FORM_ID, address(mockVault), tokenIn, tokenOut);

        vm.expectRevert(Error.FORM_DOES_NOT_EXIST.selector);
        wrapperFactory.createWrapperWithSuperform(420, address(120), tokenIn, tokenOut);

        bytes32 wrapperKey = keccak256(abi.encodePacked(address(mockVault), tokenIn, tokenOut));

        (
            address formImpl,
            address underlyingVault,
            address wrapperTokenIn,
            address wrapperTokenOut,
            address wrapperAddr
        ) = wrapperFactory.wrappers(wrapperKey);

        assertEq(formImpl, getContract(chainId, "ERC5115Form"));
        assertEq(underlyingVault, address(mockVault));
        assertEq(wrapperTokenIn, tokenIn);
        assertEq(wrapperTokenOut, tokenOut);
        assertEq(wrapperAddr, wrapper);
    }

    function test_BatchCreateWrapperWithSuperform() public {
        address[] memory tokensIn = new address[](1);
        tokensIn[0] = tokenIn;

        address[] memory tokensOut = new address[](2);
        tokensOut[0] = tokenOut;
        tokensOut[1] = tokenOut;

        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);
        wrapperFactory.batchCreateWrappersWithSuperform(FORM_ID, address(mockVault), tokensIn, tokensOut);

        tokensIn = new address[](2);
        tokensIn[0] = tokenIn;
        tokensIn[1] = tokenIn2;

        address[] memory wrappers =
            wrapperFactory.batchCreateWrappersWithSuperform(FORM_ID, address(mockVault), tokensIn, tokensOut);

        bytes32 wrapperKeys1 = keccak256(abi.encodePacked(address(mockVault), tokenIn, tokenOut));
        bytes32 wrapperKeys2 = keccak256(abi.encodePacked(address(mockVault), tokenIn2, tokenOut));

        address formImpl;
        address underlyingVault;
        address wrapperTokenIn;
        address wrapperTokenOut;
        address wrapperAddr;

        (formImpl, underlyingVault, wrapperTokenIn, wrapperTokenOut, wrapperAddr) =
            wrapperFactory.wrappers(wrapperKeys1);

        assertEq(formImpl, getContract(chainId, "ERC5115Form"));
        assertEq(underlyingVault, address(mockVault));
        assertEq(wrapperTokenIn, tokenIn);
        assertEq(wrapperTokenOut, tokenOut);
        assertEq(wrapperAddr, wrappers[0]);

        (formImpl, underlyingVault, wrapperTokenIn, wrapperTokenOut, wrapperAddr) =
            wrapperFactory.wrappers(wrapperKeys2);

        assertEq(formImpl, getContract(chainId, "ERC5115Form"));
        assertEq(underlyingVault, address(mockVault));
        assertEq(wrapperTokenIn, tokenIn2);
        assertEq(wrapperTokenOut, tokenOut);
        assertEq(wrapperAddr, wrappers[1]);
    }

    // Test creating a superform for an existing wrapper
    // This test checks if a superform can be created for a wrapper that already exists
    function test_CreateSuperformForWrapper() public {
        address wrapper = wrapperFactory.createWrapper(address(mockVault), tokenIn, tokenOut);
        bytes32 wrapperKey = keccak256(abi.encodePacked(address(mockVault), tokenIn, tokenOut));

        bytes32 invalidWrapperKey = keccak256(abi.encodePacked(address(mockVault), tokenOut, tokenIn));
        vm.expectRevert(IERC5115To4626WrapperFactory.WRAPPER_DOES_NOT_EXIST.selector);
        wrapperFactory.createSuperformForWrapper(invalidWrapperKey, FORM_ID);

        vm.expectRevert(Error.FORM_DOES_NOT_EXIST.selector);
        wrapperFactory.createSuperformForWrapper(wrapperKey, 420);

        (uint256 superformId, address superform) = wrapperFactory.createSuperformForWrapper(wrapperKey, FORM_ID);

        assert(wrapper != address(0));
        assert(superformId != 0);
        assert(superform != address(0));
    }

    // Test batch updating wrapper form implementations
    // This test verifies that multiple wrapper form implementations can be updated in a single transaction
    function test_BatchUpdateWrapperFormImplementation() public {
        address wrapper1 = wrapperFactory.createWrapperWithSuperform(FORM_ID, address(mockVault), tokenIn, tokenOut);
        address wrapper2 = wrapperFactory.createWrapperWithSuperform(FORM_ID, address(mockVault), tokenOut, tokenIn);

        bytes32 wrapperKey1 = keccak256(abi.encodePacked(address(mockVault), tokenIn, tokenOut));
        bytes32 wrapperKey2 = keccak256(abi.encodePacked(address(mockVault), tokenOut, tokenIn));

        bytes32[] memory wrapperKeys = new bytes32[](2);
        wrapperKeys[0] = wrapperKey1;
        wrapperKeys[1] = wrapperKey2;

        uint32[] memory formImplementationIds = new uint32[](2);
        formImplementationIds[0] = 1;
        formImplementationIds[1] = 2;

        (address formImpl1BeforeUpdate,,,,) = wrapperFactory.wrappers(wrapperKey1);
        (address formImpl2BeforeUpdate,,,,) = wrapperFactory.wrappers(wrapperKey2);

        vm.expectRevert(Error.NOT_EMERGENCY_ADMIN.selector);
        wrapperFactory.batchUpdateWrapperFormImplementation(wrapperKeys, formImplementationIds);

        vm.prank(deployer);
        wrapperFactory.batchUpdateWrapperFormImplementation(wrapperKeys, formImplementationIds);

        bytes32[] memory wrapperKeysInvalidLen = new bytes32[](1);

        vm.prank(deployer);
        vm.expectRevert(Error.ARRAY_LENGTH_MISMATCH.selector);
        wrapperFactory.batchUpdateWrapperFormImplementation(wrapperKeysInvalidLen, formImplementationIds);

        vm.prank(deployer);
        formImplementationIds[0] = 420;
        vm.expectRevert(Error.FORM_DOES_NOT_EXIST.selector);
        wrapperFactory.batchUpdateWrapperFormImplementation(wrapperKeys, formImplementationIds);

        vm.prank(deployer);
        wrapperKeys[0] = keccak256(abi.encodePacked(address(mockVault), address(0), tokenIn));
        vm.expectRevert(IERC5115To4626WrapperFactory.WRAPPER_DOES_NOT_EXIST.selector);
        wrapperFactory.batchUpdateWrapperFormImplementation(wrapperKeys, formImplementationIds);

        (address formImpl1AfterUpdate,,,,) = wrapperFactory.wrappers(wrapperKey1);
        (address formImpl2AfterUpdate,,,,) = wrapperFactory.wrappers(wrapperKey2);

        assert(formImpl1AfterUpdate != formImpl1BeforeUpdate);
        assert(formImpl2AfterUpdate != formImpl2BeforeUpdate);

        assert(wrapper1 != address(0));
        assert(wrapper2 != address(0));
    }
}
