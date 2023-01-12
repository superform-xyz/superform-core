// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.14;

/// NPM Imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Types Imports
import {UserRequest} from "../types/socketTypes.sol";

import "hardhat/console.sol";

/// @title Socket Router Mock
contract SocketRouterMock {
    function mockSocketTransfer(
        address from,
        address to,
        address token,
        uint256 amount
    ) external returns (bool) {
        IERC20(token).transferFrom(from, address(this), amount);
        IERC20(token).transfer(to, amount);

        return true;
    }
}
