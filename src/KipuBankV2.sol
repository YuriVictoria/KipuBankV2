// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; 
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {AggregatorV3Interface} from "chainlink-evm/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title KipuBankV2
/// @author @YuriVictoria
contract KipuBankV2 is AccessControl {

    mapping(address => address) public tokenToOracle;
    /// @notice Map user(address) to balance(uint256)
    mapping(address => mapping(address => uint256)) private balances;               
    /// @notice Map user(address) to qttDeposits(uint256)
    mapping(address => uint256) private qttDeposits;            
    /// @notice Map user(address) to qttWithdrawals(uint256)
    mapping(address => uint256) private qttWithdrawals;         
    
    IERC20 public paymentToken;

    /// @notice Limit to withdraw operation.
    uint256 public withdrawLimit;
    /// @notice Limit to bankCap (contract.balance <= bankCap)
    uint256 public bankCap;

    AggregatorV3Interface internal priceFeed;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @notice The Withdraw event 
    /// @param user who make the withdrawal
    /// @param value the withdrawal value
    event WithdrewETH(address indexed user, uint256 value); 
    
    /// @notice The Deposit event 
    /// @param user who make the deposit
    /// @param value the deposit value
    event DepositedETH(address indexed user, uint256 value);

    /// @notice Set new withdrawLimit 
    /// @param value of new withdrawLimit
    event ChangeWithdrawLimit(uint256 value);

    /// @notice Set new bankCap
    /// @param value of new bankCap
    event ChangeBankCap(uint256 value);

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

    // Alteração, não precisa somar
    /// @notice Revert if contract.balance pass the bankCap
    modifier inBankCap() {                                      
        if (address(this).balance > bankCap) revert BankCap();
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
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        withdrawLimit = _withdrawLimit;
        bankCap = _bankCap;
    }

    /// @notice Verify conditions and make the deposit of msg.value
    function depositETH() external payable validDepositValue inBankCap {
        balances[address(0)][msg.sender] += msg.value;
        qttDeposits[msg.sender] += 1;
        emit DepositedETH(msg.sender, msg.value);
    }

    /// @notice Verify conditions and make the withdraw of amount
    /// @param _amount value of withdraw
    function withdrawETH(uint256 _amount) external hasBalance(_token, _amount) validWithdrawAmount(_token, _amount) inWithdrawLimit(_token, _amount) {
        balances[address(0)][msg.sender] -= _amount;
        qttWithdrawals[msg.sender] += 1;
        
        emit WithdrewETH(msg.sender, _amount);
        
        makePayETH(msg.sender, _amount);
    }

    /// @notice Make the payment
    /// @param _to who receive the payment
    /// @param _amount value of payment
    function makePayETH(address _to, uint256 _amount) private {
        (bool ok,) = payable(_to).call{value: _amount}("");
        if (!ok) revert FailWithdraw();
    }

    /// @notice Get qttDeposits of msg.sender
    function getQttDeposits() external view returns (uint256) {
        return qttDeposits[msg.sender];
    }

    /// @notice Get qttWithdrawals of msg.sender
    function getQttWithdrawals() external view returns (uint256) {
        return qttWithdrawals[msg.sender];
    }

    /// @notice Get balance of msg.sender
    function getBalanceETH() external view returns (uint256) {
        return balances[address(0)][msg.sender];
    }

    /// @notice Set bankCap
    function setBankCap(uint256 _newBankCap) external onlyRole(MANAGER_ROLE) {
        bankCap = _newBankCap;
        emit ChangeBankCap(bankCap);
    }

    /// @notice Set withdrawLimit
    function setWithdrawLimit(uint256 _newWithdrawLimit) external onlyRole(MANAGER_ROLE) {
        withdrawLimit = _newWithdrawLimit;
        emit ChangeWithdrawLimit(withdrawLimit);
    }

    /// @notice Get bankCap
    function getBankCap() external view returns (uint256) {
        return bankCap;
    }

    /// @notice Get withdrawLimit
    function getWithdrawLimit() external view returns (uint256) {
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
