#!/usr/bin/env bash
# Note: How to set defaultKey - https://www.youtube.com/watch?v=VQe7cIpaE54

export ETHEREUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
export BSC_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_RPC_URL/credential)
export AVALANCHE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential)
export POLYGON_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential)
export ARBITRUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential)
export OPTIMISM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential)
export BASE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)
export FANTOM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/FANTOM_RPC_URL/credential)
export FIREBLOCKS_API_KEY=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_EMERGENCY_ACTION_KEY/credential)
export FIREBLOCKS_API_PRIVATE_KEY_PATH=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_EMERGENCY_ACTION_SECRET_SSH/private_key)
export FIREBLOCKS_VAULT_ACCOUNT_IDS=6 #Emergency admin prod

# Example here: deployed chains initially were POLY, AVAX and GNOSIS. Now adding BSC
# Run the script
# WARNING, LAST DIGIT IS 1 ONLY FOR FANTOM WHICH GOT AN ERROR WITH PROTOCOL ADMIN AND NEEDS TO BE RE-DEPLOYED
echo Running Stage 1: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage1(uint256,uint256)" 0 0 1 --rpc-url $FANTOM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

# All stage 1 must be done up until here, addresses must be copied to v1 folder

echo Running Stage 2: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage2(uint256,uint256)" 0 0 1 --rpc-url $FANTOM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

echo Running Stage 3: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage3(uint256,uint256)" 0 0 1 --rpc-url $FANTOM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

<<comment

echo Configuring new chain on Stage 2 of previous chains with emergency admin: ...
export FIREBLOCKS_RPC_URL=$ETHEREUM_RPC_URL

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 0 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow --legacy

wait

export FIREBLOCKS_RPC_URL=$BSC_RPC_URL

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 1 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

wait

export FIREBLOCKS_RPC_URL=$AVALANCHE_RPC_URL

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 2 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

wait

export FIREBLOCKS_RPC_URL=$POLYGON_RPC_URL

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 3 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

wait

export FIREBLOCKS_RPC_URL=$ARBITRUM_RPC_URL

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 4 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

wait

export FIREBLOCKS_RPC_URL=$OPTIMISM_RPC_URL

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 5 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

wait

export FIREBLOCKS_RPC_URL=$BASE_RPC_URL

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithEmergencyAdmin(uint256,uint256)" 0 6 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

wait


echo Configuring new chain on Stage 2 of previous chains with protocol admin: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 0 --rpc-url $ETHEREUM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 1 --rpc-url $BSC_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 2 --rpc-url $AVALANCHE_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 3 --rpc-url $POLYGON_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 4 --rpc-url $ARBITRUM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 5 --rpc-url $OPTIMISM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChainsWithProtocolAdmin(uint256,uint256)" 0 6 --rpc-url $BASE_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy

wait


echo Revoke burner address: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "revokeBurnerAddress(uint256,uint256)" 0 0 --rpc-url $FANTOM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait
comment
