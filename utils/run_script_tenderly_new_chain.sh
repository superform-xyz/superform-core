#!/usr/bin/env bash

# Read the RPC URL
source .env

# Run the script
echo Running Stage 1: ...


FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage1(uint256)" 0 --rpc-url $BASE_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

# All stage 1 must be done up until here

echo Running Stage 2: ...


FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage2(uint256)" 0 --rpc-url $BASE_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

echo Running Stage 3: ...

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage3(uint256)" 0 --rpc-url $BASE_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

echo Configuring new chain on Stage 2 of previous chains: ...

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256)" 0 --rpc-url $ETHEREUM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256)" 1 --rpc-url $AVALANCHE_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256)" 2 --rpc-url $GNOSIS_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000
