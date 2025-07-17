// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { Raffle } from "../src/Raffle.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { CreateSubscription } from "./interactions/CreateSubscription.s.sol";
import { FundSubscription } from "./interactions/FundSubscription.s.sol";
import { AddConsumer } from "./interactions/AddConsumer.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deploy();
    }

    function deploy() public returns (Raffle, HelperConfig.NetworkConfig memory) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription.executeUsingVRFCoordinator(config.vrfCoordinator);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.execute(config.vrfCoordinator, config.subscriptionId, config.linkToken);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(config.entranceFee, config.durationInSeconds, config.vrfCoordinator, config.gasLane, config.subscriptionId, config.callbackGasLimit);
        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.execute(address(raffle), config.vrfCoordinator, config.subscriptionId);
        return (raffle, config);
    }
}
