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

// IBaseSuperformRouterPlusXChainRebalanceData is an auto generated low-level Go binding around an user-defined struct.
type IBaseSuperformRouterPlusXChainRebalanceData struct {
	RebalanceSelector          [4]byte
	InterimAsset               common.Address
	Slippage                   *big.Int
	ExpectedAmountInterimAsset *big.Int
	RebalanceToAmbIds          []byte
	RebalanceToDstChainIds     []byte
	RebalanceToSfData          []byte
}

// ISuperformRouterPlusAsyncCompleteCrossChainRebalanceArgs is an auto generated low-level Go binding around an user-defined struct.
type ISuperformRouterPlusAsyncCompleteCrossChainRebalanceArgs struct {
	ReceiverAddressSP          common.Address
	RouterPlusPayloadId        *big.Int
	AmountReceivedInterimAsset *big.Int
	NewAmounts                 [][]*big.Int
	NewOutputAmounts           [][]*big.Int
	LiqRequests                [][]LiqRequest
}

// ISuperformRouterPlusAsyncDecodedRouterPlusRebalanceCallData is an auto generated low-level Go binding around an user-defined struct.
type ISuperformRouterPlusAsyncDecodedRouterPlusRebalanceCallData struct {
	InterimAsset      common.Address
	RebalanceSelector [4]byte
	UserSlippage      *big.Int
	ReceiverAddress   []common.Address
	SuperformIds      [][]*big.Int
	Amounts           [][]*big.Int
	OutputAmounts     [][]*big.Int
	AmbIds            [][]uint8
	DstChainIds       []uint64
}

// SuperformRouterPlusAsyncMetaData contains all meta data concerning the SuperformRouterPlusAsync contract.
var SuperformRouterPlusAsyncMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superRegistry_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"CHAIN_ID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"completeCrossChainRebalance\",\"inputs\":[{\"name\":\"args_\",\"type\":\"tuple\",\"internalType\":\"structISuperformRouterPlusAsync.CompleteCrossChainRebalanceArgs\",\"components\":[{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"routerPlusPayloadId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amountReceivedInterimAsset\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"newAmounts\",\"type\":\"uint256[][]\",\"internalType\":\"uint256[][]\"},{\"name\":\"newOutputAmounts\",\"type\":\"uint256[][]\",\"internalType\":\"uint256[][]\"},{\"name\":\"liqRequests\",\"type\":\"tuple[][]\",\"internalType\":\"structLiqRequest[][]\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]}]}],\"outputs\":[{\"name\":\"rebalanceSuccessful\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"decodeXChainRebalanceCallData\",\"inputs\":[{\"name\":\"receiverAddressSP_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"routerPlusPayloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"D\",\"type\":\"tuple\",\"internalType\":\"structISuperformRouterPlusAsync.DecodedRouterPlusRebalanceCallData\",\"components\":[{\"name\":\"interimAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"rebalanceSelector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"},{\"name\":\"userSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiverAddress\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"superformIds\",\"type\":\"uint256[][]\",\"internalType\":\"uint256[][]\"},{\"name\":\"amounts\",\"type\":\"uint256[][]\",\"internalType\":\"uint256[][]\"},{\"name\":\"outputAmounts\",\"type\":\"uint256[][]\",\"internalType\":\"uint256[][]\"},{\"name\":\"ambIds\",\"type\":\"uint8[][]\",\"internalType\":\"uint8[][]\"},{\"name\":\"dstChainIds\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"disputeRefund\",\"inputs\":[{\"name\":\"routerPlusPayloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"finalizeRefund\",\"inputs\":[{\"name\":\"routerPlusPayloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"onERC1155BatchReceived\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"onERC1155Received\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"processedRebalancePayload\",\"inputs\":[{\"name\":\"routerPlusPayloadId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"processed\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"proposeRefund\",\"inputs\":[{\"name\":\"routerPlusPayloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"refundAmount_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"refunds\",\"inputs\":[{\"name\":\"routerPlusPayloadId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"proposedTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setXChainRebalanceCallData\",\"inputs\":[{\"name\":\"receiverAddressSP_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"routerPlusPayloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data_\",\"type\":\"tuple\",\"internalType\":\"structIBaseSuperformRouterPlus.XChainRebalanceData\",\"components\":[{\"name\":\"rebalanceSelector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"},{\"name\":\"interimAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"slippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expectedAmountInterimAsset\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"rebalanceToAmbIds\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToDstChainIds\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToSfData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"superRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperRegistry\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"whitelistedSelectors\",\"inputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumIBaseSuperformRouterPlus.Actions\"},{\"name\":\"selector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"whitelisted\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"xChainRebalanceCallData\",\"inputs\":[{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"routerPlusPayloadId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"rebalanceSelector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"},{\"name\":\"interimAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"slippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expectedAmountInterimAsset\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"rebalanceToAmbIds\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToDstChainIds\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToSfData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"NewRefundAmountProposed\",\"inputs\":[{\"name\":\"routerPlusPayloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"newRefundAmount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RefundCompleted\",\"inputs\":[{\"name\":\"routerPlusPayloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"caller\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RefundDisputed\",\"inputs\":[{\"name\":\"routerPlusPayloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"disputer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RefundInitiated\",\"inputs\":[{\"name\":\"routerPlusPayloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"refundReceiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"refundToken\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"refundAmount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"XChainRebalanceComplete\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"routerPlusPayloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ALREADY_SET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ARRAY_LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AddressEmptyCode\",\"inputs\":[{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"AddressInsufficientBalance\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"BLOCK_CHAIN_ID_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"COMPLETE_REBALANCE_AMOUNT_OUT_OF_SLIPPAGE\",\"inputs\":[{\"name\":\"newAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expectedAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"userSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"COMPLETE_REBALANCE_DIFFERENT_BRIDGE_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"COMPLETE_REBALANCE_DIFFERENT_CHAIN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"COMPLETE_REBALANCE_DIFFERENT_RECEIVER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"COMPLETE_REBALANCE_DIFFERENT_TOKEN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"COMPLETE_REBALANCE_INVALID_TX_DATA_UPDATE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"COMPLETE_REBALANCE_OUTPUTAMOUNT_OUT_OF_SLIPPAGE\",\"inputs\":[{\"name\":\"newOutputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expectedOutputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"userSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"DELAY_NOT_SET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DISPUTE_TIME_ELAPSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedInnerCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_BALANCE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PROPOSER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_REBALANCE_SELECTOR\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_REFUND_DATA\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"IN_DISPUTE_PHASE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_ROUTER_PLUS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_ROUTER_PLUS_PROCESSOR\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_VALID_DISPUTER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REBALANCE_ALREADY_PROCESSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REFUND_ALREADY_PROPOSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]}]",
}

// SuperformRouterPlusAsyncABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperformRouterPlusAsyncMetaData.ABI instead.
var SuperformRouterPlusAsyncABI = SuperformRouterPlusAsyncMetaData.ABI

// SuperformRouterPlusAsync is an auto generated Go binding around an Ethereum contract.
type SuperformRouterPlusAsync struct {
	SuperformRouterPlusAsyncCaller     // Read-only binding to the contract
	SuperformRouterPlusAsyncTransactor // Write-only binding to the contract
	SuperformRouterPlusAsyncFilterer   // Log filterer for contract events
}

// SuperformRouterPlusAsyncCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperformRouterPlusAsyncCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperformRouterPlusAsyncTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperformRouterPlusAsyncTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperformRouterPlusAsyncFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperformRouterPlusAsyncFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperformRouterPlusAsyncSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperformRouterPlusAsyncSession struct {
	Contract     *SuperformRouterPlusAsync // Generic contract binding to set the session for
	CallOpts     bind.CallOpts             // Call options to use throughout this session
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// SuperformRouterPlusAsyncCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperformRouterPlusAsyncCallerSession struct {
	Contract *SuperformRouterPlusAsyncCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts                   // Call options to use throughout this session
}

// SuperformRouterPlusAsyncTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperformRouterPlusAsyncTransactorSession struct {
	Contract     *SuperformRouterPlusAsyncTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts                   // Transaction auth options to use throughout this session
}

// SuperformRouterPlusAsyncRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperformRouterPlusAsyncRaw struct {
	Contract *SuperformRouterPlusAsync // Generic contract binding to access the raw methods on
}

// SuperformRouterPlusAsyncCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperformRouterPlusAsyncCallerRaw struct {
	Contract *SuperformRouterPlusAsyncCaller // Generic read-only contract binding to access the raw methods on
}

// SuperformRouterPlusAsyncTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperformRouterPlusAsyncTransactorRaw struct {
	Contract *SuperformRouterPlusAsyncTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperformRouterPlusAsync creates a new instance of SuperformRouterPlusAsync, bound to a specific deployed contract.
func NewSuperformRouterPlusAsync(address common.Address, backend bind.ContractBackend) (*SuperformRouterPlusAsync, error) {
	contract, err := bindSuperformRouterPlusAsync(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusAsync{SuperformRouterPlusAsyncCaller: SuperformRouterPlusAsyncCaller{contract: contract}, SuperformRouterPlusAsyncTransactor: SuperformRouterPlusAsyncTransactor{contract: contract}, SuperformRouterPlusAsyncFilterer: SuperformRouterPlusAsyncFilterer{contract: contract}}, nil
}

// NewSuperformRouterPlusAsyncCaller creates a new read-only instance of SuperformRouterPlusAsync, bound to a specific deployed contract.
func NewSuperformRouterPlusAsyncCaller(address common.Address, caller bind.ContractCaller) (*SuperformRouterPlusAsyncCaller, error) {
	contract, err := bindSuperformRouterPlusAsync(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusAsyncCaller{contract: contract}, nil
}

// NewSuperformRouterPlusAsyncTransactor creates a new write-only instance of SuperformRouterPlusAsync, bound to a specific deployed contract.
func NewSuperformRouterPlusAsyncTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperformRouterPlusAsyncTransactor, error) {
	contract, err := bindSuperformRouterPlusAsync(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusAsyncTransactor{contract: contract}, nil
}

// NewSuperformRouterPlusAsyncFilterer creates a new log filterer instance of SuperformRouterPlusAsync, bound to a specific deployed contract.
func NewSuperformRouterPlusAsyncFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperformRouterPlusAsyncFilterer, error) {
	contract, err := bindSuperformRouterPlusAsync(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusAsyncFilterer{contract: contract}, nil
}

// bindSuperformRouterPlusAsync binds a generic wrapper to an already deployed contract.
func bindSuperformRouterPlusAsync(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperformRouterPlusAsyncMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperformRouterPlusAsync.Contract.SuperformRouterPlusAsyncCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.SuperformRouterPlusAsyncTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.SuperformRouterPlusAsyncTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperformRouterPlusAsync.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.contract.Transact(opts, method, params...)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCaller) CHAINID(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _SuperformRouterPlusAsync.contract.Call(opts, &out, "CHAIN_ID")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) CHAINID() (uint64, error) {
	return _SuperformRouterPlusAsync.Contract.CHAINID(&_SuperformRouterPlusAsync.CallOpts)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCallerSession) CHAINID() (uint64, error) {
	return _SuperformRouterPlusAsync.Contract.CHAINID(&_SuperformRouterPlusAsync.CallOpts)
}

// DecodeXChainRebalanceCallData is a free data retrieval call binding the contract method 0x720f1036.
//
// Solidity: function decodeXChainRebalanceCallData(address receiverAddressSP_, uint256 routerPlusPayloadId_) view returns((address,bytes4,uint256,address[],uint256[][],uint256[][],uint256[][],uint8[][],uint64[]) D)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCaller) DecodeXChainRebalanceCallData(opts *bind.CallOpts, receiverAddressSP_ common.Address, routerPlusPayloadId_ *big.Int) (ISuperformRouterPlusAsyncDecodedRouterPlusRebalanceCallData, error) {
	var out []interface{}
	err := _SuperformRouterPlusAsync.contract.Call(opts, &out, "decodeXChainRebalanceCallData", receiverAddressSP_, routerPlusPayloadId_)

	if err != nil {
		return *new(ISuperformRouterPlusAsyncDecodedRouterPlusRebalanceCallData), err
	}

	out0 := *abi.ConvertType(out[0], new(ISuperformRouterPlusAsyncDecodedRouterPlusRebalanceCallData)).(*ISuperformRouterPlusAsyncDecodedRouterPlusRebalanceCallData)

	return out0, err

}

// DecodeXChainRebalanceCallData is a free data retrieval call binding the contract method 0x720f1036.
//
// Solidity: function decodeXChainRebalanceCallData(address receiverAddressSP_, uint256 routerPlusPayloadId_) view returns((address,bytes4,uint256,address[],uint256[][],uint256[][],uint256[][],uint8[][],uint64[]) D)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) DecodeXChainRebalanceCallData(receiverAddressSP_ common.Address, routerPlusPayloadId_ *big.Int) (ISuperformRouterPlusAsyncDecodedRouterPlusRebalanceCallData, error) {
	return _SuperformRouterPlusAsync.Contract.DecodeXChainRebalanceCallData(&_SuperformRouterPlusAsync.CallOpts, receiverAddressSP_, routerPlusPayloadId_)
}

