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

// ISuperformRouterPlusDeposit4626Args is an auto generated low-level Go binding around an user-defined struct.
type ISuperformRouterPlusDeposit4626Args struct {
	Amount               *big.Int
	ExpectedOutputAmount *big.Int
	MaxSlippage          *big.Int
	ReceiverAddressSP    common.Address
	DepositCallData      []byte
}

// ISuperformRouterPlusInitiateXChainRebalanceArgs is an auto generated low-level Go binding around an user-defined struct.
type ISuperformRouterPlusInitiateXChainRebalanceArgs struct {
	Id                         *big.Int
	SharesToRedeem             *big.Int
	ReceiverAddressSP          common.Address
	InterimAsset               common.Address
	FinalizeSlippage           *big.Int
	ExpectedAmountInterimAsset *big.Int
	RebalanceToSelector        [4]byte
	CallData                   []byte
	RebalanceToAmbIds          []byte
	RebalanceToDstChainIds     []byte
	RebalanceToSfData          []byte
}

// ISuperformRouterPlusInitiateXChainRebalanceMultiArgs is an auto generated low-level Go binding around an user-defined struct.
type ISuperformRouterPlusInitiateXChainRebalanceMultiArgs struct {
	Ids                        []*big.Int
	SharesToRedeem             []*big.Int
	ReceiverAddressSP          common.Address
	InterimAsset               common.Address
	FinalizeSlippage           *big.Int
	ExpectedAmountInterimAsset *big.Int
	RebalanceToSelector        [4]byte
	CallData                   []byte
	RebalanceToAmbIds          []byte
	RebalanceToDstChainIds     []byte
	RebalanceToSfData          []byte
}

// ISuperformRouterPlusRebalanceMultiPositionsSyncArgs is an auto generated low-level Go binding around an user-defined struct.
type ISuperformRouterPlusRebalanceMultiPositionsSyncArgs struct {
	Ids                   []*big.Int
	SharesToRedeem        []*big.Int
	PreviewRedeemAmount   *big.Int
	RebalanceFromMsgValue *big.Int
	RebalanceToMsgValue   *big.Int
	InterimAsset          common.Address
	Slippage              *big.Int
	ReceiverAddressSP     common.Address
	CallData              []byte
	RebalanceToCallData   []byte
}

// ISuperformRouterPlusRebalanceSinglePositionSyncArgs is an auto generated low-level Go binding around an user-defined struct.
type ISuperformRouterPlusRebalanceSinglePositionSyncArgs struct {
	Id                    *big.Int
	SharesToRedeem        *big.Int
	PreviewRedeemAmount   *big.Int
	RebalanceFromMsgValue *big.Int
	RebalanceToMsgValue   *big.Int
	InterimAsset          common.Address
	Slippage              *big.Int
	ReceiverAddressSP     common.Address
	CallData              []byte
	RebalanceToCallData   []byte
}

// SuperformRouterPlusMetaData contains all meta data concerning the SuperformRouterPlus contract.
var SuperformRouterPlusMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superRegistry_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"CHAIN_ID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"ROUTER_PLUS_PAYLOAD_ID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"deposit4626\",\"inputs\":[{\"name\":\"vault_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperformRouterPlus.Deposit4626Args\",\"components\":[{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expectedOutputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"depositCallData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"forwardDustToPaymaster\",\"inputs\":[{\"name\":\"token_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"onERC1155BatchReceived\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"onERC1155Received\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"rebalanceMultiPositions\",\"inputs\":[{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperformRouterPlus.RebalanceMultiPositionsSyncArgs\",\"components\":[{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"sharesToRedeem\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"previewRedeemAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"rebalanceFromMsgValue\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"rebalanceToMsgValue\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"interimAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"slippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"callData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToCallData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"rebalanceSinglePosition\",\"inputs\":[{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperformRouterPlus.RebalanceSinglePositionSyncArgs\",\"components\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"sharesToRedeem\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"previewRedeemAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"rebalanceFromMsgValue\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"rebalanceToMsgValue\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"interimAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"slippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"callData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToCallData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"startCrossChainRebalance\",\"inputs\":[{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperformRouterPlus.InitiateXChainRebalanceArgs\",\"components\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"sharesToRedeem\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"finalizeSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expectedAmountInterimAsset\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"rebalanceToSelector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"},{\"name\":\"callData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToAmbIds\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToDstChainIds\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToSfData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"startCrossChainRebalanceMulti\",\"inputs\":[{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperformRouterPlus.InitiateXChainRebalanceMultiArgs\",\"components\":[{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"sharesToRedeem\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimAsset\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"finalizeSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"expectedAmountInterimAsset\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"rebalanceToSelector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"},{\"name\":\"callData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToAmbIds\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToDstChainIds\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"rebalanceToSfData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"superRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperRegistry\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"whitelistedSelectors\",\"inputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"enumIBaseSuperformRouterPlus.Actions\"},{\"name\":\"selector\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"whitelisted\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"Deposit4626Completed\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceMultiSyncCompleted\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RebalanceSyncCompleted\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RouterPlusDustForwardedToPaymaster\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"XChainRebalanceInitiated\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"routerPlusPayloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"interimAsset\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"finalizeSlippage\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"expectedAmountInterimAsset\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"rebalanceToSelector\",\"type\":\"bytes4\",\"indexed\":false,\"internalType\":\"bytes4\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"XChainRebalanceMultiInitiated\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"routerPlusPayloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"interimAsset\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"},{\"name\":\"finalizeSlippage\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"expectedAmountInterimAsset\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"rebalanceToSelector\",\"type\":\"bytes4\",\"indexed\":false,\"internalType\":\"bytes4\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ARRAY_LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ASSETS_RECEIVED_OUT_OF_SLIPPAGE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AddressEmptyCode\",\"inputs\":[{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"AddressInsufficientBalance\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"BLOCK_CHAIN_ID_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FAILED_TO_SEND_NATIVE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FailedInnerCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_DEPOSIT_SELECTOR\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_FEE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_REBALANCE_FROM_SELECTOR\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_REBALANCE_SELECTOR\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REBALANCE_MULTI_POSITIONS_UNEXPECTED_RECEIVER_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REBALANCE_SINGLE_POSITIONS_DIFFERENT_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REBALANCE_SINGLE_POSITIONS_DIFFERENT_CHAIN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REBALANCE_SINGLE_POSITIONS_DIFFERENT_TOKEN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REBALANCE_SINGLE_POSITIONS_UNEXPECTED_RECEIVER_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"VAULT_IMPLEMENTATION_FAILED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_AMOUNT\",\"inputs\":[]}]",
}

// SuperformRouterPlusABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperformRouterPlusMetaData.ABI instead.
var SuperformRouterPlusABI = SuperformRouterPlusMetaData.ABI

// SuperformRouterPlus is an auto generated Go binding around an Ethereum contract.
type SuperformRouterPlus struct {
	SuperformRouterPlusCaller     // Read-only binding to the contract
	SuperformRouterPlusTransactor // Write-only binding to the contract
	SuperformRouterPlusFilterer   // Log filterer for contract events
}

// SuperformRouterPlusCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperformRouterPlusCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperformRouterPlusTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperformRouterPlusTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperformRouterPlusFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperformRouterPlusFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperformRouterPlusSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperformRouterPlusSession struct {
	Contract     *SuperformRouterPlus // Generic contract binding to set the session for
	CallOpts     bind.CallOpts        // Call options to use throughout this session
	TransactOpts bind.TransactOpts    // Transaction auth options to use throughout this session
}

// SuperformRouterPlusCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperformRouterPlusCallerSession struct {
	Contract *SuperformRouterPlusCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts              // Call options to use throughout this session
}

// SuperformRouterPlusTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperformRouterPlusTransactorSession struct {
	Contract     *SuperformRouterPlusTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts              // Transaction auth options to use throughout this session
}

// SuperformRouterPlusRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperformRouterPlusRaw struct {
	Contract *SuperformRouterPlus // Generic contract binding to access the raw methods on
}

// SuperformRouterPlusCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperformRouterPlusCallerRaw struct {
	Contract *SuperformRouterPlusCaller // Generic read-only contract binding to access the raw methods on
}

// SuperformRouterPlusTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperformRouterPlusTransactorRaw struct {
	Contract *SuperformRouterPlusTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperformRouterPlus creates a new instance of SuperformRouterPlus, bound to a specific deployed contract.
