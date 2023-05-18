# Superform Smart Contracts

This repository contains the core protocol smart contracts of [Superform](https://app.superform.xyz/).

### Table of contents

- [Prerequisites](#prerequisites)
- [Project structure](#project-structure)
- [Installation](#installation)
- [Testing](#testing)
- [Useful-info](#useful-info)
- [Action-flows](#action-flows)

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

### Useful-info

1. All external actions, except SuperForm creation, start in `SuperRouter.sol`;
2. Deposits/withdraws can be single or multiple destination, single or multi vault, cross-chain or direct chain;
3. Multi-vault actions can contain vaults of different kinds.
4. The vaults themselves are wrapped by Forms - code implementations that adapt to the needs of a given vault. This wrapping action leads to the creation of SuperForms (the triplet of superForm address, form id and chain id).
5. Any user can wrap a vault into a SuperForm.
6. Any individual tx must be of a specific kind, either all deposits or all withdraws, for all vaults and destinations

### Action-flows

1. A user with no SuperPositions starts by depositing using the most optimized entry point for his needs.
2. For such purpose, the user has to provide a "StateRequest" containing the amounts being actioned into each vault in each chain, as well as liquidity information, about how the actual deposit/withdraw process will be handled.
3. For deposit actions, the user can provide a different input token on a source chain and receive the actual underlying token (different than input token) on the destination chain, after swapping and bridging in a single call. Sometimes it is also needed to perform another extra swap at the destination for tokens with low bridge liquidity, through the usage of `MultiTxProcessor.sol`.
4. For withdraw actions, user can choose to receive a different token than the one redeemed for from the vault, back at the source chain.

5. The typical flow for a deposit xchain transaction is:

- Validation of the input data in `SuperRouter.sol`.
- Dispatching the input tokens to the liquidity bridge using an implementation of a `BridgeValidator.sol` and `LiquidityHandler.sol`.
- Creating the `AMBMessage` with the information about what is going to be deposited and by whom.
- Messaging the information about the deposits to the vaults using `CoreStateRegistry.sol`. Typically this is done with the combination of two different AMBs by splitting the message and the proof for added security.
- Receive the information on the destination chain's `CoreStateRegistry.sol`. At this step, a keeper updates the messaged amounts to-be deposited with the actual amounts received through the liquidity bridge using one of the `updatePayload` functions.
- The keeper can then process the received message using `processPayload`. Here the deposit action is try-catched for errors. Should the action pass, a message is sent back to source acknowledging the action and minting SuperPositions to the user. If the action fails, no message is sent back and no SuperPositions are minted.
- Funds bridged can be automatically recovered by the keeper in case of error catching and sent back to source using one of `rescueFailedDeposit` functions.

6. The typical flow for a withdraw xchain transaction is:

- Validation of the input data in `SuperRouter.sol`.
- Burning the corresponding SuperPositions owned by the user in accordance to the input data.
- Creating the `AMBMessage` with the information about what is going to be withdrawn and by whom.
- Messaging the information about the withdraws to the vaults using `CoreStateRegistry.sol`. The process follows the same pattern as above
- Receive the information on the destination chain's `CoreStateRegistry.sol`.
- The keeper can then process the received message using `processPayload`. Here the withdraw action is try-catched for errors. Should the action pass, the underlying obtained is bridged back to the user in the form of the desired tokens to be received. If the action fails, a message is sent back indicating that SuperPositions need to be re-minted for the user according to the original amounts that were burned.

### Read more about our protocol

- [State Registry](https://github.com/superform-xyz/superform-core/tree/develop/src/crosschain-data/README.md)
- [Forms](https://github.com/superform-xyz/superform-core/tree/develop/src/forms/README.md)
