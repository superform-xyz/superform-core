Summary
 - [arbitrary-send-eth](#arbitrary-send-eth) (4 results) (High)
 - [reentrancy-eth](#reentrancy-eth) (1 results) (High)
 - [locked-ether](#locked-ether) (1 results) (Medium)
 - [reentrancy-no-eth](#reentrancy-no-eth) (3 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (30 results) (Medium)
 - [unused-return](#unused-return) (74 results) (Medium)
 - [calls-loop](#calls-loop) (52 results) (Low)
 - [reentrancy-benign](#reentrancy-benign) (5 results) (Low)
 - [reentrancy-events](#reentrancy-events) (17 results) (Low)
 - [assembly](#assembly) (1 results) (Informational)
 - [costly-loop](#costly-loop) (4 results) (Informational)
 - [cyclomatic-complexity](#cyclomatic-complexity) (3 results) (Informational)
 - [dead-code](#dead-code) (7 results) (Informational)
 - [low-level-calls](#low-level-calls) (4 results) (Informational)
 - [similar-names](#similar-names) (72 results) (Informational)
 - [unused-state](#unused-state) (4 results) (Informational)
 - [var-read-using-this](#var-read-using-this) (3 results) (Optimization)
## arbitrary-send-eth
Impact: High
Confidence: Medium
 - [ ] ID-0
[WormholeSRImplementation.broadcastPayload(address,bytes,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L145-L179) sends eth to arbitrary user
	Dangerous calls:
	- [wormhole.publishMessage{value: msgFee}(0,message_,broadcastFinality)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L162-L167)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L145-L179


 - [ ] ID-1
[PayMaster.treatAMB(uint8,uint256,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L83-L89) sends eth to arbitrary user
	Dangerous calls:
	- [IAmbImplementation(superRegistry.getAmbAddress(ambId_)).retryPayload{value: nativeValue_}(data_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L88)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L83-L89


 - [ ] ID-2
[BroadcastRegistry._broadcastPayload(address,uint8,uint256,bytes,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/BroadcastRegistry.sol#L144-L156) sends eth to arbitrary user
	Dangerous calls:
	- [IBroadcastAmbImplementation(superRegistry.getAmbAddress(ambId_)).broadcastPayload{value: gasToPay_}(srcSender_,message_,extraData_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/BroadcastRegistry.sol#L153-L155)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/BroadcastRegistry.sol#L144-L156


 - [ ] ID-3
[PayMaster._withdrawNative(address,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L111-L119) sends eth to arbitrary user
	Dangerous calls:
	- [(success) = address(receiver_).call{value: amount_}()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L112)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L111-L119


## reentrancy-eth
Impact: High
Confidence: Medium
 - [ ] ID-4
Reentrancy in [TimelockStateRegistry.finalizePayload(uint256,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L119-L199):
	External calls:
	- [form.withdrawAfterCoolDown(p)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L178-L195)
	- [_dispatchAcknowledgement(p.srcChainId,_getDeliveryAMB(payloadId),_constructSingleReturnData(p.srcSender,p.data))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L184-L186)
		- [_getAMBImpl(ambIds_[0]).dispatchPayload{value: d.gasPerAMB[0]}(srcSender_,dstChainId_,abi.encode(AMBMessage(data.txInfo,abi.encode(ambIds_,data.params))),d.extraDataPerAMB[0])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/BaseStateRegistry.sol#L161-L166)
		- [_getAMBImpl(ambIds_[i]).dispatchPayload{value: d.gasPerAMB[i]}(srcSender_,dstChainId_,abi.encode(data),d.extraDataPerAMB[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/BaseStateRegistry.sol#L182-L184)
	- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).mintSingle(p.srcSender,p.data.superformId,p.data.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L191-L193)
	External calls sending eth:
	- [_dispatchAcknowledgement(p.srcChainId,_getDeliveryAMB(payloadId),_constructSingleReturnData(p.srcSender,p.data))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L184-L186)
		- [_getAMBImpl(ambIds_[0]).dispatchPayload{value: d.gasPerAMB[0]}(srcSender_,dstChainId_,abi.encode(AMBMessage(data.txInfo,abi.encode(ambIds_,data.params))),d.extraDataPerAMB[0])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/BaseStateRegistry.sol#L161-L166)
		- [_getAMBImpl(ambIds_[i]).dispatchPayload{value: d.gasPerAMB[i]}(srcSender_,dstChainId_,abi.encode(data),d.extraDataPerAMB[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/BaseStateRegistry.sol#L182-L184)
	State variables written after the call(s):
	- [delete timelockPayload[timeLockPayloadId_]](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L198)
	[TimelockStateRegistry.timelockPayload](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L39) can be used in cross function reentrancies:
	- [TimelockStateRegistry.finalizePayload(uint256,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L119-L199)
	- [TimelockStateRegistry.getTimelockPayload(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L92-L94)
	- [TimelockStateRegistry.receivePayload(uint8,address,uint64,uint256,InitSingleVaultData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L101-L116)
	- [TimelockStateRegistry.timelockPayload](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L39)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L119-L199


## locked-ether
Impact: Medium
Confidence: High
 - [ ] ID-5
Contract locking ether found:
	Contract [StandardizedCallFacet](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/lifi/StandardizedCallFacet.sol#L8-L14) has payable functions:
	 - [StandardizedCallFacet.standardizedCall(bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/lifi/StandardizedCallFacet.sol#L13)
	But does not have a function to withdraw the ether

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/lifi/StandardizedCallFacet.sol#L8-L14


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-6
Reentrancy in [CoreStateRegistry._multiDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L718-L808):
	External calls:
	- [underlying.safeIncreaseAllowance(superforms[i],multiVaultData.amounts[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L743)
	- [dstAmount = IBaseForm(superforms[i]).xChainDepositIntoVault(InitSingleVaultData({payloadId:multiVaultData.payloadId,superformId:multiVaultData.superformIds[i],amount:multiVaultData.amounts[i],maxSlippage:multiVaultData.maxSlippages[i],liqData:emptyRequest,hasDstSwap:false,retain4626:multiVaultData.retain4626s[i],receiverAddress:multiVaultData.receiverAddress,extraFormData:multiVaultData.extraFormData}),srcSender_,srcChainId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L747-L784)
	- [underlying.safeDecreaseAllowance(superforms[i],multiVaultData.amounts[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L771)
	State variables written after the call(s):
	- [failedDeposits[payloadId_].superformIds.push(multiVaultData.superformIds[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L777)
	[CoreStateRegistry.failedDeposits](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L46) can be used in cross function reentrancies:
	- [CoreStateRegistry._multiDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L718-L808)
	- [CoreStateRegistry._singleDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L846-L893)
	- [CoreStateRegistry._updateAmount(IDstSwapper,bool,uint256,uint256,uint256,uint256,uint256,uint256,PayloadState,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L489-L557)
	- [CoreStateRegistry.disputeRescueFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L246-L275)
	- [CoreStateRegistry.finalizeRescueFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L312)
	- [CoreStateRegistry.getFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L68-L76)
	- [CoreStateRegistry.proposeRescueFailedDeposits(uint256,uint256[])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L208-L243)
	- [failedDeposits[payloadId_].settlementToken.push(IBaseForm(superforms[i]).getVaultAsset())](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L782)
	[CoreStateRegistry.failedDeposits](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L46) can be used in cross function reentrancies:
	- [CoreStateRegistry._multiDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L718-L808)
	- [CoreStateRegistry._singleDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L846-L893)
	- [CoreStateRegistry._updateAmount(IDstSwapper,bool,uint256,uint256,uint256,uint256,uint256,uint256,PayloadState,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L489-L557)
	- [CoreStateRegistry.disputeRescueFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L246-L275)
	- [CoreStateRegistry.finalizeRescueFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L312)
	- [CoreStateRegistry.getFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L68-L76)
	- [CoreStateRegistry.proposeRescueFailedDeposits(uint256,uint256[])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L208-L243)
	- [failedDeposits[payloadId_].settleFromDstSwapper.push(false)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L783)
	[CoreStateRegistry.failedDeposits](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L46) can be used in cross function reentrancies:
	- [CoreStateRegistry._multiDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L718-L808)
	- [CoreStateRegistry._singleDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L846-L893)
	- [CoreStateRegistry._updateAmount(IDstSwapper,bool,uint256,uint256,uint256,uint256,uint256,uint256,PayloadState,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L489-L557)
	- [CoreStateRegistry.disputeRescueFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L246-L275)
	- [CoreStateRegistry.finalizeRescueFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L312)
	- [CoreStateRegistry.getFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L68-L76)
	- [CoreStateRegistry.proposeRescueFailedDeposits(uint256,uint256[])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L208-L243)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L718-L808


 - [ ] ID-7
Reentrancy in [SuperformFactory.createSuperform(uint32,address)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L197-L237):
	External calls:
	- [BaseForm(address(superform_)).initialize(address(superRegistry),vault_,address(IERC4626(vault_).asset()))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L221)
	State variables written after the call(s):
	- [vaultFormImplCombinationToSuperforms[vaultFormImplementationCombination] = superformId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L231)
	[SuperformFactory.vaultFormImplCombinationToSuperforms](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L57-L58) can be used in cross function reentrancies:
	- [SuperformFactory.createSuperform(uint32,address)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L197-L237)
	- [SuperformFactory.vaultFormImplCombinationToSuperforms](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L57-L58)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L197-L237


 - [ ] ID-8
Reentrancy in [CoreStateRegistry.finalizeRescueFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L312):
	External calls:
	- [dstSwapper.processFailedTx(failedDeposits_.refundAddress,failedDeposits_.settlementToken[i],failedDeposits_.amounts[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L300-L302)
	- [IERC20(failedDeposits_.settlementToken[i]).safeTransfer(failedDeposits_.refundAddress,failedDeposits_.amounts[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L304-L306)
	State variables written after the call(s):
	- [delete failedDeposits[payloadId_]](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L310)
	[CoreStateRegistry.failedDeposits](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L46) can be used in cross function reentrancies:
	- [CoreStateRegistry._multiDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L718-L808)
	- [CoreStateRegistry._singleDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L846-L893)
	- [CoreStateRegistry._updateAmount(IDstSwapper,bool,uint256,uint256,uint256,uint256,uint256,uint256,PayloadState,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L489-L557)
	- [CoreStateRegistry.disputeRescueFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L246-L275)
	- [CoreStateRegistry.finalizeRescueFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L312)
	- [CoreStateRegistry.getFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L68-L76)
	- [CoreStateRegistry.proposeRescueFailedDeposits(uint256,uint256[])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L208-L243)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L312


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-9
[PaymentHelper.estimateAckCost(uint256).v](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L590) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L590


 - [ ] ID-10
[BaseRouterImplementation._singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq).emptyRequest](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L168) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L168


 - [ ] ID-11
[CoreStateRegistry._multiWithdrawal(uint256,bytes,address,uint64).errors](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L666) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L666


 - [ ] ID-12
[CoreStateRegistry._updateMultiDeposit(uint256,bytes,uint256[]).currLen](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L434) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L434


 - [ ] ID-13
[ERC4626FormImplementation._processDirectDeposit(InitSingleVaultData).vars](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L157) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L157


 - [ ] ID-14
[CoreStateRegistry._updateAmount(IDstSwapper,bool,uint256,uint256,uint256,uint256,uint256,uint256,PayloadState,uint256).asset](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L540) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L540


 - [ ] ID-15
[PaymentHelper.estimateSingleXChainSingleVault(SingleXChainSingleVaultStateReq,bool).totalDstGas](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L315) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L315


 - [ ] ID-16
[BaseRouterImplementation._singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq).vars](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L412) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L412


 - [ ] ID-17
[BaseRouterImplementation._singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq).vars](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L234) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L234


 - [ ] ID-18
[BaseRouterImplementation._directMultiDeposit(address,bytes,InitMultiVaultData).v](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L642) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L642


 - [ ] ID-19
[CoreStateRegistry._multiDeposit(uint256,bytes,address,uint64).emptyRequest](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L744) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L744


 - [ ] ID-20
[DstSwapper._processTx(uint256,uint256,uint8,bytes,IBaseStateRegistry).v](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L276) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L276


 - [ ] ID-21
[PaymentHelper._estimateSwapFees(uint64,bool[]).totalSwaps](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L703) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L703


 - [ ] ID-22
[BaseRouterImplementation._singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq).vars](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L445) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L445


 - [ ] ID-23
[ERC4626FormImplementation._processDirectWithdraw(InitSingleVaultData,address).v](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L282) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L282


 - [ ] ID-24
[WormholeARImplementation.estimateFees(uint64,bytes,bytes).dstNativeAirdrop](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L109) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L109


 - [ ] ID-25
[BaseRouterImplementation._singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq).vars](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L305) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L305


 - [ ] ID-26
[CoreStateRegistry.processPayload(uint256).returnMessage](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L183) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L183


 - [ ] ID-27
[BaseRouterImplementation._singleVaultTokenForward(address,address,bytes,InitSingleVaultData).v](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L888) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L888


 - [ ] ID-28
[CoreStateRegistry._multiDeposit(uint256,bytes,address,uint64).errors](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L734) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L734


 - [ ] ID-29
[BaseRouterImplementation._singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq).vars](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L347) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L347


 - [ ] ID-30
[ERC4626TimelockForm.withdrawAfterCoolDown(TimelockPayload).vars](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626TimelockForm.sol#L75) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626TimelockForm.sol#L75


 - [ ] ID-31
[CoreStateRegistry._updateAmount(IDstSwapper,bool,uint256,uint256,uint256,uint256,uint256,uint256,PayloadState,uint256).failedSwapQueued](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L504) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L504


 - [ ] ID-32
[CoreStateRegistry._updateWithdrawPayload(bytes,address,uint64,bytes[],uint8).singleVaultData](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L572) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L572


 - [ ] ID-33
[PaymentHelper.estimateSingleXChainMultiVault(SingleXChainMultiVaultStateReq,bool).totalDstGas](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L263) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L263


 - [ ] ID-34
[WormholeARImplementation.estimateFees(uint64,bytes,bytes).dstGasLimit](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L110) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L110


 - [ ] ID-35
[BaseRouterImplementation._singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq).vars](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L130) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L130


 - [ ] ID-36
[ERC4626FormImplementation._processXChainWithdraw(InitSingleVaultData,address,uint64).vars](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L348) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L348


 - [ ] ID-37
[BaseRouterImplementation._multiVaultTokenForward(address,address[],bytes,InitMultiVaultData,bool).v](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L964) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L964


 - [ ] ID-38
[CoreStateRegistry._multiDeposit(uint256,bytes,address,uint64).fulfilment](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L733) is a local variable never initialized

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L733


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-39
[SuperPositions._registerSERC20(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L344-L373) ignores return value by [(superform) = id.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L348)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L344-L373


 - [ ] ID-40
[CoreStateRegistry._updateTxData(bytes[],InitMultiVaultData,address,uint64,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L595-L653) ignores return value by [bridgeValidator.validateTxData(IBridgeValidator.ValidateTxDataArgs(txData_[i],dstChainId_,srcChainId_,multiVaultData_.liqData[i].liqDstChainId,false,superform,srcSender_,multiVaultData_.liqData[i].token,address(0)))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L623-L635)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L595-L653


 - [ ] ID-41
[PaymentHelper.estimateSingleXChainMultiVault(SingleXChainMultiVaultStateReq,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L254-L303) ignores return value by [(formId) = req_.superformsData.superformIds[i].getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L291)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L254-L303


 - [ ] ID-42
[CoreStateRegistry._updateTxData(bytes[],InitMultiVaultData,address,uint64,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L595-L653) ignores return value by [(superform) = multiVaultData_.superformIds[i].getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L610)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L595-L653


 - [ ] ID-43
[SuperPositions._isValidStateSyncer(uint8,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L325-L342) ignores return value by [(formImplementationId) = DataLib.getSuperform(superformId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L337)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L325-L342


 - [ ] ID-44
[CoreStateRegistry.proposeRescueFailedDeposits(uint256,uint256[])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L208-L243) ignores return value by [(multi) = DataLib.decodeTxInfo(payloadHeader[payloadId_])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L232)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L208-L243


 - [ ] ID-45
[BaseRouterImplementation._directSingleDeposit(address,bytes,InitSingleVaultData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L593-L630) ignores return value by [(superform,None,None) = vaultData_.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L605)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L593-L630


 - [ ] ID-46
[BaseRouterImplementation._singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L232-L301) ignores return value by [(superform,None,None) = req_.superformsData.superformIds[j].getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L271)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L232-L301


 - [ ] ID-47
[DstSwapper._getFormUnderlyingFrom(IBaseStateRegistry,uint256,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421) ignores return value by [(superform) = DataLib.getSuperform(data.superformIds[index_])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L406)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421


 - [ ] ID-48
[BaseForm.notPaused(InitSingleVaultData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseForm.sol#L42-L59) ignores return value by [(formImplementationId_) = singleVaultData_.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseForm.sol#L51)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseForm.sol#L42-L59


 - [ ] ID-49
[CoreStateRegistry._getSuperform(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L319-L321) ignores return value by [(superform,None,None) = superformId_.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L320)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L319-L321


 - [ ] ID-50
[BaseRouterImplementation._directWithdraw(address,uint256,uint256,uint256,uint256,LiqRequest,address,bytes,address)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L686-L715) ignores return value by [IBaseForm(superform_).directWithdrawFromVault(InitSingleVaultData(payloadId_,superformId_,amount_,maxSlippage_,liqData_,false,false,receiverAddress_,extraFormData_),srcSender_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L701-L714)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L686-L715


 - [ ] ID-51
[TimelockStateRegistry.finalizePayload(uint256,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L119-L199) ignores return value by [bridgeValidator.validateTxData(IBridgeValidator.ValidateTxDataArgs(txData_,CHAIN_ID,p.srcChainId,p.data.liqData.liqDstChainId,false,superform,p.data.receiverAddress,p.data.liqData.token,address(0)))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L152-L164)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L119-L199


 - [ ] ID-52
[SuperPositions.stateMultiSync(AMBMessage)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L182-L228) ignores return value by [(returnTxType,callbackType,multi,returnDataSrcSender) = data_.txInfo.decodeTxInfo()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L185-L186)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L182-L228


 - [ ] ID-53
[CoreStateRegistry.processPayload(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L147-L205) ignores return value by [ISuperPositions(_getAddress(keccak256(bytes)(SUPER_POSITIONS))).stateSync(message_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L178-L180)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L147-L205


 - [ ] ID-54
[PaymentHelper.estimateMultiDstSingleVault(MultiDstSingleVaultStateReq,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L201-L251) ignores return value by [(formId) = req_.superformsData[i].superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L241)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L201-L251


 - [ ] ID-55
[LayerzeroImplementation.estimateFees(uint64,bytes,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L163-L180) ignores return value by [(fees,None) = lzEndpoint.estimateFees(chainId,address(this),message_,false,extraData_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L179)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L163-L180


 - [ ] ID-56
[PaymentHelper._getGasPrice(uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L830-L840) ignores return value by [(value,updatedAt) = AggregatorV3Interface(oracleAddr).latestRoundData()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L833)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L830-L840


 - [ ] ID-57
[ERC4626FormImplementation._processXChainDeposit(InitSingleVaultData,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L246-L273) ignores return value by [(dstChainId) = singleVaultData_.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L253)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L246-L273


 - [ ] ID-58
[EmergencyQueue.onlySuperform(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L40-L48) ignores return value by [(superform) = superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L44)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L40-L48


 - [ ] ID-59
[ERC4626FormImplementation._processXChainWithdraw(InitSingleVaultData,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L333-L399) ignores return value by [(None,None,vars.dstChainId) = singleVaultData_.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L349)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L333-L399


 - [ ] ID-60
[ERC4626TimelockForm.withdrawAfterCoolDown(TimelockPayload)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626TimelockForm.sol#L64-L126) ignores return value by [IBridgeValidator(superRegistry.getBridgeValidator(vars.liqData.bridgeId)).validateTxData(IBridgeValidator.ValidateTxDataArgs(vars.liqData.txData,vars.chainId,vars.chainId,vars.liqData.liqDstChainId,false,address(this),p_.data.receiverAddress,vars.liqData.token,address(0)))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626TimelockForm.sol#L104-L116)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626TimelockForm.sol#L64-L126


 - [ ] ID-61
[CoreStateRegistry._singleWithdrawal(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L810-L844) ignores return value by [IBaseForm(superform_).xChainWithdrawFromVault(singleVaultData,srcSender_,srcChainId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L828-L841)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L810-L844


 - [ ] ID-62
[PaymentHelper.estimateSingleDirectMultiVault(SingleDirectMultiVaultStateReq,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L375-L398) ignores return value by [(formId) = req_.superformData.superformIds[i].getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L386)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L375-L398


 - [ ] ID-63
[LayerzeroImplementation._nonblockingLzReceive(uint16,bytes,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305-L315) ignores return value by [(registryId) = decoded.txInfo.decodeTxInfo()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L310)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305-L315


 - [ ] ID-64
[CoreStateRegistry.processPayload(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L147-L205) ignores return value by [ISuperPositions(_getAddress(keccak256(bytes)(SUPER_POSITIONS))).stateMultiSync(message_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L178-L180)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L147-L205


 - [ ] ID-65
[CoreStateRegistry._multiWithdrawal(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L655-L716) ignores return value by [(superform_) = multiVaultData.superformIds[i].getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L677)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L655-L716


 - [ ] ID-66
[LiFiValidator.decodeSwapOutputToken(bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L156-L174) ignores return value by [() = this.extractMainParameters(txData_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L157-L173)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L156-L174


 - [ ] ID-67
[WormholeARImplementation.dispatchPayload(address,uint64,bytes,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L130-L149) ignores return value by [relayer.sendPayloadToEvm{value: msg.value}(dstChainId,authorizedImpl[dstChainId],message_,dstNativeAirdrop,dstGasLimit)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L146-L148)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L130-L149


 - [ ] ID-68
[PaymentHelper.estimateMultiDstMultiVault(MultiDstMultiVaultStateReq,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L139-L198) ignores return value by [(formId) = req_.superformsData[i].superformIds[j].getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L186)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L139-L198


 - [ ] ID-69
[CoreStateRegistry._singleWithdrawal(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L810-L844) ignores return value by [(superform_) = singleVaultData.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L826)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L810-L844


 - [ ] ID-70
[ERC4626FormImplementation._processDirectDeposit(InitSingleVaultData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L156-L244) ignores return value by [IBridgeValidator(vars.bridgeValidator).validateTxData(IBridgeValidator.ValidateTxDataArgs(singleVaultData_.liqData.txData,vars.chainId,vars.chainId,vars.chainId,true,address(this),msg.sender,address(token),address(0)))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L197-L209)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L156-L244


 - [ ] ID-71
[DstSwapper.updateFailedTx(uint256,uint256,address,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L173-L199) ignores return value by [(multi) = DataLib.decodeTxInfo(coreStateRegistry.payloadHeader(payloadId_))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L187)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L173-L199


 - [ ] ID-72
[EmergencyQueue._executeQueuedWithdrawal(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L118-L132) ignores return value by [(superform) = data.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L128)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L118-L132


 - [ ] ID-73
[WormholeSRImplementation.receiveMessage(bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L181-L211) ignores return value by [(wormholeMessage,valid) = wormhole.parseAndVerifyVM(encodedMessage_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L187)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L181-L211


 - [ ] ID-74
[HyperlaneImplementation.handle(uint32,bytes32,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L195-L220) ignores return value by [(registryId) = decoded.txInfo.decodeTxInfo()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L216)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L195-L220


 - [ ] ID-75
[SuperformFactory.getAllSuperforms()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L151-L164) ignores return value by [(superforms_[i],None,None) = superformIds_[i].getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L162)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L151-L164


 - [ ] ID-76
[ERC4626FormImplementation._processXChainWithdraw(InitSingleVaultData,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L333-L399) ignores return value by [IBridgeValidator(vars.bridgeValidator).validateTxData(IBridgeValidator.ValidateTxDataArgs(singleVaultData_.liqData.txData,vars.dstChainId,srcChainId_,singleVaultData_.liqData.liqDstChainId,false,address(this),singleVaultData_.receiverAddress,singleVaultData_.liqData.token,address(0)))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L375-L387)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L333-L399


 - [ ] ID-77
[ERC4626FormImplementation._processDirectWithdraw(InitSingleVaultData,address)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L275-L331) ignores return value by [IBridgeValidator(v.bridgeValidator).validateTxData(IBridgeValidator.ValidateTxDataArgs(singleVaultData_.liqData.txData,v.chainId,v.chainId,singleVaultData_.liqData.liqDstChainId,false,address(this),srcSender_,singleVaultData_.liqData.token,address(0)))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L309-L321)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L275-L331


 - [ ] ID-78
[BaseRouterImplementation._directSingleWithdraw(InitSingleVaultData,address)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L719-L734) ignores return value by [(superform) = vaultData_.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L721)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L719-L734


 - [ ] ID-79
[DstSwapper.batchUpdateFailedTx(uint256,uint256[],address[],uint256[])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L202-L228) ignores return value by [(multi) = DataLib.decodeTxInfo(coreStateRegistry.payloadHeader(payloadId_))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L218)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L202-L228


 - [ ] ID-80
[TimelockStateRegistry.processPayload(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L202-L233) ignores return value by [(callbackType,srcChainId) = _payloadHeader.decodeTxInfo()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L220)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L202-L233


 - [ ] ID-81
[PaymentHelper._getNativeTokenPrice(uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L844-L854) ignores return value by [(dstTokenPrice,updatedAt) = AggregatorV3Interface(oracleAddr).latestRoundData()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L847)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L844-L854


 - [ ] ID-82
[DstSwapper._getFormUnderlyingFrom(IBaseStateRegistry,uint256,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421) ignores return value by [(superform_scope_1) = DataLib.getSuperform(data_scope_0.superformId)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L416)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421


 - [ ] ID-83
[TimelockStateRegistry._dispatchAcknowledgement(uint64,uint8[],bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L285-L290) ignores return value by [(extraData) = IPaymentHelper(superRegistry.getAddress(keccak256(bytes)(PAYMENT_HELPER))).calculateAMBData(dstChainId_,ambIds_,message_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L286-L287)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L285-L290


 - [ ] ID-84
[WormholeARImplementation.estimateFees(uint64,bytes,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L99-L123) ignores return value by [(fees,None) = relayer.quoteEVMDeliveryPrice(dstChainId,dstNativeAirdrop,dstGasLimit)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L122)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L99-L123


 - [ ] ID-85
[PaymentHelper.estimateSingleDirectSingleVault(SingleDirectSingleVaultStateReq,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L353-L372) ignores return value by [(formId) = req_.superformData.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L362)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L353-L372


 - [ ] ID-86
[CoreStateRegistry._singleDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L846-L893) ignores return value by [(superform_) = singleVaultData.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L857)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L846-L893


 - [ ] ID-87
[PaymentHelper.estimateSingleXChainSingleVault(SingleXChainSingleVaultStateReq,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L306-L350) ignores return value by [(formId) = req_.superformData.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L341)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L306-L350


 - [ ] ID-88
[SuperPositions.onlyBatchMinter(uint256[])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L92-L108) ignores return value by [(formBeaconId) = DataLib.getSuperform(superformIds[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L99)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L92-L108


 - [ ] ID-89
[WormholeARImplementation.retryPayload(bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L152-L168) ignores return value by [relayer.resendToEvm{value: msg.value}(deliveryVaaKey,targetChain,newReceiverValue,newGasLimit,newDeliveryProviderAddress)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L165-L167)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L152-L168


 - [ ] ID-90
[TimelockStateRegistry.onlyTimelockSuperform(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L60-L72) ignores return value by [(superform) = superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L64)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L60-L72


 - [ ] ID-91
[WormholeSRImplementation.broadcastPayload(address,bytes,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L145-L179) ignores return value by [wormhole.publishMessage{value: msgFee}(0,message_,broadcastFinality)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L162-L167)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L145-L179


 - [ ] ID-92
[ERC4626TimelockForm.withdrawAfterCoolDown(TimelockPayload)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626TimelockForm.sol#L64-L126) ignores return value by [IBridgeValidator(superRegistry.getBridgeValidator(vars.liqData.bridgeId)).validateTxData(IBridgeValidator.ValidateTxDataArgs(vars.liqData.txData,vars.chainId,p_.srcChainId,vars.liqData.liqDstChainId,false,address(this),p_.data.receiverAddress,vars.liqData.token,address(0)))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626TimelockForm.sol#L104-L116)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626TimelockForm.sol#L64-L126


 - [ ] ID-93
[SuperPositions.stateMultiSync(AMBMessage)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L182-L228) ignores return value by [(txType,None,None,None,srcSender,srcChainId_) = txInfo.decodeTxInfo()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L208)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L182-L228


 - [ ] ID-94
[BaseForm._isPaused(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseForm.sol#L307-L317) ignores return value by [(formImplementationId_) = superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseForm.sol#L312)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseForm.sol#L307-L317


 - [ ] ID-95
[ERC4626FormImplementation.constructor(address,uint8)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L69-L74) ignores return value by [superRegistry.getStateRegistry(stateRegistryId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L71)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L69-L74


 - [ ] ID-96
[BaseRouterImplementation._validateSuperformData(uint256,uint256,uint256,address,uint64,bool,ISuperformFactory)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L763-L807) ignores return value by [(formImplementationId,sfDstChainId) = superformId_.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L784)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L763-L807


 - [ ] ID-97
[BaseRouterImplementation._singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L128-L205) ignores return value by [(superform) = req_.superformData.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L163)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L128-L205


 - [ ] ID-98
[LiFiValidator.decodeAmountIn(bytes,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L121-L149) ignores return value by [(amount) = this.extractMainParameters(txData_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L130-L148)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L121-L149


 - [ ] ID-99
[SuperPositions.onlyMinter(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L69-L83) ignores return value by [(formBeaconId) = DataLib.getSuperform(superformId)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L74)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L69-L83


 - [ ] ID-100
[LiFiValidator.validateTxData(IBridgeValidator.ValidateTxDataArgs)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L31-L118) ignores return value by [(sendingAssetId,receiver,destinationChainId,hasDestinationCall) = this.extractMainParameters(args_.txData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L37-L117)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L31-L118


 - [ ] ID-101
[SuperformFactory.getAllSuperformsFromVault(address)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L135-L148) ignores return value by [(superforms_[i],None,None) = superformIds_[i].getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L146)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L135-L148


 - [ ] ID-102
[TimelockStateRegistry.processPayload(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L202-L233) ignores return value by [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).stateSync(_message)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L231)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L202-L233


 - [ ] ID-103
[PaymentHelper.estimateAckCost(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L589-L618) ignores return value by [(None,v.callbackType,v.isMulti,None,None,v.srcChainId) = DataLib.decodeTxInfo(v.payloadHeader)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L600)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L589-L618


 - [ ] ID-104
[DstSwapper._getFormUnderlyingFrom(IBaseStateRegistry,uint256,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421) ignores return value by [(multi) = DataLib.decodeTxInfo(payloadHeader)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L397)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421


 - [ ] ID-105
[TimelockStateRegistry.finalizePayload(uint256,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L119-L199) ignores return value by [(superform) = p.data.superformId.getSuperform()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L142)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L119-L199


 - [ ] ID-106
[SuperPositions.stateSync(AMBMessage)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L231-L277) ignores return value by [(txType,None,None,None,srcSender,srcChainId_) = txInfo.decodeTxInfo()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L256)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L231-L277


 - [ ] ID-107
[SuperPositions.stateSync(AMBMessage)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L231-L277) ignores return value by [(returnTxType,callbackType,multi,returnDataSrcSender) = data_.txInfo.decodeTxInfo()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L234-L235)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L231-L277


 - [ ] ID-108
[HyperlaneImplementation.dispatchPayload(address,uint64,bytes,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L126-L143) ignores return value by [mailbox.dispatch{value: msg.value}(domain,_castAddr(authorizedImpl[domain]),message_,_generateHookMetadata(extraData_,srcSender_))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L140-L142)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L126-L143


 - [ ] ID-109
[WormholeARImplementation.receiveWormholeMessages(bytes,bytes[],bytes32,uint16,bytes32)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L171-L202) ignores return value by [(registryId) = decoded.txInfo.decodeTxInfo()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L198)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L171-L202


 - [ ] ID-110
[CoreStateRegistry._processAck(uint256,uint64,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L895-L906) ignores return value by [(extraData) = IPaymentHelper(_getAddress(keccak256(bytes)(PAYMENT_HELPER))).calculateAMBData(srcChainId_,ambIds,returnMessage_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L900-L902)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L895-L906


 - [ ] ID-111
[DstSwapper._processTx(uint256,uint256,uint8,bytes,IBaseStateRegistry)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331) ignores return value by [validator.validateTxData(IBridgeValidator.ValidateTxDataArgs(txData_,v.chainId,v.chainId,v.chainId,false,address(0),v.finalDst,v.approvalToken,address(0)))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L284-L297)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331


 - [ ] ID-112
[CoreStateRegistry._multiWithdrawal(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L655-L716) ignores return value by [IBaseForm(superform_).xChainWithdrawFromVault(InitSingleVaultData({payloadId:multiVaultData.payloadId,superformId:multiVaultData.superformIds[i],amount:multiVaultData.amounts[i],maxSlippage:multiVaultData.maxSlippages[i],liqData:multiVaultData.liqData[i],hasDstSwap:false,retain4626:false,receiverAddress:multiVaultData.receiverAddress,extraFormData:abi.encode(payloadId_,i)}),srcSender_,srcChainId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L679-L700)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L655-L716


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-113
[BaseRouterImplementation._dispatchAmbMessage(IBaseRouterImplementation.DispatchAMBMessageVars)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L525-L549) has external calls inside a loop: [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).updateTxHistory(vars_.currentPayloadId,ambMessage.txInfo)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L541-L543)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L525-L549


 - [ ] ID-114
[BaseRouterImplementation._singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L128-L205) has external calls inside a loop: [! _validateSuperformData(req_.superformData.superformId,req_.superformData.maxSlippage,req_.superformData.amount,req_.superformData.receiverAddress,req_.dstChainId,true,ISuperformFactory(superRegistry.getAddress(keccak256(bytes)(SUPERFORM_FACTORY))))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L136-L144)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L128-L205


 - [ ] ID-115
[BaseRouterImplementation._multiVaultTokenForward(address,address[],bytes,InitMultiVaultData,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L953-L1051) has external calls inside a loop: [IPermit2(v.permit2).permitTransferFrom(IPermit2.PermitTransferFrom({permitted:IPermit2.TokenPermissions({token:v.token,amount:v.totalAmount}),nonce:nonce,deadline:deadline}),IPermit2.SignatureTransferDetails({to:address(this),requestedAmount:v.totalAmount}),srcSender_,signature)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L1016-L1032)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L953-L1051


 - [ ] ID-116
[BaseRouterImplementation._validateSuperformsData(MultiVaultSFData,uint64,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L809-L856) has external calls inside a loop: [lenSuperforms > superRegistry.getVaultLimitPerTx(dstChainId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L828)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L809-L856


 - [ ] ID-117
[DstSwapper._processTx(uint256,uint256,uint8,bytes,IBaseStateRegistry)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331) has external calls inside a loop: [validator.validateTxData(IBridgeValidator.ValidateTxDataArgs(txData_,v.chainId,v.chainId,v.chainId,false,address(0),v.finalDst,v.approvalToken,address(0)))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L284-L297)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331


 - [ ] ID-118
[BaseRouterImplementation._singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L345-L408) has external calls inside a loop: [! _validateSuperformData(req_.superformData.superformId,req_.superformData.maxSlippage,req_.superformData.amount,req_.superformData.receiverAddress,req_.dstChainId,false,ISuperformFactory(superRegistry.getAddress(keccak256(bytes)(SUPERFORM_FACTORY))))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L356-L364)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L345-L408


 - [ ] ID-119
[BaseRouterImplementation._validateAndDispatchTokens(BaseRouterImplementation.ValidateAndDispatchTokensArgs)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L494-L523) has external calls inside a loop: [bridgeValidator = superRegistry.getBridgeValidator(args_.liqRequest.bridgeId)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L499)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L494-L523


 - [ ] ID-120
[DstSwapper._processTx(uint256,uint256,uint8,bytes,IBaseStateRegistry)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331) has external calls inside a loop: [v.balanceBefore = IERC20(v.underlying).balanceOf(v.finalDst)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L302)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331


 - [ ] ID-121
[DstSwapper._getFormUnderlyingFrom(IBaseStateRegistry,uint256,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421) has external calls inside a loop: [payloadHeader = coreStateRegistry_.payloadHeader(payloadId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L394)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421


 - [ ] ID-122
[DstSwapper._processTx(uint256,uint256,uint8,bytes,IBaseStateRegistry)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331) has external calls inside a loop: [_dispatchTokens(superRegistry.getBridgeAddress(bridgeId_),txData_,v.approvalToken,v.amount,v.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L304-L310)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331


 - [ ] ID-123
[BaseRouterImplementation._validateSuperformsData(MultiVaultSFData,uint64,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L809-L856) has external calls inside a loop: [factory = ISuperformFactory(superRegistry.getAddress(keccak256(bytes)(SUPERFORM_FACTORY)))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L836)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L809-L856


 - [ ] ID-124
[BaseRouterImplementation._singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L304-L342) has external calls inside a loop: [! _validateSuperformData(req_.superformData.superformId,req_.superformData.maxSlippage,req_.superformData.amount,req_.superformData.receiverAddress,vars.srcChainId,false,ISuperformFactory(superRegistry.getAddress(keccak256(bytes)(SUPERFORM_FACTORY))))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L310-L318)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L304-L342


 - [ ] ID-125
[BaseRouterImplementation._validateAndDispatchTokens(BaseRouterImplementation.ValidateAndDispatchTokensArgs)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L494-L523) has external calls inside a loop: [hasDstSwap = IBridgeValidator(bridgeValidator).validateTxData(IBridgeValidator.ValidateTxDataArgs(args_.liqRequest.txData,args_.srcChainId,args_.dstChainId,args_.liqRequest.liqDstChainId,args_.deposit,args_.superform,args_.srcSender,args_.liqRequest.token,args_.liqRequest.interimToken))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L501-L513)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L494-L523


 - [ ] ID-126
[PaymentHelper._getGasPrice(uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L830-L840) has external calls inside a loop: [(value,updatedAt) = AggregatorV3Interface(oracleAddr).latestRoundData()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L833)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L830-L840


 - [ ] ID-127
[BaseRouterImplementation._singleVaultTokenForward(address,address,bytes,InitSingleVaultData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L878-L951) has external calls inside a loop: [IPermit2(v.permit2).permitTransferFrom(IPermit2.PermitTransferFrom({permitted:IPermit2.TokenPermissions({token:v.token,amount:v.approvalAmount}),nonce:nonce,deadline:deadline}),IPermit2.SignatureTransferDetails({to:address(this),requestedAmount:v.approvalAmount}),srcSender_,signature)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L918-L934)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L878-L951


 - [ ] ID-128
[LiquidityHandler._dispatchTokens(address,bytes,address,uint256,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/LiquidityHandler.sol#L33-L56) has external calls inside a loop: [(success) = address(bridge_).call{value: nativeAmount_}(txData_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/LiquidityHandler.sol#L54)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/LiquidityHandler.sol#L33-L56


 - [ ] ID-129
[PaymentHelper._estimateAMBFees(uint8[],uint64,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L621-L650) has external calls inside a loop: [tempFee = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(dstChainId_,proof_,extraDataPerAMB[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L642-L646)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L621-L650


 - [ ] ID-130
[DstSwapper._getFormUnderlyingFrom(IBaseStateRegistry,uint256,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421) has external calls inside a loop: [currState = coreStateRegistry_.payloadTracking(payloadId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L388)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421


 - [ ] ID-131
[BaseRouterImplementation._validateAndDispatchTokens(BaseRouterImplementation.ValidateAndDispatchTokensArgs)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L494-L523) has external calls inside a loop: [_dispatchTokens(superRegistry.getBridgeAddress(args_.liqRequest.bridgeId),args_.liqRequest.txData,args_.liqRequest.token,IBridgeValidator(bridgeValidator).decodeAmountIn(args_.liqRequest.txData,true),args_.liqRequest.nativeAmount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L516-L522)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L494-L523


 - [ ] ID-132
[EmergencyQueue._executeQueuedWithdrawal(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L118-L132) has external calls inside a loop: [IBaseForm(superform).emergencyWithdraw(data.srcSender,data.refundAddress,data.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L129)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L118-L132


 - [ ] ID-133
[PaymentHelper.estimateAMBFees(uint8[],uint64,bytes,bytes[])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L401-L426) has external calls inside a loop: [fees[i] = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(dstChainId_,message_,extraData_[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L416-L420)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L401-L426


 - [ ] ID-134
[PaymentHelper._getNativeTokenPrice(uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L844-L854) has external calls inside a loop: [(dstTokenPrice,updatedAt) = AggregatorV3Interface(oracleAddr).latestRoundData()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L847)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L844-L854


 - [ ] ID-135
[BaseRouterImplementation._singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L411-L440) has external calls inside a loop: [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnBatch(msg.sender,req_.superformData.superformIds,req_.superformData.amounts)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L421-L423)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L411-L440


 - [ ] ID-136
[BaseRouterImplementation._singleVaultTokenForward(address,address,bytes,InitSingleVaultData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L878-L951) has external calls inside a loop: [v.amountIn = IBridgeValidator(superRegistry.getBridgeValidator(v.bridgeId)).decodeAmountIn(vaultData_.liqData.txData,false)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L895-L897)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L878-L951


 - [ ] ID-137
[DstSwapper._processTx(uint256,uint256,uint8,bytes,IBaseStateRegistry)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331) has external calls inside a loop: [v.balanceAfter = IERC20(v.underlying).balanceOf(v.finalDst)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L312)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331


 - [ ] ID-138
[DstSwapper._getFormUnderlyingFrom(IBaseStateRegistry,uint256,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421) has external calls inside a loop: [underlying = IERC4626Form(superform).getVaultAsset()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L407)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421


 - [ ] ID-139
[PaymentHelper._getNextPayloadId()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L823-L826) has external calls inside a loop: [nextPayloadId = ReadOnlyBaseRegistry(superRegistry.getAddress(keccak256(bytes)(CORE_STATE_REGISTRY))).payloadsCount()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L824)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L823-L826


 - [ ] ID-140
[BaseRouterImplementation._validateSuperformData(uint256,uint256,uint256,address,uint64,bool,ISuperformFactory)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L763-L807) has external calls inside a loop: [dstChainId_ == CHAIN_ID && ! factory_.isSuperform(superformId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L778)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L763-L807


 - [ ] ID-141
[BaseRouterImplementation._dispatchAmbMessage(IBaseRouterImplementation.DispatchAMBMessageVars)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L525-L549) has external calls inside a loop: [(fees,extraData) = IPaymentHelper(superRegistry.getAddress(keccak256(bytes)(PAYMENT_HELPER))).calculateAMBData(vars_.dstChainId,vars_.ambIds,abi.encode(ambMessage))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L538-L539)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L525-L549


 - [ ] ID-142
[BaseRouterImplementation._validateSuperformData(uint256,uint256,uint256,address,uint64,bool,ISuperformFactory)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L763-L807) has external calls inside a loop: [isDeposit_ && factory_.isFormImplementationPaused(formImplementationId)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L794)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L763-L807


 - [ ] ID-143
[DstSwapper._processTx(uint256,uint256,uint8,bytes,IBaseStateRegistry)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331) has external calls inside a loop: [(v.approvalToken,v.amount) = validator.decodeDstSwap(txData_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L280)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331


 - [ ] ID-144
[DstSwapper._updateFailedTx(uint256,uint256,address,address,uint256,IBaseStateRegistry)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L333-L377) has external calls inside a loop: [currState = coreStateRegistry.payloadTracking(payloadId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L343)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L333-L377


 - [ ] ID-145
[DstSwapper._getFormUnderlyingFrom(IBaseStateRegistry,uint256,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421) has external calls inside a loop: [payload = coreStateRegistry_.payloadBody(payloadId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L395)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421


 - [ ] ID-146
[DstSwapper._processTx(uint256,uint256,uint8,bytes,IBaseStateRegistry)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331) has external calls inside a loop: [validator = IBridgeValidator(superRegistry.getBridgeValidator(bridgeId_))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L279)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331


 - [ ] ID-147
[BaseRouterImplementation._singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L443-L492) has external calls inside a loop: [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnBatch(msg.sender,req_.superformsData.superformIds,req_.superformsData.amounts)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L456-L458)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L443-L492


 - [ ] ID-148
[BaseRouterImplementation._directSingleDeposit(address,bytes,InitSingleVaultData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L593-L630) has external calls inside a loop: [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).mintSingle(srcSender_,vaultData_.superformId,dstAmount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L626-L628)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L593-L630


 - [ ] ID-149
[BaseRouterImplementation._singleVaultTokenForward(address,address,bytes,InitSingleVaultData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L878-L951) has external calls inside a loop: [v.token.allowance(srcSender_,address(this)) < v.approvalAmount](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L936)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L878-L951


 - [ ] ID-150
[BaseRouterImplementation._directDeposit(address,uint256,uint256,uint256,uint256,bool,LiqRequest,address,bytes,uint256,address)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L556-L589) has external calls inside a loop: [dstAmount = IBaseForm(superform_).directDepositIntoVault{value: msgValue_}(InitSingleVaultData(payloadId_,superformId_,amount_,maxSlippage_,liqData_,false,retain4626_,receiverAddress_,extraFormData_),srcSender_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L574-L588)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L556-L589


 - [ ] ID-151
[BaseRouterImplementation._directMultiDeposit(address,bytes,InitMultiVaultData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L634-L679) has external calls inside a loop: [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).mintBatch(srcSender_,vaultData_.superformIds,v.dstAmounts)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L676-L678)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L634-L679


 - [ ] ID-152
[BaseRouterImplementation._singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L94-L125) has external calls inside a loop: [! _validateSuperformData(req_.superformData.superformId,req_.superformData.maxSlippage,req_.superformData.amount,req_.superformData.receiverAddress,CHAIN_ID,true,ISuperformFactory(superRegistry.getAddress(keccak256(bytes)(SUPERFORM_FACTORY))))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L97-L105)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L94-L125


 - [ ] ID-153
[BaseRouterImplementation._multiVaultTokenForward(address,address[],bytes,InitMultiVaultData,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L953-L1051) has external calls inside a loop: [v.amountsIn[i] = IBridgeValidator(superRegistry.getBridgeValidator(v.bridgeIds[i])).decodeAmountIn(vaultData_.liqData[i].txData,false)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L975-L977)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L953-L1051


 - [ ] ID-154
[BaseRouterImplementation._multiVaultTokenForward(address,address[],bytes,InitMultiVaultData,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L953-L1051) has external calls inside a loop: [v.token.allowance(srcSender_,address(this)) < v.totalAmount](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L1034)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L953-L1051


 - [ ] ID-155
[DstSwapper._getFormUnderlyingFrom(IBaseStateRegistry,uint256,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421) has external calls inside a loop: [underlying = IERC4626Form(superform_scope_1).getVaultAsset()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L417)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L379-L421


 - [ ] ID-156
[CoreStateRegistry.finalizeRescueFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L312) has external calls inside a loop: [dstSwapper.processFailedTx(failedDeposits_.refundAddress,failedDeposits_.settlementToken[i],failedDeposits_.amounts[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L300-L302)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L312


 - [ ] ID-157
[BaseRouterImplementation._dispatchAmbMessage(IBaseRouterImplementation.DispatchAMBMessageVars)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L525-L549) has external calls inside a loop: [IBaseStateRegistry(superRegistry.getAddress(keccak256(bytes)(CORE_STATE_REGISTRY))).dispatchPayload{value: fees}(vars_.srcSender,vars_.ambIds,vars_.dstChainId,abi.encode(ambMessage),extraData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L546-L548)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L525-L549


 - [ ] ID-158
[BaseRouterImplementation._singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L304-L342) has external calls inside a loop: [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnSingle(msg.sender,req_.superformData.superformId,req_.superformData.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L323-L325)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L304-L342


 - [ ] ID-159
[BaseRouterImplementation._getPermit2()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L89-L91) has external calls inside a loop: [superRegistry.PERMIT2()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L90)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L89-L91


 - [ ] ID-160
[BaseRouterImplementation._directWithdraw(address,uint256,uint256,uint256,uint256,LiqRequest,address,bytes,address)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L686-L715) has external calls inside a loop: [IBaseForm(superform_).directWithdrawFromVault(InitSingleVaultData(payloadId_,superformId_,amount_,maxSlippage_,liqData_,false,false,receiverAddress_,extraFormData_),srcSender_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L701-L714)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L686-L715


 - [ ] ID-161
[PaymentHelper._estimateAMBFees(uint8[],uint64,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L621-L650) has external calls inside a loop: [tempFee = IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(dstChainId_,abi.encode(ambIdEncodedMessage),extraDataPerAMB[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L642-L646)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L621-L650


 - [ ] ID-162
[DstSwapper._updateFailedTx(uint256,uint256,address,address,uint256,IBaseStateRegistry)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L333-L377) has external calls inside a loop: [IERC20(interimToken_).balanceOf(address(this)) < amount_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L362)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L333-L377


 - [ ] ID-163
[BaseRouterImplementation._singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L345-L408) has external calls inside a loop: [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnSingle(msg.sender,req_.superformData.superformId,req_.superformData.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L369-L371)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L345-L408


 - [ ] ID-164
[DstSwapper._processTx(uint256,uint256,uint8,bytes,IBaseStateRegistry)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331) has external calls inside a loop: [_dispatchTokens(superRegistry.getBridgeAddress(bridgeId_),txData_,v.approvalToken,v.amount,0)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L304-L310)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L263-L331


## reentrancy-benign
Impact: Low
Confidence: Medium
 - [ ] ID-165
Reentrancy in [BaseRouterImplementation._singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L345-L408):
	External calls:
	- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnSingle(msg.sender,req_.superformData.superformId,req_.superformData.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L369-L371)
	State variables written after the call(s):
	- [vars.currentPayloadId = ++ payloadIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L373)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L345-L408


 - [ ] ID-166
Reentrancy in [CoreStateRegistry._singleDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L846-L893):
	External calls:
	- [underlying.safeIncreaseAllowance(superform_,singleVaultData.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L861)
	- [dstAmount = IBaseForm(superform_).xChainDepositIntoVault(singleVaultData,srcSender_,srcChainId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L864-L887)
	- [underlying.safeDecreaseAllowance(superform_,singleVaultData.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L879)
	State variables written after the call(s):
	- [failedDeposits[payloadId_].superformIds.push(singleVaultData.superformId)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L882)
	- [failedDeposits[payloadId_].settlementToken.push(IBaseForm(superform_).getVaultAsset())](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L883)
	- [failedDeposits[payloadId_].settleFromDstSwapper.push(false)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L884)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L846-L893


 - [ ] ID-167
Reentrancy in [LayerzeroImplementation._blockingLzReceive(uint16,bytes,uint64,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L337-L353):
	External calls:
	- [this.nonblockingLzReceive(srcChainId_,srcAddress_,payload_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L346-L352)
	State variables written after the call(s):
	- [failedMessages[srcChainId_][srcAddress_][nonce_] = keccak256(bytes)(payload_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L350)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L337-L353


 - [ ] ID-168
Reentrancy in [SuperformFactory.createSuperform(uint32,address)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L197-L237):
	External calls:
	- [BaseForm(address(superform_)).initialize(address(superRegistry),vault_,address(IERC4626(vault_).asset()))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L221)
	State variables written after the call(s):
	- [isSuperform[superformId_] = true](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L234)
	- [superforms.push(superformId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L233)
	- [vaultToFormImplementationId[vault_].push(formImplementationId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L229)
	- [vaultToSuperforms[vault_].push(superformId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L226)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L197-L237


 - [ ] ID-169
Reentrancy in [BaseRouterImplementation._singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L443-L492):
	External calls:
	- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnBatch(msg.sender,req_.superformsData.superformIds,req_.superformsData.amounts)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L456-L458)
	State variables written after the call(s):
	- [vars.currentPayloadId = ++ payloadIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L460)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L443-L492


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-170
Reentrancy in [CoreStateRegistry._multiDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L718-L808):
	External calls:
	- [underlying.safeIncreaseAllowance(superforms[i],multiVaultData.amounts[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L743)
	- [dstAmount = IBaseForm(superforms[i]).xChainDepositIntoVault(InitSingleVaultData({payloadId:multiVaultData.payloadId,superformId:multiVaultData.superformIds[i],amount:multiVaultData.amounts[i],maxSlippage:multiVaultData.maxSlippages[i],liqData:emptyRequest,hasDstSwap:false,retain4626:multiVaultData.retain4626s[i],receiverAddress:multiVaultData.receiverAddress,extraFormData:multiVaultData.extraFormData}),srcSender_,srcChainId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L747-L784)
	- [underlying.safeDecreaseAllowance(superforms[i],multiVaultData.amounts[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L771)
	Event emitted after the call(s):
	- [FailedXChainDeposits(payloadId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L804)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L718-L808


 - [ ] ID-171
Reentrancy in [SuperformRouter.multiDstSingleVaultWithdraw(MultiDstSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L166-L185):
	External calls:
	- [_singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq(req_.superformsData[i]))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L176)
		- [IBaseForm(superform_).directWithdrawFromVault(InitSingleVaultData(payloadId_,superformId_,amount_,maxSlippage_,liqData_,false,false,receiverAddress_,extraFormData_),srcSender_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L701-L714)
		- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnSingle(msg.sender,req_.superformData.superformId,req_.superformData.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L323-L325)
	- [_singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq(req_.ambIds[i],req_.dstChainIds[i],req_.superformsData[i]))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L178-L180)
		- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).updateTxHistory(vars_.currentPayloadId,ambMessage.txInfo)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L541-L543)
		- [IBaseStateRegistry(superRegistry.getAddress(keccak256(bytes)(CORE_STATE_REGISTRY))).dispatchPayload{value: fees}(vars_.srcSender,vars_.ambIds,vars_.dstChainId,abi.encode(ambMessage),extraData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L546-L548)
		- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnSingle(msg.sender,req_.superformData.superformId,req_.superformData.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L369-L371)
	External calls sending eth:
	- [_singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq(req_.ambIds[i],req_.dstChainIds[i],req_.superformsData[i]))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L178-L180)
		- [IBaseStateRegistry(superRegistry.getAddress(keccak256(bytes)(CORE_STATE_REGISTRY))).dispatchPayload{value: fees}(vars_.srcSender,vars_.ambIds,vars_.dstChainId,abi.encode(ambMessage),extraData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L546-L548)
	Event emitted after the call(s):
	- [Completed()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L341)
		- [_singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq(req_.superformsData[i]))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L176)
	- [CrossChainInitiatedWithdrawSingle(vars.currentPayloadId,req_.dstChainId,req_.superformData.superformId,req_.ambIds)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L405-L407)
		- [_singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq(req_.ambIds[i],req_.dstChainIds[i],req_.superformsData[i]))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L178-L180)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L166-L185


 - [ ] ID-172
Reentrancy in [BaseRouterImplementation._singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L304-L342):
	External calls:
	- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnSingle(msg.sender,req_.superformData.superformId,req_.superformData.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L323-L325)
	- [_directSingleWithdraw(vaultData,msg.sender)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L340)
		- [IBaseForm(superform_).directWithdrawFromVault(InitSingleVaultData(payloadId_,superformId_,amount_,maxSlippage_,liqData_,false,false,receiverAddress_,extraFormData_),srcSender_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L701-L714)
	Event emitted after the call(s):
	- [Completed()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L341)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L304-L342


 - [ ] ID-173
Reentrancy in [CoreStateRegistry._singleDeposit(uint256,bytes,address,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L846-L893):
	External calls:
	- [underlying.safeIncreaseAllowance(superform_,singleVaultData.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L861)
	- [dstAmount = IBaseForm(superform_).xChainDepositIntoVault(singleVaultData,srcSender_,srcChainId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L864-L887)
	- [underlying.safeDecreaseAllowance(superform_,singleVaultData.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L879)
	Event emitted after the call(s):
	- [FailedXChainDeposits(payloadId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L886)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L846-L893


 - [ ] ID-174
Reentrancy in [BaseRouterImplementation._singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L345-L408):
	External calls:
	- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnSingle(msg.sender,req_.superformData.superformId,req_.superformData.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L369-L371)
	- [_dispatchAmbMessage(DispatchAMBMessageVars(TransactionType.WITHDRAW,abi.encode(ambData),superformIds,msg.sender,req_.ambIds,0,vars.srcChainId,req_.dstChainId,vars.currentPayloadId))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L391-L403)
		- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).updateTxHistory(vars_.currentPayloadId,ambMessage.txInfo)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L541-L543)
		- [IBaseStateRegistry(superRegistry.getAddress(keccak256(bytes)(CORE_STATE_REGISTRY))).dispatchPayload{value: fees}(vars_.srcSender,vars_.ambIds,vars_.dstChainId,abi.encode(ambMessage),extraData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L546-L548)
	External calls sending eth:
	- [_dispatchAmbMessage(DispatchAMBMessageVars(TransactionType.WITHDRAW,abi.encode(ambData),superformIds,msg.sender,req_.ambIds,0,vars.srcChainId,req_.dstChainId,vars.currentPayloadId))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L391-L403)
		- [IBaseStateRegistry(superRegistry.getAddress(keccak256(bytes)(CORE_STATE_REGISTRY))).dispatchPayload{value: fees}(vars_.srcSender,vars_.ambIds,vars_.dstChainId,abi.encode(ambMessage),extraData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L546-L548)
	Event emitted after the call(s):
	- [CrossChainInitiatedWithdrawSingle(vars.currentPayloadId,req_.dstChainId,req_.superformData.superformId,req_.ambIds)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L405-L407)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L345-L408


 - [ ] ID-175
Reentrancy in [PayMaster._withdrawNative(address,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L111-L119):
	External calls:
	- [(success) = address(receiver_).call{value: amount_}()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L112)
	Event emitted after the call(s):
	- [PaymentWithdrawn(receiver_,amount_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L118)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L111-L119


 - [ ] ID-176
Reentrancy in [BaseRouterImplementation._singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L443-L492):
	External calls:
	- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnBatch(msg.sender,req_.superformsData.superformIds,req_.superformsData.amounts)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L456-L458)
	- [_dispatchAmbMessage(DispatchAMBMessageVars(TransactionType.WITHDRAW,abi.encode(ambData),req_.superformsData.superformIds,msg.sender,req_.ambIds,1,vars.srcChainId,req_.dstChainId,vars.currentPayloadId))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L475-L487)
		- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).updateTxHistory(vars_.currentPayloadId,ambMessage.txInfo)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L541-L543)
		- [IBaseStateRegistry(superRegistry.getAddress(keccak256(bytes)(CORE_STATE_REGISTRY))).dispatchPayload{value: fees}(vars_.srcSender,vars_.ambIds,vars_.dstChainId,abi.encode(ambMessage),extraData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L546-L548)
	External calls sending eth:
	- [_dispatchAmbMessage(DispatchAMBMessageVars(TransactionType.WITHDRAW,abi.encode(ambData),req_.superformsData.superformIds,msg.sender,req_.ambIds,1,vars.srcChainId,req_.dstChainId,vars.currentPayloadId))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L475-L487)
		- [IBaseStateRegistry(superRegistry.getAddress(keccak256(bytes)(CORE_STATE_REGISTRY))).dispatchPayload{value: fees}(vars_.srcSender,vars_.ambIds,vars_.dstChainId,abi.encode(ambMessage),extraData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L546-L548)
	Event emitted after the call(s):
	- [CrossChainInitiatedWithdrawMulti(vars.currentPayloadId,req_.dstChainId,req_.superformsData.superformIds,req_.ambIds)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L489-L491)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L443-L492


 - [ ] ID-177
Reentrancy in [SuperformFactory.changeFormImplementationPauseStatus(uint32,ISuperformFactory.PauseStatus,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L240-L265):
	External calls:
	- [_broadcast(abi.encode(factoryPayload),extraData_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L261)
		- [IBroadcastRegistry(superRegistry.getAddress(keccak256(bytes)(BROADCAST_REGISTRY))).broadcastPayload{value: msg.value}(msg.sender,ambId,message_,broadcastParams)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L288-L290)
	Event emitted after the call(s):
	- [FormImplementationPaused(formImplementationId_,status_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L264)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L240-L265


 - [ ] ID-178
Reentrancy in [SuperPositions._registerSERC20(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L344-L373):
	External calls:
	- [_broadcast(abi.encode(transmuterPayload))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L368)
		- [IBroadcastRegistry(superRegistry.getAddress(keccak256(bytes)(BROADCAST_REGISTRY))).broadcastPayload{value: msg.value}(msg.sender,ambId,message_,broadcastParams)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L389-L391)
	Event emitted after the call(s):
	- [SyntheticTokenRegistered(id,syntheticToken)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L370)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperPositions.sol#L344-L373


 - [ ] ID-179
Reentrancy in [SuperformFactory.createSuperform(uint32,address)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L197-L237):
	External calls:
	- [BaseForm(address(superform_)).initialize(address(superRegistry),vault_,address(IERC4626(vault_).asset()))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L221)
	Event emitted after the call(s):
	- [SuperformCreated(formImplementationId_,vault_,superformId_,superform_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L236)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L197-L237


 - [ ] ID-180
Reentrancy in [BaseRouterImplementation._singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L411-L440):
	External calls:
	- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnBatch(msg.sender,req_.superformData.superformIds,req_.superformData.amounts)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L421-L423)
	- [_directMultiWithdraw(vaultData,msg.sender)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L438)
		- [IBaseForm(superform_).directWithdrawFromVault(InitSingleVaultData(payloadId_,superformId_,amount_,maxSlippage_,liqData_,false,false,receiverAddress_,extraFormData_),srcSender_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L701-L714)
	Event emitted after the call(s):
	- [Completed()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L439)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L411-L440


 - [ ] ID-181
Reentrancy in [LayerzeroImplementation._blockingLzReceive(uint16,bytes,uint64,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L337-L353):
	External calls:
	- [this.nonblockingLzReceive(srcChainId_,srcAddress_,payload_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L346-L352)
	Event emitted after the call(s):
	- [MessageFailed(srcChainId_,srcAddress_,nonce_,payload_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L351)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L337-L353


 - [ ] ID-182
Reentrancy in [ERC4626FormImplementation._processXChainDeposit(InitSingleVaultData,uint64)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L246-L273):
	External calls:
	- [IERC20(asset).safeTransferFrom(msg.sender,address(this),singleVaultData_.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L259)
	- [IERC20(asset).safeIncreaseAllowance(vaultLoc,singleVaultData_.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L262)
	- [dstAmount = v.deposit(singleVaultData_.amount,singleVaultData_.receiverAddress)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L266)
	- [dstAmount = v.deposit(singleVaultData_.amount,address(this))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L269)
	Event emitted after the call(s):
	- [Processed(srcChainId_,dstChainId,singleVaultData_.payloadId,singleVaultData_.amount,vaultLoc)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L272)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L246-L273


 - [ ] ID-183
Reentrancy in [SuperformRouter.multiDstMultiVaultWithdraw(MultiDstMultiVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L188-L208):
	External calls:
	- [_singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq(req_.superformsData[i]))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L199)
		- [IBaseForm(superform_).directWithdrawFromVault(InitSingleVaultData(payloadId_,superformId_,amount_,maxSlippage_,liqData_,false,false,receiverAddress_,extraFormData_),srcSender_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L701-L714)
		- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnBatch(msg.sender,req_.superformData.superformIds,req_.superformData.amounts)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L421-L423)
	- [_singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq(req_.ambIds[i],req_.dstChainIds[i],req_.superformsData[i]))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L201-L203)
		- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).updateTxHistory(vars_.currentPayloadId,ambMessage.txInfo)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L541-L543)
		- [IBaseStateRegistry(superRegistry.getAddress(keccak256(bytes)(CORE_STATE_REGISTRY))).dispatchPayload{value: fees}(vars_.srcSender,vars_.ambIds,vars_.dstChainId,abi.encode(ambMessage),extraData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L546-L548)
		- [ISuperPositions(superRegistry.getAddress(keccak256(bytes)(SUPER_POSITIONS))).burnBatch(msg.sender,req_.superformsData.superformIds,req_.superformsData.amounts)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L456-L458)
	External calls sending eth:
	- [_singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq(req_.ambIds[i],req_.dstChainIds[i],req_.superformsData[i]))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L201-L203)
		- [IBaseStateRegistry(superRegistry.getAddress(keccak256(bytes)(CORE_STATE_REGISTRY))).dispatchPayload{value: fees}(vars_.srcSender,vars_.ambIds,vars_.dstChainId,abi.encode(ambMessage),extraData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L546-L548)
	Event emitted after the call(s):
	- [Completed()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L439)
		- [_singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq(req_.superformsData[i]))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L199)
	- [CrossChainInitiatedWithdrawMulti(vars.currentPayloadId,req_.dstChainId,req_.superformsData.superformIds,req_.ambIds)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L489-L491)
		- [_singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq(req_.ambIds[i],req_.dstChainIds[i],req_.superformsData[i]))](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L201-L203)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformRouter.sol#L188-L208


 - [ ] ID-184
Reentrancy in [EmergencyQueue._executeQueuedWithdrawal(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L118-L132):
	External calls:
	- [IBaseForm(superform).emergencyWithdraw(data.srcSender,data.refundAddress,data.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L129)
	Event emitted after the call(s):
	- [WithdrawalProcessed(data.refundAddress,id_,data.superformId,data.amount)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L131)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/EmergencyQueue.sol#L118-L132


 - [ ] ID-185
Reentrancy in [ERC4626FormImplementation._processEmergencyWithdraw(address,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L401-L410):
	External calls:
	- [vaultContract.safeTransfer(refundAddress_,amount_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L408)
	Event emitted after the call(s):
	- [EmergencyWithdrawalProcessed(refundAddress_,amount_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L409)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/forms/ERC4626FormImplementation.sol#L401-L410


 - [ ] ID-186
Reentrancy in [CoreStateRegistry.finalizeRescueFailedDeposits(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L312):
	External calls:
	- [dstSwapper.processFailedTx(failedDeposits_.refundAddress,failedDeposits_.settlementToken[i],failedDeposits_.amounts[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L300-L302)
	- [IERC20(failedDeposits_.settlementToken[i]).safeTransfer(failedDeposits_.refundAddress,failedDeposits_.amounts[i])](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L304-L306)
	Event emitted after the call(s):
	- [RescueFinalized(payloadId_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L311)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L312


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-187
[LiFiTxDataExtractor._slice(bytes,uint256,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/lifi/LiFiTxDataExtractor.sol#L49-L106) uses assembly
	- [INLINE ASM](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/lifi/LiFiTxDataExtractor.sol#L55-L103)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/lifi/LiFiTxDataExtractor.sol#L49-L106


## costly-loop
Impact: Informational
Confidence: Medium
 - [ ] ID-188
[BaseRouterImplementation._singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L128-L205) has costly operations inside a loop:
	- [vars.currentPayloadId = ++ payloadIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L149)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L128-L205


 - [ ] ID-189
[BaseRouterImplementation._singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L345-L408) has costly operations inside a loop:
	- [vars.currentPayloadId = ++ payloadIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L373)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L345-L408


 - [ ] ID-190
[BaseRouterImplementation._singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L232-L301) has costly operations inside a loop:
	- [vars.currentPayloadId = ++ payloadIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L243)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L232-L301


 - [ ] ID-191
[BaseRouterImplementation._singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L443-L492) has costly operations inside a loop:
	- [vars.currentPayloadId = ++ payloadIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L460)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L443-L492


## cyclomatic-complexity
Impact: Informational
Confidence: High
 - [ ] ID-192
[BaseRouterImplementation._multiVaultTokenForward(address,address[],bytes,InitMultiVaultData,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L953-L1051) has a high cyclomatic complexity (12).

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L953-L1051


 - [ ] ID-193
[LiFiValidator.validateTxData(IBridgeValidator.ValidateTxDataArgs)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L31-L118) has a high cyclomatic complexity (17).

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L31-L118


 - [ ] ID-194
[PaymentHelper.updateRemoteChain(uint64,uint256,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L461-L526) has a high cyclomatic complexity (12).

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PaymentHelper.sol#L461-L526


## dead-code
Impact: Informational
Confidence: Medium
 - [ ] ID-195
[StandardHookMetadata.formatMetadata(uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L94-L96) is never used and should be removed

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L94-L96


 - [ ] ID-196
[StandardHookMetadata.gasLimit(bytes,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L42-L45) is never used and should be removed

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L42-L45


 - [ ] ID-197
[fromWormholeFormatUnchecked(bytes32)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/wormhole/Utils.sol#L16-L18) is never used and should be removed

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/wormhole/Utils.sol#L16-L18


 - [ ] ID-198
[StandardHookMetadata.getCustomMetadata(bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L63-L66) is never used and should be removed

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L63-L66


 - [ ] ID-199
[StandardHookMetadata.refundAddress(bytes,address)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L53-L56) is never used and should be removed

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L53-L56


 - [ ] ID-200
[StandardHookMetadata.msgValue(bytes,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L31-L34) is never used and should be removed

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L31-L34


 - [ ] ID-201
[StandardHookMetadata.variant(bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L20-L23) is never used and should be removed

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/hyperlane/StandardHookMetadata.sol#L20-L23


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-202
Low level call in [LiquidityHandler._dispatchTokens(address,bytes,address,uint256,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/LiquidityHandler.sol#L33-L56):
	- [(success) = address(bridge_).call{value: nativeAmount_}(txData_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/LiquidityHandler.sol#L54)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/LiquidityHandler.sol#L33-L56


 - [ ] ID-203
Low level call in [WormholeSRImplementation.broadcastPayload(address,bytes,bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L145-L179):
	- [(success) = address(relayer).call{value: msg.value - msgFee}()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L174)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L145-L179


 - [ ] ID-204
Low level call in [DstSwapper.processFailedTx(address,address,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L231-L247):
	- [(success) = address(user_).call{value: amount_}()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L244)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/DstSwapper.sol#L231-L247


 - [ ] ID-205
Low level call in [PayMaster._withdrawNative(address,uint256)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L111-L119):
	- [(success) = address(receiver_).call{value: amount_}()](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L112)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/payments/PayMaster.sol#L111-L119


## similar-names
Impact: Informational
Confidence: Medium
 - [ ] ID-206
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [ILayerZeroEndpoint.getInboundNonce(uint16,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroEndpoint.sol#L49)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-207
Variable [BaseRouterImplementation._directDeposit(address,uint256,uint256,uint256,uint256,bool,LiqRequest,address,bytes,uint256,address).superformId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L559) is too similar to [BaseRouterImplementation._singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq).superformIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L387)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L559


 - [ ] ID-208
Variable [BaseRouterImplementation._directWithdraw(address,uint256,uint256,uint256,uint256,LiqRequest,address,bytes,address).superformId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L689) is too similar to [BaseRouterImplementation._singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq).superformIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L387)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L689


 - [ ] ID-209
Variable [TimelockStateRegistry.processPayload(uint256)._payloadHeader](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L217) is too similar to [IBaseStateRegistry.payloadHeader(uint256).payloadHeader_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/IBaseStateRegistry.sol#L49)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L217


 - [ ] ID-210
Variable [SuperRegistry.setBridgeAddresses(uint8[],address[],address[]).bridgeValidatorT](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/settings/SuperRegistry.sol#L277) is too similar to [ISuperRegistry.setBridgeAddresses(uint8[],address[],address[]).bridgeValidator_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/ISuperRegistry.sol#L203)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/settings/SuperRegistry.sol#L277


 - [ ] ID-211
Variable [BaseRouterImplementation._validateSuperformData(uint256,uint256,uint256,address,uint64,bool,ISuperformFactory).superformId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L764) is too similar to [BaseRouterImplementation._singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq).superformIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L184)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L764


 - [ ] ID-212
Variable [LayerzeroImplementation._nonblockingLzReceive(uint16,bytes,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305) is too similar to [LayerzeroImplementation.setTrustedRemote(uint16,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L149)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305


 - [ ] ID-213
Variable [SuperRegistry.setBridgeAddresses(uint8[],address[],address[]).bridgeValidatorT](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/settings/SuperRegistry.sol#L277) is too similar to [SuperRegistry.setBridgeAddresses(uint8[],address[],address[]).bridgeValidator_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/settings/SuperRegistry.sol#L265)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/settings/SuperRegistry.sol#L277


 - [ ] ID-214
Variable [SuperformFactory.addFormImplementation(address,uint32).formImplementation_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L172) is too similar to [SuperformFactory.formImplementations](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L42)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L172


 - [ ] ID-215
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [ILayerZeroEndpoint.getOutboundNonce(uint16,address).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroEndpoint.sol#L53)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-216
Variable [SuperformFactory.addFormImplementation(address,uint32).formImplementation_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L172) is too similar to [SuperformFactory.createSuperform(uint32,address).tFormImplementation](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L207)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L172


 - [ ] ID-217
Variable [LayerzeroImplementation._nonblockingLzReceive(uint16,bytes,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305) is too similar to [LayerzeroImplementation.retryMessage(uint16,bytes,uint64,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L275)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305


 - [ ] ID-218
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.nonblockingLzReceive(uint16,bytes,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L265)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-219
Variable [CoreStateRegistry._updateSingleDeposit(uint256,bytes,uint256).finalAmount_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L460) is too similar to [CoreStateRegistry._updateMultiDeposit(uint256,bytes,uint256[]).finalAmounts](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L430)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L460


 - [ ] ID-220
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [ILayerZeroEndpoint.retryPayload(uint16,bytes,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroEndpoint.sol#L79)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-221
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.nonblockingLzReceive(uint16,bytes,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L265)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-222
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14) is too similar to [LayerzeroImplementation.setTrustedRemote(uint16,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L149)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14


 - [ ] ID-223
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.lzReceive(uint16,bytes,uint64,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L236)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-224
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13) is too similar to [LayerzeroImplementation.nonblockingLzReceive(uint16,bytes,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L265)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13


 - [ ] ID-225
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.isTrustedRemote(uint16,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L158)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-226
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [ILayerZeroEndpoint.receivePayload(uint16,bytes,address,uint64,uint256,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroEndpoint.sol#L38)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-227
Variable [BaseRouterImplementation._directDeposit(address,uint256,uint256,uint256,uint256,bool,LiqRequest,address,bytes,uint256,address).superformId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L559) is too similar to [BaseRouterImplementation._singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq).superformIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L184)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L559


 - [ ] ID-228
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14) is too similar to [LayerzeroImplementation.isTrustedRemote(uint16,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L158)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14


 - [ ] ID-229
Variable [ISuperformFactory.addFormImplementation(address,uint32).formImplementation_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/ISuperformFactory.sol#L102) is too similar to [SuperformFactory.createSuperform(uint32,address).tFormImplementation](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L207)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/ISuperformFactory.sol#L102


 - [ ] ID-230
Variable [SuperRegistry.setBridgeAddresses(uint8[],address[],address[]).bridgeValidatorT](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/settings/SuperRegistry.sol#L277) is too similar to [ISuperRegistry.getBridgeValidator(uint8).bridgeValidator_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/ISuperRegistry.sol#L128)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/settings/SuperRegistry.sol#L277


 - [ ] ID-231
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.forceResumeReceive(uint16,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L144)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-232
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13) is too similar to [LayerzeroImplementation.setTrustedRemote(uint16,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L149)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13


 - [ ] ID-233
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [ILayerZeroEndpoint.receivePayload(uint16,bytes,address,uint64,uint256,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroEndpoint.sol#L37)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-234
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14) is too similar to [LayerzeroImplementation.forceResumeReceive(uint16,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L144)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14


 - [ ] ID-235
Variable [SuperRegistry.setBridgeAddresses(uint8[],address[],address[]).bridgeValidatorT](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/settings/SuperRegistry.sol#L277) is too similar to [SuperRegistry.getBridgeValidator(uint8).bridgeValidator_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/settings/SuperRegistry.sol#L145)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/settings/SuperRegistry.sol#L277


 - [ ] ID-236
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.isTrustedRemote(uint16,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L158)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-237
Variable [ISuperformFactory.addFormImplementation(address,uint32).formImplementation_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/ISuperformFactory.sol#L102) is too similar to [SuperformFactory.formImplementations](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L42)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/ISuperformFactory.sol#L102


 - [ ] ID-238
Variable [ISuperformFactory.getFormImplementation(uint32).formImplementation_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/ISuperformFactory.sol#L59) is too similar to [SuperformFactory.formImplementations](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L42)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/ISuperformFactory.sol#L59


 - [ ] ID-239
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [ILayerZeroEndpoint.getInboundNonce(uint16,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroEndpoint.sol#L49)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-240
Variable [CoreStateRegistry._getSuperform(uint256).superformId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L319) is too similar to [CoreStateRegistry.getFailedDeposits(uint256).superformIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L72)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L319


 - [ ] ID-241
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [ILayerZeroEndpoint.hasStoredPayload(uint16,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroEndpoint.sol#L84)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-242
Variable [ILayerZeroUserApplicationConfig.setConfig(uint16,uint16,uint256,bytes)._configType](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L12) is too similar to [ILayerZeroEndpoint.getConfig(uint16,uint16,address,uint256).configType_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroEndpoint.sol#L111)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L12


 - [ ] ID-243
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.setTrustedRemote(uint16,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L149)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-244
Variable [CoreStateRegistry._updateAmount(IDstSwapper,bool,uint256,uint256,uint256,uint256,uint256,uint256,PayloadState,uint256).superformId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L495) is too similar to [CoreStateRegistry.getFailedDeposits(uint256).superformIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L72)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L495


 - [ ] ID-245
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation._blockingLzReceive(uint16,bytes,uint64,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L339)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-246
Variable [CoreStateRegistry._singleReturnData(address,uint256,TransactionType,CallbackType,uint256,uint256).superformId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L938) is too similar to [CoreStateRegistry.getFailedDeposits(uint256).superformIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L72)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L938


 - [ ] ID-247
Variable [LayerzeroImplementation._nonblockingLzReceive(uint16,bytes,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305) is too similar to [LayerzeroImplementation.forceResumeReceive(uint16,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L144)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305


 - [ ] ID-248
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13) is too similar to [LayerzeroImplementation.forceResumeReceive(uint16,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L144)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13


 - [ ] ID-249
Variable [LayerzeroImplementation._nonblockingLzReceive(uint16,bytes,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305) is too similar to [LayerzeroImplementation.isTrustedRemote(uint16,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L158)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305


 - [ ] ID-250
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14) is too similar to [LayerzeroImplementation.nonblockingLzReceive(uint16,bytes,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L265)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14


 - [ ] ID-251
Variable [ILayerZeroUserApplicationConfig.setConfig(uint16,uint16,uint256,bytes)._configType](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L12) is too similar to [LayerzeroImplementation.getConfig(uint16,uint16,address,uint256).configType_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L110)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L12


 - [ ] ID-252
Variable [TimelockStateRegistry.processPayload(uint256)._payloadBody](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L218) is too similar to [IBaseStateRegistry.payloadBody(uint256).payloadBody_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/IBaseStateRegistry.sol#L44)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/TimelockStateRegistry.sol#L218


 - [ ] ID-253
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.retryMessage(uint16,bytes,uint64,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L275)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-254
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [ILayerZeroEndpoint.hasStoredPayload(uint16,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroEndpoint.sol#L84)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-255
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13) is too similar to [LayerzeroImplementation.isTrustedRemote(uint16,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L158)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13


 - [ ] ID-256
Variable [ILayerZeroUserApplicationConfig.setConfig(uint16,uint16,uint256,bytes)._configType](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L12) is too similar to [LayerzeroImplementation.setConfig(uint16,uint16,uint256,bytes).configType_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L123)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L12


 - [ ] ID-257
Variable [LayerzeroImplementation._nonblockingLzReceive(uint16,bytes,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305) is too similar to [LayerzeroImplementation.lzReceive(uint16,bytes,uint64,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L236)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305


 - [ ] ID-258
Variable [LayerzeroImplementation._nonblockingLzReceive(uint16,bytes,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305) is too similar to [LayerzeroImplementation.nonblockingLzReceive(uint16,bytes,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L265)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305


 - [ ] ID-259
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [ILayerZeroEndpoint.retryPayload(uint16,bytes,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroEndpoint.sol#L79)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-260
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.retryMessage(uint16,bytes,uint64,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L276)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-261
Variable [BaseRouterImplementation._validateSuperformData(uint256,uint256,uint256,address,uint64,bool,ISuperformFactory).superformId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L764) is too similar to [BaseRouterImplementation._singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq).superformIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L387)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L764


 - [ ] ID-262
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation._blockingLzReceive(uint16,bytes,uint64,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L338)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-263
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13) is too similar to [LayerzeroImplementation._blockingLzReceive(uint16,bytes,uint64,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L338)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13


 - [ ] ID-264
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.lzReceive(uint16,bytes,uint64,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L237)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-265
Variable [ISuperformFactory.getFormImplementation(uint32).formImplementation_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/ISuperformFactory.sol#L59) is too similar to [SuperformFactory.createSuperform(uint32,address).tFormImplementation](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L207)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/interfaces/ISuperformFactory.sol#L59


 - [ ] ID-266
Variable [CoreStateRegistry._updateAmount(IDstSwapper,bool,uint256,uint256,uint256,uint256,uint256,uint256,PayloadState,uint256).hasDstSwap_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L491) is too similar to [CoreStateRegistry._updateMultiDeposit(uint256,bytes,uint256[]).hasDstSwaps](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L432)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L491


 - [ ] ID-267
Variable [BaseRouterImplementation._directWithdraw(address,uint256,uint256,uint256,uint256,LiqRequest,address,bytes,address).superformId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L689) is too similar to [BaseRouterImplementation._singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq).superformIds](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L184)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/BaseRouterImplementation.sol#L689


 - [ ] ID-268
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14) is too similar to [LayerzeroImplementation.lzReceive(uint16,bytes,uint64,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L237)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14


 - [ ] ID-269
Variable [LayerzeroImplementation._nonblockingLzReceive(uint16,bytes,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305) is too similar to [LayerzeroImplementation._blockingLzReceive(uint16,bytes,uint64,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L338)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305


 - [ ] ID-270
Variable [CoreStateRegistry._updateAmount(IDstSwapper,bool,uint256,uint256,uint256,uint256,uint256,uint256,PayloadState,uint256).finalAmount_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L494) is too similar to [CoreStateRegistry._updateMultiDeposit(uint256,bytes,uint256[]).finalAmounts](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L430)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/extensions/CoreStateRegistry.sol#L494


 - [ ] ID-271
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14) is too similar to [LayerzeroImplementation._blockingLzReceive(uint16,bytes,uint64,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L339)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14


 - [ ] ID-272
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13) is too similar to [LayerzeroImplementation.lzReceive(uint16,bytes,uint64,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L236)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13


 - [ ] ID-273
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.forceResumeReceive(uint16,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L144)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


 - [ ] ID-274
Variable [SuperformFactory.formImplementations](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L42) is too similar to [SuperformFactory.createSuperform(uint32,address).tFormImplementation](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L207)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L42


 - [ ] ID-275
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14) is too similar to [LayerzeroImplementation.retryMessage(uint16,bytes,uint64,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L276)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L14


 - [ ] ID-276
Variable [ILayerZeroReceiver.lzReceive(uint16,bytes,uint64,bytes)._srcChainId](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13) is too similar to [LayerzeroImplementation.retryMessage(uint16,bytes,uint64,bytes).srcChainId_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L275)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroReceiver.sol#L13


 - [ ] ID-277
Variable [ILayerZeroUserApplicationConfig.forceResumeReceive(uint16,bytes)._srcAddress](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25) is too similar to [LayerzeroImplementation.setTrustedRemote(uint16,bytes).srcAddress_](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L149)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol#L25


## unused-state
Impact: Informational
Confidence: High
 - [ ] ID-278
[SuperformFactory.PAUSED](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L28) is never used in [SuperformFactory](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L20-L305)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L28


 - [ ] ID-279
[BridgeValidator.NATIVE](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/BridgeValidator.sol#L15) is never used in [SocketOneInchValidator](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/socket/SocketOneInchValidator.sol#L11-L97)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/BridgeValidator.sol#L15


 - [ ] ID-280
[BridgeValidator.NATIVE](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/BridgeValidator.sol#L15) is never used in [SocketValidator](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/socket/SocketValidator.sol#L11-L119)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/BridgeValidator.sol#L15


 - [ ] ID-281
[SuperformFactory.NON_PAUSED](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L27) is never used in [SuperformFactory](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L20-L305)

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/SuperformFactory.sol#L27


## var-read-using-this
Impact: Optimization
Confidence: High
 - [ ] ID-282
The function [LiFiValidator.decodeSwapOutputToken(bytes)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L156-L174) reads [() = this.extractMainParameters(txData_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L157-L173) with `this` which adds an extra STATICCALL.

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L156-L174


 - [ ] ID-283
The function [LiFiValidator.decodeAmountIn(bytes,bool)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L121-L149) reads [(amount) = this.extractMainParameters(txData_)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L130-L148) with `this` which adds an extra STATICCALL.

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L121-L149


 - [ ] ID-284
The function [LiFiValidator.validateTxData(IBridgeValidator.ValidateTxDataArgs)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L31-L118) reads [(sendingAssetId,receiver,destinationChainId,hasDestinationCall) = this.extractMainParameters(args_.txData)](https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L37-L117) with `this` which adds an extra STATICCALL.

https://github.com/superform-xyz/superform-core/blob/67aa2983c012cc0b8382313478cd14254401d4ae/src/crosschain-liquidity/lifi/LiFiValidator.sol#L31-L118


