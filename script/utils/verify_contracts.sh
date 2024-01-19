#!/usr/bin/env bash

# Read the RPC URL
source .env

networks=(
    56
    43114
    137
    42161
    10
    8453
    # add more networks here if needed
)

api_keys=(
    $BSCSCAN_API
    $SNOWTRACE_API
    $POLYGONSCAN_API
    $ARBISCAN_API
    $OPSCAN_API
    $BASESCAN_API
    # add more API keys here if needed
)

## CONTRACTS VERIFICATION
empty_constructor_arg="$(cast abi-encode "constructor()")"
super_constructor_arg="$(cast abi-encode "constructor(address)" 0x38594203fB14f85AF738Ec1bAFe2A82a16BB48Cb)"
superposition_constructor_arg="$(cast abi-encode "constructor(string, address)" https://ipfs-gateway.superform.xyz/ipns/k51qzi5uqu5dg90fqdo9j63m556wlddeux4mlgyythp30zousgh3huhyzouyq8/JSON/ 0x38594203fB14f85AF738Ec1bAFe2A82a16BB48Cb)"
superregistry_constructor_arg="$(cast abi-encode "constructor(address)" 0x2e639444763e402F80A9Ec9D03361Be351b9d40c)"

file_names=(
    "src/crosschain-data/extensions/CoreStateRegistry.sol"
    "src/crosschain-liquidity/DstSwapper.sol"
    "src/forms/ERC4626Form.sol"
    "src/EmergencyQueue.sol"
    "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol"
    "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol"
    "src/crosschain-liquidity/lifi/LiFiValidator.sol"
    "src/payments/PayMaster.sol"
    "src/crosschain-data/utils/PayloadHelper.sol"
    "src/payments/PaymentHelper.sol"
    "src/crosschain-liquidity/socket/SocketValidator.sol"
    "src/SuperformFactory.sol"
    "src/SuperformRouter.sol"
    "src/crosschain-data/adapters/wormhole/automatic-relayer/WormholeARImplementation.sol"
    "src/SuperPositions.sol"
    "src/settings/SuperRegistry.sol"
    "src/VaultClaimer.sol"
    # Add more file names here if needed
)

contract_names=(
    "CoreStateRegistry"
    "DstSwapper"
    "ERC4626Form"
    "EmergencyQueue"
    "HyperlaneImplementation"
    "LayerzeroImplementation"
    "LiFiValidator"
    "PayMaster"
    "PayloadHelper"
    "PaymentHelper"
    "SocketValidator"
    "SuperformFactory"
    "SuperformRouter"
    "WormholeARImplementation"
    "SuperPositions"
    "SuperRegistry"
    "VaultClaimer"
    # Add more contract names here if needed
)

contract_addresses=(
    0x884C1Da625D7E70ca1B8fA4BF7Ab535b7297CcE0
    0xc80cdE90baA1bf7f1F53562d6Ae9B6dc5b748616
    0x457724F3E7e303A831015B09286fF18Ca9F98313
    0xb822502f4b9d070Be064061e5cb69815e78cF703
    0xe3e25b658373b594319bdA2fa550073193193706
    0x3D4124bF552adBd509F4Ba213B3b0af50D0d672E
    0x7F991f7Bcad98c341Cf8c9022E64AFe2164A6073
    0x44dfA7f53b2DAF12533E326E9FE8f886fdF4Eeff
    0x01E51f95c83eAaB8148832034266D316732d551b
    0x94b253872b866C04Ba4f8C4793425991Bfe59759
    0x108f40Eba195489065B61A19dbE064691612477a
    0x9bc1de324709d8CA71eE78fa6859C50d96D4391c
    0x5E4F382e713534703E4BeF3F538777e088a6410e
    0x63567cb414A4Edf54A3a54D0f3D5DB3C2e07CB25
    0x4cCDcA3266CF83420C9cc63b39A14B93b25CDa10
    0x38594203fB14f85AF738Ec1bAFe2A82a16BB48Cb
    0xc01e503Bf896E45B6Add3095EBA7696d5a682388
    # Add more addresses here if needed
)

constructor_args=(
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $superposition_constructor_arg
    $superregistry_constructor_arg
    $empty_constructor_arg
)

# loop through networks
for i in "${!networks[@]}"; do
    network="${networks[$i]}"
    api_key="${api_keys[$i]}"

    # loop through file_names and contract_names
    for j in "${!file_names[@]}"; do
        file_name="${file_names[$j]}"
        contract_name="${contract_names[$j]}"
        contract_address="${contract_addresses[$j]}"
        constructor_arg="${constructor_args[$j]}"

        # verify the contract
        if [[ $network == 43114 ]]; then
            forge verify-contract $contract_address \
                --chain-id $network \
                --num-of-optimizations 200 \
                --watch --compiler-version v0.8.23+commit.f704f362 \
                --constructor-args "$constructor_arg" \
                "$file_name:$contract_name" \
                --etherscan-api-key "$api_key" \
                --verifier-url 'https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan'
        else
            forge verify-contract $contract_address \
                --chain-id $network \
                --num-of-optimizations 200 \
                --watch --compiler-version v0.8.23+commit.f704f362 \
                --constructor-args "$constructor_arg" \
                "$file_name:$contract_name" \
                --etherscan-api-key "$api_key"
        fi
    done
done
