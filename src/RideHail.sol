// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/libraries/DateTime.sol";
import "src/libraries/AggregatorV3Interface.sol";
import "src/libraries/IERC20.sol";

contract RideHail is DateTime{

    AggregatorV3Interface internal pricefeed;
    address internal USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private operator;
    address public owner;

    struct userDetail{
        bytes user_driver;
        address userName;
        uint YearJoined;
    }

    struct TripDetails{
        address driver;
        address rider;
        uint tripDistance;
        uint pay;
    }

    uint public FEE = 100;
    uint private BASE = 1000;

    mapping (uint => TripDetails) transactionRecord;
    uint transaction_counter = 1;

    mapping (address => userDetail) private userDetails;

    modifier onlyUser() {
        require(tx.origin == msg.sender, "Contracts can't order rides, where are they going?");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator || msg.sender == owner, "!Operator");
        _;
    }

    constructor() {
        pricefeed = AggregatorV3Interface(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7); //USDC/USD
        operator = msg.sender;
        owner = msg.sender;
    }

    function registerUser(bool _user_driver) external onlyUser{
        if(_user_driver == true && userDetails[msg.sender].userName != msg.sender){
            userDetails[msg.sender].user_driver = bytes(string("User"));
            userDetails[msg.sender].userName = msg.sender;
            userDetails[msg.sender].YearJoined = getYear(block.timestamp);
        }
        
        if(_user_driver == false && userDetails[msg.sender].userName != msg.sender){
            userDetails[msg.sender].user_driver = bytes(string("Driver"));
            userDetails[msg.sender].userName = msg.sender;
            userDetails[msg.sender].YearJoined = getYear(block.timestamp);
        }
    }

    function updateAccount(bool _user_driver) external onlyUser{
        require(userDetails[msg.sender].userName != address(0), "Caller doesn't own an account");
        if(_user_driver == true && abi.decode(userDetails[msg.sender].user_driver, (bool)) == true){return;}
        if(_user_driver == false && abi.decode(userDetails[msg.sender].user_driver, (bool)) == false){return;}
        if(_user_driver == false && abi.decode(userDetails[msg.sender].user_driver, (bool)) == true){
            userDetails[msg.sender].user_driver = bytes(string("Driver"));
        }
        if(_user_driver == true && abi.decode(userDetails[msg.sender].user_driver, (bool)) == false){
            userDetails[msg.sender].user_driver = bytes(string("User"));
        }
    }

    function deleteAccount() external onlyUser {
        require(userDetails[msg.sender].userName != address(0), "Caller doesn't own an account");
        userDetails[msg.sender].user_driver = bytes("");
        userDetails[msg.sender].userName = address(0);
        userDetails[msg.sender].YearJoined = 0;
    }

    function recordTripDetails(address driver, address rider, uint distance, uint pay) external onlyOperator{
        require(pay > 0 && distance > 0, "Pay is Zero || Distance is Zero");
        transactionRecord[transaction_counter].driver = driver;
        transactionRecord[transaction_counter].rider  = rider;
        transactionRecord[transaction_counter].tripDistance = distance;
        transactionRecord[transaction_counter].pay = pay * uint(_getPrice());
        _makePaymentToDriver(driver, rider, pay * uint(_getPrice()));
        transaction_counter++;
    }

    ///////////////////////////
    //////    VIEW       /////
    //////    FUNCTIONS  ////
    ////////////////////////

    function checkAccountDetails(address _address) public view returns(string memory _user_driver, uint yearJoined) {
        require(userDetails[_address].userName != address(0), "Caller doesn't own an account");
        _user_driver = abi.decode(userDetails[_address].user_driver, (bool)) == true ? "User" : "Driver";
        yearJoined = userDetails[_address].YearJoined;
    }

    function checkTransactionDetails(uint transactionID) public view returns (address, address, uint, uint) {
        return(
            transactionRecord[transactionID].driver,
            transactionRecord[transactionID].rider,
            transactionRecord[transactionID].tripDistance,
            transactionRecord[transactionID].pay
        );
    }

    ///////////////////////////
    //////    OPERATOR   /////
    //////    FUNCTION  ////
    ////////////////////////

    function setOperator(address newOperator) external onlyOperator{
        require(newOperator != address(0), "Zero Address");
        operator = newOperator;
    }

    ///////////////////////////
    //////    INTERNAL   /////
    //////    FUNCTIONS  ////
    ////////////////////////

    function _getPrice() internal view returns (int) {
        ( , int price, , , ) = pricefeed.latestRoundData();
        return price / 1e8; //price was originally scaled up by 1e8 so we had to divide
    }

    function _makePaymentToDriver(address driver, address rider, uint amount) internal {
        require(IERC20(USDC).balanceOf(rider) >= amount, "Insufficient Balance");
        uint fee = amount * FEE / BASE;
        uint amountLessFee = amount - fee;
        uint balanceBefore = IERC20(USDC).balanceOf(address(this));
        IERC20(USDC).transferFrom(rider,  address(this), amount);
        require(IERC20(USDC).balanceOf(address(this)) >= balanceBefore + amount, "Transfer Failed!");
        IERC20(USDC).transferFrom(address(this), driver, amountLessFee);
    }

}