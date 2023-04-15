#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Starting anvil

anvil --fork-url $ETHEREUM_RPC_URL &
anvil --fork-url $FANTOM_RPC_URL -p 8546

wait