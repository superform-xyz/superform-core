#!/bin/bash

########################
# Don't trust, verify! #
########################

# @license GNU Affero General Public License v3.0 only
# @author pcaversaccio

# Check the Bash version compatibility.
if [[ "$BASH_VERSINFO" -lt 4 ]]; then
    echo "Error: This script requires Bash 4.0 or higher."
    echo "Current version: $BASH_VERSION"
    echo "Please upgrade your Bash installation."
    echo "If you've already upgraded via Homebrew, try running:"
    echo "/opt/homebrew/bin/bash $0 $@"
    exit 1
fi

# Enable strict error handling:
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error and exit.
# -o pipefail: Return the exit status of the first failed command in a pipeline.
set -euo pipefail

# Set the terminal formatting constants.
readonly GREEN="\e[32m"
readonly RED="\e[31m"
readonly UNDERLINE="\e[4m"
readonly BOLD="\e[1m"
readonly RESET="\e[0m"

# Set the type hash constants.
# => `keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");`
# See: https://github.com/safe-global/safe-smart-account/blob/a0a1d4292006e26c4dbd52282f4c932e1ffca40f/contracts/Safe.sol#L54-L57.
readonly DOMAIN_SEPARATOR_TYPEHASH="0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218"
# => `keccak256("SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)");`
# See: https://github.com/safe-global/safe-smart-account/blob/a0a1d4292006e26c4dbd52282f4c932e1ffca40f/contracts/Safe.sol#L59-L62.
readonly SAFE_TX_TYPEHASH="0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8"

# Define the associative arrays for the API URLs and chain IDs.
declare -A API_URLS
declare -A CHAIN_IDS

# Define the supported networks from the Safe transaction service.
# See https://docs.safe.global/core-api/transaction-service-supported-networks.
API_URLS=(
    ["arbitrum"]="https://safe-transaction-arbitrum.safe.global"
    ["aurora"]="https://safe-transaction-aurora.safe.global"
    ["avalanche"]="https://safe-transaction-avalanche.safe.global"
    ["base"]="https://safe-transaction-base.safe.global"
    ["base-sepolia"]="https://safe-transaction-base-sepolia.safe.global"
    ["blast"]="https://safe-transaction-blast.safe.global"
    ["bsc"]="https://safe-transaction-bsc.safe.global"
    ["celo"]="https://safe-transaction-celo.safe.global"
    ["ethereum"]="https://safe-transaction-mainnet.safe.global"
    ["gnosis"]="https://safe-transaction-gnosis-chain.safe.global"
    ["gnosis-chiado"]="https://safe-transaction-chiado.safe.global"
    ["linea"]="https://safe-transaction-linea.safe.global"
    ["mantle"]="https://safe-transaction-mantle.safe.global"
    ["optimism"]="https://safe-transaction-optimism.safe.global"
    ["polygon"]="https://safe-transaction-polygon.safe.global"
    ["polygon-zkevm"]="https://safe-transaction-zkevm.safe.global"
    ["scroll"]="https://safe-transaction-scroll.safe.global"
    ["sepolia"]="https://safe-transaction-sepolia.safe.global"
    ["worldchain"]="https://safe-transaction-worldchain.safe.global"
    ["xlayer"]="https://safe-transaction-xlayer.safe.global"
    ["zksync"]="https://safe-transaction-zksync.safe.global"
)

# Define the chain IDs of the supported networks from the Safe transaction service.
CHAIN_IDS=(
    ["arbitrum"]="42161"
    ["aurora"]="1313161554"
    ["avalanche"]="43114"
    ["base"]="8453"
    ["base-sepolia"]="84532"
    ["blast"]="81457"
    ["bsc"]="56"
    ["celo"]="42220"
    ["ethereum"]="1"
    ["gnosis"]="100"
    ["gnosis-chiado"]="10200"
    ["linea"]="59144"
    ["mantle"]="5000"
    ["optimism"]="10"
    ["polygon"]="137"
    ["polygon-zkevm"]="1101"
    ["scroll"]="534352"
    ["sepolia"]="11155111"
    ["worldchain"]="480"
    ["xlayer"]="195"
    ["zksync"]="324"
)

# Utility function to display the usage information.
usage() {
    cat <<EOF
Usage: $0 [--help] [--list-networks] --network <network> --address <address> --nonce <nonce>

Options:
  --help              Display this help message
  --list-networks     List all supported networks and their chain IDs
  --network <network> Specify the network (required)
  --address <address> Specify the Safe multisig address (required)
  --nonce <nonce>     Specify the transaction nonce (required)

Example:
  $0 --network ethereum --address 0x1234...5678 --nonce 42
EOF
    exit 1
}

