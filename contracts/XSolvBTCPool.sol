// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./access/AdminControlUpgradeable.sol";
import "./IxSolvBTCPool.sol";
import "./ISolvBTCYieldToken.sol";
import "./ISolvBTCYieldTokenOracle.sol";

contract XSolvBTCPool is IxSolvBTCPool, ReentrancyGuardUpgradeable, AdminControlUpgradeable {
    struct Storage {
        address solvBTC;
        address xSolvBTC;
        address feeRecipient;
        uint256 withdrawFeeRate; // 10000 = 100%
        bool depositAllowed;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.xSolvBTCPool")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant STORAGE_POSITION = 0x4142751e4ad30de9575cf73d5fefb7910c20ffeb3557c886f882c49419246b00;

    function _getStorage() private pure returns (Storage storage $) {
        assembly {
            $.slot := STORAGE_POSITION
        }
    }

    event Deposit(
        address indexed owner,
        address indexed solvBTC,
        address indexed xSolvBTC,
        uint256 solvBTCAmount,
        uint256 xSolvBTCAmount
    );
    event Withdraw(
        address indexed owner,
        address indexed solvBTC,
        address indexed xSolvBTC,
        uint256 solvBTCAmount,
        uint256 xSolvBTCAmount
    );

    event SetWithdrawFeeRate(uint256 oldWithdrawFeeRate, uint256 newWithdrawFeeRate);
    event SetDepositAllowed(bool oldDepositAllowed, bool newDepositAllowed);
    event SetWithdrawAllowed(bool oldWithdrawAllowed, bool newWithdrawAllowed);
    event SetFeeRecipient(address oldFeeRecipient, address newFeeRecipient);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address solvBTC_, address xSolvBTC_, address feeRecipient_, uint256 withdrawFeeRate_)
        external
        virtual
        initializer
    {
        AdminControlUpgradeable.__AdminControl_init(msg.sender);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        Storage storage $ = _getStorage();
        $.solvBTC = solvBTC_;
        $.xSolvBTC = xSolvBTC_;
        $.feeRecipient = feeRecipient_;
        $.withdrawFeeRate = withdrawFeeRate_;
        $.depositAllowed = true;
        $.withdrawAllowed = true;
    }

    function deposit(uint256 solvBtcAmount_) external virtual override nonReentrant returns (uint256 xSolvBtcAmount) {
        require(solvBtcAmount_ > 0, "SolvBTCMultiAssetPool: deposit amount cannot be 0");
        Storage storage $ = _getStorage();
        require($.depositAllowed, "SolvBTCMultiAssetPool: deposit not allowed");
        //burn solvBTC
        ISolvBTC($.solvBTC).burn(msg.sender, solvBtcAmount_);
        //mint xSolvBTC
        xSolvBtcAmount = _calculateDepositAmount(solvBtcAmount_);
        ISolvBTCYieldToken($.xSolvBTC).mint(msg.sender, xSolvBtcAmount);

        emit Deposit(msg.sender, $.solvBTC, $.xSolvBTC, solvBtcAmount_, xSolvBtcAmount);
    }

    function withdraw(uint256 xSolvBtcAmount_) external virtual override nonReentrant returns (uint256 solvBtcAmount) {
        require(xSolvBtcAmount_ > 0, "SolvBTCMultiAssetPool: withdraw amount cannot be 0");
        Storage storage $ = _getStorage();

        solvBtcAmount = _calculateWithdrawAmount(xSolvBtcAmount_);

        //burn xSolvBTC
        ISolvBTCYieldToken($.xSolvBTC).burn(msg.sender, xSolvBtcAmount_);
        //mint solvBTC to fee recipient
        uint256 fee = _calculateWithdrawFee(solvBtcAmount);
        ISolvBTC($.solvBTC).mint($.feeRecipient, fee);
        //mint solvBTC to user
        ISolvBTC($.solvBTC).mint(msg.sender, solvBtcAmount - fee);
        emit Withdraw(msg.sender, $.solvBTC, $.xSolvBTC, solvBtcAmount, xSolvBtcAmount_);
    }

    function setWithdrawFeeRateOnlyAdmin(uint256 withdrawFeeRate_) external virtual onlyAdmin {
        require(withdrawFeeRate_ > 0, "SolvBTCMultiAssetPool: withdraw fee rate cannot be 0");
        Storage storage $ = _getStorage();
        $.withdrawFeeRate = withdrawFeeRate_;

        emit SetWithdrawFeeRate($.withdrawFeeRate, withdrawFeeRate_);
    }

    function setDepositAllowedOnlyAdmin(bool depositAllowed_) external virtual onlyAdmin {
        Storage storage $ = _getStorage();
        $.depositAllowed = depositAllowed_;

        emit SetDepositAllowed($.depositAllowed, depositAllowed_);
    }

    function setFeeRecipientOnlyAdmin(address feeRecipient_) external virtual onlyAdmin {
        require(feeRecipient_ != address(0), "SolvBTCMultiAssetPool: fee recipient cannot be 0 address");
        Storage storage $ = _getStorage();
        $.feeRecipient = feeRecipient_;

        emit SetFeeRecipient($.feeRecipient, feeRecipient_);
    }

    function withdrawFeeRate() external view virtual returns (uint256) {
        Storage storage $ = _getStorage();
        return $.withdrawFeeRate;
    }

    function depositAllowed() external view virtual returns (bool) {
        Storage storage $ = _getStorage();
        return $.depositAllowed;
    }

    function feeRecipient() external view virtual returns (address) {
        Storage storage $ = _getStorage();
        return $.feeRecipient;
    }

    function _calculateWithdrawFee(uint256 amount_) private view returns (uint256) {
        Storage storage $ = _getStorage();
        return (amount_ * $.withdrawFeeRate) / 10000;
    }

    function _getNav() private view returns (uint256) {
        Storage storage $ = _getStorage();
        address oracle = ISolvBTCYieldToken($.xSolvBTC).getOracle();
        return ISolvBTCYieldTokenOracle(oracle).getNav($.xSolvBTC);
    }

    function _calculateDepositAmount(uint256 solvBtcAmount_) private view returns (uint256) {
        Storage storage $ = _getStorage();
        return (solvBtcAmount_ * (10 ** IERC20Metadata($.xSolvBTC).decimals())) / _getNav();
    }

    function _calculateWithdrawAmount(uint256 xSolvBtcAmount_) private view returns (uint256) {
        Storage storage $ = _getStorage();
        return (xSolvBtcAmount_ * _getNav()) / (10 ** IERC20Metadata($.xSolvBTC).decimals());
    }
}
