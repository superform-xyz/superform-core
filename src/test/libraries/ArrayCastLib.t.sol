// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {Error} from "../../utils/Error.sol";
import {ArrayCastLib} from "../../libraries/ArrayCastLib.sol";
import {LiqRequest} from "../../types/LiquidityTypes.sol";

contract ArrayCastLibUser {
    function castToArray(LiqRequest memory a) external pure returns (LiqRequest[] memory) {
        return ArrayCastLib.castToArray(a);
    }
}

contract ArrayCastLibTest is Test {
    ArrayCastLibUser arrayCastLib;

    function setUp() external {
        arrayCastLib = new ArrayCastLibUser();
    }

    function test_castLiqRequestToArray() external {
        LiqRequest memory req = LiqRequest(1, "", address(0), 100, 1 wei, "");

        LiqRequest[] memory castedReq = arrayCastLib.castToArray(req);
        assertEq(castedReq.length, 1);
    }
}
