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

// SFRouterMetaData contains all meta data concerning the SFRouter contract.
var SFRouterMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superRegistry_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"receive\",\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"CHAIN_ID\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint64\",\"internalType\":\"uint64\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"forwardDustToPaymaster\",\"inputs\":[{\"name\":\"token_\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"multiDstMultiVaultDeposit\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structMultiDstMultiVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[][]\",\"internalType\":\"uint8[][]\"},{\"name\":\"dstChainIds\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"},{\"name\":\"superformsData\",\"type\":\"tuple[]\",\"internalType\":\"structMultiVaultSFData[]\",\"components\":[{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"outputAmounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"maxSlippages\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"liqRequests\",\"type\":\"tuple[]\",\"internalType\":\"structLiqRequest[]\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwaps\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"retain4626s\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"multiDstMultiVaultWithdraw\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structMultiDstMultiVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[][]\",\"internalType\":\"uint8[][]\"},{\"name\":\"dstChainIds\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"},{\"name\":\"superformsData\",\"type\":\"tuple[]\",\"internalType\":\"structMultiVaultSFData[]\",\"components\":[{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"outputAmounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"maxSlippages\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"liqRequests\",\"type\":\"tuple[]\",\"internalType\":\"structLiqRequest[]\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwaps\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"retain4626s\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"multiDstSingleVaultDeposit\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structMultiDstSingleVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[][]\",\"internalType\":\"uint8[][]\"},{\"name\":\"dstChainIds\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"},{\"name\":\"superformsData\",\"type\":\"tuple[]\",\"internalType\":\"structSingleVaultSFData[]\",\"components\":[{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqRequest\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"multiDstSingleVaultWithdraw\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structMultiDstSingleVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[][]\",\"internalType\":\"uint8[][]\"},{\"name\":\"dstChainIds\",\"type\":\"uint64[]\",\"internalType\":\"uint64[]\"},{\"name\":\"superformsData\",\"type\":\"tuple[]\",\"internalType\":\"structSingleVaultSFData[]\",\"components\":[{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqRequest\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"payloadIds\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"singleDirectMultiVaultDeposit\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleDirectMultiVaultStateReq\",\"components\":[{\"name\":\"superformData\",\"type\":\"tuple\",\"internalType\":\"structMultiVaultSFData\",\"components\":[{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"outputAmounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"maxSlippages\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"liqRequests\",\"type\":\"tuple[]\",\"internalType\":\"structLiqRequest[]\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwaps\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"retain4626s\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"singleDirectMultiVaultWithdraw\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleDirectMultiVaultStateReq\",\"components\":[{\"name\":\"superformData\",\"type\":\"tuple\",\"internalType\":\"structMultiVaultSFData\",\"components\":[{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"outputAmounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"maxSlippages\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"liqRequests\",\"type\":\"tuple[]\",\"internalType\":\"structLiqRequest[]\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwaps\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"retain4626s\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"singleDirectSingleVaultDeposit\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleDirectSingleVaultStateReq\",\"components\":[{\"name\":\"superformData\",\"type\":\"tuple\",\"internalType\":\"structSingleVaultSFData\",\"components\":[{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqRequest\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"singleDirectSingleVaultWithdraw\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleDirectSingleVaultStateReq\",\"components\":[{\"name\":\"superformData\",\"type\":\"tuple\",\"internalType\":\"structSingleVaultSFData\",\"components\":[{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqRequest\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"singleXChainMultiVaultDeposit\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleXChainMultiVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"superformsData\",\"type\":\"tuple\",\"internalType\":\"structMultiVaultSFData\",\"components\":[{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"outputAmounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"maxSlippages\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"liqRequests\",\"type\":\"tuple[]\",\"internalType\":\"structLiqRequest[]\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwaps\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"retain4626s\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"singleXChainMultiVaultWithdraw\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleXChainMultiVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"superformsData\",\"type\":\"tuple\",\"internalType\":\"structMultiVaultSFData\",\"components\":[{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"amounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"outputAmounts\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"maxSlippages\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"liqRequests\",\"type\":\"tuple[]\",\"internalType\":\"structLiqRequest[]\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwaps\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"retain4626s\",\"type\":\"bool[]\",\"internalType\":\"bool[]\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"singleXChainSingleVaultDeposit\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleXChainSingleVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"superformData\",\"type\":\"tuple\",\"internalType\":\"structSingleVaultSFData\",\"components\":[{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqRequest\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"singleXChainSingleVaultWithdraw\",\"inputs\":[{\"name\":\"req_\",\"type\":\"tuple\",\"internalType\":\"structSingleXChainSingleVaultStateReq\",\"components\":[{\"name\":\"ambIds\",\"type\":\"uint8[]\",\"internalType\":\"uint8[]\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"superformData\",\"type\":\"tuple\",\"internalType\":\"structSingleVaultSFData\",\"components\":[{\"name\":\"superformId\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"amount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"outputAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"maxSlippage\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"liqRequest\",\"type\":\"tuple\",\"internalType\":\"structLiqRequest\",\"components\":[{\"name\":\"txData\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"interimToken\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"internalType\":\"uint8\"},{\"name\":\"liqDstChainId\",\"type\":\"uint64\",\"internalType\":\"uint64\"},{\"name\":\"nativeAmount\",\"type\":\"uint256\",\"internalType\":\"uint256\"}]},{\"name\":\"permit2data\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"hasDstSwap\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"retain4626\",\"type\":\"bool\",\"internalType\":\"bool\"},{\"name\":\"receiverAddress\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"receiverAddressSP\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"extraFormData\",\"type\":\"bytes\",\"internalType\":\"bytes\"}]}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"superRegistry\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperRegistry\"}],\"stateMutability\":\"view\"},{\"type\":\"event\",\"name\":\"Completed\",\"inputs\":[],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CrossChainInitiatedDepositMulti\",\"inputs\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"amountsIn\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"bridgeIds\",\"type\":\"uint8[]\",\"indexed\":false,\"internalType\":\"uint8[]\"},{\"name\":\"ambIds\",\"type\":\"uint8[]\",\"indexed\":false,\"internalType\":\"uint8[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CrossChainInitiatedDepositSingle\",\"inputs\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"superformIds\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"amountIn\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"bridgeId\",\"type\":\"uint8\",\"indexed\":false,\"internalType\":\"uint8\"},{\"name\":\"ambIds\",\"type\":\"uint8[]\",\"indexed\":false,\"internalType\":\"uint8[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CrossChainInitiatedWithdrawMulti\",\"inputs\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"superformIds\",\"type\":\"uint256[]\",\"indexed\":false,\"internalType\":\"uint256[]\"},{\"name\":\"ambIds\",\"type\":\"uint8[]\",\"indexed\":false,\"internalType\":\"uint8[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"CrossChainInitiatedWithdrawSingle\",\"inputs\":[{\"name\":\"payloadId\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"},{\"name\":\"dstChainId\",\"type\":\"uint64\",\"indexed\":true,\"internalType\":\"uint64\"},{\"name\":\"superformIds\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"ambIds\",\"type\":\"uint8[]\",\"indexed\":false,\"internalType\":\"uint8[]\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RouterDustForwardedToPaymaster\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":true,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"AddressEmptyCode\",\"inputs\":[{\"name\":\"target\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"AddressInsufficientBalance\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"BLOCK_CHAIN_ID_OUT_OF_BOUNDS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ERC1155InvalidReceiver\",\"inputs\":[{\"name\":\"receiver\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"FAILED_TO_EXECUTE_TXDATA\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"FailedInnerCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_BALANCE\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INSUFFICIENT_NATIVE_AMOUNT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_ACTION\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_CHAIN_ID\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_DEPOSIT_TOKEN\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"INVALID_SUPERFORMS_DATA\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NO_TXDATA_PRESENT\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SafeERC20FailedOperation\",\"inputs\":[{\"name\":\"token\",\"type\":\"address\",\"internalType\":\"address\"}]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_AMOUNT\",\"inputs\":[]}]",
}

