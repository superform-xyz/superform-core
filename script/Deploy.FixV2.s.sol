// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { LiFiValidator } from "src/crosschain-liquidity/lifi/LiFiValidator.sol";
import { SuperRegistry } from "src/settings/SuperRegistry.sol";
import { ERC4626Form } from "src/forms/ERC4626Form.sol";
import { ERC4626TimelockForm } from "src/forms/ERC4626TimelockForm.sol";
import { ERC4626KYCDaoForm } from "src/forms/ERC4626KYCDaoForm.sol";
import { SuperformFactory } from "src/SuperformFactory.sol";

import "forge-std/console.sol";

contract DeployContract is Script {
    enum Chains {
        Ethereum,
        Polygon,
        Bsc,
        Avalanche,
        Arbitrum,
        Optimism,
        Fantom,
        Ethereum_Fork,
        Polygon_Fork,
        Bsc_Fork,
        Avalanche_Fork,
        Arbitrum_Fork,
        Optimism_Fork,
        Fantom_Fork
    }

    enum Cycle {
        Dev,
        Prod
    }

    uint256 public deployerPrivateKey;
    address public ownerAddress;

    /// @dev liquidity bridge ids 1 is lifi
    uint8[] public bridgeIds = [1];

    mapping(uint64 chainId => address[] bridgeAddresses) public BRIDGE_ADDRESSES;

    /// @dev Mapping of chain enum to rpc url
    mapping(Chains chains => string rpcUrls) public forks;
    uint32[] public FORM_BEACON_IDS = [uint32(1), uint32(2), uint32(3)];

    uint64 public constant ETH = 1;
    uint64 public constant BSC = 56;
    uint64 public constant AVAX = 43_114;
    uint64 public constant POLY = 137;
    uint64 public constant ARBI = 42_161;
    uint64 public constant OP = 10;
    uint64 public constant FTM = 250;

    uint64[] public chainIds = [1, 56, 43_114, 137, 42_161, 10, 250];
    string[] public chainNames = ["Ethereum", "Binance", "Avalanche", "Polygon", "Arbitrum", "Optimism", "Fantom"];

    uint64[] SELECTED_CHAIN_IDS = [56, 137, 43_114];

    bytes32 salt = "SUPERFORM_2ND_DEPLOYMENT_FIX_V2";

    constructor() {
        // Mainnet
        forks[Chains.Ethereum] = "ethereum";
        forks[Chains.Polygon] = "polygon";
        forks[Chains.Bsc] = "bsc";
        forks[Chains.Avalanche] = "avalanche";
        forks[Chains.Arbitrum] = "arbitrum";
        forks[Chains.Optimism] = "optimism";
        forks[Chains.Fantom] = "fantom";

        // Mainnet Forks
        forks[Chains.Ethereum_Fork] = "ethereum_fork";
        forks[Chains.Polygon_Fork] = "polygon_fork";
        forks[Chains.Bsc_Fork] = "bsc_fork";
        forks[Chains.Avalanche_Fork] = "avalanche_fork";
        forks[Chains.Arbitrum_Fork] = "arbitrum_fork";
        forks[Chains.Optimism_Fork] = "optimism_fork";
        forks[Chains.Fantom_Fork] = "fantom_fork";
    }

    function run(uint256 selectedChainIndex) public {
        _preDeploymentSetup();
        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (SELECTED_CHAIN_IDS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;

                break;
            }
        }
        _scriptAction(selectedChainIndex, trueIndex);
    }

    function _scriptAction(uint256 i, uint256 trueIndex) public {
        deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        ownerAddress = vm.envAddress("OWNER_ADDRESS");
        address[] memory bridgeValidators = new address[](bridgeIds.length);

        vm.startBroadcast(deployerPrivateKey);
        uint64 chainId = SELECTED_CHAIN_IDS[i];

        address superRegistry = _readContract(chainNames[trueIndex], chainId, "SuperRegistry");
        console.log("read superRegistry: %s", superRegistry);

        /// @dev 3.1 - deploy Core State Registry
        address liFiValidator = address(new LiFiValidator{salt: salt}(superRegistry));

        console.log("liFiValidator: %s", liFiValidator);

        bridgeValidators[0] = liFiValidator;

        /// @dev overriding current SR bridge addresses
        SuperRegistry(superRegistry).setBridgeAddresses(bridgeIds, BRIDGE_ADDRESSES[chainId], bridgeValidators);

        /// @dev re-deploy form implementations

        // Standard ERC4626 Form
        address erc4626Form = address(new ERC4626Form{salt: salt}(superRegistry));
        console.log("erc4626Form: %s", erc4626Form);

        // Timelock + ERC4626 Form
        address erc4626TimelockForm = address(new ERC4626TimelockForm{salt: salt}(superRegistry));
        console.log("erc4626TimelockForm: %s", erc4626TimelockForm);

        // KYCDao ERC4626 Form
        address kycDao4626Form = address(new ERC4626KYCDaoForm{salt: salt}(superRegistry));
        console.log("kycDao4626Form: %s", kycDao4626Form);

        address superformFactory =
            SuperRegistry(superRegistry).getAddress(SuperRegistry(superRegistry).SUPERFORM_FACTORY());

        /// @dev upgrade formBeacon implementation
        SuperformFactory(superformFactory).updateFormBeaconLogic(FORM_BEACON_IDS[0], erc4626Form);
        SuperformFactory(superformFactory).updateFormBeaconLogic(FORM_BEACON_IDS[1], erc4626TimelockForm);
        SuperformFactory(superformFactory).updateFormBeaconLogic(FORM_BEACON_IDS[2], kycDao4626Form);

        vm.stopBroadcast();
    }

    function _preDeploymentSetup() internal {
        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = BRIDGE_ADDRESSES;
        bridgeAddresses[ETH] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[BSC] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[AVAX] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[POLY] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[ARBI] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[OP] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[FTM] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
    }

    function _readContract(
        string memory name,
        uint64 chainId,
        string memory contractName
    )
        internal
        view
        returns (address)
    {
        string memory json;
        string memory root = vm.projectRoot();
        json =
            string(abi.encodePacked(root, "/script/output/", vm.toString(uint256(chainId)), "/", name, "-latest.json"));
        string memory file = vm.readFile(json);
        return vm.parseJsonAddress(file, string(abi.encodePacked(".", contractName)));
    }
}
