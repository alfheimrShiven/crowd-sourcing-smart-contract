// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMAL = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == 11155111)
            activeNetworkConfig = getSepoliaEthConfig();
        else if (block.chainid == 1)
            activeNetworkConfig = getMainnetEthConfig();
        else activeNetworkConfig = getOrCreateAnvilEthConfig(); // local chain
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }

    // local chain priceFeed contract address
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // check if priceFeed contract address already exists on our local chain
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // deploy the mock price feed contract on local chain
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMAL,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        // return the address of the mock contract
        NetworkConfig memory anvilNetworkConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilNetworkConfig;
    }
}
