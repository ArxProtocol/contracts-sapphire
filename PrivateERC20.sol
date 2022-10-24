// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../ERC2771Context.sol";

contract PrivateERC20 is IERC20, ERC2771Context {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _multicall) ERC2771Context(_multicall) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function _isAllowedByPrivacyPolicy(address owner) private view returns (bool) {
        return _msgSender() == owner || msg.sender == address(this);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return 0;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (!_isAllowedByPrivacyPolicy(account)) {
            return 0;
        }

        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        if (!_isAllowedByPrivacyPolicy(owner)) {
            return 0;
        }

        return _allowances[owner][spender];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        _balances[to] += amount;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
        _balances[to] += amount;
    }

    function _burn(address from, uint256 amount) internal {
        _balances[from] -= amount;
    }
}