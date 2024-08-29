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

    constructor() payable {
        owner = msg.sender;
        cycleCount = 1;
        usersInCurrentCycle = 0;

        UserDetails memory ownerDetails = UserDetails({
            firstName: "",
            lastName: "",
            profilePic: "",
            email: "",
            passwordHash: bytes32(0)
        });

        User storage user = users[owner];

        user.details = ownerDetails;
        user.info.upline = address(0);
        user.info.id = 0;
        user.info.referralCount = 0;
        user.info.cycleCount = 0;
        user.info.earnings = 0;
        user.info.partnerLevel = 1;
        user.info.referrals = new address[](0);
        user.info.userId = "0";
        user.info.uplineId = "";
        user.info.walletAddress = owner;
        user.info.referralLink = "";
        user.info.cycle = 1;
        user.info.isLevelActive[1] = true;

        idToAddress[1] = owner;
        addressToId[owner] = 1;

        // Initialize level prices
        levelPrice[1] = BASIC_PRICE;
        for (uint8 i = 2; i <= 8; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }
        levelPrice[9] = 1250 ether;
        levelPrice[10] = 2500 ether;
        levelPrice[11] = 5000 ether;
        levelPrice[12] = 9900 ether;
    }

}
