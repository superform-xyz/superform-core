// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import { SuperRegistry } from "src/settings/SuperRegistry.sol";
import { SuperRBAC } from "src/settings/SuperRBAC.sol";

import "src/types/LiquidityTypes.sol";
import "src/types/DataTypes.sol";

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
    RevertXChainDeposit,
    RevertVaultsWithdraw
}

struct StagesLocalVars {
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
    uint8[] liqBridges;
    uint256 chain0Index;
    uint256 chainDstIndex;
    uint256 nUniqueDsts;
    bool[] partialWithdrawVaults;
    int256 slippage;
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
    address lzImplementation;
    address hyperlaneHelper;
    address hyperlaneImplementation;
    address wormholeHelper;
    address wormholeBroadcastHelper;
    address wormholeImplementation;
    address wormholeSRImplementation;
    address lifiRouter;
    address erc4626Form;
    address erc4626TimelockForm;
    address kycDao4626Form;
    address coreStateRegistry;
    address PayloadHelper;
    address paymentHelper;
    address twoStepsFormStateRegistry;
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
    address payMaster;
    address superRegistry;
    address superRBAC;
    address canonicalPermit2;
    address lifiValidator;
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
    uint256 superformId;
    uint256 amount;
    uint8 liqBridge;
    uint256 maxSlippage;
    address vaultMock;
    uint64 srcChainId;
    uint64 toChainId;
    uint64 liqDstChainId;
    uint256 liquidityBridgeSrcChainId;
    uint256 liquidityBridgeToChainId;
    bool partialWithdrawVault;
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
    uint8[] liqBridges;
    uint256 maxSlippage;
    address[] vaultMock;
    uint64 srcChainId;
    uint64 toChainId;
    uint256 liquidityBridgeSrcChainId;
    uint256 index;
    uint256 chainDstIndex;
    Actions action;
    int256 slippage;
    bool[] partialWithdrawVaults;
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
}

struct updateSingleVaultDepositPayloadArgs {
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
