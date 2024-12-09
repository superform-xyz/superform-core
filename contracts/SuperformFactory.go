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

// SFFactoryMetaData contains all meta data concerning the SFFactory contract.
var SFFactoryMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superRegistry_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"CHAIN_ID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"addFormImplementation\",\"inputs\":[{\"name\":\"formImplementation_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"formImplementationId_\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"formStateRegistryId_\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"changeFormImplementationPauseStatus\",\"inputs\":[{\"name\":\"formImplementationId_\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"status_\",\"type\":\"uint8\",\"internalType\":\"enumISuperformFactory.PauseStatus\"},{\"name\":\"extraData_\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"createSuperform\",\"inputs\":[{\"name\":\"formImplementationId_\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"vault_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"superformId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"superform_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"formImplementation\",\"inputs\":[{\"name\":\"formImplementationId\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"formImplementationAddress\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"formImplementationIds\",\"inputs\":[{\"name\":\"formImplementationAddress\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"formImplementationId\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"formImplementationPaused\",\"inputs\":[{\"name\":\"formImplementationId\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumISuperformFactory.PauseStatus\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"formImplementations\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"formStateRegistryId\",\"inputs\":[{\"name\":\"formImplementationId\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"formRegistryId\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getAllSuperformsFromVault\",\"inputs\":[{\"name\":\"vault_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"superformIds_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"superforms_\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getFormCount\",\"inputs\":[],\"outputs\":[{\"name\":\"forms_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getFormImplementation\",\"inputs\":[{\"name\":\"formImplementationId_\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getFormStateRegistryId\",\"inputs\":[{\"name\":\"formImplementationId_\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"formStateRegistryId_\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSuperform\",\"inputs\":[{\"name\":\"superformId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"superform_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"formImplementationId_\",\"type\":\"uint32\",\"internalType\":\"uint32\"},{\"name\":\"chainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"getSuperformCount\",\"inputs\":[],\"outputs\":[{\"name\":\"superforms_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isFormImplementationPaused\",\"inputs\":[{\"name\":\"formImplementationId_\",\"type\":\"uint32\",\"internalType\":\"uint32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"isSuperform\",\"inputs\":[{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"superformIdExists\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"stateSyncBroadcast\",\"inputs\":[{\"name\":\"data_\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"superRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperRegistry\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"superforms\",\"inputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"vaultFormImplCombinationToSuperforms\",\"inputs\":[{\"name\":\"vaultFormImplementationCombination\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"superformIds\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"vaultToFormImplementationId\",\"inputs\":[{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"formImplementationId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"vaultToSuperforms\",\"inputs\":[{\"name\":\"vault\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"superformIds\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"xChainPayloadCounter\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"FormImplementationAdded\",\"inputs\":[{\"name\":\"formImplementation\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"formImplementationId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"formStateRegistryId\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"uint8\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FormImplementationPaused\",\"inputs\":[{\"name\":\"formImplementationId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"paused\",\"type\":\"uint8\",\"indexed\":true,\"internalType\":\"enumISuperformFactory.PauseStatus\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperRegistrySet\",\"inputs\":[{\"name\":\"superRegistry\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SuperformCreated\",\"inputs\":[{\"name\":\"formImplementationId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"superformId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"superform\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"BLOCK_CHAIN_ID_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ERC1167FailedCreateClone\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ERC165_UNSUPPORTED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FAILED_TO_SEND_NATIVE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FORM_DOES_NOT_EXIST\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FORM_IMPLEMENTATION_ALREADY_EXISTS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FORM_IMPLEMENTATION_ID_ALREADY_EXISTS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FORM_INTERFACE_UNSUPPORTED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_BROADCAST_FEE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_CHAIN_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_FORM_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_FORM_REGISTRY_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"MSG_VALUE_NOT_ZERO\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_BROADCAST_REGISTRY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_EMERGENCY_ADMIN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_PROTOCOL_ADMIN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"VAULT_FORM_IMPLEMENTATION_COMBINATION_EXISTS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]}]",
}

// SFFactoryABI is the input ABI used to generate the binding from.
// Deprecated: Use SFFactoryMetaData.ABI instead.
var SFFactoryABI = SFFactoryMetaData.ABI

// SFFactory is an auto generated Go binding around an Ethereum contract.
type SFFactory struct {
	SFFactoryCaller     // Read-only binding to the contract
	SFFactoryTransactor // Write-only binding to the contract
	SFFactoryFilterer   // Log filterer for contract events
}

// SFFactoryCaller is an auto generated read-only Go binding around an Ethereum contract.
type SFFactoryCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SFFactoryTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SFFactoryTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SFFactoryFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SFFactoryFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SFFactorySession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SFFactorySession struct {
	Contract     *SFFactory        // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// SFFactoryCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SFFactoryCallerSession struct {
	Contract *SFFactoryCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts    // Call options to use throughout this session
}

// SFFactoryTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SFFactoryTransactorSession struct {
	Contract     *SFFactoryTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts    // Transaction auth options to use throughout this session
}

// SFFactoryRaw is an auto generated low-level Go binding around an Ethereum contract.
type SFFactoryRaw struct {
	Contract *SFFactory // Generic contract binding to access the raw methods on
}

// SFFactoryCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SFFactoryCallerRaw struct {
	Contract *SFFactoryCaller // Generic read-only contract binding to access the raw methods on
}

// SFFactoryTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SFFactoryTransactorRaw struct {
	Contract *SFFactoryTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSFFactory creates a new instance of SFFactory, bound to a specific deployed contract.
