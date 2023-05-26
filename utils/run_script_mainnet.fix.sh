#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Running Script: ...

forge script script/BSC.fix.s.sol:Fix --sig "deploy()" --rpc-url $BSC_RPC_URL --broadcast \
    --force \
    --slow 
