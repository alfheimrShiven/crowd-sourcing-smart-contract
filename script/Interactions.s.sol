// SPDX-Identifier-License: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTool} from "lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "src/Fundme.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded FundMe contract with %s", SEND_VALUE);
    }

    function run() public {
        // find the latest deployed address of FundMe contract
        address mostRecentlyDeployed = DevOpsTool.get_most_recent_deployment(
            "FundMe",
            block.chainId
        );
        // fund it
        fundFundMe(mostRecentlyDeployed);
    }
}
