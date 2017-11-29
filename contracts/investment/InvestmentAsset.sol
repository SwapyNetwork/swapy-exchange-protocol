pragma solidity ^0.4.15;

import './AssetEvents.sol';
import '../token/Token.sol';

// Defines a fund raising asset contract

contract InvestmentAsset is AssetEvents {

    // Asset owner
    address public owner;
    // Asset currency
    string public currency;
    // Asset fixed value
    uint256 public fixedValue;
    // period to return the investment
    uint256 public paybackDays;
    // Gross return of investment
    uint256 public grossReturn;
    // Asset buyer
    address public investor;
    // Protocol version
    string public protocolVersion;
    // Contractual terms hash of investment
    bytes public assetTermsHash;
    // Document hash agreeing the contractual terms
    bytes public agreementHash;
    // investment timestamp
    uint public investedAt;
    // asset fuel
    Token public token;
    uint256 public tokenFuel;

    // possible stages of an asset
    enum Status {
        AVAILABLE,
        PENDING_OWNER_AGREEMENT,
        INVESTED,
        RETURNED,
        DELAYED_RETURN
    }
    Status public status;

    //  Library to delegate calls
    address public assetLibrary;
    
    function InvestmentAsset(
        address _library,
        address _owner,
        string _protocolVersion,
        string _currency,
        uint256 _fixedValue,
        bytes _assetTermsHash,
        uint _paybackDays,
        uint _grossReturn,
        address _token,
        uint256 _tokenFuel)
        public
    {
        // set the library to delegate methods 
        assetLibrary = _library;
        owner = _owner;
        protocolVersion = _protocolVersion;
        currency = _currency;
        fixedValue = _fixedValue;
        assetTermsHash = _assetTermsHash;
        paybackDays = _paybackDays;
        grossReturn = _grossR_assetTokenFueleturn;
        tokenFuel = _tokenFuel;
        status = Status.AVAILABLE;
        token = Token(_token);
        if(tokenFuel > 0){
            require(token.transferFrom(owner, this, tokenFuel));
        }
    }

    function getAsset()
        public
        constant
        returns(address, string, uint256, uint256, uint256, address, string, bytes, bytes, uint, uint256)
    {
        return (owner, currency, fixedValue, paybackDays, grossReturn, investor, protocolVersion, assetTermsHash, agreementHash, investedAt, tokenFuel);
    }

    function () payable {
        require(assetLibrary.delegatecall(msg.data));
    }

}
