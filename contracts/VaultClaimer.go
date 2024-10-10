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

// VaultClaimerMetaData contains all meta data concerning the VaultClaimer contract.
var VaultClaimerMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"function\",\"name\":\"claimProtocolOwnership\",\"inputs\":[{\"name\":\"protocolId_\",\"type\":\"string\",\"internalType\":\"string\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"Claimed\",\"inputs\":[{\"name\":\"claimer\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"protocolId\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"}],\"anonymous\":false}]",
}

// VaultClaimerABI is the input ABI used to generate the binding from.
// Deprecated: Use VaultClaimerMetaData.ABI instead.
var VaultClaimerABI = VaultClaimerMetaData.ABI

// VaultClaimer is an auto generated Go binding around an Ethereum contract.
type VaultClaimer struct {
	VaultClaimerCaller     // Read-only binding to the contract
	VaultClaimerTransactor // Write-only binding to the contract
	VaultClaimerFilterer   // Log filterer for contract events
}

// VaultClaimerCaller is an auto generated read-only Go binding around an Ethereum contract.
type VaultClaimerCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// VaultClaimerTransactor is an auto generated write-only Go binding around an Ethereum contract.
type VaultClaimerTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// VaultClaimerFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type VaultClaimerFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// VaultClaimerSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type VaultClaimerSession struct {
	Contract     *VaultClaimer     // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// VaultClaimerCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type VaultClaimerCallerSession struct {
	Contract *VaultClaimerCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts       // Call options to use throughout this session
}

// VaultClaimerTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type VaultClaimerTransactorSession struct {
	Contract     *VaultClaimerTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts       // Transaction auth options to use throughout this session
}

// VaultClaimerRaw is an auto generated low-level Go binding around an Ethereum contract.
type VaultClaimerRaw struct {
	Contract *VaultClaimer // Generic contract binding to access the raw methods on
}

// VaultClaimerCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type VaultClaimerCallerRaw struct {
	Contract *VaultClaimerCaller // Generic read-only contract binding to access the raw methods on
}

// VaultClaimerTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type VaultClaimerTransactorRaw struct {
	Contract *VaultClaimerTransactor // Generic write-only contract binding to access the raw methods on
}

// NewVaultClaimer creates a new instance of VaultClaimer, bound to a specific deployed contract.
func NewVaultClaimer(address common.Address, backend bind.ContractBackend) (*VaultClaimer, error) {
	contract, err := bindVaultClaimer(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &VaultClaimer{VaultClaimerCaller: VaultClaimerCaller{contract: contract}, VaultClaimerTransactor: VaultClaimerTransactor{contract: contract}, VaultClaimerFilterer: VaultClaimerFilterer{contract: contract}}, nil
}

// NewVaultClaimerCaller creates a new read-only instance of VaultClaimer, bound to a specific deployed contract.
func NewVaultClaimerCaller(address common.Address, caller bind.ContractCaller) (*VaultClaimerCaller, error) {
	contract, err := bindVaultClaimer(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &VaultClaimerCaller{contract: contract}, nil
}

// NewVaultClaimerTransactor creates a new write-only instance of VaultClaimer, bound to a specific deployed contract.
func NewVaultClaimerTransactor(address common.Address, transactor bind.ContractTransactor) (*VaultClaimerTransactor, error) {
	contract, err := bindVaultClaimer(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &VaultClaimerTransactor{contract: contract}, nil
}

// NewVaultClaimerFilterer creates a new log filterer instance of VaultClaimer, bound to a specific deployed contract.
func NewVaultClaimerFilterer(address common.Address, filterer bind.ContractFilterer) (*VaultClaimerFilterer, error) {
	contract, err := bindVaultClaimer(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &VaultClaimerFilterer{contract: contract}, nil
}

// bindVaultClaimer binds a generic wrapper to an already deployed contract.
func bindVaultClaimer(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := VaultClaimerMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_VaultClaimer *VaultClaimerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _VaultClaimer.Contract.VaultClaimerCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_VaultClaimer *VaultClaimerRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _VaultClaimer.Contract.VaultClaimerTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_VaultClaimer *VaultClaimerRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _VaultClaimer.Contract.VaultClaimerTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_VaultClaimer *VaultClaimerCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _VaultClaimer.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_VaultClaimer *VaultClaimerTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _VaultClaimer.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_VaultClaimer *VaultClaimerTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _VaultClaimer.Contract.contract.Transact(opts, method, params...)
}

// ClaimProtocolOwnership is a paid mutator transaction binding the contract method 0xb3bad39b.
//
// Solidity: function claimProtocolOwnership(string protocolId_) returns()
func (_VaultClaimer *VaultClaimerTransactor) ClaimProtocolOwnership(opts *bind.TransactOpts, protocolId_ string) (*types.Transaction, error) {
	return _VaultClaimer.contract.Transact(opts, "claimProtocolOwnership", protocolId_)
}

// ClaimProtocolOwnership is a paid mutator transaction binding the contract method 0xb3bad39b.
//
// Solidity: function claimProtocolOwnership(string protocolId_) returns()
func (_VaultClaimer *VaultClaimerSession) ClaimProtocolOwnership(protocolId_ string) (*types.Transaction, error) {
	return _VaultClaimer.Contract.ClaimProtocolOwnership(&_VaultClaimer.TransactOpts, protocolId_)
}

// ClaimProtocolOwnership is a paid mutator transaction binding the contract method 0xb3bad39b.
//
// Solidity: function claimProtocolOwnership(string protocolId_) returns()
func (_VaultClaimer *VaultClaimerTransactorSession) ClaimProtocolOwnership(protocolId_ string) (*types.Transaction, error) {
	return _VaultClaimer.Contract.ClaimProtocolOwnership(&_VaultClaimer.TransactOpts, protocolId_)
}

// VaultClaimerClaimedIterator is returned from FilterClaimed and is used to iterate over the raw logs and unpacked data for Claimed events raised by the VaultClaimer contract.
type VaultClaimerClaimedIterator struct {
	Event *VaultClaimerClaimed // Event containing the contract specifics and raw log

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
func (it *VaultClaimerClaimedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(VaultClaimerClaimed)
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
		it.Event = new(VaultClaimerClaimed)
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
func (it *VaultClaimerClaimedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *VaultClaimerClaimedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// VaultClaimerClaimed represents a Claimed event raised by the VaultClaimer contract.
type VaultClaimerClaimed struct {
	Claimer    common.Address
	ProtocolId string
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterClaimed is a free log retrieval operation binding the contract event 0x4ef887714b6ae4b4e5b624f78fb37bc493b148ca911452610d6ef8bffc0704e2.
//
// Solidity: event Claimed(address indexed claimer, string protocolId)
func (_VaultClaimer *VaultClaimerFilterer) FilterClaimed(opts *bind.FilterOpts, claimer []common.Address) (*VaultClaimerClaimedIterator, error) {

	var claimerRule []interface{}
	for _, claimerItem := range claimer {
		claimerRule = append(claimerRule, claimerItem)
	}

	logs, sub, err := _VaultClaimer.contract.FilterLogs(opts, "Claimed", claimerRule)
	if err != nil {
		return nil, err
	}
	return &VaultClaimerClaimedIterator{contract: _VaultClaimer.contract, event: "Claimed", logs: logs, sub: sub}, nil
}

// WatchClaimed is a free log subscription operation binding the contract event 0x4ef887714b6ae4b4e5b624f78fb37bc493b148ca911452610d6ef8bffc0704e2.
//
// Solidity: event Claimed(address indexed claimer, string protocolId)
func (_VaultClaimer *VaultClaimerFilterer) WatchClaimed(opts *bind.WatchOpts, sink chan<- *VaultClaimerClaimed, claimer []common.Address) (event.Subscription, error) {

	var claimerRule []interface{}
	for _, claimerItem := range claimer {
		claimerRule = append(claimerRule, claimerItem)
	}

	logs, sub, err := _VaultClaimer.contract.WatchLogs(opts, "Claimed", claimerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(VaultClaimerClaimed)
				if err := _VaultClaimer.contract.UnpackLog(event, "Claimed", log); err != nil {
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

// ParseClaimed is a log parse operation binding the contract event 0x4ef887714b6ae4b4e5b624f78fb37bc493b148ca911452610d6ef8bffc0704e2.
//
// Solidity: event Claimed(address indexed claimer, string protocolId)
func (_VaultClaimer *VaultClaimerFilterer) ParseClaimed(log types.Log) (*VaultClaimerClaimed, error) {
	event := new(VaultClaimerClaimed)
	if err := _VaultClaimer.contract.UnpackLog(event, "Claimed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
