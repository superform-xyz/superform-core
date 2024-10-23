#!/usr/bin/env bash
# Note: How to set defaultKey - https://www.youtube.com/watch?v=VQe7cIpaE54

export BARTIO_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BARTIO_RPC_URL/credential)
export FIREBLOCKS_API_KEY=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_EMERGENCY_ACTION_KEY/credential)
export FIREBLOCKS_API_PRIVATE_KEY_PATH=$(op read op://zry2qwhqux2w6qtjitg44xb7b4/V1_EMERGENCY_ACTION_SECRET_SSH/private_key)
export FIREBLOCKS_VAULT_ACCOUNT_IDS=6 #Emergency admin prod

echo Running Stage 1: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage1(uint256,uint256,uint256)" 3 0 0 --rpc-url $BARTIO_RPC_URL --slow --account default --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --broadcast

wait

# All stage 1 must be done up until here, addresses must be copied to v1 folder
