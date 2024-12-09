#!/usr/bin/env bash

export ETHERSCAN_API_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHERSCAN_API_KEY/credential)
export BSCSCAN_API_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSCSCAN_API_KEY/credential)
export SNOWTRACE_API_KEY=verifyContract
export POLYGONSCAN_API_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGONSCAN_API_KEY/credential)
export ARBISCAN_API_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBISCAN_API_KEY/credential)
export OPSCAN_API_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPSCAN_API_KEY/credential)
export BASESCAN_API_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASESCAN_API_KEY/credential)
export FTMSCAN_API_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/FTMSCAN_API_KEY/credential)
export LINEASCAN_API_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/LINEASCAN_API_KEY/credential)
export BLASTSCAN_API_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BLASTSCAN_API_KEY/credential)

networks=(
    1
    56
    43114
    137
    42161
    10
    8453
    250
    59144
    81457
    # add more networks here if needed
)

api_keys=(
    $ETHERSCAN_API_KEY
    $BSCSCAN_API_KEY
    $SNOWTRACE_API_KEY
    $POLYGONSCAN_API_KEY
    $ARBISCAN_API_KEY
    $OPSCAN_API_KEY
    $BASESCAN_API_KEY
    $FTMSCAN_API_KEY
    $LINEASCAN_API_KEY
    $BLASTSCAN_API_KEY
    # add more API keys here if needed
)

## CONTRACTS VERIFICATION
empty_constructor_arg="$(cast abi-encode "constructor()")"
super_constructor_arg="$(cast abi-encode "constructor(address)" 0x17A332dC7B40aE701485023b219E9D6f493a2514)"
superposition_constructor_arg="$(cast abi-encode "constructor(string, address, string, string)" https://ipfs-gateway.superform.xyz/ipns/k51qzi5uqu5dg90fqdo9j63m556wlddeux4mlgyythp30zousgh3huhyzouyq8/JSON/ 0x17A332dC7B40aE701485023b219E9D6f493a2514 SuperPositions SP)"
superregistry_constructor_arg="$(cast abi-encode "constructor(address)" 0x480bec236e3d3AE33789908BF024850B2Fe71258)"
super_rbac_arg="$(cast abi-encode 'constructor((address,address,address,address,address,address,address,address,address,address,address))' '(0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92,0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92,0xD911673eAF0D3e15fe662D58De15511c5509bAbB,0x23c658FE050B4eAeB9401768bF5911D11621629c,0x73009CE7cFFc6C4c5363734d1b429f0b848e0490,0x73009CE7cFFc6C4c5363734d1b429f0b848e0490,0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f,0x73009CE7cFFc6C4c5363734d1b429f0b848e0490,0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C,0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5,0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a)')"
wormhole_sr_arg="$(cast abi-encode "constructor(address, uint8)" 0x17A332dC7B40aE701485023b219E9D6f493a2514 2)"

super_constructor_arg_ftm="$(cast abi-encode "constructor(address)" 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4)"
superposition_constructor_arg_ftm="$(cast abi-encode "constructor(string, address, string, string)" https://ipfs-gateway.superform.xyz/ipns/k51qzi5uqu5dg90fqdo9j63m556wlddeux4mlgyythp30zousgh3huhyzouyq8/JSON/ 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4 SuperPositions SP)"
superregistry_constructor_arg_ftm="$(cast abi-encode "constructor(address)" 0xd831b4ba49852F6E7246Fe7f4A7DABB5b0C56e1F)"
super_rbac_arg_ftm="$(cast abi-encode 'constructor((address,address,address,address,address,address,address,address,address,address,address))' '(0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92,0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92,0xD911673eAF0D3e15fe662D58De15511c5509bAbB,0x23c658FE050B4eAeB9401768bF5911D11621629c,0x73009CE7cFFc6C4c5363734d1b429f0b848e0490,0x73009CE7cFFc6C4c5363734d1b429f0b848e0490,0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f,0x73009CE7cFFc6C4c5363734d1b429f0b848e0490,0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C,0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5,0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a)')"
wormhole_sr_arg_ftm="$(cast abi-encode "constructor(address, uint8)" 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4 2)"

