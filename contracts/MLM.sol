// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "./DataTypes.sol";

contract MLM {

    address public owner;
    uint256 public cycleCount;
    uint256 private usersInCurrentCycle;

}
