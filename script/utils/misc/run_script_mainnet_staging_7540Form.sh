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
export BLAST_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BLAST_RPC_URL/credential)
export LINEA_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/LINEA_RPC_URL/credential)

Run the script
# echo Deploying new form: ...
<<c
FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "deploy7540Form(uint256,uint256,uint256)" 1 0 1 --rpc-url $BSC_RPC_URL --slow --broadcast  --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "deploy7540Form(uint256,uint256,uint256)" 1 1 1 --rpc-url $ARBITRUM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "deploy7540Form(uint256,uint256,uint256)" 1 2 1 --rpc-url $OPTIMISM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "deploy7540Form(uint256,uint256,uint256)" 1 3 1 --rpc-url $BASE_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "deploy7540Form(uint256,uint256,uint256)" 1 4 1 --rpc-url $FANTOM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "deploy7540Form(uint256,uint256,uint256)" 1 5 1 --rpc-url $LINEA_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "deploy7540Form(uint256,uint256,uint256)" 1 6 1 --rpc-url $BLAST_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy
wait
c
echo Adding new form to superform factory ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "configure7540Form(uint256,uint256,uint256)" 1 0 1 --rpc-url $BSC_RPC_URL --slow --broadcast  --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "configure7540Form(uint256,uint256,uint256)" 1 1 1 --rpc-url $ARBITRUM_RPC_URL --slow --broadcast  --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "configure7540Form(uint256,uint256,uint256)" 1 2 1 --rpc-url $OPTIMISM_RPC_URL --slow --broadcast  --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "configure7540Form(uint256,uint256,uint256)" 1 3 1 --rpc-url $BASE_RPC_URL --slow --broadcast  --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "configure7540Form(uint256,uint256,uint256)" 1 4 1 --rpc-url $FANTOM_RPC_URL --slow --broadcast  --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "configure7540Form(uint256,uint256,uint256)" 1 5 1 --rpc-url $LINEA_RPC_URL --slow --broadcast  --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.7540Form.s.sol:MainnetDeploy7540Form --sig "configure7540Form(uint256,uint256,uint256)" 1 6 1 --rpc-url $BLAST_RPC_URL --slow --broadcast  --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 