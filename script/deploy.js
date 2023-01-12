const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

async function deployToLocahost() {
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

  let FantomChainId = 1;
  let BscChainId = 2;

  let ThousandTokensE18 = ethers.utils.parseEther("1000");
  let MilionTokensE18 = ethers.utils.parseEther("1000000");

  var BscStateHandlerCounter = 0;
  var FantomStateHandlerCounter = 0;

  let mockEstimatedNativeFee;
  let mockEstimatedZroFee;

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
  const SocketRouterMock = await ethers.getContractFactory("SocketRouterMock");
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

  console.log("FantomUSDC address: ", FantomUSDC.address);

  BscUSDC = await Token.deploy(
    "BSC USDC",
    "BUSDC",
    accounts[0].address,
    MilionTokensE18
  );

  console.log("BscUSDC address: ", BscUSDC.address);

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

  console.log("FantomVault address: ", FantomVault.address);

  BscVault = await Vault.deploy(BscUSDC.address, "BscVault", "TSTBscVault");

  console.log("BscVault address: ", BscVault.address);

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

  // Setting up required initial parameters
  /// @dev why do we need to do it ourselves? we really shouldn't
  //   await FantomSrc.setTokenChainId(1, BscChainId);
  //   await BscSrc.setTokenChainId(1, FantomChainId);

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
  await BscStateHandler.setHandlerController(BscSrc.address, BscDst.address);

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
  await BscStateHandler.grantRole(PROCESSOR_CONTRACT_ROLE, accounts[0].address);

  console.log("Deployed to localhost");
  console.log("SuperRouter(1) address: ", FantomSrc.address);
  console.log("SuperDestination(1) address: ", FantomDst.address);
  console.log("SuperRouter(2) address: ", BscSrc.address);
  console.log("SuperDestination(2) address: ", BscDst.address);

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
    try {
    //   console.log("log reqs");
    //   console.log([liqReq], [stateReq]);
      await targetSource.deposit([liqReq], [stateReq], {
        value: ethers.utils.parseEther("1"),
      });
    } catch (e) {
      console.log("err here");
      console.log(e);
    }
  }

  async function buildDepositCall(
    fromSrc,
    toDst,
    tokenType,
    vaultId,
    amount,
    targetChainId
  ) {
    let socketTxData = socket.interface.encodeFunctionData(
      "mockSocketTransfer",
      [fromSrc, toDst, tokenType, amount]
    );

    const stateReq = [
      targetChainId,
      [amount],
      [vaultId],
      [1000], // hardcoding max-slippage to 10%
      0x00,
      ethers.utils.parseEther("1"),
    ];

    const LiqReq = [
      1,
      socketTxData,
      tokenType,
      socket.address,
      amount,
      0, /// nativeAmount
    ];

    return { stateReq: stateReq, LiqReq: LiqReq };
  }

  const amount = ThousandTokensE18;
  const vaultId = 1;

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

}

deployToLocahost();
