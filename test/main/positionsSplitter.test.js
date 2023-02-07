/* eslint-disable prettier/prettier */
/* eslint-disable no-unused-vars */
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

describe("PositionsSplitter tests:", async() => {
    let src;
    let endPointSrc;
    let dst;
    let endPointDst;
    let accounts;
    let token;
    let stateHandlerSrc;
    let stateHandlerDst;
    let swapToken;
    let vault;
    let socket;
    let spliter;
    let sERC20;

    const srcChainId = 1;
    const dstChainId = 2;

    let mockEstimatedNativeFee;
    let mockEstimatedZroFee;

    before("deploying router and dsc", async function() {
        accounts = await ethers.getSigners();

        // Deploying LZ mocks
        const LZEndpointMock = await ethers.getContractFactory("LZEndpointMock");
        endPointSrc = await LZEndpointMock.deploy(srcChainId);
        endPointDst = await LZEndpointMock.deploy(dstChainId);

        // Deploying StateHandler
        const StateHandler = await ethers.getContractFactory("StateHandler");
        stateHandlerSrc = await StateHandler.deploy(endPointSrc.address);
        stateHandlerDst = await StateHandler.deploy(endPointDst.address);

        // Deploying Socket mocks
        const SocketRouterMock = await ethers.getContractFactory(
            "SocketRouterMock"
        );
        socket = await SocketRouterMock.deploy();

        mockEstimatedNativeFee = ethers.utils.parseEther("0.001");
        mockEstimatedZroFee = ethers.utils.parseEther("0.00025");

        await endPointSrc.setEstimatedFees(
            mockEstimatedNativeFee,
            mockEstimatedZroFee
        );
        await endPointDst.setEstimatedFees(
            mockEstimatedNativeFee,
            mockEstimatedZroFee
        );

        // Deploying mock ERC20 token
        const Token = await ethers.getContractFactory("ERC20Mock");
        token = await Token.deploy(
            "Test",
            "TST",
            accounts[0].address,
            BigNumber.from(3000000)
        );

        const SwapToken = await ethers.getContractFactory("ERC20Mock");
        swapToken = await SwapToken.deploy(
            "Swap",
            "SWP",
            accounts[0].address,
            BigNumber.from(3000000)
        );

        // Deploying Mock Vault
        const Vault = await ethers.getContractFactory("VaultMock");
        vault = await Vault.deploy(token.address, "Test Vault", "TSTVAULT");

        // Deploying Destination Contract
        const SuperDestinationABI = await ethers.getContractFactory(
            "SuperDestination"
        );
        dst = await SuperDestinationABI.deploy(dstChainId, stateHandlerDst.address);

        // Deploying routerContract
        const SuperRouterABI = await ethers.getContractFactory("SuperRouter");
        src = await SuperRouterABI.deploy(
            srcChainId,
            "test.com/",
            stateHandlerSrc.address,
            dst.address
        );

        await endPointSrc.setDestLzEndpoint(
            stateHandlerDst.address,
            endPointDst.address
        );
        await endPointDst.setDestLzEndpoint(
            stateHandlerSrc.address,
            endPointSrc.address
        );

        await dst.addVault([vault.address], [1]);

        await dst.setSrcTokenDistributor(src.address, srcChainId);

        await stateHandlerSrc.setHandlerController(src.address, dst.address);
        await stateHandlerDst.setHandlerController(dst.address, src.address);

        const role = await stateHandlerSrc.CORE_CONTRACTS_ROLE();

        await stateHandlerSrc.grantRole(role, src.address);
        await stateHandlerDst.grantRole(role, dst.address);

        await stateHandlerSrc.setTrustedRemote(2, stateHandlerDst.address);
        await stateHandlerDst.setTrustedRemote(1, stateHandlerSrc.address);

        const Spliter = await ethers.getContractFactory("PositionsSplitter");
        spliter = await Spliter.deploy(src.address);
    });

    it("setUp PositionsSplitter", async function() {
        await spliter.registerWrapper(1, "vaultId1", "vID1");
        await src.setApprovalForAll(spliter.address, true);
        const synthERC20address = await spliter.synthethicTokenId(1);
        const sERC20Factory = await ethers.getContractFactory("sERC20");
        sERC20 = new ethers.Contract(
            synthERC20address,
            sERC20Factory.interface,
            accounts[0]
        );
    });

    it("wrap vaultId into ERC20", async function() {
        const balanceOfVaultId1 = await src.balanceOf(accounts[0].address, 1);
        await spliter.wrap(1, balanceOfVaultId1);
        expect(await sERC20.balanceOf(accounts[0].address)).to.be.eq(
            balanceOfVaultId1
        );
        expect(await src.balanceOf(accounts[0].address, 1)).to.be.eq(0);
    });

    it("unwrap ERC20 and wrapBack to ERC1155", async function() {
        const balanceOfSynthERC20 = await sERC20.balanceOf(accounts[0].address);
        await sERC20.approve(spliter.address, balanceOfSynthERC20);
        await spliter.unwrap(1, balanceOfSynthERC20);
        expect(await sERC20.balanceOf(accounts[0].address)).to.be.eq(0);
        expect(await src.balanceOf(accounts[0].address, 1)).to.be.eq(
            balanceOfSynthERC20
        );
    });
});