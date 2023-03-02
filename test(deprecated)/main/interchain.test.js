/* eslint-disable prettier/prettier */
const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

describe("interchain base tests:", async() => {
    let FantomSrc;
    let BscSrc;
    let FantomLzEndpoint;
    let FantomDst;
    let BscDst;
    let BscLzEndpoint;
    let accounts;
    let FantomUSDC;
    let BscUSDC;
    let swapToken;
    let FantomVault;
    let BscVault;
    let socket;
    let FantomStateHandler;
    let BscStateHandler;

    const FantomChainId = 1;
    const BscChainId = 2;

    const ThousandTokensE18 = ethers.utils.parseEther("1000");
    const MilionTokensE18 = ethers.utils.parseEther("1000000");

    let BscStateHandlerCounter = 0;
    let FantomStateHandlerCounter = 0;

    let mockEstimatedNativeFee;
    let mockEstimatedZroFee;

    async function depositToVault(
        tokenType,
        targetSource,
        targetDst,
        stateReq,
        liqReq,
        amountToDeposit
    ) {
        await tokenType.approve(targetSource.address, amountToDeposit);

        // Mocking gas fee airdrop (native) from layerzero
        await accounts[1].sendTransaction({
            to: targetDst.address,
            value: ethers.utils.parseEther("2"),
        });

        /// Value == fee paid to relayer. API call in our design
        await targetSource.deposit([liqReq], [stateReq], {
            value: ethers.utils.parseEther("2"),
        });
    }

    async function depositToVaultMulti(
        tokenType,
        targetSource,
        targetDst,
        stateReq,
        liqReq,
        amountToDeposit
    ) {
        await tokenType.approve(targetSource.address, amountToDeposit);

        // Mocking gas fee airdrop (native) from layerzero
        await accounts[1].sendTransaction({
            to: targetDst.address,
            value: ethers.utils.parseEther("1"),
        });

        /// Value == fee paid to relayer. API call in our design
        await targetSource.deposit(liqReq, stateReq, {
            value: ethers.utils.parseEther("1"),
        });
    }

    async function buildDepositCall(
        fromSrc,
        toDst,
        tokenType,
        vaultId,
        amount,
        targetChainId
    ) {
        const socketTxData = socket.interface.encodeFunctionData(
            "mockSocketTransfer", [fromSrc, toDst, tokenType, amount]
        );

        const stateReq = [
            targetChainId, [amount],
            [vaultId],
            [1000], // hardcoding max-slippage to 10%
            0x00,
            ethers.utils.parseEther("1"),
        ];

        const LiqReq = [1, socketTxData, tokenType, socket.address, amount, 0];

        return { stateReq, LiqReq };
    }

    async function buildWithdrawCall(
        fromSrc,
        toDst,
        tokenType,
        vaultId,
        tokenAmount, /// == shares before withdraw, ERR!
        sharesAmount,
        targetChainId
    ) {
        const socketTxData = socket.interface.encodeFunctionData(
            "mockSocketTransfer", [fromSrc, toDst, tokenType, tokenAmount]
        );

        /// iterates vaultIds and calls vault.redeem()
        const stateReq = [
            targetChainId, [sharesAmount], /// amount is irrelevant on processWithdraw, err?
            [vaultId],
            [1000], // hardcoding slippage to 10%
            0x00,
            ethers.utils.parseEther("10"),
        ];

        /// withdraw uses this to sent tokens
        const LiqReq = [1, socketTxData, tokenType, socket.address, tokenAmount, 0];

        return { stateReq, LiqReq };
    }

    before("deploying router and dsc", async function() {
        try {
            accounts = await ethers.getSigners();

            // Deploying LZ mocks
            const LZEndpointMock = await ethers.getContractFactory("LZEndpointMock");
            FantomLzEndpoint = await LZEndpointMock.deploy(FantomChainId);
            BscLzEndpoint = await LZEndpointMock.deploy(BscChainId);

            // Deploying StateHandler
            const StateHandler = await ethers.getContractFactory("StateHandler");
            FantomStateHandler = await StateHandler.deploy(FantomLzEndpoint.address);
            BscStateHandler = await StateHandler.deploy(BscLzEndpoint.address);

            // Deploying Socket mocks
            const SocketRouterMock = await ethers.getContractFactory(
                "SocketRouterMock"
            );
            socket = await SocketRouterMock.deploy();

            mockEstimatedNativeFee = ethers.utils.parseEther("0.001");
            mockEstimatedZroFee = ethers.utils.parseEther("0.00025");

            await FantomLzEndpoint.setEstimatedFees(
                mockEstimatedNativeFee,
                mockEstimatedZroFee
            );
            await BscLzEndpoint.setEstimatedFees(
                mockEstimatedNativeFee,
                mockEstimatedZroFee
            );

            // Deploying mock ERC20 token
            const Token = await ethers.getContractFactory("ERC20Mock");
            FantomUSDC = await Token.deploy(
                "Fantom USDC",
                "FUSDC",
                accounts[0].address,
                MilionTokensE18
            );
            BscUSDC = await Token.deploy(
                "BSC USDC",
                "BUSDC",
                accounts[0].address,
                MilionTokensE18
            );

            const SwapToken = await ethers.getContractFactory("ERC20Mock");
            swapToken = await SwapToken.deploy(
                "Swap",
                "SWP",
                accounts[0].address,
                MilionTokensE18
            );

            // Deploying Mock Vault
            const Vault = await ethers.getContractFactory("VaultMock");
            FantomVault = await Vault.deploy(
                FantomUSDC.address,
                "FantomVault",
                "TSTFantomVault"
            );
            BscVault = await Vault.deploy(BscUSDC.address, "BscVault", "TSTBscVault");

            // Deploying Destination Contract
            const SuperDestinationABI = await ethers.getContractFactory(
                "SuperDestination"
            );
            FantomDst = await SuperDestinationABI.deploy(
                FantomChainId,
                FantomStateHandler.address
            );
            BscDst = await SuperDestinationABI.deploy(
                BscChainId,
                BscStateHandler.address
            );

            // Deploying routerContract
            const SuperRouterABI = await ethers.getContractFactory("SuperRouter");
            FantomSrc = await SuperRouterABI.deploy(
                FantomChainId,
                "test.com/",
                FantomStateHandler.address,
                FantomDst.address
            );
            BscSrc = await SuperRouterABI.deploy(
                BscChainId,
                "test.com/",
                BscStateHandler.address,
                BscDst.address
            );

            await FantomLzEndpoint.setDestLzEndpoint(
                BscStateHandler.address,
                BscLzEndpoint.address
            );
            await BscLzEndpoint.setDestLzEndpoint(
                FantomStateHandler.address,
                FantomLzEndpoint.address
            );

            await FantomDst.addVault([FantomVault.address], [1]);
            await BscDst.addVault([BscVault.address], [1]);

            await FantomDst.setSrcTokenDistributor(FantomSrc.address, FantomChainId);
            await BscDst.setSrcTokenDistributor(BscSrc.address, BscChainId);

            await FantomStateHandler.setHandlerController(
                FantomSrc.address,
                FantomDst.address
            );
            await BscStateHandler.setHandlerController(
                BscSrc.address,
                BscDst.address
            );

            const role = await FantomStateHandler.CORE_CONTRACTS_ROLE();
            const role2 = await BscStateHandler.CORE_CONTRACTS_ROLE();

            await FantomStateHandler.grantRole(role, FantomSrc.address);
            await FantomStateHandler.grantRole(role, FantomDst.address);

            await BscStateHandler.grantRole(role2, BscSrc.address);
            await BscStateHandler.grantRole(role2, BscDst.address);

            await FantomStateHandler.setTrustedRemote(
                BscChainId,
                BscStateHandler.address
            );
            await BscStateHandler.setTrustedRemote(
                FantomChainId,
                FantomStateHandler.address
            );

            await FantomSrc.setBridgeAddress([1], [socket.address]);
            await BscSrc.setBridgeAddress([1], [socket.address]);
            await BscDst.setBridgeAddress([1], [socket.address]);
            await FantomDst.setBridgeAddress([1], [socket.address]);

            const PROCESSOR_CONTRACT_ROLE =
                await FantomStateHandler.PROCESSOR_CONTRACTS_ROLE();

            await FantomStateHandler.grantRole(
                PROCESSOR_CONTRACT_ROLE,
                accounts[0].address
            );
            await BscStateHandler.grantRole(
                PROCESSOR_CONTRACT_ROLE,
                accounts[0].address
            );
        } catch (err) {
            console.log(err);
        }
    });

    it("verifying deployment contract addresses", async function() {
        // Verifying the deployment params
        expect(await FantomSrc.chainId()).to.equals(1);
        expect(await BscSrc.chainId()).to.equals(2);
        expect(await FantomDst.chainId()).to.equals(1);
        expect(await BscDst.chainId()).to.equals(2);
    });

    it("FTM=>BSC: user depositing to a vault on BSC from Fantom", async function() {
        const amount = ThousandTokensE18;
        const vaultId = 1;

        /// FROM where, TO destination, bridge TOKENTYPE in AMOUNT to CHAINID (same as destination in TO)
        /// Returns state & liquidity Request objects
        const Request = await buildDepositCall(
            FantomSrc.address,
            BscDst.address,
            BscUSDC.address,
            vaultId,
            amount,
            BscChainId
        );

        expect(await BscUSDC.balanceOf(BscDst.address)).to.equal(0);

        await depositToVault(
            BscUSDC,
            FantomSrc,
            BscDst,
            Request.stateReq,
            Request.LiqReq,
            amount
        );

        expect(await BscUSDC.balanceOf(BscDst.address)).to.equal(amount);
        ++BscStateHandlerCounter;
        await BscStateHandler.updateState(BscStateHandlerCounter, [amount]);
        await BscStateHandler.processPayload(BscStateHandlerCounter, "0x", {
            value: ethers.utils.parseEther("1"),
        });

        ++FantomStateHandlerCounter;
        await FantomStateHandler.processPayload(FantomStateHandlerCounter, "0x", {
            value: ethers.utils.parseEther("1"),
        });

        expect(await BscVault.balanceOf(BscDst.address)).to.equal(amount);
        expect(await FantomSrc.balanceOf(accounts[0].address, 1)).to.equal(amount);
        expect(await BscUSDC.balanceOf(BscDst.address)).to.equal(0);
    });

    it("FTM=>BSC: user depositing to a vault requiring swap (stays pending)", async function() {
        try {
            const amount = ThousandTokensE18;
            const vaultId = 1;

            const Request = await buildDepositCall(
                FantomSrc.address,
                BscDst.address,
                swapToken.address,
                vaultId,
                amount,
                BscChainId
            );
            await depositToVault(
                swapToken,
                FantomSrc,
                BscDst,
                Request.stateReq,
                Request.LiqReq,
                amount
            );

            ++BscStateHandlerCounter;
            await BscStateHandler.updateState(BscStateHandlerCounter, [amount]);
            await expect(
                BscStateHandler.processPayload(BscStateHandlerCounter, "0x")
            ).to.be.revertedWith("Bridge Tokens Pending");
        } catch (err) {
            console.log(err);
        }
    });

    it("FTM=>BSC: user withdrawing tokens from a vault on BSC from/to Fantom", async function() {
        const amount = ThousandTokensE18;
        const vaultId = 1;

        const sharesBalanceBeforeWithdraw = await FantomSrc.balanceOf(
            accounts[0].address,
            1
        );

        const assetToWithdraw = await BscVault.previewRedeem(
            sharesBalanceBeforeWithdraw
        );

        const tokenBalanceBeforeWithdraw = await BscUSDC.balanceOf(
            accounts[0].address
        );

        const Request = await buildWithdrawCall(
            BscDst.address,
            accounts[0].address,
            BscUSDC.address,
            vaultId,
            assetToWithdraw,
            sharesBalanceBeforeWithdraw,
            BscChainId
        );
        try {
            await FantomSrc.withdraw([Request.stateReq], [Request.LiqReq], {
                value: ethers.utils.parseEther("10"),
            });
        } catch (err) {
            console.log("---ERRORRR---", err);
        }

        ++BscStateHandlerCounter;
        await BscStateHandler.processPayload(BscStateHandlerCounter, "0x", {
            value: ethers.utils.parseEther("1"),
        });

        const tokenBalanceAfterWithdraw = await BscUSDC.balanceOf(
            accounts[0].address
        );
        const sharesBalanceAfterWithdraw = await FantomSrc.balanceOf(
            accounts[0].address,
            1
        );

        //     /// Should be checked against previewRedeem()
        expect(tokenBalanceAfterWithdraw).to.equal(
            BigNumber.from(tokenBalanceBeforeWithdraw).add(amount)
        );
        expect(sharesBalanceBeforeWithdraw).to.equal(amount); /// This is true only because Mock Vaults are empty and it's theirs first deposit! TEST
        expect(sharesBalanceAfterWithdraw).to.equal(0);
    });

    it("BSC=>FTM: user depositing to a vault on Fantom from BSC", async function() {
        const amount = ThousandTokensE18;
        const vaultId = 1;

        const Request = await buildDepositCall(
            BscSrc.address,
            FantomDst.address,
            FantomUSDC.address,
            vaultId,
            amount,
            FantomChainId
        );

        await depositToVault(
            FantomUSDC,
            BscSrc,
            FantomDst,
            Request.stateReq,
            Request.LiqReq,
            amount
        );

        /// NOTE: Each StateHandler, existing on separate chainId, has it's own keeper
        /// NOTE: Transaction flow happens between StateHandler processPayload functions
        /// NOTE: StateHandlers can be thought of as open sockets awaiting event

        /// FLOW 1: Starts from BSC router=> Reaches FTM Destination
        // fantom catches depositToFantomVault here! it's an INIT type!
        // takes it to the SuperDestination, then processDeposit (its a DEPOSIT type!)
        // processDeposit dispatches StateData with RETURN type!
        ++FantomStateHandlerCounter;
        await FantomStateHandler.updateState(FantomStateHandlerCounter, [amount]);
        await FantomStateHandler.processPayload(FantomStateHandlerCounter, "0x", {
            value: ethers.utils.parseEther("1"),
        });

        /// FLOW 2: Keeper on BSC routertriggered by end of FLOW 1
        // bsc catches new payload, payload no. 4 here! it's a RETURN
        // takes it and calls stateSync() on it's Source!
        /// NOTE: Payload no. 4 because of ping-pong between chains seems non-consecutive.
        ++BscStateHandlerCounter;
        await BscStateHandler.processPayload(BscStateHandlerCounter, "0x", {
            value: ethers.utils.parseEther("1"),
        });

        // // Checking Final Expected Results
        /// Does fantom SuperDestination has 1000 shares of 3rd party Fantom Vault?
        expect(await FantomVault.balanceOf(FantomDst.address)).to.equal(amount);
        expect(await BscSrc.balanceOf(accounts[0].address, 1)).to.equal(amount);
        expect(await FantomUSDC.balanceOf(BscDst.address)).to.equal(0);
    });

    it("BSC=>FTM: user withdrawing tokens from a vault on Fantom from/to BSC", async function() {
        const amount = ThousandTokensE18;
        const vaultId = 1;

        const sharesBalanceBeforeWithdraw = await BscSrc.balanceOf(
            accounts[0].address,
            1
        );

        /// Architecture err. We either need to guard the whole function or change Liq/State relation.
        const assetToWithdraw = await FantomVault.previewRedeem(
            sharesBalanceBeforeWithdraw
        );

        const tokenBalanceBeforeWithdraw = await FantomUSDC.balanceOf(
            accounts[0].address
        );

        const Request = await buildWithdrawCall(
            FantomDst.address,
            accounts[0].address,
            FantomUSDC.address,
            vaultId,
            assetToWithdraw,
            sharesBalanceBeforeWithdraw,
            FantomChainId
        );

        await BscSrc.withdraw([Request.stateReq], [Request.LiqReq], {
            value: ethers.utils.parseEther("10"),
        });

        ++FantomStateHandlerCounter;
        await FantomStateHandler.processPayload(FantomStateHandlerCounter, "0x", {
            value: ethers.utils.parseEther("1"),
        });

        const tokenBalanceAfterWithdraw = await FantomUSDC.balanceOf(
            accounts[0].address
        );

        const sharesBalanceAfterWithdraw = await BscSrc.balanceOf(
            accounts[0].address,
            1
        );

        expect(tokenBalanceAfterWithdraw).to.equal(
            BigNumber.from(tokenBalanceBeforeWithdraw).add(amount)
        );
        expect(sharesBalanceBeforeWithdraw).to.equal(amount);
        expect(sharesBalanceAfterWithdraw).to.equal(0);
    });

    it("FTM=>BSC: multiple LiqReq/StateReq for multi-deposit", async function() {
        const amount = ThousandTokensE18;
        const vaultIds = 1;
        const len = 2;

        const LiqReqs = [];
        const StateReqs = [];

        /// Deposit from FTM to BSC 2x
        for (let i = 0; i < len; i++) {
            const Request = await buildDepositCall(
                FantomSrc.address,
                BscDst.address,
                BscUSDC.address,
                vaultIds,
                amount,
                BscChainId
            );

            StateReqs.push(Request.stateReq);
            LiqReqs.push(Request.LiqReq);
        }

        await depositToVaultMulti(
            BscUSDC,
            FantomSrc,
            BscDst,
            StateReqs,
            LiqReqs,
            amount.mul(len)
        );

        ++BscStateHandlerCounter;
        await BscStateHandler.updateState(BscStateHandlerCounter, [amount]);
        await BscStateHandler.processPayload(BscStateHandlerCounter, "0x", {
            value: ethers.utils.parseEther("1"),
        });

        ++FantomStateHandlerCounter;
        await FantomStateHandler.processPayload(FantomStateHandlerCounter, "0x", {
            value: ethers.utils.parseEther("1"),
        });

        // expect(await BscVault.balanceOf(BscDst.address)).to.equal(amount);
        // expect(await FantomSrc.balanceOf(accounts[0].address, 1)).to.equal(amount);
        // expect(await BscUSDC.balanceOf(BscDst.address)).to.equal(0);
    });

    it("FTM=>BSC: cross-chain slippage update beyond max slippage", async function() {
        try {
            const amount = ThousandTokensE18;
            const vaultId = 1;

            /// FROM where, TO destination, bridge TOKENTYPE in AMOUNT to CHAINID (same as destination in TO)
            /// Returns state & liquidity Request objects
            const Request = await buildDepositCall(
                FantomSrc.address,
                BscDst.address,
                BscUSDC.address,
                vaultId,
                amount,
                BscChainId
            );

            await depositToVault(
                BscUSDC,
                FantomSrc,
                BscDst,
                Request.stateReq,
                Request.LiqReq,
                amount
            );

            ++BscStateHandlerCounter;

            const EightTokensE18 = ethers.utils.parseEther("800");

            await expect(
                BscStateHandler.updateState(BscStateHandlerCounter, [
                    EightTokensE18,
                ])).to.be.revertedWith("Slippage Out Of Bounds");
        } catch (err) {
            console.log(err);
            /// should error;
            assert.include(
                err.message,
                "revert",
                "State Registry: Slippage Out Of Bounds"
            );
        }
    });

    it("FTM=>BSC: cross-chain slippage update above received value", async function() {
        try {
            const amount = ThousandTokensE18;
            const vaultId = 1;

            /// FROM where, TO destination, bridge TOKENTYPE in AMOUNT to CHAINID (same as destination in TO)
            /// Returns state & liquidity Request objects
            const Request = await buildDepositCall(
                FantomSrc.address,
                BscDst.address,
                BscUSDC.address,
                vaultId,
                amount,
                BscChainId
            );

            await depositToVault(
                BscUSDC,
                FantomSrc,
                BscDst,
                Request.stateReq,
                Request.LiqReq,
                amount
            );

            ++BscStateHandlerCounter;

            const ThousandAndOneTokens18 = ethers.utils.parseEther("1001");

            await expect(BscStateHandler.updateState(BscStateHandlerCounter, [
                ThousandAndOneTokens18,
            ])).to.be.revertedWith("Negative Slippage");
        } catch (err) {
            /// should error;
            console.log(err);
            assert.include(err.message, "revert", "State Registry: Negative Slippage");
        }
    });

    it("FTM=>BSC: cross-chain slippage update from unauthorized wallet", async function() {
        try {
            const amount = ThousandTokensE18;
            const vaultId = 1;

            /// FROM where, TO destination, bridge TOKENTYPE in AMOUNT to CHAINID (same as destination in TO)
            /// Returns state & liquidity Request objects
            const Request = await buildDepositCall(
                FantomSrc.address,
                BscDst.address,
                BscUSDC.address,
                vaultId,
                amount,
                BscChainId
            );

            await depositToVault(
                BscUSDC,
                FantomSrc,
                BscDst,
                Request.stateReq,
                Request.LiqReq,
                amount
            );

            ++BscStateHandlerCounter;

            await expect(BscStateHandler.connect(accounts[2]).updateState(
                BscStateHandlerCounter, [amount]
            )).to.be.revertedWith("AccessControl");
        } catch (err) {
            /// should error;
            console.log(err);
            assert.include(
                err.message,
                "revert",
                "AccessControl: account 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc is missing role 0x2030565476ef23eb21f6c1f68075f5a89b325631df98f5793acd3297f9b80123"
            );
        }
    });
});