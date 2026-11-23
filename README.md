
# Auditoria e Engenharia de Software: Vulnerabilidade de Reentrância em Smart Contracts

Objetivo: Desenvolver competências de desenvolvimento seguro e verificação formal de código executável imutável.
Descrição da Atividade: O aluno receberá um trecho de contrato inteligente em Solidity contendo o anti-padrão de vulnerabilidade por reentrância (onde a transferência de fundos ocorre antes da atualização do saldo interno).
Identificar a falha de ordenação na máquina de estado (EVM).
Reescrever o contrato inteligente aplicando rigorosamente o padrão arquitetural Checks-Effects-Interactions.
Desenvolver um contrato atacante simulando chamadas recursivas no método de contingência (fallback).


## Contexto do Projeto

A DeFiVault Inc. é uma startup de finanças descentralizadas (DeFi) que lançou recentemente um protocolo de custódia e rendimento automatizado na rede Ethereum. O produto principal é o cofre VulnerableVault, onde usuários e investidores institucionais podem depositar Ether (ETH) para acumular rendimentos e sacar seus fundos a qualquer momento.

Nas primeiras 48 horas de operação, o cofre acumulou um total de 500 ETH de liquidez de diversos investidores

O Incidente de Segurança

Às 03:14 AM, o sistema de monitoramento on-chain disparou um alerta crítico: o saldo total do contrato VulnerableVault caiu bruscamente de 500 ETH para 0 ETH em uma única bloco, através de uma única transação disparada por um endereço não identificado.

Curiosamente, a análise inicial dos logs revelou que:

O atacante depositou apenas 1 ETH no cofre.
Em seguida, chamou a função de saque (withdraw()).
O contrato do atacante executou chamadas recursivas antes que o seu saldo interno fosse atualizado no estado da EVM (Ethereum Virtual Machine).
O atacante conseguiu drenar todo o saldo de terceiros acumulado no cofre e transferiu os fundos para sua própria carteira.
 

Contrato Vulnerável (VulnerableVault.sol)
```solidity

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
```

