// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
    LayerzeroV2Implementation lzImpl;
    HyperlaneImplementation hypImpl;
    WormholeARImplementation wormholeImpl;
    AxelarImplementation axelarImpl;
    uint8[] bridgeIds;
    address[] bridgeAddress;
}

abstract contract AbstractRescuerMissedConfig is EnvironmentUtils {
    function _configureRescuerLinea(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
    {
        assert(env == 0);
        assert(salt.length > 0);
        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();
        UpdateVars memory vars;
        vars.chainId = s_superFormChainIds[i];
        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr = vars.chainId == 250
            ? 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4
            : 0x17A332dC7B40aE701485023b219E9D6f493a2514;
        assert(address(vars.superRegistryC) == expectedSr);

        assert(trueIndex < PROTOCOL_ADMINS.length);
        address protocolAdmin = PROTOCOL_ADMINS[trueIndex];
        assert(protocolAdmin != address(0));

        address[] memory rescuerAddress = new address[](TARGET_CHAINS.length);
        bytes32[] memory ids = new bytes32[](TARGET_CHAINS.length);

        for (uint256 i; i < rescuerAddress.length; i++) {
            ids[i] = keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE");
            rescuerAddress[i] = CSR_RESCUER;
        }
        vars.superRegistryC.batchSetAddress(ids, rescuerAddress, TARGET_CHAINS);

        vm.stopBroadcast();
    }

    function _configureRescuerBlast(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
    {
        assert(env == 0);
        assert(salt.length > 0);
        UpdateVars memory vars;
        vars.chainId = s_superFormChainIds[i];
        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr = vars.chainId == 250
            ? 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4
            : 0x17A332dC7B40aE701485023b219E9D6f493a2514;
        assert(address(vars.superRegistryC) == expectedSr);

        assert(trueIndex < PROTOCOL_ADMINS.length);
        address protocolAdmin = PROTOCOL_ADMINS[trueIndex];
        assert(protocolAdmin != address(0));

        address[] memory rescuerAddress = new address[](TARGET_CHAINS.length);
        bytes32[] memory ids = new bytes32[](TARGET_CHAINS.length);

        for (uint256 i; i < rescuerAddress.length; i++) {
            ids[i] = keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE");
            rescuerAddress[i] = CSR_RESCUER;
        }

        bytes memory txn =
            abi.encodeWithSelector(SuperRegistry.batchSetAddress.selector, ids, rescuerAddress, TARGET_CHAINS);
        addToBatch(address(vars.superRegistryC), 0, txn);

        /// Send to Safe to sign
        executeBatch(vars.chainId, protocolAdmin, 0, false);
    }
}
