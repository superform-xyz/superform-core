// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

contract UnderlyingMock is ERC20("MockToken", "MOCK", 18) {
    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
