// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "./ISolvBTCYieldTokenOracle.sol";
import "./ISolvBTCYieldToken.sol";
import "./utils/ERC20TransferHelper.sol";

contract SolvBTCVault is ReentrancyGuardUpgradeable, Ownable2StepUpgradeable, EIP712Upgradeable {
    event Deposit(address indexed currency, address indexed user, uint256 amount, uint256 shares);
    event WithdrawRequest(
        address indexed user, address indexed withdrawToken, uint256 shares, bytes32 requestHash, uint256 nav
    );
    event Withdraw(address indexed user, address indexed withdrawToken, uint256 amount, uint256 timestamp);

    enum WithdrawStatus {
        NOT_EXIST,
        PENDING,
        DONE
    }

    struct WithdrawInfo {
        uint256 chainId;
        string action;
        address user;
        address withdrawToken;
        uint256 shares;
        uint256 nav;
        bytes32 requestHash;
    }

    struct SolvBTCVaultStorage {
        address sharesToken;
        address withdrawToken;
        address treasury;
        mapping(address => bool) allowedCurrencies;
        address oracle;
        address withdrawSigner;
        address feeReceiver;
        uint32 withdrawFeeRatio;
        mapping(bytes32 => WithdrawStatus) withdrawRequestStatus;
    }

    /// keccak256(abi.encode(uint256(keccak256("solv.storage.SolvBTCVault")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SolvBTCVaultStorageLocation =
        0x6004566d0072672131319f1802405d73689c7c95aeedc9ce6d5f4b0099b18500;

    // EIP712
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256(
        "Withdraw(uint256 chainId,string action,address user,address withdrawToken,uint256 shares,uint256 nav,bytes32 requestHash)"
    );
    string private constant WITHDRAW_DOMAIN_SEPARATOR_NAME = "Solv Vault Withdraw";
    string private constant WITHDRAW_DOMAIN_SEPARATOR_VERSION = "1";

    bytes4 internal constant SIGNATURE_VERIFICATION_MAGIC_VALUE = 0x1626ba7e;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address withdrawToken_,
        address sharesToken_,
        address[] calldata allowedCurrencies_,
        address oracle_,
        address feeReceiver_,
        uint32 withdrawFeeRatio_
    ) external virtual initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        Ownable2StepUpgradeable.__Ownable2Step_init();
        EIP712Upgradeable.__EIP712_init(WITHDRAW_DOMAIN_SEPARATOR_NAME, WITHDRAW_DOMAIN_SEPARATOR_VERSION);

        _setWithdrawToken(withdrawToken_);
        _setSharesToken(sharesToken_);
        _setOracle(oracle_);
        _setFeeReceiver(feeReceiver_);
        _setWithdrawFeeRatio(withdrawFeeRatio_);
        for (uint256 i = 0; i < allowedCurrencies_.length; i++) {
            _setAllowedCurrency(allowedCurrencies_[i], true);
        }
    }

    function deposit(address currency_, uint256 amount_) external nonReentrant returns (uint256 shares_) {
        SolvBTCVaultStorage storage s = _getStorage();
        require(s.allowedCurrencies[currency_], "SolvBTCVault: currency not allowed");
        require(s.oracle != address(0), "SolvBTCVault: oracle not set");
        require(s.feeReceiver != address(0), "SolvBTCVault: fee receiver not set");
        require(s.withdrawFeeRatio > 0, "SolvBTCVault: withdraw fee ratio not set");

        uint256 sharesTokenDecimals = IERC20Metadata(s.sharesToken).decimals();
        uint256 currencyDecimals = IERC20Metadata(currency_).decimals();
        uint256 navDecimals = ISolvBTCYieldTokenOracle(s.oracle).navDecimals(s.withdrawToken);

        uint256 nav = _getNav();
        shares_ = amount_ * (10 ** sharesTokenDecimals) * (10 ** navDecimals) / (nav * (10 ** currencyDecimals));

        ERC20TransferHelper.doTransferIn(currency_, _msgSender(), amount_);
        if (s.treasury != address(0)) {
            ERC20TransferHelper.doTransferOut(currency_, payable(s.treasury), amount_);
        }

        ISolvBTCYieldToken(s.sharesToken).mint(_msgSender(), shares_);

        emit Deposit(currency_, _msgSender(), amount_, shares_);
    }

    function withdrawRequest(uint256 shares_, bytes32 requestHash_) external nonReentrant {
        SolvBTCVaultStorage storage s = _getStorage();
        require(s.oracle != address(0), "SolvBTCVault: oracle not set");
        require(s.feeReceiver != address(0), "SolvBTCVault: fee receiver not set");
        require(s.withdrawFeeRatio > 0, "SolvBTCVault: withdraw fee ratio not set");
        uint256 nav = _getNav();
        bytes32 key = keccak256(abi.encodePacked(_msgSender(), s.withdrawToken, requestHash_, shares_, nav));
        require(s.withdrawRequestStatus[key] == WithdrawStatus.NOT_EXIST, "SolvBTCVault: request already exist");
        require(s.withdrawToken != address(0), "SolvBTCVault: withdraw token not set");
        require(s.sharesToken != address(0), "SolvBTCVault: shares token not set");
        require(IERC20Metadata(s.sharesToken).balanceOf(_msgSender()) >= shares_, "SolvBTCVault: shares not enough");

        ISolvBTCYieldToken(s.sharesToken).burn(_msgSender(), shares_);
        s.withdrawRequestStatus[key] = WithdrawStatus.PENDING;

        emit WithdrawRequest(_msgSender(), s.withdrawToken, shares_, requestHash_, nav);
    }

    function withdraw(bytes memory withdrawInfo_, bytes memory signature_)
        external
        nonReentrant
        returns (uint256 amount_)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        WithdrawInfo memory info = abi.decode(withdrawInfo_, (WithdrawInfo));
        SolvBTCVaultStorage storage s = _getStorage();
        bytes32 key =
            keccak256(abi.encodePacked(info.user, info.withdrawToken, info.requestHash, info.shares, info.nav));
        require(s.withdrawRequestStatus[key] == WithdrawStatus.PENDING, "SolvBTCVault: request not exist");
        require(s.withdrawToken == info.withdrawToken, "SolvBTCVault: withdraw token not match");
        require(s.oracle != address(0), "SolvBTCVault: oracle not set");
        require(s.feeReceiver != address(0), "SolvBTCVault: fee receiver not set");
        require(s.withdrawFeeRatio > 0, "SolvBTCVault: withdraw fee ratio not set");
        require(info.nav <= _getNav(), "SolvBTCVault: nav not greater than current nav");
        require(s.withdrawSigner != address(0), "SolvBTCVault: withdraw signer not set");
        require(info.chainId == chainId, "SolvBTCVault: chain id not match");
        require(info.user == _msgSender(), "SolvBTCVault: user not match");
        require(keccak256(abi.encodePacked(info.action)) == keccak256("withdraw"), "SolvBTCVault: action not match");
        bytes32 hash = _getWithdrawHash(info);
        if (s.withdrawSigner.code.length == 0) {
            address recoveredSigner = ECDSA.recover(hash, signature_);
            require(recoveredSigner == s.withdrawSigner, "Signature verification failed");
        } else {
            // verify signature by calling isValidSignature when signer is a Safe multisig wallet
            (bool success, bytes memory result) =
                s.withdrawSigner.call(abi.encodeWithSignature("isValidSignature(bytes32,bytes)", hash, signature_));
            require(
                success && abi.decode(result, (bytes4)) == SIGNATURE_VERIFICATION_MAGIC_VALUE,
                "Signature verification failed"
            );
        }

        uint256 sharesTokenDecimals = IERC20Metadata(s.sharesToken).decimals();
        uint256 withdrawTokenDecimals = IERC20Metadata(s.withdrawToken).decimals();
        uint256 navDecimals = ISolvBTCYieldTokenOracle(s.oracle).navDecimals(s.withdrawToken);
        uint256 amount =
            info.shares * info.nav * (10 ** withdrawTokenDecimals) / ((10 ** navDecimals) * (10 ** sharesTokenDecimals));

        uint256 fee = amount * s.withdrawFeeRatio / 10000;
        amount_ = amount - fee;

        s.withdrawRequestStatus[key] = WithdrawStatus.DONE;

        ERC20TransferHelper.doTransferOut(info.withdrawToken, payable(s.feeReceiver), fee);
        ERC20TransferHelper.doTransferOut(info.withdrawToken, payable(_msgSender()), amount_);

        emit Withdraw(_msgSender(), info.withdrawToken, amount_, block.timestamp);
    }

    function setOracleByAdmin(address oracle_) external onlyOwner {
        _setOracle(oracle_);
    }

    function setFeeReceiverByAdmin(address feeReceiver_) external onlyOwner {
        _setFeeReceiver(feeReceiver_);
    }

    function setWithdrawFeeRatioByAdmin(uint32 withdrawFeeRatio_) external onlyOwner {
        _setWithdrawFeeRatio(withdrawFeeRatio_);
    }

    function setAllowedCurrencyByAdmin(address currency_, bool allowed_) external onlyOwner {
        _setAllowedCurrency(currency_, allowed_);
    }

    function setWithdrawSignerByAdmin(address withdrawSigner_) external onlyOwner {
        _setWithdrawSigner(withdrawSigner_);
    }

    function getOracle() external view returns (address) {
        SolvBTCVaultStorage storage s = _getStorage();
        return s.oracle;
    }

    function getWithdrawSigner() external view returns (address) {
        SolvBTCVaultStorage storage s = _getStorage();
        return s.withdrawSigner;
    }

    function getWithdrawFeeRatio() external view returns (uint32) {
        SolvBTCVaultStorage storage s = _getStorage();
        return s.withdrawFeeRatio;
    }

    function getWithdrawToken() external view returns (address) {
        SolvBTCVaultStorage storage s = _getStorage();
        return s.withdrawToken;
    }

    function getFeeReceiver() external view returns (address) {
        SolvBTCVaultStorage storage s = _getStorage();
        return s.feeReceiver;
    }

    function getSharesToken() external view returns (address) {
        SolvBTCVaultStorage storage s = _getStorage();
        return s.sharesToken;
    }

    function isAllowedCurrency(address currency_) external view returns (bool) {
        SolvBTCVaultStorage storage s = _getStorage();
        return s.allowedCurrencies[currency_];
    }

    function _getWithdrawHash(WithdrawInfo memory info_) internal view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    WITHDRAW_TYPEHASH,
                    info_.chainId,
                    keccak256(abi.encodePacked(info_.action)),
                    info_.withdrawToken,
                    info_.shares,
                    info_.nav,
                    info_.requestHash
                )
            )
        );
    }

    function _getNav() internal view returns (uint256 nav_) {
        SolvBTCVaultStorage storage s = _getStorage();
        ISolvBTCYieldTokenOracle oracle = ISolvBTCYieldTokenOracle(s.oracle);
        nav_ = oracle.getNav(s.withdrawToken);
    }

    function _setWithdrawSigner(address withdrawSigner_) internal {
        SolvBTCVaultStorage storage s = _getStorage();
        s.withdrawSigner = withdrawSigner_;
    }

    function _setWithdrawToken(address withdrawToken_) internal {
        SolvBTCVaultStorage storage s = _getStorage();
        s.withdrawToken = withdrawToken_;
    }

    function _setSharesToken(address sharesToken_) internal {
        SolvBTCVaultStorage storage s = _getStorage();
        s.sharesToken = sharesToken_;
    }

    function _setOracle(address oracle_) internal {
        SolvBTCVaultStorage storage s = _getStorage();
        s.oracle = oracle_;
    }

    function _setFeeReceiver(address feeReceiver_) internal {
        SolvBTCVaultStorage storage s = _getStorage();
        s.feeReceiver = feeReceiver_;
    }

    function _setWithdrawFeeRatio(uint32 withdrawFeeRatio_) internal {
        SolvBTCVaultStorage storage s = _getStorage();
        s.withdrawFeeRatio = withdrawFeeRatio_;
    }

    function _setAllowedCurrency(address currency_, bool allowed_) internal {
        SolvBTCVaultStorage storage s = _getStorage();
        s.allowedCurrencies[currency_] = allowed_;
    }

    function _getStorage() internal pure returns (SolvBTCVaultStorage storage s) {
        assembly {
            s.slot := SolvBTCVaultStorageLocation
        }
    }
}
