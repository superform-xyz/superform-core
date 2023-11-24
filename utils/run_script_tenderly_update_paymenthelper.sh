#!/usr/bin/env bash

BSC_DEVNET=$(tenderly devnet spawn-rpc --project superform-v1-d4 --template bscdevnet --account superform --return-url)
POLYGON_DEVNET=$(tenderly devnet spawn-rpc --project superform-v1-d4 --template polygondevnet --account superform --return-url)
AVAX_DEVNET=$(tenderly devnet spawn-rpc --project superform-v1-d4 --template avaxdevnet --account superform --return-url)

# Run the script
echo Running Stage 1: ...


FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage1(uint256)" 0 --rpc-url $BSC_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage1(uint256)" 1 --rpc-url $POLYGON_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

#wait

#FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage1(uint256)" 2 --rpc-url $AVAX_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

echo Running Stage 2: ...


FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage2(uint256)" 0 --rpc-url $BSC_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage2(uint256)" 1 --rpc-url $POLYGON_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000


wait

echo Running Update PaymentHelper: ...


FOUNDRY_PROFILE=default forge script script/UpdatePaymentHelper.s.sol:UpdatePaymentHelper --sig "updatePaymentHelper(uint256)" 0 --rpc-url $BSC_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

wait

FOUNDRY_PROFILE=default forge script script/UpdatePaymentHelper.s.sol:UpdatePaymentHelper --sig "updatePaymentHelper(uint256)" 1 --rpc-url $POLYGON_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

#wait

#FOUNDRY_PROFILE=default forge script script/UpdatePaymentHelper.s.sol:UpdatePaymentHelper --sig "updatePaymentHelper(uint256)" 2 --rpc-url $AVAX_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

#echo Running Stage 3: ...

#wait

#FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage3(uint256)" 0 --rpc-url $BSC_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

#wait

#FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage3(uint256)" 1 --rpc-url $POLYGON_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

#wait

#FOUNDRY_PROFILE=default forge script script/Mainnet.Deploy.s.sol:MainnetDeploy --sig "deployStage3(uint256)" 2 --rpc-url $AVAX_DEVNET --broadcast --unlocked --sender 0x0000000000000000000000000000000000000000

