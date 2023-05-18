# Superform Smart Contracts

This repository contains the core protocol smart contracts of [Superform](https://app.superform.xyz/).

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
    ├── src
      ├── crosschain-data
      ├── crosschain-liquidity
      ├── forms
      ├── interfaces
      ├── settings
      ├── test
      ├── types
      ├── utils
      ├── vendor
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


1. All external actions, except SuperForm creation, start in `SuperRouter.sol`. The user has to provide a "StateRequest" containing the amounts being    actioned into each vault in each chain, as well as liquidity information, about how the actual deposit/withdraw process will be handled
2. Deposits/withdraws can be single or multiple destination, single or multi vault, cross-chain or direct chain. For deposit actions, the user can provide a different input token on a source chain and receive the actual underlying token (different than input token) on the destination chain, after swapping and bridging in a single call. Sometimes it is also needed to perform another extra swap at the destination for tokens with low bridge liquidity, through the usage of `MultiTxProcessor.sol`. For withdraw actions, user can choose to receive a different token than the one redeemed for from the vault, back at the source chain.
3. The vaults themselves are wrapped by Forms - code implementations that adapt to the needs of a given vault. This wrapping action leads to the creation of SuperForms (the triplet of superForm address, form id and chain id).
4. Any user can wrap a vault into a SuperForm using the SuperForm Factory but only the protocol may add new Form implementations. 
5. Any individual tx must be of a specific kind, either all deposits or all withdraws, for all vaults and destinations
6. Users are minted SuperPositions on successful deposits, a type of ERC-1155 we modified called ERC-1155S. On withdrawals these are burned.

#### Transaction Flow

The typical flow for a deposit xchain transaction is:

- Validation of the input data in `SuperRouter.sol`.
- Dispatching the input tokens to the liquidity bridge using an implementation of a `BridgeValidator.sol` and `LiquidityHandler.sol`.
- Creating the `AMBMessage` with the information about what is going to be deposited and by whom.
- Messaging the information about the deposits to the vaults using `CoreStateRegistry.sol`. Typically this is done with the combination of two different AMBs by splitting the message and the proof for added security.
- Receive the information on the destination chain's `CoreStateRegistry.sol`. At this step, a keeper updates the messaged amounts to-be deposited with the actual amounts received through the liquidity bridge using one of the `updatePayload` functions.
- The keeper can then process the received message using `processPayload`. Here the deposit action is try-catched for errors. Should the action pass, a message is sent back to source acknowledging the action and minting SuperPositions to the user. If the action fails, no message is sent back and no SuperPositions are minted.
- Funds bridged can be automatically recovered by the keeper in case of error catching and sent back to source using one of `rescueFailedDeposit` functions.

The typical flow for a withdraw xchain transaction is:

- Validation of the input data in `SuperRouter.sol`.
- Burning the corresponding SuperPositions owned by the user in accordance to the input data.
- Creating the `AMBMessage` with the information about what is going to be withdrawn and by whom.
- Messaging the information about the withdraws to the vaults using `CoreStateRegistry.sol`. The process follows the same pattern as above
- Receive the information on the destination chain's `CoreStateRegistry.sol`.
- The keeper can then process the received message using `processPayload`. Here the withdraw action is try-catched for errors. Should the action pass, the underlying obtained is bridged back to the user in the form of the desired tokens to be received. If the action fails, a message is sent back indicating that SuperPositions need to be re-minted for the user according to the original amounts that were burned.

#### Read more about our protocol

- [State Registry](https://github.com/superform-xyz/superform-core/tree/develop/src/crosschain-data/README.md)
- [Forms](https://github.com/superform-xyz/superform-core/tree/develop/src/forms/README.md)
