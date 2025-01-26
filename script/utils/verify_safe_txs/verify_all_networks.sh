#!/bin/bash

# Define array of networks
NETWORKS=(
    "ethereum"
    "bsc"
    "avalanche"
    "polygon"
    "arbitrum"
    "optimism"
    "base"
    "linea"
    "blast"
)

# Define arrays for networks and their corresponding nonces
declare -A NETWORK_ADDRESSES=(
    ["ethereum"]="0xd26b38a64C812403fD3F87717624C80852cD6D61"
    ["bsc"]="0xf70A19b67ACC4169cA6136728016E04931D550ae"
    ["avalanche"]="0x79DD9868A1a89720981bF077A02a4A43c57080d2"
    ["polygon"]="0x5022b05721025159c82E02abCb0Daa87e357f437"
    ["arbitrum"]="0x7Fc07cAFb65d1552849BcF151F7035C5210B76f4"
    ["optimism"]="0x99620a926D68746D5F085B3f7cD62F4fFB71f0C1"
    ["base"]="0x2F973806f8863E860A553d4F2E7c2AB4A9F3b87C"
    ["linea"]="0x62Bbfe3ef3faAb7045d29bC388E5A0c5033D8b77"
    ["blast"]="0x95B5837CF46E6ab340fFf3844ca5e7d8ead5B8AF"
)

declare -A NETWORK_NONCES=(
    ["ethereum"]="24"
    ["bsc"]="24"
    ["avalanche"]="24"
    ["polygon"]="24"
    ["arbitrum"]="23"
    ["optimism"]="23"
    ["base"]="22"
    ["linea"]="6"
    ["blast"]="5"
)

# Path to the verification script
VERIFY_SCRIPT="./script/utils/verify_safe_txs/verify_network.sh"

# Check if the verification script exists
if [ ! -f "$VERIFY_SCRIPT" ]; then
    echo "Error: Verification script not found at $VERIFY_SCRIPT"
    exit 1
fi

# Iterate through each network and execute the verification script
for network in "${NETWORKS[@]}"; do
    echo "----------------------------------------"
    echo "Verifying network: $network"
    echo "Address: ${NETWORK_ADDRESSES[$network]}"
    echo "Nonce: ${NETWORK_NONCES[$network]}"
    echo "----------------------------------------"

    /opt/homebrew/bin/bash "$VERIFY_SCRIPT" \
        --network "$network" \
        --address "${NETWORK_ADDRESSES[$network]}" \
        --nonce "${NETWORK_NONCES[$network]}"

    echo -e "\n"
done

echo "Verification complete for all networks!"
