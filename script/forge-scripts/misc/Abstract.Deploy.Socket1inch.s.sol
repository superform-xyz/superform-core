// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

import { BatchScript } from "../safe/BatchScript.sol";


struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    address socketOneInchValidator;
    SuperRegistry superRegistryC;
}

abstract contract AbstractDeploySocket1inch is BatchScript, EnvironmentUtils {
    mapping(uint64 chainId => address[] bridgeAddresses) public NEW_BRIDGE_ADDRESSES;

    function _deploySocket1inch(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(salt.length > 0);
        SetupVars memory vars;

        vars.chainId = s_superFormChainIds[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = NEW_BRIDGE_ADDRESSES;

        bridgeAddresses[ETH] = [0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0];
        bridgeAddresses[BSC] = [0xd286595d2e3D879596FAB51f83A702D10a6db27b];
        bridgeAddresses[AVAX] = [0xbDf50eAe568ECef74796ed6022a0d453e8432410];
        bridgeAddresses[POLY] = [0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0];
        bridgeAddresses[ARBI] = [0xaa3d9fA3aB930aE635b001d00C612aa5b14d750e];
        bridgeAddresses[OP] = [0xbDf50eAe568ECef74796ed6022a0d453e8432410];

        address superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(superRegistry == expectedSr);

        vars.socketOneInchValidator = address(new SocketOneInchValidator{ salt: salt }(superRegistry));
        contracts[vars.chainId][bytes32(bytes("SocketOneInchValidator"))] = vars.socketOneInchValidator;

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j = 0; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _addSafeStagingProtocolAdmin(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        SetupVars memory vars;
        vars.chainId = s_superFormChainIds[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        SuperRBAC srbac = SuperRBAC(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC")));

        bytes32 protocolAdminRole = srbac.PROTOCOL_ADMIN_ROLE();
        srbac.grantRole(protocolAdminRole, PROTOCOL_ADMINS_STAGING[i]);

        vm.stopBroadcast();
    }

    /// requires protocol admin
    function _configureSuperRegistry(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(salt.length > 0);
        SetupVars memory vars;

        vars.chainId = s_superFormChainIds[i];

        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = NEW_BRIDGE_ADDRESSES;

        bridgeAddresses[ETH] = [0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0];
        bridgeAddresses[BSC] = [0xd286595d2e3D879596FAB51f83A702D10a6db27b];
        bridgeAddresses[AVAX] = [0xbDf50eAe568ECef74796ed6022a0d453e8432410];
        bridgeAddresses[POLY] = [0x2ddf16BA6d0180e5357d5e170eF1917a01b41fc0];
        bridgeAddresses[ARBI] = [0xaa3d9fA3aB930aE635b001d00C612aa5b14d750e];
        bridgeAddresses[OP] = [0xbDf50eAe568ECef74796ed6022a0d453e8432410];

        address[] memory bridgeValidators = new address[](1);
        uint8[] memory newBridgeids = new uint8[](1);

        bridgeValidators[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SocketOneInchValidator");
        newBridgeids[0] = 3;

        assert(NEW_BRIDGE_ADDRESSES[vars.chainId][0] != address(0));

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);
        bytes memory txn = abi.encodeWithSelector(
            SuperRegistry.setBridgeAddresses.selector,
            newBridgeids,
            NEW_BRIDGE_ADDRESSES[vars.chainId],
            bridgeValidators
        );

        addToBatch(address(vars.superRegistryC), 0, txn);

        /// Send to Safe to sign
        executeBatch(vars.chainId, env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i], true);
    }
}