// SFRouterABI is the input ABI used to generate the binding from.
// Deprecated: Use SFRouterMetaData.ABI instead.
var SFRouterABI = SFRouterMetaData.ABI

// SFRouter is an auto generated Go binding around an Ethereum contract.
type SFRouter struct {
	SFRouterCaller     // Read-only binding to the contract
	SFRouterTransactor // Write-only binding to the contract
	SFRouterFilterer   // Log filterer for contract events
}

// SFRouterCaller is an auto generated read-only Go binding around an Ethereum contract.
type SFRouterCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SFRouterTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SFRouterTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SFRouterFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SFRouterFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SFRouterSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SFRouterSession struct {
	Contract     *SFRouter         // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// SFRouterCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SFRouterCallerSession struct {
	Contract *SFRouterCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts   // Call options to use throughout this session
}

// SFRouterTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SFRouterTransactorSession struct {
	Contract     *SFRouterTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// SFRouterRaw is an auto generated low-level Go binding around an Ethereum contract.
type SFRouterRaw struct {
	Contract *SFRouter // Generic contract binding to access the raw methods on
}

// SFRouterCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SFRouterCallerRaw struct {
	Contract *SFRouterCaller // Generic read-only contract binding to access the raw methods on
}

// SFRouterTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SFRouterTransactorRaw struct {
	Contract *SFRouterTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSFRouter creates a new instance of SFRouter, bound to a specific deployed contract.
