// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@solvprotocol/erc-3525/ERC3525.sol";
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

interface IOpenFundSftDelegate {
	function concrete() external view returns (address);
}

interface IOpenFundSftConcrete {
	function slotBaseInfo(uint256 slot) external view returns (SlotBaseInfo memory);
}

interface INavOracle {
    function getSubscribeNav(bytes32 poolId, uint256 time) external view returns (uint256 nav, uint256 navTime);
}

contract SftWrappedToken is ISftWrappedToken, ERC20, ReentrancyGuard {

    address public wrappedSftAddress;
    uint256 public wrappedSftSlot;
    address public navOracle;
    uint256 public holdingSftId;

    constructor(
        string memory name_, string memory symbol_, 
        address wrappedSftAddress_, uint256 wrappedSftSlot_, address navOracle_
    )
        ERC20(name_, symbol_) 
        ReentrancyGuard()
    {
        wrappedSftAddress = wrappedSftAddress_;
        wrappedSftSlot = wrappedSftSlot_;
        navOracle = navOracle_;
    }

    function decimals() public view virtual override returns (uint8) {
        return ERC3525(wrappedSftAddress).valueDecimals();
    }

    function mint(uint256 sftId_, uint256 amount_) external virtual override nonReentrant {
        require(wrappedSftSlot == ERC3525(wrappedSftAddress).slotOf(sftId_), "SftWrappedToken: slot does not match");
        require(_msgSender() == ERC3525(wrappedSftAddress).ownerOf(sftId_), "SftWrappedToken: caller is not sft owner");
        require(amount_ > 0, "SftWrappedToken: mint amount cannot be 0");
        require(amount_ <= ERC3525(wrappedSftAddress).balanceOf(sftId_), "SftWrappedToken: mint amount exceeds sft balance");

        if (ERC3525(wrappedSftAddress).balanceOf(address(this)) == 0) {
            holdingSftId = ERC3525TransferHelper.doTransferIn(wrappedSftAddress, sftId_, amount_);
        } else {
            ERC3525TransferHelper.doTransfer(wrappedSftAddress, sftId_, holdingSftId, amount_);
        }

        _mint(_msgSender(), amount_);
    }

    function burn(uint256 amount_, uint256 sftId_) external virtual override nonReentrant returns (uint256 toSftId_) {
        require(amount_ > 0, "SftWrappedToken: burn amount cannot be 0");
        _burn(_msgSender(), amount_);

        if (sftId_ == 0) {
            toSftId_ = ERC3525TransferHelper.doTransferOut(wrappedSftAddress, holdingSftId, _msgSender(), amount_);
        } else {
            require(wrappedSftSlot == ERC3525(wrappedSftAddress).slotOf(sftId_), "SftWrappedToken: slot does not match");
            ERC3525TransferHelper.doTransfer(wrappedSftAddress, holdingSftId, sftId_, amount_);
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
        return value * (10 ** decimals()) / latestNav;
    }

    // underlying asset address
    function underlyingAsset() external view virtual override returns (address) {
        address sftConcreteAddress = IOpenFundSftDelegate(wrappedSftAddress).concrete();
        SlotBaseInfo memory slotBaseInfo = IOpenFundSftConcrete(sftConcreteAddress).slotBaseInfo(wrappedSftSlot);
        return slotBaseInfo.currency;
    }
}