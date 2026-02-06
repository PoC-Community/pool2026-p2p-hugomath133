// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VaultGovernor.sol";
import "../src/PoolToken.sol";

contract VaultGovernorTest is Test {
    VaultGovernor governor;
    PoolToken token;
    address user = makeAddr("user");

    function setUp() public {
        token = new PoolToken(1_000_000 ether);
        governor = new VaultGovernor(token, 1, 50, 4);
    }

    function testGovernorParameters() public {
        assertEq(governor.votingDelay(), 1);
        assertEq(governor.votingPeriod(), 50);
        assertEq(governor.name(), "VaultGovernor");
    }

    function testQuorumCalculation() public {
        vm.roll(block.number + 1);
        uint256 expectedQuorum = 40_000 ether;
        assertEq(governor.quorum(block.number - 1), expectedQuorum);
    }
}