// DecodeXChainRebalanceCallData is a free data retrieval call binding the contract method 0x720f1036.
//
// Solidity: function decodeXChainRebalanceCallData(address receiverAddressSP_, uint256 routerPlusPayloadId_) view returns((address,bytes4,uint256,address[],uint256[][],uint256[][],uint256[][],uint8[][],uint64[]) D)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCallerSession) DecodeXChainRebalanceCallData(receiverAddressSP_ common.Address, routerPlusPayloadId_ *big.Int) (ISuperformRouterPlusAsyncDecodedRouterPlusRebalanceCallData, error) {
	return _SuperformRouterPlusAsync.Contract.DecodeXChainRebalanceCallData(&_SuperformRouterPlusAsync.CallOpts, receiverAddressSP_, routerPlusPayloadId_)
}

// OnERC1155BatchReceived is a free data retrieval call binding the contract method 0xbc197c81.
//
// Solidity: function onERC1155BatchReceived(address , address , uint256[] , uint256[] , bytes ) pure returns(bytes4)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCaller) OnERC1155BatchReceived(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address, arg2 []*big.Int, arg3 []*big.Int, arg4 []byte) ([4]byte, error) {
	var out []interface{}
	err := _SuperformRouterPlusAsync.contract.Call(opts, &out, "onERC1155BatchReceived", arg0, arg1, arg2, arg3, arg4)

	if err != nil {
		return *new([4]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([4]byte)).(*[4]byte)

	return out0, err

}

// OnERC1155BatchReceived is a free data retrieval call binding the contract method 0xbc197c81.
//
// Solidity: function onERC1155BatchReceived(address , address , uint256[] , uint256[] , bytes ) pure returns(bytes4)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) OnERC1155BatchReceived(arg0 common.Address, arg1 common.Address, arg2 []*big.Int, arg3 []*big.Int, arg4 []byte) ([4]byte, error) {
	return _SuperformRouterPlusAsync.Contract.OnERC1155BatchReceived(&_SuperformRouterPlusAsync.CallOpts, arg0, arg1, arg2, arg3, arg4)
}

// OnERC1155BatchReceived is a free data retrieval call binding the contract method 0xbc197c81.
//
// Solidity: function onERC1155BatchReceived(address , address , uint256[] , uint256[] , bytes ) pure returns(bytes4)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCallerSession) OnERC1155BatchReceived(arg0 common.Address, arg1 common.Address, arg2 []*big.Int, arg3 []*big.Int, arg4 []byte) ([4]byte, error) {
	return _SuperformRouterPlusAsync.Contract.OnERC1155BatchReceived(&_SuperformRouterPlusAsync.CallOpts, arg0, arg1, arg2, arg3, arg4)
}

// OnERC1155Received is a free data retrieval call binding the contract method 0xf23a6e61.
//
// Solidity: function onERC1155Received(address , address , uint256 , uint256 , bytes ) pure returns(bytes4)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCaller) OnERC1155Received(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address, arg2 *big.Int, arg3 *big.Int, arg4 []byte) ([4]byte, error) {
	var out []interface{}
	err := _SuperformRouterPlusAsync.contract.Call(opts, &out, "onERC1155Received", arg0, arg1, arg2, arg3, arg4)

	if err != nil {
		return *new([4]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([4]byte)).(*[4]byte)

	return out0, err

}

// OnERC1155Received is a free data retrieval call binding the contract method 0xf23a6e61.
//
// Solidity: function onERC1155Received(address , address , uint256 , uint256 , bytes ) pure returns(bytes4)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) OnERC1155Received(arg0 common.Address, arg1 common.Address, arg2 *big.Int, arg3 *big.Int, arg4 []byte) ([4]byte, error) {
	return _SuperformRouterPlusAsync.Contract.OnERC1155Received(&_SuperformRouterPlusAsync.CallOpts, arg0, arg1, arg2, arg3, arg4)
}

// OnERC1155Received is a free data retrieval call binding the contract method 0xf23a6e61.
//
// Solidity: function onERC1155Received(address , address , uint256 , uint256 , bytes ) pure returns(bytes4)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCallerSession) OnERC1155Received(arg0 common.Address, arg1 common.Address, arg2 *big.Int, arg3 *big.Int, arg4 []byte) ([4]byte, error) {
	return _SuperformRouterPlusAsync.Contract.OnERC1155Received(&_SuperformRouterPlusAsync.CallOpts, arg0, arg1, arg2, arg3, arg4)
}

// ProcessedRebalancePayload is a free data retrieval call binding the contract method 0x7411e2e9.
//
// Solidity: function processedRebalancePayload(uint256 routerPlusPayloadId) view returns(bool processed)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCaller) ProcessedRebalancePayload(opts *bind.CallOpts, routerPlusPayloadId *big.Int) (bool, error) {
	var out []interface{}
	err := _SuperformRouterPlusAsync.contract.Call(opts, &out, "processedRebalancePayload", routerPlusPayloadId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ProcessedRebalancePayload is a free data retrieval call binding the contract method 0x7411e2e9.
//
// Solidity: function processedRebalancePayload(uint256 routerPlusPayloadId) view returns(bool processed)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) ProcessedRebalancePayload(routerPlusPayloadId *big.Int) (bool, error) {
	return _SuperformRouterPlusAsync.Contract.ProcessedRebalancePayload(&_SuperformRouterPlusAsync.CallOpts, routerPlusPayloadId)
}

// ProcessedRebalancePayload is a free data retrieval call binding the contract method 0x7411e2e9.
//
// Solidity: function processedRebalancePayload(uint256 routerPlusPayloadId) view returns(bool processed)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCallerSession) ProcessedRebalancePayload(routerPlusPayloadId *big.Int) (bool, error) {
	return _SuperformRouterPlusAsync.Contract.ProcessedRebalancePayload(&_SuperformRouterPlusAsync.CallOpts, routerPlusPayloadId)
}

// Refunds is a free data retrieval call binding the contract method 0xe36bd0f3.
//
// Solidity: function refunds(uint256 routerPlusPayloadId) view returns(address receiver, address interimToken, uint256 amount, uint256 proposedTime)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCaller) Refunds(opts *bind.CallOpts, routerPlusPayloadId *big.Int) (struct {
	Receiver     common.Address
	InterimToken common.Address
	Amount       *big.Int
	ProposedTime *big.Int
}, error) {
	var out []interface{}
	err := _SuperformRouterPlusAsync.contract.Call(opts, &out, "refunds", routerPlusPayloadId)

	outstruct := new(struct {
		Receiver     common.Address
		InterimToken common.Address
		Amount       *big.Int
		ProposedTime *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Receiver = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.InterimToken = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)
	outstruct.Amount = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.ProposedTime = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// Refunds is a free data retrieval call binding the contract method 0xe36bd0f3.
//
// Solidity: function refunds(uint256 routerPlusPayloadId) view returns(address receiver, address interimToken, uint256 amount, uint256 proposedTime)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) Refunds(routerPlusPayloadId *big.Int) (struct {
	Receiver     common.Address
	InterimToken common.Address
	Amount       *big.Int
	ProposedTime *big.Int
}, error) {
	return _SuperformRouterPlusAsync.Contract.Refunds(&_SuperformRouterPlusAsync.CallOpts, routerPlusPayloadId)
}

