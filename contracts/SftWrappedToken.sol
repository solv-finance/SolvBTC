// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./ISftWrappedToken.sol";

struct SlotBaseInfo {
    address issuer;
    address currency;
    uint64 valueDate;
    uint64 maturity;
    uint64 createTime;
    bool transferable;
    bool isValid;
}

interface IERC3525 {
    function valueDecimals() external view returns (uint8);
    function balanceOf(address owner) external view returns (uint256);
    function balanceOf(uint256 sftId) external view returns (uint256);
    function ownerOf(uint256 sftId) external view returns (address);
    function slotOf(uint256 sftId) external view returns (uint256);
}

interface IOpenFundSftDelegate {
	function concrete() external view returns (address);
}

interface IOpenFundSftConcrete {
	function slotBaseInfo(uint256 slot) external view returns (SlotBaseInfo memory);
}

interface INavOracle {
    function getSubscribeNav(bytes32 poolId, uint256 time) external view returns (uint256 nav, uint256 navTime);
}

contract SftWrappedToken is ISftWrappedToken, ERC20Upgradeable, ReentrancyGuardUpgradeable {

    address public wrappedSftAddress;
    uint256 public wrappedSftSlot;
    address public navOracle;
    uint256 public holdingValueSftId;

    uint256[] internal _holdingEmptySftIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }
    
    function initialize(
        string memory name_, string memory symbol_, 
        address wrappedSftAddress_, uint256 wrappedSftSlot_, address navOracle_
    ) external virtual initializer {
        require(wrappedSftAddress_ != address(0), "SftWrappedToken: invalid sft address");
        require(wrappedSftSlot_ != 0, "SftWrappedToken: invalid sft slot");
        require(navOracle_ != address(0), "SftWrappedToken: invalid nav oracle address");

        ERC20Upgradeable.__ERC20_init(name_, symbol_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        wrappedSftAddress = wrappedSftAddress_;
        wrappedSftSlot = wrappedSftSlot_;
        navOracle = navOracle_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC3525Receiver).interfaceId || 
            interfaceId == type(IERC721Receiver).interfaceId || 
            interfaceId == type(IERC165).interfaceId;
    }

    function decimals() public view virtual override returns (uint8) {
        return IERC3525(wrappedSftAddress).valueDecimals();
    }

    function onERC3525Received(address /* operator_ */, uint256 fromSftId_, uint256 sftId_, uint256 value_, bytes calldata /* data_ */) 
        external 
        virtual 
        override 
        returns (bytes4) 
    {
        address fromSftOwner = IERC3525(wrappedSftAddress).ownerOf(fromSftId_);

        if (fromSftOwner == address(this)) {
            return IERC3525Receiver.onERC3525Received.selector;
        }

        require(value_ > 0, "SftWrappedToken: mint zero not allowed");
        if (holdingValueSftId == 0) {
            require(wrappedSftSlot == IERC3525(wrappedSftAddress).slotOf(sftId_), "SftWrappedToken: unreceivable slot");
            require(address(this) == IERC3525(wrappedSftAddress).ownerOf(sftId_), "SftWrappedToken: not owned sft id");
            holdingValueSftId = sftId_;
        } else {
            require(holdingValueSftId == sftId_, "SftWrappedToken: not holding value sft id");
        }

        _mint(fromSftOwner, value_);

        return IERC3525Receiver.onERC3525Received.selector;
    }

    function onERC721Received(address /* operator_ */, address from_, uint256 sftId_, bytes calldata /* data_ */) 
        external 
        virtual 
        override 
        returns (bytes4) 
    {
        require(wrappedSftSlot == IERC3525(wrappedSftAddress).slotOf(sftId_), "SftWrappedToken: unreceivable slot");
       require(address(this) == IERC3525(wrappedSftAddress).ownerOf(sftId_), "SftWrappedToken: not owned sft id");

        if (from_ == address(this)) {
            return IERC721Receiver.onERC721Received.selector;
        }

        uint256 sftValue = IERC3525(wrappedSftAddress).balanceOf(sftId_);
        require(sftValue > 0, "SftWrappedToken: mint zero not allowed");

        if (holdingValueSftId == 0) {
            holdingValueSftId = sftId_;
        } else {
            ERC3525TransferHelper.doTransfer(wrappedSftAddress, sftId_, holdingValueSftId, sftValue);
            _holdingEmptySftIds.push(sftId_);
        }
        _mint(from_, sftValue);
        return IERC721Receiver.onERC721Received.selector;
    }

    function mint(uint256 sftId_, uint256 amount_) external virtual override nonReentrant {
        require(wrappedSftSlot == IERC3525(wrappedSftAddress).slotOf(sftId_), "SftWrappedToken: slot does not match");
        require(msg.sender == IERC3525(wrappedSftAddress).ownerOf(sftId_), "SftWrappedToken: caller is not sft owner");
        require(amount_ > 0, "SftWrappedToken: mint amount cannot be 0");

        uint256 sftBalance = IERC3525(wrappedSftAddress).balanceOf(sftId_);
        if (amount_ == sftBalance) {
            ERC3525TransferHelper.doSafeTransferIn(wrappedSftAddress, msg.sender, sftId_);
        } else if (amount_ < sftBalance) {
            if (holdingValueSftId == 0) {
                holdingValueSftId = ERC3525TransferHelper.doTransferIn(wrappedSftAddress, sftId_, amount_);
            } else {
                ERC3525TransferHelper.doTransfer(wrappedSftAddress, sftId_, holdingValueSftId, amount_);
            }
        } else {
            revert("SftWrappedToken: mint amount exceeds sft balance");
        }
    }

    function burn(uint256 amount_, uint256 sftId_) external virtual override nonReentrant returns (uint256 toSftId_) {
        require(amount_ > 0, "SftWrappedToken: burn amount cannot be 0");
        _burn(msg.sender, amount_);

        if (sftId_ == 0) {
            if (_holdingEmptySftIds.length == 0) {
                toSftId_ = ERC3525TransferHelper.doTransferOut(wrappedSftAddress, holdingValueSftId, msg.sender, amount_);
            } else {
                toSftId_ = _holdingEmptySftIds[_holdingEmptySftIds.length - 1];
                _holdingEmptySftIds.pop();
                ERC3525TransferHelper.doTransfer(wrappedSftAddress, holdingValueSftId, toSftId_, amount_);
                ERC3525TransferHelper.doTransferOut(wrappedSftAddress, msg.sender, toSftId_);
            }
        } else {
            require(wrappedSftSlot == IERC3525(wrappedSftAddress).slotOf(sftId_), "SftWrappedToken: slot does not match");
            require(msg.sender == IERC3525(wrappedSftAddress).ownerOf(sftId_), "SftWrappedToken: not sft owner");
            ERC3525TransferHelper.doTransfer(wrappedSftAddress, holdingValueSftId, sftId_, amount_);
            toSftId_ = sftId_;
        }
    }

    /**
     * @notice Get amount of underlying asset for a given amount of shares.
     */
    function getValueByShares(uint256 shares) external view virtual override returns (uint256 value) {
        bytes32 poolId = keccak256(abi.encode(wrappedSftAddress, wrappedSftSlot));
        (uint256 latestNav, ) = INavOracle(navOracle).getSubscribeNav(poolId, block.timestamp);
        return shares * latestNav / (10 ** decimals());
    }

    /**
     * @notice Get amount of shares for a given amount of underlying asset.
     */
    function getSharesByValue(uint256 value) external view virtual override returns (uint256 shares) {
        bytes32 poolId = keccak256(abi.encode(wrappedSftAddress, wrappedSftSlot));
        (uint256 latestNav, ) = INavOracle(navOracle).getSubscribeNav(poolId, block.timestamp);
        return latestNav == 0 ? 0 : (value * (10 ** decimals()) / latestNav);
    }

    // underlying asset address
    function underlyingAsset() external view virtual override returns (address) {
        address sftConcreteAddress = IOpenFundSftDelegate(wrappedSftAddress).concrete();
        SlotBaseInfo memory slotBaseInfo = IOpenFundSftConcrete(sftConcreteAddress).slotBaseInfo(wrappedSftSlot);
        return slotBaseInfo.currency;
    }
}