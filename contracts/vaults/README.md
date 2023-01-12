# ERC4626 Wrappers in the Wild

Observations on wrapping of different protocols in ERC4626 interface.

## Introudction

`AaveV2StrategyWrapper` and `CompoundV2StrategyWrapper` contracts are based on [yield-daddy](https://github.com/timeless-fi/yield-daddy) ERC4626 wrappers for different protocols, including AAVE V2 and Compound V2. Proposed wrappers are to be deployed and used with either original AAVE/Compound protocols or their forked versions. Forked versions are expected to obey original interface and have the same accounting flow. It only makes sense, as forking is a strategy used to quickly jump through hussle of design & development of the new protocol type and focus on attracting liquidity instantly.

That dynamics often pushes forking protocols to introduce their own reward systems, staking systems, deep liquidity pools or other forms of incentives built around forked code. More than often, that additional code isn't anymore a part of original fork. In that regard, yield-daddy prioritizes original AAVE and Compound codebases.

## Solution

We extend yield-daddy AAVE and Compound wrappers with addition of `harvest()` function and low level `DexSwap` library.

## Rationale

Distributing rewards for liquidity providing is a norm in DeFi. Analytics often provide aggregate APY of the Vault as Base+Reward APY.

Staking LP-tokens is so often practice in DeFi that there's a strong reason to just automate it inside of a Vault flow for any protocol providing such opportunity.

`harvest()` is an extension of `claimRewards()`. It operates with low level swap library and permissionless re-investing for higher Vault returns to share owners. `harvest()` could be defined as part of interface, open to be called by anybody and performing reinvesting, rebalancing or reporting function for the Vault. Current implementation (swap+reinvest) is minimal.
