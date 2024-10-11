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

// AMBMessage is an auto generated low-level Go binding around an user-defined struct.
type AMBMessage struct {
	TxInfo *big.Int
	Params []byte
}

// SuperPositionsMetaData contains all meta data concerning the SuperPositions contract.
var SuperPositionsMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"dynamicURI_\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"superRegistry_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"name_\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"symbol_\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"CHAIN_ID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"aERC20Exists\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"aErc20TokenId\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"aErc20Token\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"allowance\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOf\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"balanceOfBatch\",\"inputs\":[{\"name\":\"owners\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"balances\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"burnBatch\",\"inputs\":[{\"name\":\"srcSender_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"burnSingle\",\"inputs\":[{\"name\":\"srcSender_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"decreaseAllowance\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"subtractedValue\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"decreaseAllowanceForMany\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"subtractedValues\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"dynamicURI\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"dynamicURIFrozen\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"exists\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getERC20TokenAddress\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"increaseAllowance\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"addedValue\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"increaseAllowanceForMany\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"addedValues\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isApprovedForAll\",\"inputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"mintBatch\",\"inputs\":[{\"name\":\"receiverAddressSP_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts_\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"mintSingle\",\"inputs\":[{\"name\":\"receiverAddressSP_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount_\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"name\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"registerAERC20\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"safeBatchTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"safeTransferFrom\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"data\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setApprovalForMany\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setApprovalForOne\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setDynamicURI\",\"inputs\":[{\"name\":\"dynamicURI_\",\"type\":\"string\",\"internalType\":\"string\"},{\"name\":\"freeze_\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"stateMultiSync\",\"inputs\":[{\"name\":\"data_\",\"type\":\"tuple\",\"internalType\":\"structAMBMessage\",\"components\":[{\"name\":\"txInfo\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"params\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[{\"name\":\"srcChainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"stateSync\",\"inputs\":[{\"name\":\"data_\",\"type\":\"tuple\",\"internalType\":\"structAMBMessage\",\"components\":[{\"name\":\"txInfo\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"params\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}],\"outputs\":[{\"name\":\"srcChainId_\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"stateSyncBroadcast\",\"inputs\":[{\"name\":\"data_\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"superRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperRegistry\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId_\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"symbol\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"totalSupply\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"transmuteBatchToERC1155A\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transmuteBatchToERC20\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transmuteToERC1155A\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"transmuteToERC20\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"txHistory\",\"inputs\":[{\"name\":\"transactionId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"txInfo\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"updateTxHistory\",\"inputs\":[{\"name\":\"payloadId_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"txInfo_\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"receiverAddressSP_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"uri\",\"inputs\":[{\"name\":\"id\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[{\"name\":\"\",\"type\":\"string\",\"internalType\":\"string\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"xChainPayloadCounter\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"AERC20TokenRegistered\",\"inputs\":[{\"name\":\"tokenId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"tokenAddress\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ApprovalForAll\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"approved\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ApprovalForOne\",\"inputs\":[{\"name\":\"owner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"spender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"Completed\",\"inputs\":[{\"name\":\"txId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"DynamicURIUpdated\",\"inputs\":[{\"name\":\"oldURI\",\"type\":\"string\",\"indexed\":true,\"internalType\":\"string\"},{\"name\":\"newURI\",\"type\":\"string\",\"indexed\":true,\"internalType\":\"string\"},{\"name\":\"frozen\",\"type\":\"bool\",\"indexed\":true,\"internalType\":\"bool\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferBatch\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"values\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransferSingle\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"from\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransmutedBatchToERC1155A\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransmutedBatchToERC20\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"ids\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransmutedToERC1155A\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TransmutedToERC20\",\"inputs\":[{\"name\":\"user\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"receiver\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"TxHistorySet\",\"inputs\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"txInfo\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"URI\",\"inputs\":[{\"name\":\"value\",\"type\":\"string\",\"indexed\":false,\"internalType\":\"string\"},{\"name\":\"id\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AERC20_ALREADY_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AERC20_NOT_REGISTERED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ARRAY_LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"BLOCK_CHAIN_ID_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DECREASED_ALLOWANCE_BELOW_ZERO\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"DYNAMIC_URI_FROZEN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ERC1155InsufficientBalance\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"balance\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"needed\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"tokenId\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidApprover\",\"inputs\":[{\"name\":\"approver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidArrayLength\",\"inputs\":[{\"name\":\"idsLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"valuesLength\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidOperator\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155InvalidSender\",\"inputs\":[{\"name\":\"sender\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ERC1155MissingApprovalForAll\",\"inputs\":[{\"name\":\"operator\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"owner\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"FAILED_TO_SEND_NATIVE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ID_NOT_MINTED_YET\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_BROADCAST_FEE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_CHAIN_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_MESSAGE_TYPE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_PAYLOAD_TYPE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_BROADCAST_REGISTRY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_MINTER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_MINTER_STATE_REGISTRY_ROLE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_PROTOCOL_ADMIN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NOT_SUPERFORM_ROUTER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SRC_TX_TYPE_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SUPERFORM_ID_NONEXISTENT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"TRANSFER_TO_ADDRESS_ZERO\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"TX_HISTORY_NOT_FOUND\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]}]",
}

// SuperPositionsABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperPositionsMetaData.ABI instead.
var SuperPositionsABI = SuperPositionsMetaData.ABI

// SuperPositions is an auto generated Go binding around an Ethereum contract.
type SuperPositions struct {
	SuperPositionsCaller     // Read-only binding to the contract
	SuperPositionsTransactor // Write-only binding to the contract
	SuperPositionsFilterer   // Log filterer for contract events
}

// SuperPositionsCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperPositionsCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperPositionsTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperPositionsTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperPositionsFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperPositionsFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperPositionsSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperPositionsSession struct {
	Contract     *SuperPositions   // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// SuperPositionsCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperPositionsCallerSession struct {
	Contract *SuperPositionsCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts         // Call options to use throughout this session
}

// SuperPositionsTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperPositionsTransactorSession struct {
	Contract     *SuperPositionsTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// SuperPositionsRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperPositionsRaw struct {
	Contract *SuperPositions // Generic contract binding to access the raw methods on
}

// SuperPositionsCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperPositionsCallerRaw struct {
	Contract *SuperPositionsCaller // Generic read-only contract binding to access the raw methods on
}

// SuperPositionsTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperPositionsTransactorRaw struct {
	Contract *SuperPositionsTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperPositions creates a new instance of SuperPositions, bound to a specific deployed contract.
func NewSuperPositions(address common.Address, backend bind.ContractBackend) (*SuperPositions, error) {
	contract, err := bindSuperPositions(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperPositions{SuperPositionsCaller: SuperPositionsCaller{contract: contract}, SuperPositionsTransactor: SuperPositionsTransactor{contract: contract}, SuperPositionsFilterer: SuperPositionsFilterer{contract: contract}}, nil
}

// NewSuperPositionsCaller creates a new read-only instance of SuperPositions, bound to a specific deployed contract.
func NewSuperPositionsCaller(address common.Address, caller bind.ContractCaller) (*SuperPositionsCaller, error) {
	contract, err := bindSuperPositions(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsCaller{contract: contract}, nil
}

// NewSuperPositionsTransactor creates a new write-only instance of SuperPositions, bound to a specific deployed contract.
func NewSuperPositionsTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperPositionsTransactor, error) {
	contract, err := bindSuperPositions(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsTransactor{contract: contract}, nil
}

// NewSuperPositionsFilterer creates a new log filterer instance of SuperPositions, bound to a specific deployed contract.
func NewSuperPositionsFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperPositionsFilterer, error) {
	contract, err := bindSuperPositions(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsFilterer{contract: contract}, nil
}

// bindSuperPositions binds a generic wrapper to an already deployed contract.
func bindSuperPositions(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperPositionsMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperPositions *SuperPositionsRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperPositions.Contract.SuperPositionsCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperPositions *SuperPositionsRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperPositions.Contract.SuperPositionsTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperPositions *SuperPositionsRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperPositions.Contract.SuperPositionsTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperPositions *SuperPositionsCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperPositions.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperPositions *SuperPositionsTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperPositions.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperPositions *SuperPositionsTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperPositions.Contract.contract.Transact(opts, method, params...)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SuperPositions *SuperPositionsCaller) CHAINID(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "CHAIN_ID")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SuperPositions *SuperPositionsSession) CHAINID() (uint64, error) {
	return _SuperPositions.Contract.CHAINID(&_SuperPositions.CallOpts)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SuperPositions *SuperPositionsCallerSession) CHAINID() (uint64, error) {
	return _SuperPositions.Contract.CHAINID(&_SuperPositions.CallOpts)
}

// AERC20Exists is a free data retrieval call binding the contract method 0xe673070f.
//
// Solidity: function aERC20Exists(uint256 id) view returns(bool)
func (_SuperPositions *SuperPositionsCaller) AERC20Exists(opts *bind.CallOpts, id *big.Int) (bool, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "aERC20Exists", id)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// AERC20Exists is a free data retrieval call binding the contract method 0xe673070f.
//
// Solidity: function aERC20Exists(uint256 id) view returns(bool)
func (_SuperPositions *SuperPositionsSession) AERC20Exists(id *big.Int) (bool, error) {
	return _SuperPositions.Contract.AERC20Exists(&_SuperPositions.CallOpts, id)
}

// AERC20Exists is a free data retrieval call binding the contract method 0xe673070f.
//
// Solidity: function aERC20Exists(uint256 id) view returns(bool)
func (_SuperPositions *SuperPositionsCallerSession) AERC20Exists(id *big.Int) (bool, error) {
	return _SuperPositions.Contract.AERC20Exists(&_SuperPositions.CallOpts, id)
}

// AErc20TokenId is a free data retrieval call binding the contract method 0x0282acfc.
//
// Solidity: function aErc20TokenId(uint256 id) view returns(address aErc20Token)
func (_SuperPositions *SuperPositionsCaller) AErc20TokenId(opts *bind.CallOpts, id *big.Int) (common.Address, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "aErc20TokenId", id)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// AErc20TokenId is a free data retrieval call binding the contract method 0x0282acfc.
//
// Solidity: function aErc20TokenId(uint256 id) view returns(address aErc20Token)
func (_SuperPositions *SuperPositionsSession) AErc20TokenId(id *big.Int) (common.Address, error) {
	return _SuperPositions.Contract.AErc20TokenId(&_SuperPositions.CallOpts, id)
}

// AErc20TokenId is a free data retrieval call binding the contract method 0x0282acfc.
//
// Solidity: function aErc20TokenId(uint256 id) view returns(address aErc20Token)
func (_SuperPositions *SuperPositionsCallerSession) AErc20TokenId(id *big.Int) (common.Address, error) {
	return _SuperPositions.Contract.AErc20TokenId(&_SuperPositions.CallOpts, id)
}

// Allowance is a free data retrieval call binding the contract method 0x598af9e7.
//
// Solidity: function allowance(address owner, address operator, uint256 id) view returns(uint256)
func (_SuperPositions *SuperPositionsCaller) Allowance(opts *bind.CallOpts, owner common.Address, operator common.Address, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "allowance", owner, operator, id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Allowance is a free data retrieval call binding the contract method 0x598af9e7.
//
// Solidity: function allowance(address owner, address operator, uint256 id) view returns(uint256)
func (_SuperPositions *SuperPositionsSession) Allowance(owner common.Address, operator common.Address, id *big.Int) (*big.Int, error) {
	return _SuperPositions.Contract.Allowance(&_SuperPositions.CallOpts, owner, operator, id)
}

// Allowance is a free data retrieval call binding the contract method 0x598af9e7.
//
// Solidity: function allowance(address owner, address operator, uint256 id) view returns(uint256)
func (_SuperPositions *SuperPositionsCallerSession) Allowance(owner common.Address, operator common.Address, id *big.Int) (*big.Int, error) {
	return _SuperPositions.Contract.Allowance(&_SuperPositions.CallOpts, owner, operator, id)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address , uint256 ) view returns(uint256)
func (_SuperPositions *SuperPositionsCaller) BalanceOf(opts *bind.CallOpts, arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "balanceOf", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address , uint256 ) view returns(uint256)
func (_SuperPositions *SuperPositionsSession) BalanceOf(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _SuperPositions.Contract.BalanceOf(&_SuperPositions.CallOpts, arg0, arg1)
}

// BalanceOf is a free data retrieval call binding the contract method 0x00fdd58e.
//
// Solidity: function balanceOf(address , uint256 ) view returns(uint256)
func (_SuperPositions *SuperPositionsCallerSession) BalanceOf(arg0 common.Address, arg1 *big.Int) (*big.Int, error) {
	return _SuperPositions.Contract.BalanceOf(&_SuperPositions.CallOpts, arg0, arg1)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] owners, uint256[] ids) view returns(uint256[] balances)
func (_SuperPositions *SuperPositionsCaller) BalanceOfBatch(opts *bind.CallOpts, owners []common.Address, ids []*big.Int) ([]*big.Int, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "balanceOfBatch", owners, ids)

	if err != nil {
		return *new([]*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new([]*big.Int)).(*[]*big.Int)

	return out0, err

}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] owners, uint256[] ids) view returns(uint256[] balances)
func (_SuperPositions *SuperPositionsSession) BalanceOfBatch(owners []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _SuperPositions.Contract.BalanceOfBatch(&_SuperPositions.CallOpts, owners, ids)
}

