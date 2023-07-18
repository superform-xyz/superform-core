// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import "forge-std/Test.sol";

import "../../types/LiquidityTypes.sol";

import "../../types/DataTypes.sol";

import {MockERC20} from "../mocks/MockERC20.sol";

/*//////////////////////////////////////////////////////////////
                        MAIN TEST TYPES
//////////////////////////////////////////////////////////////*/
enum Actions {
    Deposit,
    Withdraw,
    DepositPermit2,
    RescueFailedDeposit
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
    RevertUpdateStateRBAC,
    RevertXChainDeposit
}

struct StagesLocalVars {
    Vm.Log[] logs;
    MultiDstMultiVaultsStateReq multiDstMultiVaultStateReq;
    MultiDstSingleVaultStateReq multiDstSingleVaultStateReq;
    SingleDstMultiVaultsStateReq singleDstMultiVaultStateReq;
    SingleXChainSingleVaultStateReq singleXChainSingleVaultStateReq;
    SingleDirectSingleVaultStateReq singleDirectSingleVaultStateReq;
    MultiVaultsSFData[] multiSuperFormsData;
    SingleVaultSFData[] singleSuperFormsData;
    UpdateMultiVaultPayloadArgs multiVaultsPayloadArg;
    UpdateSingleVaultPayloadArgs singleVaultsPayloadArg;
    uint256 nDestinations;
    address superFormT;
    address[] vaultMock;
    address lzEndpoint_0;
    address[] lzEndpoints_1;
    address[] underlyingSrcToken;
    address payable fromSrc;
    address[] toDst;
    uint256[] targetSuperFormIds;
    uint256[] amounts;
    uint8[] liqBridges;
    uint256 chain0Index;
    uint256 chainDstIndex;
    uint256 nUniqueDsts;
    bool[] partialWithdrawVaults;
}

struct MessagingAssertVars {
    uint256 initialFork;
    uint256 msgValue;
    uint256 txIdBefore;
    uint256 receivedPayloadId;
    uint64 toChainId;
    bool success;
    MultiVaultsSFData expectedMultiVaultsData;
    SingleVaultSFData expectedSingleVaultData;
    InitMultiVaultData receivedMultiVaultData;
    InitSingleVaultData receivedSingleVaultData;
    AMBMessage data;
}

struct TestAction {
    Actions action;
    bool multiVaults;
    uint256 user;
    TestType testType;
    bytes4 revertError;
    bytes32 revertRole; // temporary until errors are added to RBAC libraries
    int256 slippage;
    bool multiTx;
    uint256 externalToken;
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
    uint64 chainId;
    uint64 dstChainId;
    uint16 dstLzChainId;
    uint32 dstHypChainId;
    uint64 dstCelerChainId;
    uint256 fork;
    address[] ambAddresses;
    address superForm;
    address factory;
    address lzHelper;
    address lzImplementation;
    address hyperlaneHelper;
    address hyperlaneImplementation;
    address celerHelper;
    address celerImplementation;
    address socketRouter;
    address lifiRouter;
    address erc4626Form;
    address erc4626TimelockForm;
    address kycDao4626Form;
    address rolesStateRegistry;
    address factoryStateRegistry;
    address coreStateRegistry;
    address PayloadHelper;
    address FeeHelper;
    address twoStepsFormStateRegistry;
    address UNDERLYING_TOKEN;
    address vault;
    address timelockVault;
    address superRouter;
    address dstLzImplementation;
    address dstHyperlaneImplementation;
    address dstCelerImplementation;
    address dstStateRegistry;
    address multiTxProcessor;
    address superRegistry;
    address superRBAC;
    address canonicalPermit2;
    address socketValidator;
    address lifiValidator;
    Vm.Log[] logs;
    address superPositions;
    address kycDAOMock;
}

/*//////////////////////////////////////////////////////////////
                    ARGS TYPES
//////////////////////////////////////////////////////////////*/

struct CallDataArgs {
    MultiVaultsSFData[] multiSuperFormsData;
    SingleVaultSFData[] singleSuperFormsData;
    MultiVaultCallDataArgs[] multiSuperFormsCallData;
    SingleVaultCallDataArgs[] singleSuperFormsCallData;
}

struct SingleVaultCallDataArgs {
    uint256 user;
    address fromSrc;
    address externalToken;
    address toDst;
    address underlyingToken;
    uint256 superFormId;
    uint256 amount;
    uint8 liqBridge;
    uint256 maxSlippage;
    address vaultMock;
    uint64 srcChainId;
    uint64 toChainId;
    uint256 liquidityBridgeSrcChainId;
    uint256 liquidityBridgeToChainId;
    bool multiTx;
    bool partialWithdrawVault;
}

struct MultiVaultCallDataArgs {
    uint256 user;
    address fromSrc;
    address externalToken;
    address[] toDst;
    address[] underlyingTokens;
    uint256[] superFormIds;
    uint256[] amounts;
    uint8[] liqBridges;
    uint256 maxSlippage;
    address[] vaultMock;
    uint64 srcChainId;
    uint64 toChainId;
    uint256 liquidityBridgeSrcChainId;
    uint256 liquidityBridgeToChainId;
    bool multiTx;
    Actions action;
    int256 slippage;
    bool[] partialWithdrawVaults;
}

struct BuildDepositCallDataArgs {
    address user;
    address fromSrc;
    address toDst;
    address[] underlyingToken;
    uint256[] targetSuperFormIds;
    uint256[] amounts;
    uint8 liqBridges;
    uint256 maxSlippage;
    uint64 srcChainId;
    uint64 toChainId;
    bool multiTx;
}

struct BuildWithdrawCallDataArgs {
    address user;
    address payable fromSrc;
    address toDst;
    address[] underlyingToken;
    address[] vaultMock;
    uint256[] targetSuperFormIds;
    uint256[] amounts;
    uint256 maxSlippage;
    LiquidityChange actionKind;
    uint64 srcChainId;
    uint64 toChainId;
}

struct UpdateMultiVaultPayloadArgs {
    uint256 payloadId;
    uint256[] amounts;
    int256 slippage;
    uint64 targetChainId;
    TestType testType;
    bytes4 revertError;
    bytes32 revertRole;
}

struct UpdateSingleVaultPayloadArgs {
    uint256 payloadId;
    uint256 amount;
    int256 slippage;
    uint64 targetChainId;
    TestType testType;
    bytes4 revertError;
    bytes32 revertRole;
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
error MISMATCH_RBAC_TEST();
error WRONG_UNDERLYING_ID();
error INVALID_AMOUNTS_LENGTH();
error INVALID_TARGETS();
error WRONG_FORMBEACON_ID();
