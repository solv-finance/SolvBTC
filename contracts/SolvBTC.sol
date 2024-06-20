// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./ISolvBTC.sol";
import "./SolvBTCMultiAssetPool.sol";

contract SolvBTC is ISolvBTC, ERC20Upgradeable, ReentrancyGuardUpgradeable {

    address public wrappedSftAddress;
    uint256 public wrappedSftSlot;
    address public navOracle;
    uint256 public holdingValueSftId;
    uint256[] internal _holdingEmptySftIds;

    modifier onlySolvBTCMultiAssetPool() {
        require(msg.sender == solvBTCMultiAssetPool(), "SolvBTC: only SolvBTCMultiAssetPool");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_) external virtual initializer {
        ERC20Upgradeable.__ERC20_init(name_, symbol_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    function initializeV2() external virtual reinitializer(2) {
        if (holdingValueSftId != 0) {
            ERC3525TransferHelper.doTransferOut(wrappedSftAddress, solvBTCMultiAssetPool(), holdingValueSftId);
        }

        wrappedSftAddress = address(0);
        wrappedSftSlot = 0;
        navOracle = address(0);
        holdingValueSftId = 0;
        delete _holdingEmptySftIds;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return 
            interfaceId == type(IERC3525Receiver).interfaceId || 
            interfaceId == type(IERC721Receiver).interfaceId || 
            interfaceId == type(IERC165).interfaceId;
    }

    function solvBTCMultiAssetPool() public view virtual override returns (address) {
        return address(0);  // TODO: set address after SolvBTCMultiAssetPool is deployed
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

    function mint(address account_, uint256 value_) external virtual nonReentrant onlySolvBTCMultiAssetPool {
        require(value_ > 0, "SolvBTC: mint value cannot be 0");
        _mint(account_, value_);
    }

    function burn(address account_, uint256 value_) external virtual nonReentrant onlySolvBTCMultiAssetPool {
        require(value_ > 0, "SolvBTC: burn value cannot be 0");
        _burn(account_, value_);
    }
}
