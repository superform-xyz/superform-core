#!/usr/bin/env bash
# Note: How to set defaultKey - https://www.youtube.com/watch?v=VQe7cIpaE54

export ETHEREUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
export BSC_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_RPC_URL/credential)
export AVALANCHE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential)
export POLYGON_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential)
export ARBITRUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential)
export OPTIMISM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential)
export BASE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)

# Run the script
echo Deploying lifi validator v2: ...

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "deployLiFiValidatorV2(uint256,uint256)" 0 0 --broadcast --rpc-url $ETHEREUM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "deployLiFiValidatorV2(uint256,uint256)" 0 1 --broadcast --rpc-url $BSC_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "deployLiFiValidatorV2(uint256,uint256)" 0 2 --broadcast --rpc-url $AVALANCHE_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "deployLiFiValidatorV2(uint256,uint256)" 0 3 --broadcast --rpc-url $POLYGON_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "deployLiFiValidatorV2(uint256,uint256)" 0 4 --broadcast --rpc-url $ARBITRUM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy
wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "deployLiFiValidatorV2(uint256,uint256)" 0 5 --broadcast --rpc-url $OPTIMISM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "deployLiFiValidatorV2(uint256,uint256)" 0 6 --broadcast --rpc-url $BASE_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

echo Adding lifi validator v2 to super registry ...

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "configureSuperRegistry(uint256,uint256)" 0 0 --rpc-url $ETHEREUM_RPC_URL --slow --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "configureSuperRegistry(uint256,uint256)" 0 1 --rpc-url $BSC_RPC_URL --slow --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "configureSuperRegistry(uint256,uint256)" 0 2 --rpc-url $AVALANCHE_RPC_URL --slow --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "configureSuperRegistry(uint256,uint256)" 0 3 --rpc-url $POLYGON_RPC_URL --slow --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "configureSuperRegistry(uint256,uint256)" 0 4 --rpc-url $ARBITRUM_RPC_URL --slow --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "configureSuperRegistry(uint256,uint256)" 0 5 --rpc-url $OPTIMISM_RPC_URL --slow --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/misc/Mainnet.DeployLiFiValidatorV2.s.sol:MainnetDeployLiFiValidatorV2 --sig "configureSuperRegistry(uint256,uint256)" 0 6 --rpc-url $BASE_RPC_URL --slow --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
