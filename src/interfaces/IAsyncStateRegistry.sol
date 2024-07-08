// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { InitSingleVaultData } from "src/types/DataTypes.sol";
import { LiqRequest } from "src/types/DataTypes.sol";

import { IBaseAsyncStateRegistry } from "./IBaseAsyncStateRegistry.sol";

//////////////////////////////////////////////////////////////
//                           ERRORS                        //
//////////////////////////////////////////////////////////////

error NOT_READY_TO_CLAIM();
error ERC7540_AMBIDS_NOT_ENCODED();
error INVALID_AMOUNT_IN_TXDATA();
error REQUEST_CONFIG_NON_EXISTENT();

//////////////////////////////////////////////////////////////
//                           STRUCTS                        //
//////////////////////////////////////////////////////////////

struct RequestConfig {
    uint8 isXChain;
    bool retain4626;
    uint64 currentSrcChainId;
    uint256 requestId;
    uint256 currentReturnDataPayloadId;
    uint256 maxSlippageSetting;
    LiqRequest currentLiqRequest; // if different than address 0 signals keepers to update txData
    uint8[] ambIds;
}

struct ClaimAvailableDepositsArgs {
    address user;
    uint256 superformId;
}

struct ClaimAvailableDepositsLocalVars {
    bool is7540;
    address superformAddress;
    uint256 claimableDeposit;
    uint8[] ambIds;
}

/// @title IAsyncStateRegistry
/// @dev Interface for AsyncStateRegistry
/// @author ZeroPoint Labs
interface IAsyncStateRegistry is IBaseAsyncStateRegistry {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event UpdatedRequestsConfig(address indexed user_, uint256 indexed superformId_, uint256 indexed requestId_);

    event ClaimedAvailableDeposits(address indexed user_, uint256 indexed superformId_, uint256 indexed requestId_);

    event ClaimedAvailableRedeems(address indexed user_, uint256 indexed superformId_, uint256 indexed requestId_);

    event FailedDepositClaim(address indexed user_, uint256 indexed superformId_, uint256 indexed requestId_);

    event FailedRedeemClaim(address indexed user_, uint256 indexed superformId_, uint256 indexed requestId_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    function getRequestConfig(
        address user_,
        uint256 superformId_
    )
        external
        view
        returns (RequestConfig memory requestConfig);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    function updateAccount(
        uint8 type_,
        uint64 srcChainId_,
        bool isDeposit_,
        uint256 requestId_,
        InitSingleVaultData memory data_
    )
        external;

    function claimAvailableDeposits(ClaimAvailableDepositsArgs memory args) external payable;

    function claimAvailableRedeems(address user_, uint256 superformId_, bytes memory updatedTxData_) external;
}
