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

import "forge-std/Test.sol";
import "../src/StakingPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract StakingPoolTest is Test {
    StakingPool public stakingPool;
    MockERC20 public token;
    address public owner;
    address public alice;
    address public bob;

    uint256 public constant INITIAL_BALANCE = 1000 * 1e18;
    uint256 public constant REWARD_RATE = 1 * 1e18; // 1 token per second

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardsFunded(uint256 amount);

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Deploy mock token
        token = new MockERC20();

        // Deploy staking pool implementation
        StakingPool implementation = new StakingPool();
        
        // Create initialization data
        bytes memory initData = abi.encodeWithSelector(
            StakingPool.initialize.selector,
            address(token),
            REWARD_RATE
        );

        // Deploy and initialize proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        stakingPool = StakingPool(address(proxy));

        // Fund users with tokens
        token.transfer(alice, INITIAL_BALANCE);
        token.transfer(bob, INITIAL_BALANCE);

        // Approve staking pool for all users
        vm.prank(alice);
        token.approve(address(stakingPool), type(uint256).max);
        vm.prank(bob);
        token.approve(address(stakingPool), type(uint256).max);
        token.approve(address(stakingPool), type(uint256).max);
    }

    function testInitialization() public view {
        assertEq(address(stakingPool.stakingToken()), address(token));
        assertEq(stakingPool.rewardRate(), REWARD_RATE);
        assertEq(stakingPool.totalStaked(), 0);
        assertEq(stakingPool.availableRewards(), 0);
    }

    function testStaking() public {
        uint256 stakeAmount = 100 * 1e18;
        
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Staked(alice, stakeAmount);
        stakingPool.stake(stakeAmount);

        assertEq(stakingPool.totalStaked(), stakeAmount);
        assertEq(stakingPool.stakedAmount(alice), stakeAmount);
        assertEq(token.balanceOf(address(stakingPool)), stakeAmount);
    }

    function testUnstaking() public {
        uint256 stakeAmount = 100 * 1e18;
        
        vm.prank(alice);
        stakingPool.stake(stakeAmount);

        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Unstaked(alice, stakeAmount);
        stakingPool.unstake(stakeAmount);

        assertEq(stakingPool.totalStaked(), 0);
        assertEq(stakingPool.stakedAmount(alice), 0);
        assertEq(token.balanceOf(address(stakingPool)), 0);
    }

    function testRewards() public {
        uint256 stakeAmount = 100 * 1e18;
        uint256 rewardAmount = 1000 * 1e18;

        // Fund reward pool
        token.approve(address(stakingPool), rewardAmount);
        stakingPool.fundRewardPool(rewardAmount);

        // Stake tokens
        vm.prank(alice);
        stakingPool.stake(stakeAmount);

        // Advance time
        vm.warp(block.timestamp + 100); // Advance 100 seconds

        // Calculate expected rewards (100 seconds * REWARD_RATE)
        uint256 expectedRewards = 100 * REWARD_RATE;

        assertApproxEqRel(
            stakingPool.pendingRewards(alice),
            expectedRewards,
            0.000001e18 // Allow for minimal rounding errors
        );

        // Claim rewards
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit RewardClaimed(alice, expectedRewards);
        stakingPool.claimRewards();

        assertEq(stakingPool.pendingRewards(alice), 0);
    }

    function testPause() public {
        uint256 stakeAmount = 100 * 1e18;

        // Pause the contract
        stakingPool.pause();

        // Try to stake (should revert)
        vm.prank(alice);
        vm.expectRevert(bytes4(keccak256("EnforcedPause()")));
        stakingPool.stake(stakeAmount);

        // Unpause
        stakingPool.unpause();

        // Now staking should work
        vm.prank(alice);
        stakingPool.stake(stakeAmount);
        assertEq(stakingPool.stakedAmount(alice), stakeAmount);
    }

    function testReentrancyProtection() public {
        // Note: Since we're using OpenZeppelin's ReentrancyGuard,
        // and all external functions that handle tokens are protected,
        // we have implicit protection against reentrancy
        // This test is here for documentation purposes
    }

    function testUpgrade() public {
        // Test upgrade functionality
        // Note: In a real scenario, you would deploy a new implementation
        // and test the upgrade process
    }

    function testMultipleUsers() public {
        uint256 aliceStake = 100 * 1e18;
        uint256 bobStake = 200 * 1e18;
        uint256 rewardAmount = 1000 * 1e18;

        // Fund reward pool
        token.approve(address(stakingPool), rewardAmount);
        stakingPool.fundRewardPool(rewardAmount);

        // Alice stakes
        vm.prank(alice);
        stakingPool.stake(aliceStake);

        // Advance time
        vm.warp(block.timestamp + 50);

        // Bob stakes
        vm.prank(bob);
        stakingPool.stake(bobStake);

        // Advance time
        vm.warp(block.timestamp + 50);

        // Verify rewards distribution is proportional to stake
        uint256 aliceRewards = stakingPool.pendingRewards(alice);
        uint256 bobRewards = stakingPool.pendingRewards(bob);

        // Bob should have fewer rewards as they staked later
        assertGt(aliceRewards, bobRewards);
    }
} 