func NewSuperformRouterPlus(address common.Address, backend bind.ContractBackend) (*SuperformRouterPlus, error) {
	contract, err := bindSuperformRouterPlus(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlus{SuperformRouterPlusCaller: SuperformRouterPlusCaller{contract: contract}, SuperformRouterPlusTransactor: SuperformRouterPlusTransactor{contract: contract}, SuperformRouterPlusFilterer: SuperformRouterPlusFilterer{contract: contract}}, nil
}

// NewSuperformRouterPlusCaller creates a new read-only instance of SuperformRouterPlus, bound to a specific deployed contract.
func NewSuperformRouterPlusCaller(address common.Address, caller bind.ContractCaller) (*SuperformRouterPlusCaller, error) {
	contract, err := bindSuperformRouterPlus(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusCaller{contract: contract}, nil
}

// NewSuperformRouterPlusTransactor creates a new write-only instance of SuperformRouterPlus, bound to a specific deployed contract.
func NewSuperformRouterPlusTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperformRouterPlusTransactor, error) {
	contract, err := bindSuperformRouterPlus(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusTransactor{contract: contract}, nil
}

// NewSuperformRouterPlusFilterer creates a new log filterer instance of SuperformRouterPlus, bound to a specific deployed contract.
func NewSuperformRouterPlusFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperformRouterPlusFilterer, error) {
	contract, err := bindSuperformRouterPlus(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusFilterer{contract: contract}, nil
}

// bindSuperformRouterPlus binds a generic wrapper to an already deployed contract.
func bindSuperformRouterPlus(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperformRouterPlusMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperformRouterPlus *SuperformRouterPlusRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperformRouterPlus.Contract.SuperformRouterPlusCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperformRouterPlus *SuperformRouterPlusRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.SuperformRouterPlusTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperformRouterPlus *SuperformRouterPlusRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.SuperformRouterPlusTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperformRouterPlus *SuperformRouterPlusCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperformRouterPlus.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperformRouterPlus *SuperformRouterPlusTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperformRouterPlus *SuperformRouterPlusTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.contract.Transact(opts, method, params...)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SuperformRouterPlus *SuperformRouterPlusCaller) CHAINID(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _SuperformRouterPlus.contract.Call(opts, &out, "CHAIN_ID")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SuperformRouterPlus *SuperformRouterPlusSession) CHAINID() (uint64, error) {
	return _SuperformRouterPlus.Contract.CHAINID(&_SuperformRouterPlus.CallOpts)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SuperformRouterPlus *SuperformRouterPlusCallerSession) CHAINID() (uint64, error) {
	return _SuperformRouterPlus.Contract.CHAINID(&_SuperformRouterPlus.CallOpts)
}

// ROUTERPLUSPAYLOADID is a free data retrieval call binding the contract method 0xed88e594.
//
// Solidity: function ROUTER_PLUS_PAYLOAD_ID() view returns(uint256)
func (_SuperformRouterPlus *SuperformRouterPlusCaller) ROUTERPLUSPAYLOADID(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperformRouterPlus.contract.Call(opts, &out, "ROUTER_PLUS_PAYLOAD_ID")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// ROUTERPLUSPAYLOADID is a free data retrieval call binding the contract method 0xed88e594.
//
// Solidity: function ROUTER_PLUS_PAYLOAD_ID() view returns(uint256)
func (_SuperformRouterPlus *SuperformRouterPlusSession) ROUTERPLUSPAYLOADID() (*big.Int, error) {
	return _SuperformRouterPlus.Contract.ROUTERPLUSPAYLOADID(&_SuperformRouterPlus.CallOpts)
}

// ROUTERPLUSPAYLOADID is a free data retrieval call binding the contract method 0xed88e594.
//
// Solidity: function ROUTER_PLUS_PAYLOAD_ID() view returns(uint256)
func (_SuperformRouterPlus *SuperformRouterPlusCallerSession) ROUTERPLUSPAYLOADID() (*big.Int, error) {
	return _SuperformRouterPlus.Contract.ROUTERPLUSPAYLOADID(&_SuperformRouterPlus.CallOpts)
}

// OnERC1155BatchReceived is a free data retrieval call binding the contract method 0xbc197c81.
//
// Solidity: function onERC1155BatchReceived(address , address , uint256[] , uint256[] , bytes ) pure returns(bytes4)
func (_SuperformRouterPlus *SuperformRouterPlusCaller) OnERC1155BatchReceived(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address, arg2 []*big.Int, arg3 []*big.Int, arg4 []byte) ([4]byte, error) {
	var out []interface{}
	err := _SuperformRouterPlus.contract.Call(opts, &out, "onERC1155BatchReceived", arg0, arg1, arg2, arg3, arg4)

	if err != nil {
		return *new([4]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([4]byte)).(*[4]byte)

	return out0, err

}

// OnERC1155BatchReceived is a free data retrieval call binding the contract method 0xbc197c81.
//
// Solidity: function onERC1155BatchReceived(address , address , uint256[] , uint256[] , bytes ) pure returns(bytes4)
func (_SuperformRouterPlus *SuperformRouterPlusSession) OnERC1155BatchReceived(arg0 common.Address, arg1 common.Address, arg2 []*big.Int, arg3 []*big.Int, arg4 []byte) ([4]byte, error) {
	return _SuperformRouterPlus.Contract.OnERC1155BatchReceived(&_SuperformRouterPlus.CallOpts, arg0, arg1, arg2, arg3, arg4)
}

// OnERC1155BatchReceived is a free data retrieval call binding the contract method 0xbc197c81.
//
// Solidity: function onERC1155BatchReceived(address , address , uint256[] , uint256[] , bytes ) pure returns(bytes4)
func (_SuperformRouterPlus *SuperformRouterPlusCallerSession) OnERC1155BatchReceived(arg0 common.Address, arg1 common.Address, arg2 []*big.Int, arg3 []*big.Int, arg4 []byte) ([4]byte, error) {
	return _SuperformRouterPlus.Contract.OnERC1155BatchReceived(&_SuperformRouterPlus.CallOpts, arg0, arg1, arg2, arg3, arg4)
}

// OnERC1155Received is a free data retrieval call binding the contract method 0xf23a6e61.
//
// Solidity: function onERC1155Received(address , address , uint256 , uint256 , bytes ) pure returns(bytes4)
func (_SuperformRouterPlus *SuperformRouterPlusCaller) OnERC1155Received(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address, arg2 *big.Int, arg3 *big.Int, arg4 []byte) ([4]byte, error) {
	var out []interface{}
	err := _SuperformRouterPlus.contract.Call(opts, &out, "onERC1155Received", arg0, arg1, arg2, arg3, arg4)

	if err != nil {
		return *new([4]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([4]byte)).(*[4]byte)

	return out0, err

}

// OnERC1155Received is a free data retrieval call binding the contract method 0xf23a6e61.
//
// Solidity: function onERC1155Received(address , address , uint256 , uint256 , bytes ) pure returns(bytes4)
func (_SuperformRouterPlus *SuperformRouterPlusSession) OnERC1155Received(arg0 common.Address, arg1 common.Address, arg2 *big.Int, arg3 *big.Int, arg4 []byte) ([4]byte, error) {
	return _SuperformRouterPlus.Contract.OnERC1155Received(&_SuperformRouterPlus.CallOpts, arg0, arg1, arg2, arg3, arg4)
}

// OnERC1155Received is a free data retrieval call binding the contract method 0xf23a6e61.
//
// Solidity: function onERC1155Received(address , address , uint256 , uint256 , bytes ) pure returns(bytes4)
func (_SuperformRouterPlus *SuperformRouterPlusCallerSession) OnERC1155Received(arg0 common.Address, arg1 common.Address, arg2 *big.Int, arg3 *big.Int, arg4 []byte) ([4]byte, error) {
	return _SuperformRouterPlus.Contract.OnERC1155Received(&_SuperformRouterPlus.CallOpts, arg0, arg1, arg2, arg3, arg4)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SuperformRouterPlus *SuperformRouterPlusCaller) SuperRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperformRouterPlus.contract.Call(opts, &out, "superRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SuperformRouterPlus *SuperformRouterPlusSession) SuperRegistry() (common.Address, error) {
	return _SuperformRouterPlus.Contract.SuperRegistry(&_SuperformRouterPlus.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SuperformRouterPlus *SuperformRouterPlusCallerSession) SuperRegistry() (common.Address, error) {
	return _SuperformRouterPlus.Contract.SuperRegistry(&_SuperformRouterPlus.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) pure returns(bool)
func (_SuperformRouterPlus *SuperformRouterPlusCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _SuperformRouterPlus.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) pure returns(bool)
func (_SuperformRouterPlus *SuperformRouterPlusSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperformRouterPlus.Contract.SupportsInterface(&_SuperformRouterPlus.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) pure returns(bool)
func (_SuperformRouterPlus *SuperformRouterPlusCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperformRouterPlus.Contract.SupportsInterface(&_SuperformRouterPlus.CallOpts, interfaceId)
}

// WhitelistedSelectors is a free data retrieval call binding the contract method 0xb8cae75c.
//
// Solidity: function whitelistedSelectors(uint8 , bytes4 selector) view returns(bool whitelisted)
func (_SuperformRouterPlus *SuperformRouterPlusCaller) WhitelistedSelectors(opts *bind.CallOpts, arg0 uint8, selector [4]byte) (bool, error) {
	var out []interface{}
	err := _SuperformRouterPlus.contract.Call(opts, &out, "whitelistedSelectors", arg0, selector)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// WhitelistedSelectors is a free data retrieval call binding the contract method 0xb8cae75c.
//
// Solidity: function whitelistedSelectors(uint8 , bytes4 selector) view returns(bool whitelisted)
func (_SuperformRouterPlus *SuperformRouterPlusSession) WhitelistedSelectors(arg0 uint8, selector [4]byte) (bool, error) {
	return _SuperformRouterPlus.Contract.WhitelistedSelectors(&_SuperformRouterPlus.CallOpts, arg0, selector)
}

// WhitelistedSelectors is a free data retrieval call binding the contract method 0xb8cae75c.
//
// Solidity: function whitelistedSelectors(uint8 , bytes4 selector) view returns(bool whitelisted)
func (_SuperformRouterPlus *SuperformRouterPlusCallerSession) WhitelistedSelectors(arg0 uint8, selector [4]byte) (bool, error) {
	return _SuperformRouterPlus.Contract.WhitelistedSelectors(&_SuperformRouterPlus.CallOpts, arg0, selector)
}

// Deposit4626 is a paid mutator transaction binding the contract method 0x1d13be58.
//
// Solidity: function deposit4626(address vault_, (uint256,uint256,uint256,address,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactor) Deposit4626(opts *bind.TransactOpts, vault_ common.Address, args ISuperformRouterPlusDeposit4626Args) (*types.Transaction, error) {
	return _SuperformRouterPlus.contract.Transact(opts, "deposit4626", vault_, args)
}

// Deposit4626 is a paid mutator transaction binding the contract method 0x1d13be58.
//
// Solidity: function deposit4626(address vault_, (uint256,uint256,uint256,address,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusSession) Deposit4626(vault_ common.Address, args ISuperformRouterPlusDeposit4626Args) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.Deposit4626(&_SuperformRouterPlus.TransactOpts, vault_, args)
}

// Deposit4626 is a paid mutator transaction binding the contract method 0x1d13be58.
//
// Solidity: function deposit4626(address vault_, (uint256,uint256,uint256,address,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactorSession) Deposit4626(vault_ common.Address, args ISuperformRouterPlusDeposit4626Args) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.Deposit4626(&_SuperformRouterPlus.TransactOpts, vault_, args)
}

// ForwardDustToPaymaster is a paid mutator transaction binding the contract method 0x4dcd03c0.
//
// Solidity: function forwardDustToPaymaster(address token_) returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactor) ForwardDustToPaymaster(opts *bind.TransactOpts, token_ common.Address) (*types.Transaction, error) {
	return _SuperformRouterPlus.contract.Transact(opts, "forwardDustToPaymaster", token_)
}

// ForwardDustToPaymaster is a paid mutator transaction binding the contract method 0x4dcd03c0.
//
// Solidity: function forwardDustToPaymaster(address token_) returns()
func (_SuperformRouterPlus *SuperformRouterPlusSession) ForwardDustToPaymaster(token_ common.Address) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.ForwardDustToPaymaster(&_SuperformRouterPlus.TransactOpts, token_)
}

// ForwardDustToPaymaster is a paid mutator transaction binding the contract method 0x4dcd03c0.
//
// Solidity: function forwardDustToPaymaster(address token_) returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactorSession) ForwardDustToPaymaster(token_ common.Address) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.ForwardDustToPaymaster(&_SuperformRouterPlus.TransactOpts, token_)
}

// RebalanceMultiPositions is a paid mutator transaction binding the contract method 0xd14b23b4.
//
// Solidity: function rebalanceMultiPositions((uint256[],uint256[],uint256,uint256,uint256,address,uint256,address,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactor) RebalanceMultiPositions(opts *bind.TransactOpts, args ISuperformRouterPlusRebalanceMultiPositionsSyncArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.contract.Transact(opts, "rebalanceMultiPositions", args)
}

// RebalanceMultiPositions is a paid mutator transaction binding the contract method 0xd14b23b4.
//
// Solidity: function rebalanceMultiPositions((uint256[],uint256[],uint256,uint256,uint256,address,uint256,address,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusSession) RebalanceMultiPositions(args ISuperformRouterPlusRebalanceMultiPositionsSyncArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.RebalanceMultiPositions(&_SuperformRouterPlus.TransactOpts, args)
}

// RebalanceMultiPositions is a paid mutator transaction binding the contract method 0xd14b23b4.
//
// Solidity: function rebalanceMultiPositions((uint256[],uint256[],uint256,uint256,uint256,address,uint256,address,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactorSession) RebalanceMultiPositions(args ISuperformRouterPlusRebalanceMultiPositionsSyncArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.RebalanceMultiPositions(&_SuperformRouterPlus.TransactOpts, args)
}

