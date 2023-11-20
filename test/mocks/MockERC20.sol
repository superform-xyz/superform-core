/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        address initialAccount,
        uint256 initialBalance
    )
        ERC20(_name, _symbol)
    {
        _mint(initialAccount, initialBalance);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
}
