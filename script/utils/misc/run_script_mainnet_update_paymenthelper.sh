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

#!/usr/bin/env bash
#https://developers.fireblocks.com/docs/ethereum-smart-contract-development

# Read the RPC URL
source .env

# Setup Fireblocks
export FIREBLOCKS_API_KEY=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_EMERGENCY_ACTION_KEY/credential)
export FIREBLOCKS_API_PRIVATE_KEY_PATH=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_EMERGENCY_ACTION_SECRET_SSH/private_key)
export FOUNDRY_PROFILE=default
export FIREBLOCKS_VAULT_ACCOUNT_IDS=6 #Emergency admin prod

# Run the script
echo Running Update PaymentHelper: ...

export FIREBLOCKS_CHAIN_ID=1

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.UpdatePaymentHelper.s.sol:MainnetUpdatePaymentHelper --sig "updatePaymentHelper(uint256,uint256)" 0 0 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

wait

export FIREBLOCKS_CHAIN_ID=56

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.UpdatePaymentHelper.s.sol:MainnetUpdatePaymentHelper --sig "updatePaymentHelper(uint256,uint256)" 0 1 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

wait

export FIREBLOCKS_CHAIN_ID=43114

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.UpdatePaymentHelper.s.sol:MainnetUpdatePaymentHelper --sig "updatePaymentHelper(uint256,uint256)" 0 2 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

wait

export FIREBLOCKS_CHAIN_ID=137

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.UpdatePaymentHelper.s.sol:MainnetUpdatePaymentHelper --sig "updatePaymentHelper(uint256,uint256)" 0 3 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

wait

export FIREBLOCKS_CHAIN_ID=42161

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.UpdatePaymentHelper.s.sol:MainnetUpdatePaymentHelper --sig "updatePaymentHelper(uint256,uint256)" 0 4 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow --legacy

wait

export FIREBLOCKS_CHAIN_ID=10

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.UpdatePaymentHelper.s.sol:MainnetUpdatePaymentHelper --sig "updatePaymentHelper(uint256,uint256)" 0 5 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow

wait

export FIREBLOCKS_CHAIN_ID=8453

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Mainnet.UpdatePaymentHelper.s.sol:MainnetUpdatePaymentHelper --sig "updatePaymentHelper(uint256,uint256)" 0 6 \
    --rpc-url {} --sender 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 --broadcast --unlocked --slow
