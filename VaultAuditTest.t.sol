// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VulnerableVault.sol";
import "../src/SecuredVault.sol";
import "../src/ReentrancyAttacker.sol";

contract VaultAuditTest is Test {
    VulnerableVault public vulnerableVault;
    SecuredVault public securedVault;
    ReentrancyAttacker public attacker;

    address public victim = address(0xAA);
    address public attackerEOA = address(0xBB);

    function setUp() public {
        vulnerableVault = new VulnerableVault();
        securedVault = new SecuredVault();

        // 1. Simula a liquidez inicial depositada no cofre (500 ETH)
        vm.deal(victim, 500 ether);
        vm.prank(victim);
        vulnerableVault.deposit{value: 500 ether}();

        vm.prank(victim);
        securedVault.deposit{value: 500 ether}();

        // 2. Provedor de 1 ETH para o invasor
        vm.deal(attackerEOA, 1 ether);
    }

    function test_exploit_VulnerableVault() public {
        vm.startPrank(attackerEOA);
        attacker = new ReentrancyAttacker(address(vulnerableVault));
        // Executa o ataque recursivo drenando o cofre vulneravel
        attacker.attack{value: 1 ether}();
        vm.stopPrank();

        assertEq(vulnerableVault.getVaultBalance(), 0 ether);
        assertEq(address(attacker).balance, 501 ether);
    }

    function test_revert_SecuredVault_OnAttack() public {
        vm.startPrank(attackerEOA);
        attacker = new ReentrancyAttacker(address(securedVault));
        // O ataque deve falhar e reverter atraves do CEI e ReentrancyGuard
        vm.expectRevert();
        attacker.attack{value: 1 ether}();
        vm.stopPrank();

        // Garante que todo o montante de 500 ETH permanece seguro no cofre
        assertEq(securedVault.getVaultBalance(), 500 ether);
        assertEq(address(attacker).balance, 0 ether);
    }
}
