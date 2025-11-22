// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./access/AdminControlUpgradeable.sol";
import "./utils/ERC20TransferHelper.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./SolvBTCYieldToken.sol";

contract BTCPlusRedeem is ReentrancyGuardUpgradeable, AdminControlUpgradeable {
    event WithdrawBTCPlus(
        address indexed user,
        address indexed solvBTC,
        address indexed btcPlus,
        uint256 btcPlusAmount,
        uint256 solvBTCAmount,
        uint256 withdrawFee
    );

    event MaxSingleWithdrawAmountUpdated(uint256 oldMaxSingleWithdrawAmount, uint256 newMaxSingleWithdrawAmount);
    event MaxWindowWithdrawAmountUpdated(
        uint256 oldMaxWindowWithdrawAmount, uint256 newMaxWindowWithdrawAmount, uint256 oldWindow, uint256 newWindow
    );

    event WithdrawFeeRateUpdated(uint64 oldWithdrawFeeRate, uint64 newWithdrawFeeRate);
    event SetFeeRecipient(address oldFeeRecipient, address newFeeRecipient);
    event SetRedemptionVault(address oldRedemptionVault, address newRedemptionVault);

    struct RateLimit {
        uint256 amountWithdrawn; // amount withdrawn in the current window
        uint256 lastWithdrawnAt; // timestamp of the last withdrawal
        uint256 maxSingleWithdrawAmount; //max amount that can be withdrawn in a single transaction
        uint256 maxWindowWithdrawAmount; //max amount that can be withdrawn in the current window
        uint256 window; // window duration in seconds
    }

    struct BTCPlusRedeemStorage {
        address solvBTC;
        address btcPlus;
        address redemptionVault;
        address feeRecipient;
        uint64 withdrawFeeRate;
        RateLimit rateLimit;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.BTCPlusRedeem")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BTCPlusRedeemStorageLocation =
        0x068bcc4b070245a4918cdc3b79265b91693407ad59d9128bddabfb5172d59900;

    function _getBTCPlusRedeemStorage() private pure returns (BTCPlusRedeemStorage storage $) {
        assembly {
            $.slot := BTCPlusRedeemStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin_,
        address redemptionVault_,
        address solvBTC_,
        address btcPlus_,
        address feeRecipient_
    ) external virtual initializer {
        if (admin_ == address(0)) {
            admin_ = msg.sender;
        }
        require(redemptionVault_ != address(0), "BTCPlusRedeem: redemption vault cannot be 0 address");
        require(solvBTC_ != address(0), "BTCPlusRedeem: solvBTC cannot be 0 address");
        require(btcPlus_ != address(0), "BTCPlusRedeem: btcPlus cannot be 0 address");
        require(feeRecipient_ != address(0), "BTCPlusRedeem: fee recipient cannot be 0 address");
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        $.redemptionVault = redemptionVault_;
        $.solvBTC = solvBTC_;
        $.btcPlus = btcPlus_;
        $.feeRecipient = feeRecipient_;
        $.rateLimit.window = 86400; // default 1 day
        $.rateLimit.maxWindowWithdrawAmount = 10 * 10 ** SolvBTCYieldToken(solvBTC_).decimals(); // default 10 BTCPlus
        $.rateLimit.maxSingleWithdrawAmount = 10 ** SolvBTCYieldToken(solvBTC_).decimals() / 100; // default 0.01 BTCPlus
        $.rateLimit.amountWithdrawn = 0; // default 0
        $.rateLimit.lastWithdrawnAt = block.timestamp - 86400; // default 1 day ago
        AdminControlUpgradeable.__AdminControl_init(admin_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    function withdrawBTCPlus(uint256 amount_) external virtual nonReentrant returns (uint256 solvBTCAmount_) {
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        RateLimit storage $$ = $.rateLimit;

        require(amount_ > 0, "BTCPlusRedeem: amount cannot be 0");

        //check per withdraw amount
        require(amount_ <= $$.maxSingleWithdrawAmount, "BTCPlusRedeem: amount exceeds single withdraw amount");

        //check daily withdraw amount
        (uint256 currentAmountWithdrawn, uint256 amountCanBeWithdrawn) =
            _amountCanBeWithdrawn($$.amountWithdrawn, $$.lastWithdrawnAt, $$.maxWindowWithdrawAmount, $$.window);
        require(amountCanBeWithdrawn >= amount_, "BTCPlusRedeem: amount exceeds daily withdraw amount");
        $$.amountWithdrawn = currentAmountWithdrawn + amount_;
        $$.lastWithdrawnAt = block.timestamp;

        //calculate SolvBTC amount by nav
        solvBTCAmount_ = SolvBTCYieldToken(address($.solvBTC)).getValueByShares(amount_);

        //check redemption vault allowance
        require(
            SolvBTCYieldToken(address($.solvBTC)).allowance(address($.redemptionVault), address(this))
                >= solvBTCAmount_,
            "BTCPlusRedeem: redemption vault allowance insufficient"
        );

        //check redemption vault balance
        require(
            SolvBTCYieldToken(address($.solvBTC)).balanceOf(address($.redemptionVault)) >= solvBTCAmount_,
            "BTCPlusRedeem: redemption vault balance insufficient"
        );

        //transfer btcPlus from user to this contract
        ERC20TransferHelper.doTransferIn(address($.btcPlus), msg.sender, amount_);

        // burn btcPlus
        SolvBTCYieldToken(address($.btcPlus)).burn(amount_);

        //transfer solvBTC from redemption vault to this contract
        ERC20TransferHelper.doTransferIn(address($.solvBTC), address($.redemptionVault), solvBTCAmount_);

        //calculate withdraw fee
        uint256 withdrawFee = (solvBTCAmount_ * $.withdrawFeeRate) / 10000;
        require(withdrawFee <= solvBTCAmount_, "BTCPlusRedeem: withdraw fee exceeds solvBTC amount");
        if (withdrawFee > 0) {
            //transfer solvBTC from redemption vault to fee recipient
            ERC20TransferHelper.doTransferOut(address($.solvBTC), payable(address($.feeRecipient)), withdrawFee);
        }
        solvBTCAmount_ -= withdrawFee;

        //transfer solvBTC from redemption vault to user
        ERC20TransferHelper.doTransferOut(address($.solvBTC), payable(msg.sender), solvBTCAmount_);

        emit WithdrawBTCPlus(msg.sender, address($.solvBTC), address($.btcPlus), amount_, solvBTCAmount_, withdrawFee);
    }

    function setMaxSingleWithdrawAmount(uint256 maxSingleWithdrawAmount_) external virtual onlyAdmin {
        //allow to set 0
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        uint256 oldMaxSingleWithdrawAmount = $.rateLimit.maxSingleWithdrawAmount;
        $.rateLimit.maxSingleWithdrawAmount = maxSingleWithdrawAmount_;
        emit MaxSingleWithdrawAmountUpdated(oldMaxSingleWithdrawAmount, maxSingleWithdrawAmount_);
    }

    function setMaxWindowWithdrawAmount(uint256 maxWindowWithdrawAmount_, uint256 window_) external virtual onlyAdmin {
        //allow to set 0
        require(window_ > 0, "BTCPlusRedeem: window cannot be 0");
        //update rate limit
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        RateLimit storage $$ = $.rateLimit;
        //Ensure we checkpoint the existing rate limit as to not retroactively apply the new decay rate.
        (uint256 currentAmountWithdrawn,) =
            _amountCanBeWithdrawn($$.amountWithdrawn, $$.lastWithdrawnAt, $$.maxWindowWithdrawAmount, $$.window);

        $$.amountWithdrawn =
            currentAmountWithdrawn > maxWindowWithdrawAmount_ ? maxWindowWithdrawAmount_ : currentAmountWithdrawn;
        $$.lastWithdrawnAt = block.timestamp;

        uint256 oldWindow = $$.window;
        uint256 oldMaxWindowWithdrawAmount = $$.maxWindowWithdrawAmount;
        //Does NOT reset the amountWithdrawn/lastWithdrawnAt of an existing rate limit.
        $$.maxWindowWithdrawAmount = maxWindowWithdrawAmount_;
        $$.window = window_;

        emit MaxWindowWithdrawAmountUpdated(oldMaxWindowWithdrawAmount, maxWindowWithdrawAmount_, oldWindow, window_);
    }

    function setWithdrawFeeRate(uint64 withdrawFeeRate_) external virtual onlyAdmin {
        //allow to set 0
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        uint64 oldWithdrawFeeRate = $.withdrawFeeRate;
        $.withdrawFeeRate = withdrawFeeRate_;
        emit WithdrawFeeRateUpdated(oldWithdrawFeeRate, withdrawFeeRate_);
    }

    function setFeeRecipient(address feeRecipient_) external virtual onlyAdmin {
        require(feeRecipient_ != address(0), "BTCPlusRedeem: fee recipient cannot be 0 address");
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        address oldFeeRecipient = $.feeRecipient;
        $.feeRecipient = feeRecipient_;
        emit SetFeeRecipient(oldFeeRecipient, feeRecipient_);
    }

    function setRedemptionVault(address redemptionVault_) external virtual onlyAdmin {
        require(redemptionVault_ != address(0), "BTCPlusRedeem: redemption vault cannot be 0 address");
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        address oldRedemptionVault = $.redemptionVault;
        $.redemptionVault = redemptionVault_;
        emit SetRedemptionVault(oldRedemptionVault, redemptionVault_);
    }

    function rateLimit() external view virtual returns (RateLimit memory) {
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        return $.rateLimit;
    }

    function withdrawFeeRate() external view virtual returns (uint64) {
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        return $.withdrawFeeRate;
    }

    function feeRecipient() external view virtual returns (address) {
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        return $.feeRecipient;
    }

    function redemptionVault() external view virtual returns (address) {
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        return $.redemptionVault;
    }

    function btcPlus() external view virtual returns (address) {
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        return $.btcPlus;
    }

    function solvBTC() external view virtual returns (address) {
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        return $.solvBTC;
    }

    function remainingWithdrawAmount() external view virtual returns (uint256) {
        BTCPlusRedeemStorage storage $ = _getBTCPlusRedeemStorage();
        RateLimit storage $$ = $.rateLimit;
        (, uint256 amountCanBeWithdrawn) =
            _amountCanBeWithdrawn($$.amountWithdrawn, $$.lastWithdrawnAt, $$.maxWindowWithdrawAmount, $$.window);
        return amountCanBeWithdrawn;
    }

    /**
     * @notice Checks current amount in flight and amount that can be sent for a given rate limit window.
     * @param _amountWithdrawn The amount in the current window.
     * @param _lastWithdrawnAt Timestamp representing the last time the rate limit was checked or updated.
     * @param _limit This represents the maximum allowed amount within a given window.
     * @param _window Defines the duration of the rate limiting window.
     * @return currentAmountWithdrawn The amount in the current window.
     * @return amountCanBeWithdrawn The amount that can be withdrawn.
     */
    function _amountCanBeWithdrawn(uint256 _amountWithdrawn, uint256 _lastWithdrawnAt, uint256 _limit, uint256 _window)
        internal
        view
        virtual
        returns (uint256 currentAmountWithdrawn, uint256 amountCanBeWithdrawn)
    {
        uint256 timeSinceLastWithdrawal = block.timestamp - _lastWithdrawnAt;
        // @dev Presumes linear decay.
        uint256 decay = (_limit * timeSinceLastWithdrawal) / (_window > 0 ? _window : 1); // prevent division by zero
        currentAmountWithdrawn = _amountWithdrawn <= decay ? 0 : _amountWithdrawn - decay;
        // @dev In the event the _limit is lowered, and the 'in-flight' amount is higher than the _limit, set to 0.
        amountCanBeWithdrawn = _limit <= currentAmountWithdrawn ? 0 : _limit - currentAmountWithdrawn;
    }
}