# Utility function to list all supported networks.
list_networks() {
    echo "Supported Networks:"
    for network in "${!CHAIN_IDS[@]}"; do
        echo "  $network (${CHAIN_IDS[$network]})"
    done
    exit 0
}

# Utility function to print a section header.
print_header() {
    local header=$1
    if [ -t 1 ] && tput sgr0 >/dev/null 2>&1; then
        # Terminal supports formatting.
        printf "\n${UNDERLINE}%s${RESET}\n" "$header"
    else
        # Fallback for terminals without formatting support.
        printf "\n%s\n" "> $header:"
    fi
}

# Utility function to print a labelled value.
print_field() {
    local label=$1
    local value=$2
    local empty_line=${3:-false}

    if [ -t 1 ] && tput sgr0 >/dev/null 2>&1; then
        # Terminal supports formatting.
        printf "%s: ${GREEN}%s${RESET}\n" "$label" "$value"
    else
        # Fallback for terminals without formatting support.
        printf "%s: %s\n" "$label" "$value"
    fi

    # Print an empty line if requested.
    if [ "$empty_line" == "true" ]; then
        echo
    fi
}

# Utility function to format the hash (keep `0x` lowercase, rest uppercase).
format_hash() {
    local hash=$1
    local prefix="${hash:0:2}"
    local rest="${hash:2}"
    echo "${prefix,,}${rest^^}"
}

# Utility function to print the hash information.
print_hash_info() {
    local domain_hash=$1
    local message_hash=$2
    local safe_tx_hash=$3

    print_header "Hashes"
    print_field "Domain hash" "$(format_hash "$domain_hash")"
    print_field "Message hash" "$(format_hash "$message_hash")"
    print_field "Safe transaction hash" "$safe_tx_hash"
}

# Utility function to print the ABI-decoded transaction data.
print_decoded_data() {
    local data_decoded=$1

    if [[ "$data_decoded" == "0x" ]]; then
        print_field "Method" "0x (ETH Transfer)"
        print_field "Parameters" "[]"
    else
        method=$(echo "$data_decoded" | jq -r ".method")
        parameters=$(echo "$data_decoded" | jq -r ".parameters")

        print_field "Method" "$method"

        # Check if the called function is sensitive and print a warning in bold.
        case "$method" in
        addOwnerWithThreshold | removeOwner | swapOwner | changeThreshold)
            echo
            echo -e "${BOLD}${RED}WARNING: The \"$method\" function modifies the owners or threshold of the Safe. Proceed with caution!${RESET}"
            ;;
        esac

        # First process all batchSetAddress methods
        echo "$parameters" | jq -c '.[] | .valueDecoded[]? | select(.dataDecoded != null and .dataDecoded.method == "batchSetAddress")' | while read -r nested_param; do
            ids=$(echo "$nested_param" | jq -r '.dataDecoded.parameters[0].value')
            new_addresses=$(echo "$nested_param" | jq -r '.dataDecoded.parameters[1].value')
            chain_ids=$(echo "$nested_param" | jq -r '.dataDecoded.parameters[-1].value')

            # Validate IDs
            expected_id="0xf98729ec1ce0343ca1d11c51d1d2d3aa1a7b3f4f6876d0611e0a6fa86520a0cb"
            if [[ $(echo "$ids" | jq -r '.[0]') != "$expected_id" || $(echo "$ids" | jq -r '.[1]') != "$expected_id" ]]; then
                echo -e "${BOLD}${RED}ERROR: IDs validation failed. Both values must be $expected_id${RESET}"
                exit 1
            fi

            # Validate New Addresses
            expected_address="0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5"
            if [[ $(echo "$new_addresses" | jq -r '.[0]') != "$expected_address" || $(echo "$new_addresses" | jq -r '.[1]') != "$expected_address" ]]; then
                echo -e "${BOLD}${RED}ERROR: New Addresses validation failed. Both values must be $expected_address${RESET}"
                exit 1
            fi

            # Validate Chain IDs
            expected_chain_id_1="59144"
            expected_chain_id_2="81457"
            if [[ $(echo "$chain_ids" | jq -r '.[0]') != "$expected_chain_id_1" || $(echo "$chain_ids" | jq -r '.[1]') != "$expected_chain_id_2" ]]; then
                echo -e "${BOLD}${RED}ERROR: Chain IDs validation failed. First value must be $expected_chain_id_1 and second value must be $expected_chain_id_2${RESET}"
                exit 1
            fi

            echo -e "${GREEN}✓ batchSetAddress parameter validated successfully${RESET}"
        done

        # Then process all setConfig methods
        echo "$parameters" | jq -c '.[] | .valueDecoded[]? | select(.dataDecoded != null and .dataDecoded.method == "setConfig")' | while read -r nested_param; do
            eid=$(echo "$nested_param" | jq -r '.dataDecoded.parameters[-1].value[0][0]')
            uln_config=$(echo "$nested_param" | jq -r '.dataDecoded.parameters[-1].value[0][-1]')
            # Format EID according to chain mapping
            dst_chain_id=""
            case "$eid" in
            "30101")
                formatted_eid="1 (ETH)"
                dst_chain_id="1"
                ;;
            "30102")
                formatted_eid="56 (BSC)"
                dst_chain_id="56"
                ;;
            "30106")
                formatted_eid="43114 (AVAX)"
                dst_chain_id="43114"
                ;;
            "30109")
                formatted_eid="137 (POLY)"
                dst_chain_id="137"
                ;;
            "30110")
                formatted_eid="42161 (ARBI)"
                dst_chain_id="42161"
                ;;
            "30111")
                formatted_eid="10 (OP)"
                dst_chain_id="10"
                ;;
            "30184")
                formatted_eid="8453 (BASE)"
                dst_chain_id="8453"
                ;;
            "30112")
                formatted_eid="250 (FANTOM)"
                dst_chain_id="250"
                ;;
            "30183")
                formatted_eid="59144 (LINEA)"
                dst_chain_id="59144"
                ;;
            "30243")
                formatted_eid="81457 (BLAST)"
                dst_chain_id="81457"
                ;;
            *)
                formatted_eid="$eid (Unknown)"
                dst_chain_id="0"
                ;;
            esac

            # Add Foundry decode call to assert confirmations were coded as intended
            FOUNDRY_PROFILE=production forge script ./script/forge-scripts/misc/DecodeULNConfig.sol --sig "decodeULNConfig(uint64,uint64,bytes)" "$chain_id" "$dst_chain_id" "$uln_config"
            echo -e "${GREEN}✓ setConfig parameter validated successfully${RESET}"
        done



    fi
}

