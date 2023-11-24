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

160:             superformIdsLen = req_.superformsData[i].superformIds.length;

264:         uint256 superformIdsLen = req_.superformsData.superformIds.length;

384:         uint256 len = req_.superformData.superformIds.length;

```

### <a name="GAS-2"></a>[GAS-2] For Operations that will not overflow, you could use unchecked

*Instances (114)*:
```solidity
File: PaymentHelper.sol

4: import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";

4: import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";

4: import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";

5: import { IPaymentHelper } from "../interfaces/IPaymentHelper.sol";

5: import { IPaymentHelper } from "../interfaces/IPaymentHelper.sol";

6: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

6: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

7: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

7: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

8: import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";

8: import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";

9: import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";

9: import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";

10: import { Error } from "../libraries/Error.sol";

10: import { Error } from "../libraries/Error.sol";

11: import { DataLib } from "../libraries/DataLib.sol";

11: import { DataLib } from "../libraries/DataLib.sol";

12: import { ProofLib } from "../libraries/ProofLib.sol";

12: import { ProofLib } from "../libraries/ProofLib.sol";

13: import { ArrayCastLib } from "../libraries/ArrayCastLib.sol";

13: import { ArrayCastLib } from "../libraries/ArrayCastLib.sol";

14: import "../types/DataTypes.sol";

14: import "../types/DataTypes.sol";

152:         for (uint256 i; i < len; ++i) {

152:         for (uint256 i; i < len; ++i) {

162:             srcAmount += ambFees;

166:                 totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], superformIdsLen);

170:                 srcAmount += _estimateAckProcessingCost(superformIdsLen);

173:                 liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequests);

176:                 totalDstGas += _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].hasDstSwaps);

181:             totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainIds[i], superformIdsLen);

185:                 for (uint256 j; j < superformIdsLen; ++j) {

185:                 for (uint256 j; j < superformIdsLen; ++j) {

188:                         totalDstGas += timelockCost[req_.dstChainIds[i]];

194:             dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);

197:         totalAmount = srcAmount + dstAmount + liqAmount;

197:         totalAmount = srcAmount + dstAmount + liqAmount;

211:         for (uint256 i; i < len; ++i) {

211:         for (uint256 i; i < len; ++i) {

219:             srcAmount += ambFees;

223:                 totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], 1);

226:                 srcAmount += _estimateAckProcessingCost(1);

229:                 liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequest.castLiqRequestToArray());

232:                 totalDstGas +=

238:             totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainIds[i], 1);

243:                 totalDstGas += timelockCost[req_.dstChainIds[i]];

247:             dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);

250:         totalAmount = srcAmount + dstAmount + liqAmount;

250:         totalAmount = srcAmount + dstAmount + liqAmount;

270:         srcAmount += ambFees;

273:         if (isDeposit_) totalDstGas += _estimateUpdateCost(req_.dstChainId, superformIdsLen);

277:         totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainId, superformIdsLen);

280:         if (isDeposit_) srcAmount += _estimateAckProcessingCost(superformIdsLen);

283:         if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformsData.liqRequests);

286:         if (isDeposit_) totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superformsData.hasDstSwaps);

290:             for (uint256 i; i < superformIdsLen; ++i) {

290:             for (uint256 i; i < superformIdsLen; ++i) {

294:                     totalDstGas += timelockCost[CHAIN_ID];

300:         dstAmount += _convertToNativeFee(req_.dstChainId, totalDstGas);

302:         totalAmount = srcAmount + dstAmount + liqAmount;

302:         totalAmount = srcAmount + dstAmount + liqAmount;

320:         srcAmount += ambFees;

323:         if (isDeposit_) totalDstGas += _estimateUpdateCost(req_.dstChainId, 1);

327:         totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainId, 1);

330:         if (isDeposit_) srcAmount += _estimateAckProcessingCost(1);

333:         if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformData.liqRequest.castLiqRequestToArray());

337:             totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superformData.hasDstSwap.castBoolToArray());

343:             totalDstGas += timelockCost[CHAIN_ID];

347:         dstAmount += _convertToNativeFee(req_.dstChainId, totalDstGas);

349:         totalAmount = srcAmount + dstAmount + liqAmount;

349:         totalAmount = srcAmount + dstAmount + liqAmount;

365:             srcAmount += timelockCost[CHAIN_ID] * _getGasPrice(CHAIN_ID);

365:             srcAmount += timelockCost[CHAIN_ID] * _getGasPrice(CHAIN_ID);

368:         if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformData.liqRequest.castLiqRequestToArray());

371:         totalAmount = liqAmount + srcAmount;

385:         for (uint256 i; i < len; ++i) {

385:         for (uint256 i; i < len; ++i) {

387:             uint256 timelockPrice = timelockCost[uint64(block.chainid)] * _getGasPrice(uint64(block.chainid));

390:                 srcAmount += timelockPrice;

394:         if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformData.liqRequests);

397:         totalAmount = liqAmount + srcAmount;

415:         for (uint256 i; i < len; ++i) {

415:         for (uint256 i; i < len; ++i) {

422:             totalFees += fees[i];

559:         uint256 totalDstGasReqInWei = abi.encode(ambIdEncodedMessage).length * gasReqPerByte;

564:         uint256 totalDstGasReqInWeiForProof = abi.encode(decodedMessage).length * gasReqPerByte;

568:         for (uint256 i; i < len; ++i) {

568:         for (uint256 i; i < len; ++i) {

641:         for (uint256 i; i < len; ++i) {

641:         for (uint256 i; i < len; ++i) {

648:             totalFees += tempFee;

674:         for (uint256 i; i < len; ++i) {

674:         for (uint256 i; i < len; ++i) {

681:             totalFees += tempFee;

689:         for (uint256 i; i < len; ++i) {

689:         for (uint256 i; i < len; ++i) {

690:             liqAmount += req_[i].nativeAmount;

710:         for (uint256 i; i < len; ++i) {

710:         for (uint256 i; i < len; ++i) {

713:                 ++totalSwaps;

713:                 ++totalSwaps;

721:         return totalSwaps * swapGasUsed[dstChainId_];

726:         return vaultsCount_ * updateGasUsed[dstChainId_];

741:         return executionGasPerVault * vaultsCount_;

746:         uint256 gasCost = vaultsCount_ * ackGasCost[CHAIN_ID];

748:         return gasCost * _getGasPrice(CHAIN_ID);

802:         uint256 dstNativeFee = dstGas_ * _getGasPrice(dstChainId_);

810:         uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

810:         uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

810:         uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

810:         uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

818:         nativeFee = (dstUsdValue) / _getNativeTokenPrice(CHAIN_ID);

825:         ++nextPayloadId;

825:         ++nextPayloadId;

```

### <a name="GAS-3"></a>[GAS-3] Using `private` rather than `public` for constants, saves gas
If needed, the values can be read from the verified contract source code, or if there are multiple values there can be a single getter function that [returns a tuple](https://github.com/code-423n4/2022-08-frax/blob/90f55a9ce4e25bceed3a74290b854341d8de6afa/src/contracts/FraxlendPair.sol#L156-L178) of the values of all currently-public constants. Saves **3406-3606 gas** in deployment gas due to the compiler not having to create non-payable getter functions for deployment calldata, not having to store the bytes of the value outside of where it's used, and not adding another entry to the method ID table

*Instances (1)*:
```solidity
File: PaymentHelper.sol

37:     uint32 public constant TIMELOCK_FORM_ID = 2;

```

