// /* eslint-disable prettier/prettier */
// const { expect } = require("chai")
// const { ethers } = require("hardhat")
// const USDC_ABI = require("./ABI/usdc.json")

// describe("Router Patch Unit Testing", () => {
//     let routerPatch
//     let user
//     let stateHandler
//     let router
//     let destination
//     let multisig
//     let whale
//     let usdc
//     let balanceUSDCBefore
//     let balanceSharesBefore
//     let balanceUSDCAfter
//     let balanceSharesAfter

//     async function buildWithdrawCall(
//         vaultId,
//         sharesAmount,
//         targetChainId
//     ) {
//         /// iterates vaultIds and calls vault.redeem()
//         const stateReq = [
//             targetChainId, [sharesAmount], /// amount is irrelevant on processWithdraw, err?
//             [vaultId],
//             [1000], // hardcoding slippage to 10%
//             0x00,
//             ethers.utils.parseEther("1"),
//         ];

//         /// withdraw uses this to sent tokens
//         const LiqReq = [1, "0x", ethers.constants.AddressZero, ethers.constants.AddressZero, 0, 0];

//         return { stateReq: stateReq, LiqReq: LiqReq };
//     }

//     // Doing some setup in here
//     before(async() => {
//         /// simulated whale to send some eth to our testers.
//         whale = await ethers.getImpersonatedSigner("0xcA8Fa8f0b631EcdB18Cda619C4Fc9d197c8aFfCa")
//             /// simulated user is blakerichardson.eth
//         user = await ethers.getImpersonatedSigner("0x1985df46791bebb1e3ed9ec60417f38cecc1d349")
//         multisig = await ethers.getImpersonatedSigner("0xDc7181e5ACa318C0a1787F0223353d1d3B2aEA0B")

//         /// funding our simulated users
//         whale.sendTransaction({ to: user.address, value: ethers.utils.parseEther("100") })
//         whale.sendTransaction({ to: multisig.address, value: ethers.utils.parseEther("100") })

//         /// simulated multisig to add router patch with ROUTER_ROLE & PROCESSOR_ROLE
//         router = await ethers.getVerifiedContractAt("0xfF3aFb7d847AeD8f2540f7b5042F693242e01ebD")
//         destination = await ethers.getVerifiedContractAt("0xc8884edE1ae44bDfF60da4B9c542C34A69648A87")
//         stateHandler = await ethers.getVerifiedContractAt("0x908da814cc9725616D410b2978E88fF2fb9482eE")

//         usdc = new ethers.Contract("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", USDC_ABI, user)

//         /// layerzero chain id for eth is 101
//         const RouterPatchABI = await ethers.getContractFactory("RouterPatch")
//         routerPatch = await RouterPatchABI.deploy("101")
//     })

//     it("setting up the existing RBACs", async() => {
//         /// providing necessary previlages
//         /// 1. Adding ROUTER_ROLE in destination.
//         await destination.connect(multisig).grantRole(await destination.ROUTER_ROLE(), routerPatch.address)

//         /// 2. Adding PROCESSOR_ROLE in state handler.
//         await stateHandler.connect(multisig).grantRole(await stateHandler.PROCESSOR_CONTRACTS_ROLE(), routerPatch.address)
//     })

//     // it("1: trying to make samechain withdrawal without shares tokens", async() => {
//     //     try {
//     //         /// vault id - 102 (which user has no balance)
//     //         /// amount - 10 (6 decimal)
//     //         /// target chain id - 101 (layerzero chain id)
//     //         const data = await buildWithdrawCall(12, 10 * 10 ** 6, 101)

//     //         const tx = await routerPatch.connect(user).withdraw([data.stateReq], [data.LiqReq])
//     //         tx.wait()
//     //     } catch (err) {
//     //         console.log("withdrawing without shares failed")
//     //     }
//     // })

//     it("2. snapshots before withdrawal", async() => {
//         balanceUSDCBefore = await usdc.balanceOf(user.address)
//         balanceSharesBefore = await router.balanceOf(user.address, 18)

//         console.log(await router.balanceOf(routerPatch.address, 18), "Shares Balance [ROUTER_PATCH]")
//     })

//     it("3: trying to make a samechain withdrawal with shares", async function() {
//         try {
//             /// approve the shares.
//             await router.connect(user).setApprovalForAll(routerPatch.address, true)
//                 /// vault id - 102 (which user has no balance)
//                 /// amount - 10 (6 decimal)
//                 /// target chain id - 101 (layerzero chain id)
//             const data = await buildWithdrawCall(18, balanceSharesBefore, 101)
//             await routerPatch.connect(user).withdraw([data.stateReq], [data.LiqReq])
//         } catch (err) {
//             console.log(err)
//             console.log("withdrawing with shares failed")
//         }
//     })

//     it("4. validation after successful withdrawal", async() => {
//         balanceUSDCAfter = await usdc.balanceOf(user.address)
//         balanceSharesAfter = await router.balanceOf(user.address, 18)

//         console.log(balanceSharesAfter, balanceUSDCAfter)
//         console.log(await router.balanceOf(routerPatch.address, 18), "Shares Balance [ROUTER_PATCH]")
//     })
// })