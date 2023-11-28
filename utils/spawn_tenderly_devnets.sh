#!/usr/bin/env bash

# Read the RPC URL
source .env


tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template bscdevnet --account $TENDERLY_ACCOUNT_ID
tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template polygondevnet --account $TENDERLY_ACCOUNT_ID
tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template basedevnet --account $TENDERLY_ACCOUNT_ID