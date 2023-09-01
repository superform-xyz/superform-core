#!/usr/bin/env bash

# Read the RPC URL
source .env


# Run the script
echo Running Stage 1: ...

FOUNDRY_PROFILE=default forge script script/Test.Mainnet.Deploy.Single.s.sol:TestMainnetDeploySingle --sig "deployStage1(uint256)" 0 --rpc-url $BSC_RPC_URL --broadcast --slow

wait

FOUNDRY_PROFILE=default forge script script/T#est.Mainnet.Deploy.Single.s.sol:TestMainnetDeploySingle --sig "deployStage1(uint256)" 1 --rpc-url $POLYGON_RPC_URL --broadcast --slow

wait

FOUNDRY_PROFILE=default forge script script/Test.Mainnet.Deploy.Single.s.sol:TestMainnetDeploySingle --sig "deployStage1(uint256)" 2 --rpc-url $AVALANCHE_RPC_URL --broadcast --slow

wait

# All stage 1 must be done up until here

echo Running Stage 2: ...


FOUNDRY_PROFILE=default forge script script/Test.Mainnet.Deploy.Single.s.sol:TestMainnetDeploySingle --sig "deployStage2(uint256)" 0 --rpc-url $BSC_RPC_URL --broadcast --slow

wait

FOUNDRY_PROFILE=default forge script script/Test.Mainnet.Deploy.Single.s.sol:TestMainnetDeploySingle --sig "deployStage2(uint256)" 1 --rpc-url $POLYGON_RPC_URL --broadcast --slow

wait

FOUNDRY_PROFILE=default forge script script/Test.Mainnet.Deploy.Single.s.sol:TestMainnetDeploySingle --sig "deployStage2(uint256)" 2 --rpc-url $AVALANCHE_RPC_URL --broadcast --slow

