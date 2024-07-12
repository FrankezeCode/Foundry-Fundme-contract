// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console } from "forge-std/Test.sol";
import {FundMe} from "src/FundMe.sol";
import {DeployFundMe} from  "script/DeployFundMe.s.sol";


contract FundMeTest is Test{

    FundMe fundme;

    address  USER = makeAddr('user');
    uint256 constant SEND_VALUE = 0.1 ether ;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value : SEND_VALUE}();
        _;
    }

    function testMINIMUM_USD() external view {  
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() external view {
        assertEq(fundme.getOwnwer() , msg.sender);
    }

    function testPriceFeedVersion() external view {
        assertEq(fundme.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETH() external  {
         vm.expectRevert();
         fundme.fund{value : 0}();
    }

    function testFundUpdatesFundedDataStructure() external{
        vm.prank(USER);//The next Tx will be sent by User
        fundme.fund{value : SEND_VALUE}();
        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderstoArrayOfFunders() external{
        vm.prank(USER);
        fundme.fund{value : SEND_VALUE}();
        uint256 index;
        address funder = fundme.getFunder(index);
        assertEq(USER, funder);
    }

    function testOnlyOwnerCanWithdraw() external funded {
        vm.expectRevert();
        fundme.withdraw();
    }

    function testWithdrawWithASingleFunder() external funded {
        //Arrange
        uint startingOwnerBalance = fundme.getOwnwer().balance;
        uint startingFundmeBalance = address(fundme).balance;

        //Act 
        vm.prank(fundme.getOwnwer());
        fundme.withdraw();

        //Asert
        uint endingOwnerBalance = fundme.getOwnwer().balance;
        uint endingFundmeBalance = address(fundme).balance;
        assertEq(endingFundmeBalance, 0);
        assertEq(startingOwnerBalance+ startingFundmeBalance, endingOwnerBalance);      
    }

    function testWithdrawWithMultipleFunders() external funded {
        //Arrange
        uint160 numberOfFunders =10;
        uint160 startFunderIndex = 1;
        for(uint160 i = startFunderIndex; i<numberOfFunders; i++){
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE);
            fundme.fund{value : SEND_VALUE}();
        }
        
        uint startingOwnerBalance = fundme.getOwnwer().balance;
        uint startingFundmeBalance = address(fundme).balance;

        //Act
        vm.startPrank(fundme.getOwnwer());
        fundme.withdraw();
        vm.startPrank(fundme.getOwnwer());

        //Assert
        assert(address(fundme).balance == 0);
        assert(startingOwnerBalance+ startingFundmeBalance == fundme.getOwnwer().balance);        



    }



}