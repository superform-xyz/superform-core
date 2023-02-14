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

struct ActionLocalVars {
    Vm.Log[] logs;
    StateReq[] stateReqs;
    LiqRequest[] liqReqs;
    StateReq stateReq;
    LiqRequest liqReq;
    MockERC20 TARGET_VAULT;
    uint256 sharesBalanceBeforeWithdraw; // 0
    uint256 amountsToWithdraw; // 0
    address vaultMock;
    address lzEndpoint_0;
    address lzEndpoint_1;
    address underlyingSrcToken;
    address underlyingDstToken;
    address payable fromSrc;
    address payable toDst;
}

struct TestAction {
    Actions action;
    uint16 CHAIN_0;
    uint16 CHAIN_1;
    uint256 vault;
    uint256 amount;
    address user;
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

struct DepositArgs {
    address underlyingSrcToken;
    address payable fromSrc; // SuperRouter
    address payable toDst; // SuperDestination
    address toLzEndpoint;
    address user;
    StateReq stateReq;
    LiqRequest liqReq;
    uint256 amount;
    uint16 srcChainId;
    uint16 toChainId;
}

struct WithdrawArgs {
    address payable fromSrc; // SuperRouter
    address payable toDst; // SuperDestination
    address toLzEndpoint;
    address user;
    StateReq stateReq;
    LiqRequest liqReq;
    uint256 amount;
    uint16 srcChainId;
    uint16 toChainId;
}

struct BuildDepositArgs {
    address fromSrc;
    address toDst;
    address underlyingSrcToken;
    uint256 targetVaultId;
    uint256 amount;
    uint16 srcChainId;
    uint16 toChainId;
}

struct BuildWithdrawArgs {
    address fromSrc;
    address toDst;
    address underlyingDstToken;
    uint256 targetVaultId;
    uint256 amount;
    uint16 srcChainId;
    uint16 toChainId;
}

/*//////////////////////////////////////////////////////////////
                        ERRORS
//////////////////////////////////////////////////////////////*/

error ETH_TRANSFER_FAILED();
error INVALID_UNDERLYING_TOKEN_NAME();
