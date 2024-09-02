// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package contracts

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// IPaymentHelperV2PaymentHelperConfig is an auto generated low-level Go binding around an user-defined struct.
type IPaymentHelperV2PaymentHelperConfig struct {
	NativeFeedOracle      common.Address
	GasPriceOracle        common.Address
	SwapGasUsed           *big.Int
	UpdateDepositGasUsed  *big.Int
	DepositGasUsed        *big.Int
	WithdrawGasUsed       *big.Int
	DefaultNativePrice    *big.Int
	DefaultGasPrice       *big.Int
	DstGasPerByte         *big.Int
	AckGasCost            *big.Int
	TimelockCost          *big.Int
	EmergencyCost         *big.Int
	UpdateWithdrawGasUsed *big.Int
}

// MultiDstMultiVaultStateReq is an auto generated low-level Go binding around an user-defined struct.
type MultiDstMultiVaultStateReq struct {
	AmbIds         [][]uint8
	DstChainIds    []uint64
	SuperformsData []MultiVaultSFData
}

// MultiDstSingleVaultStateReq is an auto generated low-level Go binding around an user-defined struct.
type MultiDstSingleVaultStateReq struct {
	AmbIds         [][]uint8
	DstChainIds    []uint64
	SuperformsData []SingleVaultSFData
}

// MultiVaultSFData is an auto generated low-level Go binding around an user-defined struct.
type MultiVaultSFData struct {
	SuperformIds      []*big.Int
	Amounts           []*big.Int
	OutputAmounts     []*big.Int
	MaxSlippages      []*big.Int
	LiqRequests       []LiqRequest
	Permit2data       []byte
	HasDstSwaps       []bool
	Retain4626s       []bool
	ReceiverAddress   common.Address
	ReceiverAddressSP common.Address
	ExtraFormData     []byte
}

// SingleDirectMultiVaultStateReq is an auto generated low-level Go binding around an user-defined struct.
type SingleDirectMultiVaultStateReq struct {
	SuperformData MultiVaultSFData
}

// SingleDirectSingleVaultStateReq is an auto generated low-level Go binding around an user-defined struct.
type SingleDirectSingleVaultStateReq struct {
	SuperformData SingleVaultSFData
}

// SingleVaultSFData is an auto generated low-level Go binding around an user-defined struct.
type SingleVaultSFData struct {
	SuperformId       *big.Int
	Amount            *big.Int
	OutputAmount      *big.Int
	MaxSlippage       *big.Int
	LiqRequest        LiqRequest
	Permit2data       []byte
	HasDstSwap        bool
	Retain4626        bool
	ReceiverAddress   common.Address
	ReceiverAddressSP common.Address
	ExtraFormData     []byte
}

// SingleXChainMultiVaultStateReq is an auto generated low-level Go binding around an user-defined struct.
type SingleXChainMultiVaultStateReq struct {
	AmbIds         []uint8
	DstChainId     uint64
	SuperformsData MultiVaultSFData
}

// SingleXChainSingleVaultStateReq is an auto generated low-level Go binding around an user-defined struct.
type SingleXChainSingleVaultStateReq struct {
	AmbIds        []uint8
	DstChainId    uint64
	SuperformData SingleVaultSFData
}

// PaymentHelperMetaData contains all meta data concerning the PaymentHelper contract.
var PaymentHelperMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superRegistry_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"CHAIN_ID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ackGasCost\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasForAck\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addRemoteChain\",\"inputs\":[{\"name\":\"chainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"config_\",\"type\":\"tuple\",\"internalType\":\"structIPaymentHelperV2.PaymentHelperConfig\",\"components\":[{\"name\":\"nativeFeedOracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"gasPriceOracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"swapGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"updateDepositGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"depositGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"withdrawGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"defaultNativePrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"defaultGasPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"dstGasPerByte\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"ackGasCost\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timelockCost\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"emergencyCost\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"updateWithdrawGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"addRemoteChains\",\"inputs\":[{\"name\":\"chainIds_\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"},{\"name\":\"configs_\",\"type\":\"tuple[]\",\"internalType\":\"structIPaymentHelperV2.PaymentHelperConfig[]\",\"components\":[{\"name\":\"nativeFeedOracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"gasPriceOracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"swapGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"updateDepositGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"depositGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"withdrawGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"defaultNativePrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"defaultGasPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"dstGasPerByte\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"ackGasCost\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timelockCost\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"emergencyCost\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"updateWithdrawGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchUpdateRemoteChain\",\"inputs\":[{\"name\":\"chainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"configTypes_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"configs_\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"batchUpdateRemoteChains\",\"inputs\":[{\"name\":\"chainIds_\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"},{\"name\":\"configTypes_\",\"type\":\"uint256[][]\",\"internalType\":\"uint256[][]\"},{\"name\":\"configs_\",\"type\":\"bytes[][]\",\"internalType\":\"bytes[][]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"calculateAMBData\",\"inputs\":[{\"name\":\"dstChainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"ambIds_\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"},{\"name\":\"message_\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"totalFees\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"extraData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"depositGasUsed\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasForDeposit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"emergencyCost\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasForEmergency\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"estimateAMBFees\",\"inputs\":[{\"name\":\"ambIds_\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"},{\"name\":\"dstChainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"message_\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"extraData_\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}],\"outputs\":[{\"name\":\"totalFees\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"estimateAckCost\",\"inputs\":[{\"name\":\"payloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"totalFees\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"estimateAckCostDefault\",\"inputs\":[{\"name\":\"multi\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"ackAmbIds\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"},{\"name\":\"srcChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"totalFees\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"estimateAckCostDefaultNativeSource\",\"inputs\":[{\"name\":\"multi\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"ackAmbIds\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"},{\"name\":\"srcChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"estimateMultiDstMultiVault\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structMultiDstMultiVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[][]\",\"internalType\":\"uint8[][]\"},{\"name\":\"dstChainIds\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"},{\"name\":\"superformsData\",\"type\":\"tuple[]\",\"internalType\":\"structMultiVaultSFData[]\",\"components\":[{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"outputAmounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"maxSlippages\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"liqRequests\",\"type\":\"tuple[]\",\"internalType\":\"structLiqRequest[]\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwaps\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"retain4626s\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]},{\"name\":\"isDeposit_\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[{\"name\":\"liqAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"srcAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"dstAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"estimateMultiDstSingleVault\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structMultiDstSingleVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[][]\",\"internalType\":\"uint8[][]\"},{\"name\":\"dstChainIds\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"},{\"name\":\"superformsData\",\"type\":\"tuple[]\",\"internalType\":\"structSingleVaultSFData[]\",\"components\":[{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqRequest\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]},{\"name\":\"isDeposit_\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[{\"name\":\"liqAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"srcAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"dstAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"estimateSingleDirectMultiVault\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleDirectMultiVaultStateReq\",\"components\":[{\"name\":\"superformData\",\"type\":\"tuple\",\"internalType\":\"structMultiVaultSFData\",\"components\":[{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"outputAmounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"maxSlippages\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"liqRequests\",\"type\":\"tuple[]\",\"internalType\":\"structLiqRequest[]\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwaps\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"retain4626s\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]},{\"name\":\"isDeposit_\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[{\"name\":\"liqAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"dstOrSameChainAmt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"estimateSingleDirectSingleVault\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleDirectSingleVaultStateReq\",\"components\":[{\"name\":\"superformData\",\"type\":\"tuple\",\"internalType\":\"structSingleVaultSFData\",\"components\":[{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqRequest\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]},{\"name\":\"isDeposit_\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[{\"name\":\"liqAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"dstOrSameChainAmt\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"estimateSingleXChainMultiVault\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleXChainMultiVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"superformsData\",\"type\":\"tuple\",\"internalType\":\"structMultiVaultSFData\",\"components\":[{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"outputAmounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"maxSlippages\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"liqRequests\",\"type\":\"tuple[]\",\"internalType\":\"structLiqRequest[]\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwaps\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"retain4626s\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]},{\"name\":\"isDeposit_\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[{\"name\":\"liqAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"srcAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"dstAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"estimateSingleXChainSingleVault\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleXChainSingleVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"superformData\",\"type\":\"tuple\",\"internalType\":\"structSingleVaultSFData\",\"components\":[{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqRequest\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]},{\"name\":\"isDeposit_\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[{\"name\":\"liqAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"srcAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"dstAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"totalAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"extraDataForTransmuter\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"gasPerByte\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasPerByte\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"gasPrice\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"defaultGasPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"gasPriceOracle\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractAggregatorV3Interface\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getRegisterTransmuterAMBData\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"nativeFeedOracle\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractAggregatorV3Interface\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"nativePrice\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"defaultNativePrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"superRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperRegistry\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"swapGasUsed\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasForSwap\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"timelockCost\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasForTimelock\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"updateDepositGasUsed\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasForUpdateDeposit\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"updateRegisterAERC20Params\",\"inputs\":[{\"name\":\"extraDataForTransmuter_\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updateRemoteChain\",\"inputs\":[{\"name\":\"chainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"configType_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"config_\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updateWithdrawGasUsed\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasForUpdateWithdraw\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"withdrawGasUsed\",\"inputs\":[{\"name\":\"chainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"gasForWithdraw\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"ChainConfigAdded\",\"inputs\":[{\"name\":\"chainId_\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"},{\"name\":\"config_\",\"type\":\"tuple\",\"indexed\":false,\"internalType\":\"structIPaymentHelperV2.PaymentHelperConfig\",\"components\":[{\"name\":\"nativeFeedOracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"gasPriceOracle\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"swapGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"updateDepositGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"depositGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"withdrawGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"defaultNativePrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"defaultGasPrice\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"dstGasPerByte\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"ackGasCost\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timelockCost\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"emergencyCost\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"updateWithdrawGasUsed\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ChainConfigUpdated\",\"inputs\":[{\"name\":\"chainId_\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"configType_\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"config_\",\"type\":\"bytes\",\"indexed\":false,\"internalType\":\"bytes\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ARRAY_LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BLOCK_CHAIN_ID_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CHAINLINK_INCOMPLETE_ROUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CHAINLINK_MALFUNCTION\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CHAINLINK_UNSUPPORTED_DECIMAL\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_CHAIN_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_NATIVE_TOKEN_PRICE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PAYLOAD_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_PAYMENT_ADMIN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_PROTOCOL_ADMIN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_INPUT_VALUE\",\"inputs\":[]}]",
}

