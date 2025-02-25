// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./access/AdminControlUpgradeable.sol";
import "./access/GovernorControlUpgradeable.sol";
import "./utils/ERC20TransferHelper.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./external/IERC3525.sol";
import "./external/IOpenFundMarket.sol";
import "./BitcoinReserveOffering.sol";

contract BRORouter is ReentrancyGuardUpgradeable, AdminControlUpgradeable, GovernorControlUpgradeable {

    event CreateSubscription(
        bytes32 indexed poolId,
        address indexed subscriber,
        address sftWrappedToken,
        uint256 swtTokenAmount,
        address currency,
        uint256 currencyAmount
    );

    event SetBroToken(address indexed sftAddress, uint256 indexed sftSlot, address indexed broToken);

    address public openFundMarket;

    // sft address => sft slot => broToken address
    mapping(address => mapping(uint256 => address)) public broTokens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address governor_, address openFundMarket_) external initializer {
        require(governor_ != address(0), "BRORouter: invalid governor");
        require(openFundMarket_ != address(0), "BRORouter: invalid openFundMarket");

        AdminControlUpgradeable.__AdminControl_init(msg.sender);
        GovernorControlUpgradeable.__GovernorControl_init(governor_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        openFundMarket = openFundMarket_;
    }

    function createSubscription(bytes32 poolId_, uint256 currencyAmount_)
        external
        virtual
        nonReentrant
        returns (uint256 shareValue_)
    {
        require(checkPoolPermission(poolId_), "BRORouter: pool permission denied");
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        IERC3525 openFundShare = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        uint256 openFundShareSlot = poolInfo.poolSFTInfo.openFundShareSlot;
        ERC20TransferHelper.doTransferIn(poolInfo.currency, msg.sender, currencyAmount_);

        ERC20TransferHelper.doApprove(poolInfo.currency, openFundMarket, currencyAmount_);
        shareValue_ =
            IOpenFundMarket(openFundMarket).subscribe(poolId_, currencyAmount_, 0, uint64(block.timestamp + 300));

        uint256 shareCount = openFundShare.balanceOf(address(this));
        uint256 shareId = openFundShare.tokenOfOwnerByIndex(address(this), shareCount - 1);
        require(openFundShare.slotOf(shareId) == openFundShareSlot, "BRORouter: incorrect share slot");
        require(openFundShare.balanceOf(shareId) == shareValue_, "BRORouter: incorrect share value");

        address broToken = broTokens[address(openFundShare)][openFundShareSlot];
        require(broToken != address(0), "BRORouter: broToken not created");

        uint256 broTokenBalanceBefore = IERC20(broToken).balanceOf(address(this));
        ERC3525TransferHelper.doSafeTransferOut(address(openFundShare), broToken, shareId);
        uint256 netBroTokenAmount = IERC20(broToken).balanceOf(address(this)) - broTokenBalanceBefore;
        ERC20TransferHelper.doTransferOut(broToken, payable(msg.sender), netBroTokenAmount);

        emit CreateSubscription(poolId_, msg.sender, broToken, shareValue_, poolInfo.currency, currencyAmount_);
    }

    function checkPoolPermission(bytes32 poolId_) public view virtual returns (bool) {
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        if (poolInfo.permissionless) {
            return true;
        }
        address whiteListManager = IOpenFundMarket(openFundMarket).getAddress("OFMWhitelistStrategyManager");
        return IOFMWhitelistStrategyManager(whiteListManager).isWhitelisted(poolId_, msg.sender);
    }

    function setBroToken(address sftAddress_, uint256 sftSlot_, address broToken_) external onlyGovernor {
        require(sftAddress_ != address(0), "BRORouter: invalid sft address");
        require(sftSlot_ != 0, "BRORouter: invalid sft slot");
        require(broToken_ != address(0), "BRORouter: invalid bro token");
        broTokens[sftAddress_][sftSlot_] = broToken_;
        emit SetBroToken(sftAddress_, sftSlot_, broToken_);
    }

    uint256[48] private __gap;
}
