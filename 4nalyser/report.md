# Report


## Gas Optimizations


| |Issue|Instances|
|-|:-|:-:|
| [GAS-1](#GAS-1) | Using bools for storage incurs overhead | 7 |
| [GAS-2](#GAS-2) | Cache array length outside of loop | 23 |
| [GAS-3](#GAS-3) | Use calldata instead of memory for function arguments that do not get mutated | 36 |
| [GAS-4](#GAS-4) | For Operations that will not overflow, you could use unchecked | 964 |
| [GAS-5](#GAS-5) | Don't initialize variables with default value | 3 |
| [GAS-6](#GAS-6) | Functions guaranteed to revert when called by normal users can be marked `payable` | 37 |
| [GAS-7](#GAS-7) | `++i` costs less gas than `i++`, especially when it's used in `for`-loops (`--i`/`i--` too) | 1 |
| [GAS-8](#GAS-8) | Using `private` rather than `public` for constants, saves gas | 38 |
| [GAS-9](#GAS-9) | Use != 0 instead of > 0 for unsigned integer comparison | 14 |
| [GAS-10](#GAS-10) | `internal` functions not called by the contract should be removed | 5 |
### <a name="GAS-1"></a>[GAS-1] Using bools for storage incurs overhead
Use uint256(1) and uint256(2) for true/false to avoid a Gwarmaccess (100 gas), and to avoid Gsset (20000 gas) when changing from ‘false’ to ‘true’, after having been ‘true’ in the past. See [source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27).

*Instances (7)*:
```solidity
File: SuperPositions.sol

48:     bool public dynamicURIFrozen;

```

```solidity
File: SuperformFactory.sol

46:     mapping(uint256 superformId => bool superformIdExists) public isSuperform;

```

```solidity
File: crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

38:     mapping(bytes32 => bool) public processedMessages;

```

```solidity
File: crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

34:     mapping(uint16 => mapping(uint64 => bool)) public isValid;

```

```solidity
File: crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

37:     mapping(bytes32 => bool) public processedMessages;

```

```solidity
File: crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

39:     mapping(bytes32 => bool) public processedMessages;

```

```solidity
File: settings/SuperRegistry.sol

88:     mapping(uint8 ambId => bool isBroadcastAMB) public isBroadcastAMB;

```

### <a name="GAS-2"></a>[GAS-2] Cache array length outside of loop
If not cached, the solidity compiler will always read the length of the array during each iteration. That is, if it is a storage array, this is an extra sload operation (100 additional extra gas for each iteration except for the first) and if it is a memory array, this is an extra mload operation (3 additional gas for each iteration except for the first).

*Instances (23)*:
```solidity
File: BaseRouterImplementation.sol

220:             new bool[](req_.superformData.amounts.length),

258:         uint256 len = req_.superformsData.superformIds.length;

431:             new bool[](req_.superformData.superformIds.length),

432:             new bool[](req_.superformData.superformIds.length),

468:             new bool[](req_.superformsData.amounts.length),

469:             new bool[](req_.superformsData.amounts.length),

643:         v.len = vaultData_.superformIds.length;

741:         uint256 len = superforms.length;

819:         uint256 len = superformsData_.amounts.length;

820:         uint256 lenSuperforms = superformsData_.superformIds.length;

821:         uint256 liqRequestsLen = superformsData_.liqRequests.length;

833:         if (!(lenSuperforms == len && lenSuperforms == superformsData_.maxSlippages.length)) {

```

```solidity
File: EmergencyQueue.sol

109:         for (uint256 i; i < ids_.length; ++i) {

```

```solidity
File: SuperPositions.sol

97:             uint256 len = superformIds.length;

320:         for (uint256 i; i < superformIds_.length; ++i) {

```

```solidity
File: SuperformFactory.sol

106:         forms_ = formImplementations.length;

111:         superforms_ = superforms.length;

142:         uint256 len = superformIds_.length;

158:         uint256 len = superformIds_.length;

```

```solidity
File: crosschain-liquidity/DstSwapper.sol

402:             if (index_ >= data.superformIds.length) {

```

```solidity
File: libraries/ArrayCastLib.sol

44:             new bool[](superformIds.length),

45:             new bool[](superformIds.length),

```

```solidity
File: libraries/DataLib.sol

64:         uint256 len = superformIds_.length;

```

### <a name="GAS-3"></a>[GAS-3] Use calldata instead of memory for function arguments that do not get mutated
Mark data types as `calldata` instead of `memory` where possible. This makes it so that the data is not automatically loaded into memory. If the data passed into the function does not need to be changed (like updating values in an array), it can be passed in as `calldata`. The one exception to this is if the argument must later be passed into another function that takes an argument that specifies `memory` storage.

*Instances (36)*:
```solidity
File: vendor/socket/ISocketOneInchImpl.sol

22:         bytes memory swapExtraData

```

```solidity
File: vendor/wormhole/IWormhole.sol

78:         bytes memory payload,

92:     function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

96:         Signature[] memory signatures,

97:         GuardianSet memory guardianSet

103:     function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

131:     function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

133:     function parseGuardianSetUpgrade(bytes memory encodedUpgrade)

138:     function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

140:     function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

142:     function parseRecoverChainId(bytes memory encodedRecoverChainId)

147:     function submitContractUpgrade(bytes memory _vm) external;

149:     function submitSetMessageFee(bytes memory _vm) external;

151:     function submitNewGuardianSet(bytes memory _vm) external;

153:     function submitTransferFees(bytes memory _vm) external;

155:     function submitRecoverChainId(bytes memory _vm) external;

```

```solidity
File: vendor/wormhole/IWormholeReceiver.sol

43:         bytes memory payload,

44:         bytes[] memory additionalVaas,

```

```solidity
File: vendor/wormhole/IWormholeRelayer.sol

65:         bytes memory payload,

99:         bytes memory payload,

135:         bytes memory payload,

138:         VaaKey[] memory vaaKeys

171:         bytes memory payload,

174:         VaaKey[] memory vaaKeys,

217:         bytes memory payload,

224:         VaaKey[] memory vaaKeys,

266:         bytes memory payload,

269:         bytes memory encodedExecutionParameters,

273:         VaaKey[] memory vaaKeys,

314:         VaaKey memory deliveryVaaKey,

350:         VaaKey memory deliveryVaaKey,

353:         bytes memory newEncodedExecutionParameters,

427:         bytes memory encodedExecutionParameters,

541:         bytes[] memory encodedVMs,

542:         bytes memory encodedDeliveryVAA,

544:         bytes memory deliveryOverrides

```

### <a name="GAS-4"></a>[GAS-4] For Operations that will not overflow, you could use unchecked

*Instances (964)*:
```solidity
File: BaseForm.sol

4: import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

4: import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

4: import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

4: import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

4: import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

5: import { ERC165 } from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

5: import { ERC165 } from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

5: import { ERC165 } from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

5: import { ERC165 } from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

5: import { ERC165 } from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

6: import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

6: import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

6: import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

6: import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

6: import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

7: import { InitSingleVaultData } from "./types/DataTypes.sol";

7: import { InitSingleVaultData } from "./types/DataTypes.sol";

8: import { IBaseForm } from "./interfaces/IBaseForm.sol";

8: import { IBaseForm } from "./interfaces/IBaseForm.sol";

9: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

9: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

10: import { Error } from "./libraries/Error.sol";

10: import { Error } from "./libraries/Error.sol";

11: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

11: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

12: import { IEmergencyQueue } from "./interfaces/IEmergencyQueue.sol";

12: import { IEmergencyQueue } from "./interfaces/IEmergencyQueue.sol";

13: import { DataLib } from "./libraries/DataLib.sol";

13: import { DataLib } from "./libraries/DataLib.sol";

```

```solidity
File: BaseRouter.sol

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { IBaseRouter } from "./interfaces/IBaseRouter.sol";

6: import { IBaseRouter } from "./interfaces/IBaseRouter.sol";

7: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

7: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

8: import "./libraries/Error.sol";

8: import "./libraries/Error.sol";

9: import "./types/DataTypes.sol";

9: import "./types/DataTypes.sol";

```

```solidity
File: BaseRouterImplementation.sol

4: import { BaseRouter } from "./BaseRouter.sol";

5: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

5: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

5: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

5: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

7: import { IBaseStateRegistry } from "./interfaces/IBaseStateRegistry.sol";

7: import { IBaseStateRegistry } from "./interfaces/IBaseStateRegistry.sol";

8: import { IBaseRouterImplementation } from "./interfaces/IBaseRouterImplementation.sol";

8: import { IBaseRouterImplementation } from "./interfaces/IBaseRouterImplementation.sol";

9: import { IPayMaster } from "./interfaces/IPayMaster.sol";

9: import { IPayMaster } from "./interfaces/IPayMaster.sol";

10: import { IPaymentHelper } from "./interfaces/IPaymentHelper.sol";

10: import { IPaymentHelper } from "./interfaces/IPaymentHelper.sol";

11: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

11: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

12: import { IBaseForm } from "./interfaces/IBaseForm.sol";

12: import { IBaseForm } from "./interfaces/IBaseForm.sol";

13: import { IBridgeValidator } from "./interfaces/IBridgeValidator.sol";

13: import { IBridgeValidator } from "./interfaces/IBridgeValidator.sol";

14: import { ISuperPositions } from "./interfaces/ISuperPositions.sol";

14: import { ISuperPositions } from "./interfaces/ISuperPositions.sol";

15: import { DataLib } from "./libraries/DataLib.sol";

15: import { DataLib } from "./libraries/DataLib.sol";

16: import { Error } from "./libraries/Error.sol";

16: import { Error } from "./libraries/Error.sol";

17: import { IPermit2 } from "./vendor/dragonfly-xyz/IPermit2.sol";

17: import { IPermit2 } from "./vendor/dragonfly-xyz/IPermit2.sol";

17: import { IPermit2 } from "./vendor/dragonfly-xyz/IPermit2.sol";

17: import { IPermit2 } from "./vendor/dragonfly-xyz/IPermit2.sol";

18: import "./crosschain-liquidity/LiquidityHandler.sol";

18: import "./crosschain-liquidity/LiquidityHandler.sol";

18: import "./crosschain-liquidity/LiquidityHandler.sol";

19: import "./types/DataTypes.sol";

19: import "./types/DataTypes.sol";

149:         vars.currentPayloadId = ++payloadIds;

149:         vars.currentPayloadId = ++payloadIds;

243:         vars.currentPayloadId = ++payloadIds;

243:         vars.currentPayloadId = ++payloadIds;

268:         for (uint256 j; j < len; ++j) {

268:         for (uint256 j; j < len; ++j) {

373:         vars.currentPayloadId = ++payloadIds;

373:         vars.currentPayloadId = ++payloadIds;

460:         vars.currentPayloadId = ++payloadIds;

460:         vars.currentPayloadId = ++payloadIds;

653:         for (uint256 i; i < v.len; ++i) {

653:         for (uint256 i; i < v.len; ++i) {

743:         for (uint256 i; i < len; ++i) {

743:         for (uint256 i; i < len; ++i) {

839:         for (uint256 i; i < len; ++i) {

839:         for (uint256 i; i < len; ++i) {

865:         uint256 residualPayment = address(this).balance - _balanceBefore;

972:         for (uint256 i; i < v.len; ++i) {

972:         for (uint256 i; i < v.len; ++i) {

989:             for (uint256 i; i < v.len; ++i) {

989:             for (uint256 i; i < v.len; ++i) {

1003:                 v.totalAmount += v.approvalAmounts[i];

1044:             for (uint256 j; j < v.targetLen; ++j) {

1044:             for (uint256 j; j < v.targetLen; ++j) {

```

```solidity
File: EmergencyQueue.sol

4: import { DataLib } from "./libraries/DataLib.sol";

4: import { DataLib } from "./libraries/DataLib.sol";

5: import { IBaseForm } from "./interfaces/IBaseForm.sol";

5: import { IBaseForm } from "./interfaces/IBaseForm.sol";

6: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

6: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

7: import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";

7: import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";

8: import { IEmergencyQueue } from "./interfaces/IEmergencyQueue.sol";

8: import { IEmergencyQueue } from "./interfaces/IEmergencyQueue.sol";

9: import { Error } from "./libraries/Error.sol";

9: import { Error } from "./libraries/Error.sol";

10: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

10: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

11: import "./types/DataTypes.sol";

11: import "./types/DataTypes.sol";

93:         ++queueCounter;

93:         ++queueCounter;

109:         for (uint256 i; i < ids_.length; ++i) {

109:         for (uint256 i; i < ids_.length; ++i) {

```

```solidity
File: SuperPositions.sol

4: import { ERC1155A } from "ERC1155A/ERC1155A.sol";

5: import { sERC20 } from "ERC1155A/sERC20.sol";

13: } from "src/types/DataTypes.sol";

13: } from "src/types/DataTypes.sol";

14: import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

14: import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

14: import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

14: import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

15: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

15: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

16: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

16: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

17: import { ISuperPositions } from "src/interfaces/ISuperPositions.sol";

17: import { ISuperPositions } from "src/interfaces/ISuperPositions.sol";

18: import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";

18: import { ISuperformFactory } from "src/interfaces/ISuperformFactory.sol";

19: import { IBaseForm } from "src/interfaces/IBaseForm.sol";

19: import { IBaseForm } from "src/interfaces/IBaseForm.sol";

20: import { IBroadcastRegistry } from "./interfaces/IBroadcastRegistry.sol";

20: import { IBroadcastRegistry } from "./interfaces/IBroadcastRegistry.sol";

21: import { IPaymentHelper } from "./interfaces/IPaymentHelper.sol";

21: import { IPaymentHelper } from "./interfaces/IPaymentHelper.sol";

22: import { Error } from "src/libraries/Error.sol";

22: import { Error } from "src/libraries/Error.sol";

23: import { DataLib } from "src/libraries/DataLib.sol";

23: import { DataLib } from "src/libraries/DataLib.sol";

98:             for (uint256 i; i < len; ++i) {

98:             for (uint256 i; i < len; ++i) {

320:         for (uint256 i; i < superformIds_.length; ++i) {

320:         for (uint256 i; i < superformIds_.length; ++i) {

352:         string memory symbol = string(abi.encodePacked("sERC20-", IBaseForm(superform).superformYieldTokenSymbol()));

365:             abi.encode(CHAIN_ID, ++xChainPayloadCounter, id, name, symbol, decimal)

365:             abi.encode(CHAIN_ID, ++xChainPayloadCounter, id, name, symbol, decimal)

```

```solidity
File: SuperformFactory.sol

4: import { ERC165Checker } from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

4: import { ERC165Checker } from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

4: import { ERC165Checker } from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

4: import { ERC165Checker } from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

4: import { ERC165Checker } from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";

5: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

5: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

5: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

5: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

6: import { BaseForm } from "./BaseForm.sol";

7: import { BroadcastMessage } from "./types/DataTypes.sol";

7: import { BroadcastMessage } from "./types/DataTypes.sol";

8: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

8: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

9: import { IBaseForm } from "./interfaces/IBaseForm.sol";

9: import { IBaseForm } from "./interfaces/IBaseForm.sol";

10: import { IBroadcastRegistry } from "./interfaces/IBroadcastRegistry.sol";

10: import { IBroadcastRegistry } from "./interfaces/IBroadcastRegistry.sol";

11: import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";

11: import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";

12: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

12: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

13: import { Error } from "./libraries/Error.sol";

13: import { Error } from "./libraries/Error.sol";

14: import { DataLib } from "./libraries/DataLib.sol";

14: import { DataLib } from "./libraries/DataLib.sol";

15: import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";

15: import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";

15: import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";

15: import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";

145:         for (uint256 i; i < len; ++i) {

145:         for (uint256 i; i < len; ++i) {

161:         for (uint256 i; i < len; ++i) {

161:         for (uint256 i; i < len; ++i) {

219:         ++superformCounter;

219:         ++superformCounter;

258:                 abi.encode(CHAIN_ID, ++xChainPayloadCounter, formImplementationId_, status_)

258:                 abi.encode(CHAIN_ID, ++xChainPayloadCounter, formImplementationId_, status_)

```

```solidity
File: SuperformRouter.sol

4: import { BaseRouterImplementation } from "./BaseRouterImplementation.sol";

5: import { BaseRouter } from "./BaseRouter.sol";

6: import { IBaseRouter } from "./interfaces/IBaseRouter.sol";

6: import { IBaseRouter } from "./interfaces/IBaseRouter.sol";

7: import "./types/DataTypes.sol";

7: import "./types/DataTypes.sol";

30:         uint256 balanceBefore = address(this).balance - msg.value;

42:         uint256 balanceBefore = address(this).balance - msg.value;

54:         uint256 balanceBefore = address(this).balance - msg.value;

66:         uint256 balanceBefore = address(this).balance - msg.value;

79:         uint256 balanceBefore = address(this).balance - msg.value;

82:         for (uint256 i; i < len; ++i) {

82:         for (uint256 i; i < len; ++i) {

102:         uint256 balanceBefore = address(this).balance - msg.value;

104:         for (uint256 i; i < len; ++i) {

104:         for (uint256 i; i < len; ++i) {

123:         uint256 balanceBefore = address(this).balance - msg.value;

135:         uint256 balanceBefore = address(this).balance - msg.value;

147:         uint256 balanceBefore = address(this).balance - msg.value;

159:         uint256 balanceBefore = address(this).balance - msg.value;

171:         uint256 balanceBefore = address(this).balance - msg.value;

174:         for (uint256 i; i < len; ++i) {

174:         for (uint256 i; i < len; ++i) {

194:         uint256 balanceBefore = address(this).balance - msg.value;

197:         for (uint256 i; i < len; ++i) {

197:         for (uint256 i; i < len; ++i) {

```

```solidity
File: crosschain-data/BaseStateRegistry.sol

4: import { Error } from "../libraries/Error.sol";

4: import { Error } from "../libraries/Error.sol";

5: import { IQuorumManager } from "../interfaces/IQuorumManager.sol";

5: import { IQuorumManager } from "../interfaces/IQuorumManager.sol";

6: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

6: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

7: import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";

7: import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";

8: import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";

8: import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";

9: import { PayloadState, AMBMessage, AMBExtraData } from "../types/DataTypes.sol";

9: import { PayloadState, AMBMessage, AMBExtraData } from "../types/DataTypes.sol";

10: import { ProofLib } from "../libraries/ProofLib.sol";

10: import { ProofLib } from "../libraries/ProofLib.sol";

117:             ++messageQuorum[proofHash];

117:             ++messageQuorum[proofHash];

122:             ++payloadsCount;

122:             ++payloadsCount;

155:         if (len - 1 < _getQuorum(dstChainId_)) {

172:             for (uint8 i = 1; i < len; ++i) {

172:             for (uint8 i = 1; i < len; ++i) {

177:                 if (i - 1 > 0 && ambIds_[i] <= ambIds_[i - 1]) {

177:                 if (i - 1 > 0 && ambIds_[i] <= ambIds_[i - 1]) {

```

```solidity
File: crosschain-data/BroadcastRegistry.sol

4: import { Error } from "src/libraries/Error.sol";

4: import { Error } from "src/libraries/Error.sol";

5: import { IBroadcastRegistry } from "src/interfaces/IBroadcastRegistry.sol";

5: import { IBroadcastRegistry } from "src/interfaces/IBroadcastRegistry.sol";

6: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

6: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

7: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

7: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

8: import { BroadcastMessage, PayloadState } from "src/types/DataTypes.sol";

8: import { BroadcastMessage, PayloadState } from "src/types/DataTypes.sol";

9: import { IBroadcastAmbImplementation } from "src/interfaces/IBroadcastAmbImplementation.sol";

9: import { IBroadcastAmbImplementation } from "src/interfaces/IBroadcastAmbImplementation.sol";

10: import { ProofLib } from "../libraries/ProofLib.sol";

10: import { ProofLib } from "../libraries/ProofLib.sol";

114:         ++payloadsCount;

114:         ++payloadsCount;

```

```solidity
File: crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

4: import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";

4: import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";

5: import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";

5: import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";

6: import { IMailbox } from "src/vendor/hyperlane/IMailbox.sol";

6: import { IMailbox } from "src/vendor/hyperlane/IMailbox.sol";

6: import { IMailbox } from "src/vendor/hyperlane/IMailbox.sol";

7: import { StandardHookMetadata } from "src/vendor/hyperlane/StandardHookMetadata.sol";

7: import { StandardHookMetadata } from "src/vendor/hyperlane/StandardHookMetadata.sol";

7: import { StandardHookMetadata } from "src/vendor/hyperlane/StandardHookMetadata.sol";

8: import { IMessageRecipient } from "src/vendor/hyperlane/IMessageRecipient.sol";

8: import { IMessageRecipient } from "src/vendor/hyperlane/IMessageRecipient.sol";

8: import { IMessageRecipient } from "src/vendor/hyperlane/IMessageRecipient.sol";

9: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

9: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

10: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

10: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

11: import { IInterchainGasPaymaster } from "src/vendor/hyperlane/IInterchainGasPaymaster.sol";

11: import { IInterchainGasPaymaster } from "src/vendor/hyperlane/IInterchainGasPaymaster.sol";

11: import { IInterchainGasPaymaster } from "src/vendor/hyperlane/IInterchainGasPaymaster.sol";

12: import { AMBMessage } from "src/types/DataTypes.sol";

12: import { AMBMessage } from "src/types/DataTypes.sol";

13: import { Error } from "src/libraries/Error.sol";

13: import { Error } from "src/libraries/Error.sol";

14: import { DataLib } from "src/libraries/DataLib.sol";

14: import { DataLib } from "src/libraries/DataLib.sol";

```

```solidity
File: crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

4: import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";

4: import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";

5: import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";

5: import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";

6: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

6: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

7: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

7: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

8: import { AMBMessage } from "src/types/DataTypes.sol";

8: import { AMBMessage } from "src/types/DataTypes.sol";

9: import { Error } from "src/libraries/Error.sol";

9: import { Error } from "src/libraries/Error.sol";

10: import { ILayerZeroReceiver } from "src/vendor/layerzero/ILayerZeroReceiver.sol";

10: import { ILayerZeroReceiver } from "src/vendor/layerzero/ILayerZeroReceiver.sol";

10: import { ILayerZeroReceiver } from "src/vendor/layerzero/ILayerZeroReceiver.sol";

11: import { ILayerZeroUserApplicationConfig } from "src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol";

11: import { ILayerZeroUserApplicationConfig } from "src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol";

11: import { ILayerZeroUserApplicationConfig } from "src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol";

12: import { ILayerZeroEndpoint } from "src/vendor/layerzero/ILayerZeroEndpoint.sol";

12: import { ILayerZeroEndpoint } from "src/vendor/layerzero/ILayerZeroEndpoint.sol";

12: import { ILayerZeroEndpoint } from "src/vendor/layerzero/ILayerZeroEndpoint.sol";

13: import { DataLib } from "src/libraries/DataLib.sol";

13: import { DataLib } from "src/libraries/DataLib.sol";

```

```solidity
File: crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

4: import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";

4: import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";

5: import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";

5: import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";

6: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

6: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

7: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

7: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

8: import { AMBMessage } from "src/types/DataTypes.sol";

8: import { AMBMessage } from "src/types/DataTypes.sol";

9: import { Error } from "src/libraries/Error.sol";

9: import { Error } from "src/libraries/Error.sol";

10: import { IWormholeRelayer, VaaKey } from "src/vendor/wormhole/IWormholeRelayer.sol";

10: import { IWormholeRelayer, VaaKey } from "src/vendor/wormhole/IWormholeRelayer.sol";

10: import { IWormholeRelayer, VaaKey } from "src/vendor/wormhole/IWormholeRelayer.sol";

11: import { IWormholeReceiver } from "src/vendor/wormhole/IWormholeReceiver.sol";

11: import { IWormholeReceiver } from "src/vendor/wormhole/IWormholeReceiver.sol";

11: import { IWormholeReceiver } from "src/vendor/wormhole/IWormholeReceiver.sol";

12: import { DataLib } from "src/libraries/DataLib.sol";

12: import { DataLib } from "src/libraries/DataLib.sol";

13: import "src/vendor/wormhole/Utils.sol";

13: import "src/vendor/wormhole/Utils.sol";

13: import "src/vendor/wormhole/Utils.sol";

131:         address, /*srcSender_*/

131:         address, /*srcSender_*/

131:         address, /*srcSender_*/

131:         address, /*srcSender_*/

```

```solidity
File: crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

4: import { IBroadcastRegistry } from "src/interfaces/IBroadcastRegistry.sol";

4: import { IBroadcastRegistry } from "src/interfaces/IBroadcastRegistry.sol";

5: import { IBroadcastAmbImplementation } from "src/interfaces/IBroadcastAmbImplementation.sol";

5: import { IBroadcastAmbImplementation } from "src/interfaces/IBroadcastAmbImplementation.sol";

6: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

6: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

7: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

7: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

8: import { Error } from "src/libraries/Error.sol";

8: import { Error } from "src/libraries/Error.sol";

9: import { IWormhole } from "src/vendor/wormhole/IWormhole.sol";

9: import { IWormhole } from "src/vendor/wormhole/IWormhole.sol";

9: import { IWormhole } from "src/vendor/wormhole/IWormhole.sol";

10: import { DataLib } from "src/libraries/DataLib.sol";

10: import { DataLib } from "src/libraries/DataLib.sol";

11: import "src/vendor/wormhole/Utils.sol";

11: import "src/vendor/wormhole/Utils.sol";

11: import "src/vendor/wormhole/Utils.sol";

129:         bytes memory, /*message_*/

129:         bytes memory, /*message_*/

129:         bytes memory, /*message_*/

129:         bytes memory, /*message_*/

130:         bytes memory /*extraData_*/

130:         bytes memory /*extraData_*/

130:         bytes memory /*extraData_*/

130:         bytes memory /*extraData_*/

146:         address, /*srcSender_*/

146:         address, /*srcSender_*/

146:         address, /*srcSender_*/

146:         address, /*srcSender_*/

148:         bytes memory /*extraData_*/

148:         bytes memory /*extraData_*/

148:         bytes memory /*extraData_*/

148:         bytes memory /*extraData_*/

174:         (bool success,) = payable(relayer).call{ value: msg.value - msgFee }("");

```

```solidity
File: crosschain-data/extensions/TimelockStateRegistry.sol

4: import { ReentrancyGuard } from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

4: import { ReentrancyGuard } from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

4: import { ReentrancyGuard } from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

4: import { ReentrancyGuard } from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

5: import { IBaseForm } from "../../interfaces/IBaseForm.sol";

5: import { IBaseForm } from "../../interfaces/IBaseForm.sol";

5: import { IBaseForm } from "../../interfaces/IBaseForm.sol";

6: import { ISuperformFactory } from "../../interfaces/ISuperformFactory.sol";

6: import { ISuperformFactory } from "../../interfaces/ISuperformFactory.sol";

6: import { ISuperformFactory } from "../../interfaces/ISuperformFactory.sol";

7: import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";

7: import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";

7: import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";

8: import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

8: import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

8: import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

9: import { IQuorumManager } from "../../interfaces/IQuorumManager.sol";

9: import { IQuorumManager } from "../../interfaces/IQuorumManager.sol";

9: import { IQuorumManager } from "../../interfaces/IQuorumManager.sol";

10: import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";

10: import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";

10: import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";

11: import { IERC4626TimelockForm } from "../../forms/interfaces/IERC4626TimelockForm.sol";

11: import { IERC4626TimelockForm } from "../../forms/interfaces/IERC4626TimelockForm.sol";

11: import { IERC4626TimelockForm } from "../../forms/interfaces/IERC4626TimelockForm.sol";

11: import { IERC4626TimelockForm } from "../../forms/interfaces/IERC4626TimelockForm.sol";

12: import { ITimelockStateRegistry } from "../../interfaces/ITimelockStateRegistry.sol";

12: import { ITimelockStateRegistry } from "../../interfaces/ITimelockStateRegistry.sol";

12: import { ITimelockStateRegistry } from "../../interfaces/ITimelockStateRegistry.sol";

13: import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";

13: import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";

13: import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";

14: import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";

14: import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";

14: import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";

15: import { IPaymentHelper } from "../../interfaces/IPaymentHelper.sol";

15: import { IPaymentHelper } from "../../interfaces/IPaymentHelper.sol";

15: import { IPaymentHelper } from "../../interfaces/IPaymentHelper.sol";

16: import { Error } from "../../libraries/Error.sol";

16: import { Error } from "../../libraries/Error.sol";

16: import { Error } from "../../libraries/Error.sol";

17: import { BaseStateRegistry } from "../BaseStateRegistry.sol";

18: import { ProofLib } from "../../libraries/ProofLib.sol";

18: import { ProofLib } from "../../libraries/ProofLib.sol";

18: import { ProofLib } from "../../libraries/ProofLib.sol";

19: import { DataLib } from "../../libraries/DataLib.sol";

19: import { DataLib } from "../../libraries/DataLib.sol";

19: import { DataLib } from "../../libraries/DataLib.sol";

20: import { PayloadUpdaterLib } from "../../libraries/PayloadUpdaterLib.sol";

20: import { PayloadUpdaterLib } from "../../libraries/PayloadUpdaterLib.sol";

20: import { PayloadUpdaterLib } from "../../libraries/PayloadUpdaterLib.sol";

21: import "../../types/DataTypes.sol";

21: import "../../types/DataTypes.sol";

21: import "../../types/DataTypes.sol";

112:         ++timelockPayloadCounter;

112:         ++timelockPayloadCounter;

```

```solidity
File: crosschain-data/utils/PayloadHelper.sol

4: import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";

4: import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";

4: import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";

5: import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";

5: import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";

5: import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";

6: import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";

6: import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";

6: import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";

7: import { ITimelockStateRegistry } from "../../interfaces/ITimelockStateRegistry.sol";

7: import { ITimelockStateRegistry } from "../../interfaces/ITimelockStateRegistry.sol";

7: import { ITimelockStateRegistry } from "../../interfaces/ITimelockStateRegistry.sol";

8: import { IPayloadHelper } from "../../interfaces/IPayloadHelper.sol";

8: import { IPayloadHelper } from "../../interfaces/IPayloadHelper.sol";

8: import { IPayloadHelper } from "../../interfaces/IPayloadHelper.sol";

9: import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

9: import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

9: import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

10: import { Error } from "../../libraries/Error.sol";

10: import { Error } from "../../libraries/Error.sol";

10: import { Error } from "../../libraries/Error.sol";

20: } from "../../types/DataTypes.sol";

20: } from "../../types/DataTypes.sol";

20: } from "../../types/DataTypes.sol";

21: import { DataLib } from "../../libraries/DataLib.sol";

21: import { DataLib } from "../../libraries/DataLib.sol";

21: import { DataLib } from "../../libraries/DataLib.sol";

22: import { ProofLib } from "../../libraries/ProofLib.sol";

22: import { ProofLib } from "../../libraries/ProofLib.sol";

22: import { ProofLib } from "../../libraries/ProofLib.sol";

366:         for (uint256 i = 0; i < len; ++i) {

366:         for (uint256 i = 0; i < len; ++i) {

```

```solidity
File: crosschain-data/utils/QuorumManager.sol

4: import { IQuorumManager } from "../../interfaces/IQuorumManager.sol";

4: import { IQuorumManager } from "../../interfaces/IQuorumManager.sol";

4: import { IQuorumManager } from "../../interfaces/IQuorumManager.sol";

5: import { Error } from "../../libraries/Error.sol";

5: import { Error } from "../../libraries/Error.sol";

5: import { Error } from "../../libraries/Error.sol";

```

```solidity
File: crosschain-liquidity/BridgeValidator.sol

4: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

4: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

5: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

5: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

```

```solidity
File: crosschain-liquidity/DstSwapper.sol

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

6: import { ReentrancyGuard } from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

6: import { ReentrancyGuard } from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

6: import { ReentrancyGuard } from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

6: import { ReentrancyGuard } from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

7: import { IDstSwapper } from "../interfaces/IDstSwapper.sol";

7: import { IDstSwapper } from "../interfaces/IDstSwapper.sol";

8: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

8: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

9: import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";

9: import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";

10: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

10: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

11: import { LiquidityHandler } from "../crosschain-liquidity/LiquidityHandler.sol";

11: import { LiquidityHandler } from "../crosschain-liquidity/LiquidityHandler.sol";

11: import { LiquidityHandler } from "../crosschain-liquidity/LiquidityHandler.sol";

12: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

12: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

13: import { IERC4626Form } from "../forms/interfaces/IERC4626Form.sol";

13: import { IERC4626Form } from "../forms/interfaces/IERC4626Form.sol";

13: import { IERC4626Form } from "../forms/interfaces/IERC4626Form.sol";

14: import { Error } from "../libraries/Error.sol";

14: import { Error } from "../libraries/Error.sol";

15: import { DataLib } from "../libraries/DataLib.sol";

15: import { DataLib } from "../libraries/DataLib.sol";

16: import { PayloadUpdaterLib } from "../libraries/PayloadUpdaterLib.sol";

16: import { PayloadUpdaterLib } from "../libraries/PayloadUpdaterLib.sol";

17: import "../types/DataTypes.sol";

17: import "../types/DataTypes.sol";

167:         for (uint256 i; i < len; ++i) {

167:         for (uint256 i; i < len; ++i) {

223:         for (uint256 i; i < len; ++i) {

223:         for (uint256 i; i < len; ++i) {

318:         v.balanceDiff = v.balanceAfter - v.balanceBefore;

```

```solidity
File: crosschain-liquidity/LiquidityHandler.sol

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { Error } from "../libraries/Error.sol";

6: import { Error } from "../libraries/Error.sol";

```

```solidity
File: crosschain-liquidity/lifi/LiFiValidator.sol

4: import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";

4: import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";

4: import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";

5: import { Error } from "src/libraries/Error.sol";

5: import { Error } from "src/libraries/Error.sol";

6: import { LiFiTxDataExtractor } from "src/vendor/lifi/LiFiTxDataExtractor.sol";

6: import { LiFiTxDataExtractor } from "src/vendor/lifi/LiFiTxDataExtractor.sol";

6: import { LiFiTxDataExtractor } from "src/vendor/lifi/LiFiTxDataExtractor.sol";

7: import { LibSwap } from "src/vendor/lifi/LibSwap.sol";

7: import { LibSwap } from "src/vendor/lifi/LibSwap.sol";

7: import { LibSwap } from "src/vendor/lifi/LibSwap.sol";

8: import { ILiFi } from "src/vendor/lifi/ILiFi.sol";

8: import { ILiFi } from "src/vendor/lifi/ILiFi.sol";

8: import { ILiFi } from "src/vendor/lifi/ILiFi.sol";

9: import { StandardizedCallFacet } from "src/vendor/lifi/StandardizedCallFacet.sol";

9: import { StandardizedCallFacet } from "src/vendor/lifi/StandardizedCallFacet.sol";

9: import { StandardizedCallFacet } from "src/vendor/lifi/StandardizedCallFacet.sol";

38:             string memory, /*bridge*/

38:             string memory, /*bridge*/

38:             string memory, /*bridge*/

38:             string memory, /*bridge*/

41:             uint256, /*amount*/

41:             uint256, /*amount*/

41:             uint256, /*amount*/

41:             uint256, /*amount*/

42:             uint256, /*minAmount*/

42:             uint256, /*minAmount*/

42:             uint256, /*minAmount*/

42:             uint256, /*minAmount*/

44:             bool, /*hasSourceSwaps*/

44:             bool, /*hasSourceSwaps*/

44:             bool, /*hasSourceSwaps*/

44:             bool, /*hasSourceSwaps*/

131:             string memory, /*bridge*/

131:             string memory, /*bridge*/

131:             string memory, /*bridge*/

131:             string memory, /*bridge*/

132:             address, /*sendingAssetId*/

132:             address, /*sendingAssetId*/

132:             address, /*sendingAssetId*/

132:             address, /*sendingAssetId*/

133:             address, /*receiver*/

133:             address, /*receiver*/

133:             address, /*receiver*/

133:             address, /*receiver*/

135:             uint256, /*minAmount*/

135:             uint256, /*minAmount*/

135:             uint256, /*minAmount*/

135:             uint256, /*minAmount*/

136:             uint256, /*destinationChainId*/

136:             uint256, /*destinationChainId*/

136:             uint256, /*destinationChainId*/

136:             uint256, /*destinationChainId*/

137:             bool, /*hasSourceSwaps*/

137:             bool, /*hasSourceSwaps*/

137:             bool, /*hasSourceSwaps*/

137:             bool, /*hasSourceSwaps*/

138:             bool /*hasDestinationCall*/

138:             bool /*hasDestinationCall*/

138:             bool /*hasDestinationCall*/

138:             bool /*hasDestinationCall*/

158:             string memory, /*bridge*/

158:             string memory, /*bridge*/

158:             string memory, /*bridge*/

158:             string memory, /*bridge*/

159:             address, /*sendingAssetId*/

159:             address, /*sendingAssetId*/

159:             address, /*sendingAssetId*/

159:             address, /*sendingAssetId*/

160:             address, /*receiver*/

160:             address, /*receiver*/

160:             address, /*receiver*/

160:             address, /*receiver*/

161:             uint256, /*amount*/

161:             uint256, /*amount*/

161:             uint256, /*amount*/

161:             uint256, /*amount*/

162:             uint256, /*minAmount*/

162:             uint256, /*minAmount*/

162:             uint256, /*minAmount*/

162:             uint256, /*minAmount*/

163:             uint256, /*destinationChainId*/

163:             uint256, /*destinationChainId*/

163:             uint256, /*destinationChainId*/

163:             uint256, /*destinationChainId*/

164:             bool, /*hasSourceSwaps*/

164:             bool, /*hasSourceSwaps*/

164:             bool, /*hasSourceSwaps*/

164:             bool, /*hasSourceSwaps*/

165:             bool /*hasDestinationCall*/

165:             bool /*hasDestinationCall*/

165:             bool /*hasDestinationCall*/

165:             bool /*hasDestinationCall*/

249:             _slice(callData, 4, callData.length - 4), (bytes32, string, string, address, uint256, LibSwap.SwapData[])

254:         receivingAssetId = swapData[swapData.length - 1].receivingAssetId;

```

```solidity
File: crosschain-liquidity/socket/SocketOneInchValidator.sol

4: import { Error } from "src/libraries/Error.sol";

4: import { Error } from "src/libraries/Error.sol";

5: import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";

5: import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";

5: import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";

6: import { ISocketOneInchImpl } from "src/vendor/socket/ISocketOneInchImpl.sol";

6: import { ISocketOneInchImpl } from "src/vendor/socket/ISocketOneInchImpl.sol";

6: import { ISocketOneInchImpl } from "src/vendor/socket/ISocketOneInchImpl.sol";

54:         bool /*genericSwapDisallowed_*/

54:         bool /*genericSwapDisallowed_*/

54:         bool /*genericSwapDisallowed_*/

54:         bool /*genericSwapDisallowed_*/

```

```solidity
File: crosschain-liquidity/socket/SocketValidator.sol

4: import { Error } from "src/libraries/Error.sol";

4: import { Error } from "src/libraries/Error.sol";

5: import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";

5: import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";

5: import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";

6: import { ISocketRegistry } from "src/vendor/socket/ISocketRegistry.sol";

6: import { ISocketRegistry } from "src/vendor/socket/ISocketRegistry.sol";

6: import { ISocketRegistry } from "src/vendor/socket/ISocketRegistry.sol";

77:         bool /*genericSwapDisallowed_*/

77:         bool /*genericSwapDisallowed_*/

77:         bool /*genericSwapDisallowed_*/

77:         bool /*genericSwapDisallowed_*/

88:     function decodeDstSwap(bytes calldata /*txData_*/ )

88:     function decodeDstSwap(bytes calldata /*txData_*/ )

88:     function decodeDstSwap(bytes calldata /*txData_*/ )

88:     function decodeDstSwap(bytes calldata /*txData_*/ )

92:         returns (address, /*token_*/ uint256 /*amount_*/ )

92:         returns (address, /*token_*/ uint256 /*amount_*/ )

92:         returns (address, /*token_*/ uint256 /*amount_*/ )

92:         returns (address, /*token_*/ uint256 /*amount_*/ )

92:         returns (address, /*token_*/ uint256 /*amount_*/ )

92:         returns (address, /*token_*/ uint256 /*amount_*/ )

92:         returns (address, /*token_*/ uint256 /*amount_*/ )

92:         returns (address, /*token_*/ uint256 /*amount_*/ )

97:     function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {

97:     function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {

97:     function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {

97:     function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {

97:     function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {

97:     function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {

97:     function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {

97:     function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {

```

```solidity
File: forms/ERC4626Form.sol

4: import { InitSingleVaultData } from "../types/DataTypes.sol";

4: import { InitSingleVaultData } from "../types/DataTypes.sol";

5: import { ERC4626FormImplementation } from "./ERC4626FormImplementation.sol";

6: import { BaseForm } from "../BaseForm.sol";

15:     uint8 constant stateRegistryId = 1; // CoreStateRegistry

15:     uint8 constant stateRegistryId = 1; // CoreStateRegistry

30:         address /*srcSender_*/

30:         address /*srcSender_*/

30:         address /*srcSender_*/

30:         address /*srcSender_*/

78:     function _emergencyWithdraw(address, /*srcSender_*/ address refundAddress_, uint256 amount_) internal override {

78:     function _emergencyWithdraw(address, /*srcSender_*/ address refundAddress_, uint256 amount_) internal override {

78:     function _emergencyWithdraw(address, /*srcSender_*/ address refundAddress_, uint256 amount_) internal override {

78:     function _emergencyWithdraw(address, /*srcSender_*/ address refundAddress_, uint256 amount_) internal override {

```

```solidity
File: forms/ERC4626FormImplementation.sol

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

5: import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

5: import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

5: import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

5: import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

5: import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

5: import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

7: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

7: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

7: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

7: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

8: import { LiquidityHandler } from "../crosschain-liquidity/LiquidityHandler.sol";

8: import { LiquidityHandler } from "../crosschain-liquidity/LiquidityHandler.sol";

8: import { LiquidityHandler } from "../crosschain-liquidity/LiquidityHandler.sol";

9: import { InitSingleVaultData } from "../types/DataTypes.sol";

9: import { InitSingleVaultData } from "../types/DataTypes.sol";

10: import { BaseForm } from "../BaseForm.sol";

11: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

11: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

12: import { Error } from "../libraries/Error.sol";

12: import { Error } from "../libraries/Error.sol";

13: import { DataLib } from "../libraries/DataLib.sol";

13: import { DataLib } from "../libraries/DataLib.sol";

98:         return IERC4626(vault).convertToAssets(10 ** vaultDecimals);

98:         return IERC4626(vault).convertToAssets(10 ** vaultDecimals);

119:         return IERC4626(vault).previewRedeem(10 ** vaultDecimals);

119:         return IERC4626(vault).previewRedeem(10 ** vaultDecimals);

144:         return string(abi.encodePacked("SUP-", IERC20Metadata(vault).symbol()));

227:         vars.assetDifference = IERC20(vars.asset).balanceOf(address(this)) - vars.balanceBefore;

335:         address, /*srcSender_*/

335:         address, /*srcSender_*/

335:         address, /*srcSender_*/

335:         address, /*srcSender_*/

```

```solidity
File: forms/ERC4626KYCDaoForm.sol

4: import { kycDAO4626 } from "super-vaults/kycdao-4626/kycdao4626.sol";

4: import { kycDAO4626 } from "super-vaults/kycdao-4626/kycdao4626.sol";

4: import { kycDAO4626 } from "super-vaults/kycdao-4626/kycdao4626.sol";

4: import { kycDAO4626 } from "super-vaults/kycdao-4626/kycdao4626.sol";

5: import { InitSingleVaultData } from "../types/DataTypes.sol";

5: import { InitSingleVaultData } from "../types/DataTypes.sol";

6: import { ERC4626FormImplementation } from "./ERC4626FormImplementation.sol";

7: import { BaseForm } from "../BaseForm.sol";

8: import { Error } from "../libraries/Error.sol";

8: import { Error } from "../libraries/Error.sol";

18:     uint8 constant stateRegistryId = 1; // CoreStateRegistry

18:     uint8 constant stateRegistryId = 1; // CoreStateRegistry

57:         InitSingleVaultData memory, /*singleVaultData_*/

57:         InitSingleVaultData memory, /*singleVaultData_*/

57:         InitSingleVaultData memory, /*singleVaultData_*/

57:         InitSingleVaultData memory, /*singleVaultData_*/

58:         address, /*srcSender_*/

58:         address, /*srcSender_*/

58:         address, /*srcSender_*/

58:         address, /*srcSender_*/

59:         uint64 /*srcChainId_*/

59:         uint64 /*srcChainId_*/

59:         uint64 /*srcChainId_*/

59:         uint64 /*srcChainId_*/

64:         returns (uint256 /*dstAmount*/ )

64:         returns (uint256 /*dstAmount*/ )

64:         returns (uint256 /*dstAmount*/ )

64:         returns (uint256 /*dstAmount*/ )

84:         InitSingleVaultData memory, /*singleVaultData_*/

84:         InitSingleVaultData memory, /*singleVaultData_*/

84:         InitSingleVaultData memory, /*singleVaultData_*/

84:         InitSingleVaultData memory, /*singleVaultData_*/

85:         address, /*srcSender_*/

85:         address, /*srcSender_*/

85:         address, /*srcSender_*/

85:         address, /*srcSender_*/

86:         uint64 /*srcChainId_*/

86:         uint64 /*srcChainId_*/

86:         uint64 /*srcChainId_*/

86:         uint64 /*srcChainId_*/

91:         returns (uint256 /*dstAmount*/ )

91:         returns (uint256 /*dstAmount*/ )

91:         returns (uint256 /*dstAmount*/ )

91:         returns (uint256 /*dstAmount*/ )

```

```solidity
File: forms/ERC4626TimelockForm.sol

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

5: import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

6: import { IERC4626TimelockVault } from "super-vaults/interfaces/IERC4626TimelockVault.sol";

6: import { IERC4626TimelockVault } from "super-vaults/interfaces/IERC4626TimelockVault.sol";

6: import { IERC4626TimelockVault } from "super-vaults/interfaces/IERC4626TimelockVault.sol";

7: import { InitSingleVaultData, TimelockPayload, LiqRequest } from "../types/DataTypes.sol";

7: import { InitSingleVaultData, TimelockPayload, LiqRequest } from "../types/DataTypes.sol";

8: import { ERC4626FormImplementation } from "./ERC4626FormImplementation.sol";

9: import { BaseForm } from "../BaseForm.sol";

10: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

10: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

11: import { ITimelockStateRegistry } from "../interfaces/ITimelockStateRegistry.sol";

11: import { ITimelockStateRegistry } from "../interfaces/ITimelockStateRegistry.sol";

12: import { IEmergencyQueue } from "../interfaces/IEmergencyQueue.sol";

12: import { IEmergencyQueue } from "../interfaces/IEmergencyQueue.sol";

13: import { DataLib } from "../libraries/DataLib.sol";

13: import { DataLib } from "../libraries/DataLib.sol";

14: import { Error } from "../libraries/Error.sol";

14: import { Error } from "../libraries/Error.sol";

26:     uint8 constant stateRegistryId = 2; // TimelockStateRegistry

26:     uint8 constant stateRegistryId = 2; // TimelockStateRegistry

135:         address /*srcSender_*/

135:         address /*srcSender_*/

135:         address /*srcSender_*/

135:         address /*srcSender_*/

201:     function _emergencyWithdraw(address, /*srcSender_*/ address refundAddress_, uint256 amount_) internal override {

201:     function _emergencyWithdraw(address, /*srcSender_*/ address refundAddress_, uint256 amount_) internal override {

201:     function _emergencyWithdraw(address, /*srcSender_*/ address refundAddress_, uint256 amount_) internal override {

201:     function _emergencyWithdraw(address, /*srcSender_*/ address refundAddress_, uint256 amount_) internal override {

216:         lockedTill_ = block.timestamp + v.getLockPeriod();

```

```solidity
File: forms/interfaces/IERC4626Form.sol

4: import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

```

```solidity
File: forms/interfaces/IERC4626TimelockForm.sol

4: import { IERC4626Form } from "./IERC4626Form.sol";

5: import { InitSingleVaultData, TimelockPayload } from "../../types/DataTypes.sol";

5: import { InitSingleVaultData, TimelockPayload } from "../../types/DataTypes.sol";

5: import { InitSingleVaultData, TimelockPayload } from "../../types/DataTypes.sol";

```

```solidity
File: interfaces/IBaseForm.sol

4: import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

4: import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

4: import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

4: import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

4: import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

5: import { InitSingleVaultData } from "../types/DataTypes.sol";

5: import { InitSingleVaultData } from "../types/DataTypes.sol";

6: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

6: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

6: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

6: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

```

```solidity
File: interfaces/IBaseRouter.sol

4: import "../types/DataTypes.sol";

4: import "../types/DataTypes.sol";

```

```solidity
File: interfaces/IBaseRouterImplementation.sol

4: import { IBaseRouter } from "./IBaseRouter.sol";

6: import "../types/DataTypes.sol";

6: import "../types/DataTypes.sol";

```

```solidity
File: interfaces/IBaseStateRegistry.sol

4: import "../types/DataTypes.sol";

4: import "../types/DataTypes.sol";

```

```solidity
File: interfaces/IEmergencyQueue.sol

4: import { InitSingleVaultData } from "../types/DataTypes.sol";

4: import { InitSingleVaultData } from "../types/DataTypes.sol";

```

```solidity
File: interfaces/IPayMaster.sol

4: import { LiqRequest } from "../types/DataTypes.sol";

4: import { LiqRequest } from "../types/DataTypes.sol";

```

```solidity
File: interfaces/IPaymentHelper.sol

11: } from "../types/DataTypes.sol";

11: } from "../types/DataTypes.sol";

```

```solidity
File: interfaces/ISuperPositions.sol

4: import { AMBMessage } from "../types/DataTypes.sol";

4: import { AMBMessage } from "../types/DataTypes.sol";

5: import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";

5: import { IERC1155A } from "ERC1155A/interfaces/IERC1155A.sol";

```

```solidity
File: interfaces/ISuperRBAC.sol

4: import { IAccessControl } from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

4: import { IAccessControl } from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

4: import { IAccessControl } from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

4: import { IAccessControl } from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

```

```solidity
File: interfaces/ITimelockStateRegistry.sol

4: import { InitSingleVaultData, TimelockPayload } from "../types/DataTypes.sol";

4: import { InitSingleVaultData, TimelockPayload } from "../types/DataTypes.sol";

```

```solidity
File: libraries/ArrayCastLib.sol

4: import { InitSingleVaultData, InitMultiVaultData, LiqRequest } from "../types/DataTypes.sol";

4: import { InitSingleVaultData, InitMultiVaultData, LiqRequest } from "../types/DataTypes.sol";

```

```solidity
File: libraries/DataLib.sol

4: import { Error } from "../libraries/Error.sol";

4: import { Error } from "../libraries/Error.sol";

67:         for (uint256 i = 0; i < len; ++i) {

67:         for (uint256 i = 0; i < len; ++i) {

```

```solidity
File: libraries/PayloadUpdaterLib.sol

4: import { DataLib } from "./DataLib.sol";

5: import { Error } from "../libraries/Error.sol";

5: import { Error } from "../libraries/Error.sol";

6: import { PayloadState, CallbackType, LiqRequest } from "../types/DataTypes.sol";

6: import { PayloadState, CallbackType, LiqRequest } from "../types/DataTypes.sol";

24:         uint256 minAmount = (maxAmount_ * (10_000 - slippage_)) / 10_000;

24:         uint256 minAmount = (maxAmount_ * (10_000 - slippage_)) / 10_000;

24:         uint256 minAmount = (maxAmount_ * (10_000 - slippage_)) / 10_000;

```

```solidity
File: libraries/ProofLib.sol

4: import { AMBMessage } from "../types/DataTypes.sol";

4: import { AMBMessage } from "../types/DataTypes.sol";

```

```solidity
File: payments/PayMaster.sol

4: import { Error } from "../libraries/Error.sol";

4: import { Error } from "../libraries/Error.sol";

5: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

5: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

6: import { IPayMaster } from "../interfaces/IPayMaster.sol";

6: import { IPayMaster } from "../interfaces/IPayMaster.sol";

7: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

7: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

8: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

8: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

9: import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";

9: import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";

10: import { LiquidityHandler } from "../crosschain-liquidity/LiquidityHandler.sol";

10: import { LiquidityHandler } from "../crosschain-liquidity/LiquidityHandler.sol";

10: import { LiquidityHandler } from "../crosschain-liquidity/LiquidityHandler.sol";

11: import { LiqRequest } from "../types/DataTypes.sol";

11: import { LiqRequest } from "../types/DataTypes.sol";

101:         totalFeesPaid[user_] += msg.value;

```

```solidity
File: settings/SuperRBAC.sol

4: import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol";

4: import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol";

4: import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol";

4: import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol";

4: import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol";

5: import { IBroadcastRegistry } from "../interfaces/IBroadcastRegistry.sol";

5: import { IBroadcastRegistry } from "../interfaces/IBroadcastRegistry.sol";

6: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

6: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

7: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

7: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

8: import { Error } from "../libraries/Error.sol";

8: import { Error } from "../libraries/Error.sol";

9: import { BroadcastMessage } from "../types/DataTypes.sol";

9: import { BroadcastMessage } from "../types/DataTypes.sol";

177:                 "SUPER_RBAC", SYNC_REVOKE, abi.encode(++xChainPayloadCounter, role_, superRegistryAddressId_)

177:                 "SUPER_RBAC", SYNC_REVOKE, abi.encode(++xChainPayloadCounter, role_, superRegistryAddressId_)

```

```solidity
File: settings/SuperRegistry.sol

4: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

4: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

5: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

5: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

6: import { QuorumManager } from "../crosschain-data/utils/QuorumManager.sol";

6: import { QuorumManager } from "../crosschain-data/utils/QuorumManager.sol";

6: import { QuorumManager } from "../crosschain-data/utils/QuorumManager.sol";

6: import { QuorumManager } from "../crosschain-data/utils/QuorumManager.sol";

7: import { Error } from "../libraries/Error.sol";

7: import { Error } from "../libraries/Error.sol";

274:         for (uint256 i; i < len; ++i) {

274:         for (uint256 i; i < len; ++i) {

303:         for (uint256 i; i < len; ++i) {

303:         for (uint256 i; i < len; ++i) {

330:         for (uint256 i; i < len; ++i) {

330:         for (uint256 i; i < len; ++i) {

```

```solidity
File: types/DataTypes.sol

50:     LiqRequest[] liqRequests; // if length = 1; amount = sum(amounts) | else  amounts must match the amounts being sent

50:     LiqRequest[] liqRequests; // if length = 1; amount = sum(amounts) | else  amounts must match the amounts being sent

53:     bool[] retain4626s; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead

53:     bool[] retain4626s; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead

55:     bytes extraFormData; // extraFormData

55:     bytes extraFormData; // extraFormData

64:     LiqRequest liqRequest; // if length = 1; amount = sum(amounts)| else  amounts must match the amounts being sent

64:     LiqRequest liqRequest; // if length = 1; amount = sum(amounts)| else  amounts must match the amounts being sent

67:     bool retain4626; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead

67:     bool retain4626; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead

69:     bytes extraFormData; // extraFormData

69:     bytes extraFormData; // extraFormData

166:     uint256 txInfo; // tight packing of  TransactionType txType,  CallbackType flag  if multi/single vault, registry id,

166:     uint256 txInfo; // tight packing of  TransactionType txType,  CallbackType flag  if multi/single vault, registry id,

166:     uint256 txInfo; // tight packing of  TransactionType txType,  CallbackType flag  if multi/single vault, registry id,

168:     bytes params; // decoding txInfo will point to the right datatype of params. Refer PayloadHelper.sol

168:     bytes params; // decoding txInfo will point to the right datatype of params. Refer PayloadHelper.sol

```

```solidity
File: vendor/dragonfly-xyz/IPermit2.sol

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

4: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

```

```solidity
File: vendor/hyperlane/IMailbox.sol

57:         NULL, // used with relayer carrying no metadata

57:         NULL, // used with relayer carrying no metadata

```

```solidity
File: vendor/hyperlane/StandardHookMetadata.sol

21:         if (_metadata.length < VARIANT_OFFSET + 2) return 0;

22:         return uint16(bytes2(_metadata[VARIANT_OFFSET:VARIANT_OFFSET + 2]));

32:         if (_metadata.length < MSG_VALUE_OFFSET + 32) return _default;

33:         return uint256(bytes32(_metadata[MSG_VALUE_OFFSET:MSG_VALUE_OFFSET + 32]));

43:         if (_metadata.length < GAS_LIMIT_OFFSET + 32) return _default;

44:         return uint256(bytes32(_metadata[GAS_LIMIT_OFFSET:GAS_LIMIT_OFFSET + 32]));

54:         if (_metadata.length < REFUND_ADDRESS_OFFSET + 20) return _default;

55:         return address(bytes20(_metadata[REFUND_ADDRESS_OFFSET:REFUND_ADDRESS_OFFSET + 20]));

```

```solidity
File: vendor/layerzero/ILayerZeroEndpoint.sol

4: import "./ILayerZeroUserApplicationConfig.sol";

```

```solidity
File: vendor/lifi/ILiFi.sol

18:         bool hasDestinationCall; // is there a destination call? we should disable this

18:         bool hasDestinationCall; // is there a destination call? we should disable this

```

```solidity
File: vendor/lifi/LiFiTxDataExtractor.sol

4: import { ILiFi } from "src/vendor/lifi/ILiFi.sol";

4: import { ILiFi } from "src/vendor/lifi/ILiFi.sol";

4: import { ILiFi } from "src/vendor/lifi/ILiFi.sol";

5: import { LibSwap } from "src/vendor/lifi/LibSwap.sol";

5: import { LibSwap } from "src/vendor/lifi/LibSwap.sol";

5: import { LibSwap } from "src/vendor/lifi/LibSwap.sol";

6: import { StandardizedCallFacet } from "./StandardizedCallFacet.sol";

27:             bridgeData = abi.decode(_slice(unwrappedData, 4, unwrappedData.length - 4), (ILiFi.BridgeData));

42:                 abi.decode(_slice(unwrappedData, 4, unwrappedData.length - 4), (ILiFi.BridgeData, LibSwap.SwapData[]));

50:         if (_length + 31 < _length) revert SliceOverflow();

51:         if (_bytes.length < _start + _length) revert SliceOutOfBounds();

```

### <a name="GAS-5"></a>[GAS-5] Don't initialize variables with default value

*Instances (3)*:
```solidity
File: crosschain-data/utils/PayloadHelper.sol

366:         for (uint256 i = 0; i < len; ++i) {

```

```solidity
File: libraries/DataLib.sol

67:         for (uint256 i = 0; i < len; ++i) {

```

```solidity
File: vendor/hyperlane/StandardHookMetadata.sol

7:     uint8 private constant VARIANT_OFFSET = 0;

```

### <a name="GAS-6"></a>[GAS-6] Functions guaranteed to revert when called by normal users can be marked `payable`
If a function modifier such as `onlyOwner` is used, the function will revert if a normal user tries to pay the function. Marking the function as `payable` will lower the gas cost for legitimate callers because the compiler will not include checks for whether a payment was provided.

*Instances (37)*:
```solidity
File: EmergencyQueue.sol

104:     function executeQueuedWithdrawal(uint256 id_) external override onlyEmergencyAdmin {

108:     function batchExecuteQueuedWithdrawal(uint256[] calldata ids_) external override onlyEmergencyAdmin {

```

```solidity
File: SuperPositions.sol

141:     function updateTxHistory(uint256 payloadId_, uint256 txInfo_) external override onlyRouter {

146:     function mintSingle(address srcSender_, uint256 id_, uint256 amount_) external override onlyMinter(id_) {

164:     function burnSingle(address srcSender_, uint256 id_, uint256 amount_) external override onlyRouter {

290:     function setDynamicURI(string memory dynamicURI_, bool freeze_) external override onlyProtocolAdmin {

```

```solidity
File: crosschain-data/BaseStateRegistry.sol

111:     function receivePayload(uint64 srcChainId_, bytes memory message_) external override onlyValidAmbImplementation {

```

```solidity
File: crosschain-data/BroadcastRegistry.sol

121:     function processPayload(uint256 payloadId) external override onlyProcessor {

```

```solidity
File: crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

87:     function setHyperlaneConfig(IMailbox mailbox_, IInterchainGasPaymaster igp_) external onlyProtocolAdmin {

155:     function setChainId(uint64 superChainId_, uint32 ambChainId_) external onlyProtocolAdmin {

182:     function setReceiver(uint32 domain_, address authorizedImpl_) external onlyProtocolAdmin {

195:     function handle(uint32 origin_, bytes32 sender_, bytes calldata body_) external override onlyMailbox {

```

```solidity
File: crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

96:     function setLzEndpoint(address endpoint_) external onlyProtocolAdmin {

134:     function setSendVersion(uint16 version_) external override onlyProtocolAdmin {

139:     function setReceiveVersion(uint16 version_) external override onlyProtocolAdmin {

144:     function forceResumeReceive(uint16 srcChainId_, bytes calldata srcAddress_) external override onlyEmergencyAdmin {

149:     function setTrustedRemote(uint16 srcChainId_, bytes calldata srcAddress_) external onlyProtocolAdmin {

211:     function setChainId(uint64 superChainId_, uint16 ambChainId_) external onlyProtocolAdmin {

```

```solidity
File: crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

86:     function setWormholeRelayer(address relayer_) external onlyProtocolAdmin {

208:     function setChainId(uint64 superChainId_, uint16 ambChainId_) external onlyProtocolAdmin {

235:     function setReceiver(uint16 chainId_, address authorizedImpl_) external onlyProtocolAdmin {

```

```solidity
File: crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

96:     function setWormholeCore(address wormhole_) external onlyProtocolAdmin {

106:     function setRelayer(address relayer_) external onlyProtocolAdmin {

114:     function setFinality(uint8 finality_) external onlyProtocolAdmin {

181:     function receiveMessage(bytes memory encodedMessage_) public onlyWormholeVAARelayer {

217:     function setChainId(uint64 superChainId_, uint16 ambChainId_) external onlyProtocolAdmin {

244:     function setReceiver(uint16 chainId_, address authorizedImpl_) external onlyProtocolAdmin {

```

```solidity
File: payments/PayMaster.sol

59:     function withdrawTo(bytes32 superRegistryId_, uint256 nativeAmount_) external override onlyPaymentAdmin {

83:     function treatAMB(uint8 ambId_, uint256 nativeValue_, bytes memory data_) external override onlyPaymentAdmin {

```

```solidity
File: settings/SuperRBAC.sol

144:     function setSuperRegistry(address superRegistry_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {

153:     function setRoleAdmin(bytes32 role_, bytes32 adminRole_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {

184:     function stateSyncBroadcast(bytes memory data_) external override onlyBroadcastRegistry {

```

```solidity
File: settings/SuperRegistry.sol

210:     function setDelay(uint256 delay_) external override onlyProtocolAdmin {

222:     function setPermit2(address permit2_) external override onlyProtocolAdmin {

232:     function setVaultLimitPerTx(uint64 chainId_, uint256 vaultLimit_) external override onlyProtocolAdmin {

242:     function setAddress(bytes32 id_, address newAddress_, uint64 chainId_) external override onlyProtocolAdmin {

345:     function setRequiredMessagingQuorum(uint64 srcChainId_, uint256 quorum_) external override onlyProtocolAdmin {

```

### <a name="GAS-7"></a>[GAS-7] `++i` costs less gas than `i++`, especially when it's used in `for`-loops (`--i`/`i--` too)
*Saves 5 gas per loop*

*Instances (1)*:
```solidity
File: settings/SuperRBAC.sol

177:                 "SUPER_RBAC", SYNC_REVOKE, abi.encode(++xChainPayloadCounter, role_, superRegistryAddressId_)

```

### <a name="GAS-8"></a>[GAS-8] Using `private` rather than `public` for constants, saves gas
If needed, the values can be read from the verified contract source code, or if there are multiple values there can be a single getter function that [returns a tuple](https://github.com/code-423n4/2022-08-frax/blob/90f55a9ce4e25bceed3a74290b854341d8de6afa/src/contracts/FraxlendPair.sol#L156-L178) of the values of all currently-public constants. Saves **3406-3606 gas** in deployment gas due to the compiler not having to create non-payable getter functions for deployment calldata, not having to store the bytes of the value outside of where it's used, and not adding another entry to the method ID table

*Instances (38)*:
```solidity
File: BaseRouter.sol

24:     uint8 public constant STATE_REGISTRY_TYPE = 1;

```

```solidity
File: settings/SuperRBAC.sol

19:     bytes32 public constant SYNC_REVOKE = keccak256("SYNC_REVOKE");

23:     bytes32 public constant override PROTOCOL_ADMIN_ROLE = keccak256("PROTOCOL_ADMIN_ROLE");

27:     bytes32 public constant override EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN_ROLE");

31:     bytes32 public constant override PAYMENT_ADMIN_ROLE = keccak256("PAYMENT_ADMIN_ROLE");

36:     bytes32 public constant override BROADCASTER_ROLE = keccak256("BROADCASTER_ROLE");

40:     bytes32 public constant override CORE_STATE_REGISTRY_PROCESSOR_ROLE =

45:     bytes32 public constant override TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE =

50:     bytes32 public constant override BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE =

55:     bytes32 public constant override CORE_STATE_REGISTRY_UPDATER_ROLE = keccak256("CORE_STATE_REGISTRY_UPDATER_ROLE");

59:     bytes32 public constant override CORE_STATE_REGISTRY_RESCUER_ROLE = keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE");

63:     bytes32 public constant override CORE_STATE_REGISTRY_DISPUTER_ROLE = keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE");

67:     bytes32 public constant override DST_SWAPPER_ROLE = keccak256("DST_SWAPPER_ROLE");

72:     bytes32 public constant override WORMHOLE_VAA_RELAYER_ROLE = keccak256("WORMHOLE_VAA_RELAYER_ROLE");

```

```solidity
File: settings/SuperRegistry.sol

17:     uint256 public constant MIN_DELAY = 1 hours;

18:     uint256 public constant MAX_DELAY = 24 hours;

23:     bytes32 public constant override SUPERFORM_ROUTER = keccak256("SUPERFORM_ROUTER");

26:     bytes32 public constant override SUPERFORM_FACTORY = keccak256("SUPERFORM_FACTORY");

29:     bytes32 public constant override SUPER_TRANSMUTER = keccak256("SUPER_TRANSMUTER");

32:     bytes32 public constant override PAYMASTER = keccak256("PAYMASTER");

36:     bytes32 public constant override PAYMENT_HELPER = keccak256("PAYMENT_HELPER");

39:     bytes32 public constant override CORE_STATE_REGISTRY = keccak256("CORE_STATE_REGISTRY");

42:     bytes32 public constant override TIMELOCK_STATE_REGISTRY = keccak256("TIMELOCK_STATE_REGISTRY");

45:     bytes32 public constant override BROADCAST_REGISTRY = keccak256("BROADCAST_REGISTRY");

48:     bytes32 public constant override SUPER_POSITIONS = keccak256("SUPER_POSITIONS");

51:     bytes32 public constant override SUPER_RBAC = keccak256("SUPER_RBAC");

54:     bytes32 public constant override PAYLOAD_HELPER = keccak256("PAYLOAD_HELPER");

57:     bytes32 public constant override DST_SWAPPER = keccak256("DST_SWAPPER");

60:     bytes32 public constant override EMERGENCY_QUEUE = keccak256("EMERGENCY_QUEUE");

63:     bytes32 public constant override PAYMENT_ADMIN = keccak256("PAYMENT_ADMIN");

64:     bytes32 public constant override CORE_REGISTRY_PROCESSOR = keccak256("CORE_REGISTRY_PROCESSOR");

65:     bytes32 public constant override BROADCAST_REGISTRY_PROCESSOR = keccak256("BROADCAST_REGISTRY_PROCESSOR");

66:     bytes32 public constant override TIMELOCK_REGISTRY_PROCESSOR = keccak256("TIMELOCK_REGISTRY_PROCESSOR");

67:     bytes32 public constant override CORE_REGISTRY_UPDATER = keccak256("CORE_REGISTRY_UPDATER");

68:     bytes32 public constant override CORE_REGISTRY_RESCUER = keccak256("CORE_REGISTRY_RESCUER");

69:     bytes32 public constant override CORE_REGISTRY_DISPUTER = keccak256("CORE_REGISTRY_DISPUTER");

70:     bytes32 public constant override DST_SWAPPER_PROCESSOR = keccak256("DST_SWAPPER_PROCESSOR");

```

```solidity
File: vendor/hyperlane/StandardHookMetadata.sol

13:     uint16 public constant VARIANT = 1;

```

### <a name="GAS-9"></a>[GAS-9] Use != 0 instead of > 0 for unsigned integer comparison

*Instances (14)*:
```solidity
File: BaseRouterImplementation.sol

670:             if (v.dstAmounts[i] > 0 && vaultData_.retain4626s[i]) {

867:         if (residualPayment > 0) {

1010:             if (v.permit2dataLen > 0) {

```

```solidity
File: crosschain-data/BaseStateRegistry.sol

177:                 if (i - 1 > 0 && ambIds_[i] <= ambIds_[i - 1]) {

```

```solidity
File: forms/ERC4626FormImplementation.sol

417:         if (dust > 0) {

```

```solidity
File: vendor/hyperlane/IInterchainGasPaymaster.sol

2: pragma solidity >=0.6.11;

```

```solidity
File: vendor/hyperlane/IMailbox.sol

2: pragma solidity >=0.8.0;

```

```solidity
File: vendor/hyperlane/IMessageRecipient.sol

2: pragma solidity >=0.6.11;

```

```solidity
File: vendor/hyperlane/StandardHookMetadata.sol

2: pragma solidity >=0.8.0;

```

```solidity
File: vendor/layerzero/ILayerZeroEndpoint.sol

2: pragma solidity >=0.5.0;

```

```solidity
File: vendor/layerzero/ILayerZeroReceiver.sol

2: pragma solidity >=0.5.0;

```

```solidity
File: vendor/layerzero/ILayerZeroUserApplicationConfig.sol

2: pragma solidity >=0.5.0;

```

```solidity
File: vendor/socket/ISocketOneInchImpl.sol

2: pragma solidity >=0.8.4;

```

```solidity
File: vendor/socket/ISocketRegistry.sol

2: pragma solidity >=0.8.4;

```

### <a name="GAS-10"></a>[GAS-10] `internal` functions not called by the contract should be removed
If the functions are required by an interface, the contract should inherit from that interface and use the `override` keyword

*Instances (5)*:
```solidity
File: vendor/hyperlane/StandardHookMetadata.sol

20:     function variant(bytes calldata _metadata) internal pure returns (uint16) {

31:     function msgValue(bytes calldata _metadata, uint256 _default) internal pure returns (uint256) {

42:     function gasLimit(bytes calldata _metadata, uint256 _default) internal pure returns (uint256) {

53:     function refundAddress(bytes calldata _metadata, address _default) internal pure returns (address) {

63:     function getCustomMetadata(bytes calldata _metadata) internal pure returns (bytes calldata) {

```


## Non Critical Issues


| |Issue|Instances|
|-|:-|:-:|
| [NC-1](#NC-1) | Event is missing `indexed` fields | 3 |
| [NC-2](#NC-2) | Constants should be defined rather than using magic numbers | 1 |
### <a name="NC-1"></a>[NC-1] Event is missing `indexed` fields
Index event fields make the field more quickly accessible to off-chain tools that parse events. However, note that each index field costs extra gas during emission, so it's not necessarily best to index the maximum allowed per event (three fields). Each event should use three indexed fields if there are three or more fields, and gas usage is not particularly of concern for the events in question. If there are fewer than three fields, all of the fields should be indexed.

*Instances (3)*:
```solidity
File: vendor/hyperlane/IInterchainGasPaymaster.sol

11:     event GasPayment(bytes32 indexed messageId, uint256 gasAmount, uint256 payment);

```

```solidity
File: vendor/wormhole/IWormhole.sol

70:     event LogMessagePublished(

```

```solidity
File: vendor/wormhole/IWormholeRelayer.sol

30:     event SendEvent(uint64 indexed sequence, uint256 deliveryQuote, uint256 paymentForExtraReceiverValue);

```

### <a name="NC-2"></a>[NC-2] Constants should be defined rather than using magic numbers

*Instances (1)*:
```solidity
File: vendor/lifi/LiFiTxDataExtractor.sol

92:                 mstore(0x40, and(add(mc, 31), not(31)))

```


## Low Issues


| |Issue|Instances|
|-|:-|:-:|
| [L-1](#L-1) |  `abi.encodePacked()` should not be used with dynamic types when passing the result to a hash function such as `keccak256()` | 1 |
| [L-2](#L-2) | Empty Function Body - Consider commenting why | 16 |
| [L-3](#L-3) | Initializers could be front-run | 4 |
| [L-4](#L-4) | Unspecific compiler version pragma | 9 |
### <a name="L-1"></a>[L-1]  `abi.encodePacked()` should not be used with dynamic types when passing the result to a hash function such as `keccak256()`
Use `abi.encode()` instead which will pad items to 32 bytes, which will [prevent hash collisions](https://docs.soliditylang.org/en/v0.8.13/abi-spec.html#non-standard-packed-mode) (e.g. `abi.encodePacked(0x123,0x456)` => `0x123456` => `abi.encodePacked(0x1,0x23456)`, but `abi.encode(0x123,0x456)` => `0x0...1230...456`). "Unless there is a compelling reason, `abi.encode` should be preferred". If there is only one argument to `abi.encodePacked()` it can often be cast to `bytes()` or `bytes32()` [instead](https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity#answer-82739).
If all arguments are strings and or bytes, `bytes.concat()` should be used instead

*Instances (1)*:
```solidity
File: SuperformFactory.sol

218:             tFormImplementation.cloneDeterministic(keccak256(abi.encodePacked(uint256(CHAIN_ID), superformCounter)));

```

### <a name="L-2"></a>[L-2] Empty Function Body - Consider commenting why

*Instances (16)*:
```solidity
File: BaseForm.sol

159:     receive() external payable { }

```

```solidity
File: BaseRouter.sol

46:     receive() external payable { }

```

```solidity
File: BaseRouterImplementation.sol

82:     constructor(address superRegistry_) BaseRouter(superRegistry_) { }

```

```solidity
File: SuperformRouter.sol

18:     constructor(address superRegistry_) BaseRouterImplementation(superRegistry_) { }

```

```solidity
File: crosschain-data/extensions/TimelockStateRegistry.sol

85:     constructor(ISuperRegistry superRegistry_) BaseStateRegistry(superRegistry_) { }

178:         try form.withdrawAfterCoolDown(p) { }

```

```solidity
File: crosschain-liquidity/DstSwapper.sol

129:     receive() external payable { }

```

```solidity
File: crosschain-liquidity/lifi/LiFiValidator.sol

19:     constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

```

```solidity
File: crosschain-liquidity/socket/SocketOneInchValidator.sol

16:     constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

```

```solidity
File: crosschain-liquidity/socket/SocketValidator.sol

15:     constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

```

```solidity
File: forms/ERC4626Form.sol

21:     constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_, stateRegistryId) { }

```

```solidity
File: forms/ERC4626KYCDaoForm.sol

24:     constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_, stateRegistryId) { }

```

```solidity
File: forms/ERC4626TimelockForm.sol

56:     constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_, stateRegistryId) { }

```

```solidity
File: payments/PayMaster.sol

56:     receive() external payable { }

```

```solidity
File: vendor/lifi/StandardizedCallFacet.sol

13:     function standardizedCall(bytes memory callData) external payable { }

```

```solidity
File: vendor/wormhole/IWormholeRelayer.sol

550: interface IWormholeRelayer is IWormholeRelayerDelivery, IWormholeRelayerSend { }

```

### <a name="L-3"></a>[L-3] Initializers could be front-run
Initializers could be front-run, allowing an attacker to either set their own values, take ownership of the contract, and in the best case forcing a re-deployment

*Instances (4)*:
```solidity
File: BaseForm.sol

164:     function initialize(address superRegistry_, address vault_, address asset_) external initializer {

164:     function initialize(address superRegistry_, address vault_, address asset_) external initializer {

```

```solidity
File: SuperformFactory.sol

221:         BaseForm(payable(superform_)).initialize(address(superRegistry), vault_, address(IERC4626(vault_).asset()));

```

```solidity
File: vendor/wormhole/IWormhole.sol

85:     function initialize() external;

```

### <a name="L-4"></a>[L-4] Unspecific compiler version pragma

*Instances (9)*:
```solidity
File: vendor/hyperlane/IInterchainGasPaymaster.sol

2: pragma solidity >=0.6.11;

```

```solidity
File: vendor/hyperlane/IMailbox.sol

2: pragma solidity >=0.8.0;

```

```solidity
File: vendor/hyperlane/IMessageRecipient.sol

2: pragma solidity >=0.6.11;

```

```solidity
File: vendor/hyperlane/StandardHookMetadata.sol

2: pragma solidity >=0.8.0;

```

```solidity
File: vendor/layerzero/ILayerZeroEndpoint.sol

2: pragma solidity >=0.5.0;

```

```solidity
File: vendor/layerzero/ILayerZeroReceiver.sol

2: pragma solidity >=0.5.0;

```

```solidity
File: vendor/layerzero/ILayerZeroUserApplicationConfig.sol

2: pragma solidity >=0.5.0;

```

```solidity
File: vendor/socket/ISocketOneInchImpl.sol

2: pragma solidity >=0.8.4;

```

```solidity
File: vendor/socket/ISocketRegistry.sol

2: pragma solidity >=0.8.4;

```


## Medium Issues


| |Issue|Instances|
|-|:-|:-:|
| [M-1](#M-1) | Centralization Risk for trusted owners | 7 |
### <a name="M-1"></a>[M-1] Centralization Risk for trusted owners

#### Impact:
Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

*Instances (7)*:
```solidity
File: interfaces/ISuperRBAC.sol

4: import { IAccessControl } from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

9: interface ISuperRBAC is IAccessControl {

```

```solidity
File: settings/SuperRBAC.sol

4: import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol";

14: contract SuperRBAC is ISuperRBAC, AccessControlEnumerable {

144:     function setSuperRegistry(address superRegistry_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {

153:     function setRoleAdmin(bytes32 role_, bytes32 adminRole_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {

166:         onlyRole(PROTOCOL_ADMIN_ROLE)

```