// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyToken
 * @dev Custom ERC20 token with pause, tax rates, staking, minting, and transfers.
 */
contract MyToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    uint256 private _initialSupply;
    uint256 private _maxSupply;
    uint256 public taxRate;
    mapping(address => uint256) private _stakingBalances;
    mapping(address => uint256) private _stakingTimestamps;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    /**
     * @dev Constructor for initializing the token contract.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param initialSupply Initial supply of the token.
     * @param maxSupply Maximum supply limit of the token.
     * @param _taxRate Tax rate applied to transfers.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 maxSupply,
        uint256 _taxRate
    ) ERC20(name, symbol) {
        _initialSupply = initialSupply * (10**decimals());
        _maxSupply = maxSupply * (10**decimals());
        taxRate = _taxRate;
        _mint(msg.sender, _initialSupply);
    }

    /**
     * @dev Set the tax rate for token transfers.
     * @param newTaxRate The new tax rate.
     */
    function setTaxRate(uint256 newTaxRate) public onlyOwner {
        taxRate = newTaxRate;
    }

    /**
     * @dev Pause the token contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the token contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Mint new tokens to a specific address.
     * @param to The address to receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= _maxSupply, "MyToken: Max supply exceeded");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Pausable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Transfer tokens to a recipient, applying the tax rate.
     * @param recipient The address to receive the transferred tokens.
     * @param amount The amount of tokens to transfer.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = (amount * taxRate) / 100;
        uint256 amountAfterTax = amount - taxAmount;
                super.transfer(recipient, amountAfterTax);
        super.transfer(owner(), taxAmount);
        return true;
    }

    /**
     * @dev Transfer tokens from a sender to a recipient, applying the tax rate.
     * @param sender The address to transfer tokens from.
     * @param recipient The address to receive the transferred tokens.
     * @param amount The amount of tokens to transfer.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = (amount * taxRate) / 100;
        uint256 amountAfterTax = amount - taxAmount;
        super.transferFrom(sender, recipient, amountAfterTax);
        super.transferFrom(sender, owner(), taxAmount);
        return true;
    }

    /**
     * @dev Stake tokens for the calling address.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) public {
        _stakingBalances[msg.sender] += amount;
        _stakingTimestamps[msg.sender] = block.timestamp;
        _burn(msg.sender, amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Unstake tokens for the calling address.
     * @param amount The amount of tokens to unstake.
     */
    function unstake(uint256 amount) public {
        require(_stakingBalances[msg.sender] >= amount, "MyToken: Not enough staked tokens");
        uint256 stakingDuration = block.timestamp - _stakingTimestamps[msg.sender];
        require(stakingDuration >= 7 days, "MyToken: Staking duration should be at least 7 days");
        _stakingBalances[msg.sender] -= amount;
        _mint(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev Get the staking balance of an address.
     * @param account The address to check the staking balance for.
     * @return The staking balance of the given address.
     */
    function stakingBalance(address account) public view returns (uint256) {
        return _stakingBalances[account];
    }

    /**
     * @dev Get the staking timestamp of an address.
     * @param account The address to check the staking timestamp for.
     * @return The staking timestamp of the given address.
     */
    function stakingTimestamp(address account) public view returns (uint256) {
        return _stakingTimestamps[account];
    }
}

