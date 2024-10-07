# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# only export these env vars if ENVIRONMENT = local
ifeq ($(ENVIRONMENT), local)
	export ETHEREUM_RPC_URL = $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
	export BSC_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_RPC_URL/credential)
	export AVALANCHE_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential)
	export POLYGON_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential)
	export ARBITRUM_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential)
	export OPTIMISM_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential)
	export BASE_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)
	export FANTOM_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/FANTOM_RPC_URL/credential)
	export LINEA_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/LINEA_RPC_URL/credential)
	export BLAST_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BLAST_RPC_URL/credential)
	export ETHEREUM_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
	export BSC_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_RPC_URL/credential)
	export AVALANCHE_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential)
	export POLYGON_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential)
	export ARBITRUM_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential)
	export OPTIMISM_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential)
	export BASE_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)
	export FANTOM_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/FANTOM_RPC_URL/credential)
	export SEPOLIA_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/SEPOLIA_RPC_URL/credential)
	export BSC_TESTNET_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_TESTNET_RPC_URL/credential)
	export LINEA_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/LINEA_RPC_URL/credential)
	export BLAST_RPC_URL_QN := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BLAST_RPC_URL/credential)
endif

# Check for required dependencies
CHECK_FORGE := $(shell command -v forge 2> /dev/null)
CHECK_SOLC := $(shell command -v solc 2> /dev/null)
CHECK_ABIGEN := $(shell command -v abigen 2> /dev/null)
CHECK_ITYFUZZ := $(shell ityfuzz -v forge 2> /dev/null)


check-forge:
ifndef CHECK_FORGE
	$(error "Forge is not installed. Please install Forge and retry.")
endif

check-solc:
ifndef CHECK_SOLC
	$(error "Solc is not installed. Please install solc and retry.")
endif

check-abigen:
ifndef CHECK_ABIGEN
	$(error "Abigen is not installed. Please install Abigen and retry.")
endif

check-ityfuzz:
ifndef CHECK_ITYFUZZ
	$(error "ityfuzz is not installed. Please install ityfuzz and retry.")
endif

# Targets that require the checks
generate: check-forge check-solc check-abigen
install: check-forge
update: check-forge
build: check-forge
build-unoptimized: check-forge
build-sizes: check-forge
test-vvv: check-forge
ftest: check-forge
test-ci: check-forge
coverage: check-forge
coverage-t: check-forge
smoke-test: check-forge
invariant: check-forge
invariant-rewards: check-forge
clean: check-forge
snapshot: check-forge
fmt: check-forge
ityfuzz: check-ityfuzz

.PHONY: generate
generate: build ## Generates go bindings for smart contracts
	./script/utils/retrieve-abis.sh

	# General
	abigen --abi out/SuperformRouter.sol/SuperformRouter.abi --pkg contracts --type SFRouter --out contracts/SuperformRouter.go
	abigen --abi out/SuperformFactory.sol/SuperformFactory.abi --pkg contracts --type SFFactory --out contracts/SuperformFactory.go
	abigen --abi out/SuperPositions.sol/SuperPositions.abi --pkg contracts --type SuperPositions --out contracts/SuperPositions.go
	abigen --abi out/VaultClaimer.sol/VaultClaimer.abi --pkg contracts --type VaultClaimer --out contracts/VaultClaimer.go
	abigen --abi out/CoreStateRegistry.sol/CoreStateRegistry.abi --pkg contracts --type CoreStateRegistry --out contracts/CoreStateRegistry.go

	# Payments
	abigen --abi out/PaymentHelper.sol/PaymentHelper.abi --pkg contracts --type PaymentHelper --out contracts/PaymentHelper.go
	abigen --abi out/PayMaster.sol/PayMaster.abi --pkg contracts --type PayMaster --out contracts/PayMaster.go

	# Forms
	abigen --abi out/ERC4626Form.sol/ERC4626Form.abi --pkg contracts --type ERC4626Form --out contracts/ERC4626Form.go

	# Superform router plus
	abigen --abi out/SuperformRouterPlus.sol/SuperformRouterPlus.abi --pkg contracts --type SuperformRouterPlus --out contracts/SuperformRouterPlus.go
	abigen --abi out/SuperformRouterPlusAsync.sol/SuperformRouterPlusAsync.abi --pkg contracts --type SuperformRouterPlusAsync --out contracts/SuperformRouterPlusAsync.go

.PHONY: install
install: ## Installs the project
	forge install

.PHONY: update
update: ## Updates the project
	forge update

.PHONY: build
build: ## Builds the project
	FOUNDRY_PROFILE=production forge build

.PHONY: build-unoptimized
build-unoptimized: ## Builds the project unoptimized
	FOUNDRY_PROFILE=localdev forge build

.PHONY: build-sizes
build-sizes: ## Builds the project and shows sizes
	FOUNDRY_PROFILE=production forge build --sizes

.PHONY: test-vvv
test-vvv: ## Runs tests with verbose output
	forge test --match-test test_7540_claimDeposit_allErrors --evm-version cancun -vvvvv

.PHONY: ftest
ftest: ## Runs tests with cancun evm version
	forge test --evm-version cancun

.PHONY: test-ci
test-ci: ## Runs tests  in CI mode
	forge test --no-match-path "test/invariant/**/*.sol" --evm-version cancun

.PHONY: coverage
coverage: ## Runs coverage
	FOUNDRY_PROFILE=coverage forge coverage --no-match-path "test/invariant/**/*.sol" --evm-version cancun --report lcov

.PHONY: coverage-t
coverage-t:	## Runs coverage for a specific contract
	FOUNDRY_PROFILE=coverage forge coverage --match-contract 7540 --evm-version cancun --report lcov

.PHONY: smoke-test
smoke-test: ## Runs smoke tests
	forge test --match-contract SmokeTest -vvv

.PHONY: invariant
invariant: ## Runs invariant tests
	forge test --match-path "test/invariant/**/*.sol" --evm-version cancun -vvv

.PHONY: invariant-rewards
invariant-rewards: ## Runs invariant tests for rewards
	forge test --match-test invariant_tokenBalances --evm-version cancun -vvv

.PHONY: clean
clean: ## Cleans the project
	forge clean

.PHONY: snapshot
snapshot: ## Creates a snapshot
	forge snapshot

.PHONY: fmt
fmt: ## Formats the project
	forge fmt && forge fmt test/

.PHONY: ityfuzz
ityfuzz: ## Runs ityfuzz
	ityfuzz evm -m -- forge test

## Help display.
## Pulls comments from beside commands and prints a nicely formatted
## display with the commands and their usage information.
.DEFAULT_GOAL := help

.PHONY: help
help: ## Prints this help
		@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