// BalanceOfBatch is a free data retrieval call binding the contract method 0x4e1273f4.
//
// Solidity: function balanceOfBatch(address[] owners, uint256[] ids) view returns(uint256[] balances)
func (_SuperPositions *SuperPositionsCallerSession) BalanceOfBatch(owners []common.Address, ids []*big.Int) ([]*big.Int, error) {
	return _SuperPositions.Contract.BalanceOfBatch(&_SuperPositions.CallOpts, owners, ids)
}

// DynamicURI is a free data retrieval call binding the contract method 0x137bc427.
//
// Solidity: function dynamicURI() view returns(string)
func (_SuperPositions *SuperPositionsCaller) DynamicURI(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "dynamicURI")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// DynamicURI is a free data retrieval call binding the contract method 0x137bc427.
//
// Solidity: function dynamicURI() view returns(string)
func (_SuperPositions *SuperPositionsSession) DynamicURI() (string, error) {
	return _SuperPositions.Contract.DynamicURI(&_SuperPositions.CallOpts)
}

// DynamicURI is a free data retrieval call binding the contract method 0x137bc427.
//
// Solidity: function dynamicURI() view returns(string)
func (_SuperPositions *SuperPositionsCallerSession) DynamicURI() (string, error) {
	return _SuperPositions.Contract.DynamicURI(&_SuperPositions.CallOpts)
}

// DynamicURIFrozen is a free data retrieval call binding the contract method 0xd7ea0c23.
//
// Solidity: function dynamicURIFrozen() view returns(bool)
func (_SuperPositions *SuperPositionsCaller) DynamicURIFrozen(opts *bind.CallOpts) (bool, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "dynamicURIFrozen")

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// DynamicURIFrozen is a free data retrieval call binding the contract method 0xd7ea0c23.
//
// Solidity: function dynamicURIFrozen() view returns(bool)
func (_SuperPositions *SuperPositionsSession) DynamicURIFrozen() (bool, error) {
	return _SuperPositions.Contract.DynamicURIFrozen(&_SuperPositions.CallOpts)
}

// DynamicURIFrozen is a free data retrieval call binding the contract method 0xd7ea0c23.
//
// Solidity: function dynamicURIFrozen() view returns(bool)
func (_SuperPositions *SuperPositionsCallerSession) DynamicURIFrozen() (bool, error) {
	return _SuperPositions.Contract.DynamicURIFrozen(&_SuperPositions.CallOpts)
}

// Exists is a free data retrieval call binding the contract method 0x4f558e79.
//
// Solidity: function exists(uint256 id) view returns(bool)
func (_SuperPositions *SuperPositionsCaller) Exists(opts *bind.CallOpts, id *big.Int) (bool, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "exists", id)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// Exists is a free data retrieval call binding the contract method 0x4f558e79.
//
// Solidity: function exists(uint256 id) view returns(bool)
func (_SuperPositions *SuperPositionsSession) Exists(id *big.Int) (bool, error) {
	return _SuperPositions.Contract.Exists(&_SuperPositions.CallOpts, id)
}

// Exists is a free data retrieval call binding the contract method 0x4f558e79.
//
// Solidity: function exists(uint256 id) view returns(bool)
func (_SuperPositions *SuperPositionsCallerSession) Exists(id *big.Int) (bool, error) {
	return _SuperPositions.Contract.Exists(&_SuperPositions.CallOpts, id)
}

// GetERC20TokenAddress is a free data retrieval call binding the contract method 0x540ed9c0.
//
// Solidity: function getERC20TokenAddress(uint256 id) view returns(address)
func (_SuperPositions *SuperPositionsCaller) GetERC20TokenAddress(opts *bind.CallOpts, id *big.Int) (common.Address, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "getERC20TokenAddress", id)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetERC20TokenAddress is a free data retrieval call binding the contract method 0x540ed9c0.
//
// Solidity: function getERC20TokenAddress(uint256 id) view returns(address)
func (_SuperPositions *SuperPositionsSession) GetERC20TokenAddress(id *big.Int) (common.Address, error) {
	return _SuperPositions.Contract.GetERC20TokenAddress(&_SuperPositions.CallOpts, id)
}

// GetERC20TokenAddress is a free data retrieval call binding the contract method 0x540ed9c0.
//
// Solidity: function getERC20TokenAddress(uint256 id) view returns(address)
func (_SuperPositions *SuperPositionsCallerSession) GetERC20TokenAddress(id *big.Int) (common.Address, error) {
	return _SuperPositions.Contract.GetERC20TokenAddress(&_SuperPositions.CallOpts, id)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address , address ) view returns(bool)
func (_SuperPositions *SuperPositionsCaller) IsApprovedForAll(opts *bind.CallOpts, arg0 common.Address, arg1 common.Address) (bool, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "isApprovedForAll", arg0, arg1)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address , address ) view returns(bool)
func (_SuperPositions *SuperPositionsSession) IsApprovedForAll(arg0 common.Address, arg1 common.Address) (bool, error) {
	return _SuperPositions.Contract.IsApprovedForAll(&_SuperPositions.CallOpts, arg0, arg1)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address , address ) view returns(bool)
func (_SuperPositions *SuperPositionsCallerSession) IsApprovedForAll(arg0 common.Address, arg1 common.Address) (bool, error) {
	return _SuperPositions.Contract.IsApprovedForAll(&_SuperPositions.CallOpts, arg0, arg1)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_SuperPositions *SuperPositionsCaller) Name(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "name")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_SuperPositions *SuperPositionsSession) Name() (string, error) {
	return _SuperPositions.Contract.Name(&_SuperPositions.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_SuperPositions *SuperPositionsCallerSession) Name() (string, error) {
	return _SuperPositions.Contract.Name(&_SuperPositions.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SuperPositions *SuperPositionsCaller) SuperRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "superRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SuperPositions *SuperPositionsSession) SuperRegistry() (common.Address, error) {
	return _SuperPositions.Contract.SuperRegistry(&_SuperPositions.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SuperPositions *SuperPositionsCallerSession) SuperRegistry() (common.Address, error) {
	return _SuperPositions.Contract.SuperRegistry(&_SuperPositions.CallOpts)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId_) view returns(bool)
func (_SuperPositions *SuperPositionsCaller) SupportsInterface(opts *bind.CallOpts, interfaceId_ [4]byte) (bool, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "supportsInterface", interfaceId_)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId_) view returns(bool)
func (_SuperPositions *SuperPositionsSession) SupportsInterface(interfaceId_ [4]byte) (bool, error) {
	return _SuperPositions.Contract.SupportsInterface(&_SuperPositions.CallOpts, interfaceId_)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId_) view returns(bool)
func (_SuperPositions *SuperPositionsCallerSession) SupportsInterface(interfaceId_ [4]byte) (bool, error) {
	return _SuperPositions.Contract.SupportsInterface(&_SuperPositions.CallOpts, interfaceId_)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_SuperPositions *SuperPositionsCaller) Symbol(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "symbol")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_SuperPositions *SuperPositionsSession) Symbol() (string, error) {
	return _SuperPositions.Contract.Symbol(&_SuperPositions.CallOpts)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_SuperPositions *SuperPositionsCallerSession) Symbol() (string, error) {
	return _SuperPositions.Contract.Symbol(&_SuperPositions.CallOpts)
}

// TotalSupply is a free data retrieval call binding the contract method 0xbd85b039.
//
// Solidity: function totalSupply(uint256 id) view returns(uint256)
func (_SuperPositions *SuperPositionsCaller) TotalSupply(opts *bind.CallOpts, id *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "totalSupply", id)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalSupply is a free data retrieval call binding the contract method 0xbd85b039.
//
// Solidity: function totalSupply(uint256 id) view returns(uint256)
func (_SuperPositions *SuperPositionsSession) TotalSupply(id *big.Int) (*big.Int, error) {
	return _SuperPositions.Contract.TotalSupply(&_SuperPositions.CallOpts, id)
}

// TotalSupply is a free data retrieval call binding the contract method 0xbd85b039.
//
// Solidity: function totalSupply(uint256 id) view returns(uint256)
func (_SuperPositions *SuperPositionsCallerSession) TotalSupply(id *big.Int) (*big.Int, error) {
	return _SuperPositions.Contract.TotalSupply(&_SuperPositions.CallOpts, id)
}

// TxHistory is a free data retrieval call binding the contract method 0x75fcbd86.
//
// Solidity: function txHistory(uint256 transactionId) view returns(uint256 txInfo, address receiverAddressSP)
func (_SuperPositions *SuperPositionsCaller) TxHistory(opts *bind.CallOpts, transactionId *big.Int) (struct {
	TxInfo            *big.Int
	ReceiverAddressSP common.Address
}, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "txHistory", transactionId)

	outstruct := new(struct {
		TxInfo            *big.Int
		ReceiverAddressSP common.Address
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.TxInfo = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.ReceiverAddressSP = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)

	return *outstruct, err

}

