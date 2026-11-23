// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VulnerableVault
 * @notice Contrato do protocolo DeFiVault com vulnerabilidade crítica de Reentrância.
 * @dev O saldo interno só é atualizado APÓS a transferência externa de ETH.
 */
contract VulnerableVault {
    mapping(address => uint256) public balances;

    // Permite o depósito de Ether no cofre
    function deposit() external payable {
        require(msg.value > 0, "O valor do deposito deve ser maior que zero");
        balances[msg.sender] += msg.value;
    }

    // FALHA CRÍTICA DE SEGURANÇA:
    // A chamada externa transfere o controle de execução para o remetente ANTES de zerar o saldo interno!
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Saldo insuficiente");

        // 1. Interaction: Chamada externa que passa a execução para o contrato do remetente
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Falha na transferencia de Ether");

        // 2. Effect: Atualização do estado interno (Executada tarde demais no loop recursivo!)
        balances[msg.sender] = 0;
    }

    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
