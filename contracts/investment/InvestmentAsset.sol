pragma solidity ^0.4.15;


// Defines a fund raising asset contract

contract InvestmentAsset {

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

    // possible stages of an asset
    enum Status {
        AVAILABLE,
        PENDING_OWNER_AGREEMENT,
        INVESTED,
        RETURNED,
        DELAYED_RETURN
    }
    Status public status;

    event Transferred(
        address _from,
        address _to,
        uint256 _value
    );

    event Canceled(
        address _owner,
        address _investor,
        uint256 _value
    );

    event Withdrawal(
        address _owner,
        address _investor,
        uint256 _value,
        bytes _terms
    );

    event Refused(
        address _owner,
        address _investor,
        uint256 _value
    );

    event Returned(
        address _owner,
        address _investor,
        uint256 _value,
        Status _status
    );

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

    // Compares the agreement terms hash of investor and owner
    modifier onlyAgreed(bytes _agreementHash) {
        require(keccak256(agreementHash) == keccak256(_agreementHash));
        _;
    }

    function InvestmentAsset(
        address _owner,
        string _protocolVersion,
        string _currency,
        uint256 _fixedValue,
        bytes _assetTermsHash,
        uint _paybackDays,
        uint _grossReturn)
        public
    {
        owner = _owner;
        protocolVersion = _protocolVersion;
        currency = _currency;
        fixedValue = _fixedValue;
        assetTermsHash = _assetTermsHash;
        paybackDays = _paybackDays;
        grossReturn = _grossReturn;
        status = Status.AVAILABLE;
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
        agreementHash = "";
        status = Status.AVAILABLE;
        investedAt = uint(0);
        return (currentInvestor, investedValue);
    }

    // Add investment interest in this asset and retain the funds within the smart contract
    function invest( bytes _agreementHash) payable
         hasStatus(Status.AVAILABLE)
         public
         returns(bool)
    {
        investor = msg.sender;
        agreementHash = _agreementHash;
        investedAt = now;
        status = Status.PENDING_OWNER_AGREEMENT;
        Transferred(investor, owner, this.balance);
        return true;
    }

    // Cancel the pending investment
    function cancelInvestment()
        onlyInvestor
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        public
        returns(bool)
    {
        var (currentInvestor, investedValue) = makeAvailable();
        Canceled(owner, currentInvestor, investedValue);
        return true;
    }

    // Accept the investor as the asset buyer and withdraw funds
    function withdrawFunds(bytes _agreementHash)
        onlyOwner
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        onlyAgreed(_agreementHash)
        public
        returns(bool)
    {
        uint256 value = this.balance;
        owner.transfer(value);
        status = Status.INVESTED;
        Withdrawal(owner, investor, value, agreementHash);
        return true;
    }

    // Refuse the pending investment
    function refuseInvestment()
        onlyOwner
        hasStatus(Status.PENDING_OWNER_AGREEMENT)
        public
        returns(bool)
    {
        var (currentInvestor, investedValue) = makeAvailable();
        Refused(owner, currentInvestor, investedValue);
        return true;
    }

    function returnInvestment() payable
        onlyOwner
        hasStatus(Status.INVESTED)
        public
        returns(bool)
    {
        investor.transfer(msg.value);
        if (now > investedAt + paybackDays * 1 days) {
            status = Status.DELAYED_RETURN;
        } else {
            status = Status.RETURNED;
        }
        Returned(owner, investor, msg.value, status);
        return true;
    }

    function getAsset()
        public
        constant
        returns(address, string, uint256, uint256, uint256, Status, address, string, bytes, bytes, uint)
    {
        return (owner, currency, fixedValue, paybackDays, grossReturn, status, investor, protocolVersion, assetTermsHash, agreementHash, investedAt);
    }

}
