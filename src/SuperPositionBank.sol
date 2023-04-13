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
    
    mapping(address => mapping(uint256 => Position)) private queue;
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
    // function depositToSourceDirectly() external;

    /// NOTE: What if we open this function to deposit here and then only make a check from SuperRouter.withdraw() if returned index matches caller of SuperRouter?
    /// NOTE: Would require users to call two separate contracts and fragments flow
    function acceptPosition(uint256[] memory _tokenIds, uint256[] memory _amounts, address _owner) public onlyRouter returns (uint256 index) {
        require(_tokenIds.length == _amounts.length, "LENGTH_MISMATCH");

        token.safeBatchTransferFrom(msg.sender, address(this), _tokenIds, _amounts, "");

        Position memory newPosition = Position({tokenIds: _tokenIds, amounts: _amounts});
        queue[_owner][queueCounter[_owner]] = newPosition;
        index = queueCounter[_owner]++;
    }

    function returnPosition(address _owner, uint256 positionIndex) public onlyRouter {
        Position memory position = queue[_owner][positionIndex];
        token.safeBatchTransferFrom(address(this), msg.sender, position.tokenIds, position.amounts, "");
        delete queue[_owner][positionIndex];
    }

    // function burnPosition(address _owner, uint256 positionIndex) public onlyRouter {
    //     Position memory position = queue[_owner][positionIndex];
    //     token.burnBatch(position.tokenIds, position.amounts);
    //     delete queue[_owner][positionIndex];
    // }

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