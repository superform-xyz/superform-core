#!/usr/bin/env bash
# Note: How to set defaultKey - https://www.youtube.com/watch?v=VQe7cIpaE54

# Read the RPC URL
source .env

# Example here: deployed chains initially were POLY, AVAX and GNOSIS. Now adding BSC

# Run the script
echo Running Stage 1: ...

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage1(uint256)" 0 --rpc-url $BSC_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

# All stage 1 must be done up until here

echo Running Stage 2: ...

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage2(uint256)" 0 --rpc-url $BSC_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

echo Running Stage 3: ...

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage3(uint256)" 0 --rpc-url $BSC_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

echo Configuring new chain on Stage 2 of previous chains: ...

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256)" 0 --rpc-url $POLYGON_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256)" 1 --rpc-url $AVALANCHE_RPC_URL --broadcast --slow --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256)" 2 --rpc-url $GNOSIS_RPC_URL --broadcast --slow --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
