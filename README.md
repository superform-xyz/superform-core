# Superform Smart Contracts

This repository contains the core protocol smart contracts of [Superform](https://app.superform.xyz/).

[![codecov](https://codecov.io/gh/superform-xyz/superform-core/graph/badge.svg?token=BEJIKMVWZ6)](https://codecov.io/gh/superform-xyz/superform-core)

### Table of contents

- [Prerequisites](#prerequisites)
- [Project structure](#project-structure)
- [Installation](#installation)
- [Testing](#testing)
- [Documentation](#documentation)

### Prerequisites

See the official Foundry installation [instructions](https://github.com/foundry-rs/foundry/blob/master/README.md#installation).

Then, install the [foundry](https://github.com/foundry-rs/foundry) toolchain installer (`foundryup`) with:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

Now that you've installed the `foundryup` binary,
anytime you need to get the latest `forge` or `cast` binaries,
you can run `foundryup`.

So, simply execute:

```bash
foundryup
```

🎉 Foundry is installed! 🎉

### Project structure

    .
    ├── script
    ├── src
      ├── crosschain-data
      ├── crosschain-liquidity
      ├── forms
      ├── interfaces
      ├── libraries
      ├── payments
      ├── settings
      ├── types
      ├── utils
      ├── vendor
    ├── test
    ├── foundry.toml
    └── README.md

It makes our project structure easily scannable:

- `src` are self-explanatory. All Smart Contract Codes are found inside [/src](./src)
- `interfaces` are where we add our custom written interfaces [/src/interfaces](./src/interfaces).
- `types` is where all re-used types are written and used across different smart contracts. [/src/types](./src/types)
- `vendor` is where all externally written interfaces reside. [/src/vendor](./src/vendor)

### Installation

Step by step instructions on setting up the project and running it

1. Set the env variables as per the dev instructions

2. Install submodules and dependencies:

```sh
foundryup
forge install
```

3. Run `forge test` to run some scenario tests against the contracts

### Testing

```sh
$ forge test
```

### Documentation

#### Contract Architecture

<img width="4245" alt="Superform v1 Smart Contract Architecture (4)" src="https://github.com/superform-xyz/superform-core/assets/33469661/0b057534-20ea-4871-8655-89454c366bf2">

1. All external actions, except SuperForm creation, start in `SuperformRouter.sol`. The user has to provide a "StateRequest" containing the amounts being actioned into each vault in each chain, as well as liquidity information, about how the actual deposit/withdraw process will be handled
2. Deposits/withdraws can be single or multiple destination, single or multi vault, cross-chain or direct chain. For deposit actions, the user can provide a different input token on a source chain and receive the actual underlying token (different than input token) on the destination chain, after swapping and bridging in a single call. Sometimes it is also needed to perform another extra swap at the destination for tokens with low bridge liquidity, through the usage of `MultiTxProcessor.sol`. For withdraw actions, user can choose to receive a different token than the one redeemed for from the vault, back at the source chain.
3. The vaults themselves are wrapped by Forms - code implementations that adapt to the needs of a given vault. This wrapping action leads to the creation of SuperForms (the triplet of superForm address, form id and chain id).
4. Any user can wrap a vault into a SuperForm using the SuperForm Factory but only the protocol may add new Form implementations.
5. Any individual tx must be of a specific kind, either all deposits or all withdraws, for all vaults and destinations
6. Users are minted SuperPositions on successful deposits, a type of ERC-1155 we modified called ERC-1155S. On withdrawals these are burned.

#### Transaction Flow

The typical flow for a deposit xchain transaction is:

- Validation of the input data in `SuperformRouter.sol`.
- Dispatching the input tokens to the liquidity bridge using an implementation of a `BridgeValidator.sol` and `LiquidityHandler.sol`.
- Creating the `AMBMessage` with the information about what is going to be deposited and by whom.
- Messaging the information about the deposits to the vaults using `CoreStateRegistry.sol`. Typically this is done with the combination of two different AMBs by splitting the message and the proof for added security.
- Receive the information on the destination chain's `CoreStateRegistry.sol`. At this step, a keeper updates the messaged amounts to-be deposited with the actual amounts received through the liquidity bridge using one of the `updatePayload` functions.
- The keeper can then process the received message using `processPayload`. Here the deposit action is try-catched for errors. Should the action pass, a message is sent back to source acknowledging the action and minting SuperPositions to the user. If the action fails, no message is sent back and no SuperPositions are minted.
- Funds bridged can be automatically recovered by the keeper in case of error catching and sent back to source using one of `rescueFailedDeposit` functions.

The typical flow for a withdraw xchain transaction is:

- Validation of the input data in `SuperformRouter.sol`.
- Burning the corresponding SuperPositions owned by the user in accordance to the input data.
- Creating the `AMBMessage` with the information about what is going to be withdrawn and by whom.
- Messaging the information about the withdraws to the vaults using `CoreStateRegistry.sol`. The process follows the same pattern as above
- Receive the information on the destination chain's `CoreStateRegistry.sol`.
- The keeper can then process the received message using `processPayload`. Here the withdraw action is try-catched for errors. Should the action pass, the underlying obtained is bridged back to the user in the form of the desired tokens to be received. If the action fails, a message is sent back indicating that SuperPositions need to be re-minted for the user according to the original amounts that were burned.

#### Read more about our protocol

- [State Registry](https://github.com/superform-xyz/superform-core/tree/develop/src/crosschain-data/README.md)
- [Forms](https://github.com/superform-xyz/superform-core/tree/develop/src/forms/README.md)

### Gas Costs (28 July 2023)

| src/SuperFormFactory.sol:SuperFormFactory contract |                 |        |        |         |         |
| -------------------------------------------------- | --------------- | ------ | ------ | ------- | ------- |
| Deployment Cost                                    | Deployment Size |        |        |         |         |
| 2784387                                            | 14142           |        |        |         |         |
| Function Name                                      | min             | avg    | median | max     | # calls |
| addFormBeacon                                      | 4682            | 643178 | 637075 | 658975  | 2263    |
| changeFormBeaconPauseStatus                        | 5466            | 505673 | 505673 | 1005881 | 2       |
| createSuperForm                                    | 725             | 320587 | 319818 | 341718  | 20107   |
| getAllSuperForms                                   | 18856           | 18856  | 18856  | 18856   | 1       |
| getAllSuperFormsFromVault                          | 1993            | 1993   | 1993   | 1993    | 1       |
| getBytecodeFormBeacon                              | 15170           | 15170  | 15170  | 15170   | 1       |
| getFormBeacon                                      | 635             | 930    | 635    | 2635    | 203     |
| getFormCount                                       | 326             | 326    | 326    | 326     | 1       |
| getSuperForm                                       | 459             | 459    | 459    | 459     | 31      |
| getSuperFormCount                                  | 348             | 348    | 348    | 348     | 1       |
| isFormBeaconPaused                                 | 1357            | 1357   | 1357   | 1357    | 1       |
| updateFormBeaconLogic                              | 2600            | 7681   | 6793   | 13416   | 5       |

| src/SuperFormRouter.sol:SuperFormRouter contract |                 |         |         |         |         |
| ------------------------------------------------ | --------------- | ------- | ------- | ------- | ------- |
| Deployment Cost                                  | Deployment Size |         |         |         |         |
| 4338555                                          | 22089           |         |         |         |         |
| Function Name                                    | min             | avg     | median  | max     | # calls |
| multiDstMultiVaultDeposit                        | 630421          | 1067055 | 1012200 | 1856786 | 11      |
| multiDstMultiVaultWithdraw                       | 563726          | 1190243 | 1500151 | 1506852 | 3       |
| multiDstSingleVaultDeposit                       | 465047          | 781205  | 773480  | 1377258 | 14      |
| multiDstSingleVaultWithdraw                      | 297130          | 354790  | 331307  | 460124  | 5       |
| singleDirectSingleVaultDeposit                   | 205460          | 252437  | 258455  | 302534  | 12      |
| singleDirectSingleVaultWithdraw                  | 24108           | 296786  | 140501  | 882035  | 4       |
| singleXChainMultiVaultDeposit                    | 256784          | 447997  | 455178  | 656408  | 13      |
| singleXChainMultiVaultWithdraw                   | 217273          | 238534  | 239594  | 257884  | 5       |
| singleXChainSingleVaultDeposit                   | 244953          | 331827  | 349072  | 397602  | 14      |
| singleXChainSingleVaultWithdraw                  | 142336          | 163485  | 162387  | 186831  | 4       |

| src/SuperPositions.sol:SuperPositions contract |                 |       |        |       |         |
| ---------------------------------------------- | --------------- | ----- | ------ | ----- | ------- |
| Deployment Cost                                | Deployment Size |       |        |       |         |
| 2720972                                        | 14450           |       |        |       |         |
| Function Name                                  | min             | avg   | median | max   | # calls |
| balanceOf                                      | 642             | 1218  | 642    | 2642  | 493     |
| burnBatchSP                                    | 6899            | 7812  | 8059   | 9218  | 13      |
| burnSingleSP                                   | 3513            | 3697  | 3513   | 4391  | 19      |
| dynamicURI                                     | 1299            | 1299  | 1299   | 1299  | 1       |
| mintBatchSP                                    | 48618           | 48618 | 48618  | 48618 | 2       |
| mintSingleSP                                   | 24512           | 24563 | 24512  | 25395 | 17      |
| setApprovalForOne                              | 2933            | 23333 | 24933  | 24933 | 55      |
| setDynamicURI                                  | 2979            | 23379 | 23546  | 43446 | 4       |
| stateMultiSync                                 | 10292           | 49599 | 51101  | 93825 | 37      |
| stateSync                                      | 7010            | 24276 | 26910  | 27861 | 43      |
| supportsInterface                              | 548             | 548   | 548    | 548   | 1       |
| updateTxHistory                                | 23495           | 23850 | 23495  | 25495 | 107     |
| uri                                            | 2332            | 2332  | 2332   | 2332  | 1       |

| src/crosschain-liquidity/MultiTxProcessor.sol:MultiTxProcessor contract |                 |        |        |        |         |
| ----------------------------------------------------------------------- | --------------- | ------ | ------ | ------ | ------- |
| Deployment Cost                                                         | Deployment Size |        |        |        |         |
| 962913                                                                  | 5020            |        |        |        |         |
| Function Name                                                           | min             | avg    | median | max    | # calls |
| batchProcessTx                                                          | 122225          | 169121 | 173375 | 228495 | 17      |
| processTx                                                               | 71500           | 73199  | 71500  | 81119  | 12      |
