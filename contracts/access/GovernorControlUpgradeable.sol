// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract GovernorControlUpgradeable is Initializable {

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

    function __GovernorControl_init(address governor_) internal onlyInitializing {
        __GovernorControl_init_unchained(governor_);
    }

    function __GovernorControl_init_unchained(address governor_) internal onlyInitializing {
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

    uint256[48] private __gap;
}
