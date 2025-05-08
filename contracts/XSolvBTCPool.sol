// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./access/AdminControlUpgradeable.sol";
import "./IxSolvBTCPool.sol";
import "./ISolvBTCYieldToken.sol";
import "./ISolvBTCYieldTokenOracle.sol";

contract XSolvBTCPool is IxSolvBTCPool, ReentrancyGuardUpgradeable, AdminControlUpgradeable {
    struct XSolvBTCPoolStorage {
        address solvBTC;
        address xSolvBTC;
        address feeRecipient;
        uint64 withdrawFeeRate; // 10000 = 100%
        bool depositAllowed;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.xSolvBTCPool")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant XSolvBTCPoolStorageLocation = 0x4142751e4ad30de9575cf73d5fefb7910c20ffeb3557c886f882c49419246b00;

    function _getXSolvBTCPoolStorage() private pure returns (XSolvBTCPoolStorage storage $) {
        assembly {
            $.slot := XSolvBTCPoolStorageLocation
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

    event SetFeeRecipient(address oldFeeRecipient, address newFeeRecipient);
    event SetWithdrawFeeRate(uint64 oldWithdrawFeeRate, uint64 newWithdrawFeeRate);
    event SetDepositAllowed(bool oldDepositAllowed, bool newDepositAllowed);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address solvBTC_, address xSolvBTC_, address feeRecipient_, uint64 withdrawFeeRate_)
        external
        virtual
        initializer
    {
        AdminControlUpgradeable.__AdminControl_init(msg.sender);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        XSolvBTCPoolStorage storage $ = _getXSolvBTCPoolStorage();
        $.solvBTC = solvBTC_;
        $.xSolvBTC = xSolvBTC_;
        
        _setFeeRecipient(feeRecipient_);
        _setWithdrawFeeRate(withdrawFeeRate_);
        _setDepositAllowed(true);
    }

    function deposit(uint256 solvBtcAmount_) external virtual override nonReentrant returns (uint256 xSolvBtcAmount) {
        require(solvBtcAmount_ > 0, "SolvBTCMultiAssetPool: deposit amount cannot be 0");
        XSolvBTCPoolStorage storage $ = _getXSolvBTCPoolStorage();
        require($.depositAllowed, "SolvBTCMultiAssetPool: deposit not allowed");
        //burn solvBTC
        ISolvBTC($.solvBTC).burn(msg.sender, solvBtcAmount_);
        //mint xSolvBTC
        xSolvBtcAmount = ISolvBTCYieldToken($.xSolvBTC).getSharesByValue(solvBtcAmount_);
        ISolvBTCYieldToken($.xSolvBTC).mint(msg.sender, xSolvBtcAmount);

        emit Deposit(msg.sender, $.solvBTC, $.xSolvBTC, solvBtcAmount_, xSolvBtcAmount);
    }

    function withdraw(uint256 xSolvBtcAmount_) external virtual override nonReentrant returns (uint256 solvBtcAmount) {
        require(xSolvBtcAmount_ > 0, "SolvBTCMultiAssetPool: withdraw amount cannot be 0");
        
        XSolvBTCPoolStorage storage $ = _getXSolvBTCPoolStorage();
        solvBtcAmount = ISolvBTCYieldToken($.xSolvBTC).getValueByShares(xSolvBtcAmount_);

        //burn xSolvBTC
        ISolvBTCYieldToken($.xSolvBTC).burn(msg.sender, xSolvBtcAmount_);
        //mint solvBTC to fee recipient
        uint256 fee = _calculateWithdrawFee(solvBtcAmount);
        if (fee > 0) {
            ISolvBTC($.solvBTC).mint($.feeRecipient, fee);
        }
        //mint solvBTC to user
        ISolvBTC($.solvBTC).mint(msg.sender, solvBtcAmount - fee);
        emit Withdraw(msg.sender, $.solvBTC, $.xSolvBTC, solvBtcAmount, xSolvBtcAmount_);
    }

    function setFeeRecipientOnlyAdmin(address feeRecipient_) external virtual onlyAdmin {
        _setFeeRecipient(feeRecipient_);
    }

    function _setFeeRecipient(address feeRecipient_) internal virtual {
        require(feeRecipient_ != address(0), "SolvBTCMultiAssetPool: fee recipient cannot be 0 address");
        XSolvBTCPoolStorage storage $ = _getXSolvBTCPoolStorage();
        address oldFeeRecipient = $.feeRecipient;
        $.feeRecipient = feeRecipient_;
        emit SetFeeRecipient(oldFeeRecipient, feeRecipient_);
    }

    function setWithdrawFeeRateOnlyAdmin(uint64 withdrawFeeRate_) external virtual onlyAdmin {
        _setWithdrawFeeRate(withdrawFeeRate_);
    }

    function _setWithdrawFeeRate(uint64 withdrawFeeRate_) internal virtual {
        require(withdrawFeeRate_ < 10000, "SolvBTCMultiAssetPool: invalid withdraw fee rate");
        XSolvBTCPoolStorage storage $ = _getXSolvBTCPoolStorage();
        uint64 oldWithdrawFeeRate = $.withdrawFeeRate;
        $.withdrawFeeRate = withdrawFeeRate_;
        emit SetWithdrawFeeRate(oldWithdrawFeeRate, withdrawFeeRate_);
    }

    function setDepositAllowedOnlyAdmin(bool depositAllowed_) external virtual onlyAdmin {
        _setDepositAllowed(depositAllowed_);
    }

    function _setDepositAllowed(bool depositAllowed_) internal virtual {
        XSolvBTCPoolStorage storage $ = _getXSolvBTCPoolStorage();
        bool oldDepositAllowed = $.depositAllowed;
        $.depositAllowed = depositAllowed_;
        emit SetDepositAllowed(oldDepositAllowed, depositAllowed_);
    }

    function feeRecipient() external view virtual returns (address) {
        XSolvBTCPoolStorage storage $ = _getXSolvBTCPoolStorage();
        return $.feeRecipient;
    }

    function withdrawFeeRate() external view virtual returns (uint64) {
        XSolvBTCPoolStorage storage $ = _getXSolvBTCPoolStorage();
        return $.withdrawFeeRate;
    }

    function depositAllowed() external view virtual returns (bool) {
        XSolvBTCPoolStorage storage $ = _getXSolvBTCPoolStorage();
        return $.depositAllowed;
    }

    function _calculateWithdrawFee(uint256 amount_) private view returns (uint256) {
        XSolvBTCPoolStorage storage $ = _getXSolvBTCPoolStorage();
        return (amount_ * $.withdrawFeeRate) / 10000;
    }
}
