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

Run the script
echo Configuring Receive DVNs on Blast ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureReceiveDVN(uint256,uint256, uint256)" 1 6 0 --rpc-url $BLAST_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

echo Configuring Send DVNs on Blast ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 6 0 0 --rpc-url $BLAST_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 6 1 0 --rpc-url $BLAST_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 6 2 0 --rpc-url $BLAST_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 6 3 0 --rpc-url $BLAST_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 6 4 0 --rpc-url $BLAST_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 6 5 0 --rpc-url $BLAST_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

echo Configuring Receive DVNs on Other Chains ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureReceiveDVN(uint256, uint256, uint256, uint256)" 1 0 6 0 --rpc-url $BSC_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureReceiveDVN(uint256, uint256, uint256, uint256)" 1 1 6 0 --rpc-url $ARBITRUM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureReceiveDVN(uint256, uint256, uint256, uint256)" 1 2 6 0 --rpc-url $OPTIMISM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureReceiveDVN(uint256, uint256, uint256, uint256)" 1 3 6 0 --rpc-url $BASE_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureReceiveDVN(uint256, uint256, uint256, uint256)" 1 4 6 0 --rpc-url $FANTOM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureReceiveDVN(uint256, uint256, uint256, uint256)" 1 5 6 0 --rpc-url $LINEA_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

echo Configuring Send DVNs on Other Chains ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 0 6 0 --rpc-url $BSC_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 1 6 0 --rpc-url $ARBITRUM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 2 6 0 --rpc-url $OPTIMISM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 3 6 0 --rpc-url $BASE_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 4 6 0 --rpc-url $FANTOM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait 

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Configure.NewDVN.s.sol --sig "configureSendDVN(uint256, uint256, uint256, uint256)" 1 5 6 0 --rpc-url $LINEA_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait