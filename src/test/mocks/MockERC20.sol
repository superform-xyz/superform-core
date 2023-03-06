// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address initialAccount,
        uint256 initialBalance
    ) ERC20(_name, _symbol, _decimals) {
        _mint(initialAccount, initialBalance);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
}
