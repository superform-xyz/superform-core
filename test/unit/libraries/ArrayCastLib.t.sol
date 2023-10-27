// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";

import { Error } from "src/utils/Error.sol";
import { ArrayCastLib } from "src/libraries/ArrayCastLib.sol";
import { LiqRequest } from "src/types/LiquidityTypes.sol";

contract ArrayCastLibUser {
    function castLiqRequestToArray(LiqRequest memory a) external pure returns (LiqRequest[] memory) {
        return ArrayCastLib.castLiqRequestToArray(a);
    }

    function castBoolToArray(bool a) external pure returns (bool[] memory) {
        return ArrayCastLib.castBoolToArray(a);
    }
}

contract ArrayCastLibTest is Test {
    ArrayCastLibUser arrayCastLib;

    function setUp() external {
        arrayCastLib = new ArrayCastLibUser();
    }

    function test_castLiqRequestToArray() external {
        LiqRequest memory req = LiqRequest(1, "", address(0), 1, 1 wei);

        LiqRequest[] memory castedReq = arrayCastLib.castLiqRequestToArray(req);
        assertEq(castedReq.length, 1);
    }

    function test_castBoolToArray() external {
        bool value = true; 
        bool[] memory castedValue = arrayCastLib.castBoolToArray(value);
        assertEq(castedValue.length, 1);
    }
}
