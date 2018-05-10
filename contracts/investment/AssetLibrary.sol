pragma solidity ^0.4.23;

import "./AssetEvents.sol";
import "../token/Token.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title Asset Library
 * @dev Defines the behavior of a fundraising asset. Designed to receive InvestmentAsset's calls and work on its storage
 */
contract AssetLibrary is AssetEvents {
    /**
     * Add safety checks for uint operations
     */
    using SafeMath for uint256;

    /**
     * Storage
     */
    // Asset owner
    address public owner;
    // Protocol
    address public protocol;
    // Asset currency
    bytes5 public currency;
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
    bytes8 public protocolVersion;
    // investment timestamp
    uint public investedAt;

    // asset fuel
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
   
    /**
     * Modifiers   
     */
    // Checks the current asset's status
    modifier hasStatus(Status _status) {
        assert(status == _status);
        _;
    }
    // Checks if the owner is the caller
    modifier onlyOwner() {
        require(msg.sender == owner, "The user isn't the owner");
        _;
    }
    // Checks if the investor is the caller
    modifier onlyInvestor() {
        require(msg.sender == investor, "The user isn't the investor");
        _;
    }
    modifier protocolOrInvestor() {
        require(msg.sender == protocol || msg.sender == investor, "The user isn't the protocol or investor");
        _;
    }
    modifier protocolOrOwner() {
        require(msg.sender == protocol || msg.sender == owner, "The user isn't the protocol or owner");
        _;
    }
    modifier isValidAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }    
    
    modifier onlyDelayed(){
        require(isDelayed(), "The return of investment isn't dalayed");
        _;
    }

    /**
     * @dev Supply collateral tokens to the asset 
     * @param _amount Token amount
     * @return Success
     */
    function supplyFuel(uint256 _amount)
        onlyOwner
        hasStatus(Status.AVAILABLE)
        external
        returns(bool)
    {
        require(token.transferFrom(msg.sender, this, _amount), "An error ocurred when sending tokens");
        tokenFuel = tokenFuel.add(_amount);
        emit LogSupplied(owner, _amount, tokenFuel);
        return true;
    }

    /**
     * @dev Add investment interest and retain pending funds within the asset 
     * @param _investor Pending Investor
     * @return Success
     */ 
    function invest(address _investor) payable
        isValidAddress(_investor)
        hasStatus(Status.AVAILABLE)
        external
        returns(bool)
    {
        status = Status.PENDING_OWNER_AGREEMENT;
        investor = _investor;
        investedAt = now;
        emit LogInvested(owner, investor, address(this).balance);
        return true;
    }

    /**
     * @dev Cancel a pending investment made
     * @return Success
     */ 
    function cancelInvestment()
        protocolOrInvestor
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        external
        returns(bool)
    {
        address currentInvestor;
        uint256 investedValue;
        (currentInvestor, investedValue) = makeAvailable();
        emit LogCanceled(owner, currentInvestor, investedValue);
        return true;
    }
   
    /**
     * @dev Refuse a pending investment
     * @return Success
     */
    function refuseInvestment()
        protocolOrOwner
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        external
        returns(bool)
    {
        address currentInvestor;
        uint256 investedValue;
        (currentInvestor, investedValue) = makeAvailable();
        emit LogRefused(owner, currentInvestor, investedValue);
        return true;
    }

    /**
     * @dev Accept the investor as the asset buyer and withdraw funds
     * @return Success
     */ 
    function withdrawFunds()
        protocolOrOwner
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        external
        returns(bool)
    {
        status = Status.INVESTED;
        uint256 _value = address(this).balance;
        owner.transfer(_value);
        emit LogWithdrawal(owner, investor, _value);
        return true;
    }

    /**
     * @dev Put this asset for sale.
     * @param _sellValue Sale value
     * @return Success
     */ 
    function sell(uint256 _sellValue)
        protocolOrInvestor
        hasStatus(Status.INVESTED)
        external
        returns(bool)
    {
        status = Status.FOR_SALE;
        sellData.value = _sellValue;
        emit LogForSale(msg.sender, _sellValue);
        return true;
    }

    /**
     * @dev Remove the asset from market place
     * @return Success
     */
    function cancelSellOrder()
        protocolOrInvestor
        hasStatus(Status.FOR_SALE)
        external
        returns(bool)
    {
        status = Status.INVESTED;
        sellData.value = uint256(0);
        emit LogCanceledSell(investor, value);
        return true;
    }

    /**
     * @dev Buy the asset on market place
     * @param _buyer Address of pending buyer
     * @return Success
     */
    function buy(address _buyer) payable
        isValidAddress(_buyer)
        hasStatus(Status.FOR_SALE)
        external
        returns(bool)
    {
        status = Status.PENDING_INVESTOR_AGREEMENT;
        sellData.buyer = _buyer;
        emit LogInvested(investor, _buyer, msg.value);
        return true;
    }

    /**
     * @dev Cancel a purchase made
     * @return Success
     */
    function cancelSale()
        hasStatus(Status.PENDING_INVESTOR_AGREEMENT)
        external
        returns(bool)
    {
        require(msg.sender == protocol || msg.sender == sellData.buyer, "The user isn't the protocol or buyer");
        status = Status.FOR_SALE;
        address buyer = sellData.buyer;
        uint256 _value = address(this).balance;
        sellData.buyer = address(0);
        buyer.transfer(_value);
        emit LogCanceled(investor, buyer, _value);
        return true;
    }
   
    /**
     * @dev Refuse purchase on market place and refunds the pending buyer
     * @return Success
     */
    function refuseSale()
        protocolOrInvestor
        hasStatus(Status.PENDING_INVESTOR_AGREEMENT)
        external
        returns(bool)
    {
        status = Status.FOR_SALE;
        address buyer = sellData.buyer;
        uint256 _value = address(this).balance;
        sellData.buyer = address(0);
        buyer.transfer(_value);
        emit LogRefused(investor, buyer, _value);
        return true;
    }

    /**
     * @dev Accept purchase. Withdraw funds, clear the sell data and change investor
     * @return Success
     */
    function acceptSale()
        protocolOrInvestor
        hasStatus(Status.PENDING_INVESTOR_AGREEMENT)
        external
        returns(bool)
    {
        status = Status.INVESTED;
        address currentInvestor = investor;
        uint256 _value = address(this).balance;
        investor = sellData.buyer;
        boughtValue = sellData.value;
        sellData.buyer = address(0);
        sellData.value = uint256(0);
        currentInvestor.transfer(_value);
        emit LogWithdrawal(currentInvestor, investor, _value);
        return true;
    }

    /**
     * @dev Require collateral tokens of the investment made
     * @return Success
     */
    function requireTokenFuel()
        protocolOrInvestor
        hasStatus(Status.INVESTED)
        onlyDelayed
        external
        returns(bool)
    {
        return withdrawTokens(investor, tokenFuel);
    }

    /**
     * @dev Return investment. Refunds pending buyer if the asset is for sale and handle remaining collateral tokens according to 
     * the period of return
     * @return Success
     */
    function returnInvestment() payable
        protocolOrOwner
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
            sellData.buyer.transfer(address(this).balance.sub(msg.value));
        }
        investor.transfer(msg.value);
        emit LogReturned(owner, investor, msg.value, _isDelayed);
        return true;
    }

    /**
     * @dev Refund investor, clear investment values and become available 
     * @return A tuple with the old investor and the refunded value
     */ 
    function makeAvailable()
        private
        returns(address, uint256)
    {
        status = Status.AVAILABLE;
        uint256 investedValue = address(this).balance;
        address currentInvestor = investor;
        investor = address(0);
        investedAt = uint(0);
        currentInvestor.transfer(investedValue);
        return (currentInvestor, investedValue);
    }

    /**
     * @dev Withdraw collateral tokens
     * @param _recipient Address to send tokens
     * @param _amount Tokens amount
     * @return Success
     */
    function withdrawTokens(address _recipient, uint256 _amount)
        private
        returns(bool)
    {
        assert(tokenFuel >= _amount);
        tokenFuel = tokenFuel.sub(_amount);
        require(token.transfer(_recipient, _amount), "An error ocurred in tokens transfer");
        emit LogTokenWithdrawal(_recipient, _amount);
        return true;
    }

    /**
     * @dev Returns true if the return of investment is delayed according to the investment date and payback period 
     * @return Delay verification
     */ 
    function isDelayed()
        view
        internal
        returns(bool)
    {
        return now > investedAt + paybackDays * 1 days;
    }
}

