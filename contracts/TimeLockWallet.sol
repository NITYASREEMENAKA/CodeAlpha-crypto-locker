// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title TimeLockWallet
/// @notice Personal portfolio contract that lets users deposit ETH or ERC20
///         tokens along with a lock-in period. Funds cannot be withdrawn
///         before the unlock time set at deposit.
contract TimeLockWallet is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @dev address(0) is used as the special key representing native ETH
    address public constant ETH_TOKEN = address(0);

    struct Deposit {
        uint256 amount;     // amount currently locked
        uint256 unlockTime; // timestamp after which withdrawal is allowed
    }

    // user => token address (ETH_TOKEN for ether) => deposit info
    mapping(address => mapping(address => Deposit)) public deposits;

    event Deposited(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 unlockTime
    );

    event Withdrawn(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    error AmountZero();
    error LockTimeInPast();
    error ActiveLockExists(uint256 currentUnlockTime);
    error StillLocked(uint256 unlockTime, uint256 nowTime);
    error NothingToWithdraw();

    /// @notice Deposit ETH with a lock-in duration.
    /// @param lockDurationSeconds how many seconds from now the funds stay locked
    function depositETH(uint256 lockDurationSeconds) external payable {
        if (msg.value == 0) revert AmountZero();
        if (lockDurationSeconds == 0) revert LockTimeInPast();

        Deposit storage d = deposits[msg.sender][ETH_TOKEN];

        // Prevent overwriting an existing active lock with a shorter one.
        // If user wants to top-up, they must wait till previous lock expires,
        // OR you can change this logic to "extend" - see notes below.
        if (d.amount > 0 && d.unlockTime > block.timestamp) {
            revert ActiveLockExists(d.unlockTime);
        }

        uint256 newUnlockTime = block.timestamp + lockDurationSeconds;

        d.amount = d.amount + msg.value; // add to any leftover (already-unlocked) balance
        d.unlockTime = newUnlockTime;

        emit Deposited(msg.sender, ETH_TOKEN, msg.value, newUnlockTime);
    }

    /// @notice Deposit ERC20 tokens with a lock-in duration.
    /// @param token the ERC20 token contract address
    /// @param amount amount of tokens to deposit (in token's smallest unit)
    /// @param lockDurationSeconds how many seconds from now the funds stay locked
    function depositToken(
        address token,
        uint256 amount,
        uint256 lockDurationSeconds
    ) external {
        if (token == ETH_TOKEN) revert("Use depositETH for ether");
        if (amount == 0) revert AmountZero();
        if (lockDurationSeconds == 0) revert LockTimeInPast();

        Deposit storage d = deposits[msg.sender][token];

        if (d.amount > 0 && d.unlockTime > block.timestamp) {
            revert ActiveLockExists(d.unlockTime);
        }

        uint256 newUnlockTime = block.timestamp + lockDurationSeconds;

        // Pull tokens from user into this contract (user must approve() first)
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        d.amount = d.amount + amount;
        d.unlockTime = newUnlockTime;

        emit Deposited(msg.sender, token, amount, newUnlockTime);
    }

    /// @notice Withdraw previously deposited ETH, only after unlock time.
    function withdrawETH() external nonReentrant {
        Deposit storage d = deposits[msg.sender][ETH_TOKEN];

        if (d.amount == 0) revert NothingToWithdraw();
        if (block.timestamp < d.unlockTime) {
            revert StillLocked(d.unlockTime, block.timestamp);
        }

        uint256 amount = d.amount;
        d.amount = 0; // effects before interactions (reentrancy safety)

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit Withdrawn(msg.sender, ETH_TOKEN, amount);
    }

    /// @notice Withdraw previously deposited ERC20 tokens, only after unlock time.
    /// @param token the ERC20 token contract address
    function withdrawToken(address token) external nonReentrant {
        require(token != ETH_TOKEN, "Use withdrawETH for ether");

        Deposit storage d = deposits[msg.sender][token];

        if (d.amount == 0) revert NothingToWithdraw();
        if (block.timestamp < d.unlockTime) {
            revert StillLocked(d.unlockTime, block.timestamp);
        }

        uint256 amount = d.amount;
        d.amount = 0;

        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, token, amount);
    }

    /// @notice View helper: how many seconds remain until withdrawal is allowed.
    /// @return secondsRemaining 0 if already unlocked (or nothing deposited)
    function timeUntilUnlock(address user, address token)
        external
        view
        returns (uint256 secondsRemaining)
    {
        uint256 unlockTime = deposits[user][token].unlockTime;
        if (block.timestamp >= unlockTime) return 0;
        return unlockTime - block.timestamp;
    }

    /// @notice View helper: get a user's deposit details for a given token.
    function getDeposit(address user, address token)
        external
        view
        returns (uint256 amount, uint256 unlockTime, bool isUnlocked)
    {
        Deposit memory d = deposits[user][token];
        return (d.amount, d.unlockTime, block.timestamp >= d.unlockTime);
    }

    /// @notice Allows the contract to receive plain ETH transfers, but
    ///         these will NOT be tracked in the lock mapping. Discouraged —
    ///         always use depositETH().
    receive() external payable {
        revert("Use depositETH() to deposit");
    }
}
