// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { DeployRaffle } from "../../script/DeployRaffle.s.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { Raffle } from "../../src/Raffle.sol";

contract RaffleTest is Test {
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    address public s_player;
    Raffle private s_raffle;
    HelperConfig.NetworkConfig private s_config;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    modifier playerPrank() {
        vm.prank(s_player);
        _;
    }

    function setUp() external {
        s_player = makeAddr("player");
        vm.deal(s_player, STARTING_USER_BALANCE);
        DeployRaffle deployer = new DeployRaffle();
        (s_raffle, s_config) = deployer.deploy();
    }

    function testRaffleInitialStateIsOpen() public view {
        assert(s_raffle.getState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsIfNotEnoughEthSent() public playerPrank {
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        s_raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public playerPrank {
        s_raffle.enterRaffle{ value: s_config.entranceFee }();
        address playerRecorded = s_raffle.getPlayer(0);
        assert(playerRecorded == s_player);
    }

    function testEnteringRaffleEmitsEvent() public playerPrank {
        vm.expectEmit(true, false, false, false, address(s_raffle));
        emit RaffleEntered(address(s_player));
        s_raffle.enterRaffle{ value: s_config.entranceFee }();
    }

    function testPlayersCanNotEnterWhileRaffleIsCalculating() public playerPrank {
        s_raffle.enterRaffle{ value: s_config.entranceFee }();
        vm.warp(block.timestamp + s_config.durationInSeconds + 1);
        vm.roll(block.number + 1);
        s_raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle_NotOpen.selector);
        s_raffle.enterRaffle{ value: s_config.entranceFee }();
    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + s_config.durationInSeconds + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = s_raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() public playerPrank {
        s_raffle.enterRaffle{ value: s_config.entranceFee }();
        vm.warp(block.timestamp + s_config.durationInSeconds + 1);
        vm.roll(block.number + 1);
        s_raffle.performUpkeep("");
        (bool upkeepNeeded, ) = s_raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }
}