file_names=(
    "src/crosschain-data/extensions/CoreStateRegistry.sol"
    "src/crosschain-liquidity/DstSwapper.sol"
    "src/forms/ERC4626Form.sol"
    "src/EmergencyQueue.sol"
    "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol"
    "src/crosschain-data/adapters/layerzero-v2/LayerzeroV2Implementation.sol"
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
    "src/settings/SuperRBAC.sol"
    "src/VaultClaimer.sol"
    "src/crosschain-data/BroadcastRegistry.sol"
    "src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol"
    "src/crosschain-liquidity/socket/SocketOneInchValidator.sol"
    "src/crosschain-liquidity/1inch/OneInchValidator.sol"
    "src/crosschain-liquidity/debridge/DeBridgeForwarderValidator.sol"
    "src/crosschain-liquidity/debridge/DeBridgeValidator.sol"
    "src/crosschain-data/adapters/axelar/AxelarImplementation.sol"
    "src/RewardsDistributor.sol"
    "src/forms/ERC5115Form.sol"
    "src/forms/wrappers/ERC5115To4626WrapperFactory.sol"
    "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol"
    "src/router-plus/SuperformRouterPlus.sol"
    # Add more file names here if needed
)

file_name_blast=(
    "src/crosschain-data/extensions/CoreStateRegistry.sol"
    "src/crosschain-liquidity/DstSwapper.sol"
    "script/forge-scripts/misc/blast/forms/BlastERC4626Form.sol"
    "src/EmergencyQueue.sol"
    "src/crosschain-data/adapters/hyperlane/HyperlaneImplementation.sol"
    "src/crosschain-data/adapters/layerzero-v2/LayerzeroV2Implementation.sol"
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
    "src/settings/SuperRBAC.sol"
    "src/VaultClaimer.sol"
    "src/crosschain-data/BroadcastRegistry.sol"
    "src/crosschain-data/adapters/wormhole/specialized-relayer/WormholeSRImplementation.sol"
    "src/crosschain-liquidity/socket/SocketOneInchValidator.sol"
    "src/crosschain-liquidity/1inch/OneInchValidator.sol"
    "src/crosschain-liquidity/debridge/DeBridgeForwarderValidator.sol"
    "src/crosschain-liquidity/debridge/DeBridgeValidator.sol"
    "src/crosschain-data/adapters/axelar/AxelarImplementation.sol"
    "src/RewardsDistributor.sol"
    "script/forge-scripts/misc/blast/forms/BlastERC5115Form.sol"
    "src/forms/wrappers/ERC5115To4626WrapperFactory.sol"
    "src/crosschain-data/adapters/layerzero/LayerzeroImplementation.sol"
    # Add more file names here if needed
)

contract_names=(
    "CoreStateRegistry"
    "DstSwapper"
    "ERC4626Form"
    "EmergencyQueue"
    "HyperlaneImplementation"
    "LayerzeroV2Implementation"
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
    "SuperRBAC"
    "VaultClaimer"
    "BroadcastRegistry"
    "WormholeSRImplementation"
    "SocketOneInchValidator"
    "OneInchValidator"
    "DeBridgeForwarderValidator"
    "DeBridgeValidator"
    "AxelarImplementation"
    "RewardsDistributor"
    "ERC5115Form"
    "ERC5115To4626WrapperFactory"
    "LayerzeroImplementation"
    "SuperformRouterPlus"
    # Add more contract names here if needed
)

