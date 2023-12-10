// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract GovernorControl {

	event NewGovernor(address oldGovernor, address newGovernor);

	address public governor;

	modifier onlyGovernor() {
		require(governor == msg.sender, "only governor");
		_;
	}

	constructor(address governor_) {
		_setGovernor(governor_);
	}

	function _setGovernor(address newGovernor_) internal {
		require(newGovernor_ != address(0), "Governor address connot be 0");
		emit NewGovernor(governor, newGovernor_);
		governor = newGovernor_;
	}
	
}