// TxHistory is a free data retrieval call binding the contract method 0x75fcbd86.
//
// Solidity: function txHistory(uint256 transactionId) view returns(uint256 txInfo, address receiverAddressSP)
func (_SuperPositions *SuperPositionsSession) TxHistory(transactionId *big.Int) (struct {
	TxInfo            *big.Int
	ReceiverAddressSP common.Address
}, error) {
	return _SuperPositions.Contract.TxHistory(&_SuperPositions.CallOpts, transactionId)
}

// TxHistory is a free data retrieval call binding the contract method 0x75fcbd86.
//
// Solidity: function txHistory(uint256 transactionId) view returns(uint256 txInfo, address receiverAddressSP)
func (_SuperPositions *SuperPositionsCallerSession) TxHistory(transactionId *big.Int) (struct {
	TxInfo            *big.Int
	ReceiverAddressSP common.Address
}, error) {
	return _SuperPositions.Contract.TxHistory(&_SuperPositions.CallOpts, transactionId)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 id) view returns(string)
func (_SuperPositions *SuperPositionsCaller) Uri(opts *bind.CallOpts, id *big.Int) (string, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "uri", id)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 id) view returns(string)
func (_SuperPositions *SuperPositionsSession) Uri(id *big.Int) (string, error) {
	return _SuperPositions.Contract.Uri(&_SuperPositions.CallOpts, id)
}

// Uri is a free data retrieval call binding the contract method 0x0e89341c.
//
// Solidity: function uri(uint256 id) view returns(string)
func (_SuperPositions *SuperPositionsCallerSession) Uri(id *big.Int) (string, error) {
	return _SuperPositions.Contract.Uri(&_SuperPositions.CallOpts, id)
}

// XChainPayloadCounter is a free data retrieval call binding the contract method 0xedf387c5.
//
// Solidity: function xChainPayloadCounter() view returns(uint256)
func (_SuperPositions *SuperPositionsCaller) XChainPayloadCounter(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperPositions.contract.Call(opts, &out, "xChainPayloadCounter")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// XChainPayloadCounter is a free data retrieval call binding the contract method 0xedf387c5.
//
// Solidity: function xChainPayloadCounter() view returns(uint256)
func (_SuperPositions *SuperPositionsSession) XChainPayloadCounter() (*big.Int, error) {
	return _SuperPositions.Contract.XChainPayloadCounter(&_SuperPositions.CallOpts)
}

// XChainPayloadCounter is a free data retrieval call binding the contract method 0xedf387c5.
//
// Solidity: function xChainPayloadCounter() view returns(uint256)
func (_SuperPositions *SuperPositionsCallerSession) XChainPayloadCounter() (*big.Int, error) {
	return _SuperPositions.Contract.XChainPayloadCounter(&_SuperPositions.CallOpts)
}

// BurnBatch is a paid mutator transaction binding the contract method 0x6b20c454.
//
// Solidity: function burnBatch(address srcSender_, uint256[] ids_, uint256[] amounts_) returns()
func (_SuperPositions *SuperPositionsTransactor) BurnBatch(opts *bind.TransactOpts, srcSender_ common.Address, ids_ []*big.Int, amounts_ []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "burnBatch", srcSender_, ids_, amounts_)
}

// BurnBatch is a paid mutator transaction binding the contract method 0x6b20c454.
//
// Solidity: function burnBatch(address srcSender_, uint256[] ids_, uint256[] amounts_) returns()
func (_SuperPositions *SuperPositionsSession) BurnBatch(srcSender_ common.Address, ids_ []*big.Int, amounts_ []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.BurnBatch(&_SuperPositions.TransactOpts, srcSender_, ids_, amounts_)
}

// BurnBatch is a paid mutator transaction binding the contract method 0x6b20c454.
//
// Solidity: function burnBatch(address srcSender_, uint256[] ids_, uint256[] amounts_) returns()
func (_SuperPositions *SuperPositionsTransactorSession) BurnBatch(srcSender_ common.Address, ids_ []*big.Int, amounts_ []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.BurnBatch(&_SuperPositions.TransactOpts, srcSender_, ids_, amounts_)
}

// BurnSingle is a paid mutator transaction binding the contract method 0x132b4816.
//
// Solidity: function burnSingle(address srcSender_, uint256 id_, uint256 amount_) returns()
func (_SuperPositions *SuperPositionsTransactor) BurnSingle(opts *bind.TransactOpts, srcSender_ common.Address, id_ *big.Int, amount_ *big.Int) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "burnSingle", srcSender_, id_, amount_)
}

// BurnSingle is a paid mutator transaction binding the contract method 0x132b4816.
//
// Solidity: function burnSingle(address srcSender_, uint256 id_, uint256 amount_) returns()
func (_SuperPositions *SuperPositionsSession) BurnSingle(srcSender_ common.Address, id_ *big.Int, amount_ *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.BurnSingle(&_SuperPositions.TransactOpts, srcSender_, id_, amount_)
}

// BurnSingle is a paid mutator transaction binding the contract method 0x132b4816.
//
// Solidity: function burnSingle(address srcSender_, uint256 id_, uint256 amount_) returns()
func (_SuperPositions *SuperPositionsTransactorSession) BurnSingle(srcSender_ common.Address, id_ *big.Int, amount_ *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.BurnSingle(&_SuperPositions.TransactOpts, srcSender_, id_, amount_)
}

// DecreaseAllowance is a paid mutator transaction binding the contract method 0xcdde3d6b.
//
// Solidity: function decreaseAllowance(address operator, uint256 id, uint256 subtractedValue) returns(bool)
func (_SuperPositions *SuperPositionsTransactor) DecreaseAllowance(opts *bind.TransactOpts, operator common.Address, id *big.Int, subtractedValue *big.Int) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "decreaseAllowance", operator, id, subtractedValue)
}

// DecreaseAllowance is a paid mutator transaction binding the contract method 0xcdde3d6b.
//
// Solidity: function decreaseAllowance(address operator, uint256 id, uint256 subtractedValue) returns(bool)
func (_SuperPositions *SuperPositionsSession) DecreaseAllowance(operator common.Address, id *big.Int, subtractedValue *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.DecreaseAllowance(&_SuperPositions.TransactOpts, operator, id, subtractedValue)
}

// DecreaseAllowance is a paid mutator transaction binding the contract method 0xcdde3d6b.
//
// Solidity: function decreaseAllowance(address operator, uint256 id, uint256 subtractedValue) returns(bool)
func (_SuperPositions *SuperPositionsTransactorSession) DecreaseAllowance(operator common.Address, id *big.Int, subtractedValue *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.DecreaseAllowance(&_SuperPositions.TransactOpts, operator, id, subtractedValue)
}

// DecreaseAllowanceForMany is a paid mutator transaction binding the contract method 0xcd4622eb.
//
// Solidity: function decreaseAllowanceForMany(address operator, uint256[] ids, uint256[] subtractedValues) returns(bool)
func (_SuperPositions *SuperPositionsTransactor) DecreaseAllowanceForMany(opts *bind.TransactOpts, operator common.Address, ids []*big.Int, subtractedValues []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "decreaseAllowanceForMany", operator, ids, subtractedValues)
}

// DecreaseAllowanceForMany is a paid mutator transaction binding the contract method 0xcd4622eb.
//
// Solidity: function decreaseAllowanceForMany(address operator, uint256[] ids, uint256[] subtractedValues) returns(bool)
func (_SuperPositions *SuperPositionsSession) DecreaseAllowanceForMany(operator common.Address, ids []*big.Int, subtractedValues []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.DecreaseAllowanceForMany(&_SuperPositions.TransactOpts, operator, ids, subtractedValues)
}

// DecreaseAllowanceForMany is a paid mutator transaction binding the contract method 0xcd4622eb.
//
// Solidity: function decreaseAllowanceForMany(address operator, uint256[] ids, uint256[] subtractedValues) returns(bool)
func (_SuperPositions *SuperPositionsTransactorSession) DecreaseAllowanceForMany(operator common.Address, ids []*big.Int, subtractedValues []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.DecreaseAllowanceForMany(&_SuperPositions.TransactOpts, operator, ids, subtractedValues)
}

// IncreaseAllowance is a paid mutator transaction binding the contract method 0xff61011a.
//
// Solidity: function increaseAllowance(address operator, uint256 id, uint256 addedValue) returns(bool)
func (_SuperPositions *SuperPositionsTransactor) IncreaseAllowance(opts *bind.TransactOpts, operator common.Address, id *big.Int, addedValue *big.Int) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "increaseAllowance", operator, id, addedValue)
}

// IncreaseAllowance is a paid mutator transaction binding the contract method 0xff61011a.
//
// Solidity: function increaseAllowance(address operator, uint256 id, uint256 addedValue) returns(bool)
func (_SuperPositions *SuperPositionsSession) IncreaseAllowance(operator common.Address, id *big.Int, addedValue *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.IncreaseAllowance(&_SuperPositions.TransactOpts, operator, id, addedValue)
}

// IncreaseAllowance is a paid mutator transaction binding the contract method 0xff61011a.
//
// Solidity: function increaseAllowance(address operator, uint256 id, uint256 addedValue) returns(bool)
func (_SuperPositions *SuperPositionsTransactorSession) IncreaseAllowance(operator common.Address, id *big.Int, addedValue *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.IncreaseAllowance(&_SuperPositions.TransactOpts, operator, id, addedValue)
}

// IncreaseAllowanceForMany is a paid mutator transaction binding the contract method 0x67bc4065.
//
// Solidity: function increaseAllowanceForMany(address operator, uint256[] ids, uint256[] addedValues) returns(bool)
func (_SuperPositions *SuperPositionsTransactor) IncreaseAllowanceForMany(opts *bind.TransactOpts, operator common.Address, ids []*big.Int, addedValues []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "increaseAllowanceForMany", operator, ids, addedValues)
}

// IncreaseAllowanceForMany is a paid mutator transaction binding the contract method 0x67bc4065.
//
// Solidity: function increaseAllowanceForMany(address operator, uint256[] ids, uint256[] addedValues) returns(bool)
func (_SuperPositions *SuperPositionsSession) IncreaseAllowanceForMany(operator common.Address, ids []*big.Int, addedValues []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.IncreaseAllowanceForMany(&_SuperPositions.TransactOpts, operator, ids, addedValues)
}

// IncreaseAllowanceForMany is a paid mutator transaction binding the contract method 0x67bc4065.
//
// Solidity: function increaseAllowanceForMany(address operator, uint256[] ids, uint256[] addedValues) returns(bool)
func (_SuperPositions *SuperPositionsTransactorSession) IncreaseAllowanceForMany(operator common.Address, ids []*big.Int, addedValues []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.IncreaseAllowanceForMany(&_SuperPositions.TransactOpts, operator, ids, addedValues)
}

