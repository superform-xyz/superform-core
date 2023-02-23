// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.14;
import "@std/Test.sol";

import "contracts/types/LiquidityTypes.sol";

import "contracts/types/DataTypes.sol";

import {MockERC20} from "../mocks/MockERC20.sol";

/*//////////////////////////////////////////////////////////////
                        MAIN TEST TYPES
//////////////////////////////////////////////////////////////*/
enum Actions {
    Deposit,
    Withdraw
}

enum LiquidityChange {
    Full,
    Partial
}

enum TestType {
    Pass,
    RevertMainAction,
    RevertProcessPayload,
    RevertUpdateStateSlippage,
    RevertUpdateStateRBAC
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
    uint16 actionType;
    LiquidityChange actionKind;
    uint16 CHAIN_0;
    uint16 CHAIN_1;
    address user;
    TestType testType;
    bytes revertString;
    uint256 maxSlippage;
    int256 slippage;
    bool multiTx;
}

struct TestAssertionVars {
    uint256 lenRequests;
    uint256[][] superPositionsAmountBefore;
    uint256[][] destinationSharesBefore;
    uint256[] tSPAmtBefore;
    uint256[] tDestinationSharesAmtBefore;
    bool success;
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
    address lzImplementation;
    address socketRouter;
    address superDestination;
    address stateRegistry;
    address UNDERLYING_TOKEN;
    address vault;
    address srcSuperRouter;
    address srcStateRegistry;
    address srcLzImplementation;
    address dstLzImplementation;
    address srcSuperDestination;
    address dstStateRegistry;
    address srcMultiTxProcessor;
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
    uint256 maxSlippage;
    uint16 srcChainId;
    uint16 toChainId;
    bool multiTx;
}

struct BuildWithdrawCallDataArgs {
    address user;
    address payable fromSrc;
    address toDst;
    address[] underlyingToken;
    address[] vaultMock;
    uint256[] targetVaultIds;
    uint256[] amounts;
    uint256 maxSlippage;
    LiquidityChange actionKind;
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
    TestType testType;
    bytes revertString;
    bool multiTx;
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
error MISMATCH_TEST_TYPE();
