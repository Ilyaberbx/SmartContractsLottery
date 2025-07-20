// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { DeployRaffle } from "../../script/DeployRaffle.s.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { Raffle } from "../../src/Raffle.sol";
import { Vm } from "forge-std/Vm.sol";

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

    modifier raffleEntered() {
        vm.prank(s_player);
        s_raffle.enterRaffle{ value: s_config.entranceFee }();
        vm.warp(block.timestamp + s_config.durationInSeconds + 1);
        vm.roll(block.number + 1);
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

    /* CHECK UPKEEP*/

    function testCheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed() public playerPrank {
        s_raffle.enterRaffle{ value: s_config.entranceFee }();
        vm.warp(block.timestamp + s_config.durationInSeconds);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = s_raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public playerPrank {
        s_raffle.enterRaffle{ value: s_config.entranceFee }();
        vm.warp(block.timestamp + s_config.durationInSeconds + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = s_raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughPlayers() public {
        vm.warp(block.timestamp + s_config.durationInSeconds + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = s_raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    /* PERFORM UPKEEP */

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public playerPrank {
        s_raffle.enterRaffle{ value: s_config.entranceFee }();
        vm.warp(block.timestamp + s_config.durationInSeconds + 1);
        vm.roll(block.number + 1);
        s_raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public playerPrank {
        s_raffle.enterRaffle{ value: s_config.entranceFee }();
        uint256 currentBalance = address(s_raffle).balance;
        uint256 numPlayers = 1;
        Raffle.RaffleState raffleState = s_raffle.getState();
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, raffleState));
        s_raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
        vm.recordLogs();
        s_raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState raffleState = s_raffle.getState();
        assert(uint256(requestId) > 0);
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(entries[1].emitter == address(s_raffle));
    }
}
