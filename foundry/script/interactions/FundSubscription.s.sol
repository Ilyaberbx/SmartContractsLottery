// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script, console } from "forge-std/Script.sol";
import { HelperConfig } from "../HelperConfig.s.sol";
import { CodeConstants } from "../CodeConstants.s.sol";
import { LinkToken } from "../../test/mocks/linkToken.t.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract FundSubscription is Script, CodeConstants {
    uint256 private constant FUND_AMOUNT = 3 ether; // Interchangable with 3 LINK

    function run() external {
        executeUsingActiveNetwork();
    }

    function executeUsingActiveNetwork() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();
        address vrfCoordinator = config.vrfCoordinator;
        uint256 subscriptionId = config.subscriptionId;
        address linkToken = config.linkToken;
        execute(vrfCoordinator, subscriptionId, linkToken);
    }

    function execute(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("Using linkToken: ", linkToken);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
            return;
        }

        vm.startBroadcast();
        LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
        vm.stopBroadcast();
    }
}
