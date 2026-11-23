// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        if (_status == _ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract SecuredVault is ReentrancyGuard {
    mapping(address => uint256) public balances;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "O valor do deposito deve ser maior que zero");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external nonReentrant {
        // 1. CHECKS: Validacao de pre-condicoes
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Saldo insuficiente");

        // 2. EFFECTS: Atualizacao atomica do estado interno antes de qualquer chamada externa
        balances[msg.sender] = 0;
        emit Withdrawn(msg.sender, amount);

        // 3. INTERACTIONS: Transferencia externa isolada
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Falha na transferencia de Ether");
    }

    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
