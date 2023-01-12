/* eslint-disable prettier/prettier */
require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require('hardhat-contract-sizer');
require("solidity-coverage");
require("xdeployer");

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
        runOnCompile: true,
        strict: false
    },
    networks: {
    // hardhat: {
        //     forking: {
        //       chainId: process.env.PRODUCTION === "true" ?  56 : 97,
        //       url: process.env.BSC_RPC_URL,
        //     }
        // }
    },
    gasReporter: {
        enabled: true,
        currency: "USD",
    }
};