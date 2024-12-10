// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./SolvBTCV2_1.sol";
import "./ISolvBTCYieldToken.sol";
import "./ISolvBTCYieldTokenOracle.sol";

contract SolvBTCYieldTokenV2_1 is SolvBTCV2_1, ISolvBTCYieldToken {

    struct SolvBTCYieldTokenStorage {
        address _oracle;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.SolvBTCYieldToken")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SolvBTCYieldTokenStorageLocation =
        0xf05073905b1e64f5ceda3673d2f3281ec4d80a5b81532923554d532211661500;

    event SetOracle(address indexed oracle);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Get amount of underlying asset for a given amount of shares.
     */
    function getValueByShares(uint256 shares) external view virtual override returns (uint256 value) {
        uint256 currentNav = ISolvBTCYieldTokenOracle(getOracle()).getNav(address(this));
        return shares * currentNav / (10 ** decimals());
    }

    /**
     * @notice Get amount of shares for a given amount of underlying asset.
     */
    function getSharesByValue(uint256 value) external view virtual override returns (uint256 shares) {
        uint256 currentNav = ISolvBTCYieldTokenOracle(getOracle()).getNav(address(this));
        return currentNav == 0 ? 0 : (value * (10 ** decimals()) / currentNav);
    }

    function _getSolvBTCLYTStorage() private pure returns (SolvBTCYieldTokenStorage storage $) {
        assembly {
            $.slot := SolvBTCYieldTokenStorageLocation
        }
    }

    function getOracle() public view virtual override returns (address) {
        SolvBTCYieldTokenStorage storage $ = _getSolvBTCLYTStorage();
        return $._oracle;
    }

    function setOracle(address oracle_) external virtual onlyOwner {
        require(oracle_ != address(0), "SolvBTCYieldToken: invalid oracle address");
        SolvBTCYieldTokenStorage storage $ = _getSolvBTCLYTStorage();
        $._oracle = oracle_;
        emit SetOracle(oracle_);
    }

    function getOracleDecimals() external view returns (uint8) {
        return ISolvBTCYieldTokenOracle(getOracle()).navDecimals(address(this));
    }
}
