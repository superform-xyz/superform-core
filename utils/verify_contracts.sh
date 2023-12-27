#!/bin/bash

# Define the networks
networks=(
    "--chain-id 56",
    "--chain-id 137",
    "--chain-id 43114"
    # Add more networks here if needed
)

##!! WARNING: HAVE TO LOOP THROUGH API KEYS

### CONTRACTS VERIFICATION

## CORE STATE REGISTRY

# Define the constructor arguments
constructor_args="constructor(address) $(cast abi-encode \"0xB97612A25491E34F5fd11D521c14A042eca039Fa\")"

# Define the file and contract names
file_name="src/crosschain-data/extensions/CoreStateRegistry.sol"
contract_name="CoreStateRegistry"

# Loop through networks
for network in "${networks[@]}"; do
    # Verify the contract
    forge verify-contract 0x67812f7490d0931dA9f2A47Cc402476B08f78502 \
        "$network" \
        --num-of-optimizations 200 \
        --watch \
        --compiler-version v0.8.23+commit.f704f36 \
        --constructor-args "$constructor_args" \
        "$file_name:$contract_name" \
        --etherscan-api-key "$API_KEY"
done
