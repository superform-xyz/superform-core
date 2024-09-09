/// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";
import { ILayerZeroEndpointV2 } from "src/vendor/layerzero/v2/ILayerZeroEndpointV2.sol";
import { SetConfigParam } from "src/vendor/layerzero/v2/IMessageLibManager.sol";

interface ILayerzeroEndpointV2Delegates is ILayerZeroEndpointV2 {
    function delegates(address _impl) external view returns (address);
}

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 srcTrueIndex;
    uint256 dstTrueIndex;
    address receiveLib;
    address dstLzImpl;
    bytes config;
    SuperRegistry superRegistryC;
    SuperformFactory superformFactory;
    SetConfigParam[] setConfigParams;
}

struct UlnConfig {
    uint64 confirmations;
    // we store the length of required DVNs and optional DVNs instead of using DVN.length directly to save gas
    uint8 requiredDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
    uint8 optionalDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
    uint8 optionalDVNThreshold; // (0, optionalDVNCount]
    address[] requiredDVNs; // no duplicates. sorted an an ascending order. allowed overlap with optionalDVNs
    address[] optionalDVNs; // no duplicates. sorted an an ascending order. allowed overlap with requiredDVNs
}

abstract contract AbstractConfigureNewDVN is EnvironmentUtils {
    address[] public DVNs = [
        0x7a23612F07d81F16B26cF0b5a4C3eca0E8668df2,
        0xfE1cD27827E16b07E61A4AC96b521bDB35e00328,
        0xcFf5b0608Fa638333f66e0dA9d4f1eB906Ac18e3,
        0x247624e2143504730aeC22912ed41F092498bEf2,
        0x9bCd17A654bffAa6f8fEa38D19661a7210e22196,
        0x19670Df5E16bEa2ba9b9e68b48C054C5bAEa06B8,
        0xDd7B5E1dB4AaFd5C8EC3b764eFB8ed265Aa5445B,
        0x247624e2143504730aeC22912ed41F092498bEf2,
        0xF45742BbfaBCEe739eA2a2d0BA2dd140F1f2C6A3,
        0xabC9b1819cc4D9846550F928B985993cF6240439
    ];

    function _configureReceiveDVN(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = finalDeployedChains[i];
        vars.srcTrueIndex = _getTrueIndex(vars.chainId);

        console.log(vars.chainId);

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        /// @dev configure receive DVN on the destination chain
        address lzImpl = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroImplementation");
        assert(lzImpl != address(0));

        console.log("Setting delegate");
        if (ILayerzeroEndpointV2Delegates(lzV2Endpoint).delegates(lzImpl) == address(0)) {
            /// @dev set delegate
            LayerzeroV2Implementation(lzImpl).setDelegate(0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92);
        }

        UlnConfig memory ulnConfig;

        ulnConfig.confirmations = 10;
        ulnConfig.requiredDVNCount = 1;
        ulnConfig.optionalDVNCount = 0;

        address[] memory optionalDVNs = new address[](0);
        ulnConfig.optionalDVNs = optionalDVNs;

        address[] memory requiredDVNs = new address[](1);

        /// @dev set receive config
        for (uint256 j; j < finalDeployedChains.length; j++) {
            if (finalDeployedChains[j] == vars.chainId) {
                continue;
            }

            vars.dstTrueIndex = _getTrueIndex(finalDeployedChains[j]);
            vars.receiveLib = ILayerZeroEndpointV2(lzV2Endpoint).defaultReceiveLibrary(lz_chainIds[vars.dstTrueIndex]);

            requiredDVNs[0] = DVNs[vars.dstTrueIndex];
            ulnConfig.requiredDVNs = requiredDVNs;

            vars.config = abi.encode(ulnConfig);

            vars.setConfigParams = new SetConfigParam[](1);
            vars.setConfigParams[0] = SetConfigParam(uint32(lz_chainIds[vars.dstTrueIndex]), uint32(2), vars.config);

            ILayerZeroEndpointV2(lzV2Endpoint).setConfig(lzImpl, vars.receiveLib, vars.setConfigParams);
        }
        vm.stopBroadcast();
    }

    function _configureSendDVN(
        uint256 env,
        uint256 i,
        uint256 srcTrueIndex,
        uint256 dstTrueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = finalDeployedChains[i];
        vars.srcTrueIndex = _getTrueIndex(vars.chainId);

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        /// @dev configure send DVN on the home chain
        address lzImpl = _readContractsV1(env, chainNames[srcTrueIndex], vars.chainId, "LayerzeroImplementation");
        assert(lzImpl != address(0));

        console.log("Setting delegate");
        if (ILayerzeroEndpointV2Delegates(lzV2Endpoint).delegates(lzImpl) == address(0)) {
            /// @dev set delegate
            LayerzeroV2Implementation(lzImpl).setDelegate(0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92);
        }

        console.log("Setting config");
        UlnConfig memory ulnConfig;

        ulnConfig.confirmations = 10;
        ulnConfig.requiredDVNCount = 1;
        ulnConfig.optionalDVNCount = 0;

        address[] memory optionalDVNs = new address[](0);
        ulnConfig.optionalDVNs = optionalDVNs;

        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DVNs[vars.srcTrueIndex];
        ulnConfig.requiredDVNs = requiredDVNs;

        vars.config = abi.encode(ulnConfig);

        vars.setConfigParams = new SetConfigParam[](1);
        vars.setConfigParams[0] = SetConfigParam(uint32(lz_chainIds[vars.dstTrueIndex]), uint32(2), vars.config);

        address sendLib = ILayerZeroEndpointV2(lzV2Endpoint).defaultSendLibrary(lz_chainIds[vars.srcTrueIndex]);

        /// @dev set send config
        ILayerZeroEndpointV2(lzV2Endpoint).setConfig(lzImpl, sendLib, vars.setConfigParams);

        vm.stopBroadcast();
    }

    function _getTrueIndex(uint256 chainId) public view returns (uint256 index) {
        for (uint256 i; i < chainIds.length; i++) {
            if (chainId == chainIds[i]) {
                index = i;
                break;
            }
        }
    }
}
