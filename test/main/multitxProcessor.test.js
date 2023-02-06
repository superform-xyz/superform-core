/* eslint-disable prettier/prettier */
const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

describe("multi-tx processor tests:", async() => {
    let accounts;
    let multiTxProcessor;
    let socket;
    let testToken;
    let destination;

    before("deploying multi-tx processor", async() => {
        accounts = await ethers.getSigners();
        destination = accounts[3].address;

        // Deploying the Multi-Tx Processor
        const MultiTxProcessor = await ethers.getContractFactory(
            "MultiTxProcessor"
        );
        multiTxProcessor = await MultiTxProcessor.deploy();

        // Deploying Socket mocks
        const SocketRouterMock = await ethers.getContractFactory(
            "SocketRouterMock"
        );
        socket = await SocketRouterMock.deploy();

        const Token = await ethers.getContractFactory("ERC20Mock");
        testToken = await Token.deploy(
            "Test USDC",
            "TUSDC",
            accounts[0].address,
            BigNumber.from(100000)
        );

        await multiTxProcessor.setBridgeAddress([1], [socket.address]);

        const SWAPPER_ROLE = await multiTxProcessor.SWAPPER_ROLE();
        await multiTxProcessor.grantRole(SWAPPER_ROLE, accounts[1].address);
    });

    it("should fail when called by user without swapper role", async() => {
        try {
            await multiTxProcessor.processMultiTx(
                accounts[0].address,
                "0x",
                accounts[0].address,
                accounts[0].address,
                0
            );
        } catch (err) {
            assert(err);
        }
    });

    it("add a new swapper role", async() => {
        const role = await multiTxProcessor.SWAPPER_ROLE();
        await multiTxProcessor.grantRole(role, accounts[1].address);
        expect(await multiTxProcessor.hasRole(role, accounts[1].address)).to.equal(
            true
        );
    });

    it("should be able to process non-native token with swapper role", async() => {
        const amount = BigNumber.from("1000");
        await testToken.transfer(multiTxProcessor.address, amount);

        const socketTxData = socket.interface.encodeFunctionData(
            "mockSocketTransfer", [multiTxProcessor.address, destination, testToken.address, amount]
        );

        await multiTxProcessor
            .connect(accounts[1])
            .processTx(1, socketTxData, testToken.address, socket.address, amount);

        expect(await testToken.balanceOf(destination)).to.equals(amount);
    });
});