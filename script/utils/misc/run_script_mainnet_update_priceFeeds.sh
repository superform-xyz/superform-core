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
export LINEA_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/LINEA_RPC_URL/credential)
export BLAST_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BLAST_RPC_URL/credential)
# Run the script

#!/usr/bin/env bash
#https://developers.fireblocks.com/docs/ethereum-smart-contract-development

# Setup Fireblocks
export FIREBLOCKS_API_KEY=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_PAYMASTER_ACTION_KEY/credential)
export FIREBLOCKS_API_PRIVATE_KEY_PATH=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_PAYMASTER_ACTION_SECRET_SSH/private_key)
export FOUNDRY_PROFILE=production
#export FIREBLOCKS_VAULT_ACCOUNT_IDS=13 #PaymentAdmin Staging
export FIREBLOCKS_VAULT_ACCOUNT_IDS=5 #PaymentAdmin Prod

# Run the script
echo Running Update PriceFeeds: ...

export FIREBLOCKS_RPC_URL=$LINEA_RPC_URL

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.UpdatePriceFeeds.s.sol:MainnetUpdatePriceFeeds --sig "updatePriceFeeds(uint256,uint256)" 0 8 \
    --rpc-url {} --sender 0xD911673eAF0D3e15fe662D58De15511c5509bAbB --unlocked --slow --broadcast
