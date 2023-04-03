// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import "@std/Test.sol";

import "../../types/LiquidityTypes.sol";

import "../../types/DataTypes.sol";

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

struct NewActionLocalVars {
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
    uint256[] maxSlippage;
}

struct AssertVars {
    uint256 initialFork;
    uint256 msgValue;
    uint256 txIdBefore;
    uint256 payloadNumberBefore;
    uint16 toChainId;
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
    address user;
    TestType testType;
    bytes4 revertError;
    bytes32 revertRole; // temporary until errors are added to RBAC libraries
    int256 slippage;
    bool multiTx;
    bytes adapterParam;
    uint256 msgValue;
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
    uint16 dstAmbChainId;
    uint32 dstHypChainId;
    uint256 fork;
    address tokenBank;
    address superForm;
    address factory;
    address lzEndpoint;
    address lzHelper;
    address lzImplementation;
    address hyperlaneHelper;
    address hyperlaneImplementation;
    address socketRouter;
    address erc4626Form;
    /// @dev erc4626TimelockForm - var needed, BaseSetup._deployProtocol() parent contract forces it
    address erc4626TimelockForm;
    address factoryStateRegistry;
    address coreStateRegistry;
    address UNDERLYING_TOKEN;
    address vault;
    /// @dev timelockVault - var needed, BaseSetup._deployProtocol() parent contract forces it
    address timelockVault;
    address srcTokenBank;
    address srcSuperRouter;
    address srcCoreStateRegistry;
    address srcFactoryStateRegistry;
    address srcSuperFormFactory;
    address dstSuperFormFactory;
    address srcErc4626Form;
    /// @dev srcErc4626TimelockForm - var needed, BaseSetup._deployProtocol() parent contract forces it
    address srcErc4626TimelockForm;
    address srcLzImplementation;
    address dstLzImplementation;
    address srcHyperlaneImplementation;
    address dstHyperlaneImplementation;
    address dstStateRegistry;
    address srcMultiTxProcessor;
    address superRegistry;
}

/*//////////////////////////////////////////////////////////////
                    ARGS TYPES
//////////////////////////////////////////////////////////////*/

struct SingleVaultCallDataArgs {
    address user;
    address fromSrc;
    address toDst;
    address underlyingToken;
    uint256 superFormId;
    uint256 amount;
    uint256 maxSlippage;
    address vaultMock;
    uint16 srcChainId;
    uint16 toChainId;
    bool multiTx;
    uint256 totalAmount;
    address sameUnderlyingCheck;
}

struct MultiVaultCallDataArgs {
    address user;
    address fromSrc;
    address[] toDst;
    address[] underlyingTokens;
    uint256[] superFormIds;
    uint256[] amounts;
    uint256[] maxSlippage;
    address[] vaultMock;
    uint16 srcChainId;
    uint16 toChainId;
    bool multiTx;
    Actions action;
}

struct BuildDepositCallDataArgs {
    address user;
    address fromSrc;
    address toDst;
    address[] underlyingToken;
    uint256[] targetSuperFormIds;
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
    uint256[] targetSuperFormIds;
    uint256[] amounts;
    uint256 maxSlippage;
    LiquidityChange actionKind;
    uint16 srcChainId;
    uint16 toChainId;
}

struct UpdateMultiVaultPayloadArgs {
    uint256 payloadId;
    uint256[] amounts;
    int256 slippage;
    uint16 targetChainId;
    TestType testType;
    bytes4 revertError;
    bytes32 revertRole;
}

struct UpdateSingleVaultPayloadArgs {
    uint256 payloadId;
    uint256 amount;
    int256 slippage;
    uint16 targetChainId;
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