// MintBatch is a paid mutator transaction binding the contract method 0xd81d0a15.
//
// Solidity: function mintBatch(address receiverAddressSP_, uint256[] ids_, uint256[] amounts_) returns()
func (_SuperPositions *SuperPositionsTransactor) MintBatch(opts *bind.TransactOpts, receiverAddressSP_ common.Address, ids_ []*big.Int, amounts_ []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "mintBatch", receiverAddressSP_, ids_, amounts_)
}

// MintBatch is a paid mutator transaction binding the contract method 0xd81d0a15.
//
// Solidity: function mintBatch(address receiverAddressSP_, uint256[] ids_, uint256[] amounts_) returns()
func (_SuperPositions *SuperPositionsSession) MintBatch(receiverAddressSP_ common.Address, ids_ []*big.Int, amounts_ []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.MintBatch(&_SuperPositions.TransactOpts, receiverAddressSP_, ids_, amounts_)
}

// MintBatch is a paid mutator transaction binding the contract method 0xd81d0a15.
//
// Solidity: function mintBatch(address receiverAddressSP_, uint256[] ids_, uint256[] amounts_) returns()
func (_SuperPositions *SuperPositionsTransactorSession) MintBatch(receiverAddressSP_ common.Address, ids_ []*big.Int, amounts_ []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.MintBatch(&_SuperPositions.TransactOpts, receiverAddressSP_, ids_, amounts_)
}

// MintSingle is a paid mutator transaction binding the contract method 0x8d04e40e.
//
// Solidity: function mintSingle(address receiverAddressSP_, uint256 id_, uint256 amount_) returns()
func (_SuperPositions *SuperPositionsTransactor) MintSingle(opts *bind.TransactOpts, receiverAddressSP_ common.Address, id_ *big.Int, amount_ *big.Int) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "mintSingle", receiverAddressSP_, id_, amount_)
}

// MintSingle is a paid mutator transaction binding the contract method 0x8d04e40e.
//
// Solidity: function mintSingle(address receiverAddressSP_, uint256 id_, uint256 amount_) returns()
func (_SuperPositions *SuperPositionsSession) MintSingle(receiverAddressSP_ common.Address, id_ *big.Int, amount_ *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.MintSingle(&_SuperPositions.TransactOpts, receiverAddressSP_, id_, amount_)
}

// MintSingle is a paid mutator transaction binding the contract method 0x8d04e40e.
//
// Solidity: function mintSingle(address receiverAddressSP_, uint256 id_, uint256 amount_) returns()
func (_SuperPositions *SuperPositionsTransactorSession) MintSingle(receiverAddressSP_ common.Address, id_ *big.Int, amount_ *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.MintSingle(&_SuperPositions.TransactOpts, receiverAddressSP_, id_, amount_)
}

// RegisterAERC20 is a paid mutator transaction binding the contract method 0x093e3164.
//
// Solidity: function registerAERC20(uint256 id) payable returns(address)
func (_SuperPositions *SuperPositionsTransactor) RegisterAERC20(opts *bind.TransactOpts, id *big.Int) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "registerAERC20", id)
}

// RegisterAERC20 is a paid mutator transaction binding the contract method 0x093e3164.
//
// Solidity: function registerAERC20(uint256 id) payable returns(address)
func (_SuperPositions *SuperPositionsSession) RegisterAERC20(id *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.RegisterAERC20(&_SuperPositions.TransactOpts, id)
}

// RegisterAERC20 is a paid mutator transaction binding the contract method 0x093e3164.
//
// Solidity: function registerAERC20(uint256 id) payable returns(address)
func (_SuperPositions *SuperPositionsTransactorSession) RegisterAERC20(id *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.RegisterAERC20(&_SuperPositions.TransactOpts, id)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data) returns()
func (_SuperPositions *SuperPositionsTransactor) SafeBatchTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, ids []*big.Int, amounts []*big.Int, data []byte) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "safeBatchTransferFrom", from, to, ids, amounts, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data) returns()
func (_SuperPositions *SuperPositionsSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, amounts []*big.Int, data []byte) (*types.Transaction, error) {
	return _SuperPositions.Contract.SafeBatchTransferFrom(&_SuperPositions.TransactOpts, from, to, ids, amounts, data)
}

// SafeBatchTransferFrom is a paid mutator transaction binding the contract method 0x2eb2c2d6.
//
// Solidity: function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data) returns()
func (_SuperPositions *SuperPositionsTransactorSession) SafeBatchTransferFrom(from common.Address, to common.Address, ids []*big.Int, amounts []*big.Int, data []byte) (*types.Transaction, error) {
	return _SuperPositions.Contract.SafeBatchTransferFrom(&_SuperPositions.TransactOpts, from, to, ids, amounts, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data) returns()
func (_SuperPositions *SuperPositionsTransactor) SafeTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, id *big.Int, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "safeTransferFrom", from, to, id, amount, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data) returns()
func (_SuperPositions *SuperPositionsSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _SuperPositions.Contract.SafeTransferFrom(&_SuperPositions.TransactOpts, from, to, id, amount, data)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0xf242432a.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data) returns()
func (_SuperPositions *SuperPositionsTransactorSession) SafeTransferFrom(from common.Address, to common.Address, id *big.Int, amount *big.Int, data []byte) (*types.Transaction, error) {
	return _SuperPositions.Contract.SafeTransferFrom(&_SuperPositions.TransactOpts, from, to, id, amount, data)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_SuperPositions *SuperPositionsTransactor) SetApprovalForAll(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "setApprovalForAll", operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_SuperPositions *SuperPositionsSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _SuperPositions.Contract.SetApprovalForAll(&_SuperPositions.TransactOpts, operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_SuperPositions *SuperPositionsTransactorSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _SuperPositions.Contract.SetApprovalForAll(&_SuperPositions.TransactOpts, operator, approved)
}

// SetApprovalForMany is a paid mutator transaction binding the contract method 0x5fa8d764.
//
// Solidity: function setApprovalForMany(address operator, uint256[] ids, uint256[] amounts) returns()
func (_SuperPositions *SuperPositionsTransactor) SetApprovalForMany(opts *bind.TransactOpts, operator common.Address, ids []*big.Int, amounts []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "setApprovalForMany", operator, ids, amounts)
}

// SetApprovalForMany is a paid mutator transaction binding the contract method 0x5fa8d764.
//
// Solidity: function setApprovalForMany(address operator, uint256[] ids, uint256[] amounts) returns()
func (_SuperPositions *SuperPositionsSession) SetApprovalForMany(operator common.Address, ids []*big.Int, amounts []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.SetApprovalForMany(&_SuperPositions.TransactOpts, operator, ids, amounts)
}

// SetApprovalForMany is a paid mutator transaction binding the contract method 0x5fa8d764.
//
// Solidity: function setApprovalForMany(address operator, uint256[] ids, uint256[] amounts) returns()
func (_SuperPositions *SuperPositionsTransactorSession) SetApprovalForMany(operator common.Address, ids []*big.Int, amounts []*big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.SetApprovalForMany(&_SuperPositions.TransactOpts, operator, ids, amounts)
}

// SetApprovalForOne is a paid mutator transaction binding the contract method 0xa49f9516.
//
// Solidity: function setApprovalForOne(address operator, uint256 id, uint256 amount) returns()
func (_SuperPositions *SuperPositionsTransactor) SetApprovalForOne(opts *bind.TransactOpts, operator common.Address, id *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "setApprovalForOne", operator, id, amount)
}

// SetApprovalForOne is a paid mutator transaction binding the contract method 0xa49f9516.
//
// Solidity: function setApprovalForOne(address operator, uint256 id, uint256 amount) returns()
func (_SuperPositions *SuperPositionsSession) SetApprovalForOne(operator common.Address, id *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.SetApprovalForOne(&_SuperPositions.TransactOpts, operator, id, amount)
}

// SetApprovalForOne is a paid mutator transaction binding the contract method 0xa49f9516.
//
// Solidity: function setApprovalForOne(address operator, uint256 id, uint256 amount) returns()
func (_SuperPositions *SuperPositionsTransactorSession) SetApprovalForOne(operator common.Address, id *big.Int, amount *big.Int) (*types.Transaction, error) {
	return _SuperPositions.Contract.SetApprovalForOne(&_SuperPositions.TransactOpts, operator, id, amount)
}

// SetDynamicURI is a paid mutator transaction binding the contract method 0xed7a8e42.
//
// Solidity: function setDynamicURI(string dynamicURI_, bool freeze_) returns()
func (_SuperPositions *SuperPositionsTransactor) SetDynamicURI(opts *bind.TransactOpts, dynamicURI_ string, freeze_ bool) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "setDynamicURI", dynamicURI_, freeze_)
}

// SetDynamicURI is a paid mutator transaction binding the contract method 0xed7a8e42.
//
// Solidity: function setDynamicURI(string dynamicURI_, bool freeze_) returns()
func (_SuperPositions *SuperPositionsSession) SetDynamicURI(dynamicURI_ string, freeze_ bool) (*types.Transaction, error) {
	return _SuperPositions.Contract.SetDynamicURI(&_SuperPositions.TransactOpts, dynamicURI_, freeze_)
}

// SetDynamicURI is a paid mutator transaction binding the contract method 0xed7a8e42.
//
// Solidity: function setDynamicURI(string dynamicURI_, bool freeze_) returns()
func (_SuperPositions *SuperPositionsTransactorSession) SetDynamicURI(dynamicURI_ string, freeze_ bool) (*types.Transaction, error) {
	return _SuperPositions.Contract.SetDynamicURI(&_SuperPositions.TransactOpts, dynamicURI_, freeze_)
}

// StateMultiSync is a paid mutator transaction binding the contract method 0x49e5b649.
//
// Solidity: function stateMultiSync((uint256,bytes) data_) returns(uint64 srcChainId_)
func (_SuperPositions *SuperPositionsTransactor) StateMultiSync(opts *bind.TransactOpts, data_ AMBMessage) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "stateMultiSync", data_)
}

// StateMultiSync is a paid mutator transaction binding the contract method 0x49e5b649.
//
// Solidity: function stateMultiSync((uint256,bytes) data_) returns(uint64 srcChainId_)
func (_SuperPositions *SuperPositionsSession) StateMultiSync(data_ AMBMessage) (*types.Transaction, error) {
	return _SuperPositions.Contract.StateMultiSync(&_SuperPositions.TransactOpts, data_)
}

// StateMultiSync is a paid mutator transaction binding the contract method 0x49e5b649.
//
// Solidity: function stateMultiSync((uint256,bytes) data_) returns(uint64 srcChainId_)
func (_SuperPositions *SuperPositionsTransactorSession) StateMultiSync(data_ AMBMessage) (*types.Transaction, error) {
	return _SuperPositions.Contract.StateMultiSync(&_SuperPositions.TransactOpts, data_)
}

// StateSync is a paid mutator transaction binding the contract method 0x33e30721.
//
// Solidity: function stateSync((uint256,bytes) data_) returns(uint64 srcChainId_)
func (_SuperPositions *SuperPositionsTransactor) StateSync(opts *bind.TransactOpts, data_ AMBMessage) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "stateSync", data_)
}

