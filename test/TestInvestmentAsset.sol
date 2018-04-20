pragma solidity ^0.4.21;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/investment/InvestmentAsset.sol";
import "../contracts/investment/AssetLibrary.sol";
import "./helpers/ThrowProxy.sol";

contract TestInvestmentAsset {
    
    InvestmentAsset baseInstance = new InvestmentAsset(
        DeployedAddresses.AssetLibrary(),
        DeployedAddresses.SwapyExchange(),
        address(this),
        bytes8("T-1.0.0"),
        bytes5("USD"),
        uint256(500),
        uint256(360),
        uint256(10),
        DeployedAddresses.Token()
    );

    AssetLibrary asset = AssetLibrary(address(baseInstance));

    ThrowProxy throwProxy = new ThrowProxy(address(asset)); 
    AssetLibrary throwableAsset = AssetLibrary(address(asset));

    // Truffle looks for `initialBalance` when it compiles the test suite 
    // and funds this test contract with the specified amount on deployment.
    uint public initialBalance = 10 ether;
    
    // Testing invest() function
    function testUserCanInvest() public {
        bool result = asset.invest.value(1 ether)(address(this));
        Assert.equal(result, true, "Asset must be invested");
        AssetLibrary.Status currentStatus = asset.status();
        bool isPending = currentStatus == AssetLibrary.Status.PENDING_OWNER_AGREEMENT;
        Assert.equal(isPending, true, "The asset must be locked for investments");
    }
    
    // Testing cancelInvestment() function
    function testInvestorCanCancelInvestment() public {
        bool result = asset.cancelInvestment();
        Assert.equal(result, true, "Investment must be canceled");
        AssetLibrary.Status currentStatus = asset.status();
        bool isAvailable = currentStatus == AssetLibrary.Status.AVAILABLE;
        Assert.equal(isAvailable, true, "The asset must be available for investments");
    }
    
    // Testing refuseInvestment() function
    function testOwnerCanRefuseInvestment() public {
        asset.invest.value(1 ether)(address(this));
        bool result = asset.refuseInvestment();
        Assert.equal(result, true, "Investment must be refused");
        AssetLibrary.Status currentStatus = asset.status();
        bool isAvailable = currentStatus == AssetLibrary.Status.AVAILABLE;
        Assert.equal(isAvailable, true, "The asset must be available for investments");
    }

    // Testing withdrawFunds() function
    function testOwnerCanWithdrawFunds() public {
        asset.invest.value(1 ether)(address(this));
        bool result = asset.withdrawFunds();
        Assert.equal(result, true, "Investment must be accepted");
        AssetLibrary.Status currentStatus = asset.status();
        bool isInvested = currentStatus == AssetLibrary.Status.INVESTED;
        Assert.equal(isInvested, true, "The asset must be invested");
    }

    // Testing sell() function
    function testInvestorCanPutOnSale() public {
        bool result = asset.sell(uint256(525));
        Assert.equal(result, true, "Asset must be put up on sale");
        AssetLibrary.Status currentStatus = asset.status();
        bool isForSale = currentStatus == AssetLibrary.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing cancelSellOrder() function
    function testInvestorCanRemoveOnSale() public {
        bool result = asset.cancelSellOrder();
        Assert.equal(result, true, "Asset must be removed for sale");
        AssetLibrary.Status currentStatus = asset.status();
        bool isInvested = currentStatus == AssetLibrary.Status.INVESTED;
        Assert.equal(isInvested, true, "The asset must be invested");
    }
    
    // Testing buy() function
    function testUserCanBuyAsset() public {
        asset.sell(uint256(525));
        bool result = asset.buy.value(1050 finney)(address(this));
        Assert.equal(result, true, "Asset must be bought");
        AssetLibrary.Status currentStatus = asset.status();
        bool isPendingSale = currentStatus == AssetLibrary.Status.PENDING_INVESTOR_AGREEMENT;
        Assert.equal(isPendingSale, true, "The asset must be locked on market place");
    }

    // Testing cancelSale() function
    function testBuyerCanCancelPurchase() public {
        bool result = asset.cancelSale();
        Assert.equal(result, true, "Purchase must be canceled");
        AssetLibrary.Status currentStatus = asset.status();
        bool isForSale = currentStatus == AssetLibrary.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing refuseSale() function
    function testInvestorCanRefusePurchase() public {
        bool result = asset.refuseSale();
        Assert.equal(result, true, "Purchase must be refused");
        AssetLibrary.Status currentStatus = asset.status();
        bool isForSale = currentStatus == AssetLibrary.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing acceptSale() function
    function testInvestorCanAcceptSale() public {
        bool result = asset.acceptSale();
        Assert.equal(result, true, "Sale must be accepted");
        AssetLibrary.Status currentStatus = asset.status();
        bool isInvested = currentStatus == AssetLibrary.Status.INVESTED;
        Assert.equal(isInvested, true, "The asset must be invested");
    }

}