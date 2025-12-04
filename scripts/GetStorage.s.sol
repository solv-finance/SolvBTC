// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

contract GetStorage is Script {
    function run() public {
        vm.startBroadcast();

        console2.logBytes32(
            keccak256(abi.encode(uint256(keccak256("solv.storage.BTCPlusRedeem")) - 1)) & ~bytes32(uint256(0xff))
        );

        vm.stopBroadcast();
    }
}
