# Overview

This directory contains information relevant to prior security reviews and the scope of bug bounties. 

## Out of scope

The following contracts, behaviors, and findings are out of scope:

- Anything in [`src/vendor`](./src/vendor)
- Prior findings in any audit report found in this directory
- Exploits concerning the inappropriate behavior of keeper roles mentioned below
- Superform allows for the permissionless addition of yield. We do not maintain the security of vaults added and funds bricked or lost by improper implementations
- Our v1 was deployed on January 24th, 2024. Changes to the LiFi or Socket codebase after this point, implicitly used in LiFiValidator and SocketValidator, are monitored and validated off-chain and we will not consider errors specific to any added functionality 
- Anything related to MultiVaultSFData.extraFormData usage in relation of multi vault withdraws processing in CoreStateRegistry (the variable is ignored)

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
