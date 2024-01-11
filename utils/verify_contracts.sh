#!/usr/bin/env bash

# Read the RPC URL
source .env

networks=(
    8453
    42161
    # add more networks here if needed
)

api_keys=(
    $BASESCAN_API
    $ARBISCAN_API
    # add more API keys here if needed
)

## CONTRACTS VERIFICATION
super_constructor_arg="$(cast abi-encode "constructor(address)" 0xB97612A25491E34F5fd11D521c14A042eca039Fa)"
superposition_constructor_arg="$(cast abi-encode "constructor(string, address)" https://ipfs-gateway.superform.xyz/ipns/k51qzi5uqu5dg90fqdo9j63m556wlddeux4mlgyythp30zousgh3huhyzouyq8/JSON/ 0xB97612A25491E34F5fd11D521c14A042eca039Fa)"
superregistry_constructor_arg="$(cast abi-encode "constructor(address)" 0x5512926dfD71dFE572B8ABCf8dc16521cD8dc03C)"

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
    # Add more contract names here if needed
)

contract_addresses=(
    0x67812f7490d0931dA9f2A47Cc402476B08f78502
    0x377E5829f552cd3435538006e754e24fA304ABd4
    0x20aA26bC4e64F5D0Bf74e6Bb1387eba124314ca3
    0xBd0e276779619b8FA82041810A94B52795eFAAf7
    0x8D64B4b4be39769441dCA258AA2aD035E2A876f6
    0x40aF1811116541A62982a486A6B9E9287d1F115A
    0x9DC12F4CCcf34Cb3CF744696b5b98D85F12D2977
    0x3cA25b41bb127F43B5eC5b283457e8065138A850
    0x962435D50C95EBf870aC9E98954b6f0170167fa6
    0x1f03015196953f393aEb8a7bA423bE6Dd850Cf8d
    0x750f09A785cf308015EAd09D62fB0AdF92b6e56D
    0x5BC1905b3195A85DE0e831e0514005807765bB54
    0xf274b178423B0A80E4c731419DcaD4363f6f9254
    0x2a489b88EcA3Ace75AA0f00AFa6659EDa5e4a7Ed
    0x4D4a0F29EFf9091360fd475fA3dB1Cc966faD958
    0xB97612A25491E34F5fd11D521c14A042eca039Fa
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