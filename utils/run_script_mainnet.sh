#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Running Script: ...

forge script script/Test.Mainnet.Deploy.s.sol \
    --broadcast \
    -vvvv
