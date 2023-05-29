#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Starting anvil

anvil --fork-url $ETHEREUM_RPC_URL &
anvil --fork-url $BSC_RPC_URL -p 8546 &
anvil --fork-url $AVALANCHE_RPC_URL -p 8547 &
#anvil --fork-url $POLYGON_RPC_URL -p 8548 &
anvil --fork-url $ARBITRUM_RPC_URL -p 8549 &
#anvil --fork-url $OPTIMISM_RPC_URL -p 8550 &
#anvil --fork-url $FANTOM_RPC_URL -p 8551 &

wait