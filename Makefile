# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

export ETHEREUM_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
export BSC_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_RPC_URL/credential)
export AVALANCHE_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential)
export POLYGON_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential)
export ARBITRUM_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential)
export OPTIMISM_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential)
export BASE_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)
export FANTOM_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/FANTOM_RPC_URL/credential)

# deps
install:; forge install
update:; forge update

# Build & test
build :; FOUNDRY_PROFILE=production forge build
test-vvv   :; forge test -vvvvv --match-contract SDMVW0000TokenInputNoSlippageAMB13Fantom
ftest   :; forge test
smoke-test   :; forge test --match-contract SmokeTest -vvv
invariant   :; forge test --match-test invariant_vaultShares -vvv
clean  :; forge clean
snapshot :; forge snapshot
fmt    :; forge fmt && forge fmt test/
ityfuzz :; ityfuzz evm -m -- forge test