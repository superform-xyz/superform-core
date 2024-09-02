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

// InitSingleVaultData is an auto generated low-level Go binding around an user-defined struct.
type InitSingleVaultData struct {
	PayloadId       *big.Int
	SuperformId     *big.Int
	Amount          *big.Int
	OutputAmount    *big.Int
	MaxSlippage     *big.Int
	LiqData         LiqRequest
	HasDstSwap      bool
	Retain4626      bool
	ReceiverAddress common.Address
	ExtraFormData   []byte
}

// LiqRequest is an auto generated low-level Go binding around an user-defined struct.
type LiqRequest struct {
	TxData        []byte
	Token         common.Address
	InterimToken  common.Address
	BridgeId      uint8
	LiqDstChainId uint64
	NativeAmount  *big.Int
}

// ERC4626FormMetaData contains all meta data concerning the ERC4626Form contract.
var ERC4626FormMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superRegistry_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"CHAIN_ID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"asset\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"directDepositIntoVault\",\"inputs\":[{\"name\":\"singleVaultData_\",\"type\":\"tuple\",\"internalType\":\"structInitSingleVaultData\",\"components\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqData\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"srcSender_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"directWithdrawFromVault\",\"inputs\":[{\"name\":\"singleVaultData_\",\"type\":\"tuple\",\"internalType\":\"structInitSingleVaultData\",\"components\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqData\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"srcSender_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"emergencyWithdraw\",\"inputs\":[{\"name\":\"receiverAddress_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"amount_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"forwardDustToPaymaster\",\"inputs\":[{\"name\":\"token_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getPreviewPricePerVaultShare\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getPricePerVaultShare\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStateRegistryId\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint8\",\"internalType\":\"uint8\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTotalAssets\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getTotalSupply\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVaultAddress\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVaultAsset\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVaultDecimals\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVaultName\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVaultShareBalance\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getVaultSymbol\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"initialize\",\"inputs\":[{\"name\":\"superRegistry_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"vault_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"asset_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"previewDepositTo\",\"inputs\":[{\"name\":\"assets_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewRedeemFrom\",\"inputs\":[{\"name\":\"shares_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"previewWithdrawFrom\",\"inputs\":[{\"name\":\"assets_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"superRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperRegistry\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"superformYieldTokenName\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"superformYieldTokenSymbol\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId_\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"vault\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"xChainDepositIntoVault\",\"inputs\":[{\"name\":\"singleVaultData_\",\"type\":\"tuple\",\"internalType\":\"structInitSingleVaultData\",\"components\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqData\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"srcSender_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"srcChainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"shares\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"xChainWithdrawFromVault\",\"inputs\":[{\"name\":\"singleVaultData_\",\"type\":\"tuple\",\"internalType\":\"structInitSingleVaultData\",\"components\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqData\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]},{\"name\":\"srcSender_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"srcChainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"outputs\":[{\"name\":\"assets\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"EmergencyWithdrawalProcessed\",\"inputs\":[{\"name\":\"refundAddress\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"FormDustForwardedToPaymaster\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Initialized\",\"inputs\":[{\"name\":\"version\",\"type\":\"uint64\",\"indexed\":false,\"internalType\":\"uint64\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Processed\",\"inputs\":[{\"name\":\"srcChainID\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"srcPayloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"vault\",\"type\":\"address\",\"indexed\":false,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"VaultAdded\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"vault\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"contractIERC4626\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AddressEmptyCode\",\"inputs\":[{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"AddressInsufficientBalance\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"BLOCK_CHAIN_ID_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CANNOT_FORWARD_4646_TOKEN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DIFFERENT_TOKENS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DIRECT_DEPOSIT_SWAP_FAILED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DIRECT_WITHDRAW_INVALID_LIQ_REQUEST\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"FAILED_TO_EXECUTE_TXDATA\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"FailedInnerCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_BALANCE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_NATIVE_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_CHAIN_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"InvalidInitialization\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_CORE_STATE_REGISTRY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_EMERGENCY_QUEUE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_SUPERFORM_ROUTER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_SUPER_REGISTRY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotInitializing\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PAUSED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SUPERFORM_ID_NONEXISTENT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"VAULT_IMPLEMENTATION_FAILED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"WITHDRAW_TOKEN_NOT_UPDATED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"WITHDRAW_TX_DATA_NOT_UPDATED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"WITHDRAW_ZERO_COLLATERAL\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_AMOUNT\",\"inputs\":[]}]",
}

// ERC4626FormABI is the input ABI used to generate the binding from.
// Deprecated: Use ERC4626FormMetaData.ABI instead.
var ERC4626FormABI = ERC4626FormMetaData.ABI

// ERC4626Form is an auto generated Go binding around an Ethereum contract.
type ERC4626Form struct {
	ERC4626FormCaller     // Read-only binding to the contract
	ERC4626FormTransactor // Write-only binding to the contract
	ERC4626FormFilterer   // Log filterer for contract events
}

// ERC4626FormCaller is an auto generated read-only Go binding around an Ethereum contract.
type ERC4626FormCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ERC4626FormTransactor is an auto generated write-only Go binding around an Ethereum contract.
type ERC4626FormTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ERC4626FormFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type ERC4626FormFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// ERC4626FormSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type ERC4626FormSession struct {
	Contract     *ERC4626Form      // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// ERC4626FormCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type ERC4626FormCallerSession struct {
	Contract *ERC4626FormCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts      // Call options to use throughout this session
}

// ERC4626FormTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type ERC4626FormTransactorSession struct {
	Contract     *ERC4626FormTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts      // Transaction auth options to use throughout this session
}

// ERC4626FormRaw is an auto generated low-level Go binding around an Ethereum contract.
type ERC4626FormRaw struct {
	Contract *ERC4626Form // Generic contract binding to access the raw methods on
}

// ERC4626FormCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type ERC4626FormCallerRaw struct {
	Contract *ERC4626FormCaller // Generic read-only contract binding to access the raw methods on
}

// ERC4626FormTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type ERC4626FormTransactorRaw struct {
	Contract *ERC4626FormTransactor // Generic write-only contract binding to access the raw methods on
}

