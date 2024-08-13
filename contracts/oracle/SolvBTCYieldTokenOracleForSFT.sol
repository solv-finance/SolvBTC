// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../ISolvBTCYieldTokenOracle.sol";
import "../access/AdminControlUpgradeable.sol";

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

interface ISFTNavOracle {
    function getSubscribeNav(bytes32 poolId, uint256 time) external view returns (uint256 nav, uint256 navTime);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract SolvBTCYieldTokenOracleForSFT is ISolvBTCYieldTokenOracle, AdminControlUpgradeable {
    struct SFTOracleConfig {
        bytes32 poolId;
        address sft;
        uint256 sftSlot;
        address oracle;
    }

    event SetSFTOracle(address indexed erc20, bytes32 indexed poolId, address sft, uint256 sftSlot, address oracle);

    //erc20 => sftoracle config
    mapping(address => SFTOracleConfig) public sftOracles;

    function initialize() external initializer {
        __AdminControl_init(msg.sender);
    }

    function getNav(address erc20) external view override returns (uint256) {
        SFTOracleConfig storage config = sftOracles[erc20];
        require(
            config.oracle != address(0) && config.poolId != 0x00,
            "SolvBTCYieldTokenOracleForSFT: no oracle for erc20"
        );

        (uint256 latestNav,) = ISFTNavOracle(config.oracle).getSubscribeNav(config.poolId, block.timestamp);
        return latestNav;
    }

    function navDecimals(address erc20) external view override returns (uint8) {
        SFTOracleConfig storage config = sftOracles[erc20];
        address sftConcreteAddress = IOpenFundSftDelegate(config.sft).concrete();
        SlotBaseInfo memory slotBaseInfo = IOpenFundSftConcrete(sftConcreteAddress).slotBaseInfo(config.sftSlot);
        return IERC20(slotBaseInfo.currency).decimals();
    }

    function setSFTOracle(address erc20, address sft, uint256 sftSlot, bytes32 poolId, address sftOracle)
        external
        onlyAdmin
    {
        require(erc20 != address(0), "SolvBTCYieldTokenOracleForSFT: invalid erc20 address");
        require(sft != address(0), "SolvBTCYieldTokenOracleForSFT: invalid sft address");
        require(sftSlot != 0, "SolvBTCYieldTokenOracleForSFT: invalid sft slot");
        require(poolId != 0x00, "SolvBTCYieldTokenOracleForSFT: invalid pool id");
        require(sftOracle != address(0), "SolvBTCYieldTokenOracleForSFT: invalid sft oracle address");
        sftOracles[erc20] = SFTOracleConfig({poolId: poolId, sft: sft, sftSlot: sftSlot, oracle: sftOracle});
        emit SetSFTOracle(erc20, poolId, sft, sftSlot, sftOracle);
    }
}
