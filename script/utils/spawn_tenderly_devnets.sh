#!/usr/bin/env bash

# Read the RPC URL
source .env

if [[ $ENVIRONMENT == "local" ]]; then
    export TENDERLY_ACCESS_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/TENDERLY_ACCESS_KEY/credential)
fi

tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template bscdevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY
tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template polygondevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY
tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template basedevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY
