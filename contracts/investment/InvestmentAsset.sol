pragma solidity ^0.4.18;

import '../token/Token.sol';

// Defines a fund raising asset contract

contract InvestmentAsset {

    // Asset owner
    address public owner;
    // Protocol
    address public protocol;
    // Asset currency
    string public currency;
    // Asset value
    uint256 public value;
    //Value bought
    uint256 public boughtValue;
    // period to return the investment
    uint256 public paybackDays;
    // Gross return of investment
    uint256 public grossReturn;
    // Asset buyer
    address public investor;
    // Protocol version
    string public protocolVersion;
    // investment timestamp
    uint public investedAt;

    // Fuel
    Token public token;
    uint256 public tokenFuel;

    // sell data
    struct Sell {
        uint256 value;
        address buyer;
    }
    Sell public sellData;

    // possible stages of an asset
    enum Status {
        AVAILABLE,
        PENDING_OWNER_AGREEMENT,
        INVESTED,
        FOR_SALE,
        PENDING_INVESTOR_AGREEMENT,
        RETURNED,
        DELAYED_RETURN
    }
    Status public status;

    //  Library to delegate calls
    address public assetLibrary;

    function InvestmentAsset(
        address _library,
        address _protocol,
        address _owner,
        string _protocolVersion,
        string _currency,
        uint256 _value,
        uint _paybackDays,
        uint _grossReturn,
        address _token)
        public
    {
        // set the library to delegate methods
        assetLibrary = _library;
        // init asset
        protocol = _protocol;
        owner = _owner;
        protocolVersion = _protocolVersion;
        currency = _currency;
        value = _value;
        boughtValue = 0;
        paybackDays = _paybackDays;
        grossReturn = _grossReturn;
        status = Status.AVAILABLE;
        tokenFuel = 0;
        token = Token(_token);
    }

    function getAsset()
        external
        constant
        returns(address, string, uint256, uint256, uint256, Status, address, string, uint, uint256, address, uint256, uint256)
    {
        return (owner, currency, value, paybackDays, grossReturn, status, investor, protocolVersion, investedAt, tokenFuel, sellData.buyer, sellData.value, boughtValue);
    }

    function () payable
        external
    {
        require(assetLibrary.delegatecall(msg.data));
    }

}
