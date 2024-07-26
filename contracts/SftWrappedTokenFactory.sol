// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./access/AdminControl.sol";
import "./access/GovernorControl.sol";

contract SftWrappedTokenFactory is AdminControl, GovernorControl {

    event NewImplementation(string indexed productType, address indexed implementation);
    event NewBeacon(string indexed productType, address indexed beacon, address indexed implementation);
    event UpgradeBeacon(string indexed productType, address indexed beacon, address indexed implementation);
    event TransferBeaconOwnership(string indexed productType, address indexed beacon, address indexed newOwner);
    event NewBeaconProxy(string indexed productType, string indexed productName, address indexed beaconProxy);
    event RemoveBeaconProxy(string indexed productType, string indexed productName, address indexed beaconProxy);
    event SftWrappedTokenCreated(
        address indexed wrappedSft, uint256 indexed wrappedSftSlot, address indexed sftWrappedToken, 
        string name, string symbol, address navOracle
    );
    
    struct ProductType {
        address implementation;
        address beacon;
        mapping(string => address) proxies;
    }

    struct SftWrappedTokenInfo {
        string name;
        string symbol;
        address wrappedSft;
        uint256 wrappedSftSlot;
        address navOracle;
    }

    mapping(string => ProductType) public productTypes;

    // sftWrappedToken address
    mapping(address => SftWrappedTokenInfo) public sftWrappedTokenInfos;

    // sft address => sft slot => sftWrappedToken address
    mapping(address => mapping(uint256 => address)) public sftWrappedTokens;

    constructor(address governor_) AdminControl(msg.sender) GovernorControl(governor_) {
        require(governor_ != address(0), "SftWrappedTokenFactory: invalid governor");
    }
    
    function setImplementation(string memory productType_, address implementation_) external virtual onlyAdmin {
        require(implementation_ != address(0), "SftWrappedTokenFactory: invalid implementation");
        productTypes[productType_].implementation = implementation_;
        emit NewImplementation(productType_, implementation_);
    }

    function deployBeacon(string memory productType_) external virtual onlyAdmin returns (address beacon) {
        address implementation = productTypes[productType_].implementation;
        require(implementation != address(0), "SftWrappedTokenFactory: implementation not deployed");
        require(productTypes[productType_].beacon == address(0), "SftWrappedTokenFactory: beacon already deployed");

        beacon = address(new UpgradeableBeacon(implementation, address(this)));
        productTypes[productType_].beacon = beacon;
        emit NewBeacon(productType_, beacon, implementation);
    }

    function upgradeBeacon(string memory productType_) external virtual onlyAdmin {
        address latestImplementation = productTypes[productType_].implementation;
        address beacon = productTypes[productType_].beacon;
        
        require(latestImplementation != address(0), "SftWrappedTokenFactory: implementation not deployed");
        require(UpgradeableBeacon(beacon).implementation() != latestImplementation, "SftWrappedTokenFactory: same implementation");
        UpgradeableBeacon(beacon).upgradeTo(latestImplementation);
        emit UpgradeBeacon(productType_, beacon, latestImplementation);
    }

    function transferBeaconOwnership(string memory productType_, address newOwner_) external virtual onlyAdmin {
        address beacon = productTypes[productType_].beacon;
        UpgradeableBeacon(beacon).transferOwnership(newOwner_);
        emit TransferBeaconOwnership(productType_, beacon, newOwner_);
    }

    function deployProductProxy(
        string memory productType_, string memory productName_,
        string memory tokenName_, string memory tokenSymbol_, 
        address wrappedSft_, uint256 wrappedSftSlot_, 
        address navOracle_
    ) external virtual onlyGovernor returns (address proxy_) {
        require(wrappedSft_ != address(0), "SftWrappedTokenFactory: invalid wrapped sft address");
        require(navOracle_ != address(0), "SftWrappedTokenFactory: invalid nav oracle address");
        require(sftWrappedTokens[wrappedSft_][wrappedSftSlot_] == address(0), "SftWrappedTokenFactory: SftWrappedToken already deployed");

        ProductType storage productType = productTypes[productType_];
        require(productType.proxies[productName_] == address(0), "SftWrappedTokenFactory: product already deployed");
        require(productType.beacon != address(0), "SftWrappedTokenFactory: beacon not deployed");

        proxy_ = address(new BeaconProxy(productType.beacon, new bytes(0)));
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,address,uint256,address)",
            tokenName_, tokenSymbol_, wrappedSft_, wrappedSftSlot_, navOracle_
        );
        (bool success, ) = proxy_.call(initData);
        require(success, "SftWrappedTokenFactory: initialization failed");

        productType.proxies[productName_] = proxy_;
        emit NewBeaconProxy(productType_, productName_, proxy_);

        sftWrappedTokenInfos[proxy_] = SftWrappedTokenInfo({
            name: tokenName_, symbol: tokenSymbol_, wrappedSft: wrappedSft_,
            wrappedSftSlot: wrappedSftSlot_, navOracle: navOracle_
        });
        sftWrappedTokens[wrappedSft_][wrappedSftSlot_] = proxy_;

        emit SftWrappedTokenCreated(wrappedSft_, wrappedSftSlot_, proxy_, tokenName_, tokenSymbol_, navOracle_);
    }

    function removeProductProxy(string memory productType_, string memory productName_) external onlyGovernor {
        address proxy = productTypes[productType_].proxies[productName_];
        require(proxy != address(0), "SftWrappedTokenFactory: proxy not deployed");
        delete productTypes[productType_].proxies[productName_];
        emit RemoveBeaconProxy(productType_, productName_, proxy);
    }

    function getImplementation(string memory productType_) external view virtual returns (address) {
        return productTypes[productType_].implementation;
    }

    function getBeacon(string memory productType_) external view virtual returns (address) {
        return productTypes[productType_].beacon;
    }

    function getProxy(string memory productType_, string memory productName_) public view returns (address) {
        return productTypes[productType_].proxies[productName_];
    }

}
