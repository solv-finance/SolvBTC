// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./access/GovernorControlUpgradeable.sol";
import "./access/PausableControlUpgradeable.sol";
import "./utils/ERC20TransferHelper.sol";
import "./SolvBTC.sol";

/**
 * @title SolvBTCWhitelistedSwap
 * @notice Execution contract for the SolvBTC Whitelisted Swap model.
 * @dev
 * - Provides a single-transaction on-chain path for converting SolvBTC
 *   into its underlying Reserve Asset for authorized callers.
 * - Supports two types of whitelisted addresses:
 *   uncapped addresses and capped addresses that share a global rate limit.
 * - Enforces both per-transaction and window-based limits for capped
 *   addresses using a linear-decay rate-limiting model.
 * - For each swap this contract:
 *   - Receives a SolvBTC amount from the caller and burns the tokens.
 *   - Pulls the corresponding Reserve Asset from `currencyVault` using
 *     a pre-configured allowance granted by governance.
 *   - Delivers the Reserve Asset to the caller or a designated recipient
 *     address supplied as `to_`.
 *   - Calculates a configurable swap fee and routes that fee amount to
 *     a dedicated fee recipient address.
 * - The contract does not custody Reserve Assets long term and does not
 *   perform pricing or market making; the conversion result is defined
 *   by the SolvBTC ↔ Reserve Asset relationship.
 * - Governance manages whitelist membership, vault configuration, fee and
 *   rate-limit parameters, and can pause execution in emergencies.
 */
