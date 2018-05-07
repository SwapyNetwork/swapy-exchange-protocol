pragma solidity ^0.4.23;

import "../contracts/investment/InvestmentAsset.sol";

contract AssetCall {

    address self;

    constructor(address assetAddress){
        self = assetAddress;
    }

    function () payable public {

    }

    function createAsset(
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
        returns (InvestmentAsset assetInstance)
    {
        assetInstance = new InvestmentAsset(_library,_protocol,_owner,_protocolVersion,_currency,_value,_paybackDays,_grossReturn,_token);
        self = address(assetInstance);
    }

    
    function cancelInvestment() returns(bool) {
        return self.call(abi.encodeWithSignature("cancelInvestment()"));
    }

    function refuseInvestment() returns(bool) {
        return self.delegatecall(abi.encodeWithSignature("refuseInvestment()"));
    }

    function withdrawFunds() returns(bool) {
        return self.delegatecall(abi.encodeWithSignature("withdrawFunds()"));
    }

    function invest(bool invalid) payable returns(bool) {
        if(invalid) {
            return self.call.value(msg.value)(abi.encodeWithSignature("invest(address)", address(0)));
        }else{
            return self.call.value(msg.value)(abi.encodeWithSignature("invest(address)", address(this)));
        }   
    }

    function returnInvestment() payable returns(bool) {
        return self.delegatecall(abi.encodeWithSignature("returnInvestment()"));
    }

    function sell(uint256 value) returns(bool) {
        return self.call(abi.encodeWithSignature("sell(uint256)", value));
    }

    function cancelSellOrder() returns(bool) {
        return self.call(abi.encodeWithSignature("cancelSellOrder()"));
    }

    function buy(bool invalid) payable returns(bool) {
        if(invalid) {
             return self.call.value(msg.value)(abi.encodeWithSignature("buy(address)", address(0)));
        }else{
            return self.call.value(msg.value)(abi.encodeWithSignature("buy(address)", address(this)));
        } 
    }

    function cancelSale() returns(bool) {
        return self.call(abi.encodeWithSignature("cancelSale()"));
    }
    
    function refuseSale() returns(bool) {
        return self.call(abi.encodeWithSignature("refuseSale()"));
    }
    
    function acceptSale() returns(bool) {
        return self.call(abi.encodeWithSignature("acceptSale()"));
    }
}
