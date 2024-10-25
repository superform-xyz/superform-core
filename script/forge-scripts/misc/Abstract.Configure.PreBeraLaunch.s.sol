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

struct UlnConfig {
    uint64 confirmations;
    // we store the length of required DVNs and optional DVNs instead of using DVN.length directly to save gas
    uint8 requiredDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
    uint8 optionalDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
    uint8 optionalDVNThreshold; // (0, optionalDVNCount]
    address[] requiredDVNs; // no duplicates. sorted an an ascending order. allowed overlap with optionalDVNs
    address[] optionalDVNs; // no duplicates. sorted an an ascending order. allowed overlap with requiredDVNs
}

abstract contract AbstractPreBeraLaunch is EnvironmentUtils {
    address[] public SuperformDVNs = [
        0x7518f30bd5867b5fA86702556245Dead173afE46,
        0xF4c489AfD83625F510947e63ff8F90dfEE0aE46C,
        0x8fb0B7D74B557e4b45EF89648BAc197EAb2E4325,
        0x1E4CE74ccf5498B19900649D9196e64BAb592451,
        0x5496d03d9065B08e5677E1c5D1107110Bb05d445,
        0xb0B2EF168F52F6d1e42f461e11117295eF992daf,
        0xEb62f578497Bdc351dD650853a751135212fAF49,
        0x2EdfE0220A74d9609c79711a65E3A2F2A85Dc83b,
        0x7A205ED4e3d7f9d0777594501705D8CD405c3B05,
        0x0E95cf21aD9376A26997c97f326C5A0a267bB8FF
    ];

    address[] public LzDVNs = [
        0x589dEDbD617e0CBcB916A9223F4d1300c294236b,
        0xfD6865c841c2d64565562fCc7e05e619A30615f0,
        0x962F502A63F5FBeB44DC9ab932122648E8352959,
        0x23DE2FE932d9043291f870324B74F820e11dc81A,
        0x2f55C492897526677C5B68fb199ea31E2c126416,
        0x6A02D83e8d433304bba74EF1c427913958187142,
        0x9e059a54699a285714207b43B055483E78FAac25,
        0xE60A3959Ca23a92BF5aAf992EF837cA7F828628a,
        0x129Ee430Cb2Ff2708CCADDBDb408a88Fe4FFd480,
        0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f
    ];

    function _setBlastDelegate(
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

        vars.srcLzImpl = _readContractsV1(env, chainNames[srcChainIndex], vars.chainId, "LayerzeroImplementation");
        assert(vars.srcLzImpl != address(0));
        assert(PROTOCOL_ADMINS[srcChainIndex] == 0x95B5837CF46E6ab340fFf3844ca5e7d8ead5B8AF);
        bytes memory txn =
            abi.encodeWithSelector(LayerzeroV2Implementation.setDelegate.selector, PROTOCOL_ADMINS[srcChainIndex]);
        addToBatch(vars.srcLzImpl, 0, txn);

        executeBatch(vars.chainId, PROTOCOL_ADMINS[srcChainIndex], manualNonces[srcChainIndex], false);
    }

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

        bytes memory txn;

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
            ulnConfig.confirmations = CONFIRMATIONS[vars.chainId][finalDeployedChains[j]];
            console.log("chainId", vars.chainId);
            console.log("finalDeployedChains[j]", finalDeployedChains[j]);
            console.log("confirmations", ulnConfig.confirmations);
            assert(ulnConfig.confirmations != 0);
            console.log("----");
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
        executeBatch(vars.chainId, PROTOCOL_ADMINS[srcChainIndex], manualNonces[srcChainIndex], false);
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
