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
super_constructor_arg="$(cast abi-encode "constructor(address)" 0x38594203fB14f85AF738Ec1bAFe2A82a16BB48Cb)"

file_names=(
    "src/crosschain-data/BroadcastRegistry.sol"
    "src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol"
    # Add more file names here if needed
)

contract_names=(
    "BroadcastRegistry"
    "WormholeSRImplementation"
    # Add more contract names here if needed
)

contract_addresses=(
    0xdded3E0fc2472eF3F1f262dbEf5DBedF7Ba11Cd1
    0x99A4DB767Bd389Fbef3072a9ec7789F668de3fE3
    # Add more addresses here if needed
)

constructor_args=(
    $super_constructor_arg
    $super_constructor_arg
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
