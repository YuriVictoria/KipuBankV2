// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title KipuBank
/// @author @YuriVictoria
contract KipuBank {
    /// @notice Map user(address) to balance(uint256)
    mapping(address => uint256) private balances;               
    /// @notice Map user(address) to qttDeposits(uint256)
    mapping(address => uint256) private qttDeposits;            
    /// @notice Map user(address) to qttWithdrawals(uint256)
    mapping(address => uint256) private qttWithdrawals;         
    
    /// @notice Limit to withdraw operation.
    uint256 immutable withdrawLimit;
    /// @notice Limit to bankCap (contract.balance <= bankCap)
    uint256 immutable bankCap;

    /// @notice The Withdraw event 
    /// @param user who make the withdrawal
    /// @param value the withdrawal value
    event Withdrew(address indexed user, uint256 value); 
    
    /// @notice The Deposit event 
    /// @param user who make the deposit
    /// @param value the deposit value
    event Deposited(address indexed user, uint256 value); 

    // ------ Erros ------
    /// @notice Thrown when the withdrawal pass the withdrawLimit
    error WithdrawLimit();
    /// @notice Thrown when sender try withdrawal a null amount
    error NothingToWithdraw();
    /// @notice Thrown when the withdrawal's Amount is bigger than balance
    error NoBalance();
    /// @notice Thrown when the payment fail
    error FailWithdraw();
    /// @notice Thrown when the deposit.value + contract.balance pass the bankCap
    error BankCap();
    /// @notice Thrown when the sender try deposit a null value
    error NothingToDeposit();

    /// @notice Revert if withdraw pass the limit
    /// @param _amount value of withdrawal
    modifier inWithdrawLimit(uint256 _amount) {
        if (_amount > withdrawLimit) revert WithdrawLimit();
        _;
    }

    /// @notice Revert if try withdraw 0
    /// @param _amount value of withdrawal
    modifier validWithdrawAmount(uint256 _amount) {
        if (_amount == 0) revert NothingToWithdraw();
        _;
    }

    /// @notice Revert if insufficient balance
    /// @param _amount value of withdrawal
    modifier hasBalance(uint256 _amount) {                      
        if (_amount > balances[msg.sender]) revert NoBalance();
        _;
    }

    /// @notice Revert if deposit + contract.balance pass the bankCap
    modifier inBankCap() {                                      
        if (address(this).balance + msg.value > bankCap) revert BankCap();
        _;
    }

    /// @notice Revert if try deposit 0
    modifier validDepositValue() {                              
        if (msg.value == 0) revert NothingToDeposit();
        _;
    }

    /// @notice The deployer defines the withdrawnLimit and bankCap.
    /// @param _withdrawLimit Define the limit to withdraw
    /// @param _bankCap Define bank capacity
    constructor(uint256 _withdrawLimit, uint256 _bankCap) {
        withdrawLimit = _withdrawLimit;
        bankCap = _bankCap;
    }

    /// @notice Verify conditions and make the deposit of msg.value
    function deposit() external payable validDepositValue inBankCap {
        balances[msg.sender] += msg.value;
        qttDeposits[msg.sender] += 1;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Verify conditions and make the withdraw of amount
    /// @param _amount value of withdraw
    function withdraw(uint256 _amount) external hasBalance(_amount) validWithdrawAmount(_amount) inWithdrawLimit(_amount) {
        balances[msg.sender] -= _amount;
        
        makePay(msg.sender, _amount);

        qttWithdrawals[msg.sender] += 1;
        emit Withdrew(msg.sender, _amount);
    }

    /// @notice Make the payment
    /// @param _to who receive the payment
    /// @param _amount value of payment
    function makePay(address _to, uint256 _amount) private {
        (bool ok,) = payable(_to).call{value: _amount}("");
        if (!ok) revert FailWithdraw();
    }

    /// @notice Get qttDeposits of msg.sender
    function getQttDeposits() public view returns (uint256) {
        return qttDeposits[msg.sender];
    }

    /// @notice Get qttWithdrawals of msg.sender
    function getQttWithdrawals() public view returns (uint256) {
        return qttWithdrawals[msg.sender];
    }

    /// @notice Get balance of msg.sender
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    /// @notice Get bankCap
    function getBankCap() public view returns (uint256) {
        return bankCap;
    }

    /// @notice Get withdrawLimit
    function getWithdrawLimit() public view returns (uint256) {
        return withdrawLimit;
    }

    /// @notice Prevent receiving stray ETH outside the intended flow
    receive() external payable {
        revert("use deposit()");
    }

    /// @notice Prevent receiving stray ETH outside the intended flow
    fallback() external payable {
        revert("invalid call");
    }
}
