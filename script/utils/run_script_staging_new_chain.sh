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

# Run the script
echo Running Stage 1: ...

#FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage1(uint256,uint256)" 1 0 --rpc-url $FANTOM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --broadcast

#wait

#echo Running Stage 2: ...

#OUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage2(uint256,uint256)" 1 0 --rpc-url $FANTOM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --broadcast

#wait

#echo Running Stage 3: ...

#FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage3(uint256,uint256)" 1 0 --rpc-url $FANTOM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --broadcast

#wait

echo Configuring new chain on Stage 2 of previous chains: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256,uint256)" 1 0 --rpc-url $BSC_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --broadcast

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256,uint256)" 1 1 --rpc-url $ARBITRUM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy --broadcast

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256,uint256)" 1 2 --rpc-url $OPTIMISM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy --broadcast

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256,uint256)" 1 3 --rpc-url $BASE_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy --broadcast

wait
