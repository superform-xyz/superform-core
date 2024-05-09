// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @dev lib imports
import "./BaseSetup.sol";

abstract contract MainnetBaseSetup is BaseSetup {
    /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
    //////////////////////////////////////////////////////////////*/

    string public folderToRead;
    uint64[] TARGET_DEPLOYMENT_CHAINS;
    string[] public chainNames =
        ["Ethereum", "Binance", "Avalanche", "Polygon", "Arbitrum", "Optimism", "Base", "Fantom"];

    enum Cycle {
        Dev,
        Prod
    }

    uint256 public deployerPrivateKey;

    address public ownerAddress;

    address public EMERGENCY_ADMIN = 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490;

    address[] public PROTOCOL_ADMINS = [
        0xd26b38a64C812403fD3F87717624C80852cD6D61,
        /// @dev ETH https://app.onchainden.com/safes/eth:0xd26b38a64c812403fd3f87717624c80852cd6d61
        0xf70A19b67ACC4169cA6136728016E04931D550ae,
        /// @dev BSC https://app.onchainden.com/safes/bnb:0xf70a19b67acc4169ca6136728016e04931d550ae
        0x79DD9868A1a89720981bF077A02a4A43c57080d2,
        /// @dev AVAX https://app.onchainden.com/safes/avax:0x79dd9868a1a89720981bf077a02a4a43c57080d2
        0x5022b05721025159c82E02abCb0Daa87e357f437,
        /// @dev POLY https://app.onchainden.com/safes/matic:0x5022b05721025159c82e02abcb0daa87e357f437
        0x7Fc07cAFb65d1552849BcF151F7035C5210B76f4,
        /// @dev ARBI https://app.onchainden.com/safes/arb1:0x7fc07cafb65d1552849bcf151f7035c5210b76f4
        0x99620a926D68746D5F085B3f7cD62F4fFB71f0C1,
        /// @dev OP https://app.onchainden.com/safes/oeth:0x99620a926d68746d5f085b3f7cd62f4ffb71f0c1
        0x2F973806f8863E860A553d4F2E7c2AB4A9F3b87C,
        /// @dev BASE https://app.onchainden.com/safes/base:0x2f973806f8863e860a553d4f2e7c2ab4a9f3b87c
        address(0)
        /// @dev GNOSIS FIXME - PROTOCOL ADMIN NOT SET FOR GNOSIS
    ];

    address[] public PROTOCOL_ADMINS_STAGING = [
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9,
        /// @dev BSC https://app.onchainden.com/safes/bnb:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9,
        /// @dev ARBI https://app.onchainden.com/safes/arb1:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        0xfe3A0C3c4980Eef00C2Ec73D8770a2D9A489fdE5,
        /// @dev OP https://app.onchainden.com/safes/oeth:0xfe3A0C3c4980Eef00C2Ec73D8770a2D9A489fdE5
        0xbd1F951F52FC7616E2F743F976295fDc5276Cfb9
        /// @dev BASE https://app.onchainden.com/safes/base:0xbd1F951F52FC7616E2F743F976295fDc5276Cfb9
    ];

    /// @dev environment variable setup for upgrade
    /// @param cycle deployment cycle (dev, prod)
    modifier setEnvDeploy(Cycle cycle) {
        if (cycle == Cycle.Dev) {
            (ownerAddress, deployerPrivateKey) = makeAddrAndKey("tenderly");
        } else {
            //deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
            ownerAddress = vm.envAddress("OWNER_ADDRESS");
        }

        _;
    }

    function setUp() public virtual override {
        _preDeploymentSetup(false, false);

        for (uint256 j = 0; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
            uint256 trueIndex;
            for (uint256 i = 0; i < chainIds.length; i++) {
                if (TARGET_DEPLOYMENT_CHAINS[j] == chainIds[i]) {
                    trueIndex = i;

                    break;
                }
            }

            _grabAddresses(j, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS);
        }
    }

    function _grabAddresses(
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory targetDeploymentChains
    )
        internal
        setEnvDeploy(cycle)
    {
        uint64 chainId = targetDeploymentChains[i];

        /// @dev 1 -  SuperRBAC
        contracts[chainId][bytes32(bytes("SuperRBAC"))] = _readContract(chainNames[trueIndex], chainId, "SuperRBAC");

        /// @dev 2 -  SuperRegistry
        contracts[chainId][bytes32(bytes("SuperRegistry"))] =
            _readContract(chainNames[trueIndex], chainId, "SuperRegistry");

        /// @dev 2.1 - Core State Registry
        contracts[chainId][bytes32(bytes("CoreStateRegistry"))] =
            _readContract(chainNames[trueIndex], chainId, "CoreStateRegistry");

        /// @dev 2,2 - Broadcast State Registry
        contracts[chainId][bytes32(bytes("BroadcastRegistry"))] =
            _readContract(chainNames[trueIndex], chainId, "BroadcastRegistry");

        /// @dev 3- Payment Helper
        contracts[chainId][bytes32(bytes("PaymentHelper"))] =
            _readContract(chainNames[trueIndex], chainId, "PaymentHelper");

        /// @dev 4.1-  Layerzero Implementation
        contracts[chainId][bytes32(bytes("LayerzeroImplementation"))] =
            _readContract(chainNames[trueIndex], chainId, "LayerzeroImplementation");

        /// @dev 4.2-  Hyperlane Implementation
        contracts[chainId][bytes32(bytes("HyperlaneImplementation"))] =
            _readContract(chainNames[trueIndex], chainId, "HyperlaneImplementation");

        /// @dev 4.3-  Wormhole Automatic Relayer Implementation
        contracts[chainId][bytes32(bytes("WormholeARImplementation"))] =
            _readContract(chainNames[trueIndex], chainId, "WormholeARImplementation");

        /// @dev 4.4-  Wormhole Specialized Relayer Implementation
        contracts[chainId][bytes32(bytes("WormholeSRImplementation"))] =
            _readContract(chainNames[trueIndex], chainId, "WormholeSRImplementation");

        /// @dev 5-  liquidity validators
        contracts[chainId][bytes32(bytes("LiFiValidator"))] =
            _readContract(chainNames[trueIndex], chainId, "LiFiValidator");

        contracts[chainId][bytes32(bytes("SocketValidator"))] =
            _readContract(chainNames[trueIndex], chainId, "SocketValidator");

        contracts[chainId][bytes32(bytes("SocketOneInchValidator"))] =
            _readContract(chainNames[trueIndex], chainId, "SocketOneInchValidator");

        /// @dev 6 -  SuperformFactory
        contracts[chainId][bytes32(bytes("SuperformFactory"))] =
            _readContract(chainNames[trueIndex], chainId, "SuperformFactory");

        /// @dev 7 -  4626Form implementations
        // Standard ERC4626 Form
        contracts[chainId][bytes32(bytes("ERC4626Form"))] = _readContract(chainNames[trueIndex], chainId, "ERC4626Form");

        /// @dev 8 -  SuperformRouter
        contracts[chainId][bytes32(bytes("SuperformRouter"))] =
            _readContract(chainNames[trueIndex], chainId, "SuperformRouter");

        /// @dev 9 -  SuperPositions
        contracts[chainId][bytes32(bytes("SuperPositions"))] =
            _readContract(chainNames[trueIndex], chainId, "SuperPositions");

        /// @dev 10 -  Payload Helper
        contracts[chainId][bytes32(bytes("PayloadHelper"))] =
            _readContract(chainNames[trueIndex], chainId, "PayloadHelper");

        /// @dev 11 -  PayMaster
        contracts[chainId][bytes32(bytes32("PayMaster"))] = _readContract(chainNames[trueIndex], chainId, "PayMaster");

        /// @dev 12 -  Dst Swapper
        contracts[chainId][bytes32(bytes("DstSwapper"))] = _readContract(chainNames[trueIndex], chainId, "DstSwapper");

        /// @dev 13  emergency queue
        contracts[chainId][bytes32(bytes("EmergencyQueue"))] =
            _readContract(chainNames[trueIndex], chainId, "EmergencyQueue");

        /// @dev 14  vault claimer
        contracts[chainId][bytes32(bytes("VaultClaimer"))] =
            _readContract(chainNames[trueIndex], chainId, "VaultClaimer");
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
        json = string(abi.encodePacked(root, folderToRead, vm.toString(uint256(chainId)), "/", name, "-latest.json"));
        string memory file = vm.readFile(json);
        return vm.parseJsonAddress(file, string(abi.encodePacked(".", contractName)));
    }
}
