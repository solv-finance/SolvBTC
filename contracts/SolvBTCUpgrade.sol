// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./utils/ERC20TransferHelper.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./external/IERC3525.sol";

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

contract SolvBTCUpgrade is ERC20Upgradeable, ReentrancyGuardUpgradeable {
    //old version contract variables, not used in this contract
    address public wrappedSftAddress;
    uint256 public wrappedSftSlot;
    address public navOracle;
    uint256 public holdingValueSftId;

    uint256[] internal _holdingEmptySftIds;

    // current version contract variables
    address public underlyingAsset;
    bool public isUpgradedToV2;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_)
        external
        virtual
        initializer
    {
        ERC20Upgradeable.__ERC20_init(name_, symbol_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    function upgradeToV2DoOnlyOnce() external {
        require(!isUpgradedToV2, "SolvBTC: already upgraded to v2");
        //set the underlying asset
        address sftConcreteAddress = IOpenFundSftDelegate(wrappedSftAddress).concrete();
        SlotBaseInfo memory slotBaseInfo = IOpenFundSftConcrete(sftConcreteAddress).slotBaseInfo(wrappedSftSlot);
        underlyingAsset = slotBaseInfo.currency;

        //destroy holding value sft
        require(wrappedSftAddress != address(0), "SolvBTC: invalid wrapped sft address");
        require(wrappedSftSlot != 0, "SolvBTC: invalid wrapped sft slot");
        require(IERC3525(wrappedSftAddress).balanceOf(address(this)) > 0, "SolvBTC: no wrapped sft balance");
        require(holdingValueSftId != 0, "SolvBTC: sft have been destoryed");
        require(IERC3525(wrappedSftAddress).balanceOf(holdingValueSftId) > 0, "SolvBTC: no holding value sft balance");
        ERC3525TransferHelper.doTransferOut(
            wrappedSftAddress, 0x000000000000000000000000000000000000dEaD, holdingValueSftId
        );

        holdingValueSftId = 0;
        wrappedSftAddress = address(0);
        wrappedSftSlot = 0;
        navOracle = address(0);
        isUpgradedToV2 = true;
    }

    /**
     * @param amount_ the amount of underlying asset
     */
    function deposit(uint256 amount_) external virtual nonReentrant {
        require(amount_ > 0, "SolvBTC: invalid amount");
        require(underlyingAsset != address(0), "SolvBTC: invalid underlying asset");

        uint8 solvBtcDecimals = decimals();
        uint8 underlyingAssetDecimals = ERC20Upgradeable(underlyingAsset).decimals();

        uint256 solvBtcAmount = amount_ * (10 ** solvBtcDecimals) / (10 ** underlyingAssetDecimals);
        ERC20TransferHelper.doTransferIn(underlyingAsset, msg.sender, amount_);
        _mint(msg.sender, solvBtcAmount);

        uint256 underlyingAssetBalance = ERC20Upgradeable(underlyingAsset).balanceOf(address(this));
        require(
            underlyingAssetBalance * (10 ** solvBtcDecimals) >= totalSupply() * (10 ** underlyingAssetDecimals), 
            "SolvBTC: balance check error"
        );
    }

    /**
     * @param amount_ the amount of SolvBTC to burn
     */
    function withdraw(uint256 amount_) external virtual nonReentrant {
        require(amount_ > 0, "SolvBTC: invalid amount");
        require(underlyingAsset != address(0), "SolvBTC: invalid underlying asset");

        uint8 solvBtcDecimals = decimals();
        uint8 underlyingAssetDecimals = ERC20Upgradeable(underlyingAsset).decimals();

        uint256 underlyingAssetAmount = amount_ * (10 ** underlyingAssetDecimals) / (10 ** solvBtcDecimals);
        _burn(msg.sender, amount_);
        ERC20TransferHelper.doTransferOut(underlyingAsset, payable(msg.sender), underlyingAssetAmount);

        uint256 underlyingAssetBalance = ERC20Upgradeable(underlyingAsset).balanceOf(address(this));
        require(
            underlyingAssetBalance * (10 ** solvBtcDecimals) >= totalSupply() * (10 ** underlyingAssetDecimals), 
            "SolvBTC: balance check error"
        );
    }
}
