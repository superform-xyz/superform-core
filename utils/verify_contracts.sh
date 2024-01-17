#!/usr/bin/env bash

# Read the RPC URL
source .env

networks=(
    10
    42161
    8453
    # add more networks here if needed
)

api_keys=(
    $OPSCAN_API
    $ARBISCAN_API
    $BASESCAN_API
    # add more API keys here if needed
)

## CONTRACTS VERIFICATION
empty_constructor_arg="$(cast abi-encode "constructor()")"
super_constructor_arg="$(cast abi-encode "constructor(address)" 0x617950dcf1Ca6177C06E100b7a1452c8906A9Ec5)"
superposition_constructor_arg="$(cast abi-encode "constructor(string, address)" https://ipfs-gateway.superform.xyz/ipns/k51qzi5uqu5dg90fqdo9j63m556wlddeux4mlgyythp30zousgh3huhyzouyq8/JSON/ 0x617950dcf1Ca6177C06E100b7a1452c8906A9Ec5)"
superregistry_constructor_arg="$(cast abi-encode "constructor(address)" 0x329788cd153E9874cfb65294C4B8EE7aDA329f60)"

file_names=(
    "src/crosschain-data/extensions/CoreStateRegistry.sol"
    "src/crosschain-liquidity/DstSwapper.sol"
    "src/forms/ERC4626Form.sol"
    "src/EmergencyQueue.sol"
    "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol"
    "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol"
    "src/crosschain-liquidity/lifi/LiFiValidator.sol"
    "src/payments/PayMaster.sol"
    "src/crosschain-data/utils/PayloadHelper.sol"
    "src/payments/PaymentHelper.sol"
    "src/crosschain-liquidity/socket/SocketValidator.sol"
    "src/SuperformFactory.sol"
    "src/SuperformRouter.sol"
    "src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol"
    "src/SuperPositions.sol"
    "src/settings/SuperRegistry.sol"
    "src/VaultClaimer.sol"
    # Add more file names here if needed
)

contract_names=(
    "CoreStateRegistry"
    "DstSwapper"
    "ERC4626Form"
    "EmergencyQueue"
    "HyperlaneImplementation"
    "LayerzeroImplementation"
    "LiFiValidator"
    "PayMaster"
    "PayloadHelper"
    "PaymentHelper"
    "SocketValidator"
    "SuperformFactory"
    "SuperformRouter"
    "WormholeARImplementation"
    "SuperPositions"
    "SuperRegistry"
    "VaultClaimer"
    # Add more contract names here if needed
)

contract_addresses=(
    0x41933290F00390578A35EEa9E8a37B5b48926b5d
    0xAD92C9A55225F3bAEE9D4f1cB807872eE8af3D18
    0x5ed70013DA6aa2c076b2d3853Eb17704CAb8c233
    0x8f24b0010E18915409B7056C9f6D264503BFEa33
    0x46968109F3b193AcE4EB1a28076b372A8951345C
    0x454866FfCA61EE5C874df00b387858Da646b5ec9
    0xE438D85618bEb99054DaeB14d2CBD976F77F360F
    0x3Fdf950794Ce55088f4b708F6D5312DF79fFf585
    0x0d002293422E020c3AE3CEF3E63e2CA4Dd31FB00
    0xf445548FC5cC3D6a4c70bb4A0aC89241370Ba2f3
    0x63eb5584bae6dBa0610F953Ff5d2EB11e8f8B920
    0xdc072816dF2812Ab30Fce59E31B2Af27d0fAB575
    0xF62c937ec43385152843aFa3707833bB4CfEE4E9
    0x039f3EBd7E0E86c235dEf8eff2FaEA8d8D974F9B
    0xD64e2FB22ADf73Ce1F23E93D08E93dc826C947bc
    0x617950dcf1Ca6177C06E100b7a1452c8906A9Ec5
    0x2EA3C881C91E1529329413D57E1B280D45E51dDD
    # Add more addresses here if needed
)

constructor_args=(
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $superposition_constructor_arg
    $superregistry_constructor_arg
    $empty_constructor_arg
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
