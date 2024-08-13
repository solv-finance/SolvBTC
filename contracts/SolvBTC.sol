// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./ISolvBTC.sol";
import "./SolvBTCMultiAssetPool.sol";

contract SolvBTC is ISolvBTC, ERC20Upgradeable, ReentrancyGuardUpgradeable, Ownable2StepUpgradeable, AccessControlUpgradeable {

    /// @custom:storage-location erc7201:solv.storage.SolvBTC
    struct SolvBTCStorage {
        address _solvBTCMultiAssetPool;
    }

    address public wrappedSftAddress;
    uint256 public wrappedSftSlot;
    address public navOracle;
    uint256 public holdingValueSftId;
    uint256[] internal _holdingEmptySftIds;

    // keccak256(abi.encode(uint256(keccak256("solv.storage.SolvBTC")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SolvBTCStorageLocation = 0x25351088c72db31d4a47cbdabb12f8d9c124b300211236164ae2941317058400;

    bytes32 public constant SOLVBTC_MINTER_ROLE = keccak256(abi.encodePacked("SOLVBTC_MINTER"));

    event SetSolvBTCMultiAssetPool(address indexed solvBTCMultiAssetPool);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_) external virtual initializer {
        ERC20Upgradeable.__ERC20_init(name_, symbol_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    function initializeV2(address solvBTCMultiAssetPool_) external virtual reinitializer(2) {
        require(msg.sender == 0x55C09707Fd7aFD670e82A62FaeE312903940013E, "SolvBTC: only owner");
        _transferOwnership(msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setSolvBTCMultiAssetPool(solvBTCMultiAssetPool_);

        if (holdingValueSftId != 0) {
            ERC3525TransferHelper.doTransferOut(wrappedSftAddress, solvBTCMultiAssetPool(), holdingValueSftId);
        }
        wrappedSftAddress = address(0);
        wrappedSftSlot = 0;
        navOracle = address(0);
        holdingValueSftId = 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC3525Receiver).interfaceId || 
            interfaceId == type(IERC721Receiver).interfaceId || 
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC3525Received(
        address, /* operator_ */
        uint256 /* fromSftId_ */,
        uint256 /* sftId_ */,
        uint256 /* value_ */,
        bytes calldata /* data_ */
    ) external virtual override returns (bytes4) {
        revert ERC3525NotReceivable(msg.sender);
    }

    function onERC721Received(
        address /* operator_ */, 
        address /* from_ */, 
        uint256 /* sftId_ */, 
        bytes calldata /* data_ */ 
    ) external virtual override returns (bytes4) {
        revert ERC721NotReceivable(msg.sender);
    }

    function mint(address account_, uint256 value_) external virtual nonReentrant onlyRole(SOLVBTC_MINTER_ROLE) {
        require(value_ > 0, "SolvBTC: mint value cannot be 0");
        _mint(account_, value_);
    }

    function burn(address account_, uint256 value_) external virtual nonReentrant onlyRole(SOLVBTC_MINTER_ROLE) {
        require(value_ > 0, "SolvBTC: burn value cannot be 0");
        _burn(account_, value_);
    }

    function sweepEmptySftIds(address sft_, uint256 sweepAmount_) external virtual {
        uint256 length = _holdingEmptySftIds.length;
        for (uint256 i = 0; i < length && i < sweepAmount_; i++) {
            uint256 lastSftId = _holdingEmptySftIds[_holdingEmptySftIds.length - 1];
            ERC3525TransferHelper.doTransferOut(sft_, 0x000000000000000000000000000000000000dEaD, lastSftId);
            _holdingEmptySftIds.pop();
        }
        if (_holdingEmptySftIds.length == 0) {
            delete _holdingEmptySftIds;
        }
    }

    function _getSolvBTCStorage() private pure returns (SolvBTCStorage storage $) {
        assembly {
            $.slot := SolvBTCStorageLocation
        }
    }

    function solvBTCMultiAssetPool() public view virtual returns (address) {
        SolvBTCStorage storage $ = _getSolvBTCStorage();
        return $._solvBTCMultiAssetPool;
    }

    function _setSolvBTCMultiAssetPool(address solvBTCMultiAssetPool_) internal virtual {
        require(solvBTCMultiAssetPool_ != address(0), "SolvBTC: invalid solvBTCMultiAssetPool address");
        SolvBTCStorage storage $ = _getSolvBTCStorage();
        require($._solvBTCMultiAssetPool == address(0), "SolvBTC: solvBTCMultiAssetPool already set");
        $._solvBTCMultiAssetPool = solvBTCMultiAssetPool_;
        emit SetSolvBTCMultiAssetPool(solvBTCMultiAssetPool_);
    }

    uint256[45] private __gap;
}
