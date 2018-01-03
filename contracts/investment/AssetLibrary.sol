pragma solidity ^0.4.18;

import './AssetEvents.sol';
import '../token/Token.sol';

// Defines methods and control modifiers for an investment
contract AssetLibrary is AssetEvents {

    // Asset owner
    address public owner;
    // Protocol
    address public protocol;
    // Asset currency
    string public currency;
    // Asset fixed value
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

    // asset fuel
    Token public token;
    uint256 public tokenFuel;

    // sell data
    struct Sell {
        uint256 value;
        address buyer;
    }

    Sell sellData;

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

    // Checks the current asset's status
    modifier hasStatus(Status _status) {
        assert(status == _status);
        _;
    }

    // Checks if the owner is the caller
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Checks if the investor is the caller
    modifier onlyInvestor() {
        require(msg.sender == investor);
        _;
    }

    // The asset can be selled by using the protocol or directly by the current investor
    modifier authorizedToSell() {
        require(msg.sender == investor || msg.sender == protocol);
        _;
    }

    modifier onlyDelayed(){
        require(isDelayed());
        _;
    }


    function isDelayed()
        view
        internal
        returns(bool)
    {
        return now > investedAt + paybackDays * 1 days;
    }

    // Refund and remove the current investor and make the asset available for investments
    function makeAvailable()
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        private
        returns(address, uint256)
    {
        uint256 investedValue = this.balance;
        investor.transfer(investedValue);
        address currentInvestor = investor;
        investor = address(0);
        status = Status.AVAILABLE;
        investedAt = uint(0);
        return (currentInvestor, investedValue);
    }


    function withdrawTokens(address _recipient, uint256 _amount)
        private
        returns(bool)
    {
        assert(tokenFuel >= _amount);
        require(token.transfer(_recipient, _amount));
        TokenWithdrawal(_recipient, _amount);
        tokenFuel -= _amount;
        return true;
    }

    // Add investment interest in this asset and retain the funds within the smart contract
    function invest(address _investor) payable
         hasStatus(Status.AVAILABLE)
         external
         returns(bool)
    {
        investor = _investor;
        investedAt = now;
        status = Status.PENDING_OWNER_AGREEMENT;
        Invested(owner, investor, this.balance);
        return true;
    }

    // Cancel the pending investment
    function cancelInvestment()
        onlyInvestor
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        external
        returns(bool)
    {
        var (currentInvestor, investedValue) = makeAvailable();
        Canceled(owner, currentInvestor, investedValue);
        return true;
    }

    // Accept the investor as the asset buyer and withdraw funds
    function withdrawFunds()
        onlyOwner
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        external
        returns(bool)
    {
        uint256 _value = this.balance;
        owner.transfer(_value);
        status = Status.INVESTED;
        Withdrawal(owner, investor, _value);
        return true;
    }

    // Refuse the pending investment
    function refuseInvestment()
        onlyOwner
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        external
        returns(bool)
    {
        var (currentInvestor, investedValue) = makeAvailable();
        Refused(owner, currentInvestor, investedValue);
        return true;
    }

    function sell(uint256 _sellValue)
        authorizedToSell
        hasStatus(Status.INVESTED)
        external
        returns(bool)
    {
        sellData.value = _sellValue;
        status = Status.FOR_SALE;
        ForSale(msg.sender, _sellValue);
        return true;
    }

    function cancelSellOrder()
        authorizedToSell
        hasStatus(Status.FOR_SALE)
        external
        returns(bool)
    {
        sellData.value = uint256(0);
        status = Status.INVESTED;
        CanceledSell(investor, value);
        return true;
    }

    function buy(address _buyer) payable
        hasStatus(Status.FOR_SALE)
        external
        returns(bool)
    {
        sellData.buyer = _buyer;
        status = Status.PENDING_INVESTOR_AGREEMENT;
        Invested(investor, _buyer, msg.value);
        return true;
    }

     function cancelSale()
        hasStatus(Status.PENDING_INVESTOR_AGREEMENT)
        external
        returns(bool)
    {
        require(msg.sender == protocol || msg.sender == sellData.buyer);
        address buyer = sellData.buyer;
        uint256 _value = this.balance;
        buyer.transfer(_value);
        sellData.buyer = address(0);
        status = Status.FOR_SALE;
        Canceled(investor, buyer, _value);
        return true;
    }

    // Refunds asset's buyer and became available for sale again
    function refuseSale()
        authorizedToSell
        hasStatus(Status.PENDING_INVESTOR_AGREEMENT)
        external
        returns(bool)
    {
        address buyer = sellData.buyer;
        uint256 _value = this.balance;
        buyer.transfer(_value);
        sellData.buyer = address(0);
        status = Status.FOR_SALE;
        Refused(investor, buyer, _value);
        return true;
    }

    // Withdraw funds, clear the sell data and change investor's address
    function acceptSale()
        authorizedToSell
        hasStatus(Status.PENDING_INVESTOR_AGREEMENT)
        external
        returns(bool)
    {
        address currentInvestor = investor;
        uint256 _value = this.balance;
        currentInvestor.transfer(_value);
        status = Status.INVESTED;
        investor = sellData.buyer;
        boughtValue = sellData.value;
        sellData.buyer = address(0);
        sellData.value = uint256(0);
        Withdrawal(currentInvestor, investor, _value);
        return true;
    }

    function returnInvestment() payable
        onlyOwner
        hasStatus(Status.INVESTED)
        external
        returns(bool)
    {
        investor.transfer(msg.value);
        bool _isDelayed = isDelayed();
        status = _isDelayed ? Status.DELAYED_RETURN : Status.RETURNED;
        if(tokenFuel > 0){
            address recipient = _isDelayed ? investor : owner;
            withdrawTokens(recipient, tokenFuel);
        }
        Returned(owner, investor, msg.value, _isDelayed);
        return true;
    }

    function supplyFuel(uint256 _amount)
        onlyOwner
        hasStatus(Status.AVAILABLE)
        external
        returns(bool)
    {
        require(token.transferFrom(msg.sender, this, _amount));
        tokenFuel += _amount;
        Supplied(owner, _amount, tokenFuel);
        return true;
    }

    function requireTokenFuel()
        onlyInvestor
        hasStatus(Status.INVESTED)
        onlyDelayed
        external
        returns(bool)
    {
        return withdrawTokens(investor, tokenFuel);
    }

}
