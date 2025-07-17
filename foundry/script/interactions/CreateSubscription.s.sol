// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script, console } from "forge-std/Script.sol";
import { HelperConfig } from "../HelperConfig.s.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function run() external {
        executeUsingActiveNetwork();
    }

    function executeUsingActiveNetwork() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();
        address vrfCoordinator = config.vrfCoordinator;
        return executeUsingVRFCoordinator(vrfCoordinator);
    }

    function executeUsingVRFCoordinator(address vrfCoordinator) public returns (uint256, address) {
        console.log("Creating subscription on chainId", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("New Subscription Id: ", subId);
        console.log("Please update Subscription Id in HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }
}
