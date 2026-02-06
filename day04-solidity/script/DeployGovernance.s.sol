// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/PoolToken.sol";
import "../src/Vault.sol";
import "../src/VaultGovernor.sol";

contract DeployGovernance is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        PoolToken token = new PoolToken(1_000_000 ether);
        Vault vault = new Vault(address(token));
        VaultGovernor governor = new VaultGovernor(IVotes(address (token)), 1, 50, 4);
        console.log("Governor deployed at:", address(governor));
        vault.setGovernor(address(governor));
        token.delegate(deployer);
        vm.stopBroadcast();
    }
}