contract_addresses=(
    0x3721B0E122768CedDfB3Dec810E64c361177f826
    0x2691638Fa19357773C186BA34924E194B4Ab6cDa
    0x58F8Cef0D825B1a609FaD0576d5F2b7399ab1335
    0xE22DCd9264086DF7B26d97A9A9d35e8dFac819dd
    0x9f1F6357284526489e8e6ce4b2cB2612Aa1d4712
    0x2a14460FEE6f73b408c6acF627190614daC97Df0
    0x7fa95363c82b2baceb73627988dc12eeb17e4c2b
    0xF1b9e0E57D134B7dFede001ccE5e879D8C2b8C1B
    0xAD2b7eD1315330633bc265A0109D3B12D4caed3c
    0x69c531E5bdf2458FFb4f5E0dB3DE41745151b2Bd
    0x7483486862BDa9BA68Be4923E7E9945c2771Ec28
    0xD85ec15A9F814D6173bF1a89273bFB3964aAdaEC
    0xa195608C2306A26f727d5199D5A382a4508308DA
    0xEa3b1027fe6dB0F01aCc73627B47fD4a5a079427
    0x01dF6fb6a28a89d6bFa53b2b3F20644AbF417678
    0x17A332dC7B40aE701485023b219E9D6f493a2514
    0x480bec236e3d3AE33789908BF024850B2Fe71258
    0xC4A234A40aC13b02096Dd4aae1b8221541Dc5d5A
    0x856ddF6348fFF6B774566cD63f2e8db3796a0965
    0x2827eFf89affacf9E80D671bca6DeCf7dbdcCaCa
    0x9B1dE8d1Fbf77Ca949f944F718D93fdC48f218C8
    0xB2B58dEfa7Dc7e26D21F58847BaEA5A6375eAf8D
    0xDEa392D62cA1Edb74FB9210Aed714ad8F12b3E60
    0x04A9e7318544DA4dd8c3d76E9c72d2087e285a8d
    0xD8d5B00C1c99174897488E3dCa157B6849731E6A
    0xce23bD7205bF2B543F6B4eeC00Add0C111FEFc3B
    0x35E3057FF29ebC5b8dEF18EC66FEde16f1B237F5
    0x664E1e7b8393DF4aC4EFAbEf9d56B2100098FCE2
    0xc100592b40eeb4CBC7524092A00400917421ab64
    0x4393C2a521ef115cd32C1d45897E7ce33aDa7aa9
    # Add more addresses here if needed
)

contract_addresses_fantom=(
    0xc4e6b51bcE2F92666207214965CBeb0Bd9B5d6BF
    0x3c6C2D73ED864E25c2C0599F5716192a89554695
    0x290dE2677EC5056458D60202B112ac44e9b3d90d
    0x898e4E8a442C079e74c9E61E956d2FD183e5Eb99
    0x0000000000000000000000000000000000000000
    0xbc558947dd89C72E4e9C3563Cfb637f8bd46CD5c
    0xbB7d1453487043Aa8db8512eC22498a8F2fB652B
    0xeE8695cDa4697987e1Fcd191F3c69FFF5Ef02eD0
    0xf3960a8759A8757E1ED44dC24d5D2dF1394633F5
    0xb69929AC813125EdFaCFad366643c3787C0d1500
    0xfDf661e1e7e8F617b383516688A8aFC9c6176A04
    0xbc85043544CC2b3Fd095d54b6431822979BBB62A
    0x50DFeb29B462a64867f421C585BDaE89cf4656d4
    0x370dffFE065D820c30341C52b34Ac18C4df4C3E9
    0x7F1535FF0f0A099eb7D314e1655BD4dC92986aAD
    0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4
    0xd831b4ba49852F6E7246Fe7f4A7DABB5b0C56e1F
    0x861e766B97eEE8774fA96C16Ee8cc448A3d68d1C
    0xf631CA98f1884Ca3AD5abC510F071C54fbd3d8E9
    0x0Bb3468d5b3Cd0842eEc911C735a9B128B21B0C9
    0xeb077f9CB0406667DDD7BE945f393297578372F1
    0xf5232D46E988e4ED6E95f90748Ec1AAEd19Ec0B8
    0xDEDaA19236743EfB77a20042AA5Bb8C8A005C388
    0x3456E9f41a4039d127aCfff4708ffC6CE0Ca83e2
    0x03a1480B5B6114B5D6c801bB4C71fc142488a41a
    0xd6cea5c8853c3fb4bbd77ef5e924c4e647c03a94
    0x168EFbe9bc32f1b4FCCbd7B0704331CBacB53e86
    0xAcceD01769200d6Fe399b88789FC8a044e094112
    0x5757dD91fcFd860aC9b7b036FF1fD3f869827e46
    # Add more addresses here if needed
)

