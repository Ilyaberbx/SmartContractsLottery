// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract CodeConstants {
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE = 10;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}