func NewSFRouter(address common.Address, backend bind.ContractBackend) (*SFRouter, error) {
	contract, err := bindSFRouter(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SFRouter{SFRouterCaller: SFRouterCaller{contract: contract}, SFRouterTransactor: SFRouterTransactor{contract: contract}, SFRouterFilterer: SFRouterFilterer{contract: contract}}, nil
}

// NewSFRouterCaller creates a new read-only instance of SFRouter, bound to a specific deployed contract.
func NewSFRouterCaller(address common.Address, caller bind.ContractCaller) (*SFRouterCaller, error) {
	contract, err := bindSFRouter(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SFRouterCaller{contract: contract}, nil
}

// NewSFRouterTransactor creates a new write-only instance of SFRouter, bound to a specific deployed contract.
func NewSFRouterTransactor(address common.Address, transactor bind.ContractTransactor) (*SFRouterTransactor, error) {
	contract, err := bindSFRouter(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SFRouterTransactor{contract: contract}, nil
}

// NewSFRouterFilterer creates a new log filterer instance of SFRouter, bound to a specific deployed contract.
func NewSFRouterFilterer(address common.Address, filterer bind.ContractFilterer) (*SFRouterFilterer, error) {
	contract, err := bindSFRouter(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SFRouterFilterer{contract: contract}, nil
}

// bindSFRouter binds a generic wrapper to an already deployed contract.
func bindSFRouter(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SFRouterMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SFRouter *SFRouterRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SFRouter.Contract.SFRouterCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SFRouter *SFRouterRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SFRouter.Contract.SFRouterTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SFRouter *SFRouterRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SFRouter.Contract.SFRouterTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SFRouter *SFRouterCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SFRouter.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SFRouter *SFRouterTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SFRouter.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SFRouter *SFRouterTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SFRouter.Contract.contract.Transact(opts, method, params...)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SFRouter *SFRouterCaller) CHAINID(opts *bind.CallOpts) (uint64, error) {
	var out []interface{}
	err := _SFRouter.contract.Call(opts, &out, "CHAIN_ID")

	if err != nil {
		return *new(uint64), err
	}

	out0 := *abi.ConvertType(out[0], new(uint64)).(*uint64)

	return out0, err

}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SFRouter *SFRouterSession) CHAINID() (uint64, error) {
	return _SFRouter.Contract.CHAINID(&_SFRouter.CallOpts)
}

// CHAINID is a free data retrieval call binding the contract method 0x85e1f4d0.
//
// Solidity: function CHAIN_ID() view returns(uint64)
func (_SFRouter *SFRouterCallerSession) CHAINID() (uint64, error) {
	return _SFRouter.Contract.CHAINID(&_SFRouter.CallOpts)
}

// PayloadIds is a free data retrieval call binding the contract method 0x4325082e.
//
// Solidity: function payloadIds() view returns(uint256)
func (_SFRouter *SFRouterCaller) PayloadIds(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SFRouter.contract.Call(opts, &out, "payloadIds")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PayloadIds is a free data retrieval call binding the contract method 0x4325082e.
//
// Solidity: function payloadIds() view returns(uint256)
func (_SFRouter *SFRouterSession) PayloadIds() (*big.Int, error) {
	return _SFRouter.Contract.PayloadIds(&_SFRouter.CallOpts)
}

// PayloadIds is a free data retrieval call binding the contract method 0x4325082e.
//
// Solidity: function payloadIds() view returns(uint256)
func (_SFRouter *SFRouterCallerSession) PayloadIds() (*big.Int, error) {
	return _SFRouter.Contract.PayloadIds(&_SFRouter.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SFRouter *SFRouterCaller) SuperRegistry(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SFRouter.contract.Call(opts, &out, "superRegistry")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SFRouter *SFRouterSession) SuperRegistry() (common.Address, error) {
	return _SFRouter.Contract.SuperRegistry(&_SFRouter.CallOpts)
}

// SuperRegistry is a free data retrieval call binding the contract method 0x24c73dda.
//
// Solidity: function superRegistry() view returns(address)
func (_SFRouter *SFRouterCallerSession) SuperRegistry() (common.Address, error) {
	return _SFRouter.Contract.SuperRegistry(&_SFRouter.CallOpts)
}

// ForwardDustToPaymaster is a paid mutator transaction binding the contract method 0x4dcd03c0.
//
// Solidity: function forwardDustToPaymaster(address token_) returns()
func (_SFRouter *SFRouterTransactor) ForwardDustToPaymaster(opts *bind.TransactOpts, token_ common.Address) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "forwardDustToPaymaster", token_)
}

// ForwardDustToPaymaster is a paid mutator transaction binding the contract method 0x4dcd03c0.
//
// Solidity: function forwardDustToPaymaster(address token_) returns()
func (_SFRouter *SFRouterSession) ForwardDustToPaymaster(token_ common.Address) (*types.Transaction, error) {
	return _SFRouter.Contract.ForwardDustToPaymaster(&_SFRouter.TransactOpts, token_)
}

// ForwardDustToPaymaster is a paid mutator transaction binding the contract method 0x4dcd03c0.
//
// Solidity: function forwardDustToPaymaster(address token_) returns()
func (_SFRouter *SFRouterTransactorSession) ForwardDustToPaymaster(token_ common.Address) (*types.Transaction, error) {
	return _SFRouter.Contract.ForwardDustToPaymaster(&_SFRouter.TransactOpts, token_)
}

// MultiDstMultiVaultDeposit is a paid mutator transaction binding the contract method 0xf9d4f18c.
//
// Solidity: function multiDstMultiVaultDeposit((uint8[][],uint64[],(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterTransactor) MultiDstMultiVaultDeposit(opts *bind.TransactOpts, req_ MultiDstMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "multiDstMultiVaultDeposit", req_)
}

// MultiDstMultiVaultDeposit is a paid mutator transaction binding the contract method 0xf9d4f18c.
//
// Solidity: function multiDstMultiVaultDeposit((uint8[][],uint64[],(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterSession) MultiDstMultiVaultDeposit(req_ MultiDstMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.MultiDstMultiVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// MultiDstMultiVaultDeposit is a paid mutator transaction binding the contract method 0xf9d4f18c.
//
// Solidity: function multiDstMultiVaultDeposit((uint8[][],uint64[],(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) MultiDstMultiVaultDeposit(req_ MultiDstMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.MultiDstMultiVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// MultiDstMultiVaultWithdraw is a paid mutator transaction binding the contract method 0x165b7a3b.
//
// Solidity: function multiDstMultiVaultWithdraw((uint8[][],uint64[],(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterTransactor) MultiDstMultiVaultWithdraw(opts *bind.TransactOpts, req_ MultiDstMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "multiDstMultiVaultWithdraw", req_)
}

// MultiDstMultiVaultWithdraw is a paid mutator transaction binding the contract method 0x165b7a3b.
//
// Solidity: function multiDstMultiVaultWithdraw((uint8[][],uint64[],(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterSession) MultiDstMultiVaultWithdraw(req_ MultiDstMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.MultiDstMultiVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// MultiDstMultiVaultWithdraw is a paid mutator transaction binding the contract method 0x165b7a3b.
//
// Solidity: function multiDstMultiVaultWithdraw((uint8[][],uint64[],(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) MultiDstMultiVaultWithdraw(req_ MultiDstMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.MultiDstMultiVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// MultiDstSingleVaultDeposit is a paid mutator transaction binding the contract method 0xae1068f2.
//
// Solidity: function multiDstSingleVaultDeposit((uint8[][],uint64[],(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterTransactor) MultiDstSingleVaultDeposit(opts *bind.TransactOpts, req_ MultiDstSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "multiDstSingleVaultDeposit", req_)
}

// MultiDstSingleVaultDeposit is a paid mutator transaction binding the contract method 0xae1068f2.
//
// Solidity: function multiDstSingleVaultDeposit((uint8[][],uint64[],(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterSession) MultiDstSingleVaultDeposit(req_ MultiDstSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.MultiDstSingleVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// MultiDstSingleVaultDeposit is a paid mutator transaction binding the contract method 0xae1068f2.
//
// Solidity: function multiDstSingleVaultDeposit((uint8[][],uint64[],(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) MultiDstSingleVaultDeposit(req_ MultiDstSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.MultiDstSingleVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// MultiDstSingleVaultWithdraw is a paid mutator transaction binding the contract method 0x178f0038.
//
// Solidity: function multiDstSingleVaultWithdraw((uint8[][],uint64[],(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterTransactor) MultiDstSingleVaultWithdraw(opts *bind.TransactOpts, req_ MultiDstSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "multiDstSingleVaultWithdraw", req_)
}

