# Superform Smart Contracts

![Coverage](https://img.shields.io/badge/coverage-100-success) [![built-with openzeppelin](https://img.shields.io/badge/built%20with-OpenZeppelin-3677FF)](https://docs.openzeppelin.com/)

This repository contains the core protocol smart contracts of [Superform](https://app.superform.xyz/).

### Table of contents

- [Getting Started](#getting-started)
- [Prerequisites](#prerequisites)
- [Project structure](#project-structure)
- [Installation](#installation)
- [Testing](#testing)

### Built with

- [LayerZero](https://layerzero.network/) - OmniChain communication Protocol
- [Foundry](https://book.getfoundry.sh) - Smart Contract Development Suite
- [Solidity](https://docs.soliditylang.org/en/v0.8.19/) - Smart Contract Programming Language

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

### Installation

Step by step instructions on setting up the project and running it

1. Set the env variables as per the dev instructions

2. Install submodules and dependencies

Or, if your repo already exists, run:

```sh
git submodule update --init --recursive
forge install
```

3. Run `forge test` to run tests against the contracts

### Project Folder layout & Structure

    .
    ├── src
      ├── crosschain-data
      ├── crosschain-liquidity
      ├── interfaces
      ├── mocks
      ├── splitter
      ├── types
      ├── test
         ├── BaseProtocolTest.t
    ├── foundry.toml
    └── README.md

It makes our project structure easily scannable:

- `src` are self-explanatory. All Smart Contract Codes are found inside [/src](./src)
- `interface` are where we add our custom written interfaces as well as external protocol interfaces [/src/interface](./src/interface).
- `types` is where all re-used types are written and used across different smart contracts. [/src/types](./src/types)

### Sorting Your Imports

I sort imports in this order:

1. Openzeppelin (or) NPM Contracts
2. Current Contract's Interfaces
3. Other Local Interfaces
4. Library Contracts/Interfaces
5. Tunnel Contracts/Interfaces
6. Type Contract
7. Error Contract

### Testing

For running unit & integration tests:

```sh
$ forge test
```

To run coverage:

```sh
$  forge coverage
```
