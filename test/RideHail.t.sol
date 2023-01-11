// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/RideHail.sol";
import "forge-std/Test.sol";

contract RideHailTest is Test {

    RideHail rideHailContract;
    address user;
    address driver;

    function setUp() public {
        rideHailContract = new RideHail();
        vm.label(address(rideHailContract), "Ride Hail Contract ");

        user = address(5);
        vm.label(user, "User Address");

        driver = address(10);
        vm.label(driver, "Driver Address");
    }

    function testRegisterUser () public {
        vm.startPrank(user, user);
        rideHailContract.registerUser(true);
        (bytes memory response, , ) = rideHailContract.userDetails(user) ;
        assertEq(response, bytes("User"));
        vm.stopPrank();

        vm.startPrank(driver, driver);
        rideHailContract.registerUser(false);
        (bytes memory reply, , ) = rideHailContract.userDetails(driver) ;
        assertEq(reply, bytes("Driver"));
        vm.stopPrank();
    }
    
}
