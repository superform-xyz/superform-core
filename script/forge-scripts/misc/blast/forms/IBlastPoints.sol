// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

interface IBlastPoints {
    function configurePointsOperator(address operator) external;
    function configurePointsOperatorOnBehalf(address contractAddress, address operator) external;
}
