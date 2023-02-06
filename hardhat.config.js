/* eslint-disable prettier/prettier */
require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
require("solidity-coverage");
// require("xdeployer"); UNCOMMENT FOR TESTING &  COMMENT DURING VERIFICATION
require("@nomiclabs/hardhat-ethers");
require("hardhat-etherscan-abi");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async(taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
    solidity: {
        version: "0.8.14",
        settings: {
            optimizer: {
                enabled: true,
                runs: 100,
            },
        },
    },
    contractSizer: {
        alphaSort: false,
        disambiguatePaths: false,
        runOnCompile: false,
        strict: false,
    },
    networks: {
        polygon: {
            chainId: process.env.PRODUCTION === "true" ? 137 : 80001,
            url: process.env.PRODUCTION === "true" ?
                process.env.POLYGON_RPC_URL : process.env.MUMBAI_RPC_URL,
            accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
        },
        avalanche: {
            chainId: process.env.PRODUCTION === "true" ? 43114 : 43113,
            url: process.env.PRODUCTION === "true" ?
                process.env.AVALANCHE_RPC_URL : process.env.FUJI_RPC_URL,
            accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
        },
        fantom: {
            chainId: process.env.PRODUCTION === "true" ? 250 : 4002,
            url: process.env.PRODUCTION === "true" ?
                process.env.FANTOM_RPC_URL : process.env.FANTOM_TESTNET_URL,
            accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
        },
        bsc: {
            chainId: process.env.PRODUCTION === "true" ? 56 : 97,
            url: process.env.PRODUCTION === "true" ?
                process.env.BSC_RPC_URL : process.env.BSC_RPC_URL,
            accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
        },
        optimism: {
            chainId: 10,
            url: process.env.OPTIMISM_RPC_URL,
            accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
        },
        arbitrum: {
            chainId: 42161,
            url: process.env.ARBITRUM_RPC_URL,
            accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
        },
        ethereum: {
            chainId: 1,
            url: process.env.ETHEREUM_RPC_URL,
            accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
        },
        hardhat: {
            chainId: 1,
            forking: {
                enabled: false,
                url: process.env.ETH_RPC_URL,
            },
        },
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
    gasReporter: {
        enabled: false,
        currency: "USD",
    },
    mocha: {
        timeout: 100000000,
    },
};