// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.14;
import "@std/Test.sol";

import "contracts/types/socketTypes.sol";

import "contracts/types/lzTypes.sol";

import {MockERC20} from "../mocks/MockERC20.sol";

/*//////////////////////////////////////////////////////////////
                        MAIN TEST TYPES
//////////////////////////////////////////////////////////////*/
enum Actions {
    Deposit,
    Withdraw
}

enum Kind {
    Full,
    Partial
}

struct ActionLocalVars {
    Vm.Log[] logs;
    StateReq[] stateReqs;
    LiqRequest[] liqReqs;
    StateReq stateReq;
    LiqRequest liqReq;
    MockERC20[][] TARGET_VAULTS;
    uint256 sharesBalanceBeforeWithdraw; // 0
    uint256 amountsToWithdraw; // 0
    address[][] vaultMock;
    address lzEndpoint_0;
    address lzEndpoint_1;
    address[][] underlyingSrcToken;
    address payable fromSrc;
    address payable toDst;
    uint256[][] targetVaultIds;
    uint256[][] amounts;
}

struct VaultsAmounts {
    uint256[] vaults;
    uint256[] amounts;
}

struct TestAction {
    Actions action;
    uint16 testType;
    Kind kind;
    uint16 CHAIN_0;
    uint16 CHAIN_1;
    address user;
    bytes revertString;
}

struct TestAssertionVars {
    uint256 lenRequests;
    uint256[][] superPositionsAmountBefore;
    uint256[][] destinationSharesBefore;
    uint256[] tSPAmtBefore;
    uint256[] tDestinationSharesAmtBefore;
}

/*//////////////////////////////////////////////////////////////
                    DEPLOYMENT TYPES
//////////////////////////////////////////////////////////////*/

struct SetupVars {
    uint16[2] chainIds;
    address[2] lzEndpoints;
    uint16 chainId;
    uint16 dstChainId;
    uint256 fork;
    address lzEndpoint;
    address lzHelper;
    address socketRouter;
    address superDestination;
    address stateHandler;
    address UNDERLYING_TOKEN;
    address vault;
    address srcSuperRouter;
    address srcStateHandler;
    address srcSuperDestination;
    address dstStateHandler;
}

/*//////////////////////////////////////////////////////////////
                    HELPER TYPES
//////////////////////////////////////////////////////////////*/

struct BuildDepositCallDataArgs {
    address user;
    address fromSrc;
    address toDst;
    address[] underlyingToken;
    uint256[] targetVaultIds;
    uint256[] amounts;
    uint16 srcChainId;
    uint16 toChainId;
}

struct BuildWithdrawCallDataArgs {
    address user;
    address payable fromSrc;
    address toDst;
    address[] underlyingToken;
    address[] vaultMock;
    uint256[] targetVaultIds;
    uint256[] amounts;
    Kind kind;
    uint16 srcChainId;
    uint16 toChainId;
}

struct InternalActionArgs {
    address payable fromSrc; // SuperRouter
    address payable toDst; // SuperDestination
    address toLzEndpoint;
    address user;
    StateReq[] stateReqs;
    LiqRequest[] liqReqs;
    uint16 srcChainId;
    uint16 toChainId;
    Actions action;
    bytes revertString;
}

struct InternalActionVars {
    uint256 initialFork;
    uint256 msgValue;
    uint256 txIdBefore;
    uint256 payloadNumberBefore;
    uint256 lenRequests;
    Vm.Log[] logs;
    InitData expectedInitData;
    InitData receivedInitData;
    StateData data;
}

/*//////////////////////////////////////////////////////////////
                        ERRORS
//////////////////////////////////////////////////////////////*/

error ETH_TRANSFER_FAILED();
error INVALID_UNDERLYING_TOKEN_NAME();
error LEN_MISMATCH();
error LEN_AMOUNTS_ZERO();
error LEN_VAULTS_ZERO();
