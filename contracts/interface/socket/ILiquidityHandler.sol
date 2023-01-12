pragma solidity ^0.8.14;

interface ILiquidityHandler {
    function dispatchTokens(
        address _to,
        bytes memory _txData,
        address _token,
        address _allowanceTarget,
        uint256 _amount
    ) external;
}
