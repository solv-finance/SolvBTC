// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./access/AdminControl.sol";
import "./access/GovernorControl.sol";

contract SolvBTCFactory is AdminControl, GovernorControl {

    event NewImplementation(string indexed productType, address indexed implementation);
    event NewBeacon(string indexed productType, address indexed beacon, address indexed implementation);
    event ImportBeacon(string indexed productType, address indexed beacon, address indexed implementation);
    event UpgradeBeacon(string indexed productType, address indexed beacon, address indexed implementation);
    event TransferBeaconOwnership(string indexed productType, address indexed beacon, address indexed newOwner);
    event NewBeaconProxy(string indexed productType, string indexed productName, address indexed beaconProxy);
    event ImportBeaconProxy(string indexed productType, string indexed productName, address indexed beaconProxy);
    event RemoveBeaconProxy(string indexed productType, string indexed productName, address indexed beaconProxy);
    
    struct ProductType {
        address implementation;
        address beacon;
        mapping(string => address) proxies;
    }

    mapping(string => ProductType) public productTypes;

    constructor(address governor_) AdminControl(msg.sender) GovernorControl(governor_) {
        require(governor_ != address(0), "SolvBTCFactory: invalid governor");
    }

    function setImplementation(string memory productType_, address implementation_) 
        external virtual onlyAdmin returns (address beacon_) 
    {
        require(implementation_ != address(0), "SolvBTCFactory: invalid implementation");
        require(implementation_ != productTypes[productType_].implementation, "SolvBTCFactory: same implementation");

        productTypes[productType_].implementation = implementation_;
        emit NewImplementation(productType_, implementation_);

        beacon_ = productTypes[productType_].beacon;
        if (beacon_ == address(0)) {
            beacon_ = address(new UpgradeableBeacon(implementation_, address(this)));
            productTypes[productType_].beacon = beacon_;
            emit NewBeacon(productType_, beacon_, implementation_);
        } else {
            UpgradeableBeacon(beacon_).upgradeTo(implementation_);
            emit UpgradeBeacon(productType_, beacon_, implementation_);
        }
    }

    function transferBeaconOwnership(string memory productType_, address newOwner_) external virtual onlyAdmin {
        address beacon = productTypes[productType_].beacon;
        UpgradeableBeacon(beacon).transferOwnership(newOwner_);
        emit TransferBeaconOwnership(productType_, beacon, newOwner_);
    }

    function importBeacon(string memory productType_, address beacon_) external virtual onlyAdmin {
        require(beacon_ != address(0), "SolvBTCFactory: invalid beacon address");
        productTypes[productType_].beacon = beacon_;
        emit ImportBeacon(productType_, beacon_, UpgradeableBeacon(beacon_).implementation());
    }

    function deployProductProxy(
        string memory productType_, string memory productName_,
        string memory tokenName_, string memory tokenSymbol_
    ) 
        external virtual onlyGovernor returns (address proxy_) 
    {
        ProductType storage productType = productTypes[productType_];
        require(productType.proxies[productName_] == address(0), "SolvBTCFactory: product already deployed");
        require(productType.beacon != address(0), "SolvBTCFactory: beacon not deployed");

        bytes32 salt = keccak256(abi.encodePacked(productType_, productName_));
        proxy_ = address(new BeaconProxy{salt: salt}(productType.beacon, new bytes(0)));

        bytes memory initData = abi.encodeWithSignature("initialize(string,string)", tokenName_, tokenSymbol_);
        (bool success, ) = proxy_.call(initData);
        require(success, "SolvBTCFactory: proxy initialization failed");

        productType.proxies[productName_] = proxy_;
        emit NewBeaconProxy(productType_, productName_, proxy_);
    }

    function importProductProxy(string memory productType_, string memory productName_, address proxy_) external onlyGovernor {
        require(productTypes[productType_].beacon != address(0), "SolvBTCFactory: beacon not deployed");
        productTypes[productType_].proxies[productName_] = proxy_;
        emit ImportBeaconProxy(productType_, productName_, proxy_);
    }

    function removeProductProxy(string memory productType_, string memory productName_) external onlyGovernor {
        address proxy = productTypes[productType_].proxies[productName_];
        require(proxy != address(0), "SolvBTCFactory: proxy not deployed");
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
