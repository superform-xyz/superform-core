///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperPositions} from "./interfaces/ISuperPositions.sol";
import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

/// @title SuperPosition Bank
/// @author Zeropoint Labs.
contract SuperPositionBank is ERC165 {
    
    ISuperPositions public token;
    address public superRouter;
    
    struct PositionBatch {
        uint256[] tokenIds;
        uint256[] amounts;
    }

    struct PositionSingle {
        uint256 tokenId;
        uint256 amount;
    }
    
    mapping(address => mapping(uint256 => PositionBatch)) private queueBatch;
    mapping(address => mapping(uint256 => PositionSingle)) private queueSingle;

    mapping(address => uint256) public queueCounter;

    constructor(ISuperPositions superPosition_, address superRouter_) {
        token = superPosition_;
        superRouter = superRouter_;
    }

    modifier onlyRouter() {
        require(msg.sender == superRouter, "DISALLOWED");
        _;
    }

    /// @dev Could call SuperRouter.deposit() function from here, first transfering tokens to this contract, thus saving gas
    /// NOTE: What if we open this function to deposit here and then only make a check from SuperRouter.withdraw() if returned index matches caller of SuperRouter?
    /// NOTE: Would require users to call two separate contracts and fragments flow
    // function depositToSourceDirectly() external;

    /// @notice Create a new position in the queue for withdrawal. _owner can have multiple positions in the queue
    function acceptSinglePosition(uint256 _tokenId, uint256 _amount, address _owner) public onlyRouter returns (uint256 index) {
        token.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        PositionSingle memory newPosition = PositionSingle({tokenId: _tokenId, amount: _amount});
        index = queueCounter[_owner]++;
        queueSingle[_owner][index] = newPosition;
    }

    /// @notice Create a new position in the queue for withdrawal. _owner can have multiple positions in the queue
    function acceptPositionBatch(uint256[] memory _tokenIds, uint256[] memory _amounts, address _owner) public onlyRouter returns (uint256 index) {
        require(_tokenIds.length == _amounts.length, "LENGTH_MISMATCH");
        token.safeBatchTransferFrom(msg.sender, address(this), _tokenIds, _amounts, "");
        PositionBatch memory newPosition = PositionBatch({tokenIds: _tokenIds, amounts: _amounts});
        index = queueCounter[_owner]++;
        queueBatch[_owner][index] = newPosition;
    }

    /// @notice Intended to be called in case of failure to perform Withdraw, we just return SuperPositions to owner
    function returnPositionSingle(address _owner, uint256 positionIndex) public onlyRouter {
        PositionSingle memory position = queueSingle[_owner][positionIndex];
        /// @dev _owner is arbitrary argument, re-think this
        delete queueSingle[_owner][positionIndex];
        token.safeTransferFrom(address(this), _owner, position.tokenId, position.amount, "");
    }

    /// @notice Intended to be called in case of failure to perform Withdraw, we just return SuperPositions to owner
    function returnPositionBatch(address _owner, uint256 positionIndex) public onlyRouter {
        PositionBatch memory position = queueBatch[_owner][positionIndex];
        /// @dev _owner is arbitrary argument, re-think this
        delete queueBatch[_owner][positionIndex];
        token.safeBatchTransferFrom(address(this), _owner, position.tokenIds, position.amounts, "");
    }

    /// @notice Intended to be called in case Withdraw succeds and we can safely burn SuperPositions for owner
    function burnPositionSingle(address _owner, uint256 positionIndex) public onlyRouter {
        PositionSingle memory position = queueSingle[_owner][positionIndex];
        token.burnSingleSP(_owner, position.tokenId, position.amount); /// <== decide how/where to burn
        delete queueSingle[_owner][positionIndex];
    }

    /// @notice Intended to be called in case Withdraw succeds and we can safely burn SuperPositions for owner
    function burnPositonBatch(address _owner, uint256 positionIndex) public onlyRouter {
        PositionBatch memory position = queueBatch[_owner][positionIndex];
        token.burnBatchSP(_owner, position.tokenIds, position.amounts);
        delete queueBatch[_owner][positionIndex];
    }

    /// @dev Private queue requires public getter
    function getPositionSingle(address _owner, uint256 positionIndex) public view returns (uint256 tokenId, uint256 amount) {
        PositionSingle memory position = queueSingle[_owner][positionIndex];
        return (position.tokenId, position.amount);
    }

    /// @dev Private queue requires public getter
    function getPositionBatch(address _owner, uint256 positionIndex) public view returns (uint256[] memory tokenIds, uint256[] memory amount) {
        PositionBatch memory position = queueBatch[_owner][positionIndex];
        return (position.tokenIds, position.amounts);
    }


    /**
     * @dev See {ERC1155s-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}