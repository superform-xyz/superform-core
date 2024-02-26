#!/usr/bin/env bash

# Read the .env
source .env

if [[ $ENVIRONMENT == "local" ]]; then
    export TENDERLY_ACCESS_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/TENDERLY_ACCESS_KEY/credential)
fi

BASE_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template basevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
BSC_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template bscdevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
POLYGON_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template polygondevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)
AVAX_DEVNET=$(tenderly devnet spawn-rpc --project $TENDERLY_PROJECT_SLUG --template avaxdevnet --account $TENDERLY_ACCOUNT_ID --access_key $TENDERLY_ACCESS_KEY --return-url)

# Run the script
echo Running Stage 1: ...

FOUNDRY_PROFILE=default forge script script/forge-scripts/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage1(uint256)" 0 --rpc-url $BASE_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

# All stage 1 must be done up until here

echo Running Stage 2: ...

FOUNDRY_PROFILE=default forge script script/forge-scripts/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage2(uint256)" 0 --rpc-url $BASE_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

echo Running Stage 3: ...

FOUNDRY_PROFILE=default forge script script/forge-scripts/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage3(uint256)" 0 --rpc-url $BASE_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

echo Configuring new chain on Stage 2 of previous chains: ...

FOUNDRY_PROFILE=default forge script script/forge-scripts/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256)" 0 --rpc-url $BSC_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256)" 1 --rpc-url $POLYGON_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/forge-scripts/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256)" 2 --rpc-url $AVAX_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000
