#!/usr/bin/env bash

# Read the RPC URL
source .env

# Define the networks and their corresponding API keys
networks=(
    56
    137
    43114
    # Add more networks here if needed
)

api_keys=(
    $BSCSCAN_API
    $POLYGONSCAN_API
    $SNOWTRACE_API
    # Add more API keys here if needed
)

## CONTRACTS VERIFICATION

## CORE STATE REGISTRY

# Define the constructor arguments
constructor_args="$(cast abi-encode "constructor(address)" 0xB97612A25491E34F5fd11D521c14A042eca039Fa)"

# Define the file and contract names
file_name="src/crosschain-data/extensions/CoreStateRegistry.sol"
contract_name="CoreStateRegistry"

# Loop through networks
for i in "${!networks[@]}"; do
    network="${networks[$i]}"
    api_key="${api_keys[$i]}"

    # Verify the contract
    if [[ $network == 43114 ]]; then
        forge verify-contract 0x67812f7490d0931dA9f2A47Cc402476B08f78502 \
            --chain-id $network \
            --num-of-optimizations 200 \
            --watch --compiler-version v0.8.23+commit.f704f362 \
            --constructor-args "$constructor_args" \
            "$file_name:$contract_name" \
            --etherscan-api-key "$api_key" \
            --verifier-url 'https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan'
    else
        forge verify-contract 0x67812f7490d0931dA9f2A47Cc402476B08f78502 \
            --chain-id $network \
            --num-of-optimizations 200 \
            --watch --compiler-version v0.8.23+commit.f704f362 \
            --constructor-args "$constructor_args" \
            "$file_name:$contract_name" \
            --etherscan-api-key "$api_key"
    fi
done

## SUPER POSITIONS

# Define the constructor arguments
constructor_args="$(cast abi-encode "constructor(string, address)" https://ipfs-gateway.superform.xyz/ipns/k51qzi5uqu5dg90fqdo9j63m556wlddeux4mlgyythp30zousgh3huhyzouyq8/JSON/ 0xB97612A25491E34F5fd11D521c14A042eca039Fa)"

# Define the file and contract names
file_name="src/SuperPositions.sol"
contract_name="SuperPositions"

# Loop through networks
for i in "${!networks[@]}"; do
    network="${networks[$i]}"
    api_key="${api_keys[$i]}"

    # Verify the contract
    if [[ $network == 43114 ]]; then
        forge verify-contract 0x4D4a0F29EFf9091360fd475fA3dB1Cc966faD958 \
            --chain-id $network \
            --num-of-optimizations 200 \
            --watch --compiler-version v0.8.23+commit.f704f362 \
            --constructor-args "$constructor_args" \
            "$file_name:$contract_name" \
            --etherscan-api-key "$api_key" \
            --verifier-url 'https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan'
    else
        forge verify-contract 0x4D4a0F29EFf9091360fd475fA3dB1Cc966faD958 \
            --chain-id $network \
            --num-of-optimizations 200 \
            --watch --compiler-version v0.8.23+commit.f704f362 \
            --constructor-args "$constructor_args" \
            "$file_name:$contract_name" \
            --etherscan-api-key "$api_key"
    fi
done
