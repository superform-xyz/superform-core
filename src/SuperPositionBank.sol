///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

/// @title SuperPosition Bank
/// @author Zeropoint Labs.
contract SuperPositionBank is ERC165 {
    
    IERC1155 public token;
    address public superRouter;
    
    struct Position {
        uint256[] tokenIds;
        uint256[] amounts;
    }

    struct PositionSingle {
        uint256 tokenId;
        uint256 amount;
    }
    
    mapping(address => mapping(uint256 => Position)) private queue;
    mapping(address => mapping(uint256 => PositionSingle)) private queueSingle;

    mapping(address => uint256) public queueCounter;

    constructor(IERC1155 _token, address _superRouter) {
        token = _token;
        superRouter = _superRouter;
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
    function acceptPosition(uint256[] memory _tokenIds, uint256[] memory _amounts, address _owner) public onlyRouter returns (uint256 index) {
        require(_tokenIds.length == _amounts.length, "LENGTH_MISMATCH");
        token.safeBatchTransferFrom(msg.sender, address(this), _tokenIds, _amounts, "");
        Position memory newPosition = Position({tokenIds: _tokenIds, amounts: _amounts});
        index = queueCounter[_owner]++;
        queue[_owner][index] = newPosition;
    }

    /// @notice Create a new position in the queue for withdrawal. _owner can have multiple positions in the queue
    function acceptSinglePosition(uint256 _tokenId, uint256 _amount, address _owner) public onlyRouter returns (uint256 index) {
        token.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        PositionSingle memory newPosition = PositionSingle({tokenId: _tokenId, amount: _amount});
        index = queueCounter[_owner]++;
        queueSingle[_owner][index] = newPosition;
    }

    /// @notice Intended to be called in case of failure to perform Withdraw, we just return SuperPositions to owner
    function returnPosition(address _owner, uint256 positionIndex) public onlyRouter {
        Position memory position = queue[_owner][positionIndex];
        /// @dev _owner is arbitrary argument, re-think this
        delete queue[_owner][positionIndex];
        token.safeBatchTransferFrom(address(this), _owner, position.tokenIds, position.amounts, "");
    }

    /// TODO: Intended to be called in case Withdraw succeds and we can safely burn SuperPositions for owner
    function burnPosition(address _owner, uint256 positionIndex) public onlyRouter {
        Position memory position = queue[_owner][positionIndex];
        // token.burnBatch(position.tokenIds, position.amounts); /// <== decide how/where to burn
        delete queue[_owner][positionIndex];
    }

    /// @dev Private queue requires public getter
    function getPosition(address _owner, uint256 positionIndex) public view returns (uint256[] memory tokenIds, uint256[] memory amounts) {
        Position memory position = queue[_owner][positionIndex];
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