// RebalanceSinglePosition is a paid mutator transaction binding the contract method 0x1e8e655f.
//
// Solidity: function rebalanceSinglePosition((uint256,uint256,uint256,uint256,uint256,address,uint256,address,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactor) RebalanceSinglePosition(opts *bind.TransactOpts, args ISuperformRouterPlusRebalanceSinglePositionSyncArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.contract.Transact(opts, "rebalanceSinglePosition", args)
}

// RebalanceSinglePosition is a paid mutator transaction binding the contract method 0x1e8e655f.
//
// Solidity: function rebalanceSinglePosition((uint256,uint256,uint256,uint256,uint256,address,uint256,address,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusSession) RebalanceSinglePosition(args ISuperformRouterPlusRebalanceSinglePositionSyncArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.RebalanceSinglePosition(&_SuperformRouterPlus.TransactOpts, args)
}

// RebalanceSinglePosition is a paid mutator transaction binding the contract method 0x1e8e655f.
//
// Solidity: function rebalanceSinglePosition((uint256,uint256,uint256,uint256,uint256,address,uint256,address,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactorSession) RebalanceSinglePosition(args ISuperformRouterPlusRebalanceSinglePositionSyncArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.RebalanceSinglePosition(&_SuperformRouterPlus.TransactOpts, args)
}

// StartCrossChainRebalance is a paid mutator transaction binding the contract method 0xfea598a4.
//
// Solidity: function startCrossChainRebalance((uint256,uint256,address,address,uint256,uint256,bytes4,bytes,bytes,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactor) StartCrossChainRebalance(opts *bind.TransactOpts, args ISuperformRouterPlusInitiateXChainRebalanceArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.contract.Transact(opts, "startCrossChainRebalance", args)
}

