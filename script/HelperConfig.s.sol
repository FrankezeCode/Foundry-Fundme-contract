// SPDX-License-Identifier: MIT

//This script is to Deploy Mock contract when we are on a local anvil chain

/* This script can also help to deploy and keep track of contract address accross different 
chains. Example Sepolia ETH/USD, MAINNET ETH/USD, BTC/USD, MATIC/USD, etc */

////It will make our test to run , regardless of the chain we are using.

pragma solidity ^0.8.26;

import {Script}  from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";


contract HelperConfig is Script{
    //if we are on a local anvil, we deploy mocks
    //otherwise , grab the exixting address on the live network

    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; //ETH/USD price feed address
        //we can also have other dataFeed 
    }

    constructor(){
      if(block.chainid == 11155111){
         activeNetworkConfig = getSepoliaEthConfig();
      }else if(block.chainid == 1){
        activeNetworkConfig = getMainnetEthConfig();
      }else {
         activeNetworkConfig =  getOrCreatAnvilETHConfig();
      }
    }
   
   function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
      //get any data you need from the chainlink sepolia dataFeed
      //lets get just Price Feed address

      NetworkConfig memory  sepoliaConfig = NetworkConfig({
        priceFeed : 0x694AA1769357215DE4FAC081bf1f309aDC325306
      });

      return  sepoliaConfig;
   }

   function getMainnetEthConfig() public pure returns(NetworkConfig memory) {
      NetworkConfig memory mainetConfig = NetworkConfig({
        priceFeed : 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
      });

      return  mainetConfig;
   }

   function getOrCreatAnvilETHConfig() public  returns(NetworkConfig memory) {
      if(activeNetworkConfig.priceFeed != address(0)){
         return activeNetworkConfig;
      }
      
      // 1. create a mock contract
      // 2. Deploy the mock contract
      // 3. Return the mock address

      vm.startBroadcast();
      MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
      vm.stopBroadcast();
      
      NetworkConfig memory anvilConfig = NetworkConfig({
        priceFeed : address(mockPriceFeed)
      });

      return anvilConfig;

   }
}
