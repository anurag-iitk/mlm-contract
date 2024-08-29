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

    event Earnings(address indexed user, uint256 amount);

    event NewCycle(address indexed user, uint256 indexed cycleCount);

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
        user.info.referralLink = generateReferralLink("0");
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

    function registerUser(
        string memory _firstName,
        string memory _lastName,
        string memory _email,
        string memory _password,
        string memory _profilePic,
        string memory _uplineId
    ) public payable {
        require(bytes(_firstName).length > 0, "First name must not be empty");
        require(bytes(_lastName).length > 0, "Last name must not be empty");
        require(bytes(_email).length > 0, "Email must not be empty");
        require(bytes(_password).length > 0, "Password must not be empty");
        require(
            bytes(_profilePic).length > 0,
            "Profile picture must not be empty"
        );
        require(
            bytes(users[msg.sender].info.userId).length == 0,
            "User already registered."
        );
        require(
            msg.value == REGISTRATION_FEE,
            "Registration requires the correct fee."
        );
        require(isValidEmail(_email), "Invalid email format");
        for (uint256 i = 0; i < userAddresses.length; i++) {
            address userAddr = userAddresses[i];
            if (
                keccak256(abi.encodePacked(users[userAddr].details.email)) ==
                keccak256(abi.encodePacked(_email))
            ) {
                revert("Email already exists");
            }
        }
        string memory userId = generateUserId();
        address uplineAddress;

        if (
            keccak256(abi.encodePacked(userId)) !=
            keccak256(abi.encodePacked("1"))
        ) {
            require(bytes(_uplineId).length > 0, "Upline ID is required.");
            uplineAddress = findAddressByUserId(_uplineId);
            require(uplineAddress != address(0), "Upline not found.");
        } else {
            _uplineId = "";
            uplineAddress = address(0);
        }

        if (usersInCurrentCycle == SPOTS_X3) {
            cycleCount++;
            usersInCurrentCycle = 0;
        }

        usersInCurrentCycle++;

        uint256 distributeAmount = msg.value / 2;

        string memory referralLink = generateReferralLink(userId);

        UserDetails memory newUserDetails = UserDetails({
            firstName: _firstName,
            lastName: _lastName,
            profilePic: _profilePic,
            email: _email,
            passwordHash: keccak256(abi.encodePacked(_password))
        });

        User storage user = users[msg.sender];

        user.details = newUserDetails;
        user.info.upline = uplineAddress;
        user.info.id = lastUserId;
        user.info.referralCount = 0;
        user.info.cycleCount = 0;
        user.info.earnings = 0;
        user.info.partnerLevel = 1;
        user.info.referrals = new address[](0);
        user.info.userId = userId;
        user.info.uplineId = _uplineId;
        user.info.walletAddress = msg.sender;
        user.info.referralLink = referralLink;
        user.info.cycle = cycleCount;
        user.info.isLevelActive[1] = true;
        userAddresses.push(msg.sender);
        idToAddress[lastUserId] = msg.sender;
        addressToId[msg.sender] = lastUserId;
        lastUserId++;

        emit UserRegistered(msg.sender, userId, _uplineId, referralLink);

        // Transfer the registration fee to the appropriate recipient
        if (uplineAddress != address(0)) {
            users[uplineAddress].info.referrals.push(msg.sender);

            // Call handleReferral function to manage referral earnings and cycle
            handleReferral(msg.sender);

            // Transfer the registration fee based on the updated logic
            uint256 uplineReferralCount = users[uplineAddress]
                .info
                .referralCount;
            if (uplineReferralCount <= 2) {
                // Send fee to the upline directly
                payable(uplineAddress).transfer(distributeAmount);
            } else if (uplineReferralCount == 3) {
                // If third referral, send fee to the upline's upline (cycle reset handled in handleReferral)
                address uplineOfUpline = users[uplineAddress].info.upline;
                if (uplineOfUpline != address(0)) {
                    payable(uplineOfUpline).transfer(distributeAmount);
                } else {
                    // Fallback to owner if no upline's upline exists
                    payable(owner).transfer(msg.value);
                }
            }
        } else {
            // If no upline (first user), send fee to the owner
            payable(owner).transfer(msg.value);
        }
    }

    function handleReferral(address _user) internal {
        address upline = users[_user].info.upline;

        if (users[upline].info.referralCount <= 2) {
            // First and second referrals go to the upline's wallet
            uint8 level = users[upline].info.partnerLevel;
            if (level >= 1) {
                rewardUser(upline, levelPrice[level]);
            }
        } else if (users[upline].info.referralCount == 3) {
            // Third referral's payment completes the cycle
            address uplineOfUpline = users[upline].info.upline;
            uint8 level = users[upline].info.partnerLevel;

            if (uplineOfUpline != address(0)) {
                // Send earnings to upline's upline and reset the cycle
                rewardUser(uplineOfUpline, levelPrice[level]);
                users[upline].info.cycleCount++;
                emit NewCycle(upline, users[upline].info.cycleCount);
            } else {
                // Fallback to owner if no upline's upline exists
                rewardUser(owner, levelPrice[level]);
            }

            // Reset upline's referral count after completing the cycle
            users[upline].info.referralCount = 0;
        }

        // Increment the referral count for the upline
        users[upline].info.referralCount++;
    }

    function rewardUser(address _user, uint256 _amount) internal virtual {
        users[_user].info.earnings += _amount;
        balances[_user] += _amount;

        emit Earnings(_user, _amount);
    }

    function generateUserId() internal view returns (string memory) {
        if (userAddresses.length == 0) {
            return "1";
        } else {
            string memory _lastUserId = users[
                userAddresses[userAddresses.length - 1]
            ].info.userId;
            uint256 lastUserIdInt = stringToUint(_lastUserId);
            uint256 newUserIdInt = lastUserIdInt + 1;
            return toString(newUserIdInt);
        }
    }

    function isValidEmail(string memory _email) internal pure returns (bool) {
        bytes memory emailBytes = bytes(_email);
        bytes memory domain = bytes("gmail.com");
        uint256 atPosition = 0;
        bool hasAt = false;
        for (uint256 i = 0; i < emailBytes.length; i++) {
            if (emailBytes[i] == bytes1("@")) {
                if (hasAt) {
                    return false;
                }
                hasAt = true;
                atPosition = i;
            }
        }
        if (!hasAt || atPosition == 0 || atPosition >= emailBytes.length - 1) {
            return false;
        }
        if (emailBytes.length < atPosition + 1 + domain.length) {
            return false;
        }
        for (uint256 i = 0; i < domain.length; i++) {
            if (emailBytes[atPosition + 1 + i] != domain[i]) {
                return false;
            }
        }
        return true;
    }

    function generateReferralLink(
        string memory userId
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked("https://myplatform.com/referral/", userId)
            );
    }

    function stringToUint(string memory s) internal pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function findAddressByUserId(
        string memory _userId
    ) internal view returns (address) {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            if (
                keccak256(
                    abi.encodePacked(users[userAddresses[i]].info.userId)
                ) == keccak256(abi.encodePacked(_userId))
            ) {
                return userAddresses[i];
            }
        }
        return address(0);
    }

    function getX3ProgramInfo(
        address _user
    ) public view returns (X3ProgramInfo memory) {
        return
            X3ProgramInfo({
                earnings: users[_user].info.earnings,
                level: users[_user].info.partnerLevel,
                cycleCount: users[_user].info.cycleCount,
                upline: users[_user].info.upline,
                referrals: users[_user].info.referrals
            });
    }

    function getUserTotalBalance(address _user) public view returns (uint256) {
        return balances[_user];
    }
}
