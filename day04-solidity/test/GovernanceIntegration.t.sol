// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PoolToken.sol";
import "../src/VaultGovernor.sol";
import "../src/Vault.sol";

contract GovernanceIntegrationTest is Test {
    PoolToken token;
    VaultGovernor governor;
    Vault vault;

    address admin = makeAddr("admin");
    address user = makeAddr("user");
    address voter1 = makeAddr("voter1");
    address voter2 = makeAddr("voter2");

    function setUp() public {
        vm.startPrank(admin);

        token = new PoolToken(1_000_000 ether);
        vault = new Vault(address(token));
        governor = new VaultGovernor(token, 1, 50, 4);

        vault.setGovernor(address(governor));

        token.transfer(user, 100_000 ether);
        token.transfer(voter1, 100_000 ether);
        token.transfer(voter2, 20_000 ether);

        vm.stopPrank();

        vm.prank(user);
        token.delegate(user);

        vm.prank(voter1);
        token.delegate(voter1);

        vm.prank(voter2);
        token.delegate(voter2);

        vm.roll(block.number + 1);
    }

    function testFullGovernanceWorkflow() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(vault);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Vault.setWithdrawalFee.selector, 500);
        string memory description = "test";

        vm.prank(user);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + 1 + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + 50 + 1);

        bytes32 descriptionHash = keccak256(bytes(description));
        governor.execute(targets, values, calldatas, descriptionHash);

        assertEq(vault.withdrawalFeeBps(), 500);
    }

    function testCannotVoteTwice() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(vault);
        calldatas[0] = abi.encodeWithSelector(Vault.setWithdrawalFee.selector, 100);

        vm.prank(user);
        uint256 proposalId = governor.propose(targets, values, calldatas, "p");

        vm.roll(block.number + 1 + 1);

        vm.startPrank(voter1);
        governor.castVote(proposalId, 1);

        vm.expectRevert();
        governor.castVote(proposalId, 1);
        vm.stopPrank();
    }

    function testProposalFailsWithoutQuorum() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(vault);
        calldatas[0] = abi.encodeWithSelector(Vault.setWithdrawalFee.selector, 100);

        vm.prank(user);
        uint256 proposalId = governor.propose(targets, values, calldatas, "p");

        vm.roll(block.number + 1 + 1);

        vm.prank(voter2);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + 50 + 1);

        uint8 status = uint8(governor.state(proposalId));
        assertEq(status, 3);
    }
}
