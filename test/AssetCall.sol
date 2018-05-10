pragma solidity ^0.4.23;

import "../contracts/investment/InvestmentAsset.sol";

contract AssetCall {

    address self;

    constructor(address assetAddress){
        self = assetAddress;
    }

    function () payable public {

    }

    function cancelInvestment() public returns(bool) {
        return self.call(abi.encodeWithSignature("cancelInvestment()"));
    }

    function invest(bool invalid) payable returns(bool) {
        if(invalid) {
            return self.call.value(msg.value)(abi.encodeWithSignature("invest(address)", address(0)));
        }else{
            return self.call.value(msg.value)(abi.encodeWithSignature("invest(address)", address(this)));
        }   
    }

    function sell(uint256 value) public returns(bool) {
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

    function cancelSale() public returns(bool) {
        return self.call(abi.encodeWithSignature("cancelSale()"));
    }
    
    function refuseSale() public returns(bool) {
        return self.call(abi.encodeWithSignature("refuseSale()"));
    }
    
    function acceptSale() public returns(bool) {
        return self.call(abi.encodeWithSignature("acceptSale()"));
    }
}
