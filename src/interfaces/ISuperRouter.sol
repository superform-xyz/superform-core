// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {LiqRequest, MultiDstMultiVaultsStateReq, SingleDstMultiVaultsStateReq, MultiDstSingleVaultStateReq, SingleXChainSingleVaultStateReq, SingleDirectSingleVaultStateReq, AMBMessage} from "../types/DataTypes.sol";

/// TODO: Change to ERC1155s / depends on SuperBank task
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

/// @title ISuperRouter
/// @author Zeropoint Labs.
interface ISuperRouter is IERC1155 {
    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct ActionLocalVars {
        AMBMessage ambMessage;
        LiqRequest liqRequest;
        uint16 srcChainId;
        uint16 dstChainId;
        uint80 currentTotalTransactions;
        address srcSender;
        uint256 liqRequestsLen;
    }
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev FIXME: to remove? - is emitted when a cross-chain transaction is initiated.
    event Initiated(uint256 txId, address fromToken, uint256 fromAmount);

    /// @dev is emitted when a cross-chain transaction is initiated.
    event CrossChainInitiated(uint80 indexed txId);

    /// @dev is emitted when a cross-chain transaction is completed.
    event Completed(uint256 txId);

    /// @dev is emitted when the super registry is updated.
    event SuperRegistryUpdated(address indexed superRegistry);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when the chain id input is invalid.
    error INVALID_INPUT_CHAIN_ID();

    /// @dev is emitted when the amb ids input is invalid.
    error INVALID_AMB_IDS();

    /// @dev is emitted when the vaults data is invalid
    error INVALID_SUPERFORMS_DATA();

    /// @dev is emitted when the chain ids data is invalid
    error INVALID_CHAIN_IDS();

    /// @dev is emitted if anything other than state Registry calls stateSync
    error REQUEST_DENIED();

    /// @dev is emitted when the payload is invalid
    error INVALID_PAYLOAD();

    /// @dev is emitted if srchain ids mismatch in state sync
    error SRC_CHAIN_IDS_MISMATCH();

    /// @dev is emitted if dsthain ids mismatch in state sync
    error DST_CHAIN_IDS_MISMATCH();

    /// @dev is emitted if the payload status is invalid
    error INVALID_PAYLOAD_STATUS();

    /// @dev is emitted when an address is being set to 0
    error ZERO_ADDRESS();

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL DEPOSIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Performs multi destination x multi vault deposits
    /// @param req is the request object containing all the necessary data for the action
    function multiDstMultiVaultDeposit(
        MultiDstMultiVaultsStateReq calldata req
    ) external payable;

    /// @dev Performs single destination x multi vault deposits
    /// @param req is the request object containing all the necessary data for the action
    function singleDstMultiVaultDeposit(
        SingleDstMultiVaultsStateReq memory req
    ) external payable;

    /// @dev Performs multi destination x single vault deposits
    /// @param req is the request object containing all the necessary data for the action
    function multiDstSingleVaultDeposit(
        MultiDstSingleVaultStateReq calldata req
    ) external payable;

    /// @dev Performs single xchain destination x single vault deposits
    /// @param req is the request object containing all the necessary data for the action
    function singleXChainSingleVaultDeposit(
        SingleXChainSingleVaultStateReq memory req
    ) external payable;

    /// @dev Performs single direct x single vault deposits
    /// @param req is the request object containing all the necessary data for the action
    function singleDirectSingleVaultDeposit(
        SingleDirectSingleVaultStateReq memory req
    ) external payable;

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL WITHDRAW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Performs multi destination x multi vault withdraws
    /// @param req is the request object containing all the necessary data for the action
    function multiDstMultiVaultWithdraw(
        MultiDstMultiVaultsStateReq calldata req
    ) external payable;

    /// @dev Performs single destination x multi vault withdraws
    /// @param req is the request object containing all the necessary data for the action
    function singleDstMultiVaultWithdraw(
        SingleDstMultiVaultsStateReq memory req
    ) external payable;

    /// @dev Performs multi destination x single vault withdraws
    /// @param req is the request object containing all the necessary data for the action
    function multiDstSingleVaultWithdraw(
        MultiDstSingleVaultStateReq calldata req
    ) external payable;

    /// @dev Performs single xchain destination x single vault withdraws
    /// @param req is the request object containing all the necessary data for the action
    function singleXChainSingleVaultWithdraw(
        SingleXChainSingleVaultStateReq memory req
    ) external payable;

    /// @dev Performs single direct x single vault withdraws
    /// @param req is the request object containing all the necessary data for the action
    function singleDirectSingleVaultWithdraw(
        SingleDirectSingleVaultStateReq memory req
    ) external payable;

    /*///////////////////////////////////////////////////////////////
                        OTHER EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param data_ is the received information to be processed.
    function stateMultiSync(AMBMessage memory data_) external payable;

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param data_ is the received information to be processed.
    function stateSync(AMBMessage memory data_) external payable;

    /*///////////////////////////////////////////////////////////////
                        External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the chain id of the router contract
    function chainId() external view returns (uint16);

    /// @dev returns the total individual vault transactions made through the router.
    function totalTransactions() external view returns (uint80);
}
