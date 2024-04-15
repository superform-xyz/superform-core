const fs = require("fs");

let constructedData = {
    types: ["address", "uint256", "address[]", "uint256[]", "uint256"],
    count: 0,
    totalAmountUSDC: 0,
    totalAmountDAI: 0,
    values: {},
};


let usdc = 10;
let dai = 20;

let totalAmountUSDC = 0;
let totalAmountDAI = 0;
const maxRewardTokenTypes = 2;
const tokenTypes = ["0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85", "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1"];
let claimer = ""
let claimers = []

for (let i = 0; ; ++i) {
    if (i + 1 < 10) {
        claimer = `0x000000000000000000000000000000000000000${(i + 1)}`
    } else if (i + 1 < 100) {
        claimer = `0x00000000000000000000000000000000000000${(i + 1)}`
    }

    claimers.push(claimer);

    /// number of token types to receive
    const randomNumberOfTokenTypes = Math.floor(Math.random() * maxRewardTokenTypes) + 1;
    console.log(`Random number of reward tokens: ${randomNumberOfTokenTypes}`)

    /// token selected
    const randomTokenType = Math.floor(Math.random() * maxRewardTokenTypes) + 1;
    if (randomNumberOfTokenTypes === 1) {
        if (randomTokenType === 1 && usdc > 0) {
            /// USDC
            usdc--;
            const randomAmountToken1 = Math.floor(Math.random() * 1000) + 1;
            constructedData.values[i] = { "0": claimer, "1": "0", "2": [tokenTypes[randomTokenType - 1]], "3": [randomAmountToken1], "4": "10" };
            totalAmountUSDC += randomAmountToken1;

        } else if (randomTokenType === 2 && dai > 0) {
            /// DAI
            dai--;
            const randomAmountToken2 = Math.floor(Math.random() * 1000) + 1;
            constructedData.values[i] = { "0": claimer, "1": "0", "2": [tokenTypes[randomTokenType - 1]], "3": [randomAmountToken2], "4": "10" };
            totalAmountDAI += randomAmountToken2;
        } else {
            break;
        }
        continue;
    } else if (randomNumberOfTokenTypes === 2) {
        if (usdc > 0 && dai > 0) {
            /// USDC
            const randomAmountToken1 = Math.floor(Math.random() * 1000) + 1;
            /// DAI
            const randomAmountToken2 = Math.floor(Math.random() * 1000) + 1;
            constructedData.values[i] = { "0": claimer, "1": "0", "2": [tokenTypes[0], tokenTypes[1]], "3": [randomAmountToken1, randomAmountToken2], "4": "10" };
            totalAmountUSDC += randomAmountToken1;
            totalAmountDAI += randomAmountToken2;
            usdc--;
            dai--;
        } else {
            break;
        }
        continue;
    }
}
console.log(`Total amount USDC: ${totalAmountUSDC}`);
console.log(`Total amount DAI: ${totalAmountDAI}`);
console.log(`Number of claimers: ${claimers.length}`)

constructedData.totalAmountUSDC = totalAmountUSDC;
constructedData.totalAmountDAI = totalAmountDAI;
constructedData.count = claimers.length;

fs.writeFileSync(`test/fuzz/rewardsDistributor/target/input1.json`, JSON.stringify(constructedData));
return;