contract SolvBTCWhitelistedSwap is ReentrancyGuardUpgradeable, GovernorControlUpgradeable, PausableControlUpgradeable {
    
    event SolvBTCSwapped (
        address indexed caller,
        address indexed to,
        address solvBTC,
        address currency,
        uint256 solvBTCAmount,
        uint256 currencyAmount,
        uint256 feeAmount
    );
    event SetSolvBTC(address solvBTC);
    event SetCurrency(address currency);
    event SetCurrencyVault(address oldCurrencyVault, address newCurrencyVault);
    event SetWhitelistEnabled(bool isWhitelistEnabled);
    event SetWhitelistConfig(address indexed account, uint64 expiration, bool isRateLimited);
    event SetFeeRecipient(address oldFeeRecipient, address newFeeRecipient);
    event SetFeeRate(uint64 oldFeeRate, uint64 newFeeRate);
    event SetMaxSingleSwapAmount(
        uint256 oldMaxSingleSwapAmount, uint256 newMaxSingleSwapAmount
    );
    event SetMaxWindowSwapAmount(
        uint256 oldMaxWindowSwapAmount, uint256 newMaxWindowSwapAmount, 
        uint256 oldWindow, uint256 newWindow
    );

    /// @notice Configurations for whitelisted addresses.
    /// - Each whitelist address is only valid up to its `expiration` timestamp.
    /// - Whitelisted addresses are either capped (sharing a common rate limit) or uncapped.
    struct WhitelistConfig {
        uint64 expiration;  // expiration time of the whitelist
        bool isRateLimited;  // whether the swap amount of a whitelisted account is limited
    }

    /// @notice Global rate-limit configuration shared by all capped whitelisted addresses.
    /// Tracks how much SolvBTC has been swapped over a rolling time window and
    /// enforces both per-transaction and aggregate limits.
    /// - `amountSwapped`: total SolvBTC currently accounted for within the active window.
    /// - `lastSwappedAt`: timestamp of the last swap or rate-limit update.
    /// - `maxSingleSwapAmount`: upper bound on SolvBTC that can be swapped in a single transaction.
    /// - `maxWindowSwapAmount`: maximum SolvBTC that all rate-limited addresses can swap during one window.
    /// - `window`: length of the rolling window, in seconds, used for rate-limit calculations.
    struct RateLimit {
        uint256 amountSwapped;
        uint256 lastSwappedAt;
        uint256 maxSingleSwapAmount;
        uint256 maxWindowSwapAmount;
        uint256 window;
    }

    /// @notice Contract storage for SolvBTCWhitelistedSwap.
    /// Holds global configuration, whitelist settings, and shared rate limits.
    /// - `solvBTC`: SolvBTC token being swapped.
    /// - `currency`: underlying reserve asset paid out to users.
    /// - `currencyVault`: vault that holds and funds the underlying currency.
    /// - `feeRecipient`: address that receives swap fees.
    /// - `feeRate`: fee charged per swap, denominated in basis points (1 / 10,000).
    /// - `isWhitelistEnabled`: whether whitelist checks are enforced.
    /// - `whitelistConfigs`: per-account whitelist configuration (expiration and rate-limit type).
    /// - `rateLimit`: global rate limit applied to all capped whitelisted addresses.
    struct SolvBTCWhitelistedSwapStorage {
        address solvBTC;
        address currency;
        address currencyVault;
        address feeRecipient;
        uint64 feeRate;
        bool isWhitelistEnabled;
        mapping(address => WhitelistConfig) whitelistConfigs;
        RateLimit rateLimit;
    }

    /// @notice Denominator used when expressing fees in basis points.
    /// A fee rate of 10000 represents 100%, 100 represents 1%, etc.
    /// Swap fees are calculated as: `fee = amount * feeRate / FEE_RATE_BASE`.
    uint64 public constant FEE_RATE_BASE = 10000;

    /// @notice Default duration, in seconds, of the rate-limit window.
    /// Used to cap the aggregate swap volume for all capped whitelisted addresses.
    /// 86400 seconds corresponds to a 24-hour (1 day) rolling window.
    uint256 public constant DEFAULT_WINDOW = 86400;

    // keccak256(abi.encode(uint256(keccak256("solv.storage.SolvBTCWhitelistedSwap")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SolvBTCWhitelistedSwapStorageLocation =
        0xf127a3e3761fc1d4f9c7f3198495ede49d975bdd97f3723dbfa905f052671400;

    function _getSolvBTCWhitelistedSwapStorage() private pure returns (SolvBTCWhitelistedSwapStorage storage $) {    
        assembly {
            $.slot := SolvBTCWhitelistedSwapStorageLocation
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract.
     * @param governor_ The address of the governor who is used to set business parameters of this contract.
     * @param pauseAdmin_ The address of the pause admin who is used to pause and unpause this contract in emergency.
     * @param solvBTC_ The address of the SolvBTC token.
     * @param currency_ The address of the underlying reserve asset.
     * @param currencyVault_ The vault address for paying the underlying reserve asset.
     * @param feeRecipient_ The address of the fee recipient.
     * @param feeRate_ The fee rate for each swap transaction, charged in terms of the underlying reserve asset.
     * @param isWhitelistEnabled_ Identify whether the caller should be whitelisted.
     */
    function initialize(
        address governor_,
        address pauseAdmin_,
        address solvBTC_,
        address currency_,
        address currencyVault_,
        address feeRecipient_,
        uint64 feeRate_,
        bool isWhitelistEnabled_
    ) 
        external 
        virtual 
        initializer 
    {
        if (governor_ == address(0))  { governor_ = msg.sender; }
        if (pauseAdmin_ == address(0))  { pauseAdmin_ = msg.sender; }
        
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        GovernorControlUpgradeable.__GovernorControl_init(governor_);
        PausableControlUpgradeable.__PausableControl_init(pauseAdmin_);

        _setSolvBTC(solvBTC_);
        _setCurrency(currency_);
        _setCurrencyVault(currencyVault_);
        _setFeeRecipient(feeRecipient_);
        _setFeeRate(feeRate_);
        _setWhitelistEnabled(isWhitelistEnabled_);

        _setMaxWindowSwapAmount(10 * 10 ** SolvBTC(solvBTC_).decimals(), DEFAULT_WINDOW);  // default at 10 SolvBTC/day
        _setMaxSingleSwapAmount(10 ** SolvBTC(solvBTC_).decimals() / 10);  // default at 0.1 solvBTC

        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        $.rateLimit.amountSwapped = 0; // default 0
        $.rateLimit.lastSwappedAt = block.timestamp;
    }

    /**
     * @notice Swap SolvBTC for the underlying reserve currency.
     * @dev
     * - If whitelist is enabled, the caller must have a valid, non-expired whitelist entry.
     *   Rate limiting is then applied only to accounts flagged as rate-limited; 
     *   when whitelist is disabled, the same limits apply to all callers.
     * - When an entry is rate-limited, this function:
     *   - Enforces a per-transaction cap via `maxSingleSwapAmount`.
     *   - Enforces a rolling-window cap via `maxWindowSwapAmount`,
     *     using linear decay computed by {_amountCanBeSwapped}.
     * - Transfers `solvbtcAmount_` of SolvBTC from the caller, burns it, 
     *   and pulls the corresponding amount of reserve currency from `currencyVault`.
     * - Applies the configured fee rate and sends the fee portion to `feeRecipient`, 
     *   while the net amount is sent to `to_`.
     * - Emits {SolvBTCSwapped} on success.
     * @param to_ Recipient address that will receive the reserve currency.
     * @param solvbtcAmount_ Amount of SolvBTC to swap, denominated in SolvBTC decimals.
     * @param currency_ The address of the underlying reserve asset.
     * @param feeRate_ The fee rate for each swap transaction.
     * @return currencyAmount_ Net amount of reserve currency sent to `to_` after fees are deducted.
     */
    function swap(address to_, uint256 solvbtcAmount_, address currency_, uint64 feeRate_) 
        external 
        virtual 
        nonReentrant 
        whenNotPaused 
        returns (uint256 currencyAmount_) 
    {
        require(solvbtcAmount_ > 0, "SolvBTCWhitelistedSwap: amount cannot be 0");
        if (currency_ != address(0)) {
            require(currency_ == currency(), "SolvBTCWhitelistedSwap: unexpected currency");
        }
        if (feeRate_ != 0) {
            require(feeRate_ == feeRate(), "SolvBTCWhitelistedSwap: unexpected fee rate");
        }

        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();

        (uint64 expiration, bool isRateLimited) = whitelistConfig(msg.sender);
        if ($.isWhitelistEnabled) {
            require(expiration > block.timestamp, "SolvBTCWhitelistedSwap: caller unauthorized");
        }

        if (!$.isWhitelistEnabled || isRateLimited) {
            RateLimit memory limit = $.rateLimit;
            require(solvbtcAmount_ <= limit.maxSingleSwapAmount, "SolvBTCWhitelistedSwap: max single swap amount exceeded");
            (uint256 currentAmountSwapped, uint256 amountCanBeSwapped) =
                _amountCanBeSwapped(limit.amountSwapped, limit.lastSwappedAt, limit.maxWindowSwapAmount, limit.window);
            require(solvbtcAmount_ <= amountCanBeSwapped, "SolvBTCWhitelistedSwap: max window swap amount exceeded");
            $.rateLimit.amountSwapped = currentAmountSwapped + solvbtcAmount_;
            $.rateLimit.lastSwappedAt = block.timestamp;
        }

        // receive SolvBTC from msg.sender and burn it
        ERC20TransferHelper.doTransferIn(address($.solvBTC), msg.sender, solvbtcAmount_);
        SolvBTC(address($.solvBTC)).burn(address(this), solvbtcAmount_);

        uint256 totalCurrencyAmount = solvbtcAmount_ * (10 ** ERC20Upgradeable(address($.currency)).decimals()) / 
            (10 ** ERC20Upgradeable(address($.solvBTC)).decimals());
        require(totalCurrencyAmount > 0, "SolvBTCWhitelistedSwap: amount too low");

        // check currency vault balance
        require(
            totalCurrencyAmount <= ERC20Upgradeable(address($.currency)).balanceOf(address($.currencyVault)),
            "SolvBTCWhitelistedSwap: vault balance insufficient"
        );

        // check currency vault allowance
        require(
            totalCurrencyAmount <= ERC20Upgradeable(address($.currency)).allowance(address($.currencyVault), address(this)),
            "SolvBTCWhitelistedSwap: vault allowance insufficient"
        );

        // receive currency from currency vault
        ERC20TransferHelper.doTransferIn(address($.currency), address($.currencyVault), totalCurrencyAmount);

        // calculate swap fee
        uint256 swapFee = (totalCurrencyAmount * $.feeRate) / FEE_RATE_BASE;
        if (swapFee > 0) {
            // transfer fee to fee recipient
            ERC20TransferHelper.doTransferOut(address($.currency), payable(address($.feeRecipient)), swapFee);
        }
        currencyAmount_ = totalCurrencyAmount - swapFee;

        // transfer currency to user
        ERC20TransferHelper.doTransferOut(address($.currency), payable(to_), currencyAmount_);

        emit SolvBTCSwapped(msg.sender, to_, address($.solvBTC), address($.currency), solvbtcAmount_, currencyAmount_, swapFee);
    }

    /**
     * @notice Set the SolvBTC token used by this contract.
     * @dev Internal helper used during initialization; validates that the
     *      address is non-zero and emits {SetSolvBTC}.
     * @param solvBTC_ Address of the SolvBTC ERC20 token.
     */
    function _setSolvBTC(address solvBTC_) internal virtual {
        require(solvBTC_ != address(0), "SolvBTCWhitelistedSwap: solvBTC cannot be 0 address");
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        $.solvBTC = solvBTC_;
        emit SetSolvBTC(solvBTC_);
    }

    /**
     * @notice Update the underlying reserve currency token.
     * @dev Restricted to the governor. Delegates to {_setCurrency}, which
     *      performs validation and emits {SetCurrency}.
     * @param currency_ Address of the ERC20 reserve asset.
     */
    function setCurrency(address currency_) external virtual onlyGovernor {
        _setCurrency(currency_);
    }

    /**
     * @notice Set the underlying reserve currency token.
     * @dev Internal helper that validates the address and emits {SetCurrency}.
     * @param currency_ Address of the ERC20 reserve asset.
     */
    function _setCurrency(address currency_) internal virtual {
        require(currency_ != address(0), "SolvBTCWhitelistedSwap: currency cannot be 0 address");
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        $.currency = currency_;
        emit SetCurrency(currency_);
    }

    /**
     * @notice Update the vault that funds the underlying reserve currency.
     * @dev Restricted to the governor. Delegates to {_setCurrencyVault},
     *      which performs validation and emits {SetCurrencyVault}.
     * @param currencyVault_ Address of the vault holding the reserve asset.
     */
    function setCurrencyVault(address currencyVault_) external virtual onlyGovernor {
        _setCurrencyVault(currencyVault_);
    }

    /**
     * @notice Set the vault that funds the underlying reserve currency.
     * @dev Internal helper that validates the address and emits
     *      {SetCurrencyVault} with both old and new values.
     * @param currencyVault_ Address of the vault holding the reserve asset.
     */
    function _setCurrencyVault(address currencyVault_) internal virtual {
        require(currencyVault_ != address(0), "SolvBTCWhitelistedSwap: currency vault cannot be 0 address");
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        address oldCurrencyVault = $.currencyVault;
        $.currencyVault = currencyVault_;
        emit SetCurrencyVault(oldCurrencyVault, currencyVault_);
    }

    /**
     * @notice Update the address that receives swap fees.
     * @dev Restricted to the governor. Delegates to {_setFeeRecipient}.
     * @param feeRecipient_ Address that will receive collected fees.
     */
    function setFeeRecipient(address feeRecipient_) external virtual onlyGovernor {
        _setFeeRecipient(feeRecipient_);
    }

    /**
     * @notice Set the address that receives swap fees.
     * @dev Internal helper that validates the address and emits
     *      {SetFeeRecipient} with both old and new values.
     * @param feeRecipient_ Address that will receive collected fees.
     */
    function _setFeeRecipient(address feeRecipient_) internal virtual {
        require(feeRecipient_ != address(0), "SolvBTCWhitelistedSwap: fee recipient cannot be 0 address");
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        address oldFeeRecipient = $.feeRecipient;
        $.feeRecipient = feeRecipient_;
        emit SetFeeRecipient(oldFeeRecipient, feeRecipient_);
    }

    /**
     * @notice Update the swap fee rate.
     * @dev Restricted to the governor. Delegates to {_setFeeRate}, which
     *      validates that the fee is below 100% and emits {SetFeeRate}.
     * @param feeRate_ New fee rate expressed in basis points (bps).
     */
    function setFeeRate(uint64 feeRate_) external virtual onlyGovernor {
        _setFeeRate(feeRate_);
    }

    /**
     * @notice Set the swap fee rate.
     * @dev Internal helper that enforces an upper bound of 100% (FEE_RATE_BASE)
     *      and emits {SetFeeRate} with both old and new values.
     * @param feeRate_ New fee rate expressed in basis points (bps).
     */
    function _setFeeRate(uint64 feeRate_) internal virtual {
        require(feeRate_ < FEE_RATE_BASE, "SolvBTCWhitelistedSwap: fee rate cannot exceed 100%");
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        uint64 oldFeeRate = $.feeRate;
        $.feeRate = feeRate_;
        emit SetFeeRate(oldFeeRate, feeRate_);
    }

    /**
     * @notice Enable or disable whitelist checks for swaps.
     * @dev Restricted to the governor. Delegates to {_setWhitelistEnabled}.
     * @param isWhitelistEnabled_ True to enforce whitelist, false to allow all callers.
     */
    function setWhitelistEnabled(bool isWhitelistEnabled_) external virtual onlyGovernor {
        _setWhitelistEnabled(isWhitelistEnabled_);
    }

    /**
     * @notice Set whether whitelist checks are enforced for swaps.
     * @dev Internal helper that updates the flag and emits {SetWhitelistEnabled}.
     * @param isWhitelistEnabled_ True to enforce whitelist, false to allow all callers.
     */
    function _setWhitelistEnabled(bool isWhitelistEnabled_) internal virtual {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        $.isWhitelistEnabled = isWhitelistEnabled_;
        emit SetWhitelistEnabled(isWhitelistEnabled_);
    }

    /**
     * @notice Configure whitelist parameters for a specific account.
     * @dev Restricted to the governor. Delegates to {_setWhitelistConfig}.
     * @param account_ Address to be whitelisted or updated.
     * @param expiration_ Timestamp after which the whitelist entry becomes invalid.
     * @param isRateLimited_ True if the account is subject to the global rate limit.
     */
    function setWhitelistConfig(address account_, uint64 expiration_, bool isRateLimited_) external virtual onlyGovernor {
        _setWhitelistConfig(account_, expiration_, isRateLimited_);
    }

    /**
     * @notice Set whitelist configuration for a specific account.
     * @dev Internal helper that writes the {WhitelistConfig} struct and emits
     *      {SetWhitelistConfig}.
     * @param account_ Address to be whitelisted or updated.
     * @param expiration_ Timestamp after which the whitelist entry becomes invalid.
     * @param isRateLimited_ True if the account is subject to the global rate limit.
     */
    function _setWhitelistConfig(address account_, uint64 expiration_, bool isRateLimited_) internal virtual {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        WhitelistConfig storage $$ = $.whitelistConfigs[account_];
        $$.expiration = expiration_;
        $$.isRateLimited = isRateLimited_;
        emit SetWhitelistConfig(account_, expiration_, isRateLimited_);
    }

    /**
     * @notice Update the maximum aggregate swap amount and window duration.
     * @dev Restricted to the governor. Delegates to {_setMaxWindowSwapAmount},
     *      which checkpoints existing usage and emits {SetMaxWindowSwapAmount}.
     * @param maxWindowSwapAmount_ New maximum SolvBTC amount that can be swapped in one window.
     * @param window_ Length of the rate-limit window in seconds.
     */
    function setMaxWindowSwapAmount(uint256 maxWindowSwapAmount_, uint256 window_) external virtual onlyGovernor {
        _setMaxWindowSwapAmount(maxWindowSwapAmount_, window_);
    }

    /**
     * @notice Set the maximum aggregate swap amount and window duration.
     * @dev Internal helper that:
     *      - Requires a non-zero window.
     *      - Recomputes the current in-flight amount using the old parameters.
     *      - Caps the carried-over amount at the new limit.
     *      - Emits {SetMaxWindowSwapAmount} with old and new values.
     * @param maxWindowSwapAmount_ New maximum SolvBTC that can be swapped in one window.
     * @param window_ Length of the rate-limit window in seconds.
     */
    function _setMaxWindowSwapAmount(uint256 maxWindowSwapAmount_, uint256 window_) internal virtual {
        require(window_ > 0, "SolvBTCWhitelistedSwap: window cannot be 0");
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        RateLimit storage $$ = $.rateLimit;
        // Ensure we checkpoint the existing rate limit as to not retroactively apply the new decay rate.
        (uint256 currentAmountSwapped,) =
            _amountCanBeSwapped($$.amountSwapped, $$.lastSwappedAt, $$.maxWindowSwapAmount, $$.window);

        $$.amountSwapped =
            currentAmountSwapped > maxWindowSwapAmount_ ? maxWindowSwapAmount_ : currentAmountSwapped;
        $$.lastSwappedAt = block.timestamp;

        uint256 oldWindow = $$.window;
        uint256 oldMaxWindowSwapAmount = $$.maxWindowSwapAmount;
        // Does NOT reset the amountSwapped/lastSwappedAt of an existing rate limit.
        $$.maxWindowSwapAmount = maxWindowSwapAmount_;
        $$.window = window_;

        emit SetMaxWindowSwapAmount(oldMaxWindowSwapAmount, maxWindowSwapAmount_, oldWindow, window_);
    }

    /**
     * @notice Update the maximum amount of SolvBTC that can be swapped
     *         in a single transaction.
     * @dev Restricted to the governor. Delegates to {_setMaxSingleSwapAmount}.
     * @param maxSingleSwapAmount_ New per-transaction swap limit (can be zero).
     */
    function setMaxSingleSwapAmount(uint256 maxSingleSwapAmount_) external virtual onlyGovernor {
        _setMaxSingleSwapAmount(maxSingleSwapAmount_);
    }

    // @dev Max single swap amount can be set to 0, but should not exceed the max window swap amount
    function _setMaxSingleSwapAmount(uint256 maxSingleSwapAmount_) internal virtual {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        require(
            maxSingleSwapAmount_ < $.rateLimit.maxWindowSwapAmount,
            "SolvBTCWhitelistedSwap: max single swap amount cannot exceed max window swap amount"
        );
        uint256 oldMaxSingleSwapAmount = $.rateLimit.maxSingleSwapAmount;
        $.rateLimit.maxSingleSwapAmount = maxSingleSwapAmount_;
        emit SetMaxSingleSwapAmount(oldMaxSingleSwapAmount, maxSingleSwapAmount_);
    }

    /**
     * @notice Return the address of the underlying reserve currency token.
     */
    function currency() public view virtual returns (address) {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        return $.currency;
    }

    /**
     * @notice Return the address of the SolvBTC token used for swaps.
     */
    function solvBTC() external view virtual returns (address) {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        return $.solvBTC;
    }

    /**
     * @notice Return the address of the vault that funds the reserve currency.
     */
    function currencyVault() external view virtual returns (address) {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        return $.currencyVault;
    }

    /**
     * @notice Return the address that receives swap fees.
     */
    function feeRecipient() external view virtual returns (address) {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        return $.feeRecipient;
    }

    /**
     * @notice Return the current swap fee rate in basis points (bps).
     */
    function feeRate() public view virtual returns (uint64) {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        return $.feeRate;
    }

    /**
     * @notice Return whether whitelist checks are currently enforced for swaps.
     */
    function isWhitelistEnabled() public view virtual returns (bool) {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        return $.isWhitelistEnabled;
    }

    /**
     * @notice Return whitelist configuration for a given account.
     * @param account_ Address to query.
     * @return expiration_ Expiration timestamp of the whitelist entry.
     * @return isRateLimited_ True if the account is subject to the global rate limit.
     */
    function whitelistConfig(address account_) public view virtual returns (uint64 expiration_, bool isRateLimited_) {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        WhitelistConfig memory $$ = $.whitelistConfigs[account_];
        return ($$.expiration, $$.isRateLimited);
    }

    /**
     * @notice Return the current global rate-limit configuration and state.
     */
    function rateLimit() external view virtual returns (RateLimit memory) {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        return $.rateLimit;
    }

    /**
     * @notice Return the remaining SolvBTC amount that can be swapped within
     *         the current window for all capped whitelisted addresses.
     * @dev Uses {_amountCanBeSwapped} to apply linear decay to the in-flight
     *      amount based on time elapsed since the last swap.
     * @return Remaining SolvBTC capacity in the active rate-limit window.
     */
    function remainingSwapAmount() external view virtual returns (uint256) {
        SolvBTCWhitelistedSwapStorage storage $ = _getSolvBTCWhitelistedSwapStorage();
        RateLimit memory $$ = $.rateLimit;
        (, uint256 amountCanBeSwapped) =
            _amountCanBeSwapped($$.amountSwapped, $$.lastSwappedAt, $$.maxWindowSwapAmount, $$.window);
        return amountCanBeSwapped;
    }

    /**
     * @notice Checks current amount in flight and amount that can be sent for a given rate limit window.
     * @param _amountSwapped The amount in the current window.
     * @param _lastSwappedAt Timestamp representing the last time the rate limit was checked or updated.
     * @param _limit This represents the maximum allowed amount within a given window.
     * @param _window Defines the duration of the rate limiting window.
     * @return currentAmountSwapped The amount in the current window.
     * @return amountCanBeSwapped The amount that can be swapped.
     */
    function _amountCanBeSwapped(uint256 _amountSwapped, uint256 _lastSwappedAt, uint256 _limit, uint256 _window)
        internal
        view
        virtual
        returns (uint256 currentAmountSwapped, uint256 amountCanBeSwapped)
    {
        uint256 timeSinceLastSwapped = block.timestamp - _lastSwappedAt;
        // @dev Presumes linear decay.
        uint256 decay = (_limit * timeSinceLastSwapped) / (_window > 0 ? _window : 1); // prevent division by zero
        currentAmountSwapped = _amountSwapped <= decay ? 0 : _amountSwapped - decay;
        // @dev In the event the _limit is lowered, and the 'in-flight' amount is higher than the _limit, set to 0.
        amountCanBeSwapped = _limit <= currentAmountSwapped ? 0 : _limit - currentAmountSwapped;
    }
}
