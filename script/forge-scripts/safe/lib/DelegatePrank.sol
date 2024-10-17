// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import { CommonBase } from "forge-std/Base.sol";
import "forge-std/console.sol";

/* 
  Make arbitrary delegatecalls to an implementation contract.

  Supplements vm.prank.

  You already know how to make a contract c call dest.fn(args):

    vm.prank(c);
    dest.fn(args);

  Now, to make c delegatecall dest.fn(args):

    delegatePrank(c,address(dest),abi.encodeCall(fn,(args)));

*/
contract DelegatePrank is CommonBase {
    Delegator delegator = makeDelegator();

    function makeDelegator() internal returns (Delegator) {
        return new Delegator();
    }

    function delegatePrank(address from, address to, bytes memory cd) public returns (bool success, bytes memory ret) {
        bytes memory code = from.code;
        vm.etch(from, address(delegator).code);
        (success, ret) = from.call(abi.encodeCall(delegator.etchCodeAndDelegateCall, (to, cd, code)));
    }
}

contract Delegator is CommonBase {
    function etchCodeAndDelegateCall(address dest, bytes memory cd, bytes calldata code) external payable virtual {
        vm.etch(address(this), code);
        assembly ("memory-safe") {
            let result := delegatecall(gas(), dest, add(cd, 32), mload(cd), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
