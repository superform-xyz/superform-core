#!/usr/bin/env bash

# Read the RPC URL
source .env

networks=(
    1
    56
    43114
    137
    42161
    10
    8453
    # add more networks here if needed
)

api_keys=(
    $ETHEREUM_API
    $BSCSCAN_API
    $SNOWTRACE_API
    $POLYGONSCAN_API
    $ARBISCAN_API
    $OPSCAN_API
    $BASESCAN_API
    # add more API keys here if needed
)

## CONTRACTS VERIFICATION
constructor_arg="$(cast abi-encode 'constructor((address,address,address,address,address,address,address,address,address,address,address))' '(0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92,0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92,0xD911673eAF0D3e15fe662D58De15511c5509bAbB,0x23c658FE050B4eAeB9401768bF5911D11621629c,0x73009CE7cFFc6C4c5363734d1b429f0b848e0490,0x73009CE7cFFc6C4c5363734d1b429f0b848e0490,0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f,0x73009CE7cFFc6C4c5363734d1b429f0b848e0490,0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C,0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5,0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a)')"

file_names=(
    "src/settings/SuperRBAC.sol"
    # Add more file names here if needed
)

contract_names=(
    "SuperRBAC"
    # Add more contract names here if needed
)

contract_addresses=(
    0x2e639444763e402F80A9Ec9D03361Be351b9d40c
    # Add more addresses here if needed
)

constructor_args=(
    $constructor_arg
)

# loop through networks
for i in "${!networks[@]}"; do
    network="${networks[$i]}"
    api_key="${api_keys[$i]}"

    # loop through file_names and contract_names
    for j in "${!file_names[@]}"; do
        file_name="${file_names[$j]}"
        contract_name="${contract_names[$j]}"
        contract_address="${contract_addresses[$j]}"
        constructor_arg="${constructor_args[$j]}"

        # verify the contract
        if [[ $network == 43114 ]]; then
            forge verify-contract $contract_address \
                --chain-id $network \
                --num-of-optimizations 200 \
                --watch --compiler-version v0.8.23+commit.f704f362 \
                --constructor-args "$constructor_arg" \
                "$file_name:$contract_name" \
                --etherscan-api-key "$api_key" \
                --verifier-url 'https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan'
        else
            forge verify-contract $contract_address \
                --chain-id $network \
                --num-of-optimizations 200 \
                --watch --compiler-version v0.8.23+commit.f704f362 \
                --constructor-args "$constructor_arg" \
                "$file_name:$contract_name" \
                --etherscan-api-key "$api_key"
        fi
    done
done
