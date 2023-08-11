#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Running Script: ...

forge script script/localnet_deploy/Local.Deploy.s.sol \
    --broadcast \
    --slow \
    -vvvv
