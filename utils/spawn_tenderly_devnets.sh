#!/usr/bin/env bash

# Read the RPC URL
source .env


# tenderly devnet spawn-rpc --project superform-v1-d4 --template ethereumdevnet --account superform
tenderly devnet spawn-rpc --project superform-v1-d4 --template avaxdevnet --account superform
tenderly devnet spawn-rpc --project superform-v1-d4 --template gnosisdevnet --account superform
