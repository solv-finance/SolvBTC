// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

pragma solidity 0.8.20;

contract SubscriptionFeeOracle is Ownable2StepUpgradeable {

    event SetSubscriptionFee(
        address indexed targetToken,
        address indexed currency,
        uint64 feeRate,
        address feeReceiver
    );

    struct SubscriptionFee {
        uint64 feeRate;   // decimal = 8, 1e8 = 100%
        address feeReceiver;
    }

    struct SubscriptionFeeOracleStorage {
        // targetToken => currency => SubscriptionFee
        mapping(address => mapping(address => SubscriptionFee)) _subscriptionFees;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.SubscriptionFeeOracle")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SubscriptionFeeOracleStorageLocation =
        0xf545260b701b0289310a18479f284ee4956210e085d12ce24f7c62168c1a6a00;

    function _getSubscriptionFeeOracleStorage() private pure returns (SubscriptionFeeOracleStorage storage $) {
        assembly {
            $.slot := SubscriptionFeeOracleStorageLocation
        }
    }

    function initialize() external initializer {
        __Ownable_init(msg.sender);
    }

    function setSubscriptionFee(
        address targetToken_,
        address currency_,
        uint64 feeRate_,
        address feeReceiver_
    ) external onlyOwner {
        require(targetToken_ != address(0), "SubscriptionFeeOracle: targetToken is zero address");
        require(currency_ != address(0), "SubscriptionFeeOracle: currency is zero address");
        require(feeRate_ <= 1e8, "SubscriptionFeeOracle: feeRate exceeds 100%");
        require(feeRate_ == 0 || feeReceiver_ != address(0), "SubscriptionFeeOracle: feeReceiver is zero address");

        SubscriptionFeeOracleStorage storage $ = _getSubscriptionFeeOracleStorage();
        $._subscriptionFees[targetToken_][currency_] = SubscriptionFee(feeRate_, feeReceiver_);
        emit SetSubscriptionFee(targetToken_, currency_, feeRate_, feeReceiver_);
    }

    function getSubscriptionFee(address targetToken_, address currency_) external view returns (uint64, address) {
        SubscriptionFee memory subscriptionFee = 
            _getSubscriptionFeeOracleStorage()._subscriptionFees[targetToken_][currency_];
        return (subscriptionFee.feeRate, subscriptionFee.feeReceiver);
    }

}