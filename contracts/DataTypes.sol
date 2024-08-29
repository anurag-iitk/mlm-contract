// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

struct UserDetails {
    string firstName;
    string lastName;
    string profilePic;
    string email;
    bytes32 passwordHash;
}

struct UserInfo {
    address upline;
    uint256 id;
    uint256 referralCount;
    uint256 cycleCount;
    uint256 earnings;
    uint8 partnerLevel;
    address[] referrals;
    string userId;
    string uplineId;
    address walletAddress;
    string referralLink;
    uint256 cycle;
    mapping(uint8 => bool) isLevelActive;
}

struct User {
    UserDetails details;
    UserInfo info;
}

struct X3ProgramInfo {
    uint256 earnings;
    uint8 level;
    uint256 cycleCount;
    address upline;
    address[] referrals;
}

struct X4ProgramInfo {
    uint256 earnings;
    uint8 level;
    uint256 cycleCount;
    address upline;
    uint256 distributedEarnings;
    uint8 firstLineCount;
    uint8 secondLineCount;
    uint8 currentCycleSpots;
    address[] firstLineRefs;
    address[] secondLineRefs;
}

struct BasicUserInfo {
    address user;
    UserDetails details;
    UserInfo info;
}
