// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "./DataTypes.sol";

contract MLM {

    address public owner;
    uint256 public cycleCount;
    uint256 private usersInCurrentCycle;

    address[] public userAddresses;

    uint256 public lastUserId = 1;
    uint8 public constant LAST_LEVEL = 12;
    uint256 public constant BASIC_PRICE = 5 ether;
    uint8 public constant SPOTS_X3 = 3;
    uint8 public constant SPOTS_X4 = 6;
    uint256 public constant REGISTRATION_FEE = 10 ether;

    mapping(address => User) internal users;
    mapping(uint256 => address) public idToAddress;
    mapping(address => uint256) public addressToId;
    mapping(uint8 => uint256) public levelPrice;
    mapping(address => uint256) public balances;

    event UserRegistered(
        address indexed walletAddress,
        string indexed userId,
        string indexed uplineId,
        string referralLink
    );

}
