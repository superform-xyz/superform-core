#!/usr/bin/env bash

# Read the RPC URL
source .env

if [[ $ENVIRONMENT == "local" ]]; then
    export TENDERLY_ACCESS_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/TENDERLY_ACCESS_KEY/credential)
fi

ETHEREUM_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template ethereum-devnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
OPTIMISM_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template optimism-devnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
ARBITRUM_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template arbitrum-devnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
LINEA_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template linea-devnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)


# Run the script
echo Running Stage 1: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage1(uint256,uint256)" 2 0 --rpc-url $ETHEREUM_DEVNET --broadcast --unlocked --sender 0xd26b38a64C812403fD3F87717624C80852cD6D61 --slow

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage1(uint256,uint256)" 2 1 --rpc-url $OPTIMISM_DEVNET --broadcast --unlocked --sender 0x99620a926D68746D5F085B3f7cD62F4fFB71f0C1 --slow

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage1(uint256,uint256)" 2 2 --rpc-url $ARBITRUM_DEVNET --broadcast --unlocked --sender 0x7Fc07cAFb65d1552849BcF151F7035C5210B76f4 --slow

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage1(uint256,uint256)" 2 3 --rpc-url $LINEA_DEVNET --broadcast --unlocked --sender 0x62Bbfe3ef3faAb7045d29bC388E5A0c5033D8b77 --slow

wait

echo Running Stage 2: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage2(uint256,uint256)" 2 0 --rpc-url $ETHEREUM_DEVNET --broadcast --unlocked --sender 0xd26b38a64C812403fD3F87717624C80852cD6D61 --slow

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage2(uint256,uint256)" 2 1 --rpc-url $OPTIMISM_DEVNET --broadcast --unlocked --sender 0x99620a926D68746D5F085B3f7cD62F4fFB71f0C1 --slow

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage2(uint256,uint256)" 2 2 --rpc-url $ARBITRUM_DEVNET --broadcast --unlocked --sender 0x7Fc07cAFb65d1552849BcF151F7035C5210B76f4 --slow

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage2(uint256,uint256)" 2 3 --rpc-url $LINEA_DEVNET --broadcast --unlocked --sender 0x62Bbfe3ef3faAb7045d29bC388E5A0c5033D8b77 --slow

wait

echo Running Stage 3: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage3(uint256,uint256)" 2 0 --rpc-url $ETHEREUM_DEVNET --broadcast --unlocked --sender 0xd26b38a64C812403fD3F87717624C80852cD6D61 --slow

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage3(uint256,uint256)" 2 1 --rpc-url $OPTIMISM_DEVNET --broadcast --unlocked --sender 0x99620a926D68746D5F085B3f7cD62F4fFB71f0C1 --slow

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage3(uint256,uint256)" 2 2 --rpc-url $ARBITRUM_DEVNET --broadcast --unlocked --sender 0x7Fc07cAFb65d1552849BcF151F7035C5210B76f4 --slow

wait

FOUNDRY_PROFILE=production forge script script/forge-scripts/Tenderly.Deploy.s.sol:TenderlyDeploy --sig "deployStage3(uint256,uint256)" 2 3 --rpc-url $LINEA_DEVNET --broadcast --unlocked --sender 0x62Bbfe3ef3faAb7045d29bC388E5A0c5033D8b77 --slow
