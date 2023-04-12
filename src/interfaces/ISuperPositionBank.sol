/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface ISuperPositionBank {

    function acceptPosition(uint256[] memory _tokenIds, uint256[] memory _amounts) external;

    function returnPosition(uint256[] memory _tokenIds, uint256[] memory _amounts) external;
}
