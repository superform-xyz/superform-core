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

// LiqRequest is an auto generated low-level Go binding around an user-defined struct.
type LiqRequest struct {
	TxData        []byte
	Token         common.Address
	InterimToken  common.Address
	BridgeId      uint8
	LiqDstChainId uint64
	NativeAmount  *big.Int
}

// PayMasterMetaData contains all meta data concerning the PayMaster contract.
var PayMasterMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superRegistry_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"receive\",\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"makePayment\",\"inputs\":[{\"name\":\"user_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"rebalanceTo\",\"inputs\":[{\"name\":\"superRegistryId_\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"dstChainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"superRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperRegistry\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalFeesPaid\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"treatAMB\",\"inputs\":[{\"name\":\"ambId_\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"nativeValue_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data_\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"withdrawNativeTo\",\"inputs\":[{\"name\":\"superRegistryId_\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"nativeAmount_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"withdrawTo\",\"inputs\":[{\"name\":\"superRegistryId_\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"token_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"NativeWithdrawn\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Payment\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TokenWithdrawn\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"token\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AddressEmptyCode\",\"inputs\":[{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"AddressInsufficientBalance\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"FAILED_TO_EXECUTE_TXDATA\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"FAILED_TO_SEND_NATIVE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedInnerCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_BALANCE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_NATIVE_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_TXDATA_RECEIVER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_PAYMENT_ADMIN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_INPUT_VALUE\",\"inputs\":[]}]",
}

// PayMasterABI is the input ABI used to generate the binding from.
// Deprecated: Use PayMasterMetaData.ABI instead.
var PayMasterABI = PayMasterMetaData.ABI

// PayMaster is an auto generated Go binding around an Ethereum contract.
type PayMaster struct {
	PayMasterCaller     // Read-only binding to the contract
	PayMasterTransactor // Write-only binding to the contract
	PayMasterFilterer   // Log filterer for contract events
}

// PayMasterCaller is an auto generated read-only Go binding around an Ethereum contract.
type PayMasterCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PayMasterTransactor is an auto generated write-only Go binding around an Ethereum contract.
type PayMasterTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PayMasterFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type PayMasterFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// PayMasterSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type PayMasterSession struct {
	Contract     *PayMaster        // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// PayMasterCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type PayMasterCallerSession struct {
	Contract *PayMasterCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts    // Call options to use throughout this session
}

// PayMasterTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type PayMasterTransactorSession struct {
	Contract     *PayMasterTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts    // Transaction auth options to use throughout this session
}

// PayMasterRaw is an auto generated low-level Go binding around an Ethereum contract.
type PayMasterRaw struct {
	Contract *PayMaster // Generic contract binding to access the raw methods on
}

// PayMasterCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type PayMasterCallerRaw struct {
	Contract *PayMasterCaller // Generic read-only contract binding to access the raw methods on
}

// PayMasterTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type PayMasterTransactorRaw struct {
	Contract *PayMasterTransactor // Generic write-only contract binding to access the raw methods on
}

