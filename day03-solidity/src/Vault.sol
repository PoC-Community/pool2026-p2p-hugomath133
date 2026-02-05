// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract Vault is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public immutable asset;
    uint256 public totalShares;
    mapping(address => uint256) public sharesOf;

    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);
    event RewardAdded(uint256 amount);
    error ZeroAmount();
    error InsufficientShares();
    error ZeroShares();
    constructor(address _asset) Ownable(msg.sender) {
        asset = IERC20(_asset);
    }

    function _convertToShares(uint256 assets) internal view returns (uint256) {
        uint256 totalAssets = asset.balanceOf(address(this));
        if (totalShares == 0) {
            return assets;
        }
        return (assets * totalShares) / totalAssets;
    }

    function _convertToAssets(uint256 shares) internal view returns (uint256) {
        uint256 totalAssets = asset.balanceOf(address(this));
        if (totalShares == 0) {
            return 0;
        }
        return (shares * totalAssets) / totalShares;
    }
    function deposit(uint256 assets) external nonReentrant returns (uint256 shares) {
        if (assets == 0) {
            revert ZeroAmount();
        }
        shares = _convertToShares(assets);
        if (shares == 0) {
            revert ZeroShares();
        }

        sharesOf[msg.sender] += shares;
        totalShares += shares;
        asset.safeTransferFrom(msg.sender, address(this), assets);
        emit Deposit(msg.sender, assets, shares);
    }

    function withdraw(uint256 shares) public nonReentrant returns (uint256 assets) {
        if (shares == 0) {
            revert ZeroAmount();
        }
        if (sharesOf[msg.sender] < shares) {
            revert InsufficientShares();
        }
        assets = _convertToAssets(shares);
        sharesOf[msg.sender] -= shares;
        totalShares -= shares;
        asset.safeTransfer(msg.sender, assets);
        emit Withdraw(msg.sender, assets, shares);
    }

    function withdrawAll() public returns (uint256 assets) {
        return withdraw(sharesOf[msg.sender]);
    }

    function previewDeposit(uint256 assets) external view returns (uint256) {
        return _convertToShares(assets);
    }

    function previewWithdraw(uint256 shares) external view returns (uint256) {
        return _convertToAssets(shares);
    }

    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function assetsOf(address user) external view returns (uint256) {
        return _convertToAssets(sharesOf[user]);
    }

    function currentRatio() external view returns (uint256) {
        uint256 assets = totalAssets();
        if (totalShares == 0) {
            return 1e18;
        }
        return (assets * 1e18) / totalShares;
    }

    function addReward(uint256 amount) external nonReentrant onlyOwner {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (totalShares == 0) {
            revert ZeroShares();
        }
        asset.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(amount);
    }
}