# Utility function to calculate the domain and message hashes.
calculate_hashes() {
    local chain_id=$1
    local address=$2
    local to=$3
    local value=$4
    local data=$5
    local operation=$6
    local safe_tx_gas=$7
    local base_gas=$8
    local gas_price=$9
    local gas_token=${10}
    local refund_receiver=${11}
    local nonce=${12}
    local data_decoded=${13}

    # Calculate the domain hash.
    local domain_hash=$(chisel eval "keccak256(abi.encode($DOMAIN_SEPARATOR_TYPEHASH, $chain_id, $address))" |
        awk '/Data:/ {gsub(/\x1b\[[0-9;]*m/, "", $3); print $3}')

    # Calculate the data hash.
    # The dynamic value `bytes` is encoded as a `keccak256` hash of its content.
    # See: https://eips.ethereum.org/EIPS/eip-712#definition-of-encodedata.
    local data_hashed=$(cast keccak "$data")

    # Encode the message.
    local message=$(cast abi-encode "SafeTxStruct(bytes32,address,uint256,bytes32,uint8,uint256,uint256,uint256,address,address,uint256)" \
        "$SAFE_TX_TYPEHASH" \
        "$to" \
        "$value" \
        "$data_hashed" \
        "$operation" \
        "$safe_tx_gas" \
        "$base_gas" \
        "$gas_price" \
        "$gas_token" \
        "$refund_receiver" \
        "$nonce")

    # Calculate the message hash.
    local message_hash=$(cast keccak "$message")

    # Calculate the Safe transaction hash.
    local safe_tx_hash=$(chisel eval "keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), bytes32($domain_hash), bytes32($message_hash)))" |
        awk '/Data:/ {gsub(/\x1b\[[0-9;]*m/, "", $3); print $3}')

    # Print the ABI-decoded transaction data.
    print_decoded_data "$data_decoded"
}

# Utility function to retrieve the API URL of the selected network.
get_api_url() {
    echo "${API_URLS[$1]:-Invalid network}" || exit 1
}

# Utility function to retrieve the chain ID of the selected network.
get_chain_id() {
    echo "${CHAIN_IDS[$1]:-Invalid network}" || exit 1
}

