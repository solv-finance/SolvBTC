// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access/GovernorControl.sol";
import "./SftWrappedToken.sol";

contract SftWrappedTokenFactory is GovernorControl {

    struct SftWrappedTokenInfo {
        string name;
        string symbol;
        address wrappedSft;
        uint256 wrappedSftSlot;
        address navOracle;
    }

    mapping(address => SftWrappedTokenInfo) internal _sftWrappedTokenInfos;

    // sft address => sft slot => wrapped token address
    mapping(address => mapping(uint256 => address)) internal _sftWrappedTokens;

    event SftWrappedTokenCreated(
        address indexed wrappedSft, uint256 indexed wrappedSftSlot, address indexed sftWrappedToken, 
        string name, string symbol, address navOracle
    );

    constructor(address governor_) GovernorControl(governor_) {}

    function createSftWrappedToken(
        string calldata name_, string calldata symbol_, 
        address wrappedSft_, uint256 wrappedSftSlot_, address navOracle_
    ) external virtual onlyGovernor returns (address sftWrappedToken_) {
        require(wrappedSft_ != address(0), "SftWrappedTokenFactory: invalid wrapped sft address");
        require(navOracle_ != address(0), "SftWrappedTokenFactory: invalid nav oracle address");

        sftWrappedToken_ = address(new SftWrappedToken(name_, symbol_, wrappedSft_, wrappedSftSlot_, navOracle_));
        _sftWrappedTokenInfos[sftWrappedToken_] = SftWrappedTokenInfo({
            name: name_, symbol: symbol_, wrappedSft: wrappedSft_,
            wrappedSftSlot: wrappedSftSlot_, navOracle: navOracle_
        });
        _sftWrappedTokens[wrappedSft_][wrappedSftSlot_] = sftWrappedToken_;

        emit SftWrappedTokenCreated(wrappedSft_, wrappedSftSlot_, sftWrappedToken_, name_, symbol_, navOracle_);
    }

    function getSftWrappedTokenInfo(address sftWrappedToken_) public virtual view returns (SftWrappedTokenInfo memory) {
        return _sftWrappedTokenInfos[sftWrappedToken_];
    }

    function getSftWrappedTokenAddress(address wrappedSft_, uint256 wrappedSftSlot_) public virtual view returns (address) {
        return(_sftWrappedTokens[wrappedSft_][wrappedSftSlot_]);
    }


}