// PaymentHelperABI is the input ABI used to generate the binding from.
// Deprecated: Use PaymentHelperMetaData.ABI instead.
var PaymentHelperABI = PaymentHelperMetaData.ABI

// PaymentHelper is an auto generated Go binding around an Ethereum contract.
type PaymentHelper struct {
	PaymentHelperCaller     // Read-only binding to the contract
	PaymentHelperTransactor // Write-only binding to the contract
	PaymentHelperFilterer   // Log filterer for contract events
}

// PaymentHelperCaller is an auto generated read-only Go binding around an Ethereum contract.
type PaymentHelperCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PaymentHelperTransactor is an auto generated write-only Go binding around an Ethereum contract.
type PaymentHelperTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PaymentHelperFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type PaymentHelperFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PaymentHelperSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type PaymentHelperSession struct {
	Contract     *PaymentHelper    // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// PaymentHelperCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type PaymentHelperCallerSession struct {
	Contract *PaymentHelperCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts        // Call options to use throughout this session
}

// PaymentHelperTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type PaymentHelperTransactorSession struct {
	Contract     *PaymentHelperTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts        // Transaction auth options to use throughout this session
}

// PaymentHelperRaw is an auto generated low-level Go binding around an Ethereum contract.
type PaymentHelperRaw struct {
	Contract *PaymentHelper // Generic contract binding to access the raw methods on
}

// PaymentHelperCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type PaymentHelperCallerRaw struct {
	Contract *PaymentHelperCaller // Generic read-only contract binding to access the raw methods on
}

// PaymentHelperTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type PaymentHelperTransactorRaw struct {
	Contract *PaymentHelperTransactor // Generic write-only contract binding to access the raw methods on
}

