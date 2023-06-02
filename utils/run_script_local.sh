#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Running Script: ...

forge script script/old/Local.Deploy.s.sol \
    --broadcast \
    --slow \
    -vvvv