contract_addresses_linea=(
    0x3721B0E122768CedDfB3Dec810E64c361177f826
    0x2691638Fa19357773C186BA34924E194B4Ab6cDa
    0x58F8Cef0D825B1a609FaD0576d5F2b7399ab1335
    0xE22DCd9264086DF7B26d97A9A9d35e8dFac819dd
    0xe6f739F355f9e9e3788752e6cfBB2A6B7b18a13c
    0xB07e2B06839ECF55A1E47A52E4A14ba6D6D76fA4
    0x717de40D4e360C678aC5e195B99605bc4aAC697E
    0x3639492Dc83019EA36899108B4A1A47cC3b3ecAa
    0x92f98d698d2c8E0f29D1bb4d75C3A03e05e811bc
    0x69c531E5bdf2458FFb4f5E0dB3DE41745151b2Bd
    0x7483486862BDa9BA68Be4923E7E9945c2771Ec28
    0xD85ec15A9F814D6173bF1a89273bFB3964aAdaEC
    0xa195608C2306A26f727d5199D5A382a4508308DA
    0xEa3b1027fe6dB0F01aCc73627B47fD4a5a079427
    0x01dF6fb6a28a89d6bFa53b2b3F20644AbF417678
    0x17A332dC7B40aE701485023b219E9D6f493a2514
    0x480bec236e3d3AE33789908BF024850B2Fe71258
    0xC4A234A40aC13b02096Dd4aae1b8221541Dc5d5A
    0x856ddF6348fFF6B774566cD63f2e8db3796a0965
    0x2827eFf89affacf9E80D671bca6DeCf7dbdcCaCa
    0x9B1dE8d1Fbf77Ca949f944F718D93fdC48f218C8
    0xB2B58dEfa7Dc7e26D21F58847BaEA5A6375eAf8D
    0xDEa392D62cA1Edb74FB9210Aed714ad8F12b3E60
    0x04A9e7318544DA4dd8c3d76E9c72d2087e285a8d
    0xbf938adDB48594089B20677931f028261D25D6A2
    0xce23bD7205bF2B543F6B4eeC00Add0C111FEFc3B
    0x35E3057FF29ebC5b8dEF18EC66FEde16f1B237F5
    0x664E1e7b8393DF4aC4EFAbEf9d56B2100098FCE2
    0xc100592b40eeb4CBC7524092A00400917421ab64
    # Add more addresses here if needed
)

