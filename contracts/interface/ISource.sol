pragma solidity ^0.8.14;

interface IController {
    function chainId() external returns (uint16);

    function stateSync(bytes memory _payload) external payable;
}
