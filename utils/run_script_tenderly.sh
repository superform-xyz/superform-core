#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Running Stage 1: ...

FOUNDRY_PROFILE=default forge script script/Test.Mainnet.Deploy.Single.s.sol:TestMainnetDeploySingle --sig "deployStage1(uint256)" 0 --rpc-url $POLYGON_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

# All stage 1 must be done up until here

echo Running Stage 2: ...

FOUNDRY_PROFILE=default forge script script/Test.Mainnet.Deploy.Single.s.sol:TestMainnetDeploySingle --sig "deployStage2(uint256)" 0 --rpc-url $POLYGON_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

