#!/usr/bin/env bash

# Read the RPC URL
source .env

if [[ $ENVIRONMENT == "local" ]]; then
    export TENDERLY_ACCESS_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/TENDERLY_ACCESS_KEY/credential)
fi

ETHEREUM_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template ethereum-devnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
OPTIMISM_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template optimism-devnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
ARBITRUM_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template arbitrum-devnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)

# Run the script
echo Running Stage 1: ...

FOUNDRY_PROFILE=default forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage1(uint256,uint256)" 2 0 --rpc-url $ETHEREUM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000 --slow

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage1(uint256,uint256)" 2 1 --rpc-url $OPTIMISM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000 --slow

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage1(uint256,uint256)" 2 2 --rpc-url $ARBITRUM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000 --slow

wait

echo Running Stage 2: ...

FOUNDRY_PROFILE=default forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage2(uint256,uint256)" 2 0 --rpc-url $ETHEREUM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000 --slow

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage2(uint256,uint256)" 2 1 --rpc-url $OPTIMISM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000 --slow

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage2(uint256,uint256)" 2 2 --rpc-url $ARBITRUM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000 --slow

wait

echo Running Stage 3: ...

FOUNDRY_PROFILE=default forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage3(uint256,uint256)" 2 0 --rpc-url $ETHEREUM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000 --slow

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage3(uint256,uint256)" 2 1 --rpc-url $OPTIMISM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000 --slow

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage3(uint256,uint256)" 2 2 --rpc-url $ARBITRUM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000 --slow
