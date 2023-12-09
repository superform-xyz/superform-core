#!/usr/bin/env bash

# Read the RPC URL
source .env

BASE_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template basedevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
ARBITRUM_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template arbitrumdevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
OPTIMISM_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template optimismdevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
FANTOM_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template fantomdevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
ETHEREUM_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template ethereumdevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)

# Run the script
echo Running Stage 1: ...


FOUNDRY_PROFILE=default forge script script/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage1(uint256,uint256)" 0 1337 --rpc-url $BASE_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage1(uint256,uint256)" 1 1337 --rpc-url $ARBITRUM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage1(uint256,uint256)" 2 1337 --rpc-url $ETHEREUM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000


wait

FOUNDRY_PROFILE=default forge script script/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage1(uint256,uint256)" 3 1337 --rpc-url $FANTOM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000


wait

echo Running Stage 2: ...


FOUNDRY_PROFILE=default forge script script/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage2(uint256)" 0 --rpc-url $BASE_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage2(uint256)" 1 --rpc-url $ARBITRUM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage2(uint256)" 2 --rpc-url $ETHEREUM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000


wait

FOUNDRY_PROFILE=default forge script script/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage2(uint256)" 3 --rpc-url $FANTOM_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000


#echo Running Stage 3: ...

#wait

#FOUNDRY_PROFILE=default forge script script/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage3(uint256)" 0 --rpc-url $BSC_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

#wait

#FOUNDRY_PROFILE=default forge script script/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage3(uint256)" 1 --rpc-url $POLYGON_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

#wait

#FOUNDRY_PROFILE=default forge script script/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage3(uint256)" 2 --rpc-url $BASE_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

