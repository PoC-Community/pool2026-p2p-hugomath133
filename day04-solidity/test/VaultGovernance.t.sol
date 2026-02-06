// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/PoolToken.sol";

contract VaultGovernanceTest is Test {
    Vault vault;
    PoolToken token;
    address owner = address(this);
    address governor = makeAddr("governor");
    address user = makeAddr("user");

    function setUp() public {
        token = new PoolToken(1_000_000 ether);
        vault = new Vault(address(token));
        vault.setGovernor(governor);
        token.transfer(user, 1000 ether);
    }

    function testSetWithdrawalFee() public {
        vm.prank(governor);
        vault.setWithdrawalFee(500);
        assertEq(vault.withdrawalFeeBps(), 500);
    }

    function testNonGovernorCannotSetFee() public {
        vm.prank(user);
        vm.expectRevert(Vault.OnlyGovernor.selector);
        vault.setWithdrawalFee(500);
    }

    function testFeeCannotExceedMax() public {
        vm.prank(governor);
        vm.expectRevert(Vault.FeeTooHigh.selector);
        vault.setWithdrawalFee(1001);
    }

    function testWithdrawalWithFee() public {
        vm.prank(governor);
        vault.setWithdrawalFee(1000);

        vm.startPrank(user);
        token.approve(address(vault), 1000 ether);
        vault.deposit(1000 ether);

        vault.withdraw(1000 ether);
        vm.stopPrank();

        assertEq(token.balanceOf(user), 900 ether);
        assertEq(token.balanceOf(address(vault)), 100 ether);
    }
}