#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Running Script: ...

forge script script/Local.Deploy.s.sol \
    --broadcast \
    -vvvv \
    --private-key $LOCAL_PRIVATE_KEY

