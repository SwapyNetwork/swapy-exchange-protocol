pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/investment/InvestmentAsset.sol";
import "../contracts/SwapyExchange.sol";
import "./helpers/ThrowProxy.sol";
import "./AssetCall.sol";

contract TestInvestmentAsset_marketplace {
    
    SwapyExchange protocol = SwapyExchange(DeployedAddresses.SwapyExchange());
    
    address token = protocol.token();
    bytes8 version = protocol.latestVersion();
    address _library = protocol.getLibrary(version);

    InvestmentAsset assetInstance = new InvestmentAsset(
        _library,
        address(protocol),
        address(this),
        version,
        bytes5("USD"),
        uint256(500),
        uint256(360),
        uint256(10),
        token
    );

    ThrowProxy throwProxy = new ThrowProxy(address(assetInstance)); 
    
    AssetCall asset = new AssetCall(address(assetInstance));
    AssetCall throwableAsset = new AssetCall(address(throwProxy));

    // Truffle looks for `initialBalance` when it compiles the test suite 
    // and funds this test contract with the specified amount on deployment.
    uint public initialBalance = 10 ether;

    function() payable public {
        
    }

    function shouldThrow(bool result) public {
        Assert.isFalse(result, "Should throw an exception");
    }

     // Testing sell() function
    function testOnlyInvestorCanPutOnSale() public {
        asset.invest.value(1 ether)(false);
        withdrawFunds(address(assetInstance));
        bool result = throwableAsset.sell(uint256(525));
        throwProxy.shouldThrow();
    }

    function testInvestorCanPutOnSale() public {
        bool result = asset.sell(uint256(525));
        Assert.equal(result, true, "Asset must be put up on sale");
        InvestmentAsset.Status currentStatus = assetInstance.status();
        bool isForSale = currentStatus == InvestmentAsset.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing cancelSellOrder() function
    function testOnlyInvestorCanRemoveOnSale() public {
        bool result = throwableAsset.cancelSellOrder();
        throwProxy.shouldThrow();
    }

    function testInvestorCanRemoveOnSale() public {
        bool result = asset.cancelSellOrder();
        Assert.equal(result, true, "Asset must be removed for sale");
        InvestmentAsset.Status currentStatus = assetInstance.status();
        bool isInvested = currentStatus == InvestmentAsset.Status.INVESTED;
        Assert.equal(isInvested, true, "The asset must be invested");
    }
    
    // Testing buy() function
    function testBuyerAddressMustBeValid() {
        asset.sell(uint256(525));
        bool result = throwableAsset.buy.value(1050 finney)(true);
        throwProxy.shouldThrow();
    }

    function testUserCanBuyAsset() public {
        uint256 previousBalance = address(this).balance;
        uint256 previousAssetBalance = address(assetInstance).balance;
        bool result = asset.buy.value(1050 finney)(false);
        Assert.equal(result, true, "Asset must be bought");
        InvestmentAsset.Status currentStatus = assetInstance.status();
        bool isPendingSale = currentStatus == InvestmentAsset.Status.PENDING_INVESTOR_AGREEMENT;
        Assert.equal(isPendingSale, true, "The asset must be locked on market place");
        Assert.equal(
            previousBalance - address(this).balance,
            address(assetInstance).balance - previousAssetBalance,
            "balance changes must be equal"
        );
    }

    // Testing cancelSale() function
    function testOnlyBuyerCanCancelPurchase() public {
        bool result = throwableAsset.cancelSale();       
        throwProxy.shouldThrow();
    }

    function testBuyerCanCancelPurchase() public {
        bool result = asset.cancelSale();
        Assert.equal(result, true, "Purchase must be canceled");
        InvestmentAsset.Status currentStatus = assetInstance.status();
        bool isForSale = currentStatus == InvestmentAsset.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing refuseSale() function
    function testOnlyInvestorCanRefusePurchase() public {
        asset.buy.value(1050 finney)(false);
        bool result = throwableAsset.refuseSale();
        throwProxy.shouldThrow();
    }
    
    function testInvestorCanRefusePurchase() public {
        bool result = asset.refuseSale();
        Assert.equal(result, true, "Purchase must be refused");
        InvestmentAsset.Status currentStatus = assetInstance.status();
        bool isForSale = currentStatus == InvestmentAsset.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing acceptSale() function
    function testOnlyInvestorCanAcceptSale() public {
        asset.buy.value(1050 finney)(false);
        bool result = throwableAsset.acceptSale();   
        throwProxy.shouldThrow();
    }

    function testInvestorCanAcceptSale() public {
        uint256 previousBalance = address(asset).balance;
        uint256 previousAssetBalance = address(assetInstance).balance;
        bool result = asset.acceptSale();
        Assert.equal(result, true, "Sale must be accepted");
        InvestmentAsset.Status currentStatus = assetInstance.status();
        bool isInvested = currentStatus == InvestmentAsset.Status.INVESTED;
        Assert.equal(isInvested, true, "The asset must be invested");
        Assert.equal(
            address(asset).balance - previousBalance,
            previousAssetBalance - address(assetInstance).balance,
            "balance changes must be equal"
        );
    }

    function withdrawFunds(address _asset) returns(bool) {
        return _asset.call(abi.encodeWithSignature("withdrawFunds()"));
    }

}


   
