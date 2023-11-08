# Forms

This directory contains Superform's "Form" smart contracts. These form contracts serve as fundamental components of the Superform DeFi infrastructure, acting as intermediaries for deposit and withdrawal actions to and from the ERC4626 compliant vaults. Each Form is uniquely associated with a single underlying Vault.

All form contracts adhere to the [IBaseForm](../interfaces/IBaseForm.sol) standard interface and implement abstract functions defined in [BaseForm](../BaseForm.sol) for both same-chain and cross-chain operations. Apart from the standard ERC4626 Form, numerous other "custom" form types can be created. These are extended from BaseForm and used when Superform needs to handle specific scenarios not covered by an existing Form.

Interaction with Superforms happens through the four implemented external functions in BaseForm. They are split by direct chain (accessible by `SuperformRouter` only) or cross chain access (accessible by `CoreStateRegistry` only).

Here's what's included in this directory:

### In scope

**ERC4626FormImplementation.sol:** Abstract implementation of a Form contract with functions that are commonly used across forms. All functions can be overriden in specific form implementations.

**ERC4626Form.sol:** The standard implementation of a Form contract. This Form interacts with a corresponding ERC4626 compliant vault.

### Out of scope

These are example Form implementations to showcase the ability of additional yield types to be added to Superform. 

**ERC4626KYCDAOForm.sol:** The standard implementation of a Form contract integrated with KYCDao's whitelist NFT. This Form interacts with a corresponding ERC4626 compliant vault.

**ERC4626TimelockForm.sol:** A variant of the standard Form contract that includes timelock functionality. This Form contract is used when time-based conditions need to be met during the deposit or withdrawal process. This Form requires a [TimelockRegistry](../crosschain-data/TimelockStateRegistry.sol) to execute redemption at a later time through the processUnlock() function.