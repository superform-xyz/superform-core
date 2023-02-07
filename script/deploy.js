/* eslint-disable node/no-unpublished-require */
/* eslint-disable prettier/prettier */
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
    console.log(hre.network.config.chainId)
    let LzChainId;

    if (hre.network.config.chainId === 1) {
        LzChainId = "101"
    } else if (hre.network.config.chainId === 42161) {
        LzChainId = "110"
    } else if (hre.network.config.chainId === 137) {
        LzChainId = "109"
    } else if (hre.network.config.chainId === 10) {
        LzChainId = "111"
    } else if (hre.network.config.chainId === 250) {
        LzChainId = "112"
    } else if (hre.network.config.chainId === 56) {
        LzChainId = "102"
    } else if (hre.network.config.chainId === 43114) {
        LzChainId = "106"
    }

    const ABI = await ethers.getContractFactory("RouterPatch")
    const contract = await ABI.deploy(LzChainId)

    await contract.deployed()
    await hre.run("verify:verify", {
        // eslint-disable-next-line no-loss-of-precision
        address: contract.address,
        constructorArguments: [LzChainId]
    });
    console.log(contract.address)
}

main().catch((err) => {
    console.log(err);
});