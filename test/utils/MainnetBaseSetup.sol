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
    string[] public chainNames = [
        "Ethereum",
        "Binance",
        "Avalanche",
        "Polygon",
        "Arbitrum",
        "Optimism",
        "Base",
        "Fantom",
        "Sepolia",
        "Binance_testnet",
        "Linea",
        "Blast"
    ];

    enum Cycle {
        Dev,
        Prod
    }

    address[] public lzV2SendLib = [
        0xc02Ab410f0734EFa3F14628780e6e695156024C2, // ETH
        0x9F8C645f2D0b2159767Bd6E0839DE4BE49e823DE, // BSC
        0x197D1333DEA5Fe0D6600E9b396c7f1B1cFCc558a, // AVAX
        0x6c26c61a97006888ea9E4FA36584c7df57Cd9dA3, // POLY
        0x975bcD720be66659e3EB3C0e4F1866a3020E493A, // ARBI
        0x1322871e4ab09Bc7f5717189434f97bBD9546e95, // OP
        0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2, // BASE
        0xC17BaBeF02a937093363220b0FB57De04A535D5E, // FANTOM
        0x32042142DD551b4EbE17B6FEd53131dd4b4eEa06, // LINEA
        0xc1B621b18187F74c8F6D52a6F709Dd2780C09821 // BLAST
    ];
    address[] public lzV2ReceiveLib = [
        0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1, // ETH
        0xB217266c3A98C8B2709Ee26836C98cf12f6cCEC1, // BSC
        0xbf3521d309642FA9B1c91A08609505BA09752c61, // AVAX
        0x1322871e4ab09Bc7f5717189434f97bBD9546e95, // POLY
        0x7B9E184e07a6EE1aC23eAe0fe8D6Be2f663f05e6, // ARBI
        0x3c4962Ff6258dcfCafD23a814237B7d6Eb712063, // OP
        0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf, // BASE
        0xe1Dd69A2D08dF4eA6a30a91cC061ac70F98aAbe3, // FANTOM
        0xE22ED54177CE1148C557de74E4873619e6c6b205, // LINEA
        0x377530cdA84DFb2673bF4d145DCF0C4D7fdcB5b6 // BLAST
    ];

    uint256 public deployerPrivateKey;

    address public ownerAddress;

    address public EMERGENCY_ADMIN = 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490;
    address public REWARDS_ADMIN = 0xf82F3D7Df94FC2994315c32322DA6238cA2A2f7f;

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
        0xe6ca8aC2D27A1bAd2Ab6b136Eab87488c3c98Fd1,
        /// @dev FANTOM https://safe.fantom.network/home?safe=ftm:0xe6ca8aC2D27A1bAd2Ab6b136Eab87488c3c98Fd1
        0x62Bbfe3ef3faAb7045d29bC388E5A0c5033D8b77,
        /// @dev LINEA https://safe.linea.build/home?safe=linea:0x62Bbfe3ef3faAb7045d29bC388E5A0c5033D8b77
        0x95B5837CF46E6ab340fFf3844ca5e7d8ead5B8AF
        /// @dev BLAST https://blast-safe.io/home?safe=blastmainnet:0x95B5837CF46E6ab340fFf3844ca5e7d8ead5B8AF
    ];

    address[] public PROTOCOL_ADMINS_STAGING = [
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9,
        /// @dev BSC https://app.onchainden.com/safes/bnb:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9,
        /// @dev ARBI https://app.onchainden.com/safes/arb1:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        0xfe3A0C3c4980Eef00C2Ec73D8770a2D9A489fdE5,
        /// @dev OP https://app.onchainden.com/safes/oeth:0xfe3A0C3c4980Eef00C2Ec73D8770a2D9A489fdE5
        0xbd1F951F52FC7616E2F743F976295fDc5276Cfb9,
        /// @dev BASE https://app.onchainden.com/safes/base:0xbd1F951F52FC7616E2F743F976295fDc5276Cfb9
        0xdc337f59a90B1F6a016c02851559AdbE81f0B889,
        /// @dev FANTOM https://safe.fantom.network/home?safe=ftm:0xdc337f59a90B1F6a016c02851559AdbE81f0B889
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9,
        /// @dev LINEA https://safe.linea.build/home?safe=linea:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
        /// @dev BLAST https://blast-safe.io/home?safe=blastmainnet:0xBbb23AE2e3816a178f8bd405fb101D064C5071d9
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

        /// @dev 4.5-  Axelar Implementation
        contracts[chainId][bytes32(bytes("AxelarImplementation"))] =
            _readContract(chainNames[trueIndex], chainId, "AxelarImplementation");

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

        /// @dev 15  rewards distributor
        contracts[chainId][bytes32(bytes("RewardsDistributor"))] =
            _readContract(chainNames[trueIndex], chainId, "RewardsDistributor");

        /// @dev 16  5115Form
        contracts[chainId][bytes32(bytes("ERC5115Form"))] = _readContract(chainNames[trueIndex], chainId, "ERC5115Form");

        /// @dev 17  DeBridgeValidator
        contracts[chainId][bytes32(bytes("DeBridgeValidator"))] =
            _readContract(chainNames[trueIndex], chainId, "DeBridgeValidator");

        /// @dev 18  DeBridgeForwarderValidator
        contracts[chainId][bytes32(bytes("DeBridgeForwarderValidator"))] =
            _readContract(chainNames[trueIndex], chainId, "DeBridgeForwarderValidator");

        /// @dev 19  OneInchValidator
        contracts[chainId][bytes32(bytes("OneInchValidator"))] =
            _readContract(chainNames[trueIndex], chainId, "OneInchValidator");

        /// @dev 20  AsyncStateRegistry
        contracts[chainId][bytes32(bytes("AsyncStateRegistry"))] =
            _readContract(chainNames[trueIndex], chainId, "AsyncStateRegistry");

        /// @dev 21 ERC7540Form
        contracts[chainId][bytes32(bytes("ERC7540Form"))] = _readContract(chainNames[trueIndex], chainId, "ERC7540Form");
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
