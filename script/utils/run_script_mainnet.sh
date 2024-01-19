#!/usr/bin/env bash
# Note: How to set defaultKey - https://www.youtube.com/watch?v=VQe7cIpaE54

# Read the RPC URL
source .env

# Run the script
echo Running Stage 1: ...

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage1(uint256)" 0 --rpc-url $BSC_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage1(uint256)" 1 --rpc-url $AVALANCHE_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage1(uint256)" 2 --rpc-url $POLYGON_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage1(uint256)" 3 --rpc-url $ARBITRUM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage1(uint256)" 4 --rpc-url $OPTIMISM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage1(uint256)" 5 --rpc-url $BASE_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

echo Running Stage 2: ...

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage2(uint256)" 0 --rpc-url $BSC_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage2(uint256)" 1 --rpc-url $AVALANCHE_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage2(uint256)" 2 --rpc-url $POLYGON_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage2(uint256)" 3 --rpc-url $ARBITRUM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage2(uint256)" 4 --rpc-url $OPTIMISM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage2(uint256)" 5 --rpc-url $BASE_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

echo Running Stage 3: ...

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage3(uint256)" 0 --rpc-url $BSC_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage3(uint256)" 1 --rpc-url $AVALANCHE_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage3(uint256)" 2 --rpc-url $POLYGON_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage3(uint256)" 3 --rpc-url $ARBITRUM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage3(uint256)" 4 --rpc-url $OPTIMISM_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage3(uint256)" 5 --rpc-url $BASE_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
