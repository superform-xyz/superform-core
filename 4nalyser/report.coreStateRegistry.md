# Report


## Gas Optimizations


| |Issue|Instances|
|-|:-|:-:|
| [GAS-1](#GAS-1) | Cache array length outside of loop | 5 |
| [GAS-2](#GAS-2) | For Operations that will not overflow, you could use unchecked | 75 |
| [GAS-3](#GAS-3) | Don't initialize variables with default value | 1 |
| [GAS-4](#GAS-4) | Functions guaranteed to revert when called by normal users can be marked `payable` | 1 |
| [GAS-5](#GAS-5) | Use != 0 instead of > 0 for unsigned integer comparison | 4 |
### <a name="GAS-1"></a>[GAS-1] Cache array length outside of loop
If not cached, the solidity compiler will always read the length of the array during each iteration. That is, if it is a storage array, this is an extra sload operation (100 additional extra gas for each iteration except for the first) and if it is a memory array, this is an extra mload operation (3 additional gas for each iteration except for the first).

*Instances (5)*:
```solidity
File: CoreStateRegistry.sol

218:             failedDeposits_.superformIds.length == 0 || proposedAmounts_.length == 0

219:                 || failedDeposits_.superformIds.length != proposedAmounts_.length

297:         for (uint256 i; i < failedDeposits_.amounts.length; ++i) {

667:         uint256 len = multiVaultData.superformIds.length;

732:         uint256 numberOfVaults = multiVaultData.superformIds.length;

```

### <a name="GAS-2"></a>[GAS-2] For Operations that will not overflow, you could use unchecked

*Instances (75)*:
```solidity
File: CoreStateRegistry.sol

4: import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { BaseStateRegistry } from "../BaseStateRegistry.sol";

7: import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";

7: import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";

7: import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";

8: import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";

8: import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";

8: import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";

9: import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";

9: import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";

9: import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";

10: import { IPaymentHelper } from "../../interfaces/IPaymentHelper.sol";

10: import { IPaymentHelper } from "../../interfaces/IPaymentHelper.sol";

10: import { IPaymentHelper } from "../../interfaces/IPaymentHelper.sol";

11: import { IBaseForm } from "../../interfaces/IBaseForm.sol";

11: import { IBaseForm } from "../../interfaces/IBaseForm.sol";

11: import { IBaseForm } from "../../interfaces/IBaseForm.sol";

12: import { IDstSwapper } from "../../interfaces/IDstSwapper.sol";

12: import { IDstSwapper } from "../../interfaces/IDstSwapper.sol";

12: import { IDstSwapper } from "../../interfaces/IDstSwapper.sol";

13: import { ISuperformFactory } from "../../interfaces/ISuperformFactory.sol";

13: import { ISuperformFactory } from "../../interfaces/ISuperformFactory.sol";

13: import { ISuperformFactory } from "../../interfaces/ISuperformFactory.sol";

14: import { ICoreStateRegistry } from "../../interfaces/ICoreStateRegistry.sol";

14: import { ICoreStateRegistry } from "../../interfaces/ICoreStateRegistry.sol";

14: import { ICoreStateRegistry } from "../../interfaces/ICoreStateRegistry.sol";

15: import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

15: import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

15: import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

16: import { DataLib } from "../../libraries/DataLib.sol";

16: import { DataLib } from "../../libraries/DataLib.sol";

16: import { DataLib } from "../../libraries/DataLib.sol";

17: import { ProofLib } from "../../libraries/ProofLib.sol";

17: import { ProofLib } from "../../libraries/ProofLib.sol";

17: import { ProofLib } from "../../libraries/ProofLib.sol";

18: import { ArrayCastLib } from "../../libraries/ArrayCastLib.sol";

18: import { ArrayCastLib } from "../../libraries/ArrayCastLib.sol";

18: import { ArrayCastLib } from "../../libraries/ArrayCastLib.sol";

19: import { PayloadUpdaterLib } from "../../libraries/PayloadUpdaterLib.sol";

19: import { PayloadUpdaterLib } from "../../libraries/PayloadUpdaterLib.sol";

19: import { PayloadUpdaterLib } from "../../libraries/PayloadUpdaterLib.sol";

20: import { Error } from "../../libraries/Error.sol";

20: import { Error } from "../../libraries/Error.sol";

20: import { Error } from "../../libraries/Error.sol";

31: } from "../../types/DataTypes.sol";

31: } from "../../types/DataTypes.sol";

31: } from "../../types/DataTypes.sol";

265:                 || block.timestamp > failedDeposits_.lastProposedTimestamp + _getDelay()

288:                 || block.timestamp < failedDeposits_.lastProposedTimestamp + _getDelay()

297:         for (uint256 i; i < failedDeposits_.amounts.length; ++i) {

297:         for (uint256 i; i < failedDeposits_.amounts.length; ++i) {

404:         for (uint256 i; i < arrLen; ++i) {

404:         for (uint256 i; i < arrLen; ++i) {

435:             for (uint256 i; i < arrLen; ++i) {

435:             for (uint256 i; i < arrLen; ++i) {

441:                     ++currLen;

441:                     ++currLen;

536:                 ++validLen_;

536:                 ++validLen_;

608:         for (uint256 i = 0; i < len; ++i) {

608:         for (uint256 i = 0; i < len; ++i) {

670:         for (uint256 i; i < len; ++i) {

670:         for (uint256 i; i < len; ++i) {

735:         for (uint256 i; i < numberOfVaults; ++i) {

735:         for (uint256 i; i < numberOfVaults; ++i) {

```

### <a name="GAS-3"></a>[GAS-3] Don't initialize variables with default value

*Instances (1)*:
```solidity
File: CoreStateRegistry.sol

608:         for (uint256 i = 0; i < len; ++i) {

```

### <a name="GAS-4"></a>[GAS-4] Functions guaranteed to revert when called by normal users can be marked `payable`
If a function modifier such as `onlyOwner` is used, the function will revert if a normal user tries to pay the function. Marking the function as `payable` will lower the gas cost for legitimate callers because the compiler will not include checks for whether a payment was provided.

*Instances (1)*:
```solidity
File: CoreStateRegistry.sol

353:     function _onlyAllowedCaller(bytes32 role_) internal view {

```

### <a name="GAS-5"></a>[GAS-5] Use != 0 instead of > 0 for unsigned integer comparison

*Instances (4)*:
```solidity
File: CoreStateRegistry.sol

428:         if (validLen > 0) {

739:             if (multiVaultData.amounts[i] > 0) {

762:                         if (dstAmount > 0 && !multiVaultData.retain4626s[i]) {

867:                 if (dstAmount > 0 && !singleVaultData.retain4626) {

```


## Low Issues


| |Issue|Instances|
|-|:-|:-:|
| [L-1](#L-1) | Empty Function Body - Consider commenting why | 2 |
### <a name="L-1"></a>[L-1] Empty Function Body - Consider commenting why

*Instances (2)*:
```solidity
File: CoreStateRegistry.sol

61:     constructor(ISuperRegistry superRegistry_) BaseStateRegistry(superRegistry_) { }

543:                 } catch { }

```

