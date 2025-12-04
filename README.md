# KIPU-BANK

## Description
This smart contract implements a personal bank where each user can perform deposit and withdrawal operations, as well as check their balance and other information.

The bank features a maximum capacity and a per-transaction withdrawal limit.

## Deployment
To deploy this contract, simply pass the bank's capacity and per-transaction withdrawal limit as constructor arguments.

## Interacting with the Contract
Interaction with the contract can be done through the following functions:

### function deposit() external payable validDepositValue inBankCap {...}
    This function receives the value to be deposited, checks if the value is not zero, and ensures it does not exceed the maximum capacity. If these conditions are met, the value is deposited.

### function withdraw(uint256 _amount) external hasBalance(_amount) validWithdrawAmount(_amount) inWithdrawLimit(_amount) {...}
    This function receives the amount to be withdrawn as a parameter. It checks if the user has sufficient balance to make the withdrawal, if the withdrawal respects the established limit, and if the withdrawal amount is different from zero.

### function getQttDeposits() public view returns (uint256) {...}
    This function returns the number of deposits the msg.sender has made.

### function getQttWithdrawals() public view returns (uint256) {...}
    This function returns the number of withdrawals the msg.sender has made.

### function getBalance() public view returns (uint256) {...}
    This function returns the msg.sender's balance.

### function getBankCap() public view returns (uint256) {...}
    This function returns the bank's totoal capacity.