// MultiDstSingleVaultWithdraw is a paid mutator transaction binding the contract method 0x178f0038.
//
// Solidity: function multiDstSingleVaultWithdraw((uint8[][],uint64[],(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterSession) MultiDstSingleVaultWithdraw(req_ MultiDstSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.MultiDstSingleVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// MultiDstSingleVaultWithdraw is a paid mutator transaction binding the contract method 0x178f0038.
//
// Solidity: function multiDstSingleVaultWithdraw((uint8[][],uint64[],(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)[]) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) MultiDstSingleVaultWithdraw(req_ MultiDstSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.MultiDstSingleVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// SingleDirectMultiVaultDeposit is a paid mutator transaction binding the contract method 0xfa0f64eb.
//
// Solidity: function singleDirectMultiVaultDeposit(((uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactor) SingleDirectMultiVaultDeposit(opts *bind.TransactOpts, req_ SingleDirectMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "singleDirectMultiVaultDeposit", req_)
}

// SingleDirectMultiVaultDeposit is a paid mutator transaction binding the contract method 0xfa0f64eb.
//
// Solidity: function singleDirectMultiVaultDeposit(((uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterSession) SingleDirectMultiVaultDeposit(req_ SingleDirectMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleDirectMultiVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// SingleDirectMultiVaultDeposit is a paid mutator transaction binding the contract method 0xfa0f64eb.
//
// Solidity: function singleDirectMultiVaultDeposit(((uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) SingleDirectMultiVaultDeposit(req_ SingleDirectMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleDirectMultiVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// SingleDirectMultiVaultWithdraw is a paid mutator transaction binding the contract method 0x2c1c0ba4.
//
// Solidity: function singleDirectMultiVaultWithdraw(((uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactor) SingleDirectMultiVaultWithdraw(opts *bind.TransactOpts, req_ SingleDirectMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "singleDirectMultiVaultWithdraw", req_)
}

// SingleDirectMultiVaultWithdraw is a paid mutator transaction binding the contract method 0x2c1c0ba4.
//
// Solidity: function singleDirectMultiVaultWithdraw(((uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterSession) SingleDirectMultiVaultWithdraw(req_ SingleDirectMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleDirectMultiVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// SingleDirectMultiVaultWithdraw is a paid mutator transaction binding the contract method 0x2c1c0ba4.
//
// Solidity: function singleDirectMultiVaultWithdraw(((uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) SingleDirectMultiVaultWithdraw(req_ SingleDirectMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleDirectMultiVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// SingleDirectSingleVaultDeposit is a paid mutator transaction binding the contract method 0xb19dcc33.
//
// Solidity: function singleDirectSingleVaultDeposit(((uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactor) SingleDirectSingleVaultDeposit(opts *bind.TransactOpts, req_ SingleDirectSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "singleDirectSingleVaultDeposit", req_)
}

// SingleDirectSingleVaultDeposit is a paid mutator transaction binding the contract method 0xb19dcc33.
//
// Solidity: function singleDirectSingleVaultDeposit(((uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterSession) SingleDirectSingleVaultDeposit(req_ SingleDirectSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleDirectSingleVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// SingleDirectSingleVaultDeposit is a paid mutator transaction binding the contract method 0xb19dcc33.
//
// Solidity: function singleDirectSingleVaultDeposit(((uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) SingleDirectSingleVaultDeposit(req_ SingleDirectSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleDirectSingleVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// SingleDirectSingleVaultWithdraw is a paid mutator transaction binding the contract method 0x407c7b1d.
//
// Solidity: function singleDirectSingleVaultWithdraw(((uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactor) SingleDirectSingleVaultWithdraw(opts *bind.TransactOpts, req_ SingleDirectSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "singleDirectSingleVaultWithdraw", req_)
}

// SingleDirectSingleVaultWithdraw is a paid mutator transaction binding the contract method 0x407c7b1d.
//
// Solidity: function singleDirectSingleVaultWithdraw(((uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterSession) SingleDirectSingleVaultWithdraw(req_ SingleDirectSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleDirectSingleVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// SingleDirectSingleVaultWithdraw is a paid mutator transaction binding the contract method 0x407c7b1d.
//
// Solidity: function singleDirectSingleVaultWithdraw(((uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) SingleDirectSingleVaultWithdraw(req_ SingleDirectSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleDirectSingleVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// SingleXChainMultiVaultDeposit is a paid mutator transaction binding the contract method 0x881d42bb.
//
// Solidity: function singleXChainMultiVaultDeposit((uint8[],uint64,(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactor) SingleXChainMultiVaultDeposit(opts *bind.TransactOpts, req_ SingleXChainMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "singleXChainMultiVaultDeposit", req_)
}

// SingleXChainMultiVaultDeposit is a paid mutator transaction binding the contract method 0x881d42bb.
//
// Solidity: function singleXChainMultiVaultDeposit((uint8[],uint64,(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterSession) SingleXChainMultiVaultDeposit(req_ SingleXChainMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleXChainMultiVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// SingleXChainMultiVaultDeposit is a paid mutator transaction binding the contract method 0x881d42bb.
//
// Solidity: function singleXChainMultiVaultDeposit((uint8[],uint64,(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) SingleXChainMultiVaultDeposit(req_ SingleXChainMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleXChainMultiVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// SingleXChainMultiVaultWithdraw is a paid mutator transaction binding the contract method 0x87493e21.
//
// Solidity: function singleXChainMultiVaultWithdraw((uint8[],uint64,(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactor) SingleXChainMultiVaultWithdraw(opts *bind.TransactOpts, req_ SingleXChainMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "singleXChainMultiVaultWithdraw", req_)
}

// SingleXChainMultiVaultWithdraw is a paid mutator transaction binding the contract method 0x87493e21.
//
// Solidity: function singleXChainMultiVaultWithdraw((uint8[],uint64,(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterSession) SingleXChainMultiVaultWithdraw(req_ SingleXChainMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleXChainMultiVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// SingleXChainMultiVaultWithdraw is a paid mutator transaction binding the contract method 0x87493e21.
//
// Solidity: function singleXChainMultiVaultWithdraw((uint8[],uint64,(uint256[],uint256[],uint256[],uint256[],(bytes,address,address,uint8,uint64,uint256)[],bytes,bool[],bool[],address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) SingleXChainMultiVaultWithdraw(req_ SingleXChainMultiVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleXChainMultiVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// SingleXChainSingleVaultDeposit is a paid mutator transaction binding the contract method 0xe5672e23.
//
// Solidity: function singleXChainSingleVaultDeposit((uint8[],uint64,(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactor) SingleXChainSingleVaultDeposit(opts *bind.TransactOpts, req_ SingleXChainSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "singleXChainSingleVaultDeposit", req_)
}