// StartCrossChainRebalance is a paid mutator transaction binding the contract method 0xfea598a4.
//
// Solidity: function startCrossChainRebalance((uint256,uint256,address,address,uint256,uint256,bytes4,bytes,bytes,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusSession) StartCrossChainRebalance(args ISuperformRouterPlusInitiateXChainRebalanceArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.StartCrossChainRebalance(&_SuperformRouterPlus.TransactOpts, args)
}

// StartCrossChainRebalance is a paid mutator transaction binding the contract method 0xfea598a4.
//
// Solidity: function startCrossChainRebalance((uint256,uint256,address,address,uint256,uint256,bytes4,bytes,bytes,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactorSession) StartCrossChainRebalance(args ISuperformRouterPlusInitiateXChainRebalanceArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.StartCrossChainRebalance(&_SuperformRouterPlus.TransactOpts, args)
}

// StartCrossChainRebalanceMulti is a paid mutator transaction binding the contract method 0xbb01fb30.
//
// Solidity: function startCrossChainRebalanceMulti((uint256[],uint256[],address,address,uint256,uint256,bytes4,bytes,bytes,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactor) StartCrossChainRebalanceMulti(opts *bind.TransactOpts, args ISuperformRouterPlusInitiateXChainRebalanceMultiArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.contract.Transact(opts, "startCrossChainRebalanceMulti", args)
}

// StartCrossChainRebalanceMulti is a paid mutator transaction binding the contract method 0xbb01fb30.
//
// Solidity: function startCrossChainRebalanceMulti((uint256[],uint256[],address,address,uint256,uint256,bytes4,bytes,bytes,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusSession) StartCrossChainRebalanceMulti(args ISuperformRouterPlusInitiateXChainRebalanceMultiArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.StartCrossChainRebalanceMulti(&_SuperformRouterPlus.TransactOpts, args)
}

// StartCrossChainRebalanceMulti is a paid mutator transaction binding the contract method 0xbb01fb30.
//
// Solidity: function startCrossChainRebalanceMulti((uint256[],uint256[],address,address,uint256,uint256,bytes4,bytes,bytes,bytes,bytes) args) payable returns()
func (_SuperformRouterPlus *SuperformRouterPlusTransactorSession) StartCrossChainRebalanceMulti(args ISuperformRouterPlusInitiateXChainRebalanceMultiArgs) (*types.Transaction, error) {
	return _SuperformRouterPlus.Contract.StartCrossChainRebalanceMulti(&_SuperformRouterPlus.TransactOpts, args)
}

