const {
    DefenderRelaySigner,
    DefenderRelayProvider,
} = require("defender-relay-client/lib/ethers");
const ethers = require("ethers");
const { request, gql } = require("graphql-request");

const QUERY_URL =
    "https://api.goldsky.com/api/public/project_cl94kmyjc05xp0ixtdmoahbtu/subgraphs/superform-beta-polygon/5.0.0/gn";
const ADDRESS = "0x908da814cc9725616D410b2978E88fF2fb9482eE";
const ADAPTER_PARAMS =
    "0x000100000000000000000000000000000000000000000000000000000000000c3500";

const query2 = gql `
  {
    payloads(where: { payloadStatus: 0 }) {
      srcChainId
      dstChainId
      payloadId
    }
  }
`;

const ABI = [{
    inputs: [{
            internalType: "uint256",
            name: "payloadId",
            type: "uint256",
        },
        {
            internalType: "bytes",
            name: "safeGasParam",
            type: "bytes",
        },
    ],
    name: "processPayload",
    outputs: [],
    stateMutability: "payable",
    type: "function",
}, ];

const ENDPOINT_ABI = [{
    inputs: [
        { internalType: "uint16", name: "_dstChainId", type: "uint16" },
        { internalType: "address", name: "_userApplication", type: "address" },
        { internalType: "bytes", name: "_payload", type: "bytes" },
        { internalType: "bool", name: "_payInZRO", type: "bool" },
        { internalType: "bytes", name: "_adapterParams", type: "bytes" },
    ],
    name: "estimateFees",
    outputs: [
        { internalType: "uint256", name: "nativeFee", type: "uint256" },
        { internalType: "uint256", name: "zroFee", type: "uint256" },
    ],
    stateMutability: "view",
    type: "function",
}, ];

exports.handler = async function(event) {
    const provider = new DefenderRelayProvider(event);
    const signer = new DefenderRelaySigner(event, provider, { speed: "fast" });
    const contract = new ethers.Contract(ADDRESS, ABI, signer);

    const data2 = await request(QUERY_URL, query2);
    for (let i = 0; i < data2.payloads.length; i++) {
        try {
            const tx = await contract.processPayload(
                data2.payloads[i].payloadId,
                ADAPTER_PARAMS
            );
            console.log(
                `Processed payloadId: ${data2.payloads[i].payloadId}: ${tx.hash}`
            );
        } catch (err) {
            console.log(`Error: ${data2.payloads[i].payloadId}`);
        }
    }
};