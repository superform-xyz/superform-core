pragma solidity ^0.8.17;

interface IController {
    function chainId() external returns (uint16);

    function totalTransactions() external returns (uint256);

    function stateSync(bytes memory _payload) external payable;
}
