// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/DateTime.sol";

contract RideHail is DateTime{

    struct userDetail{
        bytes user_driver;
        address userName;
        uint YearJoined;
    }

    mapping (address => userDetail) private userDetails;

    modifier onlyUser() {
        require(tx.origin == msg.sender, "Contracts can't order rides, where are they going?");
        _;
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
        if(userDetails[msg.sender].user_driver == bytes(string("User")) && _user_driver == true){return;}
        if(userDetails[msg.sender].user_driver == bytes(string("Driver")) && _user_driver == false){return;}
        if(userDetails[msg.sender].user_driver == bytes(string("User")) && _user_driver == false){
            userDetails[msg.sender].user_driver = bytes(string("Driver"));
        }
        if(userDetails[msg.sender].user_driver == bytes(string("Driver")) && _user_driver == true){
            userDetails[msg.sender].user_driver = bytes(string("User"));
        }
    }

    function deleteAccount() external onlyUser {
        require(userDetails[msg.sender].userName != address(0), "Caller doesn't own an account");
        userDetails[msg.sender].user_driver = bytes(0);
        userDetails[msg.sender].userName = address(0);
        userDetails[msg.sender].YearJoined = 0;
    }

    function checkAccountDetails(address _address) public view returns(string calldata _user_driver, uint yearJoined) {
        require(userDetails[msg.sender].userName != address(0), "Caller doesn't own an account");
        _user_driver = userDetails[msg.sender].user_driver == bytes(string("User")) ? "User" : "Driver";
        yearJoined = userDetails[msg.sender].YearJoined;
    }

}