pragma solidity ^0.4.18;

import '../token/Token.sol';

/**
 * @title Investment Asset 
 * @dev Defines a fundraising asset and its properties
 */
contract InvestmentAsset {

    /**
     * Storage
     */
    // Asset owner
    address public owner;
    // Protocol
    address public protocol;
    // Asset currency
    bytes5 public currency;
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
    bytes8 public protocolVersion;
    // investment timestamp
    uint public investedAt;

    // Fuel
    Token public token;
    uint256 public tokenFuel;

    // sale structure
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

    /**
     * @param _library Address of library that contains asset's logic
     * @param _protocol Swapy Exchange Protocol address
     * @param _owner Fundraising owner
     * @param _protocolVersion Version of Swapy Exchange protocol
     * @param _currency Fundraising base currency, i.e, USD
     * @param _value Asset value
     * @param _paybackDays Period in days until the return of investment
     * @param _grossReturn Gross return on investment
     * @param _token Collateral Token address
     */
    function InvestmentAsset(
        address _library,
        address _protocol,
        address _owner,
        bytes8 _protocolVersion,
        bytes5 _currency,
        uint256 _value,
        uint _paybackDays,
        uint _grossReturn,
        address _token)
        public
    {
        assetLibrary = _library;
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

    /**
     * @dev Returns asset's properties as a tuple
     * @return A tuple with asset's properties
     */ 
    function getAsset()
        external
        constant
        returns(address, bytes5, uint256, uint256, uint256, Status, address, bytes8, uint, uint256, address, uint256, uint256)
    {
        return (owner, currency, value, paybackDays, grossReturn, status, investor, protocolVersion, investedAt, tokenFuel, sellData.buyer, sellData.value, boughtValue);
    }

    /**
     * @dev Fallback function. Used to delegate calls to the library
     */ 
    function () payable
        external
    {
        require(assetLibrary.delegatecall(msg.data));
    }

}
