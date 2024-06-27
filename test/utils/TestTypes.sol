// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import { SuperRegistry } from "src/settings/SuperRegistry.sol";
import { SuperRBAC } from "src/settings/SuperRBAC.sol";

import "src/types/DataTypes.sol";

/*//////////////////////////////////////////////////////////////
                        MAIN TEST TYPES
//////////////////////////////////////////////////////////////*/
enum Actions {
    Deposit,
    DepositPermit2,
    RescueFailedDeposit,
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
    RevertUpdateStateRBAC,
    RevertXChainDeposit,
    RevertVaultsWithdraw
}

struct StagesLocalVars {
    uint256 act;
    Vm.Log[] logs;
    MultiDstMultiVaultStateReq multiDstMultiVaultStateReq;
    MultiDstSingleVaultStateReq multiDstSingleVaultStateReq;
    SingleXChainMultiVaultStateReq singleDstMultiVaultStateReq;
    SingleXChainSingleVaultStateReq singleXChainSingleVaultStateReq;
    SingleDirectSingleVaultStateReq singleDirectSingleVaultStateReq;
    updateMultiVaultDepositPayloadArgs multiVaultsPayloadArg;
    updateSingleVaultDepositPayloadArgs singleVaultsPayloadArg;
    uint256 nDestinations;
    address superformT;
    address[] vaultMock;
    address lzEndpoint_0;
    address[] lzEndpoints_1;
    address[] underlyingSrcToken;
    address[] underlyingDstToken;
    address payable fromSrc;
    address[] toDst;
    uint256[] targetSuperformIds;
    uint256[] amounts;
    uint256[] outputAmounts;
    uint8[] liqBridges;
    bool[] receive4626;
    uint256 chain0Index;
    uint256 chainDstIndex;
    uint256 nUniqueDsts;
    int256 slippage;
    uint256[] superformIds;
    /// @dev targets from invariant handler
    uint256[][] targetVaults;
    uint32[][] targetFormKinds;
    uint256[][] targetUnderlyings;
    uint256[][] targetAmounts;
    uint8[][] targetLiqBridges;
    bool[][] targetReceive4626;
    uint8[] AMBs;
    uint64 CHAIN_0;
    uint64[] DST_CHAINS;
    uint256 underlyingWithBridgeSlippage;
    uint256[] underlyingWithBridgeSlippages;
    uint256[] amountsBeforeCSR;
    uint256[] finalAmountsThatReachedCSR;
    address[] potentialRealVaults;
}

struct MessagingAssertVars {
    uint256 initialFork;
    uint256 msgValue;
    uint256 txIdBefore;
    uint256 receivedPayloadId;
    uint64 toChainId;
    bool success;
    MultiVaultSFData expectedMultiVaultsData;
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
    bool dstSwap;
    uint256 externalToken;
}
/// @dev must be 3 if external token is native (for deposits). For withdrawals, externalToken is the output token and
/// should not be set to 3 (no native for output in our tests)

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
    uint16 dstWormholeChainId;
    uint256 fork;
    address[] ambAddresses;
    address superform;
    address factory;
    address lzHelper;
    address lzV2Helper;
    address lzImplementation;
    address lzV2Implementation;
    address hyperlaneHelper;
    address hyperlaneImplementation;
    address wormholeHelper;
    address axelarHelper;
    address wormholeBroadcastHelper;
    address wormholeImplementation;
    address wormholeSRImplementation;
    address axelarImplementation;
    address dstSwapper;
    address lifiRouter;
    address deBridgeMock;
    address oneInchMock;
    address socketRouter;
    address socketOneInch;
    address debridgeForwarderMock;
    address liFiMockRugpull;
    address liFiMockBlacklisted;
    address liFiMockSwapToAttacker;
    address erc4626Form;
    address erc4626TimelockForm;
    address kycDao4626Form;
    address erc5115form;
    address coreStateRegistry;
    address PayloadHelper;
    address paymentHelper;
    address timelockStateRegistry;
    address broadcastRegistry;
    address UNDERLYING_TOKEN;
    address vault;
    address timelockVault;
    address superformRouter;
    address dstLzImplementation;
    address dstHyperlaneImplementation;
    address dstWormholeARImplementation;
    address dstWormholeSRImplementation;
    address dstwormholeBroadcastHelper;
    address dstAxelarImplementation;
    address payMaster;
    address superRegistry;
    address emergencyQueue;
    address superRBAC;
    address canonicalPermit2;
    address lifiValidator;
    address socketValidator;
    address socketOneInchValidator;
    address oneInchValidator;
    address debridgeValidator;
    address debridgeForwarderValidator;
    address rewardsDistributor;
    Vm.Log[] logs;
    address superPositions;
    address kycDAOMock;
    SuperRegistry superRegistryC;
    SuperRBAC superRBACC;
}