# Safe Transaction Hashes Calculator
# This function orchestrates the entire process of calculating the Safe transaction hashes:
# 1. Parses command-line arguments (`network`, `address`, `nonce`).
# 2. Validates that all required parameters are provided.
# 3. Retrieves the API URL and chain ID for the specified network.
# 4. Constructs the API endpoint URL.
# 5. Fetches the transaction data from the Safe transaction service API.
# 6. Extracts the relevant transaction details from the API response.
# 7. Calls the `calculate_hashes` function to compute and display the results.
calculate_safe_tx_hashes() {
    local network="" address="" nonce=""

    # Parse the command line arguments.
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --help) usage ;;
        --network)
            network="$2"
            shift 2
            ;;
        --address)
            address="$2"
            shift 2
            ;;
        --nonce)
            nonce="$2"
            shift 2
            ;;
        --list-networks) list_networks ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            ;;
        esac
    done

    # Check if the required parameters are provided.
    [ -z "$network" -o -z "$address" -o -z "$nonce" ] && usage

    # Get the API URL and chain ID for the specified network.
    local api_url=$(get_api_url "$network")
    local chain_id=$(get_chain_id "$network")
    local endpoint="${api_url}/api/v1/safes/${address}/multisig-transactions/?nonce=${nonce}"

    # Fetch the transaction data from the API.
    local response=$(curl -s "$endpoint")
    local count=$(echo "$response" | jq '.count')
    local idx=0

    # Inform the user that no transactions are available for the specified nonce.
    if [[ $count -eq 0 ]]; then
        echo "$(tput setaf 3)No transaction is available for this nonce!$(tput setaf 0)"
        exit 0
    # Notify the user about multiple transactions with identical nonce values and prompt for user input.
    elif [[ $count -gt 1 ]]; then
        cat <<EOF
$(tput setaf 3)Several transactions with identical nonce values have been detected.
This occurrence is normal if you are deliberately replacing an existing transaction.
However, if your Safe interface displays only a single transaction, this could indicate
potential irregular activity requiring your attention.$(tput sgr0)

Kindly specify the transaction's array value (available range: 0-$((${count} - 1))).
You can find the array values at the following endpoint:
$(tput setaf 2)$endpoint$(tput sgr0)

Please enter the index of the array:
EOF

        while true; do
            read -r idx

            # Validate if user input is a number.
            if ! [[ $idx =~ ^[0-9]+$ ]]; then
                echo "$(tput setaf 1)Error: Please enter a valid number!$(tput sgr0)"
                continue
            fi

            array_value=$(echo "$response" | jq ".results[$idx]")

            if [[ $array_value == null ]]; then
                echo "$(tput setaf 1)Error: No transaction found at index $idx. Please try again.$(tput sgr0)"
                continue
            fi

            break
        done
    fi

    local to=$(echo "$response" | jq -r ".results[$idx].to // \"0x0000000000000000000000000000000000000000\"")
    local value=$(echo "$response" | jq -r ".results[$idx].value // \"0\"")
    local data=$(echo "$response" | jq -r ".results[$idx].data // \"0x\"")
    local operation=$(echo "$response" | jq -r ".results[$idx].operation // \"0\"")
    local safe_tx_gas=$(echo "$response" | jq -r ".results[$idx].safeTxGas // \"0\"")
    local base_gas=$(echo "$response" | jq -r ".results[$idx].baseGas // \"0\"")
    local gas_price=$(echo "$response" | jq -r ".results[$idx].gasPrice // \"0\"")
    local gas_token=$(echo "$response" | jq -r ".results[$idx].gasToken // \"0x0000000000000000000000000000000000000000\"")
    local refund_receiver=$(echo "$response" | jq -r ".results[$idx].refundReceiver // \"0x0000000000000000000000000000000000000000\"")
    local nonce=$(echo "$response" | jq -r ".results[$idx].nonce // \"0\"")
    local data_decoded=$(echo "$response" | jq -r ".results[$idx].dataDecoded // \"0x\"")

    # Calculate and display the hashes.
    calculate_hashes "$chain_id" \
        "$address" \
        "$to" \
        "$value" \
        "$data" \
        "$operation" \
        "$safe_tx_gas" \
        "$base_gas" \
        "$gas_price" \
        "$gas_token" \
        "$refund_receiver" \
        "$nonce" \
        "$data_decoded"
}

calculate_safe_tx_hashes "$@"
