# Overview

[![codecov](https://codecov.io/gh/superform-xyz/superform-core/graph/badge.svg?token=BEJIKMVWZ6)](https://codecov.io/gh/superform-xyz/superform-core)

The Superform protocol is a suite of non-upgradeable, non-custodial smart contracts that act as a central repository for yield and a router for users. It is modular, permissionless to list vaults, and enables intent-based transactions across chains that allow users to execute into an arbitrary number of tokens, chains, and vaults at once.

For DeFi protocols, it acts as an instant out-of-the-box distribution platform for ERC4626-compliant vaults. For users, it allows access to any vault listed on the platform from the chain and asset of their choice in a single transaction. 

Core capabilities for protocols include:
- Permissionlessly list your vaults on Superform by adding your ERC4626 vault to the proper 'Form' (a vault adapter within Superform). 
- Create a profile page with embeddable data sources for users to find more information about your protocol
- Manage metadata for yield opportunities
- Users can deposit into your vaults from any chain without the need to deploy your vaults on that chain
  
Core capabilities for users: 
- Deposit or withdraw into any vault using any asset from any chain
- Batch desired actions across multiple vaults and multiple chains in a single transaction
- Automate and mange your yield portfolio from any chain
- Automatically compound your yield position
- Make cross-chain transactions using multiple AMBs 

This repository includes all of our contracts, but our protocol can be split into two categories: Core and Periphery.

- Core contracts contain logic to move liquidity and data across chains along with maintaining roles in the protocol
- Periphery contracts contain the main touch-points for protocols and users to interface with and include helper contracts to ease 3rd party integrations
  
![Superform__SuperformProtocol--Updated](https://github.com/superform-xyz/superform-core/assets/33469661/ee7a58fd-e18f-4244-92b0-7cb741ac1f45)


## Resources

- [Twitter](https://twitter.com/superformxyz)
- [Website](https://www.superform.xyz/)
- [Application](https://app.superform.xyz)
- [Technical Documentation](https://docs.superform.xyz)

## Project structure

    .
    ├── script
    ├── src
      ├── crosschain-data
      ├── crosschain-liquidity
      ├── emergency
      ├── forms
      ├── interfaces
      ├── libraries
      ├── payments
      ├── settings
      ├── types
      ├── utils
      ├── vendor
    ├── test
    ├── utils
    ├── foundry.toml
    └── README.md

- `src` is the source folder for all smart contract code[`/src`](./src)
  - `crosschain-data` implements the sending of messages from chain to chain via various AMBs [`/src/crosschain-data`](./src/crosschain-data)
  - `crosschain-liquidity` implements the movement of tokens from chain to chain via bridge aggregators [`/src/crosschain-liquidity`](./src/crosschain-liquidity)
  - `forms` implements types of yield that can be supported on Superform and introduces a queue when they are paused [`/src/forms`](./src/forms)
  - `interfaces` define interactions with other contracts [`/src/interfaces`](./src/interfaces)
  - `libraries` define functions used across other contracts [`/src/libraries`](./src/libraries)
  - `payments` implements the handling and processing of payments for cross-chain actions [`/src/payments`](./src/payments)
  - `settings` define, set, and manage roles in the Superform ecosystem [`/src/settings`](./src/settings)
  - `types` define core data structures used in the protocol [`/src/types`](./src/types)
  - `utils` define error states in the protocol [`/src/utils`](./src/utils)
  - `vendor` is where all externally written interfaces reside [`/src/vendor`](./src/vendor)

## Documentation

We recommend visiting our technical documentation at https://docs.superform.xyz. 

## Contract Architecture

1. All external actions, except Superform creation, start in `SuperformRouter.sol`. For each deposit or withdraw function the user has to provide the appropriate "StateRequest" found in `DataTypes.sol` 
2. All deposit and withdrawal actions can be to single or multiple destinations, single or multi vaults, and same-chain or cross-chain. Any token can be deposited from any chain into a vault with swapping and bridging handled in a single call. Sometimes it is also needed to perform another action on the destination chain for tokens with low bridge liquidity, through the usage of `DstSwapper.sol`. Similarly for withdraw actions, users can choose to receive a different token than the one redeemed for from the vault, but funds must go back directly to the user (i.e. no use of `DstSwapper.sol`).
3. Any individual tx must be of a specific kind, either all deposits or all withdraws, for all vaults and destinations
4. Vaults themselves can be added permissionlessly to Forms in `SuperformFactory.sol` by calling `createSuperform()`. Forms are code implementations that adapt to the needs of a given vault. The only Form under scope of this audit is `ERC4626Form.sol`, which is a wrapper around the [ERC-4626 Standard](https://erc4626.info/). Any user can wrap a vault into a SuperForm using the SuperForm Factory but only the protocol may add new Form implementations.
5. This wrapping action leads to the creation of Superforms which are assigned a unique id, made up of the superForm address, formId, and chainId.
6. Users are minted SuperPositions on successful deposits, a type of ERC-1155 we modify called ERC-1155A. On withdrawals these are burned. Users may also within each "StateRequest" deposit choose whether to retain4626 which sends the vault share directly to the user instead of holding in the appropriate Superform, but only SuperPositions can be withdrawn through SuperformRouter.   

## User Flow

In this section we will run through examples where users deposit and withdraw into vault(s) using Superform. 

<img width="943" alt="Screenshot 2023-11-08 at 2 20 43 PM" src="https://github.com/superform-xyz/superform-core/assets/33469661/5c4dee7a-a711-438f-a145-d97f9fd19b85">

### Same-chain Deposit Flow

<img width="1410" alt="Screenshot 2023-11-08 at 2 21 19 PM" src="https://github.com/superform-xyz/superform-core/assets/33469661/815b4e6d-8665-4aa6-89ff-96d07c26fe42">


- Validation of the input data in `SuperformRouter.sol`.
- Process swap transaction data if provided to allow SuperformRouter to move tokens from the user to the Superform and call `directDepositIntoVault` to move tokens from the Superform into the vault.
- Store ERC-4626 shares in the Superform and mint the apppropriate amount of SuperPositions back to the user.

### Cross-chain Deposit Flow

<img width="1450" alt="Screenshot 2023-11-08 at 2 22 12 PM" src="https://github.com/superform-xyz/superform-core/assets/33469661/f9643ebd-b267-4d9e-8eea-f9fcaabda5eb">


- Validation of the input data in `SuperformRouter.sol`.
- Dispatch the input token to the liquidity bridge using an implementation of a `BridgeValidator.sol` and `LiquidityHandler.sol`.
- Create an `AMBMessage` with the information about what is going to be deposited and by whom.
- Message the information about the deposits to the vaults using `CoreStateRegistry.sol`. This is done with the combination of a main AMB and a configurable number of proof AMBs for added security, a measure set via `setRequiredMessagingQuorum` in `SuperRegistry.sol`.
- Forward remaining payment to `PayMaster.sol` to cover the costs of cross-chain transactions and relayer payments. 
- Receive the information on the destination chain's `CoreStateRegistry.sol`. Assuming no swap was required in `DstSwapper.sol`, at this step, assuming both the payload and proof have arrived, a keeper updates the messaged amounts to-be deposited with the actual amounts received through the liquidity bridge using `updateDepositPayload`. The maximum number it can be updated to is what the user specified in StateReq.amount. If the end number of tokens received is below the minimum bound of what the user specified, calculated by StateReq.amount*(10000-StateReq.maxSlippage), the deposit is marked as failed and must be rescued through the `rescueFailedDeposit` function to return funds back to the user through an optimisic dispute process.  
- The keeper can then process the received message using `processPayload`. Here the deposit action is try-catched for errors. Should the action pass, a message is sent back to source acknowledging the action and mints SuperPositions to the user. If the action fails, no message is sent back, no SuperPositions are minted, and the `rescueFailedDeposit` function must be used.

### Same-chain Withdrawal Flow

<img width="1442" alt="Screenshot 2023-11-08 at 2 21 50 PM" src="https://github.com/superform-xyz/superform-core/assets/33469661/3c688423-9ba7-4472-9e9f-b3cafefc45f5">


- Validation of the input data in `SuperformRouter.sol`.
- Burn the corresponding SuperPositions owned by the user and call `directWithdrawFromVault` in the Superform, which redeems funds from the vault.
- Process transaction data (either a swap or a bridge) if provided and send funds back to the user.

### Cross-chain Withdrawal Flow

- Validation of the input data in `SuperformRouter.sol`.
- Burn the corresponding SuperPositions owned by the user in accordance to the input data.
- Create the `AMBMessage` with the information about what is going to be withdrawn and by whom.
- Message the information about the withdrawals from the vaults using `CoreStateRegistry.sol`. This is done with the combination of a main AMB and a configurable number of proof AMBs for added security, a measure set via `setRequiredMessagingQuorum` in `SuperRegistry.sol`.
- Forward remaining payment to `PayMaster.sol` to cover the costs of cross-chain transactions and relayer payments. 
- If no transaction data was provided with the transaction, but the user defined an intended token and chain to recieve assets back on, assuming both the payload and proof have arrived, a keeper can call `updateWithdrawPayload` to update the payload with transaction data. This can be done to reduce the chance of transaction data failure due to latency. 
- The keeper can then process the received message using `processPayload`. Here the withdraw action is try-catched for errors. Should the action pass, the underlying obtained is bridged back to the user in the form of the desired tokens to be received. If the action fails, a message is sent back indicating that SuperPositions need to be re-minted for the user according to the original amounts that were burned. No rescue methods are implemented given the re-minting behavior on withdrawals. 

## Off-chain Architecture

Superform employs a variety of keepers to support best-in-class UX of interacting cross-chain. While this introduces a degree of centralization in our protocol, these roles can be decentralized over time and have no control over user funds. These include:

- PAYMENT_ADMIN_ROLE: Role for managing payment-related actions in `PayMaster.sol`
- BROADCASTER_ROLE: Role for managing broadcasting payloads in `BroadcastStateRegistry.sol`
- CORE_STATE_REGISTRY_PROCESSOR_ROLE: Role for managing processing operations in `CoreStateRegistry.sol`
- TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE: Role for managing processing operations in `TimelockStateRegistry.sol`
- BROADCAST_REGISTRY_PROCESSOR_ROLE : Role for managing processing broadcast payloads in `BroadcastStateRegistry.sol`
- CORE_STATE_REGISTRY_UPDATER_ROLE: Role for managing updating operations in `CoreStateRegistry.sol`
- DST_SWAPPER_ROLE: Role for managing swapping operations on `DstSwapper.sol`
- CORE_STATE_REGISTRY_RESCUER_ROLE: Role for managing rescue operations in `CoreStateRegistry.sol`
- CORE_STATE_REGISTRY_DISPUTER_ROLE: Role for managing dispute operations in `CoreStateRegistry.sol`
- WORMHOLE_VAA_RELAYER_ROLE: Role that will be reading VAA's for broadcast functionality in `WormholeSRImplementation.sol`

For the purpose of this audit, exploits concerning the inappropriate behavior of these roles will not be considered. 

## Out of scope

We leave these in the repository to see intended behavior, but the following contracts and behaviors are out of scope:

- Anything in [`src/vendor`](./src/vendor)
- Exploits concerning the inappropriate behavior of permissioned roles

## Tests

Step by step instructions on setting up the project and running it

1. Make sure Foundry is installed

2. Set the .env variables using archive nodes

3. Install submodules and dependencies:

```sh
foundryup
forge install
```

4. Run `forge test` to run some scenario tests against the contracts

```sh
$ forge test
```

## Audits

- [Gerard Pearson](https://twitter.com/gpersoon): [2023-09-superform.pdf](https://github.com/superform-xyz/superform-core/files/13300598/2023-09-superform.pdf)

- [Hans Friese](https://twitter.com/hansfriese): [Superform_Core_Review_Final_Hans_20230921.pdf](https://github.com/superform-xyz/superform-core/files/13300591/Superform_Core_Review_Final_Hans_20230921.pdf)
