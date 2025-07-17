// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import { LinkToken } from "../test/mocks/LinkToken.t.sol";
import { CodeConstants } from "./CodeConstants.s.sol";

contract HelperConfig is Script, CodeConstants {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 durationInSeconds;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address linkToken;
    }

    NetworkConfig private s_localNetworkConfig;
    mapping(uint256 => NetworkConfig) private s_networkConfigs;

    error HelperConfig__InvalidChainId();

    constructor() {
        s_networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getActiveNetworkConfig() external returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) private returns (NetworkConfig memory) {
        if (s_networkConfigs[chainId].vrfCoordinator != address(0)) {
            return s_networkConfigs[chainId];
        }

        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateLocalConfig();
        }

        revert HelperConfig__InvalidChainId();
    }

    function getOrCreateLocalConfig() private returns (NetworkConfig memory) {
        if (s_localNetworkConfig.vrfCoordinator != address(0)) {
            return s_localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mockVrfCoordinator = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE, MOCK_WEI_PER_UNIT_LINK);
        LinkToken link = new LinkToken();
        vm.stopBroadcast();
        s_localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            durationInSeconds: 30,
            vrfCoordinator: address(mockVrfCoordinator),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            linkToken: address(link)
        });
        return s_localNetworkConfig;
    }

    function getSepoliaEthConfig() private pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                durationInSeconds: 30,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 500000,
                subscriptionId: 0,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }
}
