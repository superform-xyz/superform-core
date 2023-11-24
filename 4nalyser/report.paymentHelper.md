# Report


## Gas Optimizations


| |Issue|Instances|
|-|:-|:-:|
| [GAS-1](#GAS-1) | Cache array length outside of loop | 3 |
| [GAS-2](#GAS-2) | For Operations that will not overflow, you could use unchecked | 114 |
| [GAS-3](#GAS-3) | Using `private` rather than `public` for constants, saves gas | 1 |
### <a name="GAS-1"></a>[GAS-1] Cache array length outside of loop
If not cached, the solidity compiler will always read the length of the array during each iteration. That is, if it is a storage array, this is an extra sload operation (100 additional extra gas for each iteration except for the first) and if it is a memory array, this is an extra mload operation (3 additional gas for each iteration except for the first).

*Instances (3)*:
```solidity
File: PaymentHelper.sol

153:             superformIdsLen = req_.superformsData[i].superformIds.length;

251:         uint256 superformIdsLen = req_.superformsData.superformIds.length;

362:         uint256 len = req_.superformData.superformIds.length;

```

### <a name="GAS-2"></a>[GAS-2] For Operations that will not overflow, you could use unchecked

*Instances (114)*:
```solidity
File: PaymentHelper.sol

4: import {AggregatorV3Interface} from "../vendor/chainlink/AggregatorV3Interface.sol";

4: import {AggregatorV3Interface} from "../vendor/chainlink/AggregatorV3Interface.sol";

4: import {AggregatorV3Interface} from "../vendor/chainlink/AggregatorV3Interface.sol";

5: import {IPaymentHelper} from "../interfaces/IPaymentHelper.sol";

5: import {IPaymentHelper} from "../interfaces/IPaymentHelper.sol";

6: import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";

6: import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";

7: import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";

7: import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";

8: import {IBaseStateRegistry} from "../interfaces/IBaseStateRegistry.sol";

8: import {IBaseStateRegistry} from "../interfaces/IBaseStateRegistry.sol";

9: import {IAmbImplementation} from "../interfaces/IAmbImplementation.sol";

9: import {IAmbImplementation} from "../interfaces/IAmbImplementation.sol";

10: import {Error} from "../libraries/Error.sol";

10: import {Error} from "../libraries/Error.sol";

11: import {DataLib} from "../libraries/DataLib.sol";

11: import {DataLib} from "../libraries/DataLib.sol";

12: import {ProofLib} from "../libraries/ProofLib.sol";

12: import {ProofLib} from "../libraries/ProofLib.sol";

13: import {ArrayCastLib} from "../libraries/ArrayCastLib.sol";

13: import {ArrayCastLib} from "../libraries/ArrayCastLib.sol";

14: import "../types/DataTypes.sol";

14: import "../types/DataTypes.sol";

145:         for (uint256 i; i < len; ++i) {

145:         for (uint256 i; i < len; ++i) {

155:             srcAmount += ambFees;

159:                 totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], superformIdsLen);

163:                 srcAmount += _estimateAckProcessingCost(superformIdsLen);

166:                 liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequests);

169:                 totalDstGas += _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].hasDstSwaps);

174:             totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainIds[i], superformIdsLen);

178:                 for (uint256 j; j < superformIdsLen; ++j) {

178:                 for (uint256 j; j < superformIdsLen; ++j) {

181:                         totalDstGas += timelockCost[req_.dstChainIds[i]];

187:             dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);

190:         totalAmount = srcAmount + dstAmount + liqAmount;

190:         totalAmount = srcAmount + dstAmount + liqAmount;

201:         for (uint256 i; i < len; ++i) {

201:         for (uint256 i; i < len; ++i) {

209:             srcAmount += ambFees;

213:                 totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], 1);

216:                 srcAmount += _estimateAckProcessingCost(1);

219:                 liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequest.castLiqRequestToArray());

222:                 totalDstGas +=

228:             totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainIds[i], 1);

233:                 totalDstGas += timelockCost[req_.dstChainIds[i]];

237:             dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);

240:         totalAmount = srcAmount + dstAmount + liqAmount;

240:         totalAmount = srcAmount + dstAmount + liqAmount;

257:         srcAmount += ambFees;

260:         if (isDeposit_) totalDstGas += _estimateUpdateCost(req_.dstChainId, superformIdsLen);

264:         totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainId, superformIdsLen);

267:         if (isDeposit_) srcAmount += _estimateAckProcessingCost(superformIdsLen);

270:         if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformsData.liqRequests);

273:         if (isDeposit_) totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superformsData.hasDstSwaps);

277:             for (uint256 i; i < superformIdsLen; ++i) {

277:             for (uint256 i; i < superformIdsLen; ++i) {

281:                     totalDstGas += timelockCost[CHAIN_ID];

287:         dstAmount += _convertToNativeFee(req_.dstChainId, totalDstGas);

289:         totalAmount = srcAmount + dstAmount + liqAmount;

289:         totalAmount = srcAmount + dstAmount + liqAmount;

304:         srcAmount += ambFees;

307:         if (isDeposit_) totalDstGas += _estimateUpdateCost(req_.dstChainId, 1);

311:         totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainId, 1);

314:         if (isDeposit_) srcAmount += _estimateAckProcessingCost(1);

317:         if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformData.liqRequest.castLiqRequestToArray());

321:             totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superformData.hasDstSwap.castBoolToArray());

327:             totalDstGas += timelockCost[CHAIN_ID];

331:         dstAmount += _convertToNativeFee(req_.dstChainId, totalDstGas);

333:         totalAmount = srcAmount + dstAmount + liqAmount;

333:         totalAmount = srcAmount + dstAmount + liqAmount;

346:             srcAmount += timelockCost[CHAIN_ID] * _getGasPrice(CHAIN_ID);

346:             srcAmount += timelockCost[CHAIN_ID] * _getGasPrice(CHAIN_ID);

349:         if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformData.liqRequest.castLiqRequestToArray());

352:         totalAmount = liqAmount + srcAmount;

363:         for (uint256 i; i < len; ++i) {

363:         for (uint256 i; i < len; ++i) {

365:             uint256 timelockPrice = timelockCost[uint64(block.chainid)] * _getGasPrice(uint64(block.chainid));

368:                 srcAmount += timelockPrice;

372:         if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformData.liqRequests);

375:         totalAmount = liqAmount + srcAmount;

389:         for (uint256 i; i < len; ++i) {

389:         for (uint256 i; i < len; ++i) {

396:             totalFees += fees[i];

519:         uint256 totalDstGasReqInWei = abi.encode(ambIdEncodedMessage).length * gasReqPerByte;

524:         uint256 totalDstGasReqInWeiForProof = abi.encode(decodedMessage).length * gasReqPerByte;

528:         for (uint256 i; i < len; ++i) {

528:         for (uint256 i; i < len; ++i) {

597:         for (uint256 i; i < len; ++i) {

597:         for (uint256 i; i < len; ++i) {

604:             totalFees += tempFee;

626:         for (uint256 i; i < len; ++i) {

626:         for (uint256 i; i < len; ++i) {

633:             totalFees += tempFee;

641:         for (uint256 i; i < len; ++i) {

641:         for (uint256 i; i < len; ++i) {

642:             liqAmount += req_[i].nativeAmount;

659:         for (uint256 i; i < len; ++i) {

659:         for (uint256 i; i < len; ++i) {

662:                 ++totalSwaps;

662:                 ++totalSwaps;

670:         return totalSwaps * swapGasUsed[dstChainId_];

675:         return vaultsCount_ * updateGasUsed[dstChainId_];

686:         return executionGasPerVault * vaultsCount_;

691:         uint256 gasCost = vaultsCount_ * ackGasCost[CHAIN_ID];

693:         return gasCost * _getGasPrice(CHAIN_ID);

747:         uint256 dstNativeFee = dstGas_ * _getGasPrice(dstChainId_);

755:         uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

755:         uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

755:         uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

755:         uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

763:         nativeFee = (dstUsdValue) / _getNativeTokenPrice(CHAIN_ID);

770:         ++nextPayloadId;

770:         ++nextPayloadId;

```

### <a name="GAS-3"></a>[GAS-3] Using `private` rather than `public` for constants, saves gas
If needed, the values can be read from the verified contract source code, or if there are multiple values there can be a single getter function that [returns a tuple](https://github.com/code-423n4/2022-08-frax/blob/90f55a9ce4e25bceed3a74290b854341d8de6afa/src/contracts/FraxlendPair.sol#L156-L178) of the values of all currently-public constants. Saves **3406-3606 gas** in deployment gas due to the compiler not having to create non-payable getter functions for deployment calldata, not having to store the bytes of the value outside of where it's used, and not adding another entry to the method ID table

*Instances (1)*:
```solidity
File: PaymentHelper.sol

37:     uint32 public constant TIMELOCK_FORM_ID = 2;

```