// Refunds is a free data retrieval call binding the contract method 0xe36bd0f3.
//
// Solidity: function refunds(uint256 routerPlusPayloadId) view returns(address receiver, address interimToken, uint256 amount, uint256 proposedTime)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCallerSession) Refunds(routerPlusPayloadId *big.Int) (struct {
	Receiver     common.Address
	InterimToken common.Address
	Amount       *big.Int
	ProposedTime *big.Int
}, error) {
	return _SuperformRouterPlusAsync.Contract.Refunds(&_SuperformRouterPlusAsync.CallOpts, routerPlusPayloadId)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCaller) SuperRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperformRouterPlusAsync.contract.Call(opts, &out, "superRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) SuperRegistry() (common.Address, error) {
	return _SuperformRouterPlusAsync.Contract.SuperRegistry(&_SuperformRouterPlusAsync.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCallerSession) SuperRegistry() (common.Address, error) {
	return _SuperformRouterPlusAsync.Contract.SuperRegistry(&_SuperformRouterPlusAsync.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) pure returns(bool)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _SuperformRouterPlusAsync.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) pure returns(bool)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperformRouterPlusAsync.Contract.SupportsInterface(&_SuperformRouterPlusAsync.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) pure returns(bool)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperformRouterPlusAsync.Contract.SupportsInterface(&_SuperformRouterPlusAsync.CallOpts, interfaceId)
}

// WhitelistedSelectors is a free data retrieval call binding the contract method 0xb8cae75c.
//
// Solidity: function whitelistedSelectors(uint8 , bytes4 selector) view returns(bool whitelisted)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCaller) WhitelistedSelectors(opts *bind.CallOpts, arg0 uint8, selector [4]byte) (bool, error) {
	var out []interface{}
	err := _SuperformRouterPlusAsync.contract.Call(opts, &out, "whitelistedSelectors", arg0, selector)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// WhitelistedSelectors is a free data retrieval call binding the contract method 0xb8cae75c.
//
// Solidity: function whitelistedSelectors(uint8 , bytes4 selector) view returns(bool whitelisted)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) WhitelistedSelectors(arg0 uint8, selector [4]byte) (bool, error) {
	return _SuperformRouterPlusAsync.Contract.WhitelistedSelectors(&_SuperformRouterPlusAsync.CallOpts, arg0, selector)
}

// WhitelistedSelectors is a free data retrieval call binding the contract method 0xb8cae75c.
//
// Solidity: function whitelistedSelectors(uint8 , bytes4 selector) view returns(bool whitelisted)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCallerSession) WhitelistedSelectors(arg0 uint8, selector [4]byte) (bool, error) {
	return _SuperformRouterPlusAsync.Contract.WhitelistedSelectors(&_SuperformRouterPlusAsync.CallOpts, arg0, selector)
}

// XChainRebalanceCallData is a free data retrieval call binding the contract method 0x3f145088.
//
// Solidity: function xChainRebalanceCallData(address receiverAddressSP, uint256 routerPlusPayloadId) view returns(bytes4 rebalanceSelector, address interimAsset, uint256 slippage, uint256 expectedAmountInterimAsset, bytes rebalanceToAmbIds, bytes rebalanceToDstChainIds, bytes rebalanceToSfData)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCaller) XChainRebalanceCallData(opts *bind.CallOpts, receiverAddressSP common.Address, routerPlusPayloadId *big.Int) (struct {
	RebalanceSelector          [4]byte
	InterimAsset               common.Address
	Slippage                   *big.Int
	ExpectedAmountInterimAsset *big.Int
	RebalanceToAmbIds          []byte
	RebalanceToDstChainIds     []byte
	RebalanceToSfData          []byte
}, error) {
	var out []interface{}
	err := _SuperformRouterPlusAsync.contract.Call(opts, &out, "xChainRebalanceCallData", receiverAddressSP, routerPlusPayloadId)

	outstruct := new(struct {
		RebalanceSelector          [4]byte
		InterimAsset               common.Address
		Slippage                   *big.Int
		ExpectedAmountInterimAsset *big.Int
		RebalanceToAmbIds          []byte
		RebalanceToDstChainIds     []byte
		RebalanceToSfData          []byte
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.RebalanceSelector = *abi.ConvertType(out[0], new([4]byte)).(*[4]byte)
	outstruct.InterimAsset = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)
	outstruct.Slippage = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.ExpectedAmountInterimAsset = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.RebalanceToAmbIds = *abi.ConvertType(out[4], new([]byte)).(*[]byte)
	outstruct.RebalanceToDstChainIds = *abi.ConvertType(out[5], new([]byte)).(*[]byte)
	outstruct.RebalanceToSfData = *abi.ConvertType(out[6], new([]byte)).(*[]byte)

	return *outstruct, err

}

// XChainRebalanceCallData is a free data retrieval call binding the contract method 0x3f145088.
//
// Solidity: function xChainRebalanceCallData(address receiverAddressSP, uint256 routerPlusPayloadId) view returns(bytes4 rebalanceSelector, address interimAsset, uint256 slippage, uint256 expectedAmountInterimAsset, bytes rebalanceToAmbIds, bytes rebalanceToDstChainIds, bytes rebalanceToSfData)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) XChainRebalanceCallData(receiverAddressSP common.Address, routerPlusPayloadId *big.Int) (struct {
	RebalanceSelector          [4]byte
	InterimAsset               common.Address
	Slippage                   *big.Int
	ExpectedAmountInterimAsset *big.Int
	RebalanceToAmbIds          []byte
	RebalanceToDstChainIds     []byte
	RebalanceToSfData          []byte
}, error) {
	return _SuperformRouterPlusAsync.Contract.XChainRebalanceCallData(&_SuperformRouterPlusAsync.CallOpts, receiverAddressSP, routerPlusPayloadId)
}

