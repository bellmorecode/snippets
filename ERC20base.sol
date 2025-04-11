// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameToken is ERC20, Ownable {
    bool public isClaimPhase = true;
    uint256 public maxSupply = 1_000_000 ether;

    mapping(address => bool) public gameContracts;

    modifier onlyGame() {
        require(gameContracts[msg.sender], "Not authorized");
        _;
    }

    modifier claimPhaseOnly() {
        require(isClaimPhase || msg.sender == owner(), "Claim phase ended");
        _;
    }

    constructor() ERC20("GameToken", "GT") {
        _mint(msg.sender, 100_000 ether); // initial supply for devs or liquidity
    }

    function setGameContract(address gameContract, bool status) external onlyOwner {
        gameContracts[gameContract] = status;
    }

    function claim(address to, uint256 amount) external onlyGame {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _mint(to, amount);
    }

    function endClaimPhase() external onlyOwner {
        isClaimPhase = false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (isClaimPhase && from != address(0) && to != address(0)) {
            require(from == owner(), "Trading disabled during claim phase");
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}
