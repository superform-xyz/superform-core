/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface ISuperPositionBank {
    function acceptPositionBatch(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address owner
    ) external returns (uint256 index);

    function acceptPositionSingle(
        uint256 tokenId,
        uint256 amounts,
        address _owner
    ) external returns (uint256 index);

    function returnPositionBatch(
        address _owner,
        uint256 positionIndex
    ) external;

    function returnPositionSingle(
        address _owner,
        uint256 positionIndex
    ) external;

    function burnPositionBatch(address _owner, uint256 positionIndex) external;

    function burnPositionSingle(address _owner, uint256 positionIndex) external;

    function lockPositionSingle(
        address owner_,
        uint256 positionIndex
    ) external;

    function lockPositionBatch(
        address owner_,
        uint256 positionIndex
    ) external;

    function unlocked(
        address owner_,
        uint256 superFormId
    ) external view returns (uint256 amount);

    function getPositionBatch(
        address owner,
        uint256 positionIndex
    ) external returns (uint256[] memory tokenIds, uint256[] memory amounts);

    function getPositionSingle(
        address owner,
        uint256 positionIndex
    ) external returns (uint256 tokenId, uint256 amount);
}
