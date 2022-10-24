// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./PrivateERC20.sol";

contract NoteBasedWrappedERC20 is PrivateERC20 {
    using SafeERC20 for ERC20;
    
    ERC20 public immutable derivedFrom;
    uint256[] public notesFractions;

    event Deposited(address indexed from, uint256 fractionId);
    event Withdrawn(address indexed to, uint256 fractionId);
    event DustWithdrawn(address indexed to, uint256 amount);

    constructor(ERC20 _derivedFrom, uint256[] memory _fractions, uint8 _decimals, address _multicall) PrivateERC20(
        string(abi.encodePacked("Private ", _derivedFrom.name())),
        string(abi.encodePacked("p", _derivedFrom.symbol())),
        _decimals,
        _multicall
    ) {
        uint256 _prevFrac = 0;
        for (uint i = 0; i < _fractions.length; i++) {
            require(_fractions[i] > _prevFrac, "broken fraction order");
            _prevFrac = _fractions[i];
        }

        derivedFrom = _derivedFrom;
        notesFractions = _fractions;
    }

    function deposit(uint256 fractionId) public {
        uint256 amount = notesFractions[fractionId];
        derivedFrom.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        emit Deposited(msg.sender, fractionId);
    }

    function withdraw(uint256 fractionId) public {
        uint256 amount = notesFractions[fractionId];
        _burn(msg.sender, amount);
        derivedFrom.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, fractionId);
    }

    function withdrawDust() public {
        uint256 balance = balanceOf(msg.sender);
        require(balance < notesFractions[0], "your balance is not that low to withdraw dust");

        _burn(msg.sender, balance);
        derivedFrom.safeTransfer(msg.sender, balance);

        emit DustWithdrawn(msg.sender, balance);
    }
}