// SingleXChainSingleVaultDeposit is a paid mutator transaction binding the contract method 0xe5672e23.
//
// Solidity: function singleXChainSingleVaultDeposit((uint8[],uint64,(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterSession) SingleXChainSingleVaultDeposit(req_ SingleXChainSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleXChainSingleVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// SingleXChainSingleVaultDeposit is a paid mutator transaction binding the contract method 0xe5672e23.
//
// Solidity: function singleXChainSingleVaultDeposit((uint8[],uint64,(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) SingleXChainSingleVaultDeposit(req_ SingleXChainSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleXChainSingleVaultDeposit(&_SFRouter.TransactOpts, req_)
}

// SingleXChainSingleVaultWithdraw is a paid mutator transaction binding the contract method 0x67d70a29.
//
// Solidity: function singleXChainSingleVaultWithdraw((uint8[],uint64,(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactor) SingleXChainSingleVaultWithdraw(opts *bind.TransactOpts, req_ SingleXChainSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.contract.Transact(opts, "singleXChainSingleVaultWithdraw", req_)
}

// SingleXChainSingleVaultWithdraw is a paid mutator transaction binding the contract method 0x67d70a29.
//
// Solidity: function singleXChainSingleVaultWithdraw((uint8[],uint64,(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterSession) SingleXChainSingleVaultWithdraw(req_ SingleXChainSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleXChainSingleVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// SingleXChainSingleVaultWithdraw is a paid mutator transaction binding the contract method 0x67d70a29.
//
// Solidity: function singleXChainSingleVaultWithdraw((uint8[],uint64,(uint256,uint256,uint256,uint256,(bytes,address,address,uint8,uint64,uint256),bytes,bool,bool,address,address,bytes)) req_) payable returns()
func (_SFRouter *SFRouterTransactorSession) SingleXChainSingleVaultWithdraw(req_ SingleXChainSingleVaultStateReq) (*types.Transaction, error) {
	return _SFRouter.Contract.SingleXChainSingleVaultWithdraw(&_SFRouter.TransactOpts, req_)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SFRouter *SFRouterTransactor) Receive(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SFRouter.contract.RawTransact(opts, nil) // calldata is disallowed for receive function
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SFRouter *SFRouterSession) Receive() (*types.Transaction, error) {
	return _SFRouter.Contract.Receive(&_SFRouter.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SFRouter *SFRouterTransactorSession) Receive() (*types.Transaction, error) {
	return _SFRouter.Contract.Receive(&_SFRouter.TransactOpts)
}

// SFRouterCompletedIterator is returned from FilterCompleted and is used to iterate over the raw logs and unpacked data for Completed events raised by the SFRouter contract.
type SFRouterCompletedIterator struct {
	Event *SFRouterCompleted // Event containing the contract specifics and raw log

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
func (it *SFRouterCompletedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SFRouterCompleted)
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
		it.Event = new(SFRouterCompleted)
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
func (it *SFRouterCompletedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SFRouterCompletedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SFRouterCompleted represents a Completed event raised by the SFRouter contract.
type SFRouterCompleted struct {
	Raw types.Log // Blockchain specific contextual infos
}

// FilterCompleted is a free log retrieval operation binding the contract event 0xe06452d00b2b58f14a1fa6d499ea982ff93ea827ae700ea9ba03f4daddc94bc1.
//
// Solidity: event Completed()
func (_SFRouter *SFRouterFilterer) FilterCompleted(opts *bind.FilterOpts) (*SFRouterCompletedIterator, error) {

	logs, sub, err := _SFRouter.contract.FilterLogs(opts, "Completed")
	if err != nil {
		return nil, err
	}
	return &SFRouterCompletedIterator{contract: _SFRouter.contract, event: "Completed", logs: logs, sub: sub}, nil
}

// WatchCompleted is a free log subscription operation binding the contract event 0xe06452d00b2b58f14a1fa6d499ea982ff93ea827ae700ea9ba03f4daddc94bc1.
//
// Solidity: event Completed()
func (_SFRouter *SFRouterFilterer) WatchCompleted(opts *bind.WatchOpts, sink chan<- *SFRouterCompleted) (event.Subscription, error) {

	logs, sub, err := _SFRouter.contract.WatchLogs(opts, "Completed")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SFRouterCompleted)
				if err := _SFRouter.contract.UnpackLog(event, "Completed", log); err != nil {
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

// ParseCompleted is a log parse operation binding the contract event 0xe06452d00b2b58f14a1fa6d499ea982ff93ea827ae700ea9ba03f4daddc94bc1.
//
// Solidity: event Completed()
func (_SFRouter *SFRouterFilterer) ParseCompleted(log types.Log) (*SFRouterCompleted, error) {
	event := new(SFRouterCompleted)
	if err := _SFRouter.contract.UnpackLog(event, "Completed", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SFRouterCrossChainInitiatedDepositMultiIterator is returned from FilterCrossChainInitiatedDepositMulti and is used to iterate over the raw logs and unpacked data for CrossChainInitiatedDepositMulti events raised by the SFRouter contract.
type SFRouterCrossChainInitiatedDepositMultiIterator struct {
	Event *SFRouterCrossChainInitiatedDepositMulti // Event containing the contract specifics and raw log

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
func (it *SFRouterCrossChainInitiatedDepositMultiIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SFRouterCrossChainInitiatedDepositMulti)
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
		it.Event = new(SFRouterCrossChainInitiatedDepositMulti)
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
func (it *SFRouterCrossChainInitiatedDepositMultiIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SFRouterCrossChainInitiatedDepositMultiIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SFRouterCrossChainInitiatedDepositMulti represents a CrossChainInitiatedDepositMulti event raised by the SFRouter contract.
type SFRouterCrossChainInitiatedDepositMulti struct {
	PayloadId    *big.Int
	DstChainId   uint64
	SuperformIds []*big.Int
	AmountsIn    []*big.Int
	BridgeIds    []uint8
	AmbIds       []uint8
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterCrossChainInitiatedDepositMulti is a free log retrieval operation binding the contract event 0x3442cbaf79658b5b8750f04e22ec7e6a0d1a64699201b231b23dad10fa9ddcc9.
//
// Solidity: event CrossChainInitiatedDepositMulti(uint256 indexed payloadId, uint64 indexed dstChainId, uint256[] superformIds, uint256[] amountsIn, uint8[] bridgeIds, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) FilterCrossChainInitiatedDepositMulti(opts *bind.FilterOpts, payloadId []*big.Int, dstChainId []uint64) (*SFRouterCrossChainInitiatedDepositMultiIterator, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}

	logs, sub, err := _SFRouter.contract.FilterLogs(opts, "CrossChainInitiatedDepositMulti", payloadIdRule, dstChainIdRule)
	if err != nil {
		return nil, err
	}
	return &SFRouterCrossChainInitiatedDepositMultiIterator{contract: _SFRouter.contract, event: "CrossChainInitiatedDepositMulti", logs: logs, sub: sub}, nil
}

// WatchCrossChainInitiatedDepositMulti is a free log subscription operation binding the contract event 0x3442cbaf79658b5b8750f04e22ec7e6a0d1a64699201b231b23dad10fa9ddcc9.
//
// Solidity: event CrossChainInitiatedDepositMulti(uint256 indexed payloadId, uint64 indexed dstChainId, uint256[] superformIds, uint256[] amountsIn, uint8[] bridgeIds, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) WatchCrossChainInitiatedDepositMulti(opts *bind.WatchOpts, sink chan<- *SFRouterCrossChainInitiatedDepositMulti, payloadId []*big.Int, dstChainId []uint64) (event.Subscription, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}

	logs, sub, err := _SFRouter.contract.WatchLogs(opts, "CrossChainInitiatedDepositMulti", payloadIdRule, dstChainIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SFRouterCrossChainInitiatedDepositMulti)
				if err := _SFRouter.contract.UnpackLog(event, "CrossChainInitiatedDepositMulti", log); err != nil {
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

// ParseCrossChainInitiatedDepositMulti is a log parse operation binding the contract event 0x3442cbaf79658b5b8750f04e22ec7e6a0d1a64699201b231b23dad10fa9ddcc9.
//
// Solidity: event CrossChainInitiatedDepositMulti(uint256 indexed payloadId, uint64 indexed dstChainId, uint256[] superformIds, uint256[] amountsIn, uint8[] bridgeIds, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) ParseCrossChainInitiatedDepositMulti(log types.Log) (*SFRouterCrossChainInitiatedDepositMulti, error) {
	event := new(SFRouterCrossChainInitiatedDepositMulti)
	if err := _SFRouter.contract.UnpackLog(event, "CrossChainInitiatedDepositMulti", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SFRouterCrossChainInitiatedDepositSingleIterator is returned from FilterCrossChainInitiatedDepositSingle and is used to iterate over the raw logs and unpacked data for CrossChainInitiatedDepositSingle events raised by the SFRouter contract.
type SFRouterCrossChainInitiatedDepositSingleIterator struct {
	Event *SFRouterCrossChainInitiatedDepositSingle // Event containing the contract specifics and raw log

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
func (it *SFRouterCrossChainInitiatedDepositSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SFRouterCrossChainInitiatedDepositSingle)
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
		it.Event = new(SFRouterCrossChainInitiatedDepositSingle)
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
func (it *SFRouterCrossChainInitiatedDepositSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SFRouterCrossChainInitiatedDepositSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SFRouterCrossChainInitiatedDepositSingle represents a CrossChainInitiatedDepositSingle event raised by the SFRouter contract.
type SFRouterCrossChainInitiatedDepositSingle struct {
	PayloadId    *big.Int
	DstChainId   uint64
	SuperformIds *big.Int
	AmountIn     *big.Int
	BridgeId     uint8
	AmbIds       []uint8
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterCrossChainInitiatedDepositSingle is a free log retrieval operation binding the contract event 0x718b2e429b305262cd4094e2ee5ecd54cb40d7fa42ca6bb16f2a0acbd49ef8b5.
//
// Solidity: event CrossChainInitiatedDepositSingle(uint256 indexed payloadId, uint64 indexed dstChainId, uint256 superformIds, uint256 amountIn, uint8 bridgeId, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) FilterCrossChainInitiatedDepositSingle(opts *bind.FilterOpts, payloadId []*big.Int, dstChainId []uint64) (*SFRouterCrossChainInitiatedDepositSingleIterator, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}

	logs, sub, err := _SFRouter.contract.FilterLogs(opts, "CrossChainInitiatedDepositSingle", payloadIdRule, dstChainIdRule)
	if err != nil {
		return nil, err
	}
	return &SFRouterCrossChainInitiatedDepositSingleIterator{contract: _SFRouter.contract, event: "CrossChainInitiatedDepositSingle", logs: logs, sub: sub}, nil
}

// WatchCrossChainInitiatedDepositSingle is a free log subscription operation binding the contract event 0x718b2e429b305262cd4094e2ee5ecd54cb40d7fa42ca6bb16f2a0acbd49ef8b5.
//
// Solidity: event CrossChainInitiatedDepositSingle(uint256 indexed payloadId, uint64 indexed dstChainId, uint256 superformIds, uint256 amountIn, uint8 bridgeId, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) WatchCrossChainInitiatedDepositSingle(opts *bind.WatchOpts, sink chan<- *SFRouterCrossChainInitiatedDepositSingle, payloadId []*big.Int, dstChainId []uint64) (event.Subscription, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}

	logs, sub, err := _SFRouter.contract.WatchLogs(opts, "CrossChainInitiatedDepositSingle", payloadIdRule, dstChainIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SFRouterCrossChainInitiatedDepositSingle)
				if err := _SFRouter.contract.UnpackLog(event, "CrossChainInitiatedDepositSingle", log); err != nil {
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

// ParseCrossChainInitiatedDepositSingle is a log parse operation binding the contract event 0x718b2e429b305262cd4094e2ee5ecd54cb40d7fa42ca6bb16f2a0acbd49ef8b5.
//
// Solidity: event CrossChainInitiatedDepositSingle(uint256 indexed payloadId, uint64 indexed dstChainId, uint256 superformIds, uint256 amountIn, uint8 bridgeId, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) ParseCrossChainInitiatedDepositSingle(log types.Log) (*SFRouterCrossChainInitiatedDepositSingle, error) {
	event := new(SFRouterCrossChainInitiatedDepositSingle)
	if err := _SFRouter.contract.UnpackLog(event, "CrossChainInitiatedDepositSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SFRouterCrossChainInitiatedWithdrawMultiIterator is returned from FilterCrossChainInitiatedWithdrawMulti and is used to iterate over the raw logs and unpacked data for CrossChainInitiatedWithdrawMulti events raised by the SFRouter contract.
type SFRouterCrossChainInitiatedWithdrawMultiIterator struct {
	Event *SFRouterCrossChainInitiatedWithdrawMulti // Event containing the contract specifics and raw log

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
func (it *SFRouterCrossChainInitiatedWithdrawMultiIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SFRouterCrossChainInitiatedWithdrawMulti)
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
		it.Event = new(SFRouterCrossChainInitiatedWithdrawMulti)
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
func (it *SFRouterCrossChainInitiatedWithdrawMultiIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SFRouterCrossChainInitiatedWithdrawMultiIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SFRouterCrossChainInitiatedWithdrawMulti represents a CrossChainInitiatedWithdrawMulti event raised by the SFRouter contract.
type SFRouterCrossChainInitiatedWithdrawMulti struct {
	PayloadId    *big.Int
	DstChainId   uint64
	SuperformIds []*big.Int
	AmbIds       []uint8
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterCrossChainInitiatedWithdrawMulti is a free log retrieval operation binding the contract event 0xa23e8d828c95d9dae2c33b414d2a56816a00ecdf695c52f69f0f0932f05c1a48.
//
// Solidity: event CrossChainInitiatedWithdrawMulti(uint256 indexed payloadId, uint64 indexed dstChainId, uint256[] superformIds, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) FilterCrossChainInitiatedWithdrawMulti(opts *bind.FilterOpts, payloadId []*big.Int, dstChainId []uint64) (*SFRouterCrossChainInitiatedWithdrawMultiIterator, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}

	logs, sub, err := _SFRouter.contract.FilterLogs(opts, "CrossChainInitiatedWithdrawMulti", payloadIdRule, dstChainIdRule)
	if err != nil {
		return nil, err
	}
	return &SFRouterCrossChainInitiatedWithdrawMultiIterator{contract: _SFRouter.contract, event: "CrossChainInitiatedWithdrawMulti", logs: logs, sub: sub}, nil
}

// WatchCrossChainInitiatedWithdrawMulti is a free log subscription operation binding the contract event 0xa23e8d828c95d9dae2c33b414d2a56816a00ecdf695c52f69f0f0932f05c1a48.
//
// Solidity: event CrossChainInitiatedWithdrawMulti(uint256 indexed payloadId, uint64 indexed dstChainId, uint256[] superformIds, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) WatchCrossChainInitiatedWithdrawMulti(opts *bind.WatchOpts, sink chan<- *SFRouterCrossChainInitiatedWithdrawMulti, payloadId []*big.Int, dstChainId []uint64) (event.Subscription, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}

	logs, sub, err := _SFRouter.contract.WatchLogs(opts, "CrossChainInitiatedWithdrawMulti", payloadIdRule, dstChainIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SFRouterCrossChainInitiatedWithdrawMulti)
				if err := _SFRouter.contract.UnpackLog(event, "CrossChainInitiatedWithdrawMulti", log); err != nil {
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

// ParseCrossChainInitiatedWithdrawMulti is a log parse operation binding the contract event 0xa23e8d828c95d9dae2c33b414d2a56816a00ecdf695c52f69f0f0932f05c1a48.
//
// Solidity: event CrossChainInitiatedWithdrawMulti(uint256 indexed payloadId, uint64 indexed dstChainId, uint256[] superformIds, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) ParseCrossChainInitiatedWithdrawMulti(log types.Log) (*SFRouterCrossChainInitiatedWithdrawMulti, error) {
	event := new(SFRouterCrossChainInitiatedWithdrawMulti)
	if err := _SFRouter.contract.UnpackLog(event, "CrossChainInitiatedWithdrawMulti", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SFRouterCrossChainInitiatedWithdrawSingleIterator is returned from FilterCrossChainInitiatedWithdrawSingle and is used to iterate over the raw logs and unpacked data for CrossChainInitiatedWithdrawSingle events raised by the SFRouter contract.
type SFRouterCrossChainInitiatedWithdrawSingleIterator struct {
	Event *SFRouterCrossChainInitiatedWithdrawSingle // Event containing the contract specifics and raw log

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
func (it *SFRouterCrossChainInitiatedWithdrawSingleIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SFRouterCrossChainInitiatedWithdrawSingle)
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
		it.Event = new(SFRouterCrossChainInitiatedWithdrawSingle)
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
func (it *SFRouterCrossChainInitiatedWithdrawSingleIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SFRouterCrossChainInitiatedWithdrawSingleIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SFRouterCrossChainInitiatedWithdrawSingle represents a CrossChainInitiatedWithdrawSingle event raised by the SFRouter contract.
type SFRouterCrossChainInitiatedWithdrawSingle struct {
	PayloadId    *big.Int
	DstChainId   uint64
	SuperformIds *big.Int
	AmbIds       []uint8
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterCrossChainInitiatedWithdrawSingle is a free log retrieval operation binding the contract event 0x4dbd819bde4882c7e19b36e6205148983b9e3b863a72a2f8f5576044e4d41b33.
//
// Solidity: event CrossChainInitiatedWithdrawSingle(uint256 indexed payloadId, uint64 indexed dstChainId, uint256 superformIds, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) FilterCrossChainInitiatedWithdrawSingle(opts *bind.FilterOpts, payloadId []*big.Int, dstChainId []uint64) (*SFRouterCrossChainInitiatedWithdrawSingleIterator, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}

	logs, sub, err := _SFRouter.contract.FilterLogs(opts, "CrossChainInitiatedWithdrawSingle", payloadIdRule, dstChainIdRule)
	if err != nil {
		return nil, err
	}
	return &SFRouterCrossChainInitiatedWithdrawSingleIterator{contract: _SFRouter.contract, event: "CrossChainInitiatedWithdrawSingle", logs: logs, sub: sub}, nil
}

// WatchCrossChainInitiatedWithdrawSingle is a free log subscription operation binding the contract event 0x4dbd819bde4882c7e19b36e6205148983b9e3b863a72a2f8f5576044e4d41b33.
//
// Solidity: event CrossChainInitiatedWithdrawSingle(uint256 indexed payloadId, uint64 indexed dstChainId, uint256 superformIds, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) WatchCrossChainInitiatedWithdrawSingle(opts *bind.WatchOpts, sink chan<- *SFRouterCrossChainInitiatedWithdrawSingle, payloadId []*big.Int, dstChainId []uint64) (event.Subscription, error) {

	var payloadIdRule []interface{}
	for _, payloadIdItem := range payloadId {
		payloadIdRule = append(payloadIdRule, payloadIdItem)
	}
	var dstChainIdRule []interface{}
	for _, dstChainIdItem := range dstChainId {
		dstChainIdRule = append(dstChainIdRule, dstChainIdItem)
	}

	logs, sub, err := _SFRouter.contract.WatchLogs(opts, "CrossChainInitiatedWithdrawSingle", payloadIdRule, dstChainIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SFRouterCrossChainInitiatedWithdrawSingle)
				if err := _SFRouter.contract.UnpackLog(event, "CrossChainInitiatedWithdrawSingle", log); err != nil {
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

// ParseCrossChainInitiatedWithdrawSingle is a log parse operation binding the contract event 0x4dbd819bde4882c7e19b36e6205148983b9e3b863a72a2f8f5576044e4d41b33.
//
// Solidity: event CrossChainInitiatedWithdrawSingle(uint256 indexed payloadId, uint64 indexed dstChainId, uint256 superformIds, uint8[] ambIds)
func (_SFRouter *SFRouterFilterer) ParseCrossChainInitiatedWithdrawSingle(log types.Log) (*SFRouterCrossChainInitiatedWithdrawSingle, error) {
	event := new(SFRouterCrossChainInitiatedWithdrawSingle)
	if err := _SFRouter.contract.UnpackLog(event, "CrossChainInitiatedWithdrawSingle", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SFRouterRouterDustForwardedToPaymasterIterator is returned from FilterRouterDustForwardedToPaymaster and is used to iterate over the raw logs and unpacked data for RouterDustForwardedToPaymaster events raised by the SFRouter contract.
type SFRouterRouterDustForwardedToPaymasterIterator struct {
	Event *SFRouterRouterDustForwardedToPaymaster // Event containing the contract specifics and raw log

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
func (it *SFRouterRouterDustForwardedToPaymasterIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SFRouterRouterDustForwardedToPaymaster)
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
		it.Event = new(SFRouterRouterDustForwardedToPaymaster)
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
func (it *SFRouterRouterDustForwardedToPaymasterIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SFRouterRouterDustForwardedToPaymasterIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SFRouterRouterDustForwardedToPaymaster represents a RouterDustForwardedToPaymaster event raised by the SFRouter contract.
type SFRouterRouterDustForwardedToPaymaster struct {
	Token  common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterRouterDustForwardedToPaymaster is a free log retrieval operation binding the contract event 0x3b6a4197c91aad8284f4773a802871b6ef942f15034468da745ac41325904bc5.
//
// Solidity: event RouterDustForwardedToPaymaster(address indexed token, uint256 indexed amount)
func (_SFRouter *SFRouterFilterer) FilterRouterDustForwardedToPaymaster(opts *bind.FilterOpts, token []common.Address, amount []*big.Int) (*SFRouterRouterDustForwardedToPaymasterIterator, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _SFRouter.contract.FilterLogs(opts, "RouterDustForwardedToPaymaster", tokenRule, amountRule)
	if err != nil {
		return nil, err
	}
	return &SFRouterRouterDustForwardedToPaymasterIterator{contract: _SFRouter.contract, event: "RouterDustForwardedToPaymaster", logs: logs, sub: sub}, nil
}

// WatchRouterDustForwardedToPaymaster is a free log subscription operation binding the contract event 0x3b6a4197c91aad8284f4773a802871b6ef942f15034468da745ac41325904bc5.
//
// Solidity: event RouterDustForwardedToPaymaster(address indexed token, uint256 indexed amount)
func (_SFRouter *SFRouterFilterer) WatchRouterDustForwardedToPaymaster(opts *bind.WatchOpts, sink chan<- *SFRouterRouterDustForwardedToPaymaster, token []common.Address, amount []*big.Int) (event.Subscription, error) {

	var tokenRule []interface{}
	for _, tokenItem := range token {
		tokenRule = append(tokenRule, tokenItem)
	}
	var amountRule []interface{}
	for _, amountItem := range amount {
		amountRule = append(amountRule, amountItem)
	}

	logs, sub, err := _SFRouter.contract.WatchLogs(opts, "RouterDustForwardedToPaymaster", tokenRule, amountRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SFRouterRouterDustForwardedToPaymaster)
				if err := _SFRouter.contract.UnpackLog(event, "RouterDustForwardedToPaymaster", log); err != nil {
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

// ParseRouterDustForwardedToPaymaster is a log parse operation binding the contract event 0x3b6a4197c91aad8284f4773a802871b6ef942f15034468da745ac41325904bc5.
//
// Solidity: event RouterDustForwardedToPaymaster(address indexed token, uint256 indexed amount)
func (_SFRouter *SFRouterFilterer) ParseRouterDustForwardedToPaymaster(log types.Log) (*SFRouterRouterDustForwardedToPaymaster, error) {
	event := new(SFRouterRouterDustForwardedToPaymaster)
	if err := _SFRouter.contract.UnpackLog(event, "RouterDustForwardedToPaymaster", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