/*//////////////////////////////////////////////////////////////
                    ARGS TYPES
//////////////////////////////////////////////////////////////*/

struct CallDataArgs {
    MultiVaultSFData[] multiSuperformsData;
    SingleVaultSFData[] singleSuperformsData;
    MultiVaultCallDataArgs[] multiSuperformsCallData;
    SingleVaultCallDataArgs[] singleSuperformsCallData;
}

struct SingleVaultCallDataArgs {
    uint256 user;
    address fromSrc;
    address externalToken;
    address toDst;
    address underlyingToken;
    address underlyingTokenDst;
    address uniqueInterimToken;
    uint256 superformId;
    uint256 amount;
    uint256 outputAmount;
    uint8 liqBridge;
    bool receive4626;
    uint256 maxSlippage;
    address vaultMock;
    uint64 srcChainId;
    uint64 toChainId;
    uint64 liqDstChainId;
    uint256 liquidityBridgeSrcChainId;
    uint256 liquidityBridgeToChainId;
    bool dstSwap;
    int256 slippage;
}

struct MultiVaultCallDataArgs {
    uint256 user;
    address fromSrc;
    address externalToken;
    address[] toDst;
    address[] underlyingTokens;
    address[] underlyingTokensDst;
    uint256[] superformIds;
    uint256[] amounts;
    uint256[] outputAmounts;
    uint8[] liqBridges;
    bool[] receive4626;
    uint256 maxSlippage;
    address[] vaultMock;
    uint64 srcChainId;
    uint64 toChainId;
    uint256 liquidityBridgeSrcChainId;
    uint256 index;
    uint256 chainDstIndex;
    bool dstSwap;
    Actions action;
    int256 slippage;
}

struct BuildDepositCallDataArgs {
    address user;
    address fromSrc;
    address toDst;
    address[] underlyingToken;
    uint256[] targetSuperformIds;
    uint256[] amounts;
    uint8 liqBridges;
    uint256 maxSlippage;
    uint64 srcChainId;
    uint64 toChainId;
    bool dstSwap;
}

struct BuildWithdrawCallDataArgs {
    address user;
    address payable fromSrc;
    address toDst;
    address[] underlyingToken;
    address[] vaultMock;
    uint256[] targetSuperformIds;
    uint256[] amounts;
    uint256 maxSlippage;
    LiquidityChange actionKind;
    uint64 srcChainId;
    uint64 toChainId;
}

struct updateMultiVaultDepositPayloadArgs {
    uint256 payloadId;
    uint256[] amounts;
    int256 slippage;
    uint64 targetChainId;
    TestType testType;
    bytes4 revertError;
    bytes32 revertRole;
    bool isdstSwap;
}

struct updateSingleVaultDepositPayloadArgs {
    uint256 payloadId;
    uint256 amount;
    int256 slippage;
    uint64 targetChainId;
    TestType testType;
    bytes4 revertError;
    bytes32 revertRole;
    bool isdstSwap;
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
