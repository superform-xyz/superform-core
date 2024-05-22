# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env


# only export these env vars if ENVIRONMENT = local
ifeq ($(ENVIRONMENT), local)
	export TENDERLY_ACCESS_KEY := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/TENDERLY_ACCESS_KEY/credential)
	export ETHEREUM_RPC_URL = https://rpc.tenderly.co/fork/e4500fad-9554-40d4-9499-177d801944d0
	export BSC_RPC_URL := https://rpc.tenderly.co/fork/6679678c-fc50-46dd-8cc3-47e1569dd672
	export AVALANCHE_RPC_URL := https://rpc.tenderly.co/fork/deabf805-14c7-4554-855e-1412d6a701b0
	export POLYGON_RPC_URL := https://rpc.tenderly.co/fork/dd57e71f-89e1-4c5b-a1e3-c0753b3efe94
	export ARBITRUM_RPC_URL := https://rpc.tenderly.co/fork/ba5e2bc2-c38d-4b62-a701-1ae7bbc4e56e
	export OPTIMISM_RPC_URL := https://rpc.tenderly.co/fork/1a22a9d4-ef27-41c2-8bf2-6e3c85d3ca23
	export BASE_RPC_URL := https://rpc.tenderly.co/fork/3a78f7e7-4f44-4841-9507-4d665b153c54
	export FANTOM_RPC_URL := https://rpc.tenderly.co/fork/f8e3c7ec-404d-4040-8dfa-3581d22cce3b
	export ETHEREUM_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
	export BSC_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_RPC_URL/credential)
	export AVALANCHE_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential)
	export POLYGON_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential)
	export ARBITRUM_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential)
	export OPTIMISM_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential)
	export BASE_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)
	export FANTOM_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/FANTOM_RPC_URL/credential)
endif

# deps
install:; forge install
update:; forge update

# Build & test
build :; FOUNDRY_PROFILE=production forge build
build-unoptimized :; FOUNDRY_PROFILE=localdev forge build
build-sizes :; FOUNDRY_PROFILE=production forge build --sizes
test-vvv   :; forge test --match-test test_directDepositIntoVault_Paused -vvvvv
ftest   :; forge test
test-ci :; forge test --no-match-path "test/invariant/**/*.sol"
coverage :; FOUNDRY_PROFILE=coverage forge coverage --no-match-path "test/invariant/**/*.sol" --no-match-contract SmokeTest --report lcov
coverage-t :; FOUNDRY_PROFILE=coverage forge coverage --match-contract RewardsDistributorTests --report lcov
smoke-test   :; forge test --match-contract SmokeTest -vvv
invariant   :; forge test --match-path "test/invariant/**/*.sol" -vvv
invariant-rewards   :; forge test --match-test invariant_tokenBalances -vvv
clean  :; forge clean
snapshot :; forge snapshot
fmt    :; forge fmt && forge fmt test/
ityfuzz :; ityfuzz evm -m -- forge test