// NewPayMaster creates a new instance of PayMaster, bound to a specific deployed contract.
func NewPayMaster(address common.Address, backend bind.ContractBackend) (*PayMaster, error) {
	contract, err := bindPayMaster(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &PayMaster{PayMasterCaller: PayMasterCaller{contract: contract}, PayMasterTransactor: PayMasterTransactor{contract: contract}, PayMasterFilterer: PayMasterFilterer{contract: contract}}, nil
}

// NewPayMasterCaller creates a new read-only instance of PayMaster, bound to a specific deployed contract.
func NewPayMasterCaller(address common.Address, caller bind.ContractCaller) (*PayMasterCaller, error) {
	contract, err := bindPayMaster(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &PayMasterCaller{contract: contract}, nil
}

// NewPayMasterTransactor creates a new write-only instance of PayMaster, bound to a specific deployed contract.
func NewPayMasterTransactor(address common.Address, transactor bind.ContractTransactor) (*PayMasterTransactor, error) {
	contract, err := bindPayMaster(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &PayMasterTransactor{contract: contract}, nil
}

// NewPayMasterFilterer creates a new log filterer instance of PayMaster, bound to a specific deployed contract.
func NewPayMasterFilterer(address common.Address, filterer bind.ContractFilterer) (*PayMasterFilterer, error) {
	contract, err := bindPayMaster(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &PayMasterFilterer{contract: contract}, nil
}

// bindPayMaster binds a generic wrapper to an already deployed contract.
func bindPayMaster(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := PayMasterMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_PayMaster *PayMasterRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _PayMaster.Contract.PayMasterCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_PayMaster *PayMasterRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _PayMaster.Contract.PayMasterTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_PayMaster *PayMasterRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _PayMaster.Contract.PayMasterTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_PayMaster *PayMasterCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _PayMaster.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_PayMaster *PayMasterTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _PayMaster.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_PayMaster *PayMasterTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _PayMaster.Contract.contract.Transact(opts, method, params...)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_PayMaster *PayMasterCaller) SuperRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _PayMaster.contract.Call(opts, &out, "superRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_PayMaster *PayMasterSession) SuperRegistry() (common.Address, error) {
	return _PayMaster.Contract.SuperRegistry(&_PayMaster.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_PayMaster *PayMasterCallerSession) SuperRegistry() (common.Address, error) {
	return _PayMaster.Contract.SuperRegistry(&_PayMaster.CallOpts)
}

// TotalFeesPaid is a free data retrieval call binding the contract method 0xf8a5764e.
//
// Solidity: function totalFeesPaid(address ) view returns(uint256)
func (_PayMaster *PayMasterCaller) TotalFeesPaid(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _PayMaster.contract.Call(opts, &out, "totalFeesPaid", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalFeesPaid is a free data retrieval call binding the contract method 0xf8a5764e.
//
// Solidity: function totalFeesPaid(address ) view returns(uint256)
func (_PayMaster *PayMasterSession) TotalFeesPaid(arg0 common.Address) (*big.Int, error) {
	return _PayMaster.Contract.TotalFeesPaid(&_PayMaster.CallOpts, arg0)
}

// TotalFeesPaid is a free data retrieval call binding the contract method 0xf8a5764e.
//
// Solidity: function totalFeesPaid(address ) view returns(uint256)
func (_PayMaster *PayMasterCallerSession) TotalFeesPaid(arg0 common.Address) (*big.Int, error) {
	return _PayMaster.Contract.TotalFeesPaid(&_PayMaster.CallOpts, arg0)
}

// MakePayment is a paid mutator transaction binding the contract method 0x300be4fc.
//
// Solidity: function makePayment(address user_) payable returns()
func (_PayMaster *PayMasterTransactor) MakePayment(opts *bind.TransactOpts, user_ common.Address) (*types.Transaction, error) {
	return _PayMaster.contract.Transact(opts, "makePayment", user_)
}

// MakePayment is a paid mutator transaction binding the contract method 0x300be4fc.
//
// Solidity: function makePayment(address user_) payable returns()
func (_PayMaster *PayMasterSession) MakePayment(user_ common.Address) (*types.Transaction, error) {
	return _PayMaster.Contract.MakePayment(&_PayMaster.TransactOpts, user_)
}

// MakePayment is a paid mutator transaction binding the contract method 0x300be4fc.
//
// Solidity: function makePayment(address user_) payable returns()
func (_PayMaster *PayMasterTransactorSession) MakePayment(user_ common.Address) (*types.Transaction, error) {
	return _PayMaster.Contract.MakePayment(&_PayMaster.TransactOpts, user_)
}

// RebalanceTo is a paid mutator transaction binding the contract method 0xf6c65084.
//
// Solidity: function rebalanceTo(bytes32 superRegistryId_, (bytes,address,address,uint8,uint64,uint256) req_, uint64 dstChainId_) returns()
func (_PayMaster *PayMasterTransactor) RebalanceTo(opts *bind.TransactOpts, superRegistryId_ [32]byte, req_ LiqRequest, dstChainId_ uint64) (*types.Transaction, error) {
	return _PayMaster.contract.Transact(opts, "rebalanceTo", superRegistryId_, req_, dstChainId_)
}

// RebalanceTo is a paid mutator transaction binding the contract method 0xf6c65084.
//
// Solidity: function rebalanceTo(bytes32 superRegistryId_, (bytes,address,address,uint8,uint64,uint256) req_, uint64 dstChainId_) returns()
func (_PayMaster *PayMasterSession) RebalanceTo(superRegistryId_ [32]byte, req_ LiqRequest, dstChainId_ uint64) (*types.Transaction, error) {
	return _PayMaster.Contract.RebalanceTo(&_PayMaster.TransactOpts, superRegistryId_, req_, dstChainId_)
}

// RebalanceTo is a paid mutator transaction binding the contract method 0xf6c65084.
//
// Solidity: function rebalanceTo(bytes32 superRegistryId_, (bytes,address,address,uint8,uint64,uint256) req_, uint64 dstChainId_) returns()
func (_PayMaster *PayMasterTransactorSession) RebalanceTo(superRegistryId_ [32]byte, req_ LiqRequest, dstChainId_ uint64) (*types.Transaction, error) {
	return _PayMaster.Contract.RebalanceTo(&_PayMaster.TransactOpts, superRegistryId_, req_, dstChainId_)
}

// TreatAMB is a paid mutator transaction binding the contract method 0xcfeba9aa.
//
// Solidity: function treatAMB(uint8 ambId_, uint256 nativeValue_, bytes data_) returns()
func (_PayMaster *PayMasterTransactor) TreatAMB(opts *bind.TransactOpts, ambId_ uint8, nativeValue_ *big.Int, data_ []byte) (*types.Transaction, error) {
	return _PayMaster.contract.Transact(opts, "treatAMB", ambId_, nativeValue_, data_)
}

// TreatAMB is a paid mutator transaction binding the contract method 0xcfeba9aa.
//
// Solidity: function treatAMB(uint8 ambId_, uint256 nativeValue_, bytes data_) returns()
func (_PayMaster *PayMasterSession) TreatAMB(ambId_ uint8, nativeValue_ *big.Int, data_ []byte) (*types.Transaction, error) {
	return _PayMaster.Contract.TreatAMB(&_PayMaster.TransactOpts, ambId_, nativeValue_, data_)
}

// TreatAMB is a paid mutator transaction binding the contract method 0xcfeba9aa.
//
// Solidity: function treatAMB(uint8 ambId_, uint256 nativeValue_, bytes data_) returns()
func (_PayMaster *PayMasterTransactorSession) TreatAMB(ambId_ uint8, nativeValue_ *big.Int, data_ []byte) (*types.Transaction, error) {
	return _PayMaster.Contract.TreatAMB(&_PayMaster.TransactOpts, ambId_, nativeValue_, data_)
}

// WithdrawNativeTo is a paid mutator transaction binding the contract method 0xa1090c1e.
//
// Solidity: function withdrawNativeTo(bytes32 superRegistryId_, uint256 nativeAmount_) returns()
func (_PayMaster *PayMasterTransactor) WithdrawNativeTo(opts *bind.TransactOpts, superRegistryId_ [32]byte, nativeAmount_ *big.Int) (*types.Transaction, error) {
	return _PayMaster.contract.Transact(opts, "withdrawNativeTo", superRegistryId_, nativeAmount_)
}

// WithdrawNativeTo is a paid mutator transaction binding the contract method 0xa1090c1e.
//
// Solidity: function withdrawNativeTo(bytes32 superRegistryId_, uint256 nativeAmount_) returns()
func (_PayMaster *PayMasterSession) WithdrawNativeTo(superRegistryId_ [32]byte, nativeAmount_ *big.Int) (*types.Transaction, error) {
	return _PayMaster.Contract.WithdrawNativeTo(&_PayMaster.TransactOpts, superRegistryId_, nativeAmount_)
}

// WithdrawNativeTo is a paid mutator transaction binding the contract method 0xa1090c1e.
//
// Solidity: function withdrawNativeTo(bytes32 superRegistryId_, uint256 nativeAmount_) returns()
func (_PayMaster *PayMasterTransactorSession) WithdrawNativeTo(superRegistryId_ [32]byte, nativeAmount_ *big.Int) (*types.Transaction, error) {
	return _PayMaster.Contract.WithdrawNativeTo(&_PayMaster.TransactOpts, superRegistryId_, nativeAmount_)
}

// WithdrawTo is a paid mutator transaction binding the contract method 0x205ab6ac.
//
// Solidity: function withdrawTo(bytes32 superRegistryId_, address token_, uint256 amount_) returns()
func (_PayMaster *PayMasterTransactor) WithdrawTo(opts *bind.TransactOpts, superRegistryId_ [32]byte, token_ common.Address, amount_ *big.Int) (*types.Transaction, error) {
	return _PayMaster.contract.Transact(opts, "withdrawTo", superRegistryId_, token_, amount_)
}

// WithdrawTo is a paid mutator transaction binding the contract method 0x205ab6ac.
//
// Solidity: function withdrawTo(bytes32 superRegistryId_, address token_, uint256 amount_) returns()
func (_PayMaster *PayMasterSession) WithdrawTo(superRegistryId_ [32]byte, token_ common.Address, amount_ *big.Int) (*types.Transaction, error) {
	return _PayMaster.Contract.WithdrawTo(&_PayMaster.TransactOpts, superRegistryId_, token_, amount_)
}

// WithdrawTo is a paid mutator transaction binding the contract method 0x205ab6ac.
//
// Solidity: function withdrawTo(bytes32 superRegistryId_, address token_, uint256 amount_) returns()
func (_PayMaster *PayMasterTransactorSession) WithdrawTo(superRegistryId_ [32]byte, token_ common.Address, amount_ *big.Int) (*types.Transaction, error) {
	return _PayMaster.Contract.WithdrawTo(&_PayMaster.TransactOpts, superRegistryId_, token_, amount_)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_PayMaster *PayMasterTransactor) Receive(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _PayMaster.contract.RawTransact(opts, nil) // calldata is disallowed for receive function
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_PayMaster *PayMasterSession) Receive() (*types.Transaction, error) {
	return _PayMaster.Contract.Receive(&_PayMaster.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_PayMaster *PayMasterTransactorSession) Receive() (*types.Transaction, error) {
	return _PayMaster.Contract.Receive(&_PayMaster.TransactOpts)
}

// PayMasterNativeWithdrawnIterator is returned from FilterNativeWithdrawn and is used to iterate over the raw logs and unpacked data for NativeWithdrawn events raised by the PayMaster contract.
type PayMasterNativeWithdrawnIterator struct {
	Event *PayMasterNativeWithdrawn // Event containing the contract specifics and raw log

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
func (it *PayMasterNativeWithdrawnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PayMasterNativeWithdrawn)
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
		it.Event = new(PayMasterNativeWithdrawn)
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
func (it *PayMasterNativeWithdrawnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PayMasterNativeWithdrawnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PayMasterNativeWithdrawn represents a NativeWithdrawn event raised by the PayMaster contract.
type PayMasterNativeWithdrawn struct {
	Receiver common.Address
	Amount   *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterNativeWithdrawn is a free log retrieval operation binding the contract event 0xc303ca808382409472acbbf899c316cf439f409f6584aae22df86dfa3c9ed504.
//
// Solidity: event NativeWithdrawn(address indexed receiver, uint256 indexed amount)
func (_PayMaster *PayMasterFilterer) FilterNativeWithdrawn(opts *bind.FilterOpts, receiver []common.Address, amount []*big.Int) (*PayMasterNativeWithdrawnIterator, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _PayMaster.contract.FilterLogs(opts, "NativeWithdrawn", receiverRule, amountRule)
	if err != nil {
		return nil, err
	}
	return &PayMasterNativeWithdrawnIterator{contract: _PayMaster.contract, event: "NativeWithdrawn", logs: logs, sub: sub}, nil
}

// WatchNativeWithdrawn is a free log subscription operation binding the contract event 0xc303ca808382409472acbbf899c316cf439f409f6584aae22df86dfa3c9ed504.
//
// Solidity: event NativeWithdrawn(address indexed receiver, uint256 indexed amount)
func (_PayMaster *PayMasterFilterer) WatchNativeWithdrawn(opts *bind.WatchOpts, sink chan<- *PayMasterNativeWithdrawn, receiver []common.Address, amount []*big.Int) (event.Subscription, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _PayMaster.contract.WatchLogs(opts, "NativeWithdrawn", receiverRule, amountRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PayMasterNativeWithdrawn)
				if err := _PayMaster.contract.UnpackLog(event, "NativeWithdrawn", log); err != nil {
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

// ParseNativeWithdrawn is a log parse operation binding the contract event 0xc303ca808382409472acbbf899c316cf439f409f6584aae22df86dfa3c9ed504.
//
// Solidity: event NativeWithdrawn(address indexed receiver, uint256 indexed amount)
func (_PayMaster *PayMasterFilterer) ParseNativeWithdrawn(log types.Log) (*PayMasterNativeWithdrawn, error) {
	event := new(PayMasterNativeWithdrawn)
	if err := _PayMaster.contract.UnpackLog(event, "NativeWithdrawn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PayMasterPaymentIterator is returned from FilterPayment and is used to iterate over the raw logs and unpacked data for Payment events raised by the PayMaster contract.
type PayMasterPaymentIterator struct {
	Event *PayMasterPayment // Event containing the contract specifics and raw log

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
func (it *PayMasterPaymentIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PayMasterPayment)
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
		it.Event = new(PayMasterPayment)
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
func (it *PayMasterPaymentIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PayMasterPaymentIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PayMasterPayment represents a Payment event raised by the PayMaster contract.
type PayMasterPayment struct {
	User   common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterPayment is a free log retrieval operation binding the contract event 0xd4f43975feb89f48dd30cabbb32011045be187d1e11c8ea9faa43efc35282519.
//
// Solidity: event Payment(address indexed user, uint256 indexed amount)
func (_PayMaster *PayMasterFilterer) FilterPayment(opts *bind.FilterOpts, user []common.Address, amount []*big.Int) (*PayMasterPaymentIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _PayMaster.contract.FilterLogs(opts, "Payment", userRule, amountRule)
	if err != nil {
		return nil, err
	}
	return &PayMasterPaymentIterator{contract: _PayMaster.contract, event: "Payment", logs: logs, sub: sub}, nil
}

// WatchPayment is a free log subscription operation binding the contract event 0xd4f43975feb89f48dd30cabbb32011045be187d1e11c8ea9faa43efc35282519.
//
// Solidity: event Payment(address indexed user, uint256 indexed amount)
func (_PayMaster *PayMasterFilterer) WatchPayment(opts *bind.WatchOpts, sink chan<- *PayMasterPayment, user []common.Address, amount []*big.Int) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _PayMaster.contract.WatchLogs(opts, "Payment", userRule, amountRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PayMasterPayment)
				if err := _PayMaster.contract.UnpackLog(event, "Payment", log); err != nil {
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

// ParsePayment is a log parse operation binding the contract event 0xd4f43975feb89f48dd30cabbb32011045be187d1e11c8ea9faa43efc35282519.
//
// Solidity: event Payment(address indexed user, uint256 indexed amount)
func (_PayMaster *PayMasterFilterer) ParsePayment(log types.Log) (*PayMasterPayment, error) {
	event := new(PayMasterPayment)
	if err := _PayMaster.contract.UnpackLog(event, "Payment", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// PayMasterTokenWithdrawnIterator is returned from FilterTokenWithdrawn and is used to iterate over the raw logs and unpacked data for TokenWithdrawn events raised by the PayMaster contract.
type PayMasterTokenWithdrawnIterator struct {
	Event *PayMasterTokenWithdrawn // Event containing the contract specifics and raw log

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
func (it *PayMasterTokenWithdrawnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(PayMasterTokenWithdrawn)
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
		it.Event = new(PayMasterTokenWithdrawn)
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
func (it *PayMasterTokenWithdrawnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *PayMasterTokenWithdrawnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// PayMasterTokenWithdrawn represents a TokenWithdrawn event raised by the PayMaster contract.
type PayMasterTokenWithdrawn struct {
	Receiver common.Address
	Token    common.Address
	Amount   *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterTokenWithdrawn is a free log retrieval operation binding the contract event 0x8210728e7c071f615b840ee026032693858fbcd5e5359e67e438c890f59e5620.
//
// Solidity: event TokenWithdrawn(address indexed receiver, address indexed token, uint256 indexed amount)
func (_PayMaster *PayMasterFilterer) FilterTokenWithdrawn(opts *bind.FilterOpts, receiver []common.Address, token []common.Address, amount []*big.Int) (*PayMasterTokenWithdrawnIterator, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _PayMaster.contract.FilterLogs(opts, "TokenWithdrawn", receiverRule, tokenRule, amountRule)
	if err != nil {
		return nil, err
	}
	return &PayMasterTokenWithdrawnIterator{contract: _PayMaster.contract, event: "TokenWithdrawn", logs: logs, sub: sub}, nil
}

// WatchTokenWithdrawn is a free log subscription operation binding the contract event 0x8210728e7c071f615b840ee026032693858fbcd5e5359e67e438c890f59e5620.
//
// Solidity: event TokenWithdrawn(address indexed receiver, address indexed token, uint256 indexed amount)
func (_PayMaster *PayMasterFilterer) WatchTokenWithdrawn(opts *bind.WatchOpts, sink chan<- *PayMasterTokenWithdrawn, receiver []common.Address, token []common.Address, amount []*big.Int) (event.Subscription, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _PayMaster.contract.WatchLogs(opts, "TokenWithdrawn", receiverRule, tokenRule, amountRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(PayMasterTokenWithdrawn)
				if err := _PayMaster.contract.UnpackLog(event, "TokenWithdrawn", log); err != nil {
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

// ParseTokenWithdrawn is a log parse operation binding the contract event 0x8210728e7c071f615b840ee026032693858fbcd5e5359e67e438c890f59e5620.
//
// Solidity: event TokenWithdrawn(address indexed receiver, address indexed token, uint256 indexed amount)
func (_PayMaster *PayMasterFilterer) ParseTokenWithdrawn(log types.Log) (*PayMasterTokenWithdrawn, error) {
	event := new(PayMasterTokenWithdrawn)
	if err := _PayMaster.contract.UnpackLog(event, "TokenWithdrawn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
