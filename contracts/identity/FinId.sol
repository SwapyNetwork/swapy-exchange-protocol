pragma solidity ^0.4.15;

contract FinId {
    mapping(address => UserData) public userDataset;

    enum UserType {
        CREDIT_COMPANY,
        INVESTOR
    }

    struct UserData {
      UserType userType;
      bool valid;
    }

    modifier onlyValidUser(address _user) {
      require(userDataset[_user].valid);
      _;
    }

    function newUser(UserType _type) {
        UserData newUser;
        newUser.userType = _type;
        newUser.valid = true;

        userDataset[msg.sender] = newUser;
    }

    function getUser(address userAddress) constant returns (UserType) {
        if(userDataset[userAddress].valid) {
            return userDataset[userAddress];
        }
    }
}