// XChainRebalanceCallData is a free data retrieval call binding the contract method 0x3f145088.
//
// Solidity: function xChainRebalanceCallData(address receiverAddressSP, uint256 routerPlusPayloadId) view returns(bytes4 rebalanceSelector, address interimAsset, uint256 slippage, uint256 expectedAmountInterimAsset, bytes rebalanceToAmbIds, bytes rebalanceToDstChainIds, bytes rebalanceToSfData)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncCallerSession) XChainRebalanceCallData(receiverAddressSP common.Address, routerPlusPayloadId *big.Int) (struct {
	RebalanceSelector          [4]byte
	InterimAsset               common.Address
	Slippage                   *big.Int
	ExpectedAmountInterimAsset *big.Int
	RebalanceToAmbIds          []byte
	RebalanceToDstChainIds     []byte
	RebalanceToSfData          []byte
}, error) {
	return _SuperformRouterPlusAsync.Contract.XChainRebalanceCallData(&_SuperformRouterPlusAsync.CallOpts, receiverAddressSP, routerPlusPayloadId)
}

// CompleteCrossChainRebalance is a paid mutator transaction binding the contract method 0x17a16f2e.
//
// Solidity: function completeCrossChainRebalance((address,uint256,uint256,uint256[][],uint256[][],(bytes,address,address,uint8,uint64,uint256)[][]) args_) payable returns(bool rebalanceSuccessful)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactor) CompleteCrossChainRebalance(opts *bind.TransactOpts, args_ ISuperformRouterPlusAsyncCompleteCrossChainRebalanceArgs) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.contract.Transact(opts, "completeCrossChainRebalance", args_)
}

// CompleteCrossChainRebalance is a paid mutator transaction binding the contract method 0x17a16f2e.
//
// Solidity: function completeCrossChainRebalance((address,uint256,uint256,uint256[][],uint256[][],(bytes,address,address,uint8,uint64,uint256)[][]) args_) payable returns(bool rebalanceSuccessful)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) CompleteCrossChainRebalance(args_ ISuperformRouterPlusAsyncCompleteCrossChainRebalanceArgs) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.CompleteCrossChainRebalance(&_SuperformRouterPlusAsync.TransactOpts, args_)
}

// CompleteCrossChainRebalance is a paid mutator transaction binding the contract method 0x17a16f2e.
//
// Solidity: function completeCrossChainRebalance((address,uint256,uint256,uint256[][],uint256[][],(bytes,address,address,uint8,uint64,uint256)[][]) args_) payable returns(bool rebalanceSuccessful)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactorSession) CompleteCrossChainRebalance(args_ ISuperformRouterPlusAsyncCompleteCrossChainRebalanceArgs) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.CompleteCrossChainRebalance(&_SuperformRouterPlusAsync.TransactOpts, args_)
}

// DisputeRefund is a paid mutator transaction binding the contract method 0x5ee12a2c.
//
// Solidity: function disputeRefund(uint256 routerPlusPayloadId_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactor) DisputeRefund(opts *bind.TransactOpts, routerPlusPayloadId_ *big.Int) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.contract.Transact(opts, "disputeRefund", routerPlusPayloadId_)
}

// DisputeRefund is a paid mutator transaction binding the contract method 0x5ee12a2c.
//
// Solidity: function disputeRefund(uint256 routerPlusPayloadId_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) DisputeRefund(routerPlusPayloadId_ *big.Int) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.DisputeRefund(&_SuperformRouterPlusAsync.TransactOpts, routerPlusPayloadId_)
}

// DisputeRefund is a paid mutator transaction binding the contract method 0x5ee12a2c.
//
// Solidity: function disputeRefund(uint256 routerPlusPayloadId_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactorSession) DisputeRefund(routerPlusPayloadId_ *big.Int) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.DisputeRefund(&_SuperformRouterPlusAsync.TransactOpts, routerPlusPayloadId_)
}

// FinalizeRefund is a paid mutator transaction binding the contract method 0xe6d6aedc.
//
// Solidity: function finalizeRefund(uint256 routerPlusPayloadId_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactor) FinalizeRefund(opts *bind.TransactOpts, routerPlusPayloadId_ *big.Int) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.contract.Transact(opts, "finalizeRefund", routerPlusPayloadId_)
}

// FinalizeRefund is a paid mutator transaction binding the contract method 0xe6d6aedc.
//
// Solidity: function finalizeRefund(uint256 routerPlusPayloadId_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) FinalizeRefund(routerPlusPayloadId_ *big.Int) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.FinalizeRefund(&_SuperformRouterPlusAsync.TransactOpts, routerPlusPayloadId_)
}

// FinalizeRefund is a paid mutator transaction binding the contract method 0xe6d6aedc.
//
// Solidity: function finalizeRefund(uint256 routerPlusPayloadId_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactorSession) FinalizeRefund(routerPlusPayloadId_ *big.Int) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.FinalizeRefund(&_SuperformRouterPlusAsync.TransactOpts, routerPlusPayloadId_)
}

// ProposeRefund is a paid mutator transaction binding the contract method 0xe6f6338f.
//
// Solidity: function proposeRefund(uint256 routerPlusPayloadId_, uint256 refundAmount_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactor) ProposeRefund(opts *bind.TransactOpts, routerPlusPayloadId_ *big.Int, refundAmount_ *big.Int) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.contract.Transact(opts, "proposeRefund", routerPlusPayloadId_, refundAmount_)
}

// ProposeRefund is a paid mutator transaction binding the contract method 0xe6f6338f.
//
// Solidity: function proposeRefund(uint256 routerPlusPayloadId_, uint256 refundAmount_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) ProposeRefund(routerPlusPayloadId_ *big.Int, refundAmount_ *big.Int) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.ProposeRefund(&_SuperformRouterPlusAsync.TransactOpts, routerPlusPayloadId_, refundAmount_)
}

// ProposeRefund is a paid mutator transaction binding the contract method 0xe6f6338f.
//
// Solidity: function proposeRefund(uint256 routerPlusPayloadId_, uint256 refundAmount_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactorSession) ProposeRefund(routerPlusPayloadId_ *big.Int, refundAmount_ *big.Int) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.ProposeRefund(&_SuperformRouterPlusAsync.TransactOpts, routerPlusPayloadId_, refundAmount_)
}

// SetXChainRebalanceCallData is a paid mutator transaction binding the contract method 0x411227af.
//
// Solidity: function setXChainRebalanceCallData(address receiverAddressSP_, uint256 routerPlusPayloadId_, (bytes4,address,uint256,uint256,bytes,bytes,bytes) data_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactor) SetXChainRebalanceCallData(opts *bind.TransactOpts, receiverAddressSP_ common.Address, routerPlusPayloadId_ *big.Int, data_ IBaseSuperformRouterPlusXChainRebalanceData) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.contract.Transact(opts, "setXChainRebalanceCallData", receiverAddressSP_, routerPlusPayloadId_, data_)
}

// SetXChainRebalanceCallData is a paid mutator transaction binding the contract method 0x411227af.
//
// Solidity: function setXChainRebalanceCallData(address receiverAddressSP_, uint256 routerPlusPayloadId_, (bytes4,address,uint256,uint256,bytes,bytes,bytes) data_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncSession) SetXChainRebalanceCallData(receiverAddressSP_ common.Address, routerPlusPayloadId_ *big.Int, data_ IBaseSuperformRouterPlusXChainRebalanceData) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.SetXChainRebalanceCallData(&_SuperformRouterPlusAsync.TransactOpts, receiverAddressSP_, routerPlusPayloadId_, data_)
}

// SetXChainRebalanceCallData is a paid mutator transaction binding the contract method 0x411227af.
//
// Solidity: function setXChainRebalanceCallData(address receiverAddressSP_, uint256 routerPlusPayloadId_, (bytes4,address,uint256,uint256,bytes,bytes,bytes) data_) returns()
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncTransactorSession) SetXChainRebalanceCallData(receiverAddressSP_ common.Address, routerPlusPayloadId_ *big.Int, data_ IBaseSuperformRouterPlusXChainRebalanceData) (*types.Transaction, error) {
	return _SuperformRouterPlusAsync.Contract.SetXChainRebalanceCallData(&_SuperformRouterPlusAsync.TransactOpts, receiverAddressSP_, routerPlusPayloadId_, data_)
}

// SuperformRouterPlusAsyncNewRefundAmountProposedIterator is returned from FilterNewRefundAmountProposed and is used to iterate over the raw logs and unpacked data for NewRefundAmountProposed events raised by the SuperformRouterPlusAsync contract.
type SuperformRouterPlusAsyncNewRefundAmountProposedIterator struct {
	Event *SuperformRouterPlusAsyncNewRefundAmountProposed // Event containing the contract specifics and raw log

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
func (it *SuperformRouterPlusAsyncNewRefundAmountProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperformRouterPlusAsyncNewRefundAmountProposed)
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
		it.Event = new(SuperformRouterPlusAsyncNewRefundAmountProposed)
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
func (it *SuperformRouterPlusAsyncNewRefundAmountProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperformRouterPlusAsyncNewRefundAmountProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperformRouterPlusAsyncNewRefundAmountProposed represents a NewRefundAmountProposed event raised by the SuperformRouterPlusAsync contract.
type SuperformRouterPlusAsyncNewRefundAmountProposed struct {
	RouterPlusPayloadId *big.Int
	NewRefundAmount     *big.Int
	Raw                 types.Log // Blockchain specific contextual infos
}

// FilterNewRefundAmountProposed is a free log retrieval operation binding the contract event 0x1b0d110cd1dfdbef4c568765637c00b7dcc64d1d4e832884760a377df7de8acc.
//
// Solidity: event NewRefundAmountProposed(uint256 indexed routerPlusPayloadId, uint256 indexed newRefundAmount)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) FilterNewRefundAmountProposed(opts *bind.FilterOpts, routerPlusPayloadId []*big.Int, newRefundAmount []*big.Int) (*SuperformRouterPlusAsyncNewRefundAmountProposedIterator, error) {

	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}
	var newRefundAmountRule []interface{}
	for _, newRefundAmountItem := range newRefundAmount {
		newRefundAmountRule = append(newRefundAmountRule, newRefundAmountItem)
	}

	logs, sub, err := _SuperformRouterPlusAsync.contract.FilterLogs(opts, "NewRefundAmountProposed", routerPlusPayloadIdRule, newRefundAmountRule)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusAsyncNewRefundAmountProposedIterator{contract: _SuperformRouterPlusAsync.contract, event: "NewRefundAmountProposed", logs: logs, sub: sub}, nil
}

// WatchNewRefundAmountProposed is a free log subscription operation binding the contract event 0x1b0d110cd1dfdbef4c568765637c00b7dcc64d1d4e832884760a377df7de8acc.
//
// Solidity: event NewRefundAmountProposed(uint256 indexed routerPlusPayloadId, uint256 indexed newRefundAmount)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) WatchNewRefundAmountProposed(opts *bind.WatchOpts, sink chan<- *SuperformRouterPlusAsyncNewRefundAmountProposed, routerPlusPayloadId []*big.Int, newRefundAmount []*big.Int) (event.Subscription, error) {

	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}
	var newRefundAmountRule []interface{}
	for _, newRefundAmountItem := range newRefundAmount {
		newRefundAmountRule = append(newRefundAmountRule, newRefundAmountItem)
	}

	logs, sub, err := _SuperformRouterPlusAsync.contract.WatchLogs(opts, "NewRefundAmountProposed", routerPlusPayloadIdRule, newRefundAmountRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperformRouterPlusAsyncNewRefundAmountProposed)
				if err := _SuperformRouterPlusAsync.contract.UnpackLog(event, "NewRefundAmountProposed", log); err != nil {
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

// ParseNewRefundAmountProposed is a log parse operation binding the contract event 0x1b0d110cd1dfdbef4c568765637c00b7dcc64d1d4e832884760a377df7de8acc.
//
// Solidity: event NewRefundAmountProposed(uint256 indexed routerPlusPayloadId, uint256 indexed newRefundAmount)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) ParseNewRefundAmountProposed(log types.Log) (*SuperformRouterPlusAsyncNewRefundAmountProposed, error) {
	event := new(SuperformRouterPlusAsyncNewRefundAmountProposed)
	if err := _SuperformRouterPlusAsync.contract.UnpackLog(event, "NewRefundAmountProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperformRouterPlusAsyncRefundCompletedIterator is returned from FilterRefundCompleted and is used to iterate over the raw logs and unpacked data for RefundCompleted events raised by the SuperformRouterPlusAsync contract.
type SuperformRouterPlusAsyncRefundCompletedIterator struct {
	Event *SuperformRouterPlusAsyncRefundCompleted // Event containing the contract specifics and raw log

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
func (it *SuperformRouterPlusAsyncRefundCompletedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperformRouterPlusAsyncRefundCompleted)
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
		it.Event = new(SuperformRouterPlusAsyncRefundCompleted)
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
func (it *SuperformRouterPlusAsyncRefundCompletedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperformRouterPlusAsyncRefundCompletedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperformRouterPlusAsyncRefundCompleted represents a RefundCompleted event raised by the SuperformRouterPlusAsync contract.
type SuperformRouterPlusAsyncRefundCompleted struct {
	RouterPlusPayloadId *big.Int
	Caller              common.Address
	Raw                 types.Log // Blockchain specific contextual infos
}

// FilterRefundCompleted is a free log retrieval operation binding the contract event 0xe9198400deaee1ba4b33ab2fd77ed88bc266b5ae5fcc29961d66b05a9cd0cf8d.
//
// Solidity: event RefundCompleted(uint256 indexed routerPlusPayloadId, address indexed caller)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) FilterRefundCompleted(opts *bind.FilterOpts, routerPlusPayloadId []*big.Int, caller []common.Address) (*SuperformRouterPlusAsyncRefundCompletedIterator, error) {

	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperformRouterPlusAsync.contract.FilterLogs(opts, "RefundCompleted", routerPlusPayloadIdRule, callerRule)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusAsyncRefundCompletedIterator{contract: _SuperformRouterPlusAsync.contract, event: "RefundCompleted", logs: logs, sub: sub}, nil
}

// WatchRefundCompleted is a free log subscription operation binding the contract event 0xe9198400deaee1ba4b33ab2fd77ed88bc266b5ae5fcc29961d66b05a9cd0cf8d.
//
// Solidity: event RefundCompleted(uint256 indexed routerPlusPayloadId, address indexed caller)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) WatchRefundCompleted(opts *bind.WatchOpts, sink chan<- *SuperformRouterPlusAsyncRefundCompleted, routerPlusPayloadId []*big.Int, caller []common.Address) (event.Subscription, error) {

	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}
	var callerRule []interface{}
	for _, callerItem := range caller {
		callerRule = append(callerRule, callerItem)
	}

	logs, sub, err := _SuperformRouterPlusAsync.contract.WatchLogs(opts, "RefundCompleted", routerPlusPayloadIdRule, callerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperformRouterPlusAsyncRefundCompleted)
				if err := _SuperformRouterPlusAsync.contract.UnpackLog(event, "RefundCompleted", log); err != nil {
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

// ParseRefundCompleted is a log parse operation binding the contract event 0xe9198400deaee1ba4b33ab2fd77ed88bc266b5ae5fcc29961d66b05a9cd0cf8d.
//
// Solidity: event RefundCompleted(uint256 indexed routerPlusPayloadId, address indexed caller)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) ParseRefundCompleted(log types.Log) (*SuperformRouterPlusAsyncRefundCompleted, error) {
	event := new(SuperformRouterPlusAsyncRefundCompleted)
	if err := _SuperformRouterPlusAsync.contract.UnpackLog(event, "RefundCompleted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperformRouterPlusAsyncRefundDisputedIterator is returned from FilterRefundDisputed and is used to iterate over the raw logs and unpacked data for RefundDisputed events raised by the SuperformRouterPlusAsync contract.
type SuperformRouterPlusAsyncRefundDisputedIterator struct {
	Event *SuperformRouterPlusAsyncRefundDisputed // Event containing the contract specifics and raw log

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
func (it *SuperformRouterPlusAsyncRefundDisputedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperformRouterPlusAsyncRefundDisputed)
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
		it.Event = new(SuperformRouterPlusAsyncRefundDisputed)
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
func (it *SuperformRouterPlusAsyncRefundDisputedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperformRouterPlusAsyncRefundDisputedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperformRouterPlusAsyncRefundDisputed represents a RefundDisputed event raised by the SuperformRouterPlusAsync contract.
type SuperformRouterPlusAsyncRefundDisputed struct {
	RouterPlusPayloadId *big.Int
	Disputer            common.Address
	Raw                 types.Log // Blockchain specific contextual infos
}

// FilterRefundDisputed is a free log retrieval operation binding the contract event 0xc1043c062ae8e81aee14354200ff7e2e0917565b431904d7818d8dc56069ecd2.
//
// Solidity: event RefundDisputed(uint256 indexed routerPlusPayloadId, address indexed disputer)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) FilterRefundDisputed(opts *bind.FilterOpts, routerPlusPayloadId []*big.Int, disputer []common.Address) (*SuperformRouterPlusAsyncRefundDisputedIterator, error) {

	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}
	var disputerRule []interface{}
	for _, disputerItem := range disputer {
		disputerRule = append(disputerRule, disputerItem)
	}

	logs, sub, err := _SuperformRouterPlusAsync.contract.FilterLogs(opts, "RefundDisputed", routerPlusPayloadIdRule, disputerRule)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusAsyncRefundDisputedIterator{contract: _SuperformRouterPlusAsync.contract, event: "RefundDisputed", logs: logs, sub: sub}, nil
}

// WatchRefundDisputed is a free log subscription operation binding the contract event 0xc1043c062ae8e81aee14354200ff7e2e0917565b431904d7818d8dc56069ecd2.
//
// Solidity: event RefundDisputed(uint256 indexed routerPlusPayloadId, address indexed disputer)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) WatchRefundDisputed(opts *bind.WatchOpts, sink chan<- *SuperformRouterPlusAsyncRefundDisputed, routerPlusPayloadId []*big.Int, disputer []common.Address) (event.Subscription, error) {

	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}
	var disputerRule []interface{}
	for _, disputerItem := range disputer {
		disputerRule = append(disputerRule, disputerItem)
	}

	logs, sub, err := _SuperformRouterPlusAsync.contract.WatchLogs(opts, "RefundDisputed", routerPlusPayloadIdRule, disputerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperformRouterPlusAsyncRefundDisputed)
				if err := _SuperformRouterPlusAsync.contract.UnpackLog(event, "RefundDisputed", log); err != nil {
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

// ParseRefundDisputed is a log parse operation binding the contract event 0xc1043c062ae8e81aee14354200ff7e2e0917565b431904d7818d8dc56069ecd2.
//
// Solidity: event RefundDisputed(uint256 indexed routerPlusPayloadId, address indexed disputer)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) ParseRefundDisputed(log types.Log) (*SuperformRouterPlusAsyncRefundDisputed, error) {
	event := new(SuperformRouterPlusAsyncRefundDisputed)
	if err := _SuperformRouterPlusAsync.contract.UnpackLog(event, "RefundDisputed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperformRouterPlusAsyncRefundInitiatedIterator is returned from FilterRefundInitiated and is used to iterate over the raw logs and unpacked data for RefundInitiated events raised by the SuperformRouterPlusAsync contract.
type SuperformRouterPlusAsyncRefundInitiatedIterator struct {
	Event *SuperformRouterPlusAsyncRefundInitiated // Event containing the contract specifics and raw log

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
func (it *SuperformRouterPlusAsyncRefundInitiatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperformRouterPlusAsyncRefundInitiated)
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
		it.Event = new(SuperformRouterPlusAsyncRefundInitiated)
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
func (it *SuperformRouterPlusAsyncRefundInitiatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperformRouterPlusAsyncRefundInitiatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperformRouterPlusAsyncRefundInitiated represents a RefundInitiated event raised by the SuperformRouterPlusAsync contract.
type SuperformRouterPlusAsyncRefundInitiated struct {
	RouterPlusPayloadId *big.Int
	RefundReceiver      common.Address
	RefundToken         common.Address
	RefundAmount        *big.Int
	Raw                 types.Log // Blockchain specific contextual infos
}

// FilterRefundInitiated is a free log retrieval operation binding the contract event 0x3281bb9cf5a8ea9469d633ed8f37559e16750378afc44ac1c970cfd45ea7d477.
//
// Solidity: event RefundInitiated(uint256 indexed routerPlusPayloadId, address indexed refundReceiver, address refundToken, uint256 refundAmount)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) FilterRefundInitiated(opts *bind.FilterOpts, routerPlusPayloadId []*big.Int, refundReceiver []common.Address) (*SuperformRouterPlusAsyncRefundInitiatedIterator, error) {

	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}
	var refundReceiverRule []interface{}
	for _, refundReceiverItem := range refundReceiver {
		refundReceiverRule = append(refundReceiverRule, refundReceiverItem)
	}

	logs, sub, err := _SuperformRouterPlusAsync.contract.FilterLogs(opts, "RefundInitiated", routerPlusPayloadIdRule, refundReceiverRule)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusAsyncRefundInitiatedIterator{contract: _SuperformRouterPlusAsync.contract, event: "RefundInitiated", logs: logs, sub: sub}, nil
}

// WatchRefundInitiated is a free log subscription operation binding the contract event 0x3281bb9cf5a8ea9469d633ed8f37559e16750378afc44ac1c970cfd45ea7d477.
//
// Solidity: event RefundInitiated(uint256 indexed routerPlusPayloadId, address indexed refundReceiver, address refundToken, uint256 refundAmount)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) WatchRefundInitiated(opts *bind.WatchOpts, sink chan<- *SuperformRouterPlusAsyncRefundInitiated, routerPlusPayloadId []*big.Int, refundReceiver []common.Address) (event.Subscription, error) {

	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}
	var refundReceiverRule []interface{}
	for _, refundReceiverItem := range refundReceiver {
		refundReceiverRule = append(refundReceiverRule, refundReceiverItem)
	}

	logs, sub, err := _SuperformRouterPlusAsync.contract.WatchLogs(opts, "RefundInitiated", routerPlusPayloadIdRule, refundReceiverRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperformRouterPlusAsyncRefundInitiated)
				if err := _SuperformRouterPlusAsync.contract.UnpackLog(event, "RefundInitiated", log); err != nil {
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

// ParseRefundInitiated is a log parse operation binding the contract event 0x3281bb9cf5a8ea9469d633ed8f37559e16750378afc44ac1c970cfd45ea7d477.
//
// Solidity: event RefundInitiated(uint256 indexed routerPlusPayloadId, address indexed refundReceiver, address refundToken, uint256 refundAmount)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) ParseRefundInitiated(log types.Log) (*SuperformRouterPlusAsyncRefundInitiated, error) {
	event := new(SuperformRouterPlusAsyncRefundInitiated)
	if err := _SuperformRouterPlusAsync.contract.UnpackLog(event, "RefundInitiated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperformRouterPlusAsyncXChainRebalanceCompleteIterator is returned from FilterXChainRebalanceComplete and is used to iterate over the raw logs and unpacked data for XChainRebalanceComplete events raised by the SuperformRouterPlusAsync contract.
type SuperformRouterPlusAsyncXChainRebalanceCompleteIterator struct {
	Event *SuperformRouterPlusAsyncXChainRebalanceComplete // Event containing the contract specifics and raw log

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
func (it *SuperformRouterPlusAsyncXChainRebalanceCompleteIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperformRouterPlusAsyncXChainRebalanceComplete)
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
		it.Event = new(SuperformRouterPlusAsyncXChainRebalanceComplete)
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
func (it *SuperformRouterPlusAsyncXChainRebalanceCompleteIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperformRouterPlusAsyncXChainRebalanceCompleteIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperformRouterPlusAsyncXChainRebalanceComplete represents a XChainRebalanceComplete event raised by the SuperformRouterPlusAsync contract.
type SuperformRouterPlusAsyncXChainRebalanceComplete struct {
	Receiver            common.Address
	RouterPlusPayloadId *big.Int
	Raw                 types.Log // Blockchain specific contextual infos
}

// FilterXChainRebalanceComplete is a free log retrieval operation binding the contract event 0x4342715b2b00f506b666ed74e310cc14a6011e508086c24083b0482c0f893a3e.
//
// Solidity: event XChainRebalanceComplete(address indexed receiver, uint256 indexed routerPlusPayloadId)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) FilterXChainRebalanceComplete(opts *bind.FilterOpts, receiver []common.Address, routerPlusPayloadId []*big.Int) (*SuperformRouterPlusAsyncXChainRebalanceCompleteIterator, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}

	logs, sub, err := _SuperformRouterPlusAsync.contract.FilterLogs(opts, "XChainRebalanceComplete", receiverRule, routerPlusPayloadIdRule)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusAsyncXChainRebalanceCompleteIterator{contract: _SuperformRouterPlusAsync.contract, event: "XChainRebalanceComplete", logs: logs, sub: sub}, nil
}

// WatchXChainRebalanceComplete is a free log subscription operation binding the contract event 0x4342715b2b00f506b666ed74e310cc14a6011e508086c24083b0482c0f893a3e.
//
// Solidity: event XChainRebalanceComplete(address indexed receiver, uint256 indexed routerPlusPayloadId)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) WatchXChainRebalanceComplete(opts *bind.WatchOpts, sink chan<- *SuperformRouterPlusAsyncXChainRebalanceComplete, receiver []common.Address, routerPlusPayloadId []*big.Int) (event.Subscription, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}

	logs, sub, err := _SuperformRouterPlusAsync.contract.WatchLogs(opts, "XChainRebalanceComplete", receiverRule, routerPlusPayloadIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperformRouterPlusAsyncXChainRebalanceComplete)
				if err := _SuperformRouterPlusAsync.contract.UnpackLog(event, "XChainRebalanceComplete", log); err != nil {
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

// ParseXChainRebalanceComplete is a log parse operation binding the contract event 0x4342715b2b00f506b666ed74e310cc14a6011e508086c24083b0482c0f893a3e.
//
// Solidity: event XChainRebalanceComplete(address indexed receiver, uint256 indexed routerPlusPayloadId)
func (_SuperformRouterPlusAsync *SuperformRouterPlusAsyncFilterer) ParseXChainRebalanceComplete(log types.Log) (*SuperformRouterPlusAsyncXChainRebalanceComplete, error) {
	event := new(SuperformRouterPlusAsyncXChainRebalanceComplete)
	if err := _SuperformRouterPlusAsync.contract.UnpackLog(event, "XChainRebalanceComplete", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
