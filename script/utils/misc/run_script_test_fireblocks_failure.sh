#!/usr/bin/env bash
source .env

# Note: add a BSC_RPC_URL of your choice to .env file
# Substitute API key and private key path with the values corresponding to vault account id 13 (address 0xc5c971e6B9F01dcf06bda896AEA3648eD6e3EFb3). We are reading this from a secure vault in 1password

export FIREBLOCKS_API_KEY=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/FB_STAGING_PAYMASTER_ACTION/credential)
export FIREBLOCKS_API_PRIVATE_KEY_PATH=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/FB_STAGING_PAYMASTER_SECRET_SSH/private_key)
export FOUNDRY_PROFILE=production
export FIREBLOCKS_VAULT_ACCOUNT_IDS=13 #PaymentAdmin Staging

echo Testing fireblocks failure

export FIREBLOCKS_CHAIN_ID=56

fireblocks-json-rpc --http -- forge script script/forge-scripts/misc/Test.Fireblocks.Failure.Staging.sol:TestFireblocksFailure --sig "testFailure(uint256,uint256)" 1 0 \
    --rpc-url {} --sender 0xc5c971e6B9F01dcf06bda896AEA3648eD6e3EFb3 --broadcast --unlocked --slow

wait
