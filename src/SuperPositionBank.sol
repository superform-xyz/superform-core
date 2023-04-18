///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperPositions} from "./interfaces/ISuperPositions.sol";
import {ISuperRouter} from "./interfaces/ISuperRouter.sol";
import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

/// @title SuperPosition Bank
/// @author Zeropoint Labs.
contract SuperPositionBank is ERC165 {
    ISuperPositions public token;
    ISuperRouter public superRouter;

    struct PositionBatch {
        uint256[] tokenIds;
        uint256[] amounts;
    }

    struct PositionSingle {
        uint256 tokenId;
        uint256 amount;
    }

    mapping(address owner => mapping(uint256 id => PositionBatch))
        private queueBatch;
    mapping(address owner => mapping(uint256 id => PositionSingle))
        private queueSingle;
    mapping(address owner => uint256 id) public queueCounter;

    modifier onlyRouter() {
        require(msg.sender == address(superRouter), "DISALLOWED");
        _;
    }

    constructor(ISuperPositions superPosition_, ISuperRouter superRouter_) {
        token = superPosition_;
        superRouter = superRouter_;
    }

    /// @dev Could call SuperRouter.deposit() function from here, first transfering tokens to this contract, thus saving gas
    /// NOTE: What if we open this function to deposit here and then only make a check from SuperRouter.withdraw() if returned index matches caller of SuperRouter?
    /// NOTE: Would require users to call two separate contracts and fragments flow
    // function depositToSourceDirectly() external;

    /// @notice Create a new position in the queue for withdrawal. owner_ can have multiple positions in the queue
    function acceptPositionSingle(
        uint256 tokenId_,
        uint256 amount_,
        address owner_
    ) public onlyRouter returns (uint256 index) {
        token.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId_,
            amount_,
            ""
        );
        PositionSingle memory newPosition = PositionSingle({
            tokenId: tokenId_,
            amount: amount_
        });
        index = queueCounter[owner_]++;
        queueSingle[owner_][index] = newPosition;
    }

    /// @notice Create a new position in the queue for withdrawal. owner_ can have multiple positions in the queue
    function acceptPositionBatch(
        uint256[] memory tokenIds_,
        uint256[] memory amounts_,
        address owner_
    ) public onlyRouter returns (uint256 index) {
        require(tokenIds_.length == amounts_.length, "LENGTH_MISMATCH");
        token.safeBatchTransferFrom(
            msg.sender,
            address(this),
            tokenIds_,
            amounts_,
            ""
        );
        PositionBatch memory newPosition = PositionBatch({
            tokenIds: tokenIds_,
            amounts: amounts_
        });
        index = queueCounter[owner_]++;
        queueBatch[owner_][index] = newPosition;
    }

    /// @notice Intended to be called in case of failure to perform Withdraw, we just return SuperPositions to owner
    function returnPositionSingle(
        address owner_,
        uint256 positionIndex
    ) public onlyRouter {
        PositionSingle memory position = queueSingle[owner_][positionIndex];
        /// @dev owner_ is arbitrary argument, re-think this
        delete queueSingle[owner_][positionIndex];
        token.safeTransferFrom(
            address(this),
            owner_,
            position.tokenId,
            position.amount,
            ""
        );
    }

    /// @notice Intended to be called in case of failure to perform Withdraw, we just return SuperPositions to owner
    /// TODO: Implement at the SuperRouter side!
    /// NOTE: Relevant for Try/catch arc when messaging is solved
    function returnPositionBatch(
        address owner_,
        uint256 positionIndex
    ) public onlyRouter {
        PositionBatch memory position = queueBatch[owner_][positionIndex];
        /// @dev owner_ is arbitrary argument, re-think this
        delete queueBatch[owner_][positionIndex];
        token.safeBatchTransferFrom(
            address(this),
            owner_,
            position.tokenIds,
            position.amounts,
            ""
        );
    }

    /// @notice Intended to be called in case Withdraw succeds and we can safely burn SuperPositions for owner
    function burnPositionSingle(
        address owner_,
        uint256 positionIndex
    ) public onlyRouter {
        PositionSingle memory position = queueSingle[owner_][positionIndex];
        token.burnSingleSP(owner_, position.tokenId, position.amount);
        /// alternative is to transfer back to source and burn there
        delete queueSingle[owner_][positionIndex];
        superRouter.burnPositionSingle(
            owner_,
            position.tokenId,
            position.amount
        );
    }

    /// @notice Intended to be called in case Withdraw succeds and we can safely burn SuperPositions for owner
    function burnPositonBatch(
        address owner_,
        uint256 positionIndex
    ) public onlyRouter {
        PositionBatch memory position = queueBatch[owner_][positionIndex];
        delete queueBatch[owner_][positionIndex];
        superRouter.burnPositionBatch(
            owner_,
            position.tokenIds,
            position.amounts
        );
    }

    /// @dev Private queue requires public getter
    function getPositionSingle(
        address owner_,
        uint256 positionIndex
    ) public view returns (uint256 tokenId, uint256 amount) {
        PositionSingle memory position = queueSingle[owner_][positionIndex];
        return (position.tokenId, position.amount);
    }

    /// @dev Private queue requires public getter
    function getPositionBatch(
        address owner_,
        uint256 positionIndex
    ) public view returns (uint256[] memory tokenIds, uint256[] memory amount) {
        PositionBatch memory position = queueBatch[owner_][positionIndex];
        return (position.tokenIds, position.amounts);
    }

    /// @dev See {ERC1155s-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}


/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}