// StateSync is a paid mutator transaction binding the contract method 0x33e30721.
//
// Solidity: function stateSync((uint256,bytes) data_) returns(uint64 srcChainId_)
func (_SuperPositions *SuperPositionsSession) StateSync(data_ AMBMessage) (*types.Transaction, error) {
	return _SuperPositions.Contract.StateSync(&_SuperPositions.TransactOpts, data_)
}

// StateSync is a paid mutator transaction binding the contract method 0x33e30721.
//
// Solidity: function stateSync((uint256,bytes) data_) returns(uint64 srcChainId_)
func (_SuperPositions *SuperPositionsTransactorSession) StateSync(data_ AMBMessage) (*types.Transaction, error) {
	return _SuperPositions.Contract.StateSync(&_SuperPositions.TransactOpts, data_)
}

// StateSyncBroadcast is a paid mutator transaction binding the contract method 0xe6ddad4c.
//
// Solidity: function stateSyncBroadcast(bytes data_) payable returns()
func (_SuperPositions *SuperPositionsTransactor) StateSyncBroadcast(opts *bind.TransactOpts, data_ []byte) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "stateSyncBroadcast", data_)
}

// StateSyncBroadcast is a paid mutator transaction binding the contract method 0xe6ddad4c.
//
// Solidity: function stateSyncBroadcast(bytes data_) payable returns()
func (_SuperPositions *SuperPositionsSession) StateSyncBroadcast(data_ []byte) (*types.Transaction, error) {
	return _SuperPositions.Contract.StateSyncBroadcast(&_SuperPositions.TransactOpts, data_)
}

// StateSyncBroadcast is a paid mutator transaction binding the contract method 0xe6ddad4c.
//
// Solidity: function stateSyncBroadcast(bytes data_) payable returns()
func (_SuperPositions *SuperPositionsTransactorSession) StateSyncBroadcast(data_ []byte) (*types.Transaction, error) {
	return _SuperPositions.Contract.StateSyncBroadcast(&_SuperPositions.TransactOpts, data_)
}

// TransmuteBatchToERC1155A is a paid mutator transaction binding the contract method 0x5029d0c8.
//
// Solidity: function transmuteBatchToERC1155A(address owner, uint256[] ids, uint256[] amounts, address receiver) returns()
func (_SuperPositions *SuperPositionsTransactor) TransmuteBatchToERC1155A(opts *bind.TransactOpts, owner common.Address, ids []*big.Int, amounts []*big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "transmuteBatchToERC1155A", owner, ids, amounts, receiver)
}

// TransmuteBatchToERC1155A is a paid mutator transaction binding the contract method 0x5029d0c8.
//
// Solidity: function transmuteBatchToERC1155A(address owner, uint256[] ids, uint256[] amounts, address receiver) returns()
func (_SuperPositions *SuperPositionsSession) TransmuteBatchToERC1155A(owner common.Address, ids []*big.Int, amounts []*big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.Contract.TransmuteBatchToERC1155A(&_SuperPositions.TransactOpts, owner, ids, amounts, receiver)
}

// TransmuteBatchToERC1155A is a paid mutator transaction binding the contract method 0x5029d0c8.
//
// Solidity: function transmuteBatchToERC1155A(address owner, uint256[] ids, uint256[] amounts, address receiver) returns()
func (_SuperPositions *SuperPositionsTransactorSession) TransmuteBatchToERC1155A(owner common.Address, ids []*big.Int, amounts []*big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.Contract.TransmuteBatchToERC1155A(&_SuperPositions.TransactOpts, owner, ids, amounts, receiver)
}

// TransmuteBatchToERC20 is a paid mutator transaction binding the contract method 0xec737321.
//
// Solidity: function transmuteBatchToERC20(address owner, uint256[] ids, uint256[] amounts, address receiver) returns()
func (_SuperPositions *SuperPositionsTransactor) TransmuteBatchToERC20(opts *bind.TransactOpts, owner common.Address, ids []*big.Int, amounts []*big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "transmuteBatchToERC20", owner, ids, amounts, receiver)
}

// TransmuteBatchToERC20 is a paid mutator transaction binding the contract method 0xec737321.
//
// Solidity: function transmuteBatchToERC20(address owner, uint256[] ids, uint256[] amounts, address receiver) returns()
func (_SuperPositions *SuperPositionsSession) TransmuteBatchToERC20(owner common.Address, ids []*big.Int, amounts []*big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.Contract.TransmuteBatchToERC20(&_SuperPositions.TransactOpts, owner, ids, amounts, receiver)
}

// TransmuteBatchToERC20 is a paid mutator transaction binding the contract method 0xec737321.
//
// Solidity: function transmuteBatchToERC20(address owner, uint256[] ids, uint256[] amounts, address receiver) returns()
func (_SuperPositions *SuperPositionsTransactorSession) TransmuteBatchToERC20(owner common.Address, ids []*big.Int, amounts []*big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.Contract.TransmuteBatchToERC20(&_SuperPositions.TransactOpts, owner, ids, amounts, receiver)
}

// TransmuteToERC1155A is a paid mutator transaction binding the contract method 0x9473655c.
//
// Solidity: function transmuteToERC1155A(address owner, uint256 id, uint256 amount, address receiver) returns()
func (_SuperPositions *SuperPositionsTransactor) TransmuteToERC1155A(opts *bind.TransactOpts, owner common.Address, id *big.Int, amount *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "transmuteToERC1155A", owner, id, amount, receiver)
}

// TransmuteToERC1155A is a paid mutator transaction binding the contract method 0x9473655c.
//
// Solidity: function transmuteToERC1155A(address owner, uint256 id, uint256 amount, address receiver) returns()
func (_SuperPositions *SuperPositionsSession) TransmuteToERC1155A(owner common.Address, id *big.Int, amount *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.Contract.TransmuteToERC1155A(&_SuperPositions.TransactOpts, owner, id, amount, receiver)
}

// TransmuteToERC1155A is a paid mutator transaction binding the contract method 0x9473655c.
//
// Solidity: function transmuteToERC1155A(address owner, uint256 id, uint256 amount, address receiver) returns()
func (_SuperPositions *SuperPositionsTransactorSession) TransmuteToERC1155A(owner common.Address, id *big.Int, amount *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.Contract.TransmuteToERC1155A(&_SuperPositions.TransactOpts, owner, id, amount, receiver)
}

// TransmuteToERC20 is a paid mutator transaction binding the contract method 0x7081ce5e.
//
// Solidity: function transmuteToERC20(address owner, uint256 id, uint256 amount, address receiver) returns()
func (_SuperPositions *SuperPositionsTransactor) TransmuteToERC20(opts *bind.TransactOpts, owner common.Address, id *big.Int, amount *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "transmuteToERC20", owner, id, amount, receiver)
}

// TransmuteToERC20 is a paid mutator transaction binding the contract method 0x7081ce5e.
//
// Solidity: function transmuteToERC20(address owner, uint256 id, uint256 amount, address receiver) returns()
func (_SuperPositions *SuperPositionsSession) TransmuteToERC20(owner common.Address, id *big.Int, amount *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.Contract.TransmuteToERC20(&_SuperPositions.TransactOpts, owner, id, amount, receiver)
}

// TransmuteToERC20 is a paid mutator transaction binding the contract method 0x7081ce5e.
//
// Solidity: function transmuteToERC20(address owner, uint256 id, uint256 amount, address receiver) returns()
func (_SuperPositions *SuperPositionsTransactorSession) TransmuteToERC20(owner common.Address, id *big.Int, amount *big.Int, receiver common.Address) (*types.Transaction, error) {
	return _SuperPositions.Contract.TransmuteToERC20(&_SuperPositions.TransactOpts, owner, id, amount, receiver)
}

// UpdateTxHistory is a paid mutator transaction binding the contract method 0x4ec1bec7.
//
// Solidity: function updateTxHistory(uint256 payloadId_, uint256 txInfo_, address receiverAddressSP_) returns()
func (_SuperPositions *SuperPositionsTransactor) UpdateTxHistory(opts *bind.TransactOpts, payloadId_ *big.Int, txInfo_ *big.Int, receiverAddressSP_ common.Address) (*types.Transaction, error) {
	return _SuperPositions.contract.Transact(opts, "updateTxHistory", payloadId_, txInfo_, receiverAddressSP_)
}

// UpdateTxHistory is a paid mutator transaction binding the contract method 0x4ec1bec7.
//
// Solidity: function updateTxHistory(uint256 payloadId_, uint256 txInfo_, address receiverAddressSP_) returns()
func (_SuperPositions *SuperPositionsSession) UpdateTxHistory(payloadId_ *big.Int, txInfo_ *big.Int, receiverAddressSP_ common.Address) (*types.Transaction, error) {
	return _SuperPositions.Contract.UpdateTxHistory(&_SuperPositions.TransactOpts, payloadId_, txInfo_, receiverAddressSP_)
}

// UpdateTxHistory is a paid mutator transaction binding the contract method 0x4ec1bec7.
//
// Solidity: function updateTxHistory(uint256 payloadId_, uint256 txInfo_, address receiverAddressSP_) returns()
func (_SuperPositions *SuperPositionsTransactorSession) UpdateTxHistory(payloadId_ *big.Int, txInfo_ *big.Int, receiverAddressSP_ common.Address) (*types.Transaction, error) {
	return _SuperPositions.Contract.UpdateTxHistory(&_SuperPositions.TransactOpts, payloadId_, txInfo_, receiverAddressSP_)
}

