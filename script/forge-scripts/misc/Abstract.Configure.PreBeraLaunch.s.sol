/// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";
import { ILayerZeroEndpointV2, IMessageLibManager } from "src/vendor/layerzero/v2/ILayerZeroEndpointV2.sol";
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
    address axl;
    address srcLzImpl;
    bytes config;
    SuperRegistry superRegistryC;
    AxelarImplementation axelarImpl;
    SuperformFactory superformFactory;
    SetConfigParam[] setConfigParams;
    address sendLib;
}

abstract contract AbstractPreBeraLaunch is EnvironmentUtils {
    function _configure(
        uint256 env,
        uint256 srcChainIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = finalDeployedChains[srcChainIndex];

        vars.axl = _readContractsV1(env, chainNames[srcChainIndex], vars.chainId, "AxelarImplementation");
        assert(vars.axl != address(0));
        // Configure for the source chain
        vars.srcLzImpl = _readContractsV1(env, chainNames[srcChainIndex], vars.chainId, "LayerzeroImplementation");
        assert(vars.srcLzImpl != address(0));

        vars.superRegistryC =
            SuperRegistry(_readContractsV1(env, chainNames[srcChainIndex], vars.chainId, "SuperRegistry"));
        assert(address(vars.superRegistryC) != address(0));
        bytes memory txn;

        txn = abi.encodeWithSelector(
            vars.superRegistryC.setAddress.selector, rewardsAdminRole, REWARDS_ADMIN, vars.chainId
        );
        addToBatch(address(vars.superRegistryC), 0, txn);

        console.log("Setting config");
        UlnConfig memory ulnConfig;

        ulnConfig.requiredDVNCount = 2;
        ulnConfig.optionalDVNCount = 0;

        address[] memory optionalDVNs = new address[](0);
        ulnConfig.optionalDVNs = optionalDVNs;

        address[] memory requiredDVNs = new address[](2);
        requiredDVNs[0] = SuperformDVNs[srcChainIndex];
        requiredDVNs[1] = LzDVNs[srcChainIndex];

        // Sort DVNs
        if (requiredDVNs[0] > requiredDVNs[1]) {
            (requiredDVNs[0], requiredDVNs[1]) = (requiredDVNs[1], requiredDVNs[0]);
        }

        ulnConfig.requiredDVNs = requiredDVNs;

        /// @dev default to 0 to use lz v2 defaults
        ulnConfig.confirmations = 0;

        address[] memory rescuerAddress = new address[](2);
        bytes32[] memory ids = new bytes32[](2);
        uint64[] memory targetChains = new uint64[](2);
        targetChains[0] = LINEA;
        targetChains[1] = BLAST;

        for (uint256 j; j < finalDeployedChains.length; j++) {
            if (finalDeployedChains[j] == vars.chainId) {
                continue;
            }
            vars.dstTrueIndex = _getTrueIndex(finalDeployedChains[j]);

            vars.setConfigParams = new SetConfigParam[](1);

            vars.config = abi.encode(ulnConfig);

            vars.setConfigParams[0] = SetConfigParam(uint32(lz_chainIds[vars.dstTrueIndex]), uint32(2), vars.config);

            // Set send config on source chain
            vars.sendLib = ILayerZeroEndpointV2(lzV2Endpoint).defaultSendLibrary(lz_chainIds[vars.dstTrueIndex]);
            txn = abi.encodeWithSelector(
                IMessageLibManager.setConfig.selector, vars.srcLzImpl, vars.sendLib, vars.setConfigParams
            );
            addToBatch(lzV2Endpoint, 0, txn);

            // Set receive config on source chain
            vars.receiveLib = ILayerZeroEndpointV2(lzV2Endpoint).defaultReceiveLibrary(lz_chainIds[vars.dstTrueIndex]);
            txn = abi.encodeWithSelector(
                IMessageLibManager.setConfig.selector, vars.srcLzImpl, vars.receiveLib, vars.setConfigParams
            );
            addToBatch(lzV2Endpoint, 0, txn);

            // disable Axelar's other chain info on LINEA and BLAST
            if (vars.chainId == LINEA || vars.chainId == BLAST) {
                /*
                if (finalDeployedChains[j] == LINEA || finalDeployedChains[j] == BLAST) {
                    txn = abi.encodeWithSelector(
                        AxelarImplementation.setChainId.selector,
                        finalDeployedChains[j],
                        axelar_chainIds[vars.dstTrueIndex]
                    );

                    addToBatch(vars.axl, 0, txn);
                }
                txn = abi.encodeWithSelector(
                AxelarImplementation.setReceiver.selector, axelar_chainIds[vars.dstTrueIndex], address(0xDEAD)
                );

                addToBatch(vars.axl, 0, txn);
                */
            } else {
                for (uint256 i; i < rescuerAddress.length; i++) {
                    ids[i] = keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE");
                    rescuerAddress[i] = CSR_RESCUER;
                }
                txn = abi.encodeWithSelector(
                    vars.superRegistryC.batchSetAddress.selector, ids, rescuerAddress, targetChains
                );
                addToBatch(address(vars.superRegistryC), 0, txn);
            }
        }

        // Send the batch
        executeBatch(vars.chainId, PROTOCOL_ADMINS[srcChainIndex], manualNonces[srcChainIndex], true);
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
