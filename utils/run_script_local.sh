#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Running Script: ...

FOUNDRY_PROFILE=default forge script script/localnet_deploy/Local.Deploy.s.sol \
    --broadcast \
    --slow \
    -vvvv