// SuperPositionsAERC20TokenRegisteredIterator is returned from FilterAERC20TokenRegistered and is used to iterate over the raw logs and unpacked data for AERC20TokenRegistered events raised by the SuperPositions contract.
type SuperPositionsAERC20TokenRegisteredIterator struct {
	Event *SuperPositionsAERC20TokenRegistered // Event containing the contract specifics and raw log

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
func (it *SuperPositionsAERC20TokenRegisteredIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsAERC20TokenRegistered)
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
		it.Event = new(SuperPositionsAERC20TokenRegistered)
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
func (it *SuperPositionsAERC20TokenRegisteredIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsAERC20TokenRegisteredIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsAERC20TokenRegistered represents a AERC20TokenRegistered event raised by the SuperPositions contract.
type SuperPositionsAERC20TokenRegistered struct {
	TokenId      *big.Int
	TokenAddress common.Address
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterAERC20TokenRegistered is a free log retrieval operation binding the contract event 0x733ac2a007cd3853c362154b5f081e3ad8f60fd4e892fa3a0ca14a266ff897f8.
//
// Solidity: event AERC20TokenRegistered(uint256 indexed tokenId, address indexed tokenAddress)
func (_SuperPositions *SuperPositionsFilterer) FilterAERC20TokenRegistered(opts *bind.FilterOpts, tokenId []*big.Int, tokenAddress []common.Address) (*SuperPositionsAERC20TokenRegisteredIterator, error) {

	var tokenIdRule []interface{}
	for _, tokenIdItem := range tokenId {
		tokenIdRule = append(tokenIdRule, tokenIdItem)
	}
	var tokenAddressRule []interface{}
	for _, tokenAddressItem := range tokenAddress {
		tokenAddressRule = append(tokenAddressRule, tokenAddressItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "AERC20TokenRegistered", tokenIdRule, tokenAddressRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsAERC20TokenRegisteredIterator{contract: _SuperPositions.contract, event: "AERC20TokenRegistered", logs: logs, sub: sub}, nil
}

// WatchAERC20TokenRegistered is a free log subscription operation binding the contract event 0x733ac2a007cd3853c362154b5f081e3ad8f60fd4e892fa3a0ca14a266ff897f8.
//
// Solidity: event AERC20TokenRegistered(uint256 indexed tokenId, address indexed tokenAddress)
func (_SuperPositions *SuperPositionsFilterer) WatchAERC20TokenRegistered(opts *bind.WatchOpts, sink chan<- *SuperPositionsAERC20TokenRegistered, tokenId []*big.Int, tokenAddress []common.Address) (event.Subscription, error) {

	var tokenIdRule []interface{}
	for _, tokenIdItem := range tokenId {
		tokenIdRule = append(tokenIdRule, tokenIdItem)
	}
	var tokenAddressRule []interface{}
	for _, tokenAddressItem := range tokenAddress {
		tokenAddressRule = append(tokenAddressRule, tokenAddressItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "AERC20TokenRegistered", tokenIdRule, tokenAddressRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsAERC20TokenRegistered)
				if err := _SuperPositions.contract.UnpackLog(event, "AERC20TokenRegistered", log); err != nil {
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

// ParseAERC20TokenRegistered is a log parse operation binding the contract event 0x733ac2a007cd3853c362154b5f081e3ad8f60fd4e892fa3a0ca14a266ff897f8.
//
// Solidity: event AERC20TokenRegistered(uint256 indexed tokenId, address indexed tokenAddress)
func (_SuperPositions *SuperPositionsFilterer) ParseAERC20TokenRegistered(log types.Log) (*SuperPositionsAERC20TokenRegistered, error) {
	event := new(SuperPositionsAERC20TokenRegistered)
	if err := _SuperPositions.contract.UnpackLog(event, "AERC20TokenRegistered", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsApprovalForAllIterator is returned from FilterApprovalForAll and is used to iterate over the raw logs and unpacked data for ApprovalForAll events raised by the SuperPositions contract.
type SuperPositionsApprovalForAllIterator struct {
	Event *SuperPositionsApprovalForAll // Event containing the contract specifics and raw log

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
func (it *SuperPositionsApprovalForAllIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsApprovalForAll)
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
		it.Event = new(SuperPositionsApprovalForAll)
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
func (it *SuperPositionsApprovalForAllIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsApprovalForAllIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsApprovalForAll represents a ApprovalForAll event raised by the SuperPositions contract.
type SuperPositionsApprovalForAll struct {
	Account  common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApprovalForAll is a free log retrieval operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_SuperPositions *SuperPositionsFilterer) FilterApprovalForAll(opts *bind.FilterOpts, account []common.Address, operator []common.Address) (*SuperPositionsApprovalForAllIterator, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsApprovalForAllIterator{contract: _SuperPositions.contract, event: "ApprovalForAll", logs: logs, sub: sub}, nil
}

// WatchApprovalForAll is a free log subscription operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_SuperPositions *SuperPositionsFilterer) WatchApprovalForAll(opts *bind.WatchOpts, sink chan<- *SuperPositionsApprovalForAll, account []common.Address, operator []common.Address) (event.Subscription, error) {

	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "ApprovalForAll", accountRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsApprovalForAll)
				if err := _SuperPositions.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
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

// ParseApprovalForAll is a log parse operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed account, address indexed operator, bool approved)
func (_SuperPositions *SuperPositionsFilterer) ParseApprovalForAll(log types.Log) (*SuperPositionsApprovalForAll, error) {
	event := new(SuperPositionsApprovalForAll)
	if err := _SuperPositions.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsApprovalForOneIterator is returned from FilterApprovalForOne and is used to iterate over the raw logs and unpacked data for ApprovalForOne events raised by the SuperPositions contract.
type SuperPositionsApprovalForOneIterator struct {
	Event *SuperPositionsApprovalForOne // Event containing the contract specifics and raw log

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
func (it *SuperPositionsApprovalForOneIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsApprovalForOne)
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
		it.Event = new(SuperPositionsApprovalForOne)
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
func (it *SuperPositionsApprovalForOneIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsApprovalForOneIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsApprovalForOne represents a ApprovalForOne event raised by the SuperPositions contract.
type SuperPositionsApprovalForOne struct {
	Owner   common.Address
	Spender common.Address
	Id      *big.Int
	Amount  *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterApprovalForOne is a free log retrieval operation binding the contract event 0x875251d6c7be5b10ddb14ed4f59395338f15552062d4ad7723265838e316f9a8.
//
// Solidity: event ApprovalForOne(address indexed owner, address indexed spender, uint256 id, uint256 amount)
func (_SuperPositions *SuperPositionsFilterer) FilterApprovalForOne(opts *bind.FilterOpts, owner []common.Address, spender []common.Address) (*SuperPositionsApprovalForOneIterator, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var spenderRule []interface{}
	for _, spenderItem := range spender {
		spenderRule = append(spenderRule, spenderItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "ApprovalForOne", ownerRule, spenderRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsApprovalForOneIterator{contract: _SuperPositions.contract, event: "ApprovalForOne", logs: logs, sub: sub}, nil
}

// WatchApprovalForOne is a free log subscription operation binding the contract event 0x875251d6c7be5b10ddb14ed4f59395338f15552062d4ad7723265838e316f9a8.
//
// Solidity: event ApprovalForOne(address indexed owner, address indexed spender, uint256 id, uint256 amount)
func (_SuperPositions *SuperPositionsFilterer) WatchApprovalForOne(opts *bind.WatchOpts, sink chan<- *SuperPositionsApprovalForOne, owner []common.Address, spender []common.Address) (event.Subscription, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var spenderRule []interface{}
	for _, spenderItem := range spender {
		spenderRule = append(spenderRule, spenderItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "ApprovalForOne", ownerRule, spenderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsApprovalForOne)
				if err := _SuperPositions.contract.UnpackLog(event, "ApprovalForOne", log); err != nil {
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

// ParseApprovalForOne is a log parse operation binding the contract event 0x875251d6c7be5b10ddb14ed4f59395338f15552062d4ad7723265838e316f9a8.
//
// Solidity: event ApprovalForOne(address indexed owner, address indexed spender, uint256 id, uint256 amount)
func (_SuperPositions *SuperPositionsFilterer) ParseApprovalForOne(log types.Log) (*SuperPositionsApprovalForOne, error) {
	event := new(SuperPositionsApprovalForOne)
	if err := _SuperPositions.contract.UnpackLog(event, "ApprovalForOne", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsCompletedIterator is returned from FilterCompleted and is used to iterate over the raw logs and unpacked data for Completed events raised by the SuperPositions contract.
type SuperPositionsCompletedIterator struct {
	Event *SuperPositionsCompleted // Event containing the contract specifics and raw log

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
func (it *SuperPositionsCompletedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsCompleted)
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
		it.Event = new(SuperPositionsCompleted)
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
func (it *SuperPositionsCompletedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsCompletedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsCompleted represents a Completed event raised by the SuperPositions contract.
type SuperPositionsCompleted struct {
	TxId *big.Int
	Raw  types.Log // Blockchain specific contextual infos
}

// FilterCompleted is a free log retrieval operation binding the contract event 0xdfd517ed69f8a0a57d49fe494e4864fac3cfe3585c14c0bfddf39f72463ec3fd.
//
// Solidity: event Completed(uint256 indexed txId)
func (_SuperPositions *SuperPositionsFilterer) FilterCompleted(opts *bind.FilterOpts, txId []*big.Int) (*SuperPositionsCompletedIterator, error) {

	var txIdRule []interface{}
	for _, txIdItem := range txId {
		txIdRule = append(txIdRule, txIdItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "Completed", txIdRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsCompletedIterator{contract: _SuperPositions.contract, event: "Completed", logs: logs, sub: sub}, nil
}

// WatchCompleted is a free log subscription operation binding the contract event 0xdfd517ed69f8a0a57d49fe494e4864fac3cfe3585c14c0bfddf39f72463ec3fd.
//
// Solidity: event Completed(uint256 indexed txId)
func (_SuperPositions *SuperPositionsFilterer) WatchCompleted(opts *bind.WatchOpts, sink chan<- *SuperPositionsCompleted, txId []*big.Int) (event.Subscription, error) {

	var txIdRule []interface{}
	for _, txIdItem := range txId {
		txIdRule = append(txIdRule, txIdItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "Completed", txIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsCompleted)
				if err := _SuperPositions.contract.UnpackLog(event, "Completed", log); err != nil {
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

// ParseCompleted is a log parse operation binding the contract event 0xdfd517ed69f8a0a57d49fe494e4864fac3cfe3585c14c0bfddf39f72463ec3fd.
//
// Solidity: event Completed(uint256 indexed txId)
func (_SuperPositions *SuperPositionsFilterer) ParseCompleted(log types.Log) (*SuperPositionsCompleted, error) {
	event := new(SuperPositionsCompleted)
	if err := _SuperPositions.contract.UnpackLog(event, "Completed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsDynamicURIUpdatedIterator is returned from FilterDynamicURIUpdated and is used to iterate over the raw logs and unpacked data for DynamicURIUpdated events raised by the SuperPositions contract.
type SuperPositionsDynamicURIUpdatedIterator struct {
	Event *SuperPositionsDynamicURIUpdated // Event containing the contract specifics and raw log

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
func (it *SuperPositionsDynamicURIUpdatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsDynamicURIUpdated)
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
		it.Event = new(SuperPositionsDynamicURIUpdated)
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
func (it *SuperPositionsDynamicURIUpdatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsDynamicURIUpdatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsDynamicURIUpdated represents a DynamicURIUpdated event raised by the SuperPositions contract.
type SuperPositionsDynamicURIUpdated struct {
	OldURI common.Hash
	NewURI common.Hash
	Frozen bool
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterDynamicURIUpdated is a free log retrieval operation binding the contract event 0x5386175ed3f7187aa4eae65398696731724636ea68ccda712d3119159f5b1159.
//
// Solidity: event DynamicURIUpdated(string indexed oldURI, string indexed newURI, bool indexed frozen)
func (_SuperPositions *SuperPositionsFilterer) FilterDynamicURIUpdated(opts *bind.FilterOpts, oldURI []string, newURI []string, frozen []bool) (*SuperPositionsDynamicURIUpdatedIterator, error) {

	var oldURIRule []interface{}
	for _, oldURIItem := range oldURI {
		oldURIRule = append(oldURIRule, oldURIItem)
	}
	var newURIRule []interface{}
	for _, newURIItem := range newURI {
		newURIRule = append(newURIRule, newURIItem)
	}
	var frozenRule []interface{}
	for _, frozenItem := range frozen {
		frozenRule = append(frozenRule, frozenItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "DynamicURIUpdated", oldURIRule, newURIRule, frozenRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsDynamicURIUpdatedIterator{contract: _SuperPositions.contract, event: "DynamicURIUpdated", logs: logs, sub: sub}, nil
}

// WatchDynamicURIUpdated is a free log subscription operation binding the contract event 0x5386175ed3f7187aa4eae65398696731724636ea68ccda712d3119159f5b1159.
//
// Solidity: event DynamicURIUpdated(string indexed oldURI, string indexed newURI, bool indexed frozen)
func (_SuperPositions *SuperPositionsFilterer) WatchDynamicURIUpdated(opts *bind.WatchOpts, sink chan<- *SuperPositionsDynamicURIUpdated, oldURI []string, newURI []string, frozen []bool) (event.Subscription, error) {

	var oldURIRule []interface{}
	for _, oldURIItem := range oldURI {
		oldURIRule = append(oldURIRule, oldURIItem)
	}
	var newURIRule []interface{}
	for _, newURIItem := range newURI {
		newURIRule = append(newURIRule, newURIItem)
	}
	var frozenRule []interface{}
	for _, frozenItem := range frozen {
		frozenRule = append(frozenRule, frozenItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "DynamicURIUpdated", oldURIRule, newURIRule, frozenRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsDynamicURIUpdated)
				if err := _SuperPositions.contract.UnpackLog(event, "DynamicURIUpdated", log); err != nil {
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

// ParseDynamicURIUpdated is a log parse operation binding the contract event 0x5386175ed3f7187aa4eae65398696731724636ea68ccda712d3119159f5b1159.
//
// Solidity: event DynamicURIUpdated(string indexed oldURI, string indexed newURI, bool indexed frozen)
func (_SuperPositions *SuperPositionsFilterer) ParseDynamicURIUpdated(log types.Log) (*SuperPositionsDynamicURIUpdated, error) {
	event := new(SuperPositionsDynamicURIUpdated)
	if err := _SuperPositions.contract.UnpackLog(event, "DynamicURIUpdated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsTransferBatchIterator is returned from FilterTransferBatch and is used to iterate over the raw logs and unpacked data for TransferBatch events raised by the SuperPositions contract.
type SuperPositionsTransferBatchIterator struct {
	Event *SuperPositionsTransferBatch // Event containing the contract specifics and raw log

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
func (it *SuperPositionsTransferBatchIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsTransferBatch)
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
		it.Event = new(SuperPositionsTransferBatch)
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
func (it *SuperPositionsTransferBatchIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsTransferBatchIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsTransferBatch represents a TransferBatch event raised by the SuperPositions contract.
type SuperPositionsTransferBatch struct {
	Operator common.Address
	From     common.Address
	To       common.Address
	Ids      []*big.Int
	Values   []*big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterTransferBatch is a free log retrieval operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_SuperPositions *SuperPositionsFilterer) FilterTransferBatch(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*SuperPositionsTransferBatchIterator, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsTransferBatchIterator{contract: _SuperPositions.contract, event: "TransferBatch", logs: logs, sub: sub}, nil
}

// WatchTransferBatch is a free log subscription operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_SuperPositions *SuperPositionsFilterer) WatchTransferBatch(opts *bind.WatchOpts, sink chan<- *SuperPositionsTransferBatch, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "TransferBatch", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsTransferBatch)
				if err := _SuperPositions.contract.UnpackLog(event, "TransferBatch", log); err != nil {
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

// ParseTransferBatch is a log parse operation binding the contract event 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb.
//
// Solidity: event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
func (_SuperPositions *SuperPositionsFilterer) ParseTransferBatch(log types.Log) (*SuperPositionsTransferBatch, error) {
	event := new(SuperPositionsTransferBatch)
	if err := _SuperPositions.contract.UnpackLog(event, "TransferBatch", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsTransferSingleIterator is returned from FilterTransferSingle and is used to iterate over the raw logs and unpacked data for TransferSingle events raised by the SuperPositions contract.
type SuperPositionsTransferSingleIterator struct {
	Event *SuperPositionsTransferSingle // Event containing the contract specifics and raw log

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
func (it *SuperPositionsTransferSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsTransferSingle)
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
		it.Event = new(SuperPositionsTransferSingle)
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
func (it *SuperPositionsTransferSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsTransferSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsTransferSingle represents a TransferSingle event raised by the SuperPositions contract.
type SuperPositionsTransferSingle struct {
	Operator common.Address
	From     common.Address
	To       common.Address
	Id       *big.Int
	Value    *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterTransferSingle is a free log retrieval operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_SuperPositions *SuperPositionsFilterer) FilterTransferSingle(opts *bind.FilterOpts, operator []common.Address, from []common.Address, to []common.Address) (*SuperPositionsTransferSingleIterator, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsTransferSingleIterator{contract: _SuperPositions.contract, event: "TransferSingle", logs: logs, sub: sub}, nil
}

// WatchTransferSingle is a free log subscription operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_SuperPositions *SuperPositionsFilterer) WatchTransferSingle(opts *bind.WatchOpts, sink chan<- *SuperPositionsTransferSingle, operator []common.Address, from []common.Address, to []common.Address) (event.Subscription, error) {

	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}
	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "TransferSingle", operatorRule, fromRule, toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsTransferSingle)
				if err := _SuperPositions.contract.UnpackLog(event, "TransferSingle", log); err != nil {
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

// ParseTransferSingle is a log parse operation binding the contract event 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62.
//
// Solidity: event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
func (_SuperPositions *SuperPositionsFilterer) ParseTransferSingle(log types.Log) (*SuperPositionsTransferSingle, error) {
	event := new(SuperPositionsTransferSingle)
	if err := _SuperPositions.contract.UnpackLog(event, "TransferSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsTransmutedBatchToERC1155AIterator is returned from FilterTransmutedBatchToERC1155A and is used to iterate over the raw logs and unpacked data for TransmutedBatchToERC1155A events raised by the SuperPositions contract.
type SuperPositionsTransmutedBatchToERC1155AIterator struct {
	Event *SuperPositionsTransmutedBatchToERC1155A // Event containing the contract specifics and raw log

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
func (it *SuperPositionsTransmutedBatchToERC1155AIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsTransmutedBatchToERC1155A)
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
		it.Event = new(SuperPositionsTransmutedBatchToERC1155A)
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
func (it *SuperPositionsTransmutedBatchToERC1155AIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsTransmutedBatchToERC1155AIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsTransmutedBatchToERC1155A represents a TransmutedBatchToERC1155A event raised by the SuperPositions contract.
type SuperPositionsTransmutedBatchToERC1155A struct {
	User     common.Address
	Ids      []*big.Int
	Amounts  []*big.Int
	Receiver common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterTransmutedBatchToERC1155A is a free log retrieval operation binding the contract event 0x2ec4237e89b1c7ccb8710672dc83af16f1949c33f3b313eeaab1a626e6aa4427.
//
// Solidity: event TransmutedBatchToERC1155A(address indexed user, uint256[] ids, uint256[] amounts, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) FilterTransmutedBatchToERC1155A(opts *bind.FilterOpts, user []common.Address, receiver []common.Address) (*SuperPositionsTransmutedBatchToERC1155AIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "TransmutedBatchToERC1155A", userRule, receiverRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsTransmutedBatchToERC1155AIterator{contract: _SuperPositions.contract, event: "TransmutedBatchToERC1155A", logs: logs, sub: sub}, nil
}

// WatchTransmutedBatchToERC1155A is a free log subscription operation binding the contract event 0x2ec4237e89b1c7ccb8710672dc83af16f1949c33f3b313eeaab1a626e6aa4427.
//
// Solidity: event TransmutedBatchToERC1155A(address indexed user, uint256[] ids, uint256[] amounts, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) WatchTransmutedBatchToERC1155A(opts *bind.WatchOpts, sink chan<- *SuperPositionsTransmutedBatchToERC1155A, user []common.Address, receiver []common.Address) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "TransmutedBatchToERC1155A", userRule, receiverRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsTransmutedBatchToERC1155A)
				if err := _SuperPositions.contract.UnpackLog(event, "TransmutedBatchToERC1155A", log); err != nil {
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

// ParseTransmutedBatchToERC1155A is a log parse operation binding the contract event 0x2ec4237e89b1c7ccb8710672dc83af16f1949c33f3b313eeaab1a626e6aa4427.
//
// Solidity: event TransmutedBatchToERC1155A(address indexed user, uint256[] ids, uint256[] amounts, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) ParseTransmutedBatchToERC1155A(log types.Log) (*SuperPositionsTransmutedBatchToERC1155A, error) {
	event := new(SuperPositionsTransmutedBatchToERC1155A)
	if err := _SuperPositions.contract.UnpackLog(event, "TransmutedBatchToERC1155A", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsTransmutedBatchToERC20Iterator is returned from FilterTransmutedBatchToERC20 and is used to iterate over the raw logs and unpacked data for TransmutedBatchToERC20 events raised by the SuperPositions contract.
type SuperPositionsTransmutedBatchToERC20Iterator struct {
	Event *SuperPositionsTransmutedBatchToERC20 // Event containing the contract specifics and raw log

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
func (it *SuperPositionsTransmutedBatchToERC20Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsTransmutedBatchToERC20)
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
		it.Event = new(SuperPositionsTransmutedBatchToERC20)
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
func (it *SuperPositionsTransmutedBatchToERC20Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsTransmutedBatchToERC20Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsTransmutedBatchToERC20 represents a TransmutedBatchToERC20 event raised by the SuperPositions contract.
type SuperPositionsTransmutedBatchToERC20 struct {
	User     common.Address
	Ids      []*big.Int
	Amounts  []*big.Int
	Receiver common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterTransmutedBatchToERC20 is a free log retrieval operation binding the contract event 0x1c57454fefbe0a2a0aa1926734e74f4cb5137003ccf5e6edfde51c79163fbf37.
//
// Solidity: event TransmutedBatchToERC20(address indexed user, uint256[] ids, uint256[] amounts, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) FilterTransmutedBatchToERC20(opts *bind.FilterOpts, user []common.Address, receiver []common.Address) (*SuperPositionsTransmutedBatchToERC20Iterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "TransmutedBatchToERC20", userRule, receiverRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsTransmutedBatchToERC20Iterator{contract: _SuperPositions.contract, event: "TransmutedBatchToERC20", logs: logs, sub: sub}, nil
}

// WatchTransmutedBatchToERC20 is a free log subscription operation binding the contract event 0x1c57454fefbe0a2a0aa1926734e74f4cb5137003ccf5e6edfde51c79163fbf37.
//
// Solidity: event TransmutedBatchToERC20(address indexed user, uint256[] ids, uint256[] amounts, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) WatchTransmutedBatchToERC20(opts *bind.WatchOpts, sink chan<- *SuperPositionsTransmutedBatchToERC20, user []common.Address, receiver []common.Address) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "TransmutedBatchToERC20", userRule, receiverRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsTransmutedBatchToERC20)
				if err := _SuperPositions.contract.UnpackLog(event, "TransmutedBatchToERC20", log); err != nil {
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

// ParseTransmutedBatchToERC20 is a log parse operation binding the contract event 0x1c57454fefbe0a2a0aa1926734e74f4cb5137003ccf5e6edfde51c79163fbf37.
//
// Solidity: event TransmutedBatchToERC20(address indexed user, uint256[] ids, uint256[] amounts, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) ParseTransmutedBatchToERC20(log types.Log) (*SuperPositionsTransmutedBatchToERC20, error) {
	event := new(SuperPositionsTransmutedBatchToERC20)
	if err := _SuperPositions.contract.UnpackLog(event, "TransmutedBatchToERC20", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsTransmutedToERC1155AIterator is returned from FilterTransmutedToERC1155A and is used to iterate over the raw logs and unpacked data for TransmutedToERC1155A events raised by the SuperPositions contract.
type SuperPositionsTransmutedToERC1155AIterator struct {
	Event *SuperPositionsTransmutedToERC1155A // Event containing the contract specifics and raw log

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
func (it *SuperPositionsTransmutedToERC1155AIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsTransmutedToERC1155A)
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
		it.Event = new(SuperPositionsTransmutedToERC1155A)
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
func (it *SuperPositionsTransmutedToERC1155AIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsTransmutedToERC1155AIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsTransmutedToERC1155A represents a TransmutedToERC1155A event raised by the SuperPositions contract.
type SuperPositionsTransmutedToERC1155A struct {
	User     common.Address
	Id       *big.Int
	Amount   *big.Int
	Receiver common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterTransmutedToERC1155A is a free log retrieval operation binding the contract event 0x9195fdebb74042f1bd7abc0ded779a6e10ae01e0ad5f5546cb7e421d65a56666.
//
// Solidity: event TransmutedToERC1155A(address indexed user, uint256 id, uint256 amount, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) FilterTransmutedToERC1155A(opts *bind.FilterOpts, user []common.Address, receiver []common.Address) (*SuperPositionsTransmutedToERC1155AIterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "TransmutedToERC1155A", userRule, receiverRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsTransmutedToERC1155AIterator{contract: _SuperPositions.contract, event: "TransmutedToERC1155A", logs: logs, sub: sub}, nil
}

// WatchTransmutedToERC1155A is a free log subscription operation binding the contract event 0x9195fdebb74042f1bd7abc0ded779a6e10ae01e0ad5f5546cb7e421d65a56666.
//
// Solidity: event TransmutedToERC1155A(address indexed user, uint256 id, uint256 amount, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) WatchTransmutedToERC1155A(opts *bind.WatchOpts, sink chan<- *SuperPositionsTransmutedToERC1155A, user []common.Address, receiver []common.Address) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "TransmutedToERC1155A", userRule, receiverRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsTransmutedToERC1155A)
				if err := _SuperPositions.contract.UnpackLog(event, "TransmutedToERC1155A", log); err != nil {
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

// ParseTransmutedToERC1155A is a log parse operation binding the contract event 0x9195fdebb74042f1bd7abc0ded779a6e10ae01e0ad5f5546cb7e421d65a56666.
//
// Solidity: event TransmutedToERC1155A(address indexed user, uint256 id, uint256 amount, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) ParseTransmutedToERC1155A(log types.Log) (*SuperPositionsTransmutedToERC1155A, error) {
	event := new(SuperPositionsTransmutedToERC1155A)
	if err := _SuperPositions.contract.UnpackLog(event, "TransmutedToERC1155A", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsTransmutedToERC20Iterator is returned from FilterTransmutedToERC20 and is used to iterate over the raw logs and unpacked data for TransmutedToERC20 events raised by the SuperPositions contract.
type SuperPositionsTransmutedToERC20Iterator struct {
	Event *SuperPositionsTransmutedToERC20 // Event containing the contract specifics and raw log

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
func (it *SuperPositionsTransmutedToERC20Iterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsTransmutedToERC20)
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
		it.Event = new(SuperPositionsTransmutedToERC20)
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
func (it *SuperPositionsTransmutedToERC20Iterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsTransmutedToERC20Iterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsTransmutedToERC20 represents a TransmutedToERC20 event raised by the SuperPositions contract.
type SuperPositionsTransmutedToERC20 struct {
	User     common.Address
	Id       *big.Int
	Amount   *big.Int
	Receiver common.Address
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterTransmutedToERC20 is a free log retrieval operation binding the contract event 0x4420f38d0f4ce916c1d0da8d37675c007978eaaa4a8c2cc4231fd52a7a57b614.
//
// Solidity: event TransmutedToERC20(address indexed user, uint256 id, uint256 amount, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) FilterTransmutedToERC20(opts *bind.FilterOpts, user []common.Address, receiver []common.Address) (*SuperPositionsTransmutedToERC20Iterator, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "TransmutedToERC20", userRule, receiverRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsTransmutedToERC20Iterator{contract: _SuperPositions.contract, event: "TransmutedToERC20", logs: logs, sub: sub}, nil
}

// WatchTransmutedToERC20 is a free log subscription operation binding the contract event 0x4420f38d0f4ce916c1d0da8d37675c007978eaaa4a8c2cc4231fd52a7a57b614.
//
// Solidity: event TransmutedToERC20(address indexed user, uint256 id, uint256 amount, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) WatchTransmutedToERC20(opts *bind.WatchOpts, sink chan<- *SuperPositionsTransmutedToERC20, user []common.Address, receiver []common.Address) (event.Subscription, error) {

	var userRule []interface{}
	for _, userItem := range user {
		userRule = append(userRule, userItem)
	}

	var receiverRule []interface{}
	for _, receiverItem := range receiver {
		receiverRule = append(receiverRule, receiverItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "TransmutedToERC20", userRule, receiverRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsTransmutedToERC20)
				if err := _SuperPositions.contract.UnpackLog(event, "TransmutedToERC20", log); err != nil {
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

// ParseTransmutedToERC20 is a log parse operation binding the contract event 0x4420f38d0f4ce916c1d0da8d37675c007978eaaa4a8c2cc4231fd52a7a57b614.
//
// Solidity: event TransmutedToERC20(address indexed user, uint256 id, uint256 amount, address indexed receiver)
func (_SuperPositions *SuperPositionsFilterer) ParseTransmutedToERC20(log types.Log) (*SuperPositionsTransmutedToERC20, error) {
	event := new(SuperPositionsTransmutedToERC20)
	if err := _SuperPositions.contract.UnpackLog(event, "TransmutedToERC20", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsTxHistorySetIterator is returned from FilterTxHistorySet and is used to iterate over the raw logs and unpacked data for TxHistorySet events raised by the SuperPositions contract.
type SuperPositionsTxHistorySetIterator struct {
	Event *SuperPositionsTxHistorySet // Event containing the contract specifics and raw log

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
func (it *SuperPositionsTxHistorySetIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsTxHistorySet)
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
		it.Event = new(SuperPositionsTxHistorySet)
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
func (it *SuperPositionsTxHistorySetIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsTxHistorySetIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsTxHistorySet represents a TxHistorySet event raised by the SuperPositions contract.
type SuperPositionsTxHistorySet struct {
	PayloadId       *big.Int
	TxInfo          *big.Int
	ReceiverAddress common.Address
	Raw             types.Log // Blockchain specific contextual infos
}

// FilterTxHistorySet is a free log retrieval operation binding the contract event 0x226fd1a430a7a15fa93582471a806bc430535d985fa9547a69921a9499bf492b.
//
// Solidity: event TxHistorySet(uint256 indexed payloadId, uint256 txInfo, address indexed receiverAddress)
func (_SuperPositions *SuperPositionsFilterer) FilterTxHistorySet(opts *bind.FilterOpts, payloadId []*big.Int, receiverAddress []common.Address) (*SuperPositionsTxHistorySetIterator, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	var receiverAddressRule []interface{}
	for _, receiverAddressItem := range receiverAddress {
		receiverAddressRule = append(receiverAddressRule, receiverAddressItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "TxHistorySet", payloadIdRule, receiverAddressRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsTxHistorySetIterator{contract: _SuperPositions.contract, event: "TxHistorySet", logs: logs, sub: sub}, nil
}

// WatchTxHistorySet is a free log subscription operation binding the contract event 0x226fd1a430a7a15fa93582471a806bc430535d985fa9547a69921a9499bf492b.
//
// Solidity: event TxHistorySet(uint256 indexed payloadId, uint256 txInfo, address indexed receiverAddress)
func (_SuperPositions *SuperPositionsFilterer) WatchTxHistorySet(opts *bind.WatchOpts, sink chan<- *SuperPositionsTxHistorySet, payloadId []*big.Int, receiverAddress []common.Address) (event.Subscription, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}

	var receiverAddressRule []interface{}
	for _, receiverAddressItem := range receiverAddress {
		receiverAddressRule = append(receiverAddressRule, receiverAddressItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "TxHistorySet", payloadIdRule, receiverAddressRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsTxHistorySet)
				if err := _SuperPositions.contract.UnpackLog(event, "TxHistorySet", log); err != nil {
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

// ParseTxHistorySet is a log parse operation binding the contract event 0x226fd1a430a7a15fa93582471a806bc430535d985fa9547a69921a9499bf492b.
//
// Solidity: event TxHistorySet(uint256 indexed payloadId, uint256 txInfo, address indexed receiverAddress)
func (_SuperPositions *SuperPositionsFilterer) ParseTxHistorySet(log types.Log) (*SuperPositionsTxHistorySet, error) {
	event := new(SuperPositionsTxHistorySet)
	if err := _SuperPositions.contract.UnpackLog(event, "TxHistorySet", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperPositionsURIIterator is returned from FilterURI and is used to iterate over the raw logs and unpacked data for URI events raised by the SuperPositions contract.
type SuperPositionsURIIterator struct {
	Event *SuperPositionsURI // Event containing the contract specifics and raw log

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
func (it *SuperPositionsURIIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperPositionsURI)
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
		it.Event = new(SuperPositionsURI)
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
func (it *SuperPositionsURIIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperPositionsURIIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperPositionsURI represents a URI event raised by the SuperPositions contract.
type SuperPositionsURI struct {
	Value string
	Id    *big.Int
	Raw   types.Log // Blockchain specific contextual infos
}

// FilterURI is a free log retrieval operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_SuperPositions *SuperPositionsFilterer) FilterURI(opts *bind.FilterOpts, id []*big.Int) (*SuperPositionsURIIterator, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _SuperPositions.contract.FilterLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return &SuperPositionsURIIterator{contract: _SuperPositions.contract, event: "URI", logs: logs, sub: sub}, nil
}

// WatchURI is a free log subscription operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_SuperPositions *SuperPositionsFilterer) WatchURI(opts *bind.WatchOpts, sink chan<- *SuperPositionsURI, id []*big.Int) (event.Subscription, error) {

	var idRule []interface{}
	for _, idItem := range id {
		idRule = append(idRule, idItem)
	}

	logs, sub, err := _SuperPositions.contract.WatchLogs(opts, "URI", idRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperPositionsURI)
				if err := _SuperPositions.contract.UnpackLog(event, "URI", log); err != nil {
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

// ParseURI is a log parse operation binding the contract event 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b.
//
// Solidity: event URI(string value, uint256 indexed id)
func (_SuperPositions *SuperPositionsFilterer) ParseURI(log types.Log) (*SuperPositionsURI, error) {
	event := new(SuperPositionsURI)
	if err := _SuperPositions.contract.UnpackLog(event, "URI", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