// SuperformRouterPlusDeposit4626CompletedIterator is returned from FilterDeposit4626Completed and is used to iterate over the raw logs and unpacked data for Deposit4626Completed events raised by the SuperformRouterPlus contract.
type SuperformRouterPlusDeposit4626CompletedIterator struct {
	Event *SuperformRouterPlusDeposit4626Completed // Event containing the contract specifics and raw log

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
func (it *SuperformRouterPlusDeposit4626CompletedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperformRouterPlusDeposit4626Completed)
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
		it.Event = new(SuperformRouterPlusDeposit4626Completed)
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
func (it *SuperformRouterPlusDeposit4626CompletedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperformRouterPlusDeposit4626CompletedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperformRouterPlusDeposit4626Completed represents a Deposit4626Completed event raised by the SuperformRouterPlus contract.
type SuperformRouterPlusDeposit4626Completed struct {
	Receiver common.Address
	Vault    common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterDeposit4626Completed is a free log retrieval operation binding the contract event 0x709067c661df529510fce32dc66881c859f62fcbdfa319bbd2ae37745b6903d3.
//
// Solidity: event Deposit4626Completed(address indexed receiver, address indexed vault)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) FilterDeposit4626Completed(opts *bind.FilterOpts, receiver []common.Address, vault []common.Address) (*SuperformRouterPlusDeposit4626CompletedIterator, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.FilterLogs(opts, "Deposit4626Completed", receiverRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusDeposit4626CompletedIterator{contract: _SuperformRouterPlus.contract, event: "Deposit4626Completed", logs: logs, sub: sub}, nil
}

// WatchDeposit4626Completed is a free log subscription operation binding the contract event 0x709067c661df529510fce32dc66881c859f62fcbdfa319bbd2ae37745b6903d3.
//
// Solidity: event Deposit4626Completed(address indexed receiver, address indexed vault)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) WatchDeposit4626Completed(opts *bind.WatchOpts, sink chan<- *SuperformRouterPlusDeposit4626Completed, receiver []common.Address, vault []common.Address) (event.Subscription, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.WatchLogs(opts, "Deposit4626Completed", receiverRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperformRouterPlusDeposit4626Completed)
				if err := _SuperformRouterPlus.contract.UnpackLog(event, "Deposit4626Completed", log); err != nil {
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

// ParseDeposit4626Completed is a log parse operation binding the contract event 0x709067c661df529510fce32dc66881c859f62fcbdfa319bbd2ae37745b6903d3.
//
// Solidity: event Deposit4626Completed(address indexed receiver, address indexed vault)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) ParseDeposit4626Completed(log types.Log) (*SuperformRouterPlusDeposit4626Completed, error) {
	event := new(SuperformRouterPlusDeposit4626Completed)
	if err := _SuperformRouterPlus.contract.UnpackLog(event, "Deposit4626Completed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperformRouterPlusRebalanceMultiSyncCompletedIterator is returned from FilterRebalanceMultiSyncCompleted and is used to iterate over the raw logs and unpacked data for RebalanceMultiSyncCompleted events raised by the SuperformRouterPlus contract.
type SuperformRouterPlusRebalanceMultiSyncCompletedIterator struct {
	Event *SuperformRouterPlusRebalanceMultiSyncCompleted // Event containing the contract specifics and raw log

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
func (it *SuperformRouterPlusRebalanceMultiSyncCompletedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperformRouterPlusRebalanceMultiSyncCompleted)
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
		it.Event = new(SuperformRouterPlusRebalanceMultiSyncCompleted)
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
func (it *SuperformRouterPlusRebalanceMultiSyncCompletedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperformRouterPlusRebalanceMultiSyncCompletedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperformRouterPlusRebalanceMultiSyncCompleted represents a RebalanceMultiSyncCompleted event raised by the SuperformRouterPlus contract.
type SuperformRouterPlusRebalanceMultiSyncCompleted struct {
	Receiver common.Address
	Ids      []*big.Int
	Amounts  []*big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterRebalanceMultiSyncCompleted is a free log retrieval operation binding the contract event 0x20f0b022ea8533c8bb3db76cfbf94e0231259f57e2280c8c1ea27d70fb8fea9d.
//
// Solidity: event RebalanceMultiSyncCompleted(address indexed receiver, uint256[] ids, uint256[] amounts)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) FilterRebalanceMultiSyncCompleted(opts *bind.FilterOpts, receiver []common.Address) (*SuperformRouterPlusRebalanceMultiSyncCompletedIterator, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.FilterLogs(opts, "RebalanceMultiSyncCompleted", receiverRule)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusRebalanceMultiSyncCompletedIterator{contract: _SuperformRouterPlus.contract, event: "RebalanceMultiSyncCompleted", logs: logs, sub: sub}, nil
}

// WatchRebalanceMultiSyncCompleted is a free log subscription operation binding the contract event 0x20f0b022ea8533c8bb3db76cfbf94e0231259f57e2280c8c1ea27d70fb8fea9d.
//
// Solidity: event RebalanceMultiSyncCompleted(address indexed receiver, uint256[] ids, uint256[] amounts)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) WatchRebalanceMultiSyncCompleted(opts *bind.WatchOpts, sink chan<- *SuperformRouterPlusRebalanceMultiSyncCompleted, receiver []common.Address) (event.Subscription, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.WatchLogs(opts, "RebalanceMultiSyncCompleted", receiverRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperformRouterPlusRebalanceMultiSyncCompleted)
				if err := _SuperformRouterPlus.contract.UnpackLog(event, "RebalanceMultiSyncCompleted", log); err != nil {
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

// ParseRebalanceMultiSyncCompleted is a log parse operation binding the contract event 0x20f0b022ea8533c8bb3db76cfbf94e0231259f57e2280c8c1ea27d70fb8fea9d.
//
// Solidity: event RebalanceMultiSyncCompleted(address indexed receiver, uint256[] ids, uint256[] amounts)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) ParseRebalanceMultiSyncCompleted(log types.Log) (*SuperformRouterPlusRebalanceMultiSyncCompleted, error) {
	event := new(SuperformRouterPlusRebalanceMultiSyncCompleted)
	if err := _SuperformRouterPlus.contract.UnpackLog(event, "RebalanceMultiSyncCompleted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperformRouterPlusRebalanceSyncCompletedIterator is returned from FilterRebalanceSyncCompleted and is used to iterate over the raw logs and unpacked data for RebalanceSyncCompleted events raised by the SuperformRouterPlus contract.
type SuperformRouterPlusRebalanceSyncCompletedIterator struct {
	Event *SuperformRouterPlusRebalanceSyncCompleted // Event containing the contract specifics and raw log

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
func (it *SuperformRouterPlusRebalanceSyncCompletedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperformRouterPlusRebalanceSyncCompleted)
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
		it.Event = new(SuperformRouterPlusRebalanceSyncCompleted)
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
func (it *SuperformRouterPlusRebalanceSyncCompletedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperformRouterPlusRebalanceSyncCompletedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperformRouterPlusRebalanceSyncCompleted represents a RebalanceSyncCompleted event raised by the SuperformRouterPlus contract.
type SuperformRouterPlusRebalanceSyncCompleted struct {
	Receiver common.Address
	Id       *big.Int
	Amount   *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterRebalanceSyncCompleted is a free log retrieval operation binding the contract event 0xb7dda660aee9356789dca101ff746f669397b46cf6c6ac0f8783ef9efaf727c8.
//
// Solidity: event RebalanceSyncCompleted(address indexed receiver, uint256 indexed id, uint256 amount)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) FilterRebalanceSyncCompleted(opts *bind.FilterOpts, receiver []common.Address, id []*big.Int) (*SuperformRouterPlusRebalanceSyncCompletedIterator, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.FilterLogs(opts, "RebalanceSyncCompleted", receiverRule, idRule)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusRebalanceSyncCompletedIterator{contract: _SuperformRouterPlus.contract, event: "RebalanceSyncCompleted", logs: logs, sub: sub}, nil
}

// WatchRebalanceSyncCompleted is a free log subscription operation binding the contract event 0xb7dda660aee9356789dca101ff746f669397b46cf6c6ac0f8783ef9efaf727c8.
//
// Solidity: event RebalanceSyncCompleted(address indexed receiver, uint256 indexed id, uint256 amount)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) WatchRebalanceSyncCompleted(opts *bind.WatchOpts, sink chan<- *SuperformRouterPlusRebalanceSyncCompleted, receiver []common.Address, id []*big.Int) (event.Subscription, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.WatchLogs(opts, "RebalanceSyncCompleted", receiverRule, idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperformRouterPlusRebalanceSyncCompleted)
				if err := _SuperformRouterPlus.contract.UnpackLog(event, "RebalanceSyncCompleted", log); err != nil {
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

// ParseRebalanceSyncCompleted is a log parse operation binding the contract event 0xb7dda660aee9356789dca101ff746f669397b46cf6c6ac0f8783ef9efaf727c8.
//
// Solidity: event RebalanceSyncCompleted(address indexed receiver, uint256 indexed id, uint256 amount)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) ParseRebalanceSyncCompleted(log types.Log) (*SuperformRouterPlusRebalanceSyncCompleted, error) {
	event := new(SuperformRouterPlusRebalanceSyncCompleted)
	if err := _SuperformRouterPlus.contract.UnpackLog(event, "RebalanceSyncCompleted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperformRouterPlusRouterPlusDustForwardedToPaymasterIterator is returned from FilterRouterPlusDustForwardedToPaymaster and is used to iterate over the raw logs and unpacked data for RouterPlusDustForwardedToPaymaster events raised by the SuperformRouterPlus contract.
type SuperformRouterPlusRouterPlusDustForwardedToPaymasterIterator struct {
	Event *SuperformRouterPlusRouterPlusDustForwardedToPaymaster // Event containing the contract specifics and raw log

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
func (it *SuperformRouterPlusRouterPlusDustForwardedToPaymasterIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperformRouterPlusRouterPlusDustForwardedToPaymaster)
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
		it.Event = new(SuperformRouterPlusRouterPlusDustForwardedToPaymaster)
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
func (it *SuperformRouterPlusRouterPlusDustForwardedToPaymasterIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperformRouterPlusRouterPlusDustForwardedToPaymasterIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperformRouterPlusRouterPlusDustForwardedToPaymaster represents a RouterPlusDustForwardedToPaymaster event raised by the SuperformRouterPlus contract.
type SuperformRouterPlusRouterPlusDustForwardedToPaymaster struct {
	Token  common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterRouterPlusDustForwardedToPaymaster is a free log retrieval operation binding the contract event 0x141c84b86bfe9ffa1ebeca61071c35255a8cc7d0e98e80c5a2f994d77e431cfd.
//
// Solidity: event RouterPlusDustForwardedToPaymaster(address indexed token, uint256 amount)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) FilterRouterPlusDustForwardedToPaymaster(opts *bind.FilterOpts, token []common.Address) (*SuperformRouterPlusRouterPlusDustForwardedToPaymasterIterator, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.FilterLogs(opts, "RouterPlusDustForwardedToPaymaster", tokenRule)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusRouterPlusDustForwardedToPaymasterIterator{contract: _SuperformRouterPlus.contract, event: "RouterPlusDustForwardedToPaymaster", logs: logs, sub: sub}, nil
}

// WatchRouterPlusDustForwardedToPaymaster is a free log subscription operation binding the contract event 0x141c84b86bfe9ffa1ebeca61071c35255a8cc7d0e98e80c5a2f994d77e431cfd.
//
// Solidity: event RouterPlusDustForwardedToPaymaster(address indexed token, uint256 amount)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) WatchRouterPlusDustForwardedToPaymaster(opts *bind.WatchOpts, sink chan<- *SuperformRouterPlusRouterPlusDustForwardedToPaymaster, token []common.Address) (event.Subscription, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.WatchLogs(opts, "RouterPlusDustForwardedToPaymaster", tokenRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperformRouterPlusRouterPlusDustForwardedToPaymaster)
				if err := _SuperformRouterPlus.contract.UnpackLog(event, "RouterPlusDustForwardedToPaymaster", log); err != nil {
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

// ParseRouterPlusDustForwardedToPaymaster is a log parse operation binding the contract event 0x141c84b86bfe9ffa1ebeca61071c35255a8cc7d0e98e80c5a2f994d77e431cfd.
//
// Solidity: event RouterPlusDustForwardedToPaymaster(address indexed token, uint256 amount)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) ParseRouterPlusDustForwardedToPaymaster(log types.Log) (*SuperformRouterPlusRouterPlusDustForwardedToPaymaster, error) {
	event := new(SuperformRouterPlusRouterPlusDustForwardedToPaymaster)
	if err := _SuperformRouterPlus.contract.UnpackLog(event, "RouterPlusDustForwardedToPaymaster", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperformRouterPlusXChainRebalanceInitiatedIterator is returned from FilterXChainRebalanceInitiated and is used to iterate over the raw logs and unpacked data for XChainRebalanceInitiated events raised by the SuperformRouterPlus contract.
type SuperformRouterPlusXChainRebalanceInitiatedIterator struct {
	Event *SuperformRouterPlusXChainRebalanceInitiated // Event containing the contract specifics and raw log

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
func (it *SuperformRouterPlusXChainRebalanceInitiatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperformRouterPlusXChainRebalanceInitiated)
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
		it.Event = new(SuperformRouterPlusXChainRebalanceInitiated)
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
func (it *SuperformRouterPlusXChainRebalanceInitiatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperformRouterPlusXChainRebalanceInitiatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperformRouterPlusXChainRebalanceInitiated represents a XChainRebalanceInitiated event raised by the SuperformRouterPlus contract.
type SuperformRouterPlusXChainRebalanceInitiated struct {
	Receiver                   common.Address
	RouterPlusPayloadId        *big.Int
	Id                         *big.Int
	Amount                     *big.Int
	InterimAsset               common.Address
	FinalizeSlippage           *big.Int
	ExpectedAmountInterimAsset *big.Int
	RebalanceToSelector        [4]byte
	Raw                        types.Log // Blockchain specific contextual infos
}

// FilterXChainRebalanceInitiated is a free log retrieval operation binding the contract event 0x4409eb08b3c8780e5bcd4ca12b158f7904ffb1ab7f12a0bb06d77cfd93807fb1.
//
// Solidity: event XChainRebalanceInitiated(address indexed receiver, uint256 indexed routerPlusPayloadId, uint256 id, uint256 amount, address interimAsset, uint256 finalizeSlippage, uint256 expectedAmountInterimAsset, bytes4 rebalanceToSelector)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) FilterXChainRebalanceInitiated(opts *bind.FilterOpts, receiver []common.Address, routerPlusPayloadId []*big.Int) (*SuperformRouterPlusXChainRebalanceInitiatedIterator, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.FilterLogs(opts, "XChainRebalanceInitiated", receiverRule, routerPlusPayloadIdRule)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusXChainRebalanceInitiatedIterator{contract: _SuperformRouterPlus.contract, event: "XChainRebalanceInitiated", logs: logs, sub: sub}, nil
}

// WatchXChainRebalanceInitiated is a free log subscription operation binding the contract event 0x4409eb08b3c8780e5bcd4ca12b158f7904ffb1ab7f12a0bb06d77cfd93807fb1.
//
// Solidity: event XChainRebalanceInitiated(address indexed receiver, uint256 indexed routerPlusPayloadId, uint256 id, uint256 amount, address interimAsset, uint256 finalizeSlippage, uint256 expectedAmountInterimAsset, bytes4 rebalanceToSelector)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) WatchXChainRebalanceInitiated(opts *bind.WatchOpts, sink chan<- *SuperformRouterPlusXChainRebalanceInitiated, receiver []common.Address, routerPlusPayloadId []*big.Int) (event.Subscription, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.WatchLogs(opts, "XChainRebalanceInitiated", receiverRule, routerPlusPayloadIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperformRouterPlusXChainRebalanceInitiated)
				if err := _SuperformRouterPlus.contract.UnpackLog(event, "XChainRebalanceInitiated", log); err != nil {
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

// ParseXChainRebalanceInitiated is a log parse operation binding the contract event 0x4409eb08b3c8780e5bcd4ca12b158f7904ffb1ab7f12a0bb06d77cfd93807fb1.
//
// Solidity: event XChainRebalanceInitiated(address indexed receiver, uint256 indexed routerPlusPayloadId, uint256 id, uint256 amount, address interimAsset, uint256 finalizeSlippage, uint256 expectedAmountInterimAsset, bytes4 rebalanceToSelector)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) ParseXChainRebalanceInitiated(log types.Log) (*SuperformRouterPlusXChainRebalanceInitiated, error) {
	event := new(SuperformRouterPlusXChainRebalanceInitiated)
	if err := _SuperformRouterPlus.contract.UnpackLog(event, "XChainRebalanceInitiated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperformRouterPlusXChainRebalanceMultiInitiatedIterator is returned from FilterXChainRebalanceMultiInitiated and is used to iterate over the raw logs and unpacked data for XChainRebalanceMultiInitiated events raised by the SuperformRouterPlus contract.
type SuperformRouterPlusXChainRebalanceMultiInitiatedIterator struct {
	Event *SuperformRouterPlusXChainRebalanceMultiInitiated // Event containing the contract specifics and raw log

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
func (it *SuperformRouterPlusXChainRebalanceMultiInitiatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperformRouterPlusXChainRebalanceMultiInitiated)
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
		it.Event = new(SuperformRouterPlusXChainRebalanceMultiInitiated)
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
func (it *SuperformRouterPlusXChainRebalanceMultiInitiatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperformRouterPlusXChainRebalanceMultiInitiatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperformRouterPlusXChainRebalanceMultiInitiated represents a XChainRebalanceMultiInitiated event raised by the SuperformRouterPlus contract.
type SuperformRouterPlusXChainRebalanceMultiInitiated struct {
	Receiver                   common.Address
	RouterPlusPayloadId        *big.Int
	Ids                        []*big.Int
	Amounts                    []*big.Int
	InterimAsset               common.Address
	FinalizeSlippage           *big.Int
	ExpectedAmountInterimAsset *big.Int
	RebalanceToSelector        [4]byte
	Raw                        types.Log // Blockchain specific contextual infos
}

// FilterXChainRebalanceMultiInitiated is a free log retrieval operation binding the contract event 0xa138eaa85fc70fe8329ad10bf334b2ddbe1ba5e2f7608a4e0861aaf3bf321e4f.
//
// Solidity: event XChainRebalanceMultiInitiated(address indexed receiver, uint256 indexed routerPlusPayloadId, uint256[] ids, uint256[] amounts, address interimAsset, uint256 finalizeSlippage, uint256 expectedAmountInterimAsset, bytes4 rebalanceToSelector)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) FilterXChainRebalanceMultiInitiated(opts *bind.FilterOpts, receiver []common.Address, routerPlusPayloadId []*big.Int) (*SuperformRouterPlusXChainRebalanceMultiInitiatedIterator, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.FilterLogs(opts, "XChainRebalanceMultiInitiated", receiverRule, routerPlusPayloadIdRule)
	if err != nil {
		return nil, err
	}
	return &SuperformRouterPlusXChainRebalanceMultiInitiatedIterator{contract: _SuperformRouterPlus.contract, event: "XChainRebalanceMultiInitiated", logs: logs, sub: sub}, nil
}

// WatchXChainRebalanceMultiInitiated is a free log subscription operation binding the contract event 0xa138eaa85fc70fe8329ad10bf334b2ddbe1ba5e2f7608a4e0861aaf3bf321e4f.
//
// Solidity: event XChainRebalanceMultiInitiated(address indexed receiver, uint256 indexed routerPlusPayloadId, uint256[] ids, uint256[] amounts, address interimAsset, uint256 finalizeSlippage, uint256 expectedAmountInterimAsset, bytes4 rebalanceToSelector)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) WatchXChainRebalanceMultiInitiated(opts *bind.WatchOpts, sink chan<- *SuperformRouterPlusXChainRebalanceMultiInitiated, receiver []common.Address, routerPlusPayloadId []*big.Int) (event.Subscription, error) {

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}
	var routerPlusPayloadIdRule []interface{}
	for _, routerPlusPayloadIdItem := range routerPlusPayloadId {
		routerPlusPayloadIdRule = append(routerPlusPayloadIdRule, routerPlusPayloadIdItem)
	}

	logs, sub, err := _SuperformRouterPlus.contract.WatchLogs(opts, "XChainRebalanceMultiInitiated", receiverRule, routerPlusPayloadIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperformRouterPlusXChainRebalanceMultiInitiated)
				if err := _SuperformRouterPlus.contract.UnpackLog(event, "XChainRebalanceMultiInitiated", log); err != nil {
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

// ParseXChainRebalanceMultiInitiated is a log parse operation binding the contract event 0xa138eaa85fc70fe8329ad10bf334b2ddbe1ba5e2f7608a4e0861aaf3bf321e4f.
//
// Solidity: event XChainRebalanceMultiInitiated(address indexed receiver, uint256 indexed routerPlusPayloadId, uint256[] ids, uint256[] amounts, address interimAsset, uint256 finalizeSlippage, uint256 expectedAmountInterimAsset, bytes4 rebalanceToSelector)
func (_SuperformRouterPlus *SuperformRouterPlusFilterer) ParseXChainRebalanceMultiInitiated(log types.Log) (*SuperformRouterPlusXChainRebalanceMultiInitiated, error) {
	event := new(SuperformRouterPlusXChainRebalanceMultiInitiated)
	if err := _SuperformRouterPlus.contract.UnpackLog(event, "XChainRebalanceMultiInitiated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
