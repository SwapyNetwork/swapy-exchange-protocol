pragma solidity ^0.4.15;

// Defines events fired by investment assets 

contract AssetEvents {

    event Transferred(
        string _id,
        address _from,
        address _to,
        uint256 _value
    );

    event Canceled(
        string _id,
        address _owner,
        address _investor,
        uint256 _value
    );

    event Withdrawal(
        string _id,
        address _owner,
        address _investor,
        uint256 _value,
        bytes _terms
    );

    event Refused(
        string _id,
        address _owner,
        address _investor,
        uint256 _value
    );

    event Returned(
        string _id,
        address _owner,
        address _investor,
        uint256 _value
    );
}    