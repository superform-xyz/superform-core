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
    
    mapping(address => mapping(uint256 => Position)) public queue;
    mapping(address => uint256) public queueCounter;

    constructor(IERC1155 _token, address _superRouter) {
        token = _token;
        superRouter = _superRouter;
    }

    modifier onlyRouter() {
        require(msg.sender == superRouter, "DISALLOWED");
        _;
    }

    function acceptPosition(uint256[] memory _tokenIds, uint256[] memory _amounts, address _owner) public onlyRouter {
        require(_tokenIds.length == _amounts.length, "LENGTH_MISMATCH");

        token.safeBatchTransferFrom(msg.sender, address(this), _tokenIds, _amounts, "");

        Position memory newPosition = Position({tokenIds: _tokenIds, amounts: _amounts});
        queue[_owner][queueCounter[_owner]] = newPosition;
        queueCounter[_owner]++;
    }

    function returnPosition(uint256[] memory _tokenIds, uint256[] memory _amounts, address _owner, uint256 positionIndex) public onlyRouter {
        require(_tokenIds.length == _amounts.length, "LENGTH_MISMATCH");

        Position memory position = queue[_owner][positionIndex];
        require(position.tokenIds.length == _tokenIds.length, "INVALID_POSITION");
        
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(position.tokenIds[i] == _tokenIds[i], "INVALID_TOKEN_ID");
            require(position.amounts[i] == _amounts[i], "INVALID_AMOUNT");
        }
        
        token.safeBatchTransferFrom(address(this), msg.sender, _tokenIds, _amounts, "");
        
        delete queue[_owner][positionIndex];
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