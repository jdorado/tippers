// *******************************************************
// *    _______ _                           *
// *   |__   __(_)                          *
// *      | |   _ _ __  _ __   ___ _ __ ___ *
// *      | |  | | '_ \| '_ \ / _ \ '__/ __|*
// *      | |  | | |_) | |_) |  __/ |  \__ \*
// *      |_|  |_| .__/| .__/ \___|_|  |___/*
// *             |_|   |_|                   *
// *******************************************************
// Demether Finance: https://github.com/demetherdefi

// Primary Author(s)
// Juan C. Dorado: https://github.com/jdorado/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStakingPool {
    /**
     * @dev Emitted when tokens are staked
     */
    event Staked(address indexed user, uint256 amount);

    /**
     * @dev Emitted when tokens are unstaked
     */
    event Unstaked(address indexed user, uint256 amount);

    /**
     * @dev Emitted when rewards are claimed
     */
    event RewardClaimed(address indexed user, uint256 amount);

    /**
     * @dev Emitted when rewards are funded
     */
    event RewardsFunded(uint256 amount);

    /**
     * @dev Stakes tokens in the pool
     */
    function stake(uint256 amount) external;

    /**
     * @dev Unstakes tokens from the pool
     */
    function unstake(uint256 amount) external;

    /**
     * @dev Claims available rewards
     */
    function claimRewards() external;

    /**
     * @dev Funds the reward pool (admin only)
     */
    function fundRewardPool(uint256 amount) external;

    /**
     * @dev Returns the staked amount for a user
     */
    function stakedAmount(address user) external view returns (uint256);

    /**
     * @dev Returns the pending rewards for a user
     */
    function pendingRewards(address user) external view returns (uint256);
} 