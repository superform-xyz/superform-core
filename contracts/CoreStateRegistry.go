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

// CoreStateRegistryMetaData contains all meta data concerning the CoreStateRegistry contract.
var CoreStateRegistryMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superRegistry_\",\"type\":\"address\",\"internalType\":\"contractISuperRegistry\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"CHAIN_ID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"dispatchPayload\",\"inputs\":[{\"name\":\"srcSender_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ambIds_\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"},{\"name\":\"dstChainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"message_\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"extraData_\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"disputeRescueFailedDeposits\",\"inputs\":[{\"name\":\"payloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"finalizeRescueFailedDeposits\",\"inputs\":[{\"name\":\"payloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getFailedDeposits\",\"inputs\":[{\"name\":\"payloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"lastProposedTime\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getMessageAMB\",\"inputs\":[{\"name\":\"payloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"messageQuorum\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"payloadBody\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"payloadHeader\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"payloadTracking\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumPayloadState\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"payloadsCount\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"processPayload\",\"inputs\":[{\"name\":\"payloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"proposeRescueFailedDeposits\",\"inputs\":[{\"name\":\"payloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"proposedAmounts_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"receivePayload\",\"inputs\":[{\"name\":\"srcChainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"message_\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"superRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperRegistry\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"updateDepositPayload\",\"inputs\":[{\"name\":\"payloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"finalTokens_\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"finalAmounts_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updateWithdrawPayload\",\"inputs\":[{\"name\":\"payloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"txData_\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"validateSlippage\",\"inputs\":[{\"name\":\"finalAmount_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"FailedXChainDeposits\",\"inputs\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PayloadProcessed\",\"inputs\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PayloadReceived\",\"inputs\":[{\"name\":\"srcChainId\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"PayloadUpdated\",\"inputs\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ProofReceived\",\"inputs\":[{\"name\":\"proof\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RescueDisputed\",\"inputs\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RescueFinalized\",\"inputs\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RescueProposed\",\"inputs\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"proposedAmount\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"proposedTime\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperRegistryUpdated\",\"inputs\":[{\"name\":\"superRegistry\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AddressEmptyCode\",\"inputs\":[{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"AddressInsufficientBalance\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"BLOCK_CHAIN_ID_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BRIDGE_TOKENS_PENDING\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CANNOT_UPDATE_WITHDRAW_TX_DATA\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DELAY_NOT_SET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DIFFERENT_PAYLOAD_UPDATE_TX_DATA_LENGTH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DISPUTE_TIME_ELAPSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedInnerCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_QUORUM\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_CHAIN_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_DST_SWAP_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_INTERNAL_CALL\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PAYLOAD_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PAYLOAD_TYPE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PAYLOAD_UPDATE_REQUEST\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PROOF_BRIDGE_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PROOF_BRIDGE_IDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_RESCUE_DATA\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_UPDATE_FINAL_TOKEN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NEGATIVE_SLIPPAGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_AMB_IMPLEMENTATION\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_PRIVILEGED_CALLER\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"NOT_SUPERFORM_ROUTER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_VALID_DISPUTER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PAYLOAD_ALREADY_PROCESSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PAYLOAD_ALREADY_UPDATED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PAYLOAD_NOT_UPDATED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"RESCUE_ALREADY_PROPOSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"RESCUE_LOCKED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SLIPPAGE_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SUPERFORM_ID_NONEXISTENT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedDecreaseAllowance\",\"inputs\":[{\"name\":\"spender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"currentAllowance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"requestedDecrease\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ZERO_AMB_ID_LENGTH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_FINAL_TOKEN\",\"inputs\":[]}]",
}

// CoreStateRegistryABI is the input ABI used to generate the binding from.
// Deprecated: Use CoreStateRegistryMetaData.ABI instead.
var CoreStateRegistryABI = CoreStateRegistryMetaData.ABI

// CoreStateRegistry is an auto generated Go binding around an Ethereum contract.
type CoreStateRegistry struct {
	CoreStateRegistryCaller     // Read-only binding to the contract
	CoreStateRegistryTransactor // Write-only binding to the contract
	CoreStateRegistryFilterer   // Log filterer for contract events
}

// CoreStateRegistryCaller is an auto generated read-only Go binding around an Ethereum contract.
type CoreStateRegistryCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// CoreStateRegistryTransactor is an auto generated write-only Go binding around an Ethereum contract.
type CoreStateRegistryTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// CoreStateRegistryFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type CoreStateRegistryFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// CoreStateRegistrySession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type CoreStateRegistrySession struct {
	Contract     *CoreStateRegistry // Generic contract binding to set the session for
	CallOpts     bind.CallOpts      // Call options to use throughout this session
	TransactOpts bind.TransactOpts  // Transaction auth options to use throughout this session
}

// CoreStateRegistryCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type CoreStateRegistryCallerSession struct {
	Contract *CoreStateRegistryCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts            // Call options to use throughout this session
}

// CoreStateRegistryTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type CoreStateRegistryTransactorSession struct {
	Contract     *CoreStateRegistryTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts            // Transaction auth options to use throughout this session
}

// CoreStateRegistryRaw is an auto generated low-level Go binding around an Ethereum contract.
type CoreStateRegistryRaw struct {
	Contract *CoreStateRegistry // Generic contract binding to access the raw methods on
}

// CoreStateRegistryCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type CoreStateRegistryCallerRaw struct {
	Contract *CoreStateRegistryCaller // Generic read-only contract binding to access the raw methods on
}

// CoreStateRegistryTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type CoreStateRegistryTransactorRaw struct {
	Contract *CoreStateRegistryTransactor // Generic write-only contract binding to access the raw methods on
}

