#!/usr/bin/env bash
# Note: How to set defaultKey - https://www.youtube.com/watch?v=VQe7cIpaE54

export ETHEREUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
export BSC_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_RPC_URL/credential)
export AVALANCHE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential)
export POLYGON_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential)
export ARBITRUM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential)
export OPTIMISM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential)
export BASE_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)
export FANTOM_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/FANTOM_RPC_URL/credential)

# Run the script

<<comment
Addresses obtained with a sample deployment to Polygon
{
  "BroadcastRegistry": "0x5767897fc69A77AC68a75001a56fcA6c421adc6f",
  "CoreStateRegistry": "0x80AAb0eA1243817E22D6ad76ebe06385900e906d",
  "DstSwapper": "0xAACA228C3fca21c41C4Ea82EBb2d8843bd830B3b",
  "ERC4626Form": "0xB2f32B62B7537304b830dE6575Fe73c41ea52991",
  "EmergencyQueue": "0x7FE59421D6b85afa86d982E3186a74c72f6c4c03",
  "HyperlaneImplementation": "0x207BFE0Fb040F17cC61B67e4aaDfC59C9e170671",
  "LayerzeroImplementation": "0x1863862794cD8ec60daBF8B473fcA928B78cE563",
  "LiFiValidator": "0xA96ced02619a4648884c3e897eD4280cd7Dfe15D",  -> Diff due to surl
  "PayMaster": "0x4E3Bcd5B7571aAf8e000D9641df8c16d70B1a4b0", -> Diff due to surl
  "PayloadHelper": "0x5Ae08549F266a9B4cC95Ad8aac57bE6Af236b647",
  "PaymentHelper": "0xe14BCe82D4a72e4C95402a83fEF3C2299a61fD8C", -> Diff due to surl + IpaymentHelper
  "RewardsDistributor": "0xb779de9C79AC9B1d9B90cc61b593C5aE4aad51D3", -> Diff due to surl
  "SocketOneInchValidator": "0x055c58C02A18105Fd44Ba18F57a79E219Ed37c43",
  "SocketValidator": "0x71060c588Aa01e61253EE4ac231Ac1a2bC672Bb8",
  "SuperPositions": "0x9AB6Dd8c4FC98F859a3271db98B81777aC2893b0",
  "SuperRBAC": "0x9736b60c4f749232d400B5605f21AE137a5Ebb71",
  "SuperRegistry": "0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47",
  "SuperformFactory": "0x9CA4480B65E5F3d57cFb942ac44A0A6Ab0B2C843",
  "SuperformRouter": "0x21b69aC55e3B620aCF74b4362D34d5E51a8187b8",
  "VaultClaimer": "0xf1930eD240cF9c4F1840aDB689E5d231687922C5",
  "WormholeARImplementation": "0x3b6FABE94a5d0B160e2E1519495e7Fe9dD009Ea3",
  "WormholeSRImplementation": "0x44b451Ca87267a62A0C853ECFbaaC1C3E528a82C"
}
comment

echo Running Stage 1: ...

FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage1(uint256,uint256)" 1 0 --rpc-url $POLYGON_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92

wait

#echo Running Stage 2: ...

#OUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage2(uint256,uint256)" 1 0 --rpc-url $FANTOM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --broadcast

#wait

#echo Running Stage 3: ...

#FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "deployStage3(uint256,uint256)" 1 0 --rpc-url $FANTOM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --broadcast

#wait

#echo Configuring new chain on Stage 2 of previous chains: ...

#FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256,uint256)" 1 0 --rpc-url $BSC_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --broadcast

#wait

#FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256,uint256)" 1 1 --rpc-url $ARBITRUM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy --broadcast

#wait

#FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256,uint256)" 1 2 --rpc-url $OPTIMISM_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy --broadcast

#wait

#FOUNDRY_PROFILE=production forge script script/forge-scripts/misc/Mainnet.Deploy.NewChain.s.sol:MainnetDeployNewChain --sig "configurePreviousChains(uint256,uint256)" 1 3 --rpc-url $BASE_RPC_URL --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92 --legacy --broadcast

#wait
