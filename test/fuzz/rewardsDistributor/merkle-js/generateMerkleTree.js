const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");


/// read all the files in target folder
let files = fs.readdirSync('test/fuzz/rewardsDistributor/target/');
let filteredFiles = files.filter(file => file.startsWith("input"))
let constructedData = [];

for (let i = 0; i < filteredFiles.length; ++i) {
  const jsonTreeData = require(`../target/${filteredFiles[i]}`);
  for (let j = 0; j < jsonTreeData.count; ++j) {
    if (jsonTreeData.values[j][2].length != jsonTreeData.values[j][3].length) {
      throw new Error("Invalid input data");
    }
    constructedData.push(
      [jsonTreeData.values[j][0].toString(), jsonTreeData.values[j][1].toString(), jsonTreeData.values[j][2], jsonTreeData.values[j][3], jsonTreeData.values[j][4].toString()]
    )
  }

  /// step 2: construct the merkle tree
  const tree = StandardMerkleTree.of(constructedData, ["address", "uint256", "address[]", "uint256[]", "uint256"]);

  /// step 3: construct the root
  const root = tree.root;
  const treeDump = tree.dump();

  /// step 4: construct the root for each index
  for (const [i, v] of tree.entries()) {
    const proof = tree.getProof(i);
    treeDump.values[i].claimer = treeDump.values[i].value[0];
    treeDump.values[i].periodId = parseInt(treeDump.values[i].value[1]);
    treeDump.values[i].rewardTokens = treeDump.values[i].value[2].map((value) => value.toString());
    treeDump.values[i].amountsClaimed = treeDump.values[i].value[3].map((value) => parseInt(value));
    treeDump.values[i].chainId = parseInt(treeDump.values[i].value[4]);
  }

  /// step 4: write the tree and root for further use
  fs.writeFileSync(`test/fuzz/rewardsDistributor/target/jsGeneratedRoot${i}.json`, JSON.stringify({ "root": root }));
  fs.writeFileSync(`test/fuzz/rewardsDistributor/target/jsTreeDump${i}.json`, JSON.stringify(treeDump));
  constructedData = [];
}