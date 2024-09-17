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

# echo Deploying layerzero v1: ...

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployLayerzeroV1( uint256,uint256, uint256)" 0 0 0 --rpc-url $ETHEREUM_RPC_URL --slow --broadcast  --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployLayerzeroV1( uint256,uint256, uint256)" 0 1 0 --rpc-url $BSC_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployLayerzeroV1( uint256,uint256, uint256)" 0 2 0 --rpc-url $AVALANCHE_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployLayerzeroV1( uint256,uint256, uint256)" 0 3 0 --rpc-url $POLYGON_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployLayerzeroV1( uint256,uint256, uint256)" 0 4 0 --rpc-url $ARBITRUM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployLayerzeroV1( uint256,uint256, uint256)" 0 5 0 --rpc-url $OPTIMISM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployLayerzeroV1( uint256,uint256, uint256)" 0 6 0 --rpc-url $BASE_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployLayerzeroV1( uint256,uint256, uint256)" 0 7 1 --rpc-url $FANTOM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# echo Deploying payment helper v2: ...

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPaymentHelperV2( uint256,uint256, uint256)" 0 0 0 --rpc-url $ETHEREUM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPaymentHelperV2( uint256,uint256, uint256)" 0 1 0 --rpc-url $BSC_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPaymentHelperV2( uint256,uint256, uint256)" 0 2 0 --rpc-url $AVALANCHE_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPaymentHelperV2( uint256,uint256, uint256)" 0 3 0 --rpc-url $POLYGON_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPaymentHelperV2( uint256,uint256, uint256)" 0 4 0 --rpc-url $ARBITRUM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPaymentHelperV2( uint256,uint256, uint256)" 0 5 0 --rpc-url $OPTIMISM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPaymentHelperV2( uint256,uint256, uint256)" 0 6 0 --rpc-url $BASE_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait

# FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPaymentHelperV2( uint256,uint256, uint256)" 0 7 1 --rpc-url $FANTOM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
# wait
<<comment

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPayloadHelperV2( uint256,uint256, uint256)" 0 0 0 --rpc-url $ETHEREUM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPayloadHelperV2( uint256,uint256, uint256)" 0 1 0 --rpc-url $BSC_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPayloadHelperV2( uint256,uint256, uint256)" 0 2 0 --rpc-url $AVALANCHE_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPayloadHelperV2( uint256,uint256, uint256)" 0 3 0 --rpc-url $POLYGON_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait


FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPayloadHelperV2( uint256,uint256, uint256)" 0 4 0 --rpc-url $ARBITRUM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPayloadHelperV2( uint256,uint256, uint256)" 0 5 0 --rpc-url $OPTIMISM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPayloadHelperV2( uint256,uint256, uint256)" 0 6 0 --rpc-url $BASE_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "deployPayloadHelperV2( uint256,uint256, uint256)" 0 7 1 --rpc-url $FANTOM_RPC_URL --slow --broadcast --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
wait
comment
# echo Configuring payment helper via payment admin: ...

# export FIREBLOCKS_API_KEY=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_PAYMASTER_ACTION_KEY/credential)
# export FIREBLOCKS_API_PRIVATE_KEY_PATH=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_PAYMASTER_ACTION_SECRET_SSH/private_key)
# export FOUNDRY_PROFILE=production
# #export FIREBLOCKS_VAULT_ACCOUNT_IDS=13 #PaymentAdmin Staging
# export FIREBLOCKS_VAULT_ACCOUNT_IDS=5 #PaymentAdmin Prod

# export FIREBLOCKS_RPC_URL=$ETHEREUM_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPaymentAdmin(uint256, uint256, uint256)" 0 0 0 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow --legacy

# wait

# export FIREBLOCKS_RPC_URL=$BSC_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPaymentAdmin(uint256, uint256, uint256)" 0 1 0 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$AVALANCHE_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPaymentAdmin(uint256, uint256, uint256)" 0 2 0 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$POLYGON_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPaymentAdmin(uint256, uint256, uint256)" 0 3 0 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$ARBITRUM_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPaymentAdmin(uint256, uint256, uint256)" 0 4 0 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$OPTIMISM_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPaymentAdmin(uint256, uint256, uint256)" 0 5 0 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$BASE_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPaymentAdmin(uint256, uint256, uint256)" 0 6 0 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait

# export FIREBLOCKS_RPC_URL=$FANTOM_RPC_URL

# fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPaymentAdmin(uint256, uint256, uint256)" 0 7 1 \
#     --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --broadcast --unlocked --slow

# wait
<<comment
echo configuring the new amb and disabling old ambs

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configure5115AndDisableAMB( uint256,uint256, uint256)" 0 0 0 --rpc-url $ETHEREUM_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configure5115AndDisableAMB( uint256,uint256, uint256)" 0 1 0 --rpc-url $BSC_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configure5115AndDisableAMB( uint256,uint256, uint256)" 0 2 0 --rpc-url $AVALANCHE_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configure5115AndDisableAMB( uint256,uint256, uint256)" 0 3 0 --rpc-url $POLYGON_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configure5115AndDisableAMB( uint256,uint256, uint256)" 0 4 0 --rpc-url $ARBITRUM_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configure5115AndDisableAMB( uint256,uint256, uint256)" 0 5 0 --rpc-url $OPTIMISM_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configure5115AndDisableAMB( uint256,uint256, uint256)" 0 6 0 --rpc-url $BASE_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configure5115AndDisableAMB( uint256,uint256, uint256)" 0 7 1 --rpc-url $FANTOM_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait


comment
FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPayloadHelperv2( uint256,uint256, uint256)" 0 0 0 --rpc-url $ETHEREUM_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPayloadHelperv2( uint256,uint256, uint256)" 0 1 0 --rpc-url $BSC_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPayloadHelperv2( uint256,uint256, uint256)" 0 2 0 --rpc-url $AVALANCHE_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPayloadHelperv2( uint256,uint256, uint256)" 0 3 0 --rpc-url $POLYGON_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPayloadHelperv2( uint256,uint256, uint256)" 0 4 0 --rpc-url $ARBITRUM_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPayloadHelperv2( uint256,uint256, uint256)" 0 5 0 --rpc-url $OPTIMISM_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPayloadHelperv2( uint256,uint256, uint256)" 0 6 0 --rpc-url $BASE_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.ConfigureERC5115AndDisableAMBs.s.sol --sig "configureProdPayloadHelperv2( uint256,uint256, uint256)" 0 7 1 --rpc-url $FANTOM_RPC_URL --broadcast --slow --sender 0x1985df46791BEBb1e3ed9Ec60417F38CECc1D349
wait
