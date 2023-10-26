# State Registry

This directory contains the components to enable crosschain communication functionality to Superform Protocol. It also includes the wrapper contracts for different arbitrary message bridges (AMBs) leveraged by Superform. Layerzero, Hyperlane & Wormhole have completed wrapper implementation.

## Components Overview

---

The following components are a key part of superform's robust crosschain communication.

- **Base State Registry [BaseStateRegistry.sol](./BaseStateRegistry.sol)**: The base implementation of the state registry, exposes sending and receiving payload interfaces. Any cross-chain message is also called a "payload".
- **Core State Registry [CoreStateRegistry.sol](./extensions/CoreStateRegistry.sol)**: Child contract inheriting base state registry which enables core contracts, including routers & form implementations, to communicate with their counterparts on a different network. Contains its custom logic for payload processing & updation (during deposits).
- **Factory State Registry [FactoryStateRegistry.sol](./extensions/FactoryStateRegistry.sol)**: Child contract inheriting base state registry which enables crosschain communication between factory contracts.
- **Two Steps Form State Registry [TimelockStateRegistry.sol](./extensions/TimelockStateRegistry.sol)**: Special state registry implementation contract, specifically designed to process withdrawal request for timelock forms, such as timelocked. Inherits base state registry to send acknowledgement on failure withdrawals for timelock' forms.

Each individual AMB wrapper will be placed inside a folder named after the Arbitrary Message Bridge (AMB).

- **[LayerzeroImplementation.sol](./adapters/layerzero/Implementation.sol)**: Wrapper for Layerzero AMB

- **[HyperlaneImplementation.sol](./adapters/hyperlane/Implementation.sol)**: Wrapper for Hyperlane AMB

## Architecture

---

The entire architecture can be viewed here on Figma: [Architecture Diagram](https://www.figma.com/file/pVU5nivxGIixdagMpaaKjJ/State-Registry?type=whiteboard&node-id=0-1&t=Tv3mz31gmvlJtw5t-0)

## State Registry: Functional Description

---

### Send Payload

Every cross-chain communication should be made through the state registry, and the foremost step is to call the `dispatchPayload()` or `broadcastPayload()` function on individual state registries. State registry contracts are deployed on each of the supported networks and will be the point of cross-chain communication.

- dispatchPayload() - sends a payload to one destination chain
- broadcastPayload() - sends a payload to all supported chains

## Receive Payload

The base state registry exposes the ability to receive any cross-chain message, which accepts incoming messages after specific validations from approved AMB wrapper contracts.

## Updating Payload

It is required only during cross-chain deposits. Allows unique updater off-chain keepers to update the slippage that occurred during cross-chain depositions. For now, it is only utilized by Core State Registry.

## Process Payload

The cross-chain payload contains remote chain execution information, which can be triggered by calling the `processPayload()` function exposed by the state registry contracts. The logic is overridden in different state registries to provide flexibility in processing according to their needs.

## Chain Id

Every AMB has their identifier for different chains/networks. In state registries, perform assigned chains are used, which are mapped to the AMB-specific chain ids inside the amb implementation contracts.

## Security Assumptions: A Primer

---

- Only AMB implementation contracts can write new messages into state registry
- Sender should be authenticated to interact with the AMB implmenetation contract
- Processing & Update of payload can only be made by keepers with special privileges
- `onlySender` modifier is overriden by all contracts inheriting base state registry
