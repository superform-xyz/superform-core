#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Deploying CSR: ...

FOUNDRY_PROFILE=default forge script script/Deploy.CSR.s.sol:DeployContract --sig "deployCsr()" --rpc-url $POLYGON_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/Deploy.CSR.s.sol:DeployContract --sig "deployCsr()" --rpc-url $BSC_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/Deploy.CSR.s.sol:DeployContract --sig "deployCsr()" --rpc-url $AVALANCHE_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000
