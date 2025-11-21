// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

pragma solidity 0.8.20;

contract FeeManager is Ownable2StepUpgradeable {

    // DepositFee
    event SetDepositFee(
        address indexed targetToken,
        address indexed currency,
        uint64 feeRate,
        address feeReceiver
    );

    struct DepositFee {
        uint64 feeRate;   // decimal = 8, 1e8 = 100%
        address feeReceiver;
    }

    struct DepositFeeParam {
        address targetToken;
        address currency;
        uint64 feeRate;
        address feeReceiver;
    }

    struct FeeManagerStorage {
        // targetToken => currency => DepositFee
        mapping(address => mapping(address => DepositFee)) _depositFees;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.FeeManager")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant FeeManagerStorageLocation =
        0xd54c6203b7ea9f2a1f1717acf254621134b6951cfc66daad7b3aa9cad9627c00;

    function _getFeeManagerStorage() private pure returns (FeeManagerStorage storage $) {
        assembly {
            $.slot := FeeManagerStorageLocation
        }
    }

    function initialize() external initializer {
        __Ownable_init(msg.sender);
    }

    function setDepositFees(DepositFeeParam[] calldata params) external onlyOwner {
        for (uint256 i = 0; i < params.length; i++) {
            address targetToken = params[i].targetToken;
            address currency = params[i].currency;
            uint64 feeRate = params[i].feeRate;
            address feeReceiver = params[i].feeReceiver;

            require(targetToken != address(0), "FeeManager: targetToken is zero address");
            require(currency != address(0), "FeeManager: currency is zero address");
            require(feeRate <= 1e8, "FeeManager: feeRate exceeds 100%");
            require(feeRate == 0 || feeReceiver != address(0), "FeeManager: feeReceiver is zero address");

            FeeManagerStorage storage $ = _getFeeManagerStorage();
            $._depositFees[targetToken][currency] = DepositFee(feeRate, feeReceiver);
            emit SetDepositFee(targetToken, currency, feeRate, feeReceiver);
        }
    }

    function getDepositFee(address targetToken_, address currency_, uint256 amount_) 
        external 
        view 
        virtual
        returns (uint256 feeAmount_, address feeReceiver_) 
    {
        DepositFee memory depositFee = _getFeeManagerStorage()._depositFees[targetToken_][currency_];
        feeAmount_ = (amount_ * depositFee.feeRate) / 1e8;
        feeReceiver_ = depositFee.feeReceiver;
    }

}