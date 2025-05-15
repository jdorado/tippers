// *******************************************************
// *    _______ _                           *
// *   |__   __(_)                          *
// *      | |   _ _ __  _ __   ___ _ __ ___ *
// *      | |  | | '_ \| '_ \ / _ \ '__/ __|*
// *      | |  | | |_) | |_) |  __/ |  \__ \*
// *      |_|  |_| .__/| .__/ \___|_|  |___/*
// *             |_|   |_|                   *
// *******************************************************

// Primary Author(s)
// Juan C. Dorado: https://github.com/jdorado/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStakingPool.sol";

/**
 * @title StakingPool
 * @dev A staking pool contract where users can stake ERC20 tokens and earn rewards
 */
contract StakingPool is 
    IStakingPool,
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    /// @dev The token being staked
    IERC20 public stakingToken;
    
    /// @dev The reward rate per second (in wei)
    uint256 public rewardRate;
    
    /// @dev Last time rewards were updated
    uint256 public lastUpdateTime;
    
    /// @dev Accumulated rewards per share
    uint256 public rewardPerShareStored;
    
    /// @dev Total staked amount
    uint256 public totalStaked;
    
    /// @dev Available rewards in the pool
    uint256 public availableRewards;

    /// @dev Mapping of user address to staked amount
    mapping(address => uint256) public override stakedAmount;
    
    /// @dev User reward per share paid
    mapping(address => uint256) private userRewardPerSharePaid;
    
    /// @dev User rewards to be claimed
    mapping(address => uint256) private rewards;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _stakingToken,
        uint256 _rewardRate
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();

        require(_stakingToken != address(0), "Invalid staking token");
        stakingToken = IERC20(_stakingToken);
        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
    }

    /**
     * @dev Required by the OZ UUPS module
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Updates the reward state for a user
     */
    modifier updateReward(address account) {
        rewardPerShareStored = rewardPerShare();
        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerSharePaid[account] = rewardPerShareStored;
        }
        _;
    }

    /**
     * @dev Returns the current reward per share
     */
    function rewardPerShare() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerShareStored;
        }
        return rewardPerShareStored + (
            ((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalStaked
        );
    }

    /**
     * @dev Returns the earned rewards for an account
     */
    function earned(address account) public view returns (uint256) {
        return (
            (stakedAmount[account] * (rewardPerShare() - userRewardPerSharePaid[account])) / 1e18
        ) + rewards[account];
    }

    /**
     * @dev Stakes tokens in the pool
     */
    function stake(uint256 amount) external override nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        
        totalStaked += amount;
        stakedAmount[msg.sender] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Unstakes tokens from the pool
     */
    function unstake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(stakedAmount[msg.sender] >= amount, "Insufficient balance");

        totalStaked -= amount;
        stakedAmount[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev Claims available rewards
     */
    function claimRewards() external override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        require(reward <= availableRewards, "Insufficient rewards in pool");

        rewards[msg.sender] = 0;
        availableRewards -= reward;
        stakingToken.safeTransfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @dev Funds the reward pool (admin only)
     */
    function fundRewardPool(uint256 amount) external override onlyOwner nonReentrant {
        require(amount > 0, "Cannot fund 0");
        
        availableRewards += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        
        emit RewardsFunded(amount);
    }

    /**
     * @dev Returns pending rewards for a user
     */
    function pendingRewards(address user) external view override returns (uint256) {
        return earned(user);
    }

    /**
     * @dev Pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Updates the reward rate (admin only)
     */
    function setRewardRate(uint256 _rewardRate) external onlyOwner updateReward(address(0)) {
        rewardRate = _rewardRate;
    }
} 