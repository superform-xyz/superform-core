#!/usr/bin/env bash

export ETHEREUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
export BSC_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_RPC_URL/credential)
export AVALANCHE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential)
export POLYGON_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential)
export ARBITRUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential)
export OPTIMISM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential)
export BASE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)

# Run the script
echo Starting anvil

anvil --fork-url $ETHEREUM_RPC_URL &
anvil --fork-url $BSC_RPC_URL -p 8546 &
anvil --fork-url $AVALANCHE_RPC_URL -p 8547 &
anvil --fork-url $POLYGON_RPC_URL -p 8548 &
#anvil --fork-url $ARBITRUM_RPC_URL -p 8549 &
#anvil --fork-url $OPTIMISM_RPC_URL -p 8550 &
#anvil --fork-url $FANTOM_RPC_URL -p 8551 &

wait