// NewERC4626Form creates a new instance of ERC4626Form, bound to a specific deployed contract.
func NewERC4626Form(address common.Address, backend bind.ContractBackend) (*ERC4626Form, error) {
	contract, err := bindERC4626Form(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &ERC4626Form{ERC4626FormCaller: ERC4626FormCaller{contract: contract}, ERC4626FormTransactor: ERC4626FormTransactor{contract: contract}, ERC4626FormFilterer: ERC4626FormFilterer{contract: contract}}, nil
}

// NewERC4626FormCaller creates a new read-only instance of ERC4626Form, bound to a specific deployed contract.
func NewERC4626FormCaller(address common.Address, caller bind.ContractCaller) (*ERC4626FormCaller, error) {
	contract, err := bindERC4626Form(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &ERC4626FormCaller{contract: contract}, nil
}

// NewERC4626FormTransactor creates a new write-only instance of ERC4626Form, bound to a specific deployed contract.
func NewERC4626FormTransactor(address common.Address, transactor bind.ContractTransactor) (*ERC4626FormTransactor, error) {
	contract, err := bindERC4626Form(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &ERC4626FormTransactor{contract: contract}, nil
}

// NewERC4626FormFilterer creates a new log filterer instance of ERC4626Form, bound to a specific deployed contract.
func NewERC4626FormFilterer(address common.Address, filterer bind.ContractFilterer) (*ERC4626FormFilterer, error) {
	contract, err := bindERC4626Form(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &ERC4626FormFilterer{contract: contract}, nil
}

// bindERC4626Form binds a generic wrapper to an already deployed contract.
func bindERC4626Form(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := ERC4626FormMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ERC4626Form *ERC4626FormRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ERC4626Form.Contract.ERC4626FormCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ERC4626Form *ERC4626FormRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ERC4626Form.Contract.ERC4626FormTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ERC4626Form *ERC4626FormRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ERC4626Form.Contract.ERC4626FormTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_ERC4626Form *ERC4626FormCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _ERC4626Form.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_ERC4626Form *ERC4626FormTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _ERC4626Form.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_ERC4626Form *ERC4626FormTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _ERC4626Form.Contract.contract.Transact(opts, method, params...)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_ERC4626Form *ERC4626FormCaller) CHAINID(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "CHAIN_ID")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_ERC4626Form *ERC4626FormSession) CHAINID() (uint64, error) {
	return _ERC4626Form.Contract.CHAINID(&_ERC4626Form.CallOpts)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_ERC4626Form *ERC4626FormCallerSession) CHAINID() (uint64, error) {
	return _ERC4626Form.Contract.CHAINID(&_ERC4626Form.CallOpts)
}

// Asset is a free data retrieval call binding the contract method 0x38d52e0f.
//
// Solidity: function asset() view returns(address)
func (_ERC4626Form *ERC4626FormCaller) Asset(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "asset")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Asset is a free data retrieval call binding the contract method 0x38d52e0f.
//
// Solidity: function asset() view returns(address)
func (_ERC4626Form *ERC4626FormSession) Asset() (common.Address, error) {
	return _ERC4626Form.Contract.Asset(&_ERC4626Form.CallOpts)
}

// Asset is a free data retrieval call binding the contract method 0x38d52e0f.
//
// Solidity: function asset() view returns(address)
func (_ERC4626Form *ERC4626FormCallerSession) Asset() (common.Address, error) {
	return _ERC4626Form.Contract.Asset(&_ERC4626Form.CallOpts)
}

// GetPreviewPricePerVaultShare is a free data retrieval call binding the contract method 0x38d92fd5.
//
// Solidity: function getPreviewPricePerVaultShare() view returns(uint256)
func (_ERC4626Form *ERC4626FormCaller) GetPreviewPricePerVaultShare(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "getPreviewPricePerVaultShare")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetPreviewPricePerVaultShare is a free data retrieval call binding the contract method 0x38d92fd5.
//
// Solidity: function getPreviewPricePerVaultShare() view returns(uint256)
func (_ERC4626Form *ERC4626FormSession) GetPreviewPricePerVaultShare() (*big.Int, error) {
	return _ERC4626Form.Contract.GetPreviewPricePerVaultShare(&_ERC4626Form.CallOpts)
}

// GetPreviewPricePerVaultShare is a free data retrieval call binding the contract method 0x38d92fd5.
//
// Solidity: function getPreviewPricePerVaultShare() view returns(uint256)
func (_ERC4626Form *ERC4626FormCallerSession) GetPreviewPricePerVaultShare() (*big.Int, error) {
	return _ERC4626Form.Contract.GetPreviewPricePerVaultShare(&_ERC4626Form.CallOpts)
}

// GetPricePerVaultShare is a free data retrieval call binding the contract method 0xff5f3e48.
//
// Solidity: function getPricePerVaultShare() view returns(uint256)
func (_ERC4626Form *ERC4626FormCaller) GetPricePerVaultShare(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "getPricePerVaultShare")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetPricePerVaultShare is a free data retrieval call binding the contract method 0xff5f3e48.
//
// Solidity: function getPricePerVaultShare() view returns(uint256)
func (_ERC4626Form *ERC4626FormSession) GetPricePerVaultShare() (*big.Int, error) {
	return _ERC4626Form.Contract.GetPricePerVaultShare(&_ERC4626Form.CallOpts)
}

// GetPricePerVaultShare is a free data retrieval call binding the contract method 0xff5f3e48.
//
// Solidity: function getPricePerVaultShare() view returns(uint256)
func (_ERC4626Form *ERC4626FormCallerSession) GetPricePerVaultShare() (*big.Int, error) {
	return _ERC4626Form.Contract.GetPricePerVaultShare(&_ERC4626Form.CallOpts)
}

// GetStateRegistryId is a free data retrieval call binding the contract method 0x91deb882.
//
// Solidity: function getStateRegistryId() view returns(uint8)
func (_ERC4626Form *ERC4626FormCaller) GetStateRegistryId(opts *bind.CallOpts) (uint8, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "getStateRegistryId")

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// GetStateRegistryId is a free data retrieval call binding the contract method 0x91deb882.
//
// Solidity: function getStateRegistryId() view returns(uint8)
func (_ERC4626Form *ERC4626FormSession) GetStateRegistryId() (uint8, error) {
	return _ERC4626Form.Contract.GetStateRegistryId(&_ERC4626Form.CallOpts)
}

// GetStateRegistryId is a free data retrieval call binding the contract method 0x91deb882.
//
// Solidity: function getStateRegistryId() view returns(uint8)
func (_ERC4626Form *ERC4626FormCallerSession) GetStateRegistryId() (uint8, error) {
	return _ERC4626Form.Contract.GetStateRegistryId(&_ERC4626Form.CallOpts)
}

// GetTotalAssets is a free data retrieval call binding the contract method 0x6e07302b.
//
// Solidity: function getTotalAssets() view returns(uint256)
func (_ERC4626Form *ERC4626FormCaller) GetTotalAssets(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "getTotalAssets")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetTotalAssets is a free data retrieval call binding the contract method 0x6e07302b.
//
// Solidity: function getTotalAssets() view returns(uint256)
func (_ERC4626Form *ERC4626FormSession) GetTotalAssets() (*big.Int, error) {
	return _ERC4626Form.Contract.GetTotalAssets(&_ERC4626Form.CallOpts)
}

// GetTotalAssets is a free data retrieval call binding the contract method 0x6e07302b.
//
// Solidity: function getTotalAssets() view returns(uint256)
func (_ERC4626Form *ERC4626FormCallerSession) GetTotalAssets() (*big.Int, error) {
	return _ERC4626Form.Contract.GetTotalAssets(&_ERC4626Form.CallOpts)
}

// GetTotalSupply is a free data retrieval call binding the contract method 0xc4e41b22.
//
// Solidity: function getTotalSupply() view returns(uint256)
func (_ERC4626Form *ERC4626FormCaller) GetTotalSupply(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "getTotalSupply")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetTotalSupply is a free data retrieval call binding the contract method 0xc4e41b22.
//
// Solidity: function getTotalSupply() view returns(uint256)
func (_ERC4626Form *ERC4626FormSession) GetTotalSupply() (*big.Int, error) {
	return _ERC4626Form.Contract.GetTotalSupply(&_ERC4626Form.CallOpts)
}

// GetTotalSupply is a free data retrieval call binding the contract method 0xc4e41b22.
//
// Solidity: function getTotalSupply() view returns(uint256)
func (_ERC4626Form *ERC4626FormCallerSession) GetTotalSupply() (*big.Int, error) {
	return _ERC4626Form.Contract.GetTotalSupply(&_ERC4626Form.CallOpts)
}

// GetVaultAddress is a free data retrieval call binding the contract method 0x65cacaa4.
//
// Solidity: function getVaultAddress() view returns(address)
func (_ERC4626Form *ERC4626FormCaller) GetVaultAddress(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "getVaultAddress")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetVaultAddress is a free data retrieval call binding the contract method 0x65cacaa4.
//
// Solidity: function getVaultAddress() view returns(address)
func (_ERC4626Form *ERC4626FormSession) GetVaultAddress() (common.Address, error) {
	return _ERC4626Form.Contract.GetVaultAddress(&_ERC4626Form.CallOpts)
}

// GetVaultAddress is a free data retrieval call binding the contract method 0x65cacaa4.
//
// Solidity: function getVaultAddress() view returns(address)
func (_ERC4626Form *ERC4626FormCallerSession) GetVaultAddress() (common.Address, error) {
	return _ERC4626Form.Contract.GetVaultAddress(&_ERC4626Form.CallOpts)
}

// GetVaultAsset is a free data retrieval call binding the contract method 0xb60262ca.
//
// Solidity: function getVaultAsset() view returns(address)
func (_ERC4626Form *ERC4626FormCaller) GetVaultAsset(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "getVaultAsset")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetVaultAsset is a free data retrieval call binding the contract method 0xb60262ca.
//
// Solidity: function getVaultAsset() view returns(address)
func (_ERC4626Form *ERC4626FormSession) GetVaultAsset() (common.Address, error) {
	return _ERC4626Form.Contract.GetVaultAsset(&_ERC4626Form.CallOpts)
}

// GetVaultAsset is a free data retrieval call binding the contract method 0xb60262ca.
//
// Solidity: function getVaultAsset() view returns(address)
func (_ERC4626Form *ERC4626FormCallerSession) GetVaultAsset() (common.Address, error) {
	return _ERC4626Form.Contract.GetVaultAsset(&_ERC4626Form.CallOpts)
}

// GetVaultDecimals is a free data retrieval call binding the contract method 0xc32dcd89.
//
// Solidity: function getVaultDecimals() view returns(uint256)
func (_ERC4626Form *ERC4626FormCaller) GetVaultDecimals(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "getVaultDecimals")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetVaultDecimals is a free data retrieval call binding the contract method 0xc32dcd89.
//
// Solidity: function getVaultDecimals() view returns(uint256)
func (_ERC4626Form *ERC4626FormSession) GetVaultDecimals() (*big.Int, error) {
	return _ERC4626Form.Contract.GetVaultDecimals(&_ERC4626Form.CallOpts)
}

// GetVaultDecimals is a free data retrieval call binding the contract method 0xc32dcd89.
//
// Solidity: function getVaultDecimals() view returns(uint256)
func (_ERC4626Form *ERC4626FormCallerSession) GetVaultDecimals() (*big.Int, error) {
	return _ERC4626Form.Contract.GetVaultDecimals(&_ERC4626Form.CallOpts)
}

// GetVaultName is a free data retrieval call binding the contract method 0x9f5376c1.
//
// Solidity: function getVaultName() view returns(string)
func (_ERC4626Form *ERC4626FormCaller) GetVaultName(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "getVaultName")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// GetVaultName is a free data retrieval call binding the contract method 0x9f5376c1.
//
// Solidity: function getVaultName() view returns(string)
func (_ERC4626Form *ERC4626FormSession) GetVaultName() (string, error) {
	return _ERC4626Form.Contract.GetVaultName(&_ERC4626Form.CallOpts)
}

// GetVaultName is a free data retrieval call binding the contract method 0x9f5376c1.
//
// Solidity: function getVaultName() view returns(string)
func (_ERC4626Form *ERC4626FormCallerSession) GetVaultName() (string, error) {
	return _ERC4626Form.Contract.GetVaultName(&_ERC4626Form.CallOpts)
}

// GetVaultShareBalance is a free data retrieval call binding the contract method 0x35eda680.
//
// Solidity: function getVaultShareBalance() view returns(uint256)
func (_ERC4626Form *ERC4626FormCaller) GetVaultShareBalance(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "getVaultShareBalance")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetVaultShareBalance is a free data retrieval call binding the contract method 0x35eda680.
//
// Solidity: function getVaultShareBalance() view returns(uint256)
func (_ERC4626Form *ERC4626FormSession) GetVaultShareBalance() (*big.Int, error) {
	return _ERC4626Form.Contract.GetVaultShareBalance(&_ERC4626Form.CallOpts)
}

// GetVaultShareBalance is a free data retrieval call binding the contract method 0x35eda680.
//
// Solidity: function getVaultShareBalance() view returns(uint256)
func (_ERC4626Form *ERC4626FormCallerSession) GetVaultShareBalance() (*big.Int, error) {
	return _ERC4626Form.Contract.GetVaultShareBalance(&_ERC4626Form.CallOpts)
}

// GetVaultSymbol is a free data retrieval call binding the contract method 0x77188067.
//
// Solidity: function getVaultSymbol() view returns(string)
func (_ERC4626Form *ERC4626FormCaller) GetVaultSymbol(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "getVaultSymbol")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// GetVaultSymbol is a free data retrieval call binding the contract method 0x77188067.
//
// Solidity: function getVaultSymbol() view returns(string)
func (_ERC4626Form *ERC4626FormSession) GetVaultSymbol() (string, error) {
	return _ERC4626Form.Contract.GetVaultSymbol(&_ERC4626Form.CallOpts)
}

// GetVaultSymbol is a free data retrieval call binding the contract method 0x77188067.
//
// Solidity: function getVaultSymbol() view returns(string)
func (_ERC4626Form *ERC4626FormCallerSession) GetVaultSymbol() (string, error) {
	return _ERC4626Form.Contract.GetVaultSymbol(&_ERC4626Form.CallOpts)
}

// PreviewDepositTo is a free data retrieval call binding the contract method 0x07c080f9.
//
// Solidity: function previewDepositTo(uint256 assets_) view returns(uint256)
func (_ERC4626Form *ERC4626FormCaller) PreviewDepositTo(opts *bind.CallOpts, assets_ *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "previewDepositTo", assets_)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PreviewDepositTo is a free data retrieval call binding the contract method 0x07c080f9.
//
// Solidity: function previewDepositTo(uint256 assets_) view returns(uint256)
func (_ERC4626Form *ERC4626FormSession) PreviewDepositTo(assets_ *big.Int) (*big.Int, error) {
	return _ERC4626Form.Contract.PreviewDepositTo(&_ERC4626Form.CallOpts, assets_)
}

// PreviewDepositTo is a free data retrieval call binding the contract method 0x07c080f9.
//
// Solidity: function previewDepositTo(uint256 assets_) view returns(uint256)
func (_ERC4626Form *ERC4626FormCallerSession) PreviewDepositTo(assets_ *big.Int) (*big.Int, error) {
	return _ERC4626Form.Contract.PreviewDepositTo(&_ERC4626Form.CallOpts, assets_)
}

// PreviewRedeemFrom is a free data retrieval call binding the contract method 0xb7ba28cd.
//
// Solidity: function previewRedeemFrom(uint256 shares_) view returns(uint256)
func (_ERC4626Form *ERC4626FormCaller) PreviewRedeemFrom(opts *bind.CallOpts, shares_ *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "previewRedeemFrom", shares_)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PreviewRedeemFrom is a free data retrieval call binding the contract method 0xb7ba28cd.
//
// Solidity: function previewRedeemFrom(uint256 shares_) view returns(uint256)
func (_ERC4626Form *ERC4626FormSession) PreviewRedeemFrom(shares_ *big.Int) (*big.Int, error) {
	return _ERC4626Form.Contract.PreviewRedeemFrom(&_ERC4626Form.CallOpts, shares_)
}

// PreviewRedeemFrom is a free data retrieval call binding the contract method 0xb7ba28cd.
//
// Solidity: function previewRedeemFrom(uint256 shares_) view returns(uint256)
func (_ERC4626Form *ERC4626FormCallerSession) PreviewRedeemFrom(shares_ *big.Int) (*big.Int, error) {
	return _ERC4626Form.Contract.PreviewRedeemFrom(&_ERC4626Form.CallOpts, shares_)
}

// PreviewWithdrawFrom is a free data retrieval call binding the contract method 0x37d25010.
//
// Solidity: function previewWithdrawFrom(uint256 assets_) view returns(uint256)
func (_ERC4626Form *ERC4626FormCaller) PreviewWithdrawFrom(opts *bind.CallOpts, assets_ *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "previewWithdrawFrom", assets_)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PreviewWithdrawFrom is a free data retrieval call binding the contract method 0x37d25010.
//
// Solidity: function previewWithdrawFrom(uint256 assets_) view returns(uint256)
func (_ERC4626Form *ERC4626FormSession) PreviewWithdrawFrom(assets_ *big.Int) (*big.Int, error) {
	return _ERC4626Form.Contract.PreviewWithdrawFrom(&_ERC4626Form.CallOpts, assets_)
}

// PreviewWithdrawFrom is a free data retrieval call binding the contract method 0x37d25010.
//
// Solidity: function previewWithdrawFrom(uint256 assets_) view returns(uint256)
func (_ERC4626Form *ERC4626FormCallerSession) PreviewWithdrawFrom(assets_ *big.Int) (*big.Int, error) {
	return _ERC4626Form.Contract.PreviewWithdrawFrom(&_ERC4626Form.CallOpts, assets_)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_ERC4626Form *ERC4626FormCaller) SuperRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "superRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_ERC4626Form *ERC4626FormSession) SuperRegistry() (common.Address, error) {
	return _ERC4626Form.Contract.SuperRegistry(&_ERC4626Form.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_ERC4626Form *ERC4626FormCallerSession) SuperRegistry() (common.Address, error) {
	return _ERC4626Form.Contract.SuperRegistry(&_ERC4626Form.CallOpts)
}

// SuperformYieldTokenName is a free data retrieval call binding the contract method 0x20592d98.
//
// Solidity: function superformYieldTokenName() view returns(string)
func (_ERC4626Form *ERC4626FormCaller) SuperformYieldTokenName(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "superformYieldTokenName")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// SuperformYieldTokenName is a free data retrieval call binding the contract method 0x20592d98.
//
// Solidity: function superformYieldTokenName() view returns(string)
func (_ERC4626Form *ERC4626FormSession) SuperformYieldTokenName() (string, error) {
	return _ERC4626Form.Contract.SuperformYieldTokenName(&_ERC4626Form.CallOpts)
}

// SuperformYieldTokenName is a free data retrieval call binding the contract method 0x20592d98.
//
// Solidity: function superformYieldTokenName() view returns(string)
func (_ERC4626Form *ERC4626FormCallerSession) SuperformYieldTokenName() (string, error) {
	return _ERC4626Form.Contract.SuperformYieldTokenName(&_ERC4626Form.CallOpts)
}

// SuperformYieldTokenSymbol is a free data retrieval call binding the contract method 0x17a57e08.
//
// Solidity: function superformYieldTokenSymbol() view returns(string)
func (_ERC4626Form *ERC4626FormCaller) SuperformYieldTokenSymbol(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "superformYieldTokenSymbol")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// SuperformYieldTokenSymbol is a free data retrieval call binding the contract method 0x17a57e08.
//
// Solidity: function superformYieldTokenSymbol() view returns(string)
func (_ERC4626Form *ERC4626FormSession) SuperformYieldTokenSymbol() (string, error) {
	return _ERC4626Form.Contract.SuperformYieldTokenSymbol(&_ERC4626Form.CallOpts)
}

// SuperformYieldTokenSymbol is a free data retrieval call binding the contract method 0x17a57e08.
//
// Solidity: function superformYieldTokenSymbol() view returns(string)
func (_ERC4626Form *ERC4626FormCallerSession) SuperformYieldTokenSymbol() (string, error) {
	return _ERC4626Form.Contract.SuperformYieldTokenSymbol(&_ERC4626Form.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId_) view returns(bool)
func (_ERC4626Form *ERC4626FormCaller) SupportsInterface(opts *bind.CallOpts, interfaceId_ [4]byte) (bool, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "supportsInterface", interfaceId_)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId_) view returns(bool)
func (_ERC4626Form *ERC4626FormSession) SupportsInterface(interfaceId_ [4]byte) (bool, error) {
	return _ERC4626Form.Contract.SupportsInterface(&_ERC4626Form.CallOpts, interfaceId_)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId_) view returns(bool)
func (_ERC4626Form *ERC4626FormCallerSession) SupportsInterface(interfaceId_ [4]byte) (bool, error) {
	return _ERC4626Form.Contract.SupportsInterface(&_ERC4626Form.CallOpts, interfaceId_)
}

// Vault is a free data retrieval call binding the contract method 0xfbfa77cf.
//
// Solidity: function vault() view returns(address)
func (_ERC4626Form *ERC4626FormCaller) Vault(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _ERC4626Form.contract.Call(opts, &out, "vault")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Vault is a free data retrieval call binding the contract method 0xfbfa77cf.
//
// Solidity: function vault() view returns(address)
func (_ERC4626Form *ERC4626FormSession) Vault() (common.Address, error) {
	return _ERC4626Form.Contract.Vault(&_ERC4626Form.CallOpts)
}

// Vault is a free data retrieval call binding the contract method 0xfbfa77cf.
//
// Solidity: function vault() view returns(address)
func (_ERC4626Form *ERC4626FormCallerSession) Vault() (common.Address, error) {
	return _ERC4626Form.Contract.Vault(&_ERC4626Form.CallOpts)
}

// DirectDepositIntoVault is a paid mutator transaction binding the contract method 0xb9232775.
//
// Solidity: function directDepositIntoVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_) payable returns(uint256 shares)
func (_ERC4626Form *ERC4626FormTransactor) DirectDepositIntoVault(opts *bind.TransactOpts, singleVaultData_ InitSingleVaultData, srcSender_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.contract.Transact(opts, "directDepositIntoVault", singleVaultData_, srcSender_)
}

// DirectDepositIntoVault is a paid mutator transaction binding the contract method 0xb9232775.
//
// Solidity: function directDepositIntoVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_) payable returns(uint256 shares)
func (_ERC4626Form *ERC4626FormSession) DirectDepositIntoVault(singleVaultData_ InitSingleVaultData, srcSender_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.Contract.DirectDepositIntoVault(&_ERC4626Form.TransactOpts, singleVaultData_, srcSender_)
}

// DirectDepositIntoVault is a paid mutator transaction binding the contract method 0xb9232775.
//
// Solidity: function directDepositIntoVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_) payable returns(uint256 shares)
func (_ERC4626Form *ERC4626FormTransactorSession) DirectDepositIntoVault(singleVaultData_ InitSingleVaultData, srcSender_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.Contract.DirectDepositIntoVault(&_ERC4626Form.TransactOpts, singleVaultData_, srcSender_)
}

// DirectWithdrawFromVault is a paid mutator transaction binding the contract method 0xcb829dc3.
//
// Solidity: function directWithdrawFromVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_) returns(uint256 assets)
func (_ERC4626Form *ERC4626FormTransactor) DirectWithdrawFromVault(opts *bind.TransactOpts, singleVaultData_ InitSingleVaultData, srcSender_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.contract.Transact(opts, "directWithdrawFromVault", singleVaultData_, srcSender_)
}

// DirectWithdrawFromVault is a paid mutator transaction binding the contract method 0xcb829dc3.
//
// Solidity: function directWithdrawFromVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_) returns(uint256 assets)
func (_ERC4626Form *ERC4626FormSession) DirectWithdrawFromVault(singleVaultData_ InitSingleVaultData, srcSender_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.Contract.DirectWithdrawFromVault(&_ERC4626Form.TransactOpts, singleVaultData_, srcSender_)
}

// DirectWithdrawFromVault is a paid mutator transaction binding the contract method 0xcb829dc3.
//
// Solidity: function directWithdrawFromVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_) returns(uint256 assets)
func (_ERC4626Form *ERC4626FormTransactorSession) DirectWithdrawFromVault(singleVaultData_ InitSingleVaultData, srcSender_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.Contract.DirectWithdrawFromVault(&_ERC4626Form.TransactOpts, singleVaultData_, srcSender_)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address receiverAddress_, uint256 amount_) returns()
func (_ERC4626Form *ERC4626FormTransactor) EmergencyWithdraw(opts *bind.TransactOpts, receiverAddress_ common.Address, amount_ *big.Int) (*types.Transaction, error) {
	return _ERC4626Form.contract.Transact(opts, "emergencyWithdraw", receiverAddress_, amount_)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address receiverAddress_, uint256 amount_) returns()
func (_ERC4626Form *ERC4626FormSession) EmergencyWithdraw(receiverAddress_ common.Address, amount_ *big.Int) (*types.Transaction, error) {
	return _ERC4626Form.Contract.EmergencyWithdraw(&_ERC4626Form.TransactOpts, receiverAddress_, amount_)
}

// EmergencyWithdraw is a paid mutator transaction binding the contract method 0x95ccea67.
//
// Solidity: function emergencyWithdraw(address receiverAddress_, uint256 amount_) returns()
func (_ERC4626Form *ERC4626FormTransactorSession) EmergencyWithdraw(receiverAddress_ common.Address, amount_ *big.Int) (*types.Transaction, error) {
	return _ERC4626Form.Contract.EmergencyWithdraw(&_ERC4626Form.TransactOpts, receiverAddress_, amount_)
}

// ForwardDustToPaymaster is a paid mutator transaction binding the contract method 0x4dcd03c0.
//
// Solidity: function forwardDustToPaymaster(address token_) returns()
func (_ERC4626Form *ERC4626FormTransactor) ForwardDustToPaymaster(opts *bind.TransactOpts, token_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.contract.Transact(opts, "forwardDustToPaymaster", token_)
}

// ForwardDustToPaymaster is a paid mutator transaction binding the contract method 0x4dcd03c0.
//
// Solidity: function forwardDustToPaymaster(address token_) returns()
func (_ERC4626Form *ERC4626FormSession) ForwardDustToPaymaster(token_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.Contract.ForwardDustToPaymaster(&_ERC4626Form.TransactOpts, token_)
}

// ForwardDustToPaymaster is a paid mutator transaction binding the contract method 0x4dcd03c0.
//
// Solidity: function forwardDustToPaymaster(address token_) returns()
func (_ERC4626Form *ERC4626FormTransactorSession) ForwardDustToPaymaster(token_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.Contract.ForwardDustToPaymaster(&_ERC4626Form.TransactOpts, token_)
}

// Initialize is a paid mutator transaction binding the contract method 0xc0c53b8b.
//
// Solidity: function initialize(address superRegistry_, address vault_, address asset_) returns()
func (_ERC4626Form *ERC4626FormTransactor) Initialize(opts *bind.TransactOpts, superRegistry_ common.Address, vault_ common.Address, asset_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.contract.Transact(opts, "initialize", superRegistry_, vault_, asset_)
}

// Initialize is a paid mutator transaction binding the contract method 0xc0c53b8b.
//
// Solidity: function initialize(address superRegistry_, address vault_, address asset_) returns()
func (_ERC4626Form *ERC4626FormSession) Initialize(superRegistry_ common.Address, vault_ common.Address, asset_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.Contract.Initialize(&_ERC4626Form.TransactOpts, superRegistry_, vault_, asset_)
}

// Initialize is a paid mutator transaction binding the contract method 0xc0c53b8b.
//
// Solidity: function initialize(address superRegistry_, address vault_, address asset_) returns()
func (_ERC4626Form *ERC4626FormTransactorSession) Initialize(superRegistry_ common.Address, vault_ common.Address, asset_ common.Address) (*types.Transaction, error) {
	return _ERC4626Form.Contract.Initialize(&_ERC4626Form.TransactOpts, superRegistry_, vault_, asset_)
}

// XChainDepositIntoVault is a paid mutator transaction binding the contract method 0x95e4f1da.
//
// Solidity: function xChainDepositIntoVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_, uint64 srcChainId_) returns(uint256 shares)
func (_ERC4626Form *ERC4626FormTransactor) XChainDepositIntoVault(opts *bind.TransactOpts, singleVaultData_ InitSingleVaultData, srcSender_ common.Address, srcChainId_ uint64) (*types.Transaction, error) {
	return _ERC4626Form.contract.Transact(opts, "xChainDepositIntoVault", singleVaultData_, srcSender_, srcChainId_)
}

// XChainDepositIntoVault is a paid mutator transaction binding the contract method 0x95e4f1da.
//
// Solidity: function xChainDepositIntoVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_, uint64 srcChainId_) returns(uint256 shares)
func (_ERC4626Form *ERC4626FormSession) XChainDepositIntoVault(singleVaultData_ InitSingleVaultData, srcSender_ common.Address, srcChainId_ uint64) (*types.Transaction, error) {
	return _ERC4626Form.Contract.XChainDepositIntoVault(&_ERC4626Form.TransactOpts, singleVaultData_, srcSender_, srcChainId_)
}

// XChainDepositIntoVault is a paid mutator transaction binding the contract method 0x95e4f1da.
//
// Solidity: function xChainDepositIntoVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_, uint64 srcChainId_) returns(uint256 shares)
func (_ERC4626Form *ERC4626FormTransactorSession) XChainDepositIntoVault(singleVaultData_ InitSingleVaultData, srcSender_ common.Address, srcChainId_ uint64) (*types.Transaction, error) {
	return _ERC4626Form.Contract.XChainDepositIntoVault(&_ERC4626Form.TransactOpts, singleVaultData_, srcSender_, srcChainId_)
}

// XChainWithdrawFromVault is a paid mutator transaction binding the contract method 0xef164fef.
//
// Solidity: function xChainWithdrawFromVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_, uint64 srcChainId_) returns(uint256 assets)
func (_ERC4626Form *ERC4626FormTransactor) XChainWithdrawFromVault(opts *bind.TransactOpts, singleVaultData_ InitSingleVaultData, srcSender_ common.Address, srcChainId_ uint64) (*types.Transaction, error) {
	return _ERC4626Form.contract.Transact(opts, "xChainWithdrawFromVault", singleVaultData_, srcSender_, srcChainId_)
}

// XChainWithdrawFromVault is a paid mutator transaction binding the contract method 0xef164fef.
//
// Solidity: function xChainWithdrawFromVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_, uint64 srcChainId_) returns(uint256 assets)
func (_ERC4626Form *ERC4626FormSession) XChainWithdrawFromVault(singleVaultData_ InitSingleVaultData, srcSender_ common.Address, srcChainId_ uint64) (*types.Transaction, error) {
	return _ERC4626Form.Contract.XChainWithdrawFromVault(&_ERC4626Form.TransactOpts, singleVaultData_, srcSender_, srcChainId_)
}

// XChainWithdrawFromVault is a paid mutator transaction binding the contract method 0xef164fef.
//
// Solidity: function xChainWithdrawFromVault((uint256,uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bool,bool,address,bytes) singleVaultData_, address srcSender_, uint64 srcChainId_) returns(uint256 assets)
func (_ERC4626Form *ERC4626FormTransactorSession) XChainWithdrawFromVault(singleVaultData_ InitSingleVaultData, srcSender_ common.Address, srcChainId_ uint64) (*types.Transaction, error) {
	return _ERC4626Form.Contract.XChainWithdrawFromVault(&_ERC4626Form.TransactOpts, singleVaultData_, srcSender_, srcChainId_)
}

// ERC4626FormEmergencyWithdrawalProcessedIterator is returned from FilterEmergencyWithdrawalProcessed and is used to iterate over the raw logs and unpacked data for EmergencyWithdrawalProcessed events raised by the ERC4626Form contract.
type ERC4626FormEmergencyWithdrawalProcessedIterator struct {
	Event *ERC4626FormEmergencyWithdrawalProcessed // Event containing the contract specifics and raw log

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
func (it *ERC4626FormEmergencyWithdrawalProcessedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626FormEmergencyWithdrawalProcessed)
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
		it.Event = new(ERC4626FormEmergencyWithdrawalProcessed)
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
func (it *ERC4626FormEmergencyWithdrawalProcessedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626FormEmergencyWithdrawalProcessedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626FormEmergencyWithdrawalProcessed represents a EmergencyWithdrawalProcessed event raised by the ERC4626Form contract.
type ERC4626FormEmergencyWithdrawalProcessed struct {
	RefundAddress common.Address
	Amount        *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterEmergencyWithdrawalProcessed is a free log retrieval operation binding the contract event 0x83b8068554a495dbb4af07014f8171144d6670eb522b356f8d3f37cbd76ba116.
//
// Solidity: event EmergencyWithdrawalProcessed(address indexed refundAddress, uint256 indexed amount)
func (_ERC4626Form *ERC4626FormFilterer) FilterEmergencyWithdrawalProcessed(opts *bind.FilterOpts, refundAddress []common.Address, amount []*big.Int) (*ERC4626FormEmergencyWithdrawalProcessedIterator, error) {

	var refundAddressRule []interface{}
	for _, refundAddressItem := range refundAddress {
		refundAddressRule = append(refundAddressRule, refundAddressItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _ERC4626Form.contract.FilterLogs(opts, "EmergencyWithdrawalProcessed", refundAddressRule, amountRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626FormEmergencyWithdrawalProcessedIterator{contract: _ERC4626Form.contract, event: "EmergencyWithdrawalProcessed", logs: logs, sub: sub}, nil
}

// WatchEmergencyWithdrawalProcessed is a free log subscription operation binding the contract event 0x83b8068554a495dbb4af07014f8171144d6670eb522b356f8d3f37cbd76ba116.
//
// Solidity: event EmergencyWithdrawalProcessed(address indexed refundAddress, uint256 indexed amount)
func (_ERC4626Form *ERC4626FormFilterer) WatchEmergencyWithdrawalProcessed(opts *bind.WatchOpts, sink chan<- *ERC4626FormEmergencyWithdrawalProcessed, refundAddress []common.Address, amount []*big.Int) (event.Subscription, error) {

	var refundAddressRule []interface{}
	for _, refundAddressItem := range refundAddress {
		refundAddressRule = append(refundAddressRule, refundAddressItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _ERC4626Form.contract.WatchLogs(opts, "EmergencyWithdrawalProcessed", refundAddressRule, amountRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626FormEmergencyWithdrawalProcessed)
				if err := _ERC4626Form.contract.UnpackLog(event, "EmergencyWithdrawalProcessed", log); err != nil {
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

// ParseEmergencyWithdrawalProcessed is a log parse operation binding the contract event 0x83b8068554a495dbb4af07014f8171144d6670eb522b356f8d3f37cbd76ba116.
//
// Solidity: event EmergencyWithdrawalProcessed(address indexed refundAddress, uint256 indexed amount)
func (_ERC4626Form *ERC4626FormFilterer) ParseEmergencyWithdrawalProcessed(log types.Log) (*ERC4626FormEmergencyWithdrawalProcessed, error) {
	event := new(ERC4626FormEmergencyWithdrawalProcessed)
	if err := _ERC4626Form.contract.UnpackLog(event, "EmergencyWithdrawalProcessed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626FormFormDustForwardedToPaymasterIterator is returned from FilterFormDustForwardedToPaymaster and is used to iterate over the raw logs and unpacked data for FormDustForwardedToPaymaster events raised by the ERC4626Form contract.
type ERC4626FormFormDustForwardedToPaymasterIterator struct {
	Event *ERC4626FormFormDustForwardedToPaymaster // Event containing the contract specifics and raw log

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
func (it *ERC4626FormFormDustForwardedToPaymasterIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626FormFormDustForwardedToPaymaster)
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
		it.Event = new(ERC4626FormFormDustForwardedToPaymaster)
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
func (it *ERC4626FormFormDustForwardedToPaymasterIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626FormFormDustForwardedToPaymasterIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626FormFormDustForwardedToPaymaster represents a FormDustForwardedToPaymaster event raised by the ERC4626Form contract.
type ERC4626FormFormDustForwardedToPaymaster struct {
	Token  common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterFormDustForwardedToPaymaster is a free log retrieval operation binding the contract event 0xd34222ea8b5b095ec7a6f42ff87fa762ab480b9e8cea464915ee985f1510c10a.
//
// Solidity: event FormDustForwardedToPaymaster(address indexed token, uint256 indexed amount)
func (_ERC4626Form *ERC4626FormFilterer) FilterFormDustForwardedToPaymaster(opts *bind.FilterOpts, token []common.Address, amount []*big.Int) (*ERC4626FormFormDustForwardedToPaymasterIterator, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _ERC4626Form.contract.FilterLogs(opts, "FormDustForwardedToPaymaster", tokenRule, amountRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626FormFormDustForwardedToPaymasterIterator{contract: _ERC4626Form.contract, event: "FormDustForwardedToPaymaster", logs: logs, sub: sub}, nil
}

// WatchFormDustForwardedToPaymaster is a free log subscription operation binding the contract event 0xd34222ea8b5b095ec7a6f42ff87fa762ab480b9e8cea464915ee985f1510c10a.
//
// Solidity: event FormDustForwardedToPaymaster(address indexed token, uint256 indexed amount)
func (_ERC4626Form *ERC4626FormFilterer) WatchFormDustForwardedToPaymaster(opts *bind.WatchOpts, sink chan<- *ERC4626FormFormDustForwardedToPaymaster, token []common.Address, amount []*big.Int) (event.Subscription, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _ERC4626Form.contract.WatchLogs(opts, "FormDustForwardedToPaymaster", tokenRule, amountRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626FormFormDustForwardedToPaymaster)
				if err := _ERC4626Form.contract.UnpackLog(event, "FormDustForwardedToPaymaster", log); err != nil {
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

// ParseFormDustForwardedToPaymaster is a log parse operation binding the contract event 0xd34222ea8b5b095ec7a6f42ff87fa762ab480b9e8cea464915ee985f1510c10a.
//
// Solidity: event FormDustForwardedToPaymaster(address indexed token, uint256 indexed amount)
func (_ERC4626Form *ERC4626FormFilterer) ParseFormDustForwardedToPaymaster(log types.Log) (*ERC4626FormFormDustForwardedToPaymaster, error) {
	event := new(ERC4626FormFormDustForwardedToPaymaster)
	if err := _ERC4626Form.contract.UnpackLog(event, "FormDustForwardedToPaymaster", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626FormInitializedIterator is returned from FilterInitialized and is used to iterate over the raw logs and unpacked data for Initialized events raised by the ERC4626Form contract.
type ERC4626FormInitializedIterator struct {
	Event *ERC4626FormInitialized // Event containing the contract specifics and raw log

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
func (it *ERC4626FormInitializedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626FormInitialized)
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
		it.Event = new(ERC4626FormInitialized)
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
func (it *ERC4626FormInitializedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626FormInitializedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626FormInitialized represents a Initialized event raised by the ERC4626Form contract.
type ERC4626FormInitialized struct {
	Version uint64
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterInitialized is a free log retrieval operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_ERC4626Form *ERC4626FormFilterer) FilterInitialized(opts *bind.FilterOpts) (*ERC4626FormInitializedIterator, error) {

	logs, sub, err := _ERC4626Form.contract.FilterLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return &ERC4626FormInitializedIterator{contract: _ERC4626Form.contract, event: "Initialized", logs: logs, sub: sub}, nil
}

// WatchInitialized is a free log subscription operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_ERC4626Form *ERC4626FormFilterer) WatchInitialized(opts *bind.WatchOpts, sink chan<- *ERC4626FormInitialized) (event.Subscription, error) {

	logs, sub, err := _ERC4626Form.contract.WatchLogs(opts, "Initialized")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626FormInitialized)
				if err := _ERC4626Form.contract.UnpackLog(event, "Initialized", log); err != nil {
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

// ParseInitialized is a log parse operation binding the contract event 0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2.
//
// Solidity: event Initialized(uint64 version)
func (_ERC4626Form *ERC4626FormFilterer) ParseInitialized(log types.Log) (*ERC4626FormInitialized, error) {
	event := new(ERC4626FormInitialized)
	if err := _ERC4626Form.contract.UnpackLog(event, "Initialized", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626FormProcessedIterator is returned from FilterProcessed and is used to iterate over the raw logs and unpacked data for Processed events raised by the ERC4626Form contract.
type ERC4626FormProcessedIterator struct {
	Event *ERC4626FormProcessed // Event containing the contract specifics and raw log

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
func (it *ERC4626FormProcessedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626FormProcessed)
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
		it.Event = new(ERC4626FormProcessed)
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
func (it *ERC4626FormProcessedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626FormProcessedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626FormProcessed represents a Processed event raised by the ERC4626Form contract.
type ERC4626FormProcessed struct {
	SrcChainID   uint64
	DstChainId   uint64
	SrcPayloadId *big.Int
	Amount       *big.Int
	Vault        common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterProcessed is a free log retrieval operation binding the contract event 0x9664a7293fbeac5e42927bc5eb69c82d1fe2f0b17e510b38ebfba582d47923fe.
//
// Solidity: event Processed(uint64 indexed srcChainID, uint64 indexed dstChainId, uint256 indexed srcPayloadId, uint256 amount, address vault)
func (_ERC4626Form *ERC4626FormFilterer) FilterProcessed(opts *bind.FilterOpts, srcChainID []uint64, dstChainId []uint64, srcPayloadId []*big.Int) (*ERC4626FormProcessedIterator, error) {

	var srcChainIDRule []interface{}
	for _, srcChainIDItem := range srcChainID {
		srcChainIDRule = append(srcChainIDRule, srcChainIDItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}
	var srcPayloadIdRule []interface{}
	for _, srcPayloadIdItem := range srcPayloadId {
		srcPayloadIdRule = append(srcPayloadIdRule, srcPayloadIdItem)
	}

	logs, sub, err := _ERC4626Form.contract.FilterLogs(opts, "Processed", srcChainIDRule, dstChainIdRule, srcPayloadIdRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626FormProcessedIterator{contract: _ERC4626Form.contract, event: "Processed", logs: logs, sub: sub}, nil
}

// WatchProcessed is a free log subscription operation binding the contract event 0x9664a7293fbeac5e42927bc5eb69c82d1fe2f0b17e510b38ebfba582d47923fe.
//
// Solidity: event Processed(uint64 indexed srcChainID, uint64 indexed dstChainId, uint256 indexed srcPayloadId, uint256 amount, address vault)
func (_ERC4626Form *ERC4626FormFilterer) WatchProcessed(opts *bind.WatchOpts, sink chan<- *ERC4626FormProcessed, srcChainID []uint64, dstChainId []uint64, srcPayloadId []*big.Int) (event.Subscription, error) {

	var srcChainIDRule []interface{}
	for _, srcChainIDItem := range srcChainID {
		srcChainIDRule = append(srcChainIDRule, srcChainIDItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}
	var srcPayloadIdRule []interface{}
	for _, srcPayloadIdItem := range srcPayloadId {
		srcPayloadIdRule = append(srcPayloadIdRule, srcPayloadIdItem)
	}

	logs, sub, err := _ERC4626Form.contract.WatchLogs(opts, "Processed", srcChainIDRule, dstChainIdRule, srcPayloadIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626FormProcessed)
				if err := _ERC4626Form.contract.UnpackLog(event, "Processed", log); err != nil {
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

// ParseProcessed is a log parse operation binding the contract event 0x9664a7293fbeac5e42927bc5eb69c82d1fe2f0b17e510b38ebfba582d47923fe.
//
// Solidity: event Processed(uint64 indexed srcChainID, uint64 indexed dstChainId, uint256 indexed srcPayloadId, uint256 amount, address vault)
func (_ERC4626Form *ERC4626FormFilterer) ParseProcessed(log types.Log) (*ERC4626FormProcessed, error) {
	event := new(ERC4626FormProcessed)
	if err := _ERC4626Form.contract.UnpackLog(event, "Processed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// ERC4626FormVaultAddedIterator is returned from FilterVaultAdded and is used to iterate over the raw logs and unpacked data for VaultAdded events raised by the ERC4626Form contract.
type ERC4626FormVaultAddedIterator struct {
	Event *ERC4626FormVaultAdded // Event containing the contract specifics and raw log

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
func (it *ERC4626FormVaultAddedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(ERC4626FormVaultAdded)
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
		it.Event = new(ERC4626FormVaultAdded)
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
func (it *ERC4626FormVaultAddedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *ERC4626FormVaultAddedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// ERC4626FormVaultAdded represents a VaultAdded event raised by the ERC4626Form contract.
type ERC4626FormVaultAdded struct {
	Id    *big.Int
	Vault common.Address
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterVaultAdded is a free log retrieval operation binding the contract event 0xa3ccd9b56d18a571b67b97905e5ef425788000d31a490513f7cad937175beeeb.
//
// Solidity: event VaultAdded(uint256 indexed id, address indexed vault)
func (_ERC4626Form *ERC4626FormFilterer) FilterVaultAdded(opts *bind.FilterOpts, id []*big.Int, vault []common.Address) (*ERC4626FormVaultAddedIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _ERC4626Form.contract.FilterLogs(opts, "VaultAdded", idRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return &ERC4626FormVaultAddedIterator{contract: _ERC4626Form.contract, event: "VaultAdded", logs: logs, sub: sub}, nil
}

// WatchVaultAdded is a free log subscription operation binding the contract event 0xa3ccd9b56d18a571b67b97905e5ef425788000d31a490513f7cad937175beeeb.
//
// Solidity: event VaultAdded(uint256 indexed id, address indexed vault)
func (_ERC4626Form *ERC4626FormFilterer) WatchVaultAdded(opts *bind.WatchOpts, sink chan<- *ERC4626FormVaultAdded, id []*big.Int, vault []common.Address) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}
	var vaultRule []interface{}
	for _, vaultItem := range vault {
		vaultRule = append(vaultRule, vaultItem)
	}

	logs, sub, err := _ERC4626Form.contract.WatchLogs(opts, "VaultAdded", idRule, vaultRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(ERC4626FormVaultAdded)
				if err := _ERC4626Form.contract.UnpackLog(event, "VaultAdded", log); err != nil {
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

// ParseVaultAdded is a log parse operation binding the contract event 0xa3ccd9b56d18a571b67b97905e5ef425788000d31a490513f7cad937175beeeb.
//
// Solidity: event VaultAdded(uint256 indexed id, address indexed vault)
func (_ERC4626Form *ERC4626FormFilterer) ParseVaultAdded(log types.Log) (*ERC4626FormVaultAdded, error) {
	event := new(ERC4626FormVaultAdded)
	if err := _ERC4626Form.contract.UnpackLog(event, "VaultAdded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
