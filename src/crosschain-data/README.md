# State Registry

This directory contains the components to enable crosschain communication functionality to Superform Protocol. It also includes wrapper contracts for different arbitrary message bridges (AMBs) leveraged by Superform: Layerzero, Hyperlane & Wormhole.

## Components Overview

The following components are a key part of superform's robust crosschain communication. New State Registries may be added by the Protocol Admin if new Form types are added to support new deposit/withdrawal flows. 

## Architecture

<img width="926" alt="Screenshot 2023-11-14 at 11 58 08 AM" src="https://github.com/superform-xyz/superform-core/assets/33469661/1ca6341a-d3f5-4b54-8758-596584dde9ca">

## State Registry: Functional Description

### Sending Payloads

Every cross-chain communication call should be made through the state registry, starting with `dispatchPayload()` or `broadcastPayload()` on individual state registries. State registry contracts are deployed on each of the supported networks and will be the point of cross-chain communication.

- dispatchPayload() - sends a payload to one destination chain
- broadcastPayload() - sends a payload to all supported chains

### Receiving Payloads

`BaseStateRegistry` exposes the ability to receive any cross-chain message, which accepts incoming messages after specific validations from approved AMB wrapper contracts.

### Updating Payloads

Updating payloads are performed in `CoreStateRegistry`. This is only required for cross-chain deposits via `updateDepositPayload()` but optional on cross-chain withdrawals via `updateWithdrawPayload()` if the user didn't send in any liquidity data. Updating can only be performed if the appropriate quorum on the chain was met via sending through the appropriate number of proof AMBs. 

### Processing Payloads

The cross-chain payload contains remote chain execution information, which can be triggered by calling the `processPayload()` function exposed by the state registry contracts. The logic is overridden in different state registries to provide flexibility in processing according to their needs. 

On deposits, payloads must be processed once on the destination chain to deposit funds, and once the acknowledgement is sent back, processed again to mint SuperPositions (assuming the user )

On withdrawals, payloads must only be processed once on the destination chain to redeem funds. 

### Chain Id

Every AMB has their identifier for different chains/networks. In state registries, perform assigned chains are used, which are mapped to the AMB-specific chain ids inside the amb implementation contracts.

### Key Security Assumptions
- Only AMB implementation contracts can write new messages into state registry
- Sender should be authenticated to interact with the AMB implmenetation contract
- Updating and processing payloads can only be made by keepers with special privileges
- `onlySender` modifier is overriden by all contracts inheriting base state registry

## In scope

- **Base State Registry [BaseStateRegistry.sol](./BaseStateRegistry.sol)**: The base implementation of the state registry, exposes sending and receiving payload interfaces. Any cross-chain message is also called a "payload".

- **Core State Registry [CoreStateRegistry.sol](./extensions/CoreStateRegistry.sol)**: Contract inheriting BaseStateRegistry which enables core contracts, including routers & form implementations, to communicate with their counterparts on a different network. Contains its custom logic for payload processing & updating (during deposits).

- **Timelock Form State Registry [TimelockStateRegistry.sol](./extensions/TimelockStateRegistry.sol)**: Contract inheriting BaseStateRegistry, specifically designed to process withdrawal request for ERC4626TimelockForm. Inherits BaseStateRegistry to send acknowledgement on failure withdrawals for timelock forms.

- **Broadcast State Registry [BroadcastRegistry.sol](./BroadcastRegistry.sol)**: BroadcastRegistry proposes a unique form of communication from Chain A to all chains Superform is on, as opposed to BaseStateRegistry which assumes communication between only two chains. 

Each individual AMB wrapper will be placed inside a folder named after the Arbitrary Message Bridge (AMB).

- **[LayerzeroImplementation.sol](./adapters/layerzero/Implementation.sol)**: Wrapper for Layerzero AMB

- **[HyperlaneImplementation.sol](./adapters/hyperlane/Implementation.sol)**: Wrapper for Hyperlane AMB

- **[WormholeARImplementation.sol](./adapters/wormhole/automatic-relayer/WormholeARImplementation.sol)**: Wrapper for Wormhole Automatic Relayer AMB

- **[WormholeSRImplementation.sol](./adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol)**: Wrapper for Wormhole Specialized Relayer AMB, used specifically in `BroadcastRegistry.sol`
  
