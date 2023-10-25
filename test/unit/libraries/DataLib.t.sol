// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";

import { Error } from "src/utils/Error.sol";
import { DataLib } from "src/libraries/DataLib.sol";

contract DataLibUser {
    function packSuperform(address a, uint32 b, uint64 c) external pure returns (uint256) {
        return DataLib.packSuperform(a, b, c);
    }
}

contract DataLibTest is Test {
    DataLibUser dataLib;

    function setUp() external {
        dataLib = new DataLibUser();
    }

    function test_packSuperform() external {
        /// generates the exp superform id with shift
        uint256 superformId = _legacySuperformPackWithShift();

        /// check if the assembly based superform generation is good
        uint256 newSuperformId = dataLib.packSuperform(address(111), 1, 1);
        assertEq(superformId, newSuperformId);
    }

    function _legacySuperformPackWithShift() internal pure returns (uint256 superformId_) {
        address superform_ = address(111);
        uint32 formImplementationId_ = 1;
        uint64 chainId_ = 1;

        superformId_ = uint256(uint160(superform_));
        superformId_ |= uint256(formImplementationId_) << 160;
        superformId_ |= uint256(chainId_) << 192;
    }
}
