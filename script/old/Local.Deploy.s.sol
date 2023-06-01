// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {AbstractDeploy} from "./Abstract.Deploy.s.sol";
import {MockERC20} from "../../src/test/mocks/MockERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {VaultMock} from "../../src/test/mocks/VaultMock.sol";
import {ERC4626TimelockMock} from "../../src/test/mocks/ERC4626TimelockMock.sol";
import {kycDAO4626} from "super-vaults/kycdao-4626/kycdao4626.sol";
import {AggregatorV3Interface} from "../../src/test/utils/AggregatorV3Interface.sol";

contract LocalDeploy is AbstractDeploy {
    /*//////////////////////////////////////////////////////////////
                        LOCAL DEPLOYMENT SPECIFIC SETTINGS
    //////////////////////////////////////////////////////////////*/
    string[] public UNDERLYING_TOKENS = ["DAI", "USDT", "WETH"];

    bytes[] public vaultBytecodes;

    // formbeacon id => vault name
    mapping(uint256 formBeaconId => string[] names) VAULT_NAMES;
    // chainId => formbeacon id => vault
    mapping(uint64 chainId => mapping(uint256 formBeaconId => IERC4626[] vaults)) public vaults;
    // chainId => formbeacon id => vault id
    mapping(uint64 chainId => mapping(uint256 formBeaconId => uint256[] ids)) vaultIds;

    /*//////////////////////////////////////////////////////////////
                        SELECT CHAIN IDS TO DEPLOY HERE
    //////////////////////////////////////////////////////////////*/

    uint64[] SELECTED_CHAIN_IDS = [56, 42161, 43114]; /// @dev BSC, ARBI & AVAX
    uint256[] EVM_CHAIN_IDS = [56, 42161, 43114]; /// @dev BSC, ARBI & AVAX
    Chains[] SELECTED_CHAIN_NAMES = [Chains.Bsc_Fork, Chains.Arbitrum_Fork, Chains.Avalanche_Fork];
    /*//////////////////////////////////////////////////////////////
                        CHAINLINK VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint64 => address) public PRICE_FEEDS;

    address public constant ETHEREUM_ETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant BSC_BNB_USD_FEED = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address public constant AVALANCHE_AVAX_USD_FEED = 0x0A77230d17318075983913bC2145DB16C7366156;
    address public constant POLYGON_MATIC_USD_FEED = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
    address public constant FANTOM_FTM_USD_FEED = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;

    /// @notice The main script entrypoint
    function run() external {
        uint256[] memory forkIds = _preDeploymentSetup(SELECTED_CHAIN_NAMES, Cycle.Dev);

        mapping(uint64 => address) storage priceFeeds = PRICE_FEEDS;
        priceFeeds[ETH] = ETHEREUM_ETH_USD_FEED;
        priceFeeds[BSC] = BSC_BNB_USD_FEED;
        priceFeeds[AVAX] = AVALANCHE_AVAX_USD_FEED;
        priceFeeds[POLY] = POLYGON_MATIC_USD_FEED;
        priceFeeds[ARBI] = address(0);
        priceFeeds[OP] = address(0);
        priceFeeds[FTM] = FANTOM_FTM_USD_FEED;

        _fundNativeTokens(forkIds, SELECTED_CHAIN_IDS);

        /// @dev setup vault_names for mock vault deployments
        vaultBytecodes.push(type(VaultMock).creationCode);
        vaultBytecodes.push(type(ERC4626TimelockMock).creationCode);
        vaultBytecodes.push(type(kycDAO4626).creationCode);

        string[] memory underlyingTokens = UNDERLYING_TOKENS;
        for (uint256 i = 0; i < VAULT_KINDS.length; i++) {
            for (uint256 j = 0; j < underlyingTokens.length; j++) {
                VAULT_NAMES[i].push(string.concat(underlyingTokens[j], VAULT_KINDS[i]));
            }
        }

        bytes memory bytecodeWithArgs;
        address vault;
        address UNDERLYING_TOKEN;
        uint256 vaultId;
        uint256 chainIdIndex;

        /// @dev Deployment stage 1
        for (uint256 i = 0; i < SELECTED_CHAIN_IDS.length; i++) {
            for (uint256 j = 0; j < chainIds.length; j++) {
                if (chainIds[j] == SELECTED_CHAIN_IDS[i]) {
                    chainIdIndex = j;
                    break;
                }
            }
            _setupStage1(chainIdIndex, Cycle.Dev, SELECTED_CHAIN_IDS, EVM_CHAIN_IDS, forkIds[i]);

            /// @dev 5 - Deploy UNDERLYING_TOKENS and VAULTS
            /// @dev FIXME grab testnet tokens
            /// NOTE: This loop deploys all Forms on all chainIds with all of the UNDERLYING TOKENS (id x form) x chainId
            for (uint256 j = 0; j < UNDERLYING_TOKENS.length; j++) {
                UNDERLYING_TOKEN = address(
                    new MockERC20(UNDERLYING_TOKENS[j], UNDERLYING_TOKENS[j], ownerAddress, milionTokensE18)
                );
                contracts[SELECTED_CHAIN_IDS[i]][bytes32(bytes(UNDERLYING_TOKENS[j]))] = UNDERLYING_TOKEN;
            }

            vaultId = 0;

            for (uint256 j = 0; j < FORM_BEACON_IDS.length; j++) {
                for (uint256 k = 0; k < UNDERLYING_TOKENS.length; k++) {
                    /// @dev 5 - Deploy mock Vault
                    if (j != 2) {
                        bytecodeWithArgs = abi.encodePacked(
                            vaultBytecodes[j],
                            abi.encode(
                                MockERC20(getContract(SELECTED_CHAIN_IDS[i], UNDERLYING_TOKENS[k])),
                                VAULT_NAMES[j][k],
                                VAULT_NAMES[j][k]
                            )
                        );

                        vault = _deployWithCreate2(bytecodeWithArgs, 1);
                    } else {
                        /// deploy the kycDAOVault wrapper with different args only in Polygon

                        bytecodeWithArgs = abi.encodePacked(
                            vaultBytecodes[j],
                            abi.encode(
                                MockERC20(getContract(SELECTED_CHAIN_IDS[i], UNDERLYING_TOKENS[k])),
                                kycDAOValidityAddresses[i]
                            )
                        );

                        vault = _deployWithCreate2(bytecodeWithArgs, 1);
                    }

                    /// @dev Add ERC4626Vault
                    contracts[SELECTED_CHAIN_IDS[i]][bytes32(bytes(string.concat(VAULT_NAMES[j][k])))] = vault;

                    vaults[SELECTED_CHAIN_IDS[i]][FORM_BEACON_IDS[j]].push(IERC4626(vault));
                    vaultIds[SELECTED_CHAIN_IDS[i]][FORM_BEACON_IDS[j]].push(vaultId++);
                }
            }
        }

        /// @dev Deployment Stage 2 - Setup trusted remotes and deploy superforms. This must be done after the rest of the protocol has been deployed on all chains
        for (uint256 i = 0; i < SELECTED_CHAIN_IDS.length; i++) {
            for (uint256 j = 0; j < chainIds.length; j++) {
                if (chainIds[j] == SELECTED_CHAIN_IDS[i]) {
                    chainIdIndex = j;
                    break;
                }
            }
            _setupStage2(chainIdIndex, Cycle.Dev, SELECTED_CHAIN_IDS, forkIds[i]);
        }
    }

    function _getPriceMultiplier(
        uint64 targetChainId_,
        uint256 targetForkId_,
        uint256 ethForkId_
    ) internal returns (uint256) {
        uint256 multiplier;

        if (targetChainId_ == ETH || targetChainId_ == ARBI || targetChainId_ == OP) {
            /// @dev default multiplier for chains with ETH native token

            multiplier = 1;
        } else {
            vm.selectFork(ethForkId_);
            vm.startBroadcast(deployerPrivateKey);

            int256 ethUsdPrice = _getLatestPrice(PRICE_FEEDS[ETH]);

            vm.stopBroadcast();
            vm.selectFork(targetForkId_);
            vm.startBroadcast(deployerPrivateKey);

            address targetChainPriceFeed = PRICE_FEEDS[targetChainId_];
            if (targetChainPriceFeed != address(0)) {
                int256 price = _getLatestPrice(targetChainPriceFeed);
                vm.stopBroadcast();

                multiplier = 2 * uint256(ethUsdPrice / price);
            } else {
                vm.stopBroadcast();
                multiplier = 2 * uint256(ethUsdPrice);
            }
            /// @dev return to initial fork

            vm.startBroadcast(deployerPrivateKey);
            vm.stopBroadcast();
        }

        return multiplier;
    }

    function _getLatestPrice(address priceFeed_) internal view returns (int256) {
        // prettier-ignore
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(priceFeed_).latestRoundData();
        return price;
    }

    function _fundNativeTokens(
        uint256[] memory forkIds,
        uint64[] memory s_superFormChainIds
    ) internal setEnvDeploy(Cycle.Dev) {
        for (uint256 i = 0; i < s_superFormChainIds.length; i++) {
            uint256 multiplier = _getPriceMultiplier(s_superFormChainIds[i], forkIds[i], forkIds[forkIds.length - 1]);

            uint256 amountDeployer = 100000 * multiplier * 1e18;

            vm.selectFork(forkIds[i]);
            vm.startBroadcast(deployerPrivateKey);

            vm.deal(ownerAddress, amountDeployer);

            vm.stopBroadcast();
        }
    }
}
