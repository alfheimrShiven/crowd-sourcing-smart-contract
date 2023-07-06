// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testCheckMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender); // the FundMeTest contract is deploying the FundMe.sol contract as it's a script
    }

    function testPriceFeedVersionIsAccurate() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();

        // will pass if next line fails since we've declared `expectRevert()`
        fundMe.fund();
    }

    function testFundUpdatesAddressToAmtMapping() public funded {
        uint256 amtFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amtFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        assertEq(fundMe.getFunder(0), USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawAfterASingleFunder() public funded {
        // Step 1: Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            (startingOwnerBalance + startingFundMeBalance),
            endingOwnerBalance
        );
    }

    function testWithdrawAfterMultipleFunders() public {
        // Step 1: Arrange
        uint160 firstFunderIndex = 1; // address(1) is stable as compared to address(0)
        uint160 lastFunderIndex = 10;

        for (uint160 i = firstFunderIndex; i < lastFunderIndex; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); // gas charged

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance; // this would be lesser as gas would be charge on withdraw
        assertEq(endingFundMeBalance, 0);
        assertEq(
            (startingOwnerBalance + startingFundMeBalance),
            endingOwnerBalance
        );
    }

    function testWithdrawAfterMultipleFundersCheaper() public {
        // Step 1: Arrange
        uint160 firstFunderIndex = 1; // address(1) is stable as compared to address(0)
        uint160 lastFunderIndex = 10;

        for (uint160 i = firstFunderIndex; i < lastFunderIndex; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw(); // gas charged

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance; // this would be lesser as gas would be charge on withdraw
        assertEq(endingFundMeBalance, 0);
        assertEq(
            (startingOwnerBalance + startingFundMeBalance),
            endingOwnerBalance
        );
    }
}
