pragma solidity ^0.4.18;

import './AssetEvents.sol';
import '../token/Token.sol';
import "zeppelin-solidity/contracts/math/SafeMath.sol";

// Defines methods and control modifiers for an investment
contract AssetLibrary is AssetEvents {

    using SafeMath for uint256;

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

    modifier protocolOrInvestor() {
        require(msg.sender == investor || msg.sender == protocol);
        _;
    }

    modifier protocolOrOwner() {
        require(msg.sender == owner || msg.sender == protocol);
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
        status = Status.AVAILABLE;
        uint256 investedValue = this.balance;
        investor.transfer(investedValue);
        address currentInvestor = investor;
        investor = address(0);
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
        tokenFuel = tokenFuel.sub(_amount);
        return true;
    }

    // Add investment interest in this asset and retain the funds within the smart contract
    function invest(address _investor) payable
         hasStatus(Status.AVAILABLE)
         external
         returns(bool)
    {
        status = Status.PENDING_OWNER_AGREEMENT;
        investor = _investor;
        investedAt = now;
        Invested(owner, investor, this.balance);
        return true;
    }

    // Cancel the pending investment
    function cancelInvestment()
        protocolOrInvestor
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
        protocolOrOwner
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        external
        returns(bool)
    {
        status = Status.INVESTED;
        uint256 _value = this.balance;
        owner.transfer(_value);
        Withdrawal(owner, investor, _value);
        return true;
    }

    // Refuse the pending investment
    function refuseInvestment()
        protocolOrOwner
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        external
        returns(bool)
    {
        var (currentInvestor, investedValue) = makeAvailable();
        Refused(owner, currentInvestor, investedValue);
        return true;
    }

    function sell(uint256 _sellValue)
        protocolOrInvestor
        hasStatus(Status.INVESTED)
        external
        returns(bool)
    {
        status = Status.FOR_SALE;
        sellData.value = _sellValue;
        ForSale(msg.sender, _sellValue);
        return true;
    }

    function cancelSellOrder()
        protocolOrInvestor
        hasStatus(Status.FOR_SALE)
        external
        returns(bool)
    {
        status = Status.INVESTED;
        sellData.value = uint256(0);
        CanceledSell(investor, value);
        return true;
    }

    function buy(address _buyer) payable
        hasStatus(Status.FOR_SALE)
        external
        returns(bool)
    {
        status = Status.PENDING_INVESTOR_AGREEMENT;
        sellData.buyer = _buyer;
        Invested(investor, _buyer, msg.value);
        return true;
    }

    function cancelSale()
        hasStatus(Status.PENDING_INVESTOR_AGREEMENT)
        external
        returns(bool)
    {
        require(msg.sender == protocol || msg.sender == sellData.buyer);
        status = Status.FOR_SALE;
        address buyer = sellData.buyer;
        uint256 _value = this.balance;
        buyer.transfer(_value);
        sellData.buyer = address(0);
        Canceled(investor, buyer, _value);
        return true;
    }

    // Refunds asset's buyer and became available for sale again
    function refuseSale()
        protocolOrInvestor
        hasStatus(Status.PENDING_INVESTOR_AGREEMENT)
        external
        returns(bool)
    {
        status = Status.FOR_SALE;
        address buyer = sellData.buyer;
        uint256 _value = this.balance;
        buyer.transfer(_value);
        sellData.buyer = address(0);
        Refused(investor, buyer, _value);
        return true;
    }

    // Withdraw funds, clear the sell data and change investor's address
    function acceptSale()
        protocolOrInvestor
        hasStatus(Status.PENDING_INVESTOR_AGREEMENT)
        external
        returns(bool)
    {
        status = Status.INVESTED;
        address currentInvestor = investor;
        uint256 _value = this.balance;
        currentInvestor.transfer(_value);
        investor = sellData.buyer;
        boughtValue = sellData.value;
        sellData.buyer = address(0);
        sellData.value = uint256(0);
        Withdrawal(currentInvestor, investor, _value);
        return true;
    }

    function returnInvestment() payable
        onlyOwner
        external
        returns(bool)
    {
        assert(status == Status.INVESTED || status == Status.FOR_SALE || status == Status.PENDING_INVESTOR_AGREEMENT);
        Status currentStatus = status;
        bool _isDelayed = isDelayed();
        status = _isDelayed ? Status.DELAYED_RETURN : Status.RETURNED;
        if(tokenFuel > 0){
            address recipient = _isDelayed ? investor : owner;
            withdrawTokens(recipient, tokenFuel);
        }
        if (currentStatus == Status.PENDING_INVESTOR_AGREEMENT) {
            sellData.buyer.transfer(this.balance.sub(msg.value));
        }
        investor.transfer(msg.value);
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
        tokenFuel = tokenFuel.add(_amount);
        Supplied(owner, _amount, tokenFuel);
        return true;
    }

    function requireTokenFuel()
        protocolOrInvestor
        hasStatus(Status.INVESTED)
        onlyDelayed
        external
        returns(bool)
    {
        return withdrawTokens(investor, tokenFuel);
    }

}