contract_addresses_blast=(
    0x3721B0E122768CedDfB3Dec810E64c361177f826
    0x2691638Fa19357773C186BA34924E194B4Ab6cDa
    0x9dbb4Ca0Ba024cd5efF6401F1d177b9de6A3Fd3E
    0xE22DCd9264086DF7B26d97A9A9d35e8dFac819dd
    0xe6f739F355f9e9e3788752e6cfBB2A6B7b18a13c
    0xB07e2B06839ECF55A1E47A52E4A14ba6D6D76fA4
    0x717de40D4e360C678aC5e195B99605bc4aAC697E
    0x3639492Dc83019EA36899108B4A1A47cC3b3ecAa
    0x92f98d698d2c8E0f29D1bb4d75C3A03e05e811bc
    0x69c531E5bdf2458FFb4f5E0dB3DE41745151b2Bd
    0x7483486862BDa9BA68Be4923E7E9945c2771Ec28
    0xD85ec15A9F814D6173bF1a89273bFB3964aAdaEC
    0xa195608C2306A26f727d5199D5A382a4508308DA
    0xbe296d633E91BD3E72f52732d80F7b28F18cDB54
    0x01dF6fb6a28a89d6bFa53b2b3F20644AbF417678
    0x17A332dC7B40aE701485023b219E9D6f493a2514
    0x480bec236e3d3AE33789908BF024850B2Fe71258
    0xC4A234A40aC13b02096Dd4aae1b8221541Dc5d5A
    0x856ddF6348fFF6B774566cD63f2e8db3796a0965
    0x2827eFf89affacf9E80D671bca6DeCf7dbdcCaCa
    0x9B1dE8d1Fbf77Ca949f944F718D93fdC48f218C8
    0xB2B58dEfa7Dc7e26D21F58847BaEA5A6375eAf8D
    0xDEa392D62cA1Edb74FB9210Aed714ad8F12b3E60
    0x04A9e7318544DA4dd8c3d76E9c72d2087e285a8d
    0xbf938adDB48594089B20677931f028261D25D6A2
    0xce23bD7205bF2B543F6B4eeC00Add0C111FEFc3B
    0x5266958cb4b8E6A1534c6Ac19f4220909cf3F7FA
    0x664E1e7b8393DF4aC4EFAbEf9d56B2100098FCE2
    0xc100592b40eeb4CBC7524092A00400917421ab64
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
    $super_rbac_arg
    $empty_constructor_arg
    $super_constructor_arg
    $wormhole_sr_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
    $super_constructor_arg
)

constructor_args_ftm=(
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $superposition_constructor_arg_ftm
    $superregistry_constructor_arg_ftm
    $super_rbac_arg_ftm
    $empty_constructor_arg
    $super_constructor_arg_ftm
    $wormhole_sr_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
    $super_constructor_arg_ftm
)

# loop through networks
for i in "${!networks[@]}"; do
    network="${networks[$i]}"
    api_key="${api_keys[$i]}"

    # loop through file_names and contract_names
    for j in "${!file_names[@]}"; do
        file_name="${file_names[$j]}"
        file_name_blast="${file_name_blast[$j]}"
        contract_name="${contract_names[$j]}"
        contract_address="${contract_addresses[$j]}"
        contract_address_fantom="${contract_addresses_fantom[$j]}"
        contract_address_linea="${contract_addresses_linea[$j]}"
        contract_address_blast="${contract_addresses_blast[$j]}"
        constructor_arg="${constructor_args[$j]}"
        constructor_arg_ftm="${constructor_args_ftm[$j]}"
        # verify the contract
        if [[ $network == 43114 ]]; then
            forge verify-contract $contract_address \
                --chain-id $network \
                --num-of-optimizations 200 \
                --watch --compiler-version v0.8.23 \
                --constructor-args "$constructor_arg" \
                "$file_name:$contract_name" \
                --etherscan-api-key "$api_key" \
                --verifier-url 'https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan'
        elif [[ $network == 250 ]]; then
            forge verify-contract $contract_address_fantom \
                --chain-id $network \
                --num-of-optimizations 200 \
                --watch --compiler-version v0.8.23 \
                --constructor-args "$constructor_arg_ftm" \
                "$file_name:$contract_name" \
                --etherscan-api-key "$api_key"
        elif [[ $network == 59144 ]]; then
            forge verify-contract $contract_address_linea \
                --chain-id $network \
                --num-of-optimizations 200 \
                --watch --compiler-version v0.8.23 \
                --constructor-args "$constructor_arg" \
                "$file_name:$contract_name" \
                --etherscan-api-key "$api_key"
        elif [[ $network == 81457 ]]; then
            forge verify-contract $contract_address_blast \
                --chain-id $network \
                --num-of-optimizations 200 \
                --watch --compiler-version v0.8.23 \
                --constructor-args "$constructor_arg" \
                "$file_name_blast:$contract_name" \
                --etherscan-api-key "$api_key"
        else
            forge verify-contract $contract_address \
                --chain-id $network \
                --num-of-optimizations 200 \
                --watch --compiler-version v0.8.23 \
                --constructor-args "$constructor_arg" \
                "$file_name:$contract_name" \
                --etherscan-api-key "$api_key"
        fi
    done
done
