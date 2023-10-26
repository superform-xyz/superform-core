# Forms

This directory contains Superform's "Form" smart contracts. These form contracts serve as fundamental components of the Superform DeFi infrastructure, acting as intermediaries for deposit and withdrawal actions to and from the ERC4626 compliant vaults. Each Form is uniquely associated with a single underlying Vault.

All form contracts adhere to the [IBaseForm](../interfaces/IBaseForm.sol) standard interface and implement abstract functions defined in [BaseForm](../BaseForm.sol) for both same-chain and cross-chain operations. Apart from the standard ERC4626 and time-locked forms, numerous other "custom" form types can be created. These are extended from BaseForm and used when Superform needs to handle specific scenarios not covered by an existing Form.

Here's what's included in this directory:

**ERC4626FormImplementation.sol:** Abstract implementation of a Form contract with functions that are commonly used across forms. All functions can be overriden in specific form implementations.

**ERC4626Form.sol:** The standard implementation of a Form contract. This Form interacts with a corresponding ERC4626 compliant vault.

**ERC4626KYCDAOForm.sol:** The standard implementation of a Form contract integrated with KYCDao's whitelist NFT. This Form interacts with a corresponding ERC4626 compliant vault.

**ERC4626TimelockForm.sol:** A variant of the standard Form contract that includes timelock functionality. This Form contract is used when time-based conditions need to be met during the deposit or withdrawal process. This Form requires a [TimelockRegistry](../crosschain-data/TimelockStateRegistry.sol) _(also known as FormStateRegistry)_ to execute redemption at a later time through the processUnlock() function.

**FormBeacon.sol:** Implements a Beacon Proxy pattern for each Form for improved management. Each Form is deployed as part of Beacon Proxy logic through the SuperformFactory.
