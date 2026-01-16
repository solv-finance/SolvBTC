// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./access/AdminControlUpgradeable.sol";
import "./access/CallerControlUpgradeable.sol";
import "./utils/ERC20TransferHelper.sol";
import "./SolvBTC.sol";

contract SolvBTCRedeem is ReentrancyGuardUpgradeable, AdminControlUpgradeable, PausableUpgradeable, CallerControlUpgradeable {
    
    event WithdrawSolvBTC(
        address indexed caller,
        address indexed to,
        address solvBTC,
        address currency,
        uint256 solvBTCAmount,
        uint256 currencyAmount,
        uint256 withdrawFeeAmount
    );
    event SetCurrency(address currency);
    event SetRedemptionVault(address oldRedemptionVault, address newRedemptionVault);
    event SetCallerRestricted(bool isCallerRestricted);
    event SetFeeRecipient(address oldFeeRecipient, address newFeeRecipient);
    event SetWithdrawFeeRate(uint64 oldWithdrawFeeRate, uint64 newWithdrawFeeRate);
    event MaxSingleWithdrawAmountUpdated(uint256 oldMaxSingleWithdrawAmount, uint256 newMaxSingleWithdrawAmount);
    event MaxWindowWithdrawAmountUpdated(
        uint256 oldMaxWindowWithdrawAmount, uint256 newMaxWindowWithdrawAmount, 
        uint256 oldWindow, uint256 newWindow
    );

    struct RateLimit {
        uint256 amountWithdrawn; // amount withdrawn in the current window
        uint256 lastWithdrawnAt; // timestamp of the last withdrawal
        uint256 maxSingleWithdrawAmount; //max amount that can be withdrawn in a single transaction
        uint256 maxWindowWithdrawAmount; //max amount that can be withdrawn in the current window
        uint256 window; // window duration in seconds
    }

    struct SolvBTCRedeemStorage {
        address currency;
        address solvBTC;
        address redemptionVault;
        bool isCallerRestricted;
        address feeRecipient;
        uint64 withdrawFeeRate;
        RateLimit rateLimit;
    }

    uint64 public constant FEE_RATE_BASE = 10000;
    uint256 public constant DEFAULT_WINDOW = 86400; // 1 day

    // keccak256(abi.encode(uint256(keccak256("solv.storage.SolvBTCRedeem")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SolvBTCRedeemStorageLocation =
        0x14f41b446482fb7b17eba69fa0f257dd12a04df2e6f0c99a65c11400b6953100;

    function _getSolvBTCRedeemStorage() private pure returns (SolvBTCRedeemStorage storage $) {
        assembly {
            $.slot := SolvBTCRedeemStorageLocation
        }
    }

    modifier checkCaller() {
        require(
            !_getSolvBTCRedeemStorage().isCallerRestricted || isCallerAllowed(msg.sender), 
            "SolvBTCRedeem: caller not allowed"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin_,
        address redemptionVault_,
        address currency_,
        address solvBTC_,
        address feeRecipient_,
        bool isCallerRestricted_
    ) 
        external 
        virtual 
        initializer 
    {
        if (admin_ == address(0)) {
            admin_ = msg.sender;
        }
        require(redemptionVault_ != address(0), "SolvBTCRedeem: redemption vault cannot be 0 address");
        require(currency_ != address(0), "SolvBTCRedeem: currency cannot be 0 address");
        require(solvBTC_ != address(0), "SolvBTCRedeem: solvBTC cannot be 0 address");
        require(feeRecipient_ != address(0), "SolvBTCRedeem: fee recipient cannot be 0 address");

        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        $.redemptionVault = redemptionVault_;
        $.currency = currency_;
        $.solvBTC = solvBTC_;
        $.feeRecipient = feeRecipient_;
        $.isCallerRestricted = isCallerRestricted_;

        $.rateLimit.window = DEFAULT_WINDOW;
        $.rateLimit.maxWindowWithdrawAmount = 10 * 10 ** SolvBTC(solvBTC_).decimals(); // default 10 solvBTC
        $.rateLimit.maxSingleWithdrawAmount = 10 ** SolvBTC(solvBTC_).decimals() / 10; // default 0.1 solvBTC
        $.rateLimit.amountWithdrawn = 0; // default 0
        $.rateLimit.lastWithdrawnAt = block.timestamp;

        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        AdminControlUpgradeable.__AdminControl_init(admin_);
        PausableUpgradeable.__Pausable_init();
        CallerControlUpgradeable.__CallerControl_init();
    }

    function withdrawSolvBTC(address to_, uint256 amount_) 
        external 
        virtual 
        nonReentrant 
        whenNotPaused 
        checkCaller 
        returns (uint256 currencyAmount_) 
    {
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        RateLimit storage $$ = $.rateLimit;

        require(amount_ > 0, "SolvBTCRedeem: amount cannot be 0");

        //check per withdraw amount
        require(amount_ <= $$.maxSingleWithdrawAmount, "SolvBTCRedeem: amount exceeds single withdraw amount");

        //check daily withdraw amount
        (uint256 currentAmountWithdrawn, uint256 amountCanBeWithdrawn) =
            _amountCanBeWithdrawn($$.amountWithdrawn, $$.lastWithdrawnAt, $$.maxWindowWithdrawAmount, $$.window);
        require(amountCanBeWithdrawn >= amount_, "SolvBTCRedeem: amount exceeds daily withdraw amount");
        $$.amountWithdrawn = currentAmountWithdrawn + amount_;
        $$.lastWithdrawnAt = block.timestamp;

        // transfer solvBTC from user to this contract
        ERC20TransferHelper.doTransferIn(address($.solvBTC), msg.sender, amount_);

        // burn solvBTC
        SolvBTC(address($.solvBTC)).burn(address(this), amount_);

        uint256 totalAmount = amount_ * (10 ** ERC20Upgradeable(address($.currency)).decimals()) / 
            (10 ** ERC20Upgradeable(address($.solvBTC)).decimals());

        // check redemption vault balance
        require(
            ERC20Upgradeable(address($.currency)).balanceOf(address($.redemptionVault)) >= totalAmount,
            "SolvBTCRedeem: redemption vault balance insufficient"
        );

        // check redemption vault allowance
        require(
            ERC20Upgradeable(address($.currency)).allowance(address($.redemptionVault), address(this)) >= totalAmount,
            "SolvBTCRedeem: redemption vault allowance insufficient"
        );

        // transfer currency from redemption vault to this contract
        ERC20TransferHelper.doTransferIn(address($.currency), address($.redemptionVault), totalAmount);

        // calculate withdraw fee
        uint256 withdrawFee = (totalAmount * $.withdrawFeeRate) / FEE_RATE_BASE;
        require(withdrawFee <= totalAmount, "SolvBTCRedeem: withdraw fee exceeds currency amount");
        if (withdrawFee > 0) {
            // transfer currency to fee recipient
            ERC20TransferHelper.doTransferOut(address($.currency), payable(address($.feeRecipient)), withdrawFee);
        }
        currencyAmount_ = totalAmount - withdrawFee;

        // transfer currency to user
        ERC20TransferHelper.doTransferOut(address($.currency), payable(to_), currencyAmount_);

        emit WithdrawSolvBTC(msg.sender, to_, address($.solvBTC), address($.currency), amount_, currencyAmount_, withdrawFee);
    }

    function setCurrency(address currency_) external virtual onlyAdmin {
        require(currency_ != address(0), "SolvBTCRedeem: currency cannot be 0 address");
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        $.currency = currency_;
        emit SetCurrency(currency_);
    }

    function setRedemptionVault(address redemptionVault_) external virtual onlyAdmin {
        require(redemptionVault_ != address(0), "SolvBTCRedeem: redemption vault cannot be 0 address");
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        address oldRedemptionVault = $.redemptionVault;
        $.redemptionVault = redemptionVault_;
        emit SetRedemptionVault(oldRedemptionVault, redemptionVault_);
    }

    function setFeeRecipient(address feeRecipient_) external virtual onlyAdmin {
        require(feeRecipient_ != address(0), "SolvBTCRedeem: fee recipient cannot be 0 address");
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        address oldFeeRecipient = $.feeRecipient;
        $.feeRecipient = feeRecipient_;
        emit SetFeeRecipient(oldFeeRecipient, feeRecipient_);
    }

    function setMaxSingleWithdrawAmount(uint256 maxSingleWithdrawAmount_) external virtual onlyAdmin {
        //allow to set 0, but not exceed maxWindowWithdrawAmount
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        require(
            maxSingleWithdrawAmount_ < $.rateLimit.maxWindowWithdrawAmount,
            "SolvBTCRedeem: max single withdraw amount cannot exceed max window withdraw amount"
        );
        uint256 oldMaxSingleWithdrawAmount = $.rateLimit.maxSingleWithdrawAmount;
        $.rateLimit.maxSingleWithdrawAmount = maxSingleWithdrawAmount_;
        emit MaxSingleWithdrawAmountUpdated(oldMaxSingleWithdrawAmount, maxSingleWithdrawAmount_);
    }

    function setWithdrawFeeRate(uint64 withdrawFeeRate_) external virtual onlyAdmin {
        //allow to set 0, but not exceed 100%
        require(withdrawFeeRate_ < FEE_RATE_BASE, "SolvBTCRedeem: withdraw fee rate cannot exceed 100%");
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        uint64 oldWithdrawFeeRate = $.withdrawFeeRate;
        $.withdrawFeeRate = withdrawFeeRate_;
        emit SetWithdrawFeeRate(oldWithdrawFeeRate, withdrawFeeRate_);
    }

    function setMaxWindowWithdrawAmount(uint256 maxWindowWithdrawAmount_, uint256 window_) external virtual onlyAdmin {
        //allow to set 0
        require(window_ > 0, "SolvBTCRedeem: window cannot be 0");
        //update rate limit
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
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

    function pause() external onlyAdmin whenNotPaused {
        _pause();
    }

    function unpause() external onlyAdmin whenPaused {
        _unpause();
    }

    function setCallerRestricted(bool isCallerRestricted_) external virtual onlyAdmin {
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        $.isCallerRestricted = isCallerRestricted_;
        emit SetCallerRestricted(isCallerRestricted_);
    }

    function setCallerAllowed(address caller_, bool isAllowed_) external virtual onlyAdmin {
        _setCallerAllowed(caller_, isAllowed_);
    }

    function currency() external view virtual returns (address) {
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        return $.currency;
    }

    function solvBTC() external view virtual returns (address) {
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        return $.solvBTC;
    }

    function redemptionVault() external view virtual returns (address) {
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        return $.redemptionVault;
    }

    function isCallerRestricted() external view virtual returns (bool) {
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        return $.isCallerRestricted;
    }

    function feeRecipient() external view virtual returns (address) {
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        return $.feeRecipient;
    }

    function withdrawFeeRate() external view virtual returns (uint64) {
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        return $.withdrawFeeRate;
    }

    function rateLimit() external view virtual returns (RateLimit memory) {
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
        return $.rateLimit;
    }

    function remainingWithdrawAmount() external view virtual returns (uint256) {
        SolvBTCRedeemStorage storage $ = _getSolvBTCRedeemStorage();
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
