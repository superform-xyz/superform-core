#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Running Script: $script...


# We specify the anvil url as http://localhost:8545
# We need to specify the sender for our local anvil node
forge script script/Local.Deploy.s.sol \
    --broadcast \
    -vvvv \
    --private-key $LOCAL_PRIVATE_KEY \
    --multi

# Once finished, we want to kill our anvil instance running in the background
trap "exit" INT TERM
trap "kill 0" EXIT
