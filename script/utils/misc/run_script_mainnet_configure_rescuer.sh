#!/usr/bin/env bash
# Note: How to set default - https://www.youtube.com/watch?v=VQe7cIpaE54

export ETHEREUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
export BSC_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_RPC_URL/credential)
export AVALANCHE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential)
export POLYGON_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential)
export ARBITRUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential)
export OPTIMISM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential)
export BASE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)
export FANTOM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/FANTOM_RPC_URL/credential)
export LINEA_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/LINEA_RPC_URL/credential)
export BLAST_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BLAST_RPC_URL/credential)

echo Configuring bridge rescuer: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.DeployRescuerMissedConfig.s.sol:MainnetDeployRescuerMissedConfig --sig "configureRescuer(uint256,uint256, uint256)" 0 8 0 --rpc-url $LINEA_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

<<c
WARNING PAY ATTENTION TO NONCEs
echo Configuring bridge rescuer: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.DeployRescuerMissedConfig.s.sol:MainnetDeployRescuerMissedConfig --sig "configureRescuer(uint256,uint256, uint256)" 0 9 0 --rpc-url $BLAST_RPC_URL --slow --broadcast --sender 0x1985df46791bebb1e3ed9ec60417f38cecc1d349
wait
c
