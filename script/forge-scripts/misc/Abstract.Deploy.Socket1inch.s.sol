// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    address socketOneInchValidator;
    SuperRegistry superRegistryC;
}

abstract contract AbstractDeploySocket1inch is EnvironmentUtils {
    mapping(uint64 chainId => address[] bridgeAddresses) public NEW_BRIDGE_ADDRESSES;

    /// @dev Revoke roles
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

        address[] memory bridgeValidators = new address[](1);
        uint8[] memory newBridgeids = new uint8[](1);

        vars.socketOneInchValidator = address(new SocketOneInchValidator{ salt: salt }(vars.superRegistry));
        contracts[vars.chainId][bytes32(bytes("SocketOneInchValidator"))] = vars.socketOneInchValidator;

        bridgeValidators[0] = vars.socketOneInchValidator;
        newBridgeids[0] = 3;

        assert(BRIDGE_ADDRESSES[vars.chainId][0] != address(0));

        /// @dev for mainnet this part needs to be done by protocol admin
        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));

        assert(address(vars.superRegistryC) == 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47);

        vars.superRegistryC.setBridgeAddresses(newBridgeids, BRIDGE_ADDRESSES[vars.chainId], bridgeValidators);

        vm.stopBroadcast();
    }
}