// NewPaymentHelper creates a new instance of PaymentHelper, bound to a specific deployed contract.
func NewPaymentHelper(address common.Address, backend bind.ContractBackend) (*PaymentHelper, error) {
	contract, err := bindPaymentHelper(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &PaymentHelper{PaymentHelperCaller: PaymentHelperCaller{contract: contract}, PaymentHelperTransactor: PaymentHelperTransactor{contract: contract}, PaymentHelperFilterer: PaymentHelperFilterer{contract: contract}}, nil
}

// NewPaymentHelperCaller creates a new read-only instance of PaymentHelper, bound to a specific deployed contract.
func NewPaymentHelperCaller(address common.Address, caller bind.ContractCaller) (*PaymentHelperCaller, error) {
	contract, err := bindPaymentHelper(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &PaymentHelperCaller{contract: contract}, nil
}

// NewPaymentHelperTransactor creates a new write-only instance of PaymentHelper, bound to a specific deployed contract.
func NewPaymentHelperTransactor(address common.Address, transactor bind.ContractTransactor) (*PaymentHelperTransactor, error) {
	contract, err := bindPaymentHelper(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &PaymentHelperTransactor{contract: contract}, nil
}

// NewPaymentHelperFilterer creates a new log filterer instance of PaymentHelper, bound to a specific deployed contract.
func NewPaymentHelperFilterer(address common.Address, filterer bind.ContractFilterer) (*PaymentHelperFilterer, error) {
	contract, err := bindPaymentHelper(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &PaymentHelperFilterer{contract: contract}, nil
}

// bindPaymentHelper binds a generic wrapper to an already deployed contract.
func bindPaymentHelper(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := PaymentHelperMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_PaymentHelper *PaymentHelperRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _PaymentHelper.Contract.PaymentHelperCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_PaymentHelper *PaymentHelperRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _PaymentHelper.Contract.PaymentHelperTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_PaymentHelper *PaymentHelperRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _PaymentHelper.Contract.PaymentHelperTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_PaymentHelper *PaymentHelperCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _PaymentHelper.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_PaymentHelper *PaymentHelperTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _PaymentHelper.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_PaymentHelper *PaymentHelperTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _PaymentHelper.Contract.contract.Transact(opts, method, params...)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_PaymentHelper *PaymentHelperCaller) CHAINID(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "CHAIN_ID")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_PaymentHelper *PaymentHelperSession) CHAINID() (uint64, error) {
	return _PaymentHelper.Contract.CHAINID(&_PaymentHelper.CallOpts)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_PaymentHelper *PaymentHelperCallerSession) CHAINID() (uint64, error) {
	return _PaymentHelper.Contract.CHAINID(&_PaymentHelper.CallOpts)
}

// AckGasCost is a free data retrieval call binding the contract method 0xd8bb4f4e.
//
// Solidity: function ackGasCost(uint64 chainId) view returns(uint256 gasForAck)
func (_PaymentHelper *PaymentHelperCaller) AckGasCost(opts *bind.CallOpts, chainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "ackGasCost", chainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// AckGasCost is a free data retrieval call binding the contract method 0xd8bb4f4e.
//
// Solidity: function ackGasCost(uint64 chainId) view returns(uint256 gasForAck)
func (_PaymentHelper *PaymentHelperSession) AckGasCost(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.AckGasCost(&_PaymentHelper.CallOpts, chainId)
}

// AckGasCost is a free data retrieval call binding the contract method 0xd8bb4f4e.
//
// Solidity: function ackGasCost(uint64 chainId) view returns(uint256 gasForAck)
func (_PaymentHelper *PaymentHelperCallerSession) AckGasCost(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.AckGasCost(&_PaymentHelper.CallOpts, chainId)
}

// CalculateAMBData is a free data retrieval call binding the contract method 0x3283166a.
//
// Solidity: function calculateAMBData(uint64 dstChainId_, uint8[] ambIds_, bytes message_) view returns(uint256 totalFees, bytes extraData)
func (_PaymentHelper *PaymentHelperCaller) CalculateAMBData(opts *bind.CallOpts, dstChainId_ uint64, ambIds_ []uint8, message_ []byte) (struct {
	TotalFees *big.Int
	ExtraData []byte
}, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "calculateAMBData", dstChainId_, ambIds_, message_)

	outstruct := new(struct {
		TotalFees *big.Int
		ExtraData []byte
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.TotalFees = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.ExtraData = *abi.ConvertType(out[1], new([]byte)).(*[]byte)

	return *outstruct, err

}

// CalculateAMBData is a free data retrieval call binding the contract method 0x3283166a.
//
// Solidity: function calculateAMBData(uint64 dstChainId_, uint8[] ambIds_, bytes message_) view returns(uint256 totalFees, bytes extraData)
func (_PaymentHelper *PaymentHelperSession) CalculateAMBData(dstChainId_ uint64, ambIds_ []uint8, message_ []byte) (struct {
	TotalFees *big.Int
	ExtraData []byte
}, error) {
	return _PaymentHelper.Contract.CalculateAMBData(&_PaymentHelper.CallOpts, dstChainId_, ambIds_, message_)
}

// CalculateAMBData is a free data retrieval call binding the contract method 0x3283166a.
//
// Solidity: function calculateAMBData(uint64 dstChainId_, uint8[] ambIds_, bytes message_) view returns(uint256 totalFees, bytes extraData)
func (_PaymentHelper *PaymentHelperCallerSession) CalculateAMBData(dstChainId_ uint64, ambIds_ []uint8, message_ []byte) (struct {
	TotalFees *big.Int
	ExtraData []byte
}, error) {
	return _PaymentHelper.Contract.CalculateAMBData(&_PaymentHelper.CallOpts, dstChainId_, ambIds_, message_)
}

// DepositGasUsed is a free data retrieval call binding the contract method 0x4c75c0d8.
//
// Solidity: function depositGasUsed(uint64 chainId) view returns(uint256 gasForDeposit)
func (_PaymentHelper *PaymentHelperCaller) DepositGasUsed(opts *bind.CallOpts, chainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "depositGasUsed", chainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// DepositGasUsed is a free data retrieval call binding the contract method 0x4c75c0d8.
//
// Solidity: function depositGasUsed(uint64 chainId) view returns(uint256 gasForDeposit)
func (_PaymentHelper *PaymentHelperSession) DepositGasUsed(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.DepositGasUsed(&_PaymentHelper.CallOpts, chainId)
}

// DepositGasUsed is a free data retrieval call binding the contract method 0x4c75c0d8.
//
// Solidity: function depositGasUsed(uint64 chainId) view returns(uint256 gasForDeposit)
func (_PaymentHelper *PaymentHelperCallerSession) DepositGasUsed(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.DepositGasUsed(&_PaymentHelper.CallOpts, chainId)
}

// EmergencyCost is a free data retrieval call binding the contract method 0x0292540b.
//
// Solidity: function emergencyCost(uint64 chainId) view returns(uint256 gasForEmergency)
func (_PaymentHelper *PaymentHelperCaller) EmergencyCost(opts *bind.CallOpts, chainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "emergencyCost", chainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// EmergencyCost is a free data retrieval call binding the contract method 0x0292540b.
//
// Solidity: function emergencyCost(uint64 chainId) view returns(uint256 gasForEmergency)
func (_PaymentHelper *PaymentHelperSession) EmergencyCost(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.EmergencyCost(&_PaymentHelper.CallOpts, chainId)
}

// EmergencyCost is a free data retrieval call binding the contract method 0x0292540b.
//
// Solidity: function emergencyCost(uint64 chainId) view returns(uint256 gasForEmergency)
func (_PaymentHelper *PaymentHelperCallerSession) EmergencyCost(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.EmergencyCost(&_PaymentHelper.CallOpts, chainId)
}

// EstimateAMBFees is a free data retrieval call binding the contract method 0x1f864be3.
//
// Solidity: function estimateAMBFees(uint8[] ambIds_, uint64 dstChainId_, bytes message_, bytes[] extraData_) view returns(uint256 totalFees, uint256[])
func (_PaymentHelper *PaymentHelperCaller) EstimateAMBFees(opts *bind.CallOpts, ambIds_ []uint8, dstChainId_ uint64, message_ []byte, extraData_ [][]byte) (*big.Int, []*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "estimateAMBFees", ambIds_, dstChainId_, message_, extraData_)

	if err != nil {
		return *new(*big.Int), *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	out1 := *abi.ConvertType(out[1], new([]*big.Int)).(*[]*big.Int)

	return out0, out1, err

}

// EstimateAMBFees is a free data retrieval call binding the contract method 0x1f864be3.
//
// Solidity: function estimateAMBFees(uint8[] ambIds_, uint64 dstChainId_, bytes message_, bytes[] extraData_) view returns(uint256 totalFees, uint256[])
func (_PaymentHelper *PaymentHelperSession) EstimateAMBFees(ambIds_ []uint8, dstChainId_ uint64, message_ []byte, extraData_ [][]byte) (*big.Int, []*big.Int, error) {
	return _PaymentHelper.Contract.EstimateAMBFees(&_PaymentHelper.CallOpts, ambIds_, dstChainId_, message_, extraData_)
}

// EstimateAMBFees is a free data retrieval call binding the contract method 0x1f864be3.
//
// Solidity: function estimateAMBFees(uint8[] ambIds_, uint64 dstChainId_, bytes message_, bytes[] extraData_) view returns(uint256 totalFees, uint256[])
func (_PaymentHelper *PaymentHelperCallerSession) EstimateAMBFees(ambIds_ []uint8, dstChainId_ uint64, message_ []byte, extraData_ [][]byte) (*big.Int, []*big.Int, error) {
	return _PaymentHelper.Contract.EstimateAMBFees(&_PaymentHelper.CallOpts, ambIds_, dstChainId_, message_, extraData_)
}

// EstimateAckCost is a free data retrieval call binding the contract method 0x596703e7.
//
// Solidity: function estimateAckCost(uint256 payloadId_) view returns(uint256 totalFees)
func (_PaymentHelper *PaymentHelperCaller) EstimateAckCost(opts *bind.CallOpts, payloadId_ *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "estimateAckCost", payloadId_)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// EstimateAckCost is a free data retrieval call binding the contract method 0x596703e7.
//
// Solidity: function estimateAckCost(uint256 payloadId_) view returns(uint256 totalFees)
func (_PaymentHelper *PaymentHelperSession) EstimateAckCost(payloadId_ *big.Int) (*big.Int, error) {
	return _PaymentHelper.Contract.EstimateAckCost(&_PaymentHelper.CallOpts, payloadId_)
}

// EstimateAckCost is a free data retrieval call binding the contract method 0x596703e7.
//
// Solidity: function estimateAckCost(uint256 payloadId_) view returns(uint256 totalFees)
func (_PaymentHelper *PaymentHelperCallerSession) EstimateAckCost(payloadId_ *big.Int) (*big.Int, error) {
	return _PaymentHelper.Contract.EstimateAckCost(&_PaymentHelper.CallOpts, payloadId_)
}

// EstimateAckCostDefault is a free data retrieval call binding the contract method 0x36c7fe1d.
//
// Solidity: function estimateAckCostDefault(bool multi, uint8[] ackAmbIds, uint64 srcChainId) view returns(uint256 totalFees)
func (_PaymentHelper *PaymentHelperCaller) EstimateAckCostDefault(opts *bind.CallOpts, multi bool, ackAmbIds []uint8, srcChainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "estimateAckCostDefault", multi, ackAmbIds, srcChainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// EstimateAckCostDefault is a free data retrieval call binding the contract method 0x36c7fe1d.
//
// Solidity: function estimateAckCostDefault(bool multi, uint8[] ackAmbIds, uint64 srcChainId) view returns(uint256 totalFees)
func (_PaymentHelper *PaymentHelperSession) EstimateAckCostDefault(multi bool, ackAmbIds []uint8, srcChainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.EstimateAckCostDefault(&_PaymentHelper.CallOpts, multi, ackAmbIds, srcChainId)
}

// EstimateAckCostDefault is a free data retrieval call binding the contract method 0x36c7fe1d.
//
// Solidity: function estimateAckCostDefault(bool multi, uint8[] ackAmbIds, uint64 srcChainId) view returns(uint256 totalFees)
func (_PaymentHelper *PaymentHelperCallerSession) EstimateAckCostDefault(multi bool, ackAmbIds []uint8, srcChainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.EstimateAckCostDefault(&_PaymentHelper.CallOpts, multi, ackAmbIds, srcChainId)
}

// EstimateAckCostDefaultNativeSource is a free data retrieval call binding the contract method 0xb1752d59.
//
// Solidity: function estimateAckCostDefaultNativeSource(bool multi, uint8[] ackAmbIds, uint64 srcChainId) view returns(uint256)
func (_PaymentHelper *PaymentHelperCaller) EstimateAckCostDefaultNativeSource(opts *bind.CallOpts, multi bool, ackAmbIds []uint8, srcChainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "estimateAckCostDefaultNativeSource", multi, ackAmbIds, srcChainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// EstimateAckCostDefaultNativeSource is a free data retrieval call binding the contract method 0xb1752d59.
//
// Solidity: function estimateAckCostDefaultNativeSource(bool multi, uint8[] ackAmbIds, uint64 srcChainId) view returns(uint256)
func (_PaymentHelper *PaymentHelperSession) EstimateAckCostDefaultNativeSource(multi bool, ackAmbIds []uint8, srcChainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.EstimateAckCostDefaultNativeSource(&_PaymentHelper.CallOpts, multi, ackAmbIds, srcChainId)
}

// EstimateAckCostDefaultNativeSource is a free data retrieval call binding the contract method 0xb1752d59.
//
// Solidity: function estimateAckCostDefaultNativeSource(bool multi, uint8[] ackAmbIds, uint64 srcChainId) view returns(uint256)
func (_PaymentHelper *PaymentHelperCallerSession) EstimateAckCostDefaultNativeSource(multi bool, ackAmbIds []uint8, srcChainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.EstimateAckCostDefaultNativeSource(&_PaymentHelper.CallOpts, multi, ackAmbIds, srcChainId)
}

// EstimateMultiDstMultiVault is a free data retrieval call binding the contract method 0xf3afdd88.
//
// Solidity: function estimateMultiDstMultiVault((uint8[][],uint64[],(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)[]) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCaller) EstimateMultiDstMultiVault(opts *bind.CallOpts, req_ MultiDstMultiVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "estimateMultiDstMultiVault", req_, isDeposit_)

	outstruct := new(struct {
		LiqAmount   *big.Int
		SrcAmount   *big.Int
		DstAmount   *big.Int
		TotalAmount *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.LiqAmount = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.SrcAmount = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.DstAmount = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.TotalAmount = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// EstimateMultiDstMultiVault is a free data retrieval call binding the contract method 0xf3afdd88.
//
// Solidity: function estimateMultiDstMultiVault((uint8[][],uint64[],(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)[]) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperSession) EstimateMultiDstMultiVault(req_ MultiDstMultiVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateMultiDstMultiVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// EstimateMultiDstMultiVault is a free data retrieval call binding the contract method 0xf3afdd88.
//
// Solidity: function estimateMultiDstMultiVault((uint8[][],uint64[],(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)[]) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCallerSession) EstimateMultiDstMultiVault(req_ MultiDstMultiVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateMultiDstMultiVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// EstimateMultiDstSingleVault is a free data retrieval call binding the contract method 0xd7013974.
//
// Solidity: function estimateMultiDstSingleVault((uint8[][],uint64[],(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)[]) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCaller) EstimateMultiDstSingleVault(opts *bind.CallOpts, req_ MultiDstSingleVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "estimateMultiDstSingleVault", req_, isDeposit_)

	outstruct := new(struct {
		LiqAmount   *big.Int
		SrcAmount   *big.Int
		DstAmount   *big.Int
		TotalAmount *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.LiqAmount = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.SrcAmount = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.DstAmount = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.TotalAmount = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// EstimateMultiDstSingleVault is a free data retrieval call binding the contract method 0xd7013974.
//
// Solidity: function estimateMultiDstSingleVault((uint8[][],uint64[],(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)[]) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperSession) EstimateMultiDstSingleVault(req_ MultiDstSingleVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateMultiDstSingleVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// EstimateMultiDstSingleVault is a free data retrieval call binding the contract method 0xd7013974.
//
// Solidity: function estimateMultiDstSingleVault((uint8[][],uint64[],(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)[]) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCallerSession) EstimateMultiDstSingleVault(req_ MultiDstSingleVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateMultiDstSingleVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// EstimateSingleDirectMultiVault is a free data retrieval call binding the contract method 0x7504988b.
//
// Solidity: function estimateSingleDirectMultiVault(((uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 dstOrSameChainAmt, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCaller) EstimateSingleDirectMultiVault(opts *bind.CallOpts, req_ SingleDirectMultiVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount         *big.Int
	DstOrSameChainAmt *big.Int
	TotalAmount       *big.Int
}, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "estimateSingleDirectMultiVault", req_, isDeposit_)

	outstruct := new(struct {
		LiqAmount         *big.Int
		DstOrSameChainAmt *big.Int
		TotalAmount       *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.LiqAmount = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.DstOrSameChainAmt = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.TotalAmount = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// EstimateSingleDirectMultiVault is a free data retrieval call binding the contract method 0x7504988b.
//
// Solidity: function estimateSingleDirectMultiVault(((uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 dstOrSameChainAmt, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperSession) EstimateSingleDirectMultiVault(req_ SingleDirectMultiVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount         *big.Int
	DstOrSameChainAmt *big.Int
	TotalAmount       *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateSingleDirectMultiVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// EstimateSingleDirectMultiVault is a free data retrieval call binding the contract method 0x7504988b.
//
// Solidity: function estimateSingleDirectMultiVault(((uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 dstOrSameChainAmt, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCallerSession) EstimateSingleDirectMultiVault(req_ SingleDirectMultiVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount         *big.Int
	DstOrSameChainAmt *big.Int
	TotalAmount       *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateSingleDirectMultiVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// EstimateSingleDirectSingleVault is a free data retrieval call binding the contract method 0xf3d80846.
//
// Solidity: function estimateSingleDirectSingleVault(((uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 dstOrSameChainAmt, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCaller) EstimateSingleDirectSingleVault(opts *bind.CallOpts, req_ SingleDirectSingleVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount         *big.Int
	DstOrSameChainAmt *big.Int
	TotalAmount       *big.Int
}, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "estimateSingleDirectSingleVault", req_, isDeposit_)

	outstruct := new(struct {
		LiqAmount         *big.Int
		DstOrSameChainAmt *big.Int
		TotalAmount       *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.LiqAmount = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.DstOrSameChainAmt = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.TotalAmount = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// EstimateSingleDirectSingleVault is a free data retrieval call binding the contract method 0xf3d80846.
//
// Solidity: function estimateSingleDirectSingleVault(((uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 dstOrSameChainAmt, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperSession) EstimateSingleDirectSingleVault(req_ SingleDirectSingleVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount         *big.Int
	DstOrSameChainAmt *big.Int
	TotalAmount       *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateSingleDirectSingleVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// EstimateSingleDirectSingleVault is a free data retrieval call binding the contract method 0xf3d80846.
//
// Solidity: function estimateSingleDirectSingleVault(((uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 dstOrSameChainAmt, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCallerSession) EstimateSingleDirectSingleVault(req_ SingleDirectSingleVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount         *big.Int
	DstOrSameChainAmt *big.Int
	TotalAmount       *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateSingleDirectSingleVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// EstimateSingleXChainMultiVault is a free data retrieval call binding the contract method 0xc97c55b0.
//
// Solidity: function estimateSingleXChainMultiVault((uint8[],uint64,(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCaller) EstimateSingleXChainMultiVault(opts *bind.CallOpts, req_ SingleXChainMultiVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "estimateSingleXChainMultiVault", req_, isDeposit_)

	outstruct := new(struct {
		LiqAmount   *big.Int
		SrcAmount   *big.Int
		DstAmount   *big.Int
		TotalAmount *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.LiqAmount = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.SrcAmount = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.DstAmount = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.TotalAmount = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// EstimateSingleXChainMultiVault is a free data retrieval call binding the contract method 0xc97c55b0.
//
// Solidity: function estimateSingleXChainMultiVault((uint8[],uint64,(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperSession) EstimateSingleXChainMultiVault(req_ SingleXChainMultiVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateSingleXChainMultiVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// EstimateSingleXChainMultiVault is a free data retrieval call binding the contract method 0xc97c55b0.
//
// Solidity: function estimateSingleXChainMultiVault((uint8[],uint64,(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCallerSession) EstimateSingleXChainMultiVault(req_ SingleXChainMultiVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateSingleXChainMultiVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// EstimateSingleXChainSingleVault is a free data retrieval call binding the contract method 0x61d26cae.
//
// Solidity: function estimateSingleXChainSingleVault((uint8[],uint64,(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCaller) EstimateSingleXChainSingleVault(opts *bind.CallOpts, req_ SingleXChainSingleVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "estimateSingleXChainSingleVault", req_, isDeposit_)

	outstruct := new(struct {
		LiqAmount   *big.Int
		SrcAmount   *big.Int
		DstAmount   *big.Int
		TotalAmount *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.LiqAmount = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.SrcAmount = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.DstAmount = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.TotalAmount = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// EstimateSingleXChainSingleVault is a free data retrieval call binding the contract method 0x61d26cae.
//
// Solidity: function estimateSingleXChainSingleVault((uint8[],uint64,(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperSession) EstimateSingleXChainSingleVault(req_ SingleXChainSingleVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateSingleXChainSingleVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// EstimateSingleXChainSingleVault is a free data retrieval call binding the contract method 0x61d26cae.
//
// Solidity: function estimateSingleXChainSingleVault((uint8[],uint64,(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_, bool isDeposit_) view returns(uint256 liqAmount, uint256 srcAmount, uint256 dstAmount, uint256 totalAmount)
func (_PaymentHelper *PaymentHelperCallerSession) EstimateSingleXChainSingleVault(req_ SingleXChainSingleVaultStateReq, isDeposit_ bool) (struct {
	LiqAmount   *big.Int
	SrcAmount   *big.Int
	DstAmount   *big.Int
	TotalAmount *big.Int
}, error) {
	return _PaymentHelper.Contract.EstimateSingleXChainSingleVault(&_PaymentHelper.CallOpts, req_, isDeposit_)
}

// ExtraDataForTransmuter is a free data retrieval call binding the contract method 0xda163637.
//
// Solidity: function extraDataForTransmuter() view returns(bytes)
func (_PaymentHelper *PaymentHelperCaller) ExtraDataForTransmuter(opts *bind.CallOpts) ([]byte, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "extraDataForTransmuter")

	if err != nil {
		return *new([]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([]byte)).(*[]byte)

	return out0, err

}

// ExtraDataForTransmuter is a free data retrieval call binding the contract method 0xda163637.
//
// Solidity: function extraDataForTransmuter() view returns(bytes)
func (_PaymentHelper *PaymentHelperSession) ExtraDataForTransmuter() ([]byte, error) {
	return _PaymentHelper.Contract.ExtraDataForTransmuter(&_PaymentHelper.CallOpts)
}

// ExtraDataForTransmuter is a free data retrieval call binding the contract method 0xda163637.
//
// Solidity: function extraDataForTransmuter() view returns(bytes)
func (_PaymentHelper *PaymentHelperCallerSession) ExtraDataForTransmuter() ([]byte, error) {
	return _PaymentHelper.Contract.ExtraDataForTransmuter(&_PaymentHelper.CallOpts)
}

// GasPerByte is a free data retrieval call binding the contract method 0x904b1a28.
//
// Solidity: function gasPerByte(uint64 chainId) view returns(uint256 gasPerByte)
func (_PaymentHelper *PaymentHelperCaller) GasPerByte(opts *bind.CallOpts, chainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "gasPerByte", chainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GasPerByte is a free data retrieval call binding the contract method 0x904b1a28.
//
// Solidity: function gasPerByte(uint64 chainId) view returns(uint256 gasPerByte)
func (_PaymentHelper *PaymentHelperSession) GasPerByte(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.GasPerByte(&_PaymentHelper.CallOpts, chainId)
}

// GasPerByte is a free data retrieval call binding the contract method 0x904b1a28.
//
// Solidity: function gasPerByte(uint64 chainId) view returns(uint256 gasPerByte)
func (_PaymentHelper *PaymentHelperCallerSession) GasPerByte(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.GasPerByte(&_PaymentHelper.CallOpts, chainId)
}

// GasPrice is a free data retrieval call binding the contract method 0x4786b424.
//
// Solidity: function gasPrice(uint64 chainId) view returns(uint256 defaultGasPrice)
func (_PaymentHelper *PaymentHelperCaller) GasPrice(opts *bind.CallOpts, chainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "gasPrice", chainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GasPrice is a free data retrieval call binding the contract method 0x4786b424.
//
// Solidity: function gasPrice(uint64 chainId) view returns(uint256 defaultGasPrice)
func (_PaymentHelper *PaymentHelperSession) GasPrice(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.GasPrice(&_PaymentHelper.CallOpts, chainId)
}

// GasPrice is a free data retrieval call binding the contract method 0x4786b424.
//
// Solidity: function gasPrice(uint64 chainId) view returns(uint256 defaultGasPrice)
func (_PaymentHelper *PaymentHelperCallerSession) GasPrice(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.GasPrice(&_PaymentHelper.CallOpts, chainId)
}

// GasPriceOracle is a free data retrieval call binding the contract method 0x49c3af45.
//
// Solidity: function gasPriceOracle(uint64 chainId) view returns(address)
func (_PaymentHelper *PaymentHelperCaller) GasPriceOracle(opts *bind.CallOpts, chainId uint64) (common.Address, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "gasPriceOracle", chainId)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GasPriceOracle is a free data retrieval call binding the contract method 0x49c3af45.
//
// Solidity: function gasPriceOracle(uint64 chainId) view returns(address)
func (_PaymentHelper *PaymentHelperSession) GasPriceOracle(chainId uint64) (common.Address, error) {
	return _PaymentHelper.Contract.GasPriceOracle(&_PaymentHelper.CallOpts, chainId)
}

// GasPriceOracle is a free data retrieval call binding the contract method 0x49c3af45.
//
// Solidity: function gasPriceOracle(uint64 chainId) view returns(address)
func (_PaymentHelper *PaymentHelperCallerSession) GasPriceOracle(chainId uint64) (common.Address, error) {
	return _PaymentHelper.Contract.GasPriceOracle(&_PaymentHelper.CallOpts, chainId)
}

// GetRegisterTransmuterAMBData is a free data retrieval call binding the contract method 0x53d69edc.
//
// Solidity: function getRegisterTransmuterAMBData() view returns(bytes)
func (_PaymentHelper *PaymentHelperCaller) GetRegisterTransmuterAMBData(opts *bind.CallOpts) ([]byte, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "getRegisterTransmuterAMBData")

	if err != nil {
		return *new([]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([]byte)).(*[]byte)

	return out0, err

}

// GetRegisterTransmuterAMBData is a free data retrieval call binding the contract method 0x53d69edc.
//
// Solidity: function getRegisterTransmuterAMBData() view returns(bytes)
func (_PaymentHelper *PaymentHelperSession) GetRegisterTransmuterAMBData() ([]byte, error) {
	return _PaymentHelper.Contract.GetRegisterTransmuterAMBData(&_PaymentHelper.CallOpts)
}

// GetRegisterTransmuterAMBData is a free data retrieval call binding the contract method 0x53d69edc.
//
// Solidity: function getRegisterTransmuterAMBData() view returns(bytes)
func (_PaymentHelper *PaymentHelperCallerSession) GetRegisterTransmuterAMBData() ([]byte, error) {
	return _PaymentHelper.Contract.GetRegisterTransmuterAMBData(&_PaymentHelper.CallOpts)
}

// NativeFeedOracle is a free data retrieval call binding the contract method 0x12c4da86.
//
// Solidity: function nativeFeedOracle(uint64 chainId) view returns(address)
func (_PaymentHelper *PaymentHelperCaller) NativeFeedOracle(opts *bind.CallOpts, chainId uint64) (common.Address, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "nativeFeedOracle", chainId)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// NativeFeedOracle is a free data retrieval call binding the contract method 0x12c4da86.
//
// Solidity: function nativeFeedOracle(uint64 chainId) view returns(address)
func (_PaymentHelper *PaymentHelperSession) NativeFeedOracle(chainId uint64) (common.Address, error) {
	return _PaymentHelper.Contract.NativeFeedOracle(&_PaymentHelper.CallOpts, chainId)
}

// NativeFeedOracle is a free data retrieval call binding the contract method 0x12c4da86.
//
// Solidity: function nativeFeedOracle(uint64 chainId) view returns(address)
func (_PaymentHelper *PaymentHelperCallerSession) NativeFeedOracle(chainId uint64) (common.Address, error) {
	return _PaymentHelper.Contract.NativeFeedOracle(&_PaymentHelper.CallOpts, chainId)
}

// NativePrice is a free data retrieval call binding the contract method 0x4545fc31.
//
// Solidity: function nativePrice(uint64 chainId) view returns(uint256 defaultNativePrice)
func (_PaymentHelper *PaymentHelperCaller) NativePrice(opts *bind.CallOpts, chainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "nativePrice", chainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// NativePrice is a free data retrieval call binding the contract method 0x4545fc31.
//
// Solidity: function nativePrice(uint64 chainId) view returns(uint256 defaultNativePrice)
func (_PaymentHelper *PaymentHelperSession) NativePrice(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.NativePrice(&_PaymentHelper.CallOpts, chainId)
}

// NativePrice is a free data retrieval call binding the contract method 0x4545fc31.
//
// Solidity: function nativePrice(uint64 chainId) view returns(uint256 defaultNativePrice)
func (_PaymentHelper *PaymentHelperCallerSession) NativePrice(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.NativePrice(&_PaymentHelper.CallOpts, chainId)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_PaymentHelper *PaymentHelperCaller) SuperRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "superRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_PaymentHelper *PaymentHelperSession) SuperRegistry() (common.Address, error) {
	return _PaymentHelper.Contract.SuperRegistry(&_PaymentHelper.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_PaymentHelper *PaymentHelperCallerSession) SuperRegistry() (common.Address, error) {
	return _PaymentHelper.Contract.SuperRegistry(&_PaymentHelper.CallOpts)
}

// SwapGasUsed is a free data retrieval call binding the contract method 0xa9ce4648.
//
// Solidity: function swapGasUsed(uint64 chainId) view returns(uint256 gasForSwap)
func (_PaymentHelper *PaymentHelperCaller) SwapGasUsed(opts *bind.CallOpts, chainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "swapGasUsed", chainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// SwapGasUsed is a free data retrieval call binding the contract method 0xa9ce4648.
//
// Solidity: function swapGasUsed(uint64 chainId) view returns(uint256 gasForSwap)
func (_PaymentHelper *PaymentHelperSession) SwapGasUsed(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.SwapGasUsed(&_PaymentHelper.CallOpts, chainId)
}

// SwapGasUsed is a free data retrieval call binding the contract method 0xa9ce4648.
//
// Solidity: function swapGasUsed(uint64 chainId) view returns(uint256 gasForSwap)
func (_PaymentHelper *PaymentHelperCallerSession) SwapGasUsed(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.SwapGasUsed(&_PaymentHelper.CallOpts, chainId)
}

// TimelockCost is a free data retrieval call binding the contract method 0x1f5ae58f.
//
// Solidity: function timelockCost(uint64 chainId) view returns(uint256 gasForTimelock)
func (_PaymentHelper *PaymentHelperCaller) TimelockCost(opts *bind.CallOpts, chainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "timelockCost", chainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TimelockCost is a free data retrieval call binding the contract method 0x1f5ae58f.
//
// Solidity: function timelockCost(uint64 chainId) view returns(uint256 gasForTimelock)
func (_PaymentHelper *PaymentHelperSession) TimelockCost(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.TimelockCost(&_PaymentHelper.CallOpts, chainId)
}

// TimelockCost is a free data retrieval call binding the contract method 0x1f5ae58f.
//
// Solidity: function timelockCost(uint64 chainId) view returns(uint256 gasForTimelock)
func (_PaymentHelper *PaymentHelperCallerSession) TimelockCost(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.TimelockCost(&_PaymentHelper.CallOpts, chainId)
}

// UpdateDepositGasUsed is a free data retrieval call binding the contract method 0x786c69f3.
//
// Solidity: function updateDepositGasUsed(uint64 chainId) view returns(uint256 gasForUpdateDeposit)
func (_PaymentHelper *PaymentHelperCaller) UpdateDepositGasUsed(opts *bind.CallOpts, chainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "updateDepositGasUsed", chainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// UpdateDepositGasUsed is a free data retrieval call binding the contract method 0x786c69f3.
//
// Solidity: function updateDepositGasUsed(uint64 chainId) view returns(uint256 gasForUpdateDeposit)
func (_PaymentHelper *PaymentHelperSession) UpdateDepositGasUsed(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.UpdateDepositGasUsed(&_PaymentHelper.CallOpts, chainId)
}

// UpdateDepositGasUsed is a free data retrieval call binding the contract method 0x786c69f3.
//
// Solidity: function updateDepositGasUsed(uint64 chainId) view returns(uint256 gasForUpdateDeposit)
func (_PaymentHelper *PaymentHelperCallerSession) UpdateDepositGasUsed(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.UpdateDepositGasUsed(&_PaymentHelper.CallOpts, chainId)
}

// UpdateWithdrawGasUsed is a free data retrieval call binding the contract method 0x10c5fbe4.
//
// Solidity: function updateWithdrawGasUsed(uint64 chainId) view returns(uint256 gasForUpdateWithdraw)
func (_PaymentHelper *PaymentHelperCaller) UpdateWithdrawGasUsed(opts *bind.CallOpts, chainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "updateWithdrawGasUsed", chainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// UpdateWithdrawGasUsed is a free data retrieval call binding the contract method 0x10c5fbe4.
//
// Solidity: function updateWithdrawGasUsed(uint64 chainId) view returns(uint256 gasForUpdateWithdraw)
func (_PaymentHelper *PaymentHelperSession) UpdateWithdrawGasUsed(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.UpdateWithdrawGasUsed(&_PaymentHelper.CallOpts, chainId)
}

// UpdateWithdrawGasUsed is a free data retrieval call binding the contract method 0x10c5fbe4.
//
// Solidity: function updateWithdrawGasUsed(uint64 chainId) view returns(uint256 gasForUpdateWithdraw)
func (_PaymentHelper *PaymentHelperCallerSession) UpdateWithdrawGasUsed(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.UpdateWithdrawGasUsed(&_PaymentHelper.CallOpts, chainId)
}

// WithdrawGasUsed is a free data retrieval call binding the contract method 0x7f7aecb5.
//
// Solidity: function withdrawGasUsed(uint64 chainId) view returns(uint256 gasForWithdraw)
func (_PaymentHelper *PaymentHelperCaller) WithdrawGasUsed(opts *bind.CallOpts, chainId uint64) (*big.Int, error) {
	var out []interface{}
	err := _PaymentHelper.contract.Call(opts, &out, "withdrawGasUsed", chainId)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// WithdrawGasUsed is a free data retrieval call binding the contract method 0x7f7aecb5.
//
// Solidity: function withdrawGasUsed(uint64 chainId) view returns(uint256 gasForWithdraw)
func (_PaymentHelper *PaymentHelperSession) WithdrawGasUsed(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.WithdrawGasUsed(&_PaymentHelper.CallOpts, chainId)
}

// WithdrawGasUsed is a free data retrieval call binding the contract method 0x7f7aecb5.
//
// Solidity: function withdrawGasUsed(uint64 chainId) view returns(uint256 gasForWithdraw)
func (_PaymentHelper *PaymentHelperCallerSession) WithdrawGasUsed(chainId uint64) (*big.Int, error) {
	return _PaymentHelper.Contract.WithdrawGasUsed(&_PaymentHelper.CallOpts, chainId)
}

// AddRemoteChain is a paid mutator transaction binding the contract method 0xa8a08389.
//
// Solidity: function addRemoteChain(uint64 chainId_, (address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) config_) returns()
func (_PaymentHelper *PaymentHelperTransactor) AddRemoteChain(opts *bind.TransactOpts, chainId_ uint64, config_ IPaymentHelperV2PaymentHelperConfig) (*types.Transaction, error) {
	return _PaymentHelper.contract.Transact(opts, "addRemoteChain", chainId_, config_)
}

// AddRemoteChain is a paid mutator transaction binding the contract method 0xa8a08389.
//
// Solidity: function addRemoteChain(uint64 chainId_, (address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) config_) returns()
func (_PaymentHelper *PaymentHelperSession) AddRemoteChain(chainId_ uint64, config_ IPaymentHelperV2PaymentHelperConfig) (*types.Transaction, error) {
	return _PaymentHelper.Contract.AddRemoteChain(&_PaymentHelper.TransactOpts, chainId_, config_)
}

// AddRemoteChain is a paid mutator transaction binding the contract method 0xa8a08389.
//
// Solidity: function addRemoteChain(uint64 chainId_, (address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) config_) returns()
func (_PaymentHelper *PaymentHelperTransactorSession) AddRemoteChain(chainId_ uint64, config_ IPaymentHelperV2PaymentHelperConfig) (*types.Transaction, error) {
	return _PaymentHelper.Contract.AddRemoteChain(&_PaymentHelper.TransactOpts, chainId_, config_)
}

// AddRemoteChains is a paid mutator transaction binding the contract method 0x9d57d64e.
//
// Solidity: function addRemoteChains(uint64[] chainIds_, (address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)[] configs_) returns()
func (_PaymentHelper *PaymentHelperTransactor) AddRemoteChains(opts *bind.TransactOpts, chainIds_ []uint64, configs_ []IPaymentHelperV2PaymentHelperConfig) (*types.Transaction, error) {
	return _PaymentHelper.contract.Transact(opts, "addRemoteChains", chainIds_, configs_)
}

// AddRemoteChains is a paid mutator transaction binding the contract method 0x9d57d64e.
//
// Solidity: function addRemoteChains(uint64[] chainIds_, (address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)[] configs_) returns()
func (_PaymentHelper *PaymentHelperSession) AddRemoteChains(chainIds_ []uint64, configs_ []IPaymentHelperV2PaymentHelperConfig) (*types.Transaction, error) {
	return _PaymentHelper.Contract.AddRemoteChains(&_PaymentHelper.TransactOpts, chainIds_, configs_)
}

// AddRemoteChains is a paid mutator transaction binding the contract method 0x9d57d64e.
//
// Solidity: function addRemoteChains(uint64[] chainIds_, (address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)[] configs_) returns()
func (_PaymentHelper *PaymentHelperTransactorSession) AddRemoteChains(chainIds_ []uint64, configs_ []IPaymentHelperV2PaymentHelperConfig) (*types.Transaction, error) {
	return _PaymentHelper.Contract.AddRemoteChains(&_PaymentHelper.TransactOpts, chainIds_, configs_)
}

// BatchUpdateRemoteChain is a paid mutator transaction binding the contract method 0xc2085f46.
//
// Solidity: function batchUpdateRemoteChain(uint64 chainId_, uint256[] configTypes_, bytes[] configs_) returns()
func (_PaymentHelper *PaymentHelperTransactor) BatchUpdateRemoteChain(opts *bind.TransactOpts, chainId_ uint64, configTypes_ []*big.Int, configs_ [][]byte) (*types.Transaction, error) {
	return _PaymentHelper.contract.Transact(opts, "batchUpdateRemoteChain", chainId_, configTypes_, configs_)
}

// BatchUpdateRemoteChain is a paid mutator transaction binding the contract method 0xc2085f46.
//
// Solidity: function batchUpdateRemoteChain(uint64 chainId_, uint256[] configTypes_, bytes[] configs_) returns()
func (_PaymentHelper *PaymentHelperSession) BatchUpdateRemoteChain(chainId_ uint64, configTypes_ []*big.Int, configs_ [][]byte) (*types.Transaction, error) {
	return _PaymentHelper.Contract.BatchUpdateRemoteChain(&_PaymentHelper.TransactOpts, chainId_, configTypes_, configs_)
}

// BatchUpdateRemoteChain is a paid mutator transaction binding the contract method 0xc2085f46.
//
// Solidity: function batchUpdateRemoteChain(uint64 chainId_, uint256[] configTypes_, bytes[] configs_) returns()
func (_PaymentHelper *PaymentHelperTransactorSession) BatchUpdateRemoteChain(chainId_ uint64, configTypes_ []*big.Int, configs_ [][]byte) (*types.Transaction, error) {
	return _PaymentHelper.Contract.BatchUpdateRemoteChain(&_PaymentHelper.TransactOpts, chainId_, configTypes_, configs_)
}

// BatchUpdateRemoteChains is a paid mutator transaction binding the contract method 0xea7a8392.
//
// Solidity: function batchUpdateRemoteChains(uint64[] chainIds_, uint256[][] configTypes_, bytes[][] configs_) returns()
func (_PaymentHelper *PaymentHelperTransactor) BatchUpdateRemoteChains(opts *bind.TransactOpts, chainIds_ []uint64, configTypes_ [][]*big.Int, configs_ [][][]byte) (*types.Transaction, error) {
	return _PaymentHelper.contract.Transact(opts, "batchUpdateRemoteChains", chainIds_, configTypes_, configs_)
}

// BatchUpdateRemoteChains is a paid mutator transaction binding the contract method 0xea7a8392.
//
// Solidity: function batchUpdateRemoteChains(uint64[] chainIds_, uint256[][] configTypes_, bytes[][] configs_) returns()
func (_PaymentHelper *PaymentHelperSession) BatchUpdateRemoteChains(chainIds_ []uint64, configTypes_ [][]*big.Int, configs_ [][][]byte) (*types.Transaction, error) {
	return _PaymentHelper.Contract.BatchUpdateRemoteChains(&_PaymentHelper.TransactOpts, chainIds_, configTypes_, configs_)
}

// BatchUpdateRemoteChains is a paid mutator transaction binding the contract method 0xea7a8392.
//
// Solidity: function batchUpdateRemoteChains(uint64[] chainIds_, uint256[][] configTypes_, bytes[][] configs_) returns()
func (_PaymentHelper *PaymentHelperTransactorSession) BatchUpdateRemoteChains(chainIds_ []uint64, configTypes_ [][]*big.Int, configs_ [][][]byte) (*types.Transaction, error) {
	return _PaymentHelper.Contract.BatchUpdateRemoteChains(&_PaymentHelper.TransactOpts, chainIds_, configTypes_, configs_)
}

// UpdateRegisterAERC20Params is a paid mutator transaction binding the contract method 0xb9694b52.
//
// Solidity: function updateRegisterAERC20Params(bytes extraDataForTransmuter_) returns()
func (_PaymentHelper *PaymentHelperTransactor) UpdateRegisterAERC20Params(opts *bind.TransactOpts, extraDataForTransmuter_ []byte) (*types.Transaction, error) {
	return _PaymentHelper.contract.Transact(opts, "updateRegisterAERC20Params", extraDataForTransmuter_)
}

// UpdateRegisterAERC20Params is a paid mutator transaction binding the contract method 0xb9694b52.
//
// Solidity: function updateRegisterAERC20Params(bytes extraDataForTransmuter_) returns()
func (_PaymentHelper *PaymentHelperSession) UpdateRegisterAERC20Params(extraDataForTransmuter_ []byte) (*types.Transaction, error) {
	return _PaymentHelper.Contract.UpdateRegisterAERC20Params(&_PaymentHelper.TransactOpts, extraDataForTransmuter_)
}

// UpdateRegisterAERC20Params is a paid mutator transaction binding the contract method 0xb9694b52.
//
// Solidity: function updateRegisterAERC20Params(bytes extraDataForTransmuter_) returns()
func (_PaymentHelper *PaymentHelperTransactorSession) UpdateRegisterAERC20Params(extraDataForTransmuter_ []byte) (*types.Transaction, error) {
	return _PaymentHelper.Contract.UpdateRegisterAERC20Params(&_PaymentHelper.TransactOpts, extraDataForTransmuter_)
}

// UpdateRemoteChain is a paid mutator transaction binding the contract method 0x7abae251.
//
// Solidity: function updateRemoteChain(uint64 chainId_, uint256 configType_, bytes config_) returns()
func (_PaymentHelper *PaymentHelperTransactor) UpdateRemoteChain(opts *bind.TransactOpts, chainId_ uint64, configType_ *big.Int, config_ []byte) (*types.Transaction, error) {
	return _PaymentHelper.contract.Transact(opts, "updateRemoteChain", chainId_, configType_, config_)
}

// UpdateRemoteChain is a paid mutator transaction binding the contract method 0x7abae251.
//
// Solidity: function updateRemoteChain(uint64 chainId_, uint256 configType_, bytes config_) returns()
func (_PaymentHelper *PaymentHelperSession) UpdateRemoteChain(chainId_ uint64, configType_ *big.Int, config_ []byte) (*types.Transaction, error) {
	return _PaymentHelper.Contract.UpdateRemoteChain(&_PaymentHelper.TransactOpts, chainId_, configType_, config_)
}

// UpdateRemoteChain is a paid mutator transaction binding the contract method 0x7abae251.
//
// Solidity: function updateRemoteChain(uint64 chainId_, uint256 configType_, bytes config_) returns()
func (_PaymentHelper *PaymentHelperTransactorSession) UpdateRemoteChain(chainId_ uint64, configType_ *big.Int, config_ []byte) (*types.Transaction, error) {
	return _PaymentHelper.Contract.UpdateRemoteChain(&_PaymentHelper.TransactOpts, chainId_, configType_, config_)
}

// PaymentHelperChainConfigAddedIterator is returned from FilterChainConfigAdded and is used to iterate over the raw logs and unpacked data for ChainConfigAdded events raised by the PaymentHelper contract.
type PaymentHelperChainConfigAddedIterator struct {
	Event *PaymentHelperChainConfigAdded // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *PaymentHelperChainConfigAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PaymentHelperChainConfigAdded)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(PaymentHelperChainConfigAdded)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *PaymentHelperChainConfigAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PaymentHelperChainConfigAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PaymentHelperChainConfigAdded represents a ChainConfigAdded event raised by the PaymentHelper contract.
type PaymentHelperChainConfigAdded struct {
	ChainId uint64
	Config  IPaymentHelperV2PaymentHelperConfig
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterChainConfigAdded is a free log retrieval operation binding the contract event 0xdee9f507a37f922d400f1af8b89ddcf4419171e4570e9bc6b83e49659d6a26eb.
//
// Solidity: event ChainConfigAdded(uint64 chainId_, (address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) config_)
func (_PaymentHelper *PaymentHelperFilterer) FilterChainConfigAdded(opts *bind.FilterOpts) (*PaymentHelperChainConfigAddedIterator, error) {

	logs, sub, err := _PaymentHelper.contract.FilterLogs(opts, "ChainConfigAdded")
	if err != nil {
		return nil, err
	}
	return &PaymentHelperChainConfigAddedIterator{contract: _PaymentHelper.contract, event: "ChainConfigAdded", logs: logs, sub: sub}, nil
}

// WatchChainConfigAdded is a free log subscription operation binding the contract event 0xdee9f507a37f922d400f1af8b89ddcf4419171e4570e9bc6b83e49659d6a26eb.
//
// Solidity: event ChainConfigAdded(uint64 chainId_, (address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) config_)
func (_PaymentHelper *PaymentHelperFilterer) WatchChainConfigAdded(opts *bind.WatchOpts, sink chan<- *PaymentHelperChainConfigAdded) (event.Subscription, error) {

	logs, sub, err := _PaymentHelper.contract.WatchLogs(opts, "ChainConfigAdded")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PaymentHelperChainConfigAdded)
				if err := _PaymentHelper.contract.UnpackLog(event, "ChainConfigAdded", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseChainConfigAdded is a log parse operation binding the contract event 0xdee9f507a37f922d400f1af8b89ddcf4419171e4570e9bc6b83e49659d6a26eb.
//
// Solidity: event ChainConfigAdded(uint64 chainId_, (address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) config_)
func (_PaymentHelper *PaymentHelperFilterer) ParseChainConfigAdded(log types.Log) (*PaymentHelperChainConfigAdded, error) {
	event := new(PaymentHelperChainConfigAdded)
	if err := _PaymentHelper.contract.UnpackLog(event, "ChainConfigAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PaymentHelperChainConfigUpdatedIterator is returned from FilterChainConfigUpdated and is used to iterate over the raw logs and unpacked data for ChainConfigUpdated events raised by the PaymentHelper contract.
type PaymentHelperChainConfigUpdatedIterator struct {
	Event *PaymentHelperChainConfigUpdated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *PaymentHelperChainConfigUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PaymentHelperChainConfigUpdated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(PaymentHelperChainConfigUpdated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *PaymentHelperChainConfigUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PaymentHelperChainConfigUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PaymentHelperChainConfigUpdated represents a ChainConfigUpdated event raised by the PaymentHelper contract.
type PaymentHelperChainConfigUpdated struct {
	ChainId    uint64
	ConfigType *big.Int
	Config     []byte
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterChainConfigUpdated is a free log retrieval operation binding the contract event 0xae3dadf141b0383d3b4db666b2fc32179836af27e11a3e8f07c3ef8da82e5930.
//
// Solidity: event ChainConfigUpdated(uint64 indexed chainId_, uint256 indexed configType_, bytes config_)
func (_PaymentHelper *PaymentHelperFilterer) FilterChainConfigUpdated(opts *bind.FilterOpts, chainId_ []uint64, configType_ []*big.Int) (*PaymentHelperChainConfigUpdatedIterator, error) {

	var chainId_Rule []interface{}
	for _, chainId_Item := range chainId_ {
		chainId_Rule = append(chainId_Rule, chainId_Item)
	}
	var configType_Rule []interface{}
	for _, configType_Item := range configType_ {
		configType_Rule = append(configType_Rule, configType_Item)
	}

	logs, sub, err := _PaymentHelper.contract.FilterLogs(opts, "ChainConfigUpdated", chainId_Rule, configType_Rule)
	if err != nil {
		return nil, err
	}
	return &PaymentHelperChainConfigUpdatedIterator{contract: _PaymentHelper.contract, event: "ChainConfigUpdated", logs: logs, sub: sub}, nil
}

// WatchChainConfigUpdated is a free log subscription operation binding the contract event 0xae3dadf141b0383d3b4db666b2fc32179836af27e11a3e8f07c3ef8da82e5930.
//
// Solidity: event ChainConfigUpdated(uint64 indexed chainId_, uint256 indexed configType_, bytes config_)
func (_PaymentHelper *PaymentHelperFilterer) WatchChainConfigUpdated(opts *bind.WatchOpts, sink chan<- *PaymentHelperChainConfigUpdated, chainId_ []uint64, configType_ []*big.Int) (event.Subscription, error) {

	var chainId_Rule []interface{}
	for _, chainId_Item := range chainId_ {
		chainId_Rule = append(chainId_Rule, chainId_Item)
	}
	var configType_Rule []interface{}
	for _, configType_Item := range configType_ {
		configType_Rule = append(configType_Rule, configType_Item)
	}

	logs, sub, err := _PaymentHelper.contract.WatchLogs(opts, "ChainConfigUpdated", chainId_Rule, configType_Rule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PaymentHelperChainConfigUpdated)
				if err := _PaymentHelper.contract.UnpackLog(event, "ChainConfigUpdated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseChainConfigUpdated is a log parse operation binding the contract event 0xae3dadf141b0383d3b4db666b2fc32179836af27e11a3e8f07c3ef8da82e5930.
//
// Solidity: event ChainConfigUpdated(uint64 indexed chainId_, uint256 indexed configType_, bytes config_)
func (_PaymentHelper *PaymentHelperFilterer) ParseChainConfigUpdated(log types.Log) (*PaymentHelperChainConfigUpdated, error) {
	event := new(PaymentHelperChainConfigUpdated)
	if err := _PaymentHelper.contract.UnpackLog(event, "ChainConfigUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
