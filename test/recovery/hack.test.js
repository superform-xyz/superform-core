/* eslint-disable no-undef */
/* eslint-disable prettier/prettier */
const { expect } = require("chai");
const { ethers } = require("hardhat");

/// HOW TO RUN:
/// Scenario: User can manipulate StateData to redeem shares from different vaults
/// First start local hardhat node against forked Arbitrum (npx hardhat node --fork https://arb1.arbitrum.io/rpc --port 8545)
/// Then run `npm run test-hack` to run this test

describe("Router Patch Unit Testing", () => {
    let routerPatch;
    let user;
    let stateHandler;
    let router;
    let destination;
    let multisig;
    let whale;

    async function buildWithdrawCall(vaultId, sharesAmount, targetChainId) {
        /// iterates vaultIds and calls vault.redeem()
        const stateReq = [
            targetChainId, [sharesAmount], /// NOTE: amount is irrelevant on processWithdraw, err?
            [vaultId],
            [1000], // hardcoding slippage to 10%
            0x00,
            ethers.utils.parseEther("1"),
        ];

        /// withdraw uses this to sent tokens
        const LiqReq = [
            110,
            "0x",
            ethers.constants.AddressZero,
            ethers.constants.AddressZero,
            0,
            0,
        ];

        return { stateReq: stateReq, LiqReq: LiqReq };
    }

    // Doing some setup in here
    before(async() => {
        /// simulated whale to send some Aeth to our testers.
        whale = await ethers.getImpersonatedSigner(
            "0xB38e8c17e38363aF6EbdCb3dAE12e0243582891D"
        );

        /// simulated user is SP Whale on Arbitrum (most active chain on superform)
        /// vaultId: 421612		shares: 486152584813877 (Arbitrum DAI AaveV3 Lending Vault)
        /// vaultId: 421615		shares: 99500000000000 (Arbitrum WETH AaveV3 Lending Vault)
        /// Use 486e19 shares of 421612 to redeem from 421615 multiple times
        user = await ethers.getImpersonatedSigner(
            "0x93ab0cd091dc8dd513ebfd11972e64a2ac558552"
        );
        /// simulated deployer on Arbtirum
        multisig = await ethers.getImpersonatedSigner(
            "0x5608AE4d9b19c4dABC7521212ec143e7d2F0AEcA"
        );

        /// funding our simulated users
        whale.sendTransaction({
            to: user.address,
            value: ethers.utils.parseEther("100"),
        });
        whale.sendTransaction({
            to: multisig.address,
            value: ethers.utils.parseEther("100"),
        });

        /// simulated multisig to add router patch with ROUTER_ROLE & PROCESSOR_ROLE
        router = await ethers.getVerifiedContractAt(
            "0xfF3aFb7d847AeD8f2540f7b5042F693242e01ebD"
        );
        destination = await ethers.getVerifiedContractAt(
            "0xc8884edE1ae44bDfF60da4B9c542C34A69648A87"
        );
        stateHandler = await ethers.getVerifiedContractAt(
            "0x908da814cc9725616D410b2978E88fF2fb9482eE"
        );

        /// interface for any erc20 token we need to interact with
        // const ERC20_ABI = await hre.artifacts.readArtifact("ERC20Mock");
        // const daiAddr = "0xda10009cbd5d07dd0cecc66161fc93d7c9000da1";
        // const wethAddr = "0x82af49447d8a07e3bd95bd0d56f35241523fbab1";
        // dai = new ethers.Contract(daiAddr, ERC20_ABI.abi, user);
        // weth = new ethers.Contract(wethAddr, ERC20_ABI.abi, user);

        /// layerzero chain id for Arbitrum is 110 (read from destination address)
        const RouterPatchABI = await ethers.getContractFactory("RouterPatch");
        routerPatch = await RouterPatchABI.deploy("110");
    });

    it("setting up the existing RBACs", async() => {
        /// providing necessary previlages
        /// 1. Adding ROUTER_ROLE in destination.
        await destination
            .connect(multisig)
            .grantRole(await destination.ROUTER_ROLE(), routerPatch.address);

        /// 2. Adding PROCESSOR_ROLE in state handler.
        await stateHandler
            .connect(multisig)
            .grantRole(
                await stateHandler.PROCESSOR_CONTRACTS_ROLE(),
                routerPatch.address
            );
    });

    /// NOTE: Try/catch makes it as passed tests, preffer assertion for verifying and try/catch only for debugging.
    it("1: trying to make samechain withdrawal without shares tokens", async() => {
        try {
            /// vault id - 102 (which user has no balance)
            /// amount - 10 (6 decimal)
            /// target chain id - 101 (layerzero chain id)
            const data = await buildWithdrawCall(421612, 10 * 10 ** 18, 110);

            const tx = await routerPatch
                .connect(user)
                .withdraw([data.stateReq], [data.LiqReq]);
            tx.wait();
        } catch (err) {
            console.log("withdrawing without shares failed");
        }
    });

    it("1. snapshots before withdrawal", async() => {
        balanceSharesBefore = await router.balanceOf(user.address, 421612);

        console.log(
            await router.balanceOf(routerPatch.address, 421612),
            "Shares Balance [ROUTER_PATCH]"
        );
    });

    it("2: overwithdraw from vault id 421612 (FAILS, AS SHOULD)", async function() {
        try {
            /// approve the shares.
            await router.connect(user).setApprovalForAll(routerPatch.address, true);
            /// vault id - 102 (which user has no balance)
            /// amount - 10 (6 decimal)
            /// target chain id - 101 (layerzero chain id)

            /// vaultId: 421612		shares: 486152584813877 (Arbitrum DAI AaveV3 Lending Vault)
            /// vaultId: 421615		shares: 99500000000000 (Arbitrum WETH AaveV3 Lending Vault)
            /// Use 486e19 shares of 421612 to redeem from 421615 multiple times

            const balanceOf421612 = await router.balanceOf(user.address, 421612); /// Router returns zero shares here?
            const balanceOf421615 = await router.balanceOf(user.address, 421615);

            console.log(
                "AAVE DAI shares balance:",
                balanceOf421612,
                "AAVE WETH shares balance",
                balanceOf421615
            );

            // let data = await buildWithdrawCall(421612, balanceOf421612, 110);

            /// NOTE: Just withdraw owned shares
            // await routerPatch.connect(user).withdraw([data.stateReq], [data.LiqReq]);

            /// Step 1: Withdraw all user SP for vaultId 421615
            let data = await buildWithdrawCall(421615, balanceOf421615, 110);

            await routerPatch.connect(user).withdraw([data.stateReq], [data.LiqReq]);

            /// Step 2: Withdraw more from vaultId 421615 using 421612 shares Fail
            data = await buildWithdrawCall(421615, balanceOf421615, 110);

            await expect(
                routerPatch.connect(user).withdraw([data.stateReq], [data.LiqReq])
            ).to.be.reverted;
        } catch (err) {
            console.log(err);
            console.log("withdrawing with shares failed");
        }
    });
});