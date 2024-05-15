// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./utils/ERC20TransferHelper.sol";

contract SolvBTC is ERC20Upgradeable, ReentrancyGuardUpgradeable {
    
    address public underlyingAsset;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_, address underlyingAsset_)
        external
        virtual
        initializer
    {
        ERC20Upgradeable.__ERC20_init(name_, symbol_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        underlyingAsset = underlyingAsset_;
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
