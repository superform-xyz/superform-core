// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import { ArrayCastLib } from "src/libraries/ArrayCastLib.sol";
import { InitSingleVaultData, InitMultiVaultData, LiqRequest } from "src/types/DataTypes.sol";

contract ArrayCastLibUser {
    function castLiqRequestToArray(LiqRequest memory a) external pure returns (LiqRequest[] memory) {
        return ArrayCastLib.castLiqRequestToArray(a);
    }

    function castBoolToArray(bool a) external pure returns (bool[] memory) {
        return ArrayCastLib.castBoolToArray(a);
    }

    function castToMultiVaultData(InitSingleVaultData memory a)
        external
        pure
        returns (InitMultiVaultData memory castedData_)
    {
        return ArrayCastLib.castToMultiVaultData(a);
    }
}

contract ArrayCastLibTest is Test {
    ArrayCastLibUser arrayCastLib;

    function setUp() external {
        arrayCastLib = new ArrayCastLibUser();
    }

    function test_castLiqRequestToArray() external {
        LiqRequest memory req = LiqRequest("", address(0), address(0), 1, 1, 1 wei);

        LiqRequest[] memory castedReq = arrayCastLib.castLiqRequestToArray(req);
        assertEq(castedReq.length, 1);
    }

    function test_castBoolToArray() external {
        bool value = true;
        bool[] memory castedValue = arrayCastLib.castBoolToArray(value);
        assertEq(castedValue.length, 1);
    }

    function test_castToMultiVaultData() external {
        InitSingleVaultData memory data = InitSingleVaultData(
            1, 1, 1e18, 100, LiqRequest(bytes(""), address(0), address(0), 1, 1, 0), false, false, address(0), ""
        );
        InitMultiVaultData memory castedValue = arrayCastLib.castToMultiVaultData(data);
        assertEq(castedValue.superformIds.length, 1);
    }
}
