#!/usr/bin/env bash

# Navigate to the out directory
cd ./out

# Loop over all directories
for contract_dir in */; do
  # Find the JSON file inside the contract directory
  for json_file in "$contract_dir"*.json; do
    # Check if the JSON file exists
    if [[ -f "$json_file" ]]; then
      # Check if the JSON file contains the "abi" field
      if jq -e '.abi' "$json_file" > /dev/null 2>&1; then
        # Extract the base name of the contract (without extension)
        contract_name=$(basename "$json_file" .json)

        # Generate the ABI file path
        abi_file="${contract_dir}${contract_name}.abi"

        # Extract the ABI from the JSON and write it to the ABI file
        jq '.abi' "$json_file" > "$abi_file"
      fi
    fi
  done
done