// NewCoreStateRegistry creates a new instance of CoreStateRegistry, bound to a specific deployed contract.
func NewCoreStateRegistry(address common.Address, backend bind.ContractBackend) (*CoreStateRegistry, error) {
	contract, err := bindCoreStateRegistry(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistry{CoreStateRegistryCaller: CoreStateRegistryCaller{contract: contract}, CoreStateRegistryTransactor: CoreStateRegistryTransactor{contract: contract}, CoreStateRegistryFilterer: CoreStateRegistryFilterer{contract: contract}}, nil
}

// NewCoreStateRegistryCaller creates a new read-only instance of CoreStateRegistry, bound to a specific deployed contract.
func NewCoreStateRegistryCaller(address common.Address, caller bind.ContractCaller) (*CoreStateRegistryCaller, error) {
	contract, err := bindCoreStateRegistry(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistryCaller{contract: contract}, nil
}

// NewCoreStateRegistryTransactor creates a new write-only instance of CoreStateRegistry, bound to a specific deployed contract.
func NewCoreStateRegistryTransactor(address common.Address, transactor bind.ContractTransactor) (*CoreStateRegistryTransactor, error) {
	contract, err := bindCoreStateRegistry(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistryTransactor{contract: contract}, nil
}

// NewCoreStateRegistryFilterer creates a new log filterer instance of CoreStateRegistry, bound to a specific deployed contract.
func NewCoreStateRegistryFilterer(address common.Address, filterer bind.ContractFilterer) (*CoreStateRegistryFilterer, error) {
	contract, err := bindCoreStateRegistry(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistryFilterer{contract: contract}, nil
}

// bindCoreStateRegistry binds a generic wrapper to an already deployed contract.
func bindCoreStateRegistry(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := CoreStateRegistryMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_CoreStateRegistry *CoreStateRegistryRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _CoreStateRegistry.Contract.CoreStateRegistryCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_CoreStateRegistry *CoreStateRegistryRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.CoreStateRegistryTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_CoreStateRegistry *CoreStateRegistryRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.CoreStateRegistryTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_CoreStateRegistry *CoreStateRegistryCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _CoreStateRegistry.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_CoreStateRegistry *CoreStateRegistryTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_CoreStateRegistry *CoreStateRegistryTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.contract.Transact(opts, method, params...)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_CoreStateRegistry *CoreStateRegistryCaller) CHAINID(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _CoreStateRegistry.contract.Call(opts, &out, "CHAIN_ID")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_CoreStateRegistry *CoreStateRegistrySession) CHAINID() (uint64, error) {
	return _CoreStateRegistry.Contract.CHAINID(&_CoreStateRegistry.CallOpts)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_CoreStateRegistry *CoreStateRegistryCallerSession) CHAINID() (uint64, error) {
	return _CoreStateRegistry.Contract.CHAINID(&_CoreStateRegistry.CallOpts)
}

// GetFailedDeposits is a free data retrieval call binding the contract method 0xd468711a.
//
// Solidity: function getFailedDeposits(uint256 payloadId_) view returns(uint256[] superformIds, uint256[] amounts, uint256 lastProposedTime)
func (_CoreStateRegistry *CoreStateRegistryCaller) GetFailedDeposits(opts *bind.CallOpts, payloadId_ *big.Int) (struct {
	SuperformIds     []*big.Int
	Amounts          []*big.Int
	LastProposedTime *big.Int
}, error) {
	var out []interface{}
	err := _CoreStateRegistry.contract.Call(opts, &out, "getFailedDeposits", payloadId_)

	outstruct := new(struct {
		SuperformIds     []*big.Int
		Amounts          []*big.Int
		LastProposedTime *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.SuperformIds = *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)
	outstruct.Amounts = *abi.ConvertType(out[1], new([]*big.Int)).(*[]*big.Int)
	outstruct.LastProposedTime = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetFailedDeposits is a free data retrieval call binding the contract method 0xd468711a.
//
// Solidity: function getFailedDeposits(uint256 payloadId_) view returns(uint256[] superformIds, uint256[] amounts, uint256 lastProposedTime)
func (_CoreStateRegistry *CoreStateRegistrySession) GetFailedDeposits(payloadId_ *big.Int) (struct {
	SuperformIds     []*big.Int
	Amounts          []*big.Int
	LastProposedTime *big.Int
}, error) {
	return _CoreStateRegistry.Contract.GetFailedDeposits(&_CoreStateRegistry.CallOpts, payloadId_)
}

// GetFailedDeposits is a free data retrieval call binding the contract method 0xd468711a.
//
// Solidity: function getFailedDeposits(uint256 payloadId_) view returns(uint256[] superformIds, uint256[] amounts, uint256 lastProposedTime)
func (_CoreStateRegistry *CoreStateRegistryCallerSession) GetFailedDeposits(payloadId_ *big.Int) (struct {
	SuperformIds     []*big.Int
	Amounts          []*big.Int
	LastProposedTime *big.Int
}, error) {
	return _CoreStateRegistry.Contract.GetFailedDeposits(&_CoreStateRegistry.CallOpts, payloadId_)
}

// GetMessageAMB is a free data retrieval call binding the contract method 0xd830364e.
//
// Solidity: function getMessageAMB(uint256 payloadId_) view returns(uint8[])
func (_CoreStateRegistry *CoreStateRegistryCaller) GetMessageAMB(opts *bind.CallOpts, payloadId_ *big.Int) ([]uint8, error) {
	var out []interface{}
	err := _CoreStateRegistry.contract.Call(opts, &out, "getMessageAMB", payloadId_)

	if err != nil {
		return *new([]uint8), err
	}

	out0 := *abi.ConvertType(out[0], new([]uint8)).(*[]uint8)

	return out0, err

}

// GetMessageAMB is a free data retrieval call binding the contract method 0xd830364e.
//
// Solidity: function getMessageAMB(uint256 payloadId_) view returns(uint8[])
func (_CoreStateRegistry *CoreStateRegistrySession) GetMessageAMB(payloadId_ *big.Int) ([]uint8, error) {
	return _CoreStateRegistry.Contract.GetMessageAMB(&_CoreStateRegistry.CallOpts, payloadId_)
}

// GetMessageAMB is a free data retrieval call binding the contract method 0xd830364e.
//
// Solidity: function getMessageAMB(uint256 payloadId_) view returns(uint8[])
func (_CoreStateRegistry *CoreStateRegistryCallerSession) GetMessageAMB(payloadId_ *big.Int) ([]uint8, error) {
	return _CoreStateRegistry.Contract.GetMessageAMB(&_CoreStateRegistry.CallOpts, payloadId_)
}

// MessageQuorum is a free data retrieval call binding the contract method 0xd4961606.
//
// Solidity: function messageQuorum(bytes32 ) view returns(uint256)
func (_CoreStateRegistry *CoreStateRegistryCaller) MessageQuorum(opts *bind.CallOpts, arg0 [32]byte) (*big.Int, error) {
	var out []interface{}
	err := _CoreStateRegistry.contract.Call(opts, &out, "messageQuorum", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MessageQuorum is a free data retrieval call binding the contract method 0xd4961606.
//
// Solidity: function messageQuorum(bytes32 ) view returns(uint256)
func (_CoreStateRegistry *CoreStateRegistrySession) MessageQuorum(arg0 [32]byte) (*big.Int, error) {
	return _CoreStateRegistry.Contract.MessageQuorum(&_CoreStateRegistry.CallOpts, arg0)
}

// MessageQuorum is a free data retrieval call binding the contract method 0xd4961606.
//
// Solidity: function messageQuorum(bytes32 ) view returns(uint256)
func (_CoreStateRegistry *CoreStateRegistryCallerSession) MessageQuorum(arg0 [32]byte) (*big.Int, error) {
	return _CoreStateRegistry.Contract.MessageQuorum(&_CoreStateRegistry.CallOpts, arg0)
}

// PayloadBody is a free data retrieval call binding the contract method 0x361ad42b.
//
// Solidity: function payloadBody(uint256 ) view returns(bytes)
func (_CoreStateRegistry *CoreStateRegistryCaller) PayloadBody(opts *bind.CallOpts, arg0 *big.Int) ([]byte, error) {
	var out []interface{}
	err := _CoreStateRegistry.contract.Call(opts, &out, "payloadBody", arg0)

	if err != nil {
		return *new([]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([]byte)).(*[]byte)

	return out0, err

}

// PayloadBody is a free data retrieval call binding the contract method 0x361ad42b.
//
// Solidity: function payloadBody(uint256 ) view returns(bytes)
func (_CoreStateRegistry *CoreStateRegistrySession) PayloadBody(arg0 *big.Int) ([]byte, error) {
	return _CoreStateRegistry.Contract.PayloadBody(&_CoreStateRegistry.CallOpts, arg0)
}

// PayloadBody is a free data retrieval call binding the contract method 0x361ad42b.
//
// Solidity: function payloadBody(uint256 ) view returns(bytes)
func (_CoreStateRegistry *CoreStateRegistryCallerSession) PayloadBody(arg0 *big.Int) ([]byte, error) {
	return _CoreStateRegistry.Contract.PayloadBody(&_CoreStateRegistry.CallOpts, arg0)
}

// PayloadHeader is a free data retrieval call binding the contract method 0x36445ffd.
//
// Solidity: function payloadHeader(uint256 ) view returns(uint256)
func (_CoreStateRegistry *CoreStateRegistryCaller) PayloadHeader(opts *bind.CallOpts, arg0 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _CoreStateRegistry.contract.Call(opts, &out, "payloadHeader", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PayloadHeader is a free data retrieval call binding the contract method 0x36445ffd.
//
// Solidity: function payloadHeader(uint256 ) view returns(uint256)
func (_CoreStateRegistry *CoreStateRegistrySession) PayloadHeader(arg0 *big.Int) (*big.Int, error) {
	return _CoreStateRegistry.Contract.PayloadHeader(&_CoreStateRegistry.CallOpts, arg0)
}

// PayloadHeader is a free data retrieval call binding the contract method 0x36445ffd.
//
// Solidity: function payloadHeader(uint256 ) view returns(uint256)
func (_CoreStateRegistry *CoreStateRegistryCallerSession) PayloadHeader(arg0 *big.Int) (*big.Int, error) {
	return _CoreStateRegistry.Contract.PayloadHeader(&_CoreStateRegistry.CallOpts, arg0)
}

// PayloadTracking is a free data retrieval call binding the contract method 0xb63d36a5.
//
// Solidity: function payloadTracking(uint256 ) view returns(uint8)
func (_CoreStateRegistry *CoreStateRegistryCaller) PayloadTracking(opts *bind.CallOpts, arg0 *big.Int) (uint8, error) {
	var out []interface{}
	err := _CoreStateRegistry.contract.Call(opts, &out, "payloadTracking", arg0)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// PayloadTracking is a free data retrieval call binding the contract method 0xb63d36a5.
//
// Solidity: function payloadTracking(uint256 ) view returns(uint8)
func (_CoreStateRegistry *CoreStateRegistrySession) PayloadTracking(arg0 *big.Int) (uint8, error) {
	return _CoreStateRegistry.Contract.PayloadTracking(&_CoreStateRegistry.CallOpts, arg0)
}

// PayloadTracking is a free data retrieval call binding the contract method 0xb63d36a5.
//
// Solidity: function payloadTracking(uint256 ) view returns(uint8)
func (_CoreStateRegistry *CoreStateRegistryCallerSession) PayloadTracking(arg0 *big.Int) (uint8, error) {
	return _CoreStateRegistry.Contract.PayloadTracking(&_CoreStateRegistry.CallOpts, arg0)
}

// PayloadsCount is a free data retrieval call binding the contract method 0x13c02a59.
//
// Solidity: function payloadsCount() view returns(uint256)
func (_CoreStateRegistry *CoreStateRegistryCaller) PayloadsCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _CoreStateRegistry.contract.Call(opts, &out, "payloadsCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PayloadsCount is a free data retrieval call binding the contract method 0x13c02a59.
//
// Solidity: function payloadsCount() view returns(uint256)
func (_CoreStateRegistry *CoreStateRegistrySession) PayloadsCount() (*big.Int, error) {
	return _CoreStateRegistry.Contract.PayloadsCount(&_CoreStateRegistry.CallOpts)
}

// PayloadsCount is a free data retrieval call binding the contract method 0x13c02a59.
//
// Solidity: function payloadsCount() view returns(uint256)
func (_CoreStateRegistry *CoreStateRegistryCallerSession) PayloadsCount() (*big.Int, error) {
	return _CoreStateRegistry.Contract.PayloadsCount(&_CoreStateRegistry.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_CoreStateRegistry *CoreStateRegistryCaller) SuperRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _CoreStateRegistry.contract.Call(opts, &out, "superRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_CoreStateRegistry *CoreStateRegistrySession) SuperRegistry() (common.Address, error) {
	return _CoreStateRegistry.Contract.SuperRegistry(&_CoreStateRegistry.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_CoreStateRegistry *CoreStateRegistryCallerSession) SuperRegistry() (common.Address, error) {
	return _CoreStateRegistry.Contract.SuperRegistry(&_CoreStateRegistry.CallOpts)
}

// ValidateSlippage is a free data retrieval call binding the contract method 0x803c15df.
//
// Solidity: function validateSlippage(uint256 finalAmount_, uint256 amount_, uint256 maxSlippage_) view returns(bool)
func (_CoreStateRegistry *CoreStateRegistryCaller) ValidateSlippage(opts *bind.CallOpts, finalAmount_ *big.Int, amount_ *big.Int, maxSlippage_ *big.Int) (bool, error) {
	var out []interface{}
	err := _CoreStateRegistry.contract.Call(opts, &out, "validateSlippage", finalAmount_, amount_, maxSlippage_)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// ValidateSlippage is a free data retrieval call binding the contract method 0x803c15df.
//
// Solidity: function validateSlippage(uint256 finalAmount_, uint256 amount_, uint256 maxSlippage_) view returns(bool)
func (_CoreStateRegistry *CoreStateRegistrySession) ValidateSlippage(finalAmount_ *big.Int, amount_ *big.Int, maxSlippage_ *big.Int) (bool, error) {
	return _CoreStateRegistry.Contract.ValidateSlippage(&_CoreStateRegistry.CallOpts, finalAmount_, amount_, maxSlippage_)
}

// ValidateSlippage is a free data retrieval call binding the contract method 0x803c15df.
//
// Solidity: function validateSlippage(uint256 finalAmount_, uint256 amount_, uint256 maxSlippage_) view returns(bool)
func (_CoreStateRegistry *CoreStateRegistryCallerSession) ValidateSlippage(finalAmount_ *big.Int, amount_ *big.Int, maxSlippage_ *big.Int) (bool, error) {
	return _CoreStateRegistry.Contract.ValidateSlippage(&_CoreStateRegistry.CallOpts, finalAmount_, amount_, maxSlippage_)
}

// DispatchPayload is a paid mutator transaction binding the contract method 0x23de31e1.
//
// Solidity: function dispatchPayload(address srcSender_, uint8[] ambIds_, uint64 dstChainId_, bytes message_, bytes extraData_) payable returns()
func (_CoreStateRegistry *CoreStateRegistryTransactor) DispatchPayload(opts *bind.TransactOpts, srcSender_ common.Address, ambIds_ []uint8, dstChainId_ uint64, message_ []byte, extraData_ []byte) (*types.Transaction, error) {
	return _CoreStateRegistry.contract.Transact(opts, "dispatchPayload", srcSender_, ambIds_, dstChainId_, message_, extraData_)
}

// DispatchPayload is a paid mutator transaction binding the contract method 0x23de31e1.
//
// Solidity: function dispatchPayload(address srcSender_, uint8[] ambIds_, uint64 dstChainId_, bytes message_, bytes extraData_) payable returns()
func (_CoreStateRegistry *CoreStateRegistrySession) DispatchPayload(srcSender_ common.Address, ambIds_ []uint8, dstChainId_ uint64, message_ []byte, extraData_ []byte) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.DispatchPayload(&_CoreStateRegistry.TransactOpts, srcSender_, ambIds_, dstChainId_, message_, extraData_)
}

// DispatchPayload is a paid mutator transaction binding the contract method 0x23de31e1.
//
// Solidity: function dispatchPayload(address srcSender_, uint8[] ambIds_, uint64 dstChainId_, bytes message_, bytes extraData_) payable returns()
func (_CoreStateRegistry *CoreStateRegistryTransactorSession) DispatchPayload(srcSender_ common.Address, ambIds_ []uint8, dstChainId_ uint64, message_ []byte, extraData_ []byte) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.DispatchPayload(&_CoreStateRegistry.TransactOpts, srcSender_, ambIds_, dstChainId_, message_, extraData_)
}

// DisputeRescueFailedDeposits is a paid mutator transaction binding the contract method 0x13bff012.
//
// Solidity: function disputeRescueFailedDeposits(uint256 payloadId_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactor) DisputeRescueFailedDeposits(opts *bind.TransactOpts, payloadId_ *big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.contract.Transact(opts, "disputeRescueFailedDeposits", payloadId_)
}

// DisputeRescueFailedDeposits is a paid mutator transaction binding the contract method 0x13bff012.
//
// Solidity: function disputeRescueFailedDeposits(uint256 payloadId_) returns()
func (_CoreStateRegistry *CoreStateRegistrySession) DisputeRescueFailedDeposits(payloadId_ *big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.DisputeRescueFailedDeposits(&_CoreStateRegistry.TransactOpts, payloadId_)
}

// DisputeRescueFailedDeposits is a paid mutator transaction binding the contract method 0x13bff012.
//
// Solidity: function disputeRescueFailedDeposits(uint256 payloadId_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactorSession) DisputeRescueFailedDeposits(payloadId_ *big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.DisputeRescueFailedDeposits(&_CoreStateRegistry.TransactOpts, payloadId_)
}

// FinalizeRescueFailedDeposits is a paid mutator transaction binding the contract method 0x2d46647d.
//
// Solidity: function finalizeRescueFailedDeposits(uint256 payloadId_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactor) FinalizeRescueFailedDeposits(opts *bind.TransactOpts, payloadId_ *big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.contract.Transact(opts, "finalizeRescueFailedDeposits", payloadId_)
}

// FinalizeRescueFailedDeposits is a paid mutator transaction binding the contract method 0x2d46647d.
//
// Solidity: function finalizeRescueFailedDeposits(uint256 payloadId_) returns()
func (_CoreStateRegistry *CoreStateRegistrySession) FinalizeRescueFailedDeposits(payloadId_ *big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.FinalizeRescueFailedDeposits(&_CoreStateRegistry.TransactOpts, payloadId_)
}

// FinalizeRescueFailedDeposits is a paid mutator transaction binding the contract method 0x2d46647d.
//
// Solidity: function finalizeRescueFailedDeposits(uint256 payloadId_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactorSession) FinalizeRescueFailedDeposits(payloadId_ *big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.FinalizeRescueFailedDeposits(&_CoreStateRegistry.TransactOpts, payloadId_)
}

// ProcessPayload is a paid mutator transaction binding the contract method 0x5aef9480.
//
// Solidity: function processPayload(uint256 payloadId_) payable returns()
func (_CoreStateRegistry *CoreStateRegistryTransactor) ProcessPayload(opts *bind.TransactOpts, payloadId_ *big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.contract.Transact(opts, "processPayload", payloadId_)
}

// ProcessPayload is a paid mutator transaction binding the contract method 0x5aef9480.
//
// Solidity: function processPayload(uint256 payloadId_) payable returns()
func (_CoreStateRegistry *CoreStateRegistrySession) ProcessPayload(payloadId_ *big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.ProcessPayload(&_CoreStateRegistry.TransactOpts, payloadId_)
}

// ProcessPayload is a paid mutator transaction binding the contract method 0x5aef9480.
//
// Solidity: function processPayload(uint256 payloadId_) payable returns()
func (_CoreStateRegistry *CoreStateRegistryTransactorSession) ProcessPayload(payloadId_ *big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.ProcessPayload(&_CoreStateRegistry.TransactOpts, payloadId_)
}

// ProposeRescueFailedDeposits is a paid mutator transaction binding the contract method 0xe17d89e8.
//
// Solidity: function proposeRescueFailedDeposits(uint256 payloadId_, uint256[] proposedAmounts_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactor) ProposeRescueFailedDeposits(opts *bind.TransactOpts, payloadId_ *big.Int, proposedAmounts_ []*big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.contract.Transact(opts, "proposeRescueFailedDeposits", payloadId_, proposedAmounts_)
}

// ProposeRescueFailedDeposits is a paid mutator transaction binding the contract method 0xe17d89e8.
//
// Solidity: function proposeRescueFailedDeposits(uint256 payloadId_, uint256[] proposedAmounts_) returns()
func (_CoreStateRegistry *CoreStateRegistrySession) ProposeRescueFailedDeposits(payloadId_ *big.Int, proposedAmounts_ []*big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.ProposeRescueFailedDeposits(&_CoreStateRegistry.TransactOpts, payloadId_, proposedAmounts_)
}

// ProposeRescueFailedDeposits is a paid mutator transaction binding the contract method 0xe17d89e8.
//
// Solidity: function proposeRescueFailedDeposits(uint256 payloadId_, uint256[] proposedAmounts_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactorSession) ProposeRescueFailedDeposits(payloadId_ *big.Int, proposedAmounts_ []*big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.ProposeRescueFailedDeposits(&_CoreStateRegistry.TransactOpts, payloadId_, proposedAmounts_)
}

// ReceivePayload is a paid mutator transaction binding the contract method 0xcc2d8abd.
//
// Solidity: function receivePayload(uint64 srcChainId_, bytes message_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactor) ReceivePayload(opts *bind.TransactOpts, srcChainId_ uint64, message_ []byte) (*types.Transaction, error) {
	return _CoreStateRegistry.contract.Transact(opts, "receivePayload", srcChainId_, message_)
}

// ReceivePayload is a paid mutator transaction binding the contract method 0xcc2d8abd.
//
// Solidity: function receivePayload(uint64 srcChainId_, bytes message_) returns()
func (_CoreStateRegistry *CoreStateRegistrySession) ReceivePayload(srcChainId_ uint64, message_ []byte) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.ReceivePayload(&_CoreStateRegistry.TransactOpts, srcChainId_, message_)
}

// ReceivePayload is a paid mutator transaction binding the contract method 0xcc2d8abd.
//
// Solidity: function receivePayload(uint64 srcChainId_, bytes message_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactorSession) ReceivePayload(srcChainId_ uint64, message_ []byte) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.ReceivePayload(&_CoreStateRegistry.TransactOpts, srcChainId_, message_)
}

// UpdateDepositPayload is a paid mutator transaction binding the contract method 0x474fd874.
//
// Solidity: function updateDepositPayload(uint256 payloadId_, address[] finalTokens_, uint256[] finalAmounts_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactor) UpdateDepositPayload(opts *bind.TransactOpts, payloadId_ *big.Int, finalTokens_ []common.Address, finalAmounts_ []*big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.contract.Transact(opts, "updateDepositPayload", payloadId_, finalTokens_, finalAmounts_)
}

// UpdateDepositPayload is a paid mutator transaction binding the contract method 0x474fd874.
//
// Solidity: function updateDepositPayload(uint256 payloadId_, address[] finalTokens_, uint256[] finalAmounts_) returns()
func (_CoreStateRegistry *CoreStateRegistrySession) UpdateDepositPayload(payloadId_ *big.Int, finalTokens_ []common.Address, finalAmounts_ []*big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.UpdateDepositPayload(&_CoreStateRegistry.TransactOpts, payloadId_, finalTokens_, finalAmounts_)
}

// UpdateDepositPayload is a paid mutator transaction binding the contract method 0x474fd874.
//
// Solidity: function updateDepositPayload(uint256 payloadId_, address[] finalTokens_, uint256[] finalAmounts_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactorSession) UpdateDepositPayload(payloadId_ *big.Int, finalTokens_ []common.Address, finalAmounts_ []*big.Int) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.UpdateDepositPayload(&_CoreStateRegistry.TransactOpts, payloadId_, finalTokens_, finalAmounts_)
}

// UpdateWithdrawPayload is a paid mutator transaction binding the contract method 0x439890e2.
//
// Solidity: function updateWithdrawPayload(uint256 payloadId_, bytes[] txData_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactor) UpdateWithdrawPayload(opts *bind.TransactOpts, payloadId_ *big.Int, txData_ [][]byte) (*types.Transaction, error) {
	return _CoreStateRegistry.contract.Transact(opts, "updateWithdrawPayload", payloadId_, txData_)
}

// UpdateWithdrawPayload is a paid mutator transaction binding the contract method 0x439890e2.
//
// Solidity: function updateWithdrawPayload(uint256 payloadId_, bytes[] txData_) returns()
func (_CoreStateRegistry *CoreStateRegistrySession) UpdateWithdrawPayload(payloadId_ *big.Int, txData_ [][]byte) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.UpdateWithdrawPayload(&_CoreStateRegistry.TransactOpts, payloadId_, txData_)
}

// UpdateWithdrawPayload is a paid mutator transaction binding the contract method 0x439890e2.
//
// Solidity: function updateWithdrawPayload(uint256 payloadId_, bytes[] txData_) returns()
func (_CoreStateRegistry *CoreStateRegistryTransactorSession) UpdateWithdrawPayload(payloadId_ *big.Int, txData_ [][]byte) (*types.Transaction, error) {
	return _CoreStateRegistry.Contract.UpdateWithdrawPayload(&_CoreStateRegistry.TransactOpts, payloadId_, txData_)
}

// CoreStateRegistryFailedXChainDepositsIterator is returned from FilterFailedXChainDeposits and is used to iterate over the raw logs and unpacked data for FailedXChainDeposits events raised by the CoreStateRegistry contract.
type CoreStateRegistryFailedXChainDepositsIterator struct {
	Event *CoreStateRegistryFailedXChainDeposits // Event containing the contract specifics and raw log

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
func (it *CoreStateRegistryFailedXChainDepositsIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CoreStateRegistryFailedXChainDeposits)
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
		it.Event = new(CoreStateRegistryFailedXChainDeposits)
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
func (it *CoreStateRegistryFailedXChainDepositsIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CoreStateRegistryFailedXChainDepositsIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CoreStateRegistryFailedXChainDeposits represents a FailedXChainDeposits event raised by the CoreStateRegistry contract.
type CoreStateRegistryFailedXChainDeposits struct {
	PayloadId *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterFailedXChainDeposits is a free log retrieval operation binding the contract event 0x21c4f33a94342256a428d6cb08476047bdb16e6866308b7d904df8990eb781c8.
//
// Solidity: event FailedXChainDeposits(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) FilterFailedXChainDeposits(opts *bind.FilterOpts, payloadId []*big.Int) (*CoreStateRegistryFailedXChainDepositsIterator, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.FilterLogs(opts, "FailedXChainDeposits", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistryFailedXChainDepositsIterator{contract: _CoreStateRegistry.contract, event: "FailedXChainDeposits", logs: logs, sub: sub}, nil
}

// WatchFailedXChainDeposits is a free log subscription operation binding the contract event 0x21c4f33a94342256a428d6cb08476047bdb16e6866308b7d904df8990eb781c8.
//
// Solidity: event FailedXChainDeposits(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) WatchFailedXChainDeposits(opts *bind.WatchOpts, sink chan<- *CoreStateRegistryFailedXChainDeposits, payloadId []*big.Int) (event.Subscription, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.WatchLogs(opts, "FailedXChainDeposits", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CoreStateRegistryFailedXChainDeposits)
				if err := _CoreStateRegistry.contract.UnpackLog(event, "FailedXChainDeposits", log); err != nil {
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

// ParseFailedXChainDeposits is a log parse operation binding the contract event 0x21c4f33a94342256a428d6cb08476047bdb16e6866308b7d904df8990eb781c8.
//
// Solidity: event FailedXChainDeposits(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) ParseFailedXChainDeposits(log types.Log) (*CoreStateRegistryFailedXChainDeposits, error) {
	event := new(CoreStateRegistryFailedXChainDeposits)
	if err := _CoreStateRegistry.contract.UnpackLog(event, "FailedXChainDeposits", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// CoreStateRegistryPayloadProcessedIterator is returned from FilterPayloadProcessed and is used to iterate over the raw logs and unpacked data for PayloadProcessed events raised by the CoreStateRegistry contract.
type CoreStateRegistryPayloadProcessedIterator struct {
	Event *CoreStateRegistryPayloadProcessed // Event containing the contract specifics and raw log

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
func (it *CoreStateRegistryPayloadProcessedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CoreStateRegistryPayloadProcessed)
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
		it.Event = new(CoreStateRegistryPayloadProcessed)
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
func (it *CoreStateRegistryPayloadProcessedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CoreStateRegistryPayloadProcessedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CoreStateRegistryPayloadProcessed represents a PayloadProcessed event raised by the CoreStateRegistry contract.
type CoreStateRegistryPayloadProcessed struct {
	PayloadId *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterPayloadProcessed is a free log retrieval operation binding the contract event 0xbce0bd6fef1367dca0b65255a7d010501f79e4dd96d4add4c3e42a419ae6457c.
//
// Solidity: event PayloadProcessed(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) FilterPayloadProcessed(opts *bind.FilterOpts, payloadId []*big.Int) (*CoreStateRegistryPayloadProcessedIterator, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.FilterLogs(opts, "PayloadProcessed", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistryPayloadProcessedIterator{contract: _CoreStateRegistry.contract, event: "PayloadProcessed", logs: logs, sub: sub}, nil
}

// WatchPayloadProcessed is a free log subscription operation binding the contract event 0xbce0bd6fef1367dca0b65255a7d010501f79e4dd96d4add4c3e42a419ae6457c.
//
// Solidity: event PayloadProcessed(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) WatchPayloadProcessed(opts *bind.WatchOpts, sink chan<- *CoreStateRegistryPayloadProcessed, payloadId []*big.Int) (event.Subscription, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.WatchLogs(opts, "PayloadProcessed", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CoreStateRegistryPayloadProcessed)
				if err := _CoreStateRegistry.contract.UnpackLog(event, "PayloadProcessed", log); err != nil {
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

// ParsePayloadProcessed is a log parse operation binding the contract event 0xbce0bd6fef1367dca0b65255a7d010501f79e4dd96d4add4c3e42a419ae6457c.
//
// Solidity: event PayloadProcessed(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) ParsePayloadProcessed(log types.Log) (*CoreStateRegistryPayloadProcessed, error) {
	event := new(CoreStateRegistryPayloadProcessed)
	if err := _CoreStateRegistry.contract.UnpackLog(event, "PayloadProcessed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// CoreStateRegistryPayloadReceivedIterator is returned from FilterPayloadReceived and is used to iterate over the raw logs and unpacked data for PayloadReceived events raised by the CoreStateRegistry contract.
type CoreStateRegistryPayloadReceivedIterator struct {
	Event *CoreStateRegistryPayloadReceived // Event containing the contract specifics and raw log

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
func (it *CoreStateRegistryPayloadReceivedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CoreStateRegistryPayloadReceived)
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
		it.Event = new(CoreStateRegistryPayloadReceived)
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
func (it *CoreStateRegistryPayloadReceivedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CoreStateRegistryPayloadReceivedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CoreStateRegistryPayloadReceived represents a PayloadReceived event raised by the CoreStateRegistry contract.
type CoreStateRegistryPayloadReceived struct {
	SrcChainId uint64
	DstChainId uint64
	PayloadId  *big.Int
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterPayloadReceived is a free log retrieval operation binding the contract event 0x3371afb211a5a616ecaaab76f9466c9295fae2aa4e6dc1ed821b6eb25ee442cf.
//
// Solidity: event PayloadReceived(uint64 indexed srcChainId, uint64 indexed dstChainId, uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) FilterPayloadReceived(opts *bind.FilterOpts, srcChainId []uint64, dstChainId []uint64, payloadId []*big.Int) (*CoreStateRegistryPayloadReceivedIterator, error) {

	var srcChainIdRule []interface{}
	for _, srcChainIdItem := range srcChainId {
		srcChainIdRule = append(srcChainIdRule, srcChainIdItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}
	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.FilterLogs(opts, "PayloadReceived", srcChainIdRule, dstChainIdRule, payloadIdRule)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistryPayloadReceivedIterator{contract: _CoreStateRegistry.contract, event: "PayloadReceived", logs: logs, sub: sub}, nil
}

// WatchPayloadReceived is a free log subscription operation binding the contract event 0x3371afb211a5a616ecaaab76f9466c9295fae2aa4e6dc1ed821b6eb25ee442cf.
//
// Solidity: event PayloadReceived(uint64 indexed srcChainId, uint64 indexed dstChainId, uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) WatchPayloadReceived(opts *bind.WatchOpts, sink chan<- *CoreStateRegistryPayloadReceived, srcChainId []uint64, dstChainId []uint64, payloadId []*big.Int) (event.Subscription, error) {

	var srcChainIdRule []interface{}
	for _, srcChainIdItem := range srcChainId {
		srcChainIdRule = append(srcChainIdRule, srcChainIdItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}
	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.WatchLogs(opts, "PayloadReceived", srcChainIdRule, dstChainIdRule, payloadIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CoreStateRegistryPayloadReceived)
				if err := _CoreStateRegistry.contract.UnpackLog(event, "PayloadReceived", log); err != nil {
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

// ParsePayloadReceived is a log parse operation binding the contract event 0x3371afb211a5a616ecaaab76f9466c9295fae2aa4e6dc1ed821b6eb25ee442cf.
//
// Solidity: event PayloadReceived(uint64 indexed srcChainId, uint64 indexed dstChainId, uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) ParsePayloadReceived(log types.Log) (*CoreStateRegistryPayloadReceived, error) {
	event := new(CoreStateRegistryPayloadReceived)
	if err := _CoreStateRegistry.contract.UnpackLog(event, "PayloadReceived", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// CoreStateRegistryPayloadUpdatedIterator is returned from FilterPayloadUpdated and is used to iterate over the raw logs and unpacked data for PayloadUpdated events raised by the CoreStateRegistry contract.
type CoreStateRegistryPayloadUpdatedIterator struct {
	Event *CoreStateRegistryPayloadUpdated // Event containing the contract specifics and raw log

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
func (it *CoreStateRegistryPayloadUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CoreStateRegistryPayloadUpdated)
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
		it.Event = new(CoreStateRegistryPayloadUpdated)
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
func (it *CoreStateRegistryPayloadUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CoreStateRegistryPayloadUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CoreStateRegistryPayloadUpdated represents a PayloadUpdated event raised by the CoreStateRegistry contract.
type CoreStateRegistryPayloadUpdated struct {
	PayloadId *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterPayloadUpdated is a free log retrieval operation binding the contract event 0x144d814d5dc6f17c1a88bc42c55d67392a51c818908ed7cca6118bc51a34b153.
//
// Solidity: event PayloadUpdated(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) FilterPayloadUpdated(opts *bind.FilterOpts, payloadId []*big.Int) (*CoreStateRegistryPayloadUpdatedIterator, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.FilterLogs(opts, "PayloadUpdated", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistryPayloadUpdatedIterator{contract: _CoreStateRegistry.contract, event: "PayloadUpdated", logs: logs, sub: sub}, nil
}

// WatchPayloadUpdated is a free log subscription operation binding the contract event 0x144d814d5dc6f17c1a88bc42c55d67392a51c818908ed7cca6118bc51a34b153.
//
// Solidity: event PayloadUpdated(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) WatchPayloadUpdated(opts *bind.WatchOpts, sink chan<- *CoreStateRegistryPayloadUpdated, payloadId []*big.Int) (event.Subscription, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.WatchLogs(opts, "PayloadUpdated", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CoreStateRegistryPayloadUpdated)
				if err := _CoreStateRegistry.contract.UnpackLog(event, "PayloadUpdated", log); err != nil {
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

// ParsePayloadUpdated is a log parse operation binding the contract event 0x144d814d5dc6f17c1a88bc42c55d67392a51c818908ed7cca6118bc51a34b153.
//
// Solidity: event PayloadUpdated(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) ParsePayloadUpdated(log types.Log) (*CoreStateRegistryPayloadUpdated, error) {
	event := new(CoreStateRegistryPayloadUpdated)
	if err := _CoreStateRegistry.contract.UnpackLog(event, "PayloadUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// CoreStateRegistryProofReceivedIterator is returned from FilterProofReceived and is used to iterate over the raw logs and unpacked data for ProofReceived events raised by the CoreStateRegistry contract.
type CoreStateRegistryProofReceivedIterator struct {
	Event *CoreStateRegistryProofReceived // Event containing the contract specifics and raw log

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
func (it *CoreStateRegistryProofReceivedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CoreStateRegistryProofReceived)
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
		it.Event = new(CoreStateRegistryProofReceived)
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
func (it *CoreStateRegistryProofReceivedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CoreStateRegistryProofReceivedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CoreStateRegistryProofReceived represents a ProofReceived event raised by the CoreStateRegistry contract.
type CoreStateRegistryProofReceived struct {
	Proof [32]byte
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterProofReceived is a free log retrieval operation binding the contract event 0xfeea67837572d96738a25f3ac5fa382a1c601ead52e97fb27a02c6103360c063.
//
// Solidity: event ProofReceived(bytes32 indexed proof)
func (_CoreStateRegistry *CoreStateRegistryFilterer) FilterProofReceived(opts *bind.FilterOpts, proof [][32]byte) (*CoreStateRegistryProofReceivedIterator, error) {

	var proofRule []interface{}
	for _, proofItem := range proof {
		proofRule = append(proofRule, proofItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.FilterLogs(opts, "ProofReceived", proofRule)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistryProofReceivedIterator{contract: _CoreStateRegistry.contract, event: "ProofReceived", logs: logs, sub: sub}, nil
}

// WatchProofReceived is a free log subscription operation binding the contract event 0xfeea67837572d96738a25f3ac5fa382a1c601ead52e97fb27a02c6103360c063.
//
// Solidity: event ProofReceived(bytes32 indexed proof)
func (_CoreStateRegistry *CoreStateRegistryFilterer) WatchProofReceived(opts *bind.WatchOpts, sink chan<- *CoreStateRegistryProofReceived, proof [][32]byte) (event.Subscription, error) {

	var proofRule []interface{}
	for _, proofItem := range proof {
		proofRule = append(proofRule, proofItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.WatchLogs(opts, "ProofReceived", proofRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CoreStateRegistryProofReceived)
				if err := _CoreStateRegistry.contract.UnpackLog(event, "ProofReceived", log); err != nil {
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

// ParseProofReceived is a log parse operation binding the contract event 0xfeea67837572d96738a25f3ac5fa382a1c601ead52e97fb27a02c6103360c063.
//
// Solidity: event ProofReceived(bytes32 indexed proof)
func (_CoreStateRegistry *CoreStateRegistryFilterer) ParseProofReceived(log types.Log) (*CoreStateRegistryProofReceived, error) {
	event := new(CoreStateRegistryProofReceived)
	if err := _CoreStateRegistry.contract.UnpackLog(event, "ProofReceived", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// CoreStateRegistryRescueDisputedIterator is returned from FilterRescueDisputed and is used to iterate over the raw logs and unpacked data for RescueDisputed events raised by the CoreStateRegistry contract.
type CoreStateRegistryRescueDisputedIterator struct {
	Event *CoreStateRegistryRescueDisputed // Event containing the contract specifics and raw log

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
func (it *CoreStateRegistryRescueDisputedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CoreStateRegistryRescueDisputed)
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
		it.Event = new(CoreStateRegistryRescueDisputed)
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
func (it *CoreStateRegistryRescueDisputedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CoreStateRegistryRescueDisputedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CoreStateRegistryRescueDisputed represents a RescueDisputed event raised by the CoreStateRegistry contract.
type CoreStateRegistryRescueDisputed struct {
	PayloadId *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterRescueDisputed is a free log retrieval operation binding the contract event 0x7e98ef42b90939b396b85416fa66b14f7a5c284f7a7e794d995b3fad3c6e85cb.
//
// Solidity: event RescueDisputed(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) FilterRescueDisputed(opts *bind.FilterOpts, payloadId []*big.Int) (*CoreStateRegistryRescueDisputedIterator, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.FilterLogs(opts, "RescueDisputed", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistryRescueDisputedIterator{contract: _CoreStateRegistry.contract, event: "RescueDisputed", logs: logs, sub: sub}, nil
}

// WatchRescueDisputed is a free log subscription operation binding the contract event 0x7e98ef42b90939b396b85416fa66b14f7a5c284f7a7e794d995b3fad3c6e85cb.
//
// Solidity: event RescueDisputed(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) WatchRescueDisputed(opts *bind.WatchOpts, sink chan<- *CoreStateRegistryRescueDisputed, payloadId []*big.Int) (event.Subscription, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.WatchLogs(opts, "RescueDisputed", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CoreStateRegistryRescueDisputed)
				if err := _CoreStateRegistry.contract.UnpackLog(event, "RescueDisputed", log); err != nil {
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

// ParseRescueDisputed is a log parse operation binding the contract event 0x7e98ef42b90939b396b85416fa66b14f7a5c284f7a7e794d995b3fad3c6e85cb.
//
// Solidity: event RescueDisputed(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) ParseRescueDisputed(log types.Log) (*CoreStateRegistryRescueDisputed, error) {
	event := new(CoreStateRegistryRescueDisputed)
	if err := _CoreStateRegistry.contract.UnpackLog(event, "RescueDisputed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// CoreStateRegistryRescueFinalizedIterator is returned from FilterRescueFinalized and is used to iterate over the raw logs and unpacked data for RescueFinalized events raised by the CoreStateRegistry contract.
type CoreStateRegistryRescueFinalizedIterator struct {
	Event *CoreStateRegistryRescueFinalized // Event containing the contract specifics and raw log

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
func (it *CoreStateRegistryRescueFinalizedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CoreStateRegistryRescueFinalized)
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
		it.Event = new(CoreStateRegistryRescueFinalized)
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
func (it *CoreStateRegistryRescueFinalizedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CoreStateRegistryRescueFinalizedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CoreStateRegistryRescueFinalized represents a RescueFinalized event raised by the CoreStateRegistry contract.
type CoreStateRegistryRescueFinalized struct {
	PayloadId *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterRescueFinalized is a free log retrieval operation binding the contract event 0x4dcd0d064503785f7194bc0d094f808cd1df65b1440424e51cd211c9672f77cc.
//
// Solidity: event RescueFinalized(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) FilterRescueFinalized(opts *bind.FilterOpts, payloadId []*big.Int) (*CoreStateRegistryRescueFinalizedIterator, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.FilterLogs(opts, "RescueFinalized", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistryRescueFinalizedIterator{contract: _CoreStateRegistry.contract, event: "RescueFinalized", logs: logs, sub: sub}, nil
}

// WatchRescueFinalized is a free log subscription operation binding the contract event 0x4dcd0d064503785f7194bc0d094f808cd1df65b1440424e51cd211c9672f77cc.
//
// Solidity: event RescueFinalized(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) WatchRescueFinalized(opts *bind.WatchOpts, sink chan<- *CoreStateRegistryRescueFinalized, payloadId []*big.Int) (event.Subscription, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.WatchLogs(opts, "RescueFinalized", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CoreStateRegistryRescueFinalized)
				if err := _CoreStateRegistry.contract.UnpackLog(event, "RescueFinalized", log); err != nil {
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

// ParseRescueFinalized is a log parse operation binding the contract event 0x4dcd0d064503785f7194bc0d094f808cd1df65b1440424e51cd211c9672f77cc.
//
// Solidity: event RescueFinalized(uint256 indexed payloadId)
func (_CoreStateRegistry *CoreStateRegistryFilterer) ParseRescueFinalized(log types.Log) (*CoreStateRegistryRescueFinalized, error) {
	event := new(CoreStateRegistryRescueFinalized)
	if err := _CoreStateRegistry.contract.UnpackLog(event, "RescueFinalized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// CoreStateRegistryRescueProposedIterator is returned from FilterRescueProposed and is used to iterate over the raw logs and unpacked data for RescueProposed events raised by the CoreStateRegistry contract.
type CoreStateRegistryRescueProposedIterator struct {
	Event *CoreStateRegistryRescueProposed // Event containing the contract specifics and raw log

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
func (it *CoreStateRegistryRescueProposedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CoreStateRegistryRescueProposed)
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
		it.Event = new(CoreStateRegistryRescueProposed)
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
func (it *CoreStateRegistryRescueProposedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CoreStateRegistryRescueProposedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CoreStateRegistryRescueProposed represents a RescueProposed event raised by the CoreStateRegistry contract.
type CoreStateRegistryRescueProposed struct {
	PayloadId      *big.Int
	SuperformIds   []*big.Int
	ProposedAmount []*big.Int
	ProposedTime   *big.Int
	Raw            types.Log // Blockchain specific contextual infos
}

// FilterRescueProposed is a free log retrieval operation binding the contract event 0x78f133e107c1f55f0cb4abf0d9d0afc7d4949197a40bb9c88b97d51aec80f5cf.
//
// Solidity: event RescueProposed(uint256 indexed payloadId, uint256[] superformIds, uint256[] proposedAmount, uint256 proposedTime)
func (_CoreStateRegistry *CoreStateRegistryFilterer) FilterRescueProposed(opts *bind.FilterOpts, payloadId []*big.Int) (*CoreStateRegistryRescueProposedIterator, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.FilterLogs(opts, "RescueProposed", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistryRescueProposedIterator{contract: _CoreStateRegistry.contract, event: "RescueProposed", logs: logs, sub: sub}, nil
}

// WatchRescueProposed is a free log subscription operation binding the contract event 0x78f133e107c1f55f0cb4abf0d9d0afc7d4949197a40bb9c88b97d51aec80f5cf.
//
// Solidity: event RescueProposed(uint256 indexed payloadId, uint256[] superformIds, uint256[] proposedAmount, uint256 proposedTime)
func (_CoreStateRegistry *CoreStateRegistryFilterer) WatchRescueProposed(opts *bind.WatchOpts, sink chan<- *CoreStateRegistryRescueProposed, payloadId []*big.Int) (event.Subscription, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.WatchLogs(opts, "RescueProposed", payloadIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CoreStateRegistryRescueProposed)
				if err := _CoreStateRegistry.contract.UnpackLog(event, "RescueProposed", log); err != nil {
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

// ParseRescueProposed is a log parse operation binding the contract event 0x78f133e107c1f55f0cb4abf0d9d0afc7d4949197a40bb9c88b97d51aec80f5cf.
//
// Solidity: event RescueProposed(uint256 indexed payloadId, uint256[] superformIds, uint256[] proposedAmount, uint256 proposedTime)
func (_CoreStateRegistry *CoreStateRegistryFilterer) ParseRescueProposed(log types.Log) (*CoreStateRegistryRescueProposed, error) {
	event := new(CoreStateRegistryRescueProposed)
	if err := _CoreStateRegistry.contract.UnpackLog(event, "RescueProposed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// CoreStateRegistrySuperRegistryUpdatedIterator is returned from FilterSuperRegistryUpdated and is used to iterate over the raw logs and unpacked data for SuperRegistryUpdated events raised by the CoreStateRegistry contract.
type CoreStateRegistrySuperRegistryUpdatedIterator struct {
	Event *CoreStateRegistrySuperRegistryUpdated // Event containing the contract specifics and raw log

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
func (it *CoreStateRegistrySuperRegistryUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CoreStateRegistrySuperRegistryUpdated)
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
		it.Event = new(CoreStateRegistrySuperRegistryUpdated)
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
func (it *CoreStateRegistrySuperRegistryUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CoreStateRegistrySuperRegistryUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CoreStateRegistrySuperRegistryUpdated represents a SuperRegistryUpdated event raised by the CoreStateRegistry contract.
type CoreStateRegistrySuperRegistryUpdated struct {
	SuperRegistry common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterSuperRegistryUpdated is a free log retrieval operation binding the contract event 0xeaf7993bef68cfddc6098ead78c5c5734292af7bb159688dd49a4a1af69f58a3.
//
// Solidity: event SuperRegistryUpdated(address indexed superRegistry)
func (_CoreStateRegistry *CoreStateRegistryFilterer) FilterSuperRegistryUpdated(opts *bind.FilterOpts, superRegistry []common.Address) (*CoreStateRegistrySuperRegistryUpdatedIterator, error) {

	var superRegistryRule []interface{}
	for _, superRegistryItem := range superRegistry {
		superRegistryRule = append(superRegistryRule, superRegistryItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.FilterLogs(opts, "SuperRegistryUpdated", superRegistryRule)
	if err != nil {
		return nil, err
	}
	return &CoreStateRegistrySuperRegistryUpdatedIterator{contract: _CoreStateRegistry.contract, event: "SuperRegistryUpdated", logs: logs, sub: sub}, nil
}

// WatchSuperRegistryUpdated is a free log subscription operation binding the contract event 0xeaf7993bef68cfddc6098ead78c5c5734292af7bb159688dd49a4a1af69f58a3.
//
// Solidity: event SuperRegistryUpdated(address indexed superRegistry)
func (_CoreStateRegistry *CoreStateRegistryFilterer) WatchSuperRegistryUpdated(opts *bind.WatchOpts, sink chan<- *CoreStateRegistrySuperRegistryUpdated, superRegistry []common.Address) (event.Subscription, error) {

	var superRegistryRule []interface{}
	for _, superRegistryItem := range superRegistry {
		superRegistryRule = append(superRegistryRule, superRegistryItem)
	}

	logs, sub, err := _CoreStateRegistry.contract.WatchLogs(opts, "SuperRegistryUpdated", superRegistryRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CoreStateRegistrySuperRegistryUpdated)
				if err := _CoreStateRegistry.contract.UnpackLog(event, "SuperRegistryUpdated", log); err != nil {
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

// ParseSuperRegistryUpdated is a log parse operation binding the contract event 0xeaf7993bef68cfddc6098ead78c5c5734292af7bb159688dd49a4a1af69f58a3.
//
// Solidity: event SuperRegistryUpdated(address indexed superRegistry)
func (_CoreStateRegistry *CoreStateRegistryFilterer) ParseSuperRegistryUpdated(log types.Log) (*CoreStateRegistrySuperRegistryUpdated, error) {
	event := new(CoreStateRegistrySuperRegistryUpdated)
	if err := _CoreStateRegistry.contract.UnpackLog(event, "SuperRegistryUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
