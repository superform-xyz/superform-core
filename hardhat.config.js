/* eslint-disable prettier/prettier */
require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require('hardhat-contract-sizer');
require("solidity-coverage");
require("xdeployer");
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
                runs: 100
            }
        },
    },
    contractSizer: {
        alphaSort: false,
        disambiguatePaths: false,
        runOnCompile: false,
        strict: false
    },
    networks: {
        hardhat: {
            chainId: 1,
            forking: {
                enabled: true,
                url: "https://mainnet.infura.io/v3/59a5debd441b4793a52b5ec69ba1ac23"
            }
        }
    },
    etherscan: {
        apiKey: "7PVFUDTW44QBP8Y7CU5WKX6DXJMHSBTWNW"
    },
    gasReporter: {
        enabled: false,
        currency: "USD",
    },
    mocha: {
        timeout: 100000000
    }
};