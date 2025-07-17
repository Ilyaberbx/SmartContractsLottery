// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script, console } from "forge-std/Script.sol";
import { DevOpsTools } from "../../lib/foundry-devops/src/DevOpsTools.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract AddConsumer is Script {
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        executeUsingConfig(mostRecentlyDeployed);
    }

    function executeUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();
        uint256 subId = config.subscriptionId;
        address vrfCoordinator = config.vrfCoordinator;
        execute(mostRecentlyDeployed, vrfCoordinator, subId);
    }

    function execute(address contractToAddVrf, address vrfCoordinator, uint256 subId) public {
        console.log("Adding consumer to", contractToAddVrf);
        console.log("Using vrfCoordinator", vrfCoordinator);
        console.log("Using subId", subId);
        console.log("On chainId", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddVrf);
        vm.stopBroadcast();
    }
}