func NewSFFactory(address common.Address, backend bind.ContractBackend) (*SFFactory, error) {
	contract, err := bindSFFactory(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SFFactory{SFFactoryCaller: SFFactoryCaller{contract: contract}, SFFactoryTransactor: SFFactoryTransactor{contract: contract}, SFFactoryFilterer: SFFactoryFilterer{contract: contract}}, nil
}

// NewSFFactoryCaller creates a new read-only instance of SFFactory, bound to a specific deployed contract.
func NewSFFactoryCaller(address common.Address, caller bind.ContractCaller) (*SFFactoryCaller, error) {
	contract, err := bindSFFactory(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SFFactoryCaller{contract: contract}, nil
}

// NewSFFactoryTransactor creates a new write-only instance of SFFactory, bound to a specific deployed contract.
func NewSFFactoryTransactor(address common.Address, transactor bind.ContractTransactor) (*SFFactoryTransactor, error) {
	contract, err := bindSFFactory(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SFFactoryTransactor{contract: contract}, nil
}

// NewSFFactoryFilterer creates a new log filterer instance of SFFactory, bound to a specific deployed contract.
func NewSFFactoryFilterer(address common.Address, filterer bind.ContractFilterer) (*SFFactoryFilterer, error) {
	contract, err := bindSFFactory(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SFFactoryFilterer{contract: contract}, nil
}

// bindSFFactory binds a generic wrapper to an already deployed contract.
func bindSFFactory(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SFFactoryMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SFFactory *SFFactoryRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SFFactory.Contract.SFFactoryCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SFFactory *SFFactoryRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SFFactory.Contract.SFFactoryTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SFFactory *SFFactoryRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SFFactory.Contract.SFFactoryTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SFFactory *SFFactoryCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SFFactory.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SFFactory *SFFactoryTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SFFactory.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SFFactory *SFFactoryTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SFFactory.Contract.contract.Transact(opts, method, params...)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SFFactory *SFFactoryCaller) CHAINID(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "CHAIN_ID")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SFFactory *SFFactorySession) CHAINID() (uint64, error) {
	return _SFFactory.Contract.CHAINID(&_SFFactory.CallOpts)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SFFactory *SFFactoryCallerSession) CHAINID() (uint64, error) {
	return _SFFactory.Contract.CHAINID(&_SFFactory.CallOpts)
}

// FormImplementation is a free data retrieval call binding the contract method 0xe83310a2.
//
// Solidity: function formImplementation(uint32 formImplementationId) view returns(address formImplementationAddress)
func (_SFFactory *SFFactoryCaller) FormImplementation(opts *bind.CallOpts, formImplementationId uint32) (common.Address, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "formImplementation", formImplementationId)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// FormImplementation is a free data retrieval call binding the contract method 0xe83310a2.
//
// Solidity: function formImplementation(uint32 formImplementationId) view returns(address formImplementationAddress)
func (_SFFactory *SFFactorySession) FormImplementation(formImplementationId uint32) (common.Address, error) {
	return _SFFactory.Contract.FormImplementation(&_SFFactory.CallOpts, formImplementationId)
}

// FormImplementation is a free data retrieval call binding the contract method 0xe83310a2.
//
// Solidity: function formImplementation(uint32 formImplementationId) view returns(address formImplementationAddress)
func (_SFFactory *SFFactoryCallerSession) FormImplementation(formImplementationId uint32) (common.Address, error) {
	return _SFFactory.Contract.FormImplementation(&_SFFactory.CallOpts, formImplementationId)
}

// FormImplementationIds is a free data retrieval call binding the contract method 0x80e8586b.
//
// Solidity: function formImplementationIds(address formImplementationAddress) view returns(uint32 formImplementationId)
func (_SFFactory *SFFactoryCaller) FormImplementationIds(opts *bind.CallOpts, formImplementationAddress common.Address) (uint32, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "formImplementationIds", formImplementationAddress)

	if err != nil {
		return *new(uint32), err
	}

	out0 := *abi.ConvertType(out[0], new(uint32)).(*uint32)

	return out0, err

}

// FormImplementationIds is a free data retrieval call binding the contract method 0x80e8586b.
//
// Solidity: function formImplementationIds(address formImplementationAddress) view returns(uint32 formImplementationId)
func (_SFFactory *SFFactorySession) FormImplementationIds(formImplementationAddress common.Address) (uint32, error) {
	return _SFFactory.Contract.FormImplementationIds(&_SFFactory.CallOpts, formImplementationAddress)
}

// FormImplementationIds is a free data retrieval call binding the contract method 0x80e8586b.
//
// Solidity: function formImplementationIds(address formImplementationAddress) view returns(uint32 formImplementationId)
func (_SFFactory *SFFactoryCallerSession) FormImplementationIds(formImplementationAddress common.Address) (uint32, error) {
	return _SFFactory.Contract.FormImplementationIds(&_SFFactory.CallOpts, formImplementationAddress)
}

// FormImplementationPaused is a free data retrieval call binding the contract method 0x1bc089ed.
//
// Solidity: function formImplementationPaused(uint32 formImplementationId) view returns(uint8)
func (_SFFactory *SFFactoryCaller) FormImplementationPaused(opts *bind.CallOpts, formImplementationId uint32) (uint8, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "formImplementationPaused", formImplementationId)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// FormImplementationPaused is a free data retrieval call binding the contract method 0x1bc089ed.
//
// Solidity: function formImplementationPaused(uint32 formImplementationId) view returns(uint8)
func (_SFFactory *SFFactorySession) FormImplementationPaused(formImplementationId uint32) (uint8, error) {
	return _SFFactory.Contract.FormImplementationPaused(&_SFFactory.CallOpts, formImplementationId)
}

// FormImplementationPaused is a free data retrieval call binding the contract method 0x1bc089ed.
//
// Solidity: function formImplementationPaused(uint32 formImplementationId) view returns(uint8)
func (_SFFactory *SFFactoryCallerSession) FormImplementationPaused(formImplementationId uint32) (uint8, error) {
	return _SFFactory.Contract.FormImplementationPaused(&_SFFactory.CallOpts, formImplementationId)
}

// FormImplementations is a free data retrieval call binding the contract method 0xdfd6e4ab.
//
// Solidity: function formImplementations(uint256 ) view returns(address)
func (_SFFactory *SFFactoryCaller) FormImplementations(opts *bind.CallOpts, arg0 *big.Int) (common.Address, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "formImplementations", arg0)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// FormImplementations is a free data retrieval call binding the contract method 0xdfd6e4ab.
//
// Solidity: function formImplementations(uint256 ) view returns(address)
func (_SFFactory *SFFactorySession) FormImplementations(arg0 *big.Int) (common.Address, error) {
	return _SFFactory.Contract.FormImplementations(&_SFFactory.CallOpts, arg0)
}

// FormImplementations is a free data retrieval call binding the contract method 0xdfd6e4ab.
//
// Solidity: function formImplementations(uint256 ) view returns(address)
func (_SFFactory *SFFactoryCallerSession) FormImplementations(arg0 *big.Int) (common.Address, error) {
	return _SFFactory.Contract.FormImplementations(&_SFFactory.CallOpts, arg0)
}

// FormStateRegistryId is a free data retrieval call binding the contract method 0x7239fe4f.
//
// Solidity: function formStateRegistryId(uint32 formImplementationId) view returns(uint8 formRegistryId)
func (_SFFactory *SFFactoryCaller) FormStateRegistryId(opts *bind.CallOpts, formImplementationId uint32) (uint8, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "formStateRegistryId", formImplementationId)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// FormStateRegistryId is a free data retrieval call binding the contract method 0x7239fe4f.
//
// Solidity: function formStateRegistryId(uint32 formImplementationId) view returns(uint8 formRegistryId)
func (_SFFactory *SFFactorySession) FormStateRegistryId(formImplementationId uint32) (uint8, error) {
	return _SFFactory.Contract.FormStateRegistryId(&_SFFactory.CallOpts, formImplementationId)
}

// FormStateRegistryId is a free data retrieval call binding the contract method 0x7239fe4f.
//
// Solidity: function formStateRegistryId(uint32 formImplementationId) view returns(uint8 formRegistryId)
func (_SFFactory *SFFactoryCallerSession) FormStateRegistryId(formImplementationId uint32) (uint8, error) {
	return _SFFactory.Contract.FormStateRegistryId(&_SFFactory.CallOpts, formImplementationId)
}

// GetAllSuperformsFromVault is a free data retrieval call binding the contract method 0x2085caec.
//
// Solidity: function getAllSuperformsFromVault(address vault_) view returns(uint256[] superformIds_, address[] superforms_)
func (_SFFactory *SFFactoryCaller) GetAllSuperformsFromVault(opts *bind.CallOpts, vault_ common.Address) (struct {
	SuperformIds []*big.Int
	Superforms   []common.Address
}, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "getAllSuperformsFromVault", vault_)

	outstruct := new(struct {
		SuperformIds []*big.Int
		Superforms   []common.Address
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.SuperformIds = *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)
	outstruct.Superforms = *abi.ConvertType(out[1], new([]common.Address)).(*[]common.Address)

	return *outstruct, err

}

// GetAllSuperformsFromVault is a free data retrieval call binding the contract method 0x2085caec.
//
// Solidity: function getAllSuperformsFromVault(address vault_) view returns(uint256[] superformIds_, address[] superforms_)
func (_SFFactory *SFFactorySession) GetAllSuperformsFromVault(vault_ common.Address) (struct {
	SuperformIds []*big.Int
	Superforms   []common.Address
}, error) {
	return _SFFactory.Contract.GetAllSuperformsFromVault(&_SFFactory.CallOpts, vault_)
}

// GetAllSuperformsFromVault is a free data retrieval call binding the contract method 0x2085caec.
//
// Solidity: function getAllSuperformsFromVault(address vault_) view returns(uint256[] superformIds_, address[] superforms_)
func (_SFFactory *SFFactoryCallerSession) GetAllSuperformsFromVault(vault_ common.Address) (struct {
	SuperformIds []*big.Int
	Superforms   []common.Address
}, error) {
	return _SFFactory.Contract.GetAllSuperformsFromVault(&_SFFactory.CallOpts, vault_)
}

// GetFormCount is a free data retrieval call binding the contract method 0x589434ca.
//
// Solidity: function getFormCount() view returns(uint256 forms_)
func (_SFFactory *SFFactoryCaller) GetFormCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "getFormCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetFormCount is a free data retrieval call binding the contract method 0x589434ca.
//
// Solidity: function getFormCount() view returns(uint256 forms_)
func (_SFFactory *SFFactorySession) GetFormCount() (*big.Int, error) {
	return _SFFactory.Contract.GetFormCount(&_SFFactory.CallOpts)
}

// GetFormCount is a free data retrieval call binding the contract method 0x589434ca.
//
// Solidity: function getFormCount() view returns(uint256 forms_)
func (_SFFactory *SFFactoryCallerSession) GetFormCount() (*big.Int, error) {
	return _SFFactory.Contract.GetFormCount(&_SFFactory.CallOpts)
}

// GetFormImplementation is a free data retrieval call binding the contract method 0xbb3808cc.
//
// Solidity: function getFormImplementation(uint32 formImplementationId_) view returns(address)
func (_SFFactory *SFFactoryCaller) GetFormImplementation(opts *bind.CallOpts, formImplementationId_ uint32) (common.Address, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "getFormImplementation", formImplementationId_)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetFormImplementation is a free data retrieval call binding the contract method 0xbb3808cc.
//
// Solidity: function getFormImplementation(uint32 formImplementationId_) view returns(address)
func (_SFFactory *SFFactorySession) GetFormImplementation(formImplementationId_ uint32) (common.Address, error) {
	return _SFFactory.Contract.GetFormImplementation(&_SFFactory.CallOpts, formImplementationId_)
}

// GetFormImplementation is a free data retrieval call binding the contract method 0xbb3808cc.
//
// Solidity: function getFormImplementation(uint32 formImplementationId_) view returns(address)
func (_SFFactory *SFFactoryCallerSession) GetFormImplementation(formImplementationId_ uint32) (common.Address, error) {
	return _SFFactory.Contract.GetFormImplementation(&_SFFactory.CallOpts, formImplementationId_)
}

// GetFormStateRegistryId is a free data retrieval call binding the contract method 0x52fc069e.
//
// Solidity: function getFormStateRegistryId(uint32 formImplementationId_) view returns(uint8 formStateRegistryId_)
func (_SFFactory *SFFactoryCaller) GetFormStateRegistryId(opts *bind.CallOpts, formImplementationId_ uint32) (uint8, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "getFormStateRegistryId", formImplementationId_)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// GetFormStateRegistryId is a free data retrieval call binding the contract method 0x52fc069e.
//
// Solidity: function getFormStateRegistryId(uint32 formImplementationId_) view returns(uint8 formStateRegistryId_)
func (_SFFactory *SFFactorySession) GetFormStateRegistryId(formImplementationId_ uint32) (uint8, error) {
	return _SFFactory.Contract.GetFormStateRegistryId(&_SFFactory.CallOpts, formImplementationId_)
}

// GetFormStateRegistryId is a free data retrieval call binding the contract method 0x52fc069e.
//
// Solidity: function getFormStateRegistryId(uint32 formImplementationId_) view returns(uint8 formStateRegistryId_)
func (_SFFactory *SFFactoryCallerSession) GetFormStateRegistryId(formImplementationId_ uint32) (uint8, error) {
	return _SFFactory.Contract.GetFormStateRegistryId(&_SFFactory.CallOpts, formImplementationId_)
}

// GetSuperform is a free data retrieval call binding the contract method 0x6fb86dd3.
//
// Solidity: function getSuperform(uint256 superformId_) pure returns(address superform_, uint32 formImplementationId_, uint64 chainId_)
func (_SFFactory *SFFactoryCaller) GetSuperform(opts *bind.CallOpts, superformId_ *big.Int) (struct {
	Superform            common.Address
	FormImplementationId uint32
	ChainId              uint64
}, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "getSuperform", superformId_)

	outstruct := new(struct {
		Superform            common.Address
		FormImplementationId uint32
		ChainId              uint64
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Superform = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.FormImplementationId = *abi.ConvertType(out[1], new(uint32)).(*uint32)
	outstruct.ChainId = *abi.ConvertType(out[2], new(uint64)).(*uint64)

	return *outstruct, err

}

// GetSuperform is a free data retrieval call binding the contract method 0x6fb86dd3.
//
// Solidity: function getSuperform(uint256 superformId_) pure returns(address superform_, uint32 formImplementationId_, uint64 chainId_)
func (_SFFactory *SFFactorySession) GetSuperform(superformId_ *big.Int) (struct {
	Superform            common.Address
	FormImplementationId uint32
	ChainId              uint64
}, error) {
	return _SFFactory.Contract.GetSuperform(&_SFFactory.CallOpts, superformId_)
}

// GetSuperform is a free data retrieval call binding the contract method 0x6fb86dd3.
//
// Solidity: function getSuperform(uint256 superformId_) pure returns(address superform_, uint32 formImplementationId_, uint64 chainId_)
func (_SFFactory *SFFactoryCallerSession) GetSuperform(superformId_ *big.Int) (struct {
	Superform            common.Address
	FormImplementationId uint32
	ChainId              uint64
}, error) {
	return _SFFactory.Contract.GetSuperform(&_SFFactory.CallOpts, superformId_)
}

// GetSuperformCount is a free data retrieval call binding the contract method 0x1547665d.
//
// Solidity: function getSuperformCount() view returns(uint256 superforms_)
func (_SFFactory *SFFactoryCaller) GetSuperformCount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "getSuperformCount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetSuperformCount is a free data retrieval call binding the contract method 0x1547665d.
//
// Solidity: function getSuperformCount() view returns(uint256 superforms_)
func (_SFFactory *SFFactorySession) GetSuperformCount() (*big.Int, error) {
	return _SFFactory.Contract.GetSuperformCount(&_SFFactory.CallOpts)
}

// GetSuperformCount is a free data retrieval call binding the contract method 0x1547665d.
//
// Solidity: function getSuperformCount() view returns(uint256 superforms_)
func (_SFFactory *SFFactoryCallerSession) GetSuperformCount() (*big.Int, error) {
	return _SFFactory.Contract.GetSuperformCount(&_SFFactory.CallOpts)
}

// IsFormImplementationPaused is a free data retrieval call binding the contract method 0x596db717.
//
// Solidity: function isFormImplementationPaused(uint32 formImplementationId_) view returns(bool)
func (_SFFactory *SFFactoryCaller) IsFormImplementationPaused(opts *bind.CallOpts, formImplementationId_ uint32) (bool, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "isFormImplementationPaused", formImplementationId_)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsFormImplementationPaused is a free data retrieval call binding the contract method 0x596db717.
//
// Solidity: function isFormImplementationPaused(uint32 formImplementationId_) view returns(bool)
func (_SFFactory *SFFactorySession) IsFormImplementationPaused(formImplementationId_ uint32) (bool, error) {
	return _SFFactory.Contract.IsFormImplementationPaused(&_SFFactory.CallOpts, formImplementationId_)
}

// IsFormImplementationPaused is a free data retrieval call binding the contract method 0x596db717.
//
// Solidity: function isFormImplementationPaused(uint32 formImplementationId_) view returns(bool)
func (_SFFactory *SFFactoryCallerSession) IsFormImplementationPaused(formImplementationId_ uint32) (bool, error) {
	return _SFFactory.Contract.IsFormImplementationPaused(&_SFFactory.CallOpts, formImplementationId_)
}

// IsSuperform is a free data retrieval call binding the contract method 0xb5c75697.
//
// Solidity: function isSuperform(uint256 superformId) view returns(bool superformIdExists)
func (_SFFactory *SFFactoryCaller) IsSuperform(opts *bind.CallOpts, superformId *big.Int) (bool, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "isSuperform", superformId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsSuperform is a free data retrieval call binding the contract method 0xb5c75697.
//
// Solidity: function isSuperform(uint256 superformId) view returns(bool superformIdExists)
func (_SFFactory *SFFactorySession) IsSuperform(superformId *big.Int) (bool, error) {
	return _SFFactory.Contract.IsSuperform(&_SFFactory.CallOpts, superformId)
}

// IsSuperform is a free data retrieval call binding the contract method 0xb5c75697.
//
// Solidity: function isSuperform(uint256 superformId) view returns(bool superformIdExists)
func (_SFFactory *SFFactoryCallerSession) IsSuperform(superformId *big.Int) (bool, error) {
	return _SFFactory.Contract.IsSuperform(&_SFFactory.CallOpts, superformId)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SFFactory *SFFactoryCaller) SuperRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "superRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SFFactory *SFFactorySession) SuperRegistry() (common.Address, error) {
	return _SFFactory.Contract.SuperRegistry(&_SFFactory.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SFFactory *SFFactoryCallerSession) SuperRegistry() (common.Address, error) {
	return _SFFactory.Contract.SuperRegistry(&_SFFactory.CallOpts)
}

// Superforms is a free data retrieval call binding the contract method 0x479f3b87.
//
// Solidity: function superforms(uint256 ) view returns(uint256)
func (_SFFactory *SFFactoryCaller) Superforms(opts *bind.CallOpts, arg0 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "superforms", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Superforms is a free data retrieval call binding the contract method 0x479f3b87.
//
// Solidity: function superforms(uint256 ) view returns(uint256)
func (_SFFactory *SFFactorySession) Superforms(arg0 *big.Int) (*big.Int, error) {
	return _SFFactory.Contract.Superforms(&_SFFactory.CallOpts, arg0)
}

// Superforms is a free data retrieval call binding the contract method 0x479f3b87.
//
// Solidity: function superforms(uint256 ) view returns(uint256)
func (_SFFactory *SFFactoryCallerSession) Superforms(arg0 *big.Int) (*big.Int, error) {
	return _SFFactory.Contract.Superforms(&_SFFactory.CallOpts, arg0)
}

// VaultFormImplCombinationToSuperforms is a free data retrieval call binding the contract method 0xb85225bb.
//
// Solidity: function vaultFormImplCombinationToSuperforms(bytes32 vaultFormImplementationCombination) view returns(uint256 superformIds)
func (_SFFactory *SFFactoryCaller) VaultFormImplCombinationToSuperforms(opts *bind.CallOpts, vaultFormImplementationCombination [32]byte) (*big.Int, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "vaultFormImplCombinationToSuperforms", vaultFormImplementationCombination)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// VaultFormImplCombinationToSuperforms is a free data retrieval call binding the contract method 0xb85225bb.
//
// Solidity: function vaultFormImplCombinationToSuperforms(bytes32 vaultFormImplementationCombination) view returns(uint256 superformIds)
func (_SFFactory *SFFactorySession) VaultFormImplCombinationToSuperforms(vaultFormImplementationCombination [32]byte) (*big.Int, error) {
	return _SFFactory.Contract.VaultFormImplCombinationToSuperforms(&_SFFactory.CallOpts, vaultFormImplementationCombination)
}

// VaultFormImplCombinationToSuperforms is a free data retrieval call binding the contract method 0xb85225bb.
//
// Solidity: function vaultFormImplCombinationToSuperforms(bytes32 vaultFormImplementationCombination) view returns(uint256 superformIds)
func (_SFFactory *SFFactoryCallerSession) VaultFormImplCombinationToSuperforms(vaultFormImplementationCombination [32]byte) (*big.Int, error) {
	return _SFFactory.Contract.VaultFormImplCombinationToSuperforms(&_SFFactory.CallOpts, vaultFormImplementationCombination)
}

// VaultToFormImplementationId is a free data retrieval call binding the contract method 0x9e066838.
//
// Solidity: function vaultToFormImplementationId(address vault, uint256 ) view returns(uint256 formImplementationId)
func (_SFFactory *SFFactoryCaller) VaultToFormImplementationId(opts *bind.CallOpts, vault common.Address, arg1 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "vaultToFormImplementationId", vault, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// VaultToFormImplementationId is a free data retrieval call binding the contract method 0x9e066838.
//
// Solidity: function vaultToFormImplementationId(address vault, uint256 ) view returns(uint256 formImplementationId)
func (_SFFactory *SFFactorySession) VaultToFormImplementationId(vault common.Address, arg1 *big.Int) (*big.Int, error) {
	return _SFFactory.Contract.VaultToFormImplementationId(&_SFFactory.CallOpts, vault, arg1)
}

// VaultToFormImplementationId is a free data retrieval call binding the contract method 0x9e066838.
//
// Solidity: function vaultToFormImplementationId(address vault, uint256 ) view returns(uint256 formImplementationId)
func (_SFFactory *SFFactoryCallerSession) VaultToFormImplementationId(vault common.Address, arg1 *big.Int) (*big.Int, error) {
	return _SFFactory.Contract.VaultToFormImplementationId(&_SFFactory.CallOpts, vault, arg1)
}

// VaultToSuperforms is a free data retrieval call binding the contract method 0x8de833a9.
//
// Solidity: function vaultToSuperforms(address vault, uint256 ) view returns(uint256 superformIds)
func (_SFFactory *SFFactoryCaller) VaultToSuperforms(opts *bind.CallOpts, vault common.Address, arg1 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "vaultToSuperforms", vault, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// VaultToSuperforms is a free data retrieval call binding the contract method 0x8de833a9.
//
// Solidity: function vaultToSuperforms(address vault, uint256 ) view returns(uint256 superformIds)
func (_SFFactory *SFFactorySession) VaultToSuperforms(vault common.Address, arg1 *big.Int) (*big.Int, error) {
	return _SFFactory.Contract.VaultToSuperforms(&_SFFactory.CallOpts, vault, arg1)
}

// VaultToSuperforms is a free data retrieval call binding the contract method 0x8de833a9.
//
// Solidity: function vaultToSuperforms(address vault, uint256 ) view returns(uint256 superformIds)
func (_SFFactory *SFFactoryCallerSession) VaultToSuperforms(vault common.Address, arg1 *big.Int) (*big.Int, error) {
	return _SFFactory.Contract.VaultToSuperforms(&_SFFactory.CallOpts, vault, arg1)
}

// XChainPayloadCounter is a free data retrieval call binding the contract method 0xedf387c5.
//
// Solidity: function xChainPayloadCounter() view returns(uint256)
func (_SFFactory *SFFactoryCaller) XChainPayloadCounter(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SFFactory.contract.Call(opts, &out, "xChainPayloadCounter")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// XChainPayloadCounter is a free data retrieval call binding the contract method 0xedf387c5.
//
// Solidity: function xChainPayloadCounter() view returns(uint256)
func (_SFFactory *SFFactorySession) XChainPayloadCounter() (*big.Int, error) {
	return _SFFactory.Contract.XChainPayloadCounter(&_SFFactory.CallOpts)
}

// XChainPayloadCounter is a free data retrieval call binding the contract method 0xedf387c5.
//
// Solidity: function xChainPayloadCounter() view returns(uint256)
func (_SFFactory *SFFactoryCallerSession) XChainPayloadCounter() (*big.Int, error) {
	return _SFFactory.Contract.XChainPayloadCounter(&_SFFactory.CallOpts)
}

// AddFormImplementation is a paid mutator transaction binding the contract method 0x3d2378f4.
//
// Solidity: function addFormImplementation(address formImplementation_, uint32 formImplementationId_, uint8 formStateRegistryId_) returns()
func (_SFFactory *SFFactoryTransactor) AddFormImplementation(opts *bind.TransactOpts, formImplementation_ common.Address, formImplementationId_ uint32, formStateRegistryId_ uint8) (*types.Transaction, error) {
	return _SFFactory.contract.Transact(opts, "addFormImplementation", formImplementation_, formImplementationId_, formStateRegistryId_)
}

// AddFormImplementation is a paid mutator transaction binding the contract method 0x3d2378f4.
//
// Solidity: function addFormImplementation(address formImplementation_, uint32 formImplementationId_, uint8 formStateRegistryId_) returns()
func (_SFFactory *SFFactorySession) AddFormImplementation(formImplementation_ common.Address, formImplementationId_ uint32, formStateRegistryId_ uint8) (*types.Transaction, error) {
	return _SFFactory.Contract.AddFormImplementation(&_SFFactory.TransactOpts, formImplementation_, formImplementationId_, formStateRegistryId_)
}

// AddFormImplementation is a paid mutator transaction binding the contract method 0x3d2378f4.
//
// Solidity: function addFormImplementation(address formImplementation_, uint32 formImplementationId_, uint8 formStateRegistryId_) returns()
func (_SFFactory *SFFactoryTransactorSession) AddFormImplementation(formImplementation_ common.Address, formImplementationId_ uint32, formStateRegistryId_ uint8) (*types.Transaction, error) {
	return _SFFactory.Contract.AddFormImplementation(&_SFFactory.TransactOpts, formImplementation_, formImplementationId_, formStateRegistryId_)
}

// ChangeFormImplementationPauseStatus is a paid mutator transaction binding the contract method 0x2d75c56a.
//
// Solidity: function changeFormImplementationPauseStatus(uint32 formImplementationId_, uint8 status_, bytes extraData_) payable returns()
func (_SFFactory *SFFactoryTransactor) ChangeFormImplementationPauseStatus(opts *bind.TransactOpts, formImplementationId_ uint32, status_ uint8, extraData_ []byte) (*types.Transaction, error) {
	return _SFFactory.contract.Transact(opts, "changeFormImplementationPauseStatus", formImplementationId_, status_, extraData_)
}

// ChangeFormImplementationPauseStatus is a paid mutator transaction binding the contract method 0x2d75c56a.
//
// Solidity: function changeFormImplementationPauseStatus(uint32 formImplementationId_, uint8 status_, bytes extraData_) payable returns()
func (_SFFactory *SFFactorySession) ChangeFormImplementationPauseStatus(formImplementationId_ uint32, status_ uint8, extraData_ []byte) (*types.Transaction, error) {
	return _SFFactory.Contract.ChangeFormImplementationPauseStatus(&_SFFactory.TransactOpts, formImplementationId_, status_, extraData_)
}

// ChangeFormImplementationPauseStatus is a paid mutator transaction binding the contract method 0x2d75c56a.
//
// Solidity: function changeFormImplementationPauseStatus(uint32 formImplementationId_, uint8 status_, bytes extraData_) payable returns()
func (_SFFactory *SFFactoryTransactorSession) ChangeFormImplementationPauseStatus(formImplementationId_ uint32, status_ uint8, extraData_ []byte) (*types.Transaction, error) {
	return _SFFactory.Contract.ChangeFormImplementationPauseStatus(&_SFFactory.TransactOpts, formImplementationId_, status_, extraData_)
}

// CreateSuperform is a paid mutator transaction binding the contract method 0xc4d6e6b2.
//
// Solidity: function createSuperform(uint32 formImplementationId_, address vault_) returns(uint256 superformId_, address superform_)
func (_SFFactory *SFFactoryTransactor) CreateSuperform(opts *bind.TransactOpts, formImplementationId_ uint32, vault_ common.Address) (*types.Transaction, error) {
	return _SFFactory.contract.Transact(opts, "createSuperform", formImplementationId_, vault_)
}

// CreateSuperform is a paid mutator transaction binding the contract method 0xc4d6e6b2.
//
// Solidity: function createSuperform(uint32 formImplementationId_, address vault_) returns(uint256 superformId_, address superform_)
func (_SFFactory *SFFactorySession) CreateSuperform(formImplementationId_ uint32, vault_ common.Address) (*types.Transaction, error) {
	return _SFFactory.Contract.CreateSuperform(&_SFFactory.TransactOpts, formImplementationId_, vault_)
}

// CreateSuperform is a paid mutator transaction binding the contract method 0xc4d6e6b2.
//
// Solidity: function createSuperform(uint32 formImplementationId_, address vault_) returns(uint256 superformId_, address superform_)
func (_SFFactory *SFFactoryTransactorSession) CreateSuperform(formImplementationId_ uint32, vault_ common.Address) (*types.Transaction, error) {
	return _SFFactory.Contract.CreateSuperform(&_SFFactory.TransactOpts, formImplementationId_, vault_)
}

// StateSyncBroadcast is a paid mutator transaction binding the contract method 0xe6ddad4c.
//
// Solidity: function stateSyncBroadcast(bytes data_) payable returns()
func (_SFFactory *SFFactoryTransactor) StateSyncBroadcast(opts *bind.TransactOpts, data_ []byte) (*types.Transaction, error) {
	return _SFFactory.contract.Transact(opts, "stateSyncBroadcast", data_)
}

// StateSyncBroadcast is a paid mutator transaction binding the contract method 0xe6ddad4c.
//
// Solidity: function stateSyncBroadcast(bytes data_) payable returns()
func (_SFFactory *SFFactorySession) StateSyncBroadcast(data_ []byte) (*types.Transaction, error) {
	return _SFFactory.Contract.StateSyncBroadcast(&_SFFactory.TransactOpts, data_)
}

// StateSyncBroadcast is a paid mutator transaction binding the contract method 0xe6ddad4c.
//
// Solidity: function stateSyncBroadcast(bytes data_) payable returns()
func (_SFFactory *SFFactoryTransactorSession) StateSyncBroadcast(data_ []byte) (*types.Transaction, error) {
	return _SFFactory.Contract.StateSyncBroadcast(&_SFFactory.TransactOpts, data_)
}

// SFFactoryFormImplementationAddedIterator is returned from FilterFormImplementationAdded and is used to iterate over the raw logs and unpacked data for FormImplementationAdded events raised by the SFFactory contract.
type SFFactoryFormImplementationAddedIterator struct {
	Event *SFFactoryFormImplementationAdded // Event containing the contract specifics and raw log

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
func (it *SFFactoryFormImplementationAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SFFactoryFormImplementationAdded)
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
		it.Event = new(SFFactoryFormImplementationAdded)
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
func (it *SFFactoryFormImplementationAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SFFactoryFormImplementationAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SFFactoryFormImplementationAdded represents a FormImplementationAdded event raised by the SFFactory contract.
type SFFactoryFormImplementationAdded struct {
	FormImplementation   common.Address
	FormImplementationId *big.Int
	FormStateRegistryId  uint8
	Raw                  types.Log // Blockchain specific contextual infos
}

// FilterFormImplementationAdded is a free log retrieval operation binding the contract event 0x57e36bd8ee2840c13ad182923b129cd3b97186aa7ac714bfa5e59425fc22eeeb.
//
// Solidity: event FormImplementationAdded(address indexed formImplementation, uint256 indexed formImplementationId, uint8 indexed formStateRegistryId)
func (_SFFactory *SFFactoryFilterer) FilterFormImplementationAdded(opts *bind.FilterOpts, formImplementation []common.Address, formImplementationId []*big.Int, formStateRegistryId []uint8) (*SFFactoryFormImplementationAddedIterator, error) {

	var formImplementationRule []interface{}
	for _, formImplementationItem := range formImplementation {
		formImplementationRule = append(formImplementationRule, formImplementationItem)
	}
	var formImplementationIdRule []interface{}
	for _, formImplementationIdItem := range formImplementationId {
		formImplementationIdRule = append(formImplementationIdRule, formImplementationIdItem)
	}
	var formStateRegistryIdRule []interface{}
	for _, formStateRegistryIdItem := range formStateRegistryId {
		formStateRegistryIdRule = append(formStateRegistryIdRule, formStateRegistryIdItem)
	}

	logs, sub, err := _SFFactory.contract.FilterLogs(opts, "FormImplementationAdded", formImplementationRule, formImplementationIdRule, formStateRegistryIdRule)
	if err != nil {
		return nil, err
	}
	return &SFFactoryFormImplementationAddedIterator{contract: _SFFactory.contract, event: "FormImplementationAdded", logs: logs, sub: sub}, nil
}

// WatchFormImplementationAdded is a free log subscription operation binding the contract event 0x57e36bd8ee2840c13ad182923b129cd3b97186aa7ac714bfa5e59425fc22eeeb.
//
// Solidity: event FormImplementationAdded(address indexed formImplementation, uint256 indexed formImplementationId, uint8 indexed formStateRegistryId)
func (_SFFactory *SFFactoryFilterer) WatchFormImplementationAdded(opts *bind.WatchOpts, sink chan<- *SFFactoryFormImplementationAdded, formImplementation []common.Address, formImplementationId []*big.Int, formStateRegistryId []uint8) (event.Subscription, error) {

	var formImplementationRule []interface{}
	for _, formImplementationItem := range formImplementation {
		formImplementationRule = append(formImplementationRule, formImplementationItem)
	}
	var formImplementationIdRule []interface{}
	for _, formImplementationIdItem := range formImplementationId {
		formImplementationIdRule = append(formImplementationIdRule, formImplementationIdItem)
	}
	var formStateRegistryIdRule []interface{}
	for _, formStateRegistryIdItem := range formStateRegistryId {
		formStateRegistryIdRule = append(formStateRegistryIdRule, formStateRegistryIdItem)
	}

	logs, sub, err := _SFFactory.contract.WatchLogs(opts, "FormImplementationAdded", formImplementationRule, formImplementationIdRule, formStateRegistryIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SFFactoryFormImplementationAdded)
				if err := _SFFactory.contract.UnpackLog(event, "FormImplementationAdded", log); err != nil {
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

// ParseFormImplementationAdded is a log parse operation binding the contract event 0x57e36bd8ee2840c13ad182923b129cd3b97186aa7ac714bfa5e59425fc22eeeb.
//
// Solidity: event FormImplementationAdded(address indexed formImplementation, uint256 indexed formImplementationId, uint8 indexed formStateRegistryId)
func (_SFFactory *SFFactoryFilterer) ParseFormImplementationAdded(log types.Log) (*SFFactoryFormImplementationAdded, error) {
	event := new(SFFactoryFormImplementationAdded)
	if err := _SFFactory.contract.UnpackLog(event, "FormImplementationAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SFFactoryFormImplementationPausedIterator is returned from FilterFormImplementationPaused and is used to iterate over the raw logs and unpacked data for FormImplementationPaused events raised by the SFFactory contract.
type SFFactoryFormImplementationPausedIterator struct {
	Event *SFFactoryFormImplementationPaused // Event containing the contract specifics and raw log

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
func (it *SFFactoryFormImplementationPausedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SFFactoryFormImplementationPaused)
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
		it.Event = new(SFFactoryFormImplementationPaused)
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
func (it *SFFactoryFormImplementationPausedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SFFactoryFormImplementationPausedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SFFactoryFormImplementationPaused represents a FormImplementationPaused event raised by the SFFactory contract.
type SFFactoryFormImplementationPaused struct {
	FormImplementationId *big.Int
	Paused               uint8
	Raw                  types.Log // Blockchain specific contextual infos
}

// FilterFormImplementationPaused is a free log retrieval operation binding the contract event 0x1cb88bdf176e51fa7c40e8e4683e78b1792a2ce649cfae1f26fec314eebe536e.
//
// Solidity: event FormImplementationPaused(uint256 indexed formImplementationId, uint8 indexed paused)
func (_SFFactory *SFFactoryFilterer) FilterFormImplementationPaused(opts *bind.FilterOpts, formImplementationId []*big.Int, paused []uint8) (*SFFactoryFormImplementationPausedIterator, error) {

	var formImplementationIdRule []interface{}
	for _, formImplementationIdItem := range formImplementationId {
		formImplementationIdRule = append(formImplementationIdRule, formImplementationIdItem)
	}
	var pausedRule []interface{}
	for _, pausedItem := range paused {
		pausedRule = append(pausedRule, pausedItem)
	}

	logs, sub, err := _SFFactory.contract.FilterLogs(opts, "FormImplementationPaused", formImplementationIdRule, pausedRule)
	if err != nil {
		return nil, err
	}
	return &SFFactoryFormImplementationPausedIterator{contract: _SFFactory.contract, event: "FormImplementationPaused", logs: logs, sub: sub}, nil
}

// WatchFormImplementationPaused is a free log subscription operation binding the contract event 0x1cb88bdf176e51fa7c40e8e4683e78b1792a2ce649cfae1f26fec314eebe536e.
//
// Solidity: event FormImplementationPaused(uint256 indexed formImplementationId, uint8 indexed paused)
func (_SFFactory *SFFactoryFilterer) WatchFormImplementationPaused(opts *bind.WatchOpts, sink chan<- *SFFactoryFormImplementationPaused, formImplementationId []*big.Int, paused []uint8) (event.Subscription, error) {

	var formImplementationIdRule []interface{}
	for _, formImplementationIdItem := range formImplementationId {
		formImplementationIdRule = append(formImplementationIdRule, formImplementationIdItem)
	}
	var pausedRule []interface{}
	for _, pausedItem := range paused {
		pausedRule = append(pausedRule, pausedItem)
	}

	logs, sub, err := _SFFactory.contract.WatchLogs(opts, "FormImplementationPaused", formImplementationIdRule, pausedRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SFFactoryFormImplementationPaused)
				if err := _SFFactory.contract.UnpackLog(event, "FormImplementationPaused", log); err != nil {
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

// ParseFormImplementationPaused is a log parse operation binding the contract event 0x1cb88bdf176e51fa7c40e8e4683e78b1792a2ce649cfae1f26fec314eebe536e.
//
// Solidity: event FormImplementationPaused(uint256 indexed formImplementationId, uint8 indexed paused)
func (_SFFactory *SFFactoryFilterer) ParseFormImplementationPaused(log types.Log) (*SFFactoryFormImplementationPaused, error) {
	event := new(SFFactoryFormImplementationPaused)
	if err := _SFFactory.contract.UnpackLog(event, "FormImplementationPaused", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SFFactorySuperRegistrySetIterator is returned from FilterSuperRegistrySet and is used to iterate over the raw logs and unpacked data for SuperRegistrySet events raised by the SFFactory contract.
type SFFactorySuperRegistrySetIterator struct {
	Event *SFFactorySuperRegistrySet // Event containing the contract specifics and raw log

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
func (it *SFFactorySuperRegistrySetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SFFactorySuperRegistrySet)
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
		it.Event = new(SFFactorySuperRegistrySet)
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
func (it *SFFactorySuperRegistrySetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SFFactorySuperRegistrySetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SFFactorySuperRegistrySet represents a SuperRegistrySet event raised by the SFFactory contract.
type SFFactorySuperRegistrySet struct {
	SuperRegistry common.Address
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterSuperRegistrySet is a free log retrieval operation binding the contract event 0x2eebcbfce9dd6cba1a52c0f9851fa11132c398a5aaaa5c605f536ef4d467b66b.
//
// Solidity: event SuperRegistrySet(address indexed superRegistry)
func (_SFFactory *SFFactoryFilterer) FilterSuperRegistrySet(opts *bind.FilterOpts, superRegistry []common.Address) (*SFFactorySuperRegistrySetIterator, error) {

	var superRegistryRule []interface{}
	for _, superRegistryItem := range superRegistry {
		superRegistryRule = append(superRegistryRule, superRegistryItem)
	}

	logs, sub, err := _SFFactory.contract.FilterLogs(opts, "SuperRegistrySet", superRegistryRule)
	if err != nil {
		return nil, err
	}
	return &SFFactorySuperRegistrySetIterator{contract: _SFFactory.contract, event: "SuperRegistrySet", logs: logs, sub: sub}, nil
}

// WatchSuperRegistrySet is a free log subscription operation binding the contract event 0x2eebcbfce9dd6cba1a52c0f9851fa11132c398a5aaaa5c605f536ef4d467b66b.
//
// Solidity: event SuperRegistrySet(address indexed superRegistry)
func (_SFFactory *SFFactoryFilterer) WatchSuperRegistrySet(opts *bind.WatchOpts, sink chan<- *SFFactorySuperRegistrySet, superRegistry []common.Address) (event.Subscription, error) {

	var superRegistryRule []interface{}
	for _, superRegistryItem := range superRegistry {
		superRegistryRule = append(superRegistryRule, superRegistryItem)
	}

	logs, sub, err := _SFFactory.contract.WatchLogs(opts, "SuperRegistrySet", superRegistryRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SFFactorySuperRegistrySet)
				if err := _SFFactory.contract.UnpackLog(event, "SuperRegistrySet", log); err != nil {
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

// ParseSuperRegistrySet is a log parse operation binding the contract event 0x2eebcbfce9dd6cba1a52c0f9851fa11132c398a5aaaa5c605f536ef4d467b66b.
//
// Solidity: event SuperRegistrySet(address indexed superRegistry)
func (_SFFactory *SFFactoryFilterer) ParseSuperRegistrySet(log types.Log) (*SFFactorySuperRegistrySet, error) {
	event := new(SFFactorySuperRegistrySet)
	if err := _SFFactory.contract.UnpackLog(event, "SuperRegistrySet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SFFactorySuperformCreatedIterator is returned from FilterSuperformCreated and is used to iterate over the raw logs and unpacked data for SuperformCreated events raised by the SFFactory contract.
type SFFactorySuperformCreatedIterator struct {
	Event *SFFactorySuperformCreated // Event containing the contract specifics and raw log

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
func (it *SFFactorySuperformCreatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SFFactorySuperformCreated)
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
		it.Event = new(SFFactorySuperformCreated)
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
func (it *SFFactorySuperformCreatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SFFactorySuperformCreatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SFFactorySuperformCreated represents a SuperformCreated event raised by the SFFactory contract.
type SFFactorySuperformCreated struct {
	FormImplementationId *big.Int
	Vault                common.Address
	SuperformId          *big.Int
	Superform            common.Address
	Raw                  types.Log // Blockchain specific contextual infos
}

// FilterSuperformCreated is a free log retrieval operation binding the contract event 0xf40fe66c44bcbe514dc449b1c700989fe0ace6e4e6c48a118cc9b452c285c72b.
//
// Solidity: event SuperformCreated(uint256 indexed formImplementationId, address indexed vault, uint256 indexed superformId, address superform)
func (_SFFactory *SFFactoryFilterer) FilterSuperformCreated(opts *bind.FilterOpts, formImplementationId []*big.Int, vault []common.Address, superformId []*big.Int) (*SFFactorySuperformCreatedIterator, error) {

	var formImplementationIdRule []interface{}
	for _, formImplementationIdItem := range formImplementationId {
		formImplementationIdRule = append(formImplementationIdRule, formImplementationIdItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}
	var superformIdRule []interface{}
	for _, superformIdItem := range superformId {
		superformIdRule = append(superformIdRule, superformIdItem)
	}

	logs, sub, err := _SFFactory.contract.FilterLogs(opts, "SuperformCreated", formImplementationIdRule, vaultRule, superformIdRule)
	if err != nil {
		return nil, err
	}
	return &SFFactorySuperformCreatedIterator{contract: _SFFactory.contract, event: "SuperformCreated", logs: logs, sub: sub}, nil
}

// WatchSuperformCreated is a free log subscription operation binding the contract event 0xf40fe66c44bcbe514dc449b1c700989fe0ace6e4e6c48a118cc9b452c285c72b.
//
// Solidity: event SuperformCreated(uint256 indexed formImplementationId, address indexed vault, uint256 indexed superformId, address superform)
func (_SFFactory *SFFactoryFilterer) WatchSuperformCreated(opts *bind.WatchOpts, sink chan<- *SFFactorySuperformCreated, formImplementationId []*big.Int, vault []common.Address, superformId []*big.Int) (event.Subscription, error) {

	var formImplementationIdRule []interface{}
	for _, formImplementationIdItem := range formImplementationId {
		formImplementationIdRule = append(formImplementationIdRule, formImplementationIdItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}
	var superformIdRule []interface{}
	for _, superformIdItem := range superformId {
		superformIdRule = append(superformIdRule, superformIdItem)
	}

	logs, sub, err := _SFFactory.contract.WatchLogs(opts, "SuperformCreated", formImplementationIdRule, vaultRule, superformIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SFFactorySuperformCreated)
				if err := _SFFactory.contract.UnpackLog(event, "SuperformCreated", log); err != nil {
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

// ParseSuperformCreated is a log parse operation binding the contract event 0xf40fe66c44bcbe514dc449b1c700989fe0ace6e4e6c48a118cc9b452c285c72b.
//
// Solidity: event SuperformCreated(uint256 indexed formImplementationId, address indexed vault, uint256 indexed superformId, address superform)
func (_SFFactory *SFFactoryFilterer) ParseSuperformCreated(log types.Log) (*SFFactorySuperformCreated, error) {
	event := new(SFFactorySuperformCreated)
	if err := _SFFactory.contract.UnpackLog(event, "SuperformCreated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
