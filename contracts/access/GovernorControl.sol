// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract GovernorControl {

	event NewGovernor(address oldGovernor, address newGovernor);
	event NewPendingGovernor(address oldPendingGovernor, address newPendingGovernor);

	address public governor;
	address public pendingGovernor;

	modifier onlyGovernor() {
		require(governor == msg.sender, "only governor");
		_;
	}

	modifier onlyPendingGovernor() {
		require(pendingGovernor == msg.sender, "only governor");
		_;
	}

	constructor(address governor_) {
		governor = governor_;
		emit NewGovernor(address(0), governor_);
	}

	function transferGovernance(address newPendingGovernor_) external virtual onlyGovernor {
		emit NewPendingGovernor(pendingGovernor, newPendingGovernor_);
		pendingGovernor = newPendingGovernor_;
	}

	function acceptGovernance() external virtual onlyPendingGovernor {
		emit NewGovernor(governor, pendingGovernor);
		governor = pendingGovernor;
		delete pendingGovernor;
	}
}

