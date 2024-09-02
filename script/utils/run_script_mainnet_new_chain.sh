# #!/usr/bin/env bash
# # Note: How to set defaultKey - https://www.youtube.com/watch?v=VQe7cIpaE54

# export ETHEREUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
# export BSC_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_RPC_URL/credential)
# export AVALANCHE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential)
# export POLYGON_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential)
# export ARBITRUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential)
# export OPTIMISM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential)
# export BASE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)
# export FANTOM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/FANTOM_RPC_URL/credential)
# export FIREBLOCKS_API_KEY=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_EMERGENCY_ACTION_KEY/credential)
# export FIREBLOCKS_API_PRIVATE_KEY_PATH=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_EMERGENCY_ACTION_SECRET_SSH/private_key)
# export FIREBLOCKS_VAULT_ACCOUNT_IDS=6 #Emergency admin prod

# <<comment
# Set of contracts with improper PROTOCOL_ADMIN

# Actions taken to disable:
# - Pause Forms
# - Set vault limit to 0

# {
#   "BroadcastRegistry": "0x856ddF6348fFF6B774566cD63f2e8db3796a0965",
#   "CoreStateRegistry": "0x3721B0E122768CedDfB3Dec810E64c361177f826",
#   "DstSwapper": "0x2691638Fa19357773C186BA34924E194B4Ab6cDa",
#   "ERC4626Form": "0x58F8Cef0D825B1a609FaD0576d5F2b7399ab1335",
#   "EmergencyQueue": "0xE22DCd9264086DF7B26d97A9A9d35e8dFac819dd",
#   "HyperlaneImplementation": "0x0000000000000000000000000000000000000000",
#   "LayerzeroImplementation": "0x8a3E646d9FDAA5ce032743fCe4d81B5Fa8723Be2",
#   "LiFiValidator": "0x717de40D4e360C678aC5e195B99605bc4aAC697E",
#   "PayMaster": "0x3639492Dc83019EA36899108B4A1A47cC3b3ecAa",
#   "PayloadHelper": "0x92f98d698d2c8E0f29D1bb4d75C3A03e05e811bc",
#   "PaymentHelper": "0x722669cbE532F08bb4EB81127e6Ef386627E90be",
#   "SocketOneInchValidator": "0x3dD20fB87bc2576CB0a2D7f2E75E9D13371eee79",
#   "SocketValidator": "0x7483486862BDa9BA68Be4923E7E9945c2771Ec28",
#   "SuperPositions": "0x01dF6fb6a28a89d6bFa53b2b3F20644AbF417678",
#   "SuperRBAC": "0x480bec236e3d3AE33789908BF024850B2Fe71258",
#   "SuperRegistry": "0x17A332dC7B40aE701485023b219E9D6f493a2514",
#   "SuperformFactory": "0xD85ec15A9F814D6173bF1a89273bFB3964aAdaEC",
#   "SuperformRouter": "0xa195608C2306A26f727d5199D5A382a4508308DA",
#   "VaultClaimer": "0xC4A234A40aC13b02096Dd4aae1b8221541Dc5d5A",
#   "WormholeARImplementation": "0xbD59F0B24d7A668f2c2CEAcfa056518bB3C06A9f",
#   "WormholeSRImplementation": "0x2827eFf89affacf9E80D671bca6DeCf7dbdcCaCa"
# }

# comment

# # Example here: deployed chains initially were POLY, AVAX and GNOSIS. Now adding BSC
# # Run the script
# # WARNING, LAST DIGIT IS 1 ONLY FOR FANTOM WHICH GOT AN ERROR WITH PROTOCOL ADMIN AND NEEDS TO BE RE-DEPLOYED
# echo Running Stage 1: ...
# <<comment

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage1(uint256,uint256,uint256)" 0 0 1 --rpc-url $FANTOM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

# wait

# # All stage 1 must be done up until here, addresses must be copied to v1 folder

# echo Running Stage 2: ...

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage2(uint256,uint256,uint256)" 0 0 1 --rpc-url $FANTOM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

# wait


# echo Running Stage 3: ...

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage3(uint256,uint256,uint256)" 0 0 1 --rpc-url $FANTOM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

# wait



# echo Configuring new chain on Stage 2 of previous chains with emergency admin: ...
# export FIREBLOCKS_RPC_URL=$ETHEREUM_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 0 \
#     --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow --legacy

# wait

# export FIREBLOCKS_RPC_URL=$BSC_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 1 \
#     --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$AVALANCHE_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 2 \
#     --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$POLYGON_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 3 \
#     --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$ARBITRUM_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 4 \
#     --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$OPTIMISM_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 5 \
#     --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$BASE_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 6 \
#     --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

# wait



# echo Configuring new chain on Stage 2 of previous chains with protocol admin: ...

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 0 --rpc-url $ETHEREUM_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349

# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 1 --rpc-url $BSC_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349

# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 2 --rpc-url $AVALANCHE_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349

# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 3 --rpc-url $POLYGON_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349

# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 4 --rpc-url $ARBITRUM_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349

# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 5 --rpc-url $OPTIMISM_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349 --legacy

# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 6 --rpc-url $BASE_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349 --legacy

# wait


# echo Configure all other chains based on new chain payment helper gas values: ...

# export FIREBLOCKS_API_KEY=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_PAYMASTER_ACTION_KEY/credential)
# export FIREBLOCKS_API_PRIVATE_KEY_PATH=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_PAYMASTER_ACTION_SECRET_SSH/private_key)
# export FOUNDRY_PROFILE=production
# #export FIREBLOCKS_VAULT_ACCOUNT_IDS=13 #PaymentAdmin Staging
# export FIREBLOCKS_VAULT_ACCOUNT_IDS=5 #PaymentAdmin Prod

# export FIREBLOCKS_RPC_URL=$ETHEREUM_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configureGasAmountOfNewChainInAllChains(uint256,uint256)" 0 0 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow --legacy

# wait

# export FIREBLOCKS_RPC_URL=$BSC_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configureGasAmountOfNewChainInAllChains(uint256,uint256)" 0 1 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$AVALANCHE_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configureGasAmountOfNewChainInAllChains(uint256,uint256)" 0 2 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$POLYGON_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configureGasAmountOfNewChainInAllChains(uint256,uint256)" 0 3 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow
# wait

# export FIREBLOCKS_RPC_URL=$ARBITRUM_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configureGasAmountOfNewChainInAllChains(uint256,uint256)" 0 4 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$OPTIMISM_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configureGasAmountOfNewChainInAllChains(uint256,uint256)" 0 5 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$BASE_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configureGasAmountOfNewChainInAllChains(uint256,uint256)" 0 6 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait
# comment

# echo Revoke burner address: ...

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "revokeBurnerAddress(uint256,uint256)" 0 0 --rpc-url $FANTOM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

# wait
# x