// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { VRFConsumerBaseV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import { VRFV2PlusClient } from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle
 * @author Illia Verbanov
 * @notice This is raffle smart contract
 * @dev This implements the Chainlink VRF Version 2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint32 private constant RANDOM_NUMS_COUNT = 3;
    uint16 private constant MINIMUM_REQUEST_CONFIRMATIONS = 3;
    uint256 private immutable I_ENTRANCE_FEE;
    uint256 private immutable I_DURATION_IN_SECONDS;
    uint256 private immutable I_SUBSCRIPTION_ID;
    bytes32 private immutable I_KEY_HASH;
    uint32 private immutable I_CALLBACK_GAS_LIMIT;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address private s_recentWinner;
    RaffleState private s_state;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle_NotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    constructor(uint256 entranceFee, uint256 durationInSeconds, address vrfCoordinator, bytes32 keyHash, uint256 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator) {
        I_ENTRANCE_FEE = entranceFee;
        I_DURATION_IN_SECONDS = durationInSeconds;
        I_KEY_HASH = keyHash;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0);
        s_state = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < I_ENTRANCE_FEE) {
            revert Raffle__NotEnoughEthSent();
        }

        if (s_state != RaffleState.OPEN) {
            revert Raffle_NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function fulfillRandomWords(uint256 /* requestId */, uint256[] calldata randomWords) internal virtual override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_state = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);

        (bool success, ) = recentWinner.call{ value: address(this).balance }("");

        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory) {
        bool isTimePassed = (block.timestamp - s_lastTimeStamp) > I_DURATION_IN_SECONDS;
        bool isOpen = s_state == RaffleState.OPEN;
        bool hasPlayersEnough = s_players.length > 0;
        bool hasEnoughFunds = address(this).balance > 0;
        upkeepNeeded = isTimePassed && hasPlayersEnough && isOpen && hasEnoughFunds;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_state));
        }

        s_state = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: I_KEY_HASH,
            subId: I_SUBSCRIPTION_ID,
            requestConfirmations: MINIMUM_REQUEST_CONFIRMATIONS,
            callbackGasLimit: I_CALLBACK_GAS_LIMIT,
            numWords: RANDOM_NUMS_COUNT,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({ nativePayment: false }))
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId);
    }

    function getEntranceFee() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }

    function getState() external view returns (RaffleState) {
        return s_state;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
