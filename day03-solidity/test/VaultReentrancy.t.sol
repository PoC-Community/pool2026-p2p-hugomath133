// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "./mocks/MaliciousToken.sol";

contract VaultReentrancyTest is Test {
    Vault public vault;
    MaliciousToken public token;
    address public attacker = address(1);

    function setUp() public {
        token = new MaliciousToken();
        vault = new Vault(address(token));
        token.setVault(address(vault));
        token.transfer(attacker, 100 ether);
    }

    function testReentrancyProtection() public {
        vm.startPrank(attacker);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether);

        token.enableAttack(true);

        vm.expectRevert();
        vault.withdraw(100 ether);

        vm.stopPrank();
    }
}