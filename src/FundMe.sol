// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "src/PriceConveter.sol";


error FundMe_notOwner();

contract FundMe {

    uint public constant MINIMUM_USD = 5e18;
    address[] private s_funders;
    mapping(address funder => uint amount) private  s_addressToAmountFunded;
    address private immutable i_owner;
    AggregatorV3Interface  s_priceFeed ;


    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface (priceFeed);
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe_notOwner();
        }
        _;
    }

    function fund() public payable {
        require(PriceConverter.getConversionRate(msg.value, s_priceFeed) >= MINIMUM_USD);
        s_funders.push(msg.sender);
         s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // for(starting index, ending index, step amount){ perform this operation }
        for (uint i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i]; //this is use to get each address of the funders
             s_addressToAmountFunded[funder] = 0; //this is use to reset the value of each address to zero
        }

        s_funders = new address[](0); // this is use to reset the array to zero

        //withdraw
        (bool callSucess, ) = payable(msg.sender).call{ value: address(this).balance}("");
        require(callSucess, "call failed");
    }


     function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }


    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * view / pure functions (GETTERS)
     */
    function getFunder(uint index) external view returns(address){
        return s_funders[index];
    }

    function getAddressToAmountFunded(address fundingAddress) external view returns(uint256){
        return s_addressToAmountFunded[fundingAddress];
    }

    function getOwnwer() external view returns(address){
        return i_owner;
    }

    
}
