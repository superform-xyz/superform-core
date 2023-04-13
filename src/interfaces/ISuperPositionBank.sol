/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface ISuperPositionBank {

    function acceptPosition(uint256[] memory _tokenIds, uint256[] memory _amounts, address _owner) external returns (uint256 index);

    function returnPosition(address _owner, uint256 positionIndex) external;

    function burnPosition(address _owner, uint256 positionIndex) external;
}
