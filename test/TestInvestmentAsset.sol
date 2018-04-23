pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/investment/InvestmentAsset.sol";
import "../contracts/investment/AssetLibrary.sol";
import "./helpers/ThrowProxy.sol";

contract TestInvestmentAsset {

    InvestmentAsset asset = new InvestmentAsset(
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

    ThrowProxy throwProxy = new ThrowProxy(address(asset)); 
    InvestmentAsset throwableAsset = InvestmentAsset(address(asset));

    // Truffle looks for `initialBalance` when it compiles the test suite 
    // and funds this test contract with the specified amount on deployment.
    uint public initialBalance = 10 ether;
    
    // Testing invest() function
    function testUserCanInvest() public {
        bool result = address(asset).call.value(1 ether)(abi.encodeWithSignature("invest(address)", address(this)));
        Assert.equal(result, true, "Asset must be invested");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isPending = currentStatus == InvestmentAsset.Status.PENDING_OWNER_AGREEMENT;
        Assert.equal(isPending, true, "The asset must be locked for investments");
    }
    
    // Testing cancelInvestment() function
    function testInvestorCanCancelInvestment() public {
        bool result = address(asset).call(abi.encodeWithSignature("cancelInvestment()"));
        Assert.equal(result, true, "Investment must be canceled");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isAvailable = currentStatus == InvestmentAsset.Status.AVAILABLE;
        Assert.equal(isAvailable, true, "The asset must be available for investments");
    }
    
    // Testing refuseInvestment() function
    function testOwnerCanRefuseInvestment() public {
        address(asset).call.value(1 ether)(abi.encodeWithSignature("invest(address)", address(this)));
        bool result = address(asset).call(abi.encodeWithSignature("refuseInvestment()"));
        Assert.equal(result, true, "Investment must be refused");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isAvailable = currentStatus == InvestmentAsset.Status.AVAILABLE;
        Assert.equal(isAvailable, true, "The asset must be available for investments");
    }

    // Testing withdrawFunds() function
    function testOwnerCanWithdrawFunds() public {
        address(asset).call.value(1 ether)(abi.encodeWithSignature("invest(address)", address(this)));
        bool result = address(asset).call(abi.encodeWithSignature("withdrawFunds()"));
        Assert.equal(result, true, "Investment must be accepted");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isInvested = currentStatus == InvestmentAsset.Status.INVESTED;
        Assert.equal(isInvested, true, "The asset must be invested");
    }

    // Testing sell() function
    function testInvestorCanPutOnSale() public {
        bool result = address(asset).call(abi.encodeWithSignature("sell()",uint256(525)));
        Assert.equal(result, true, "Asset must be put up on sale");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isForSale = currentStatus == InvestmentAsset.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing cancelSellOrder() function
    function testInvestorCanRemoveOnSale() public {
        bool result = address(asset).call(abi.encodeWithSignature("cancelSellOrder()"));
        Assert.equal(result, true, "Asset must be removed for sale");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isInvested = currentStatus == InvestmentAsset.Status.INVESTED;
        Assert.equal(isInvested, true, "The asset must be invested");
    }
    
    // Testing buy() function
    function testUserCanBuyAsset() public {
        address(asset).call(abi.encodeWithSignature("sell(uint256)", uint256(525)));
        bool result = address(asset).call.value(1050 finney)(abi.encodeWithSignature("buy(address)", address(this)));
        Assert.equal(result, true, "Asset must be bought");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isPendingSale = currentStatus == InvestmentAsset.Status.PENDING_INVESTOR_AGREEMENT;
        Assert.equal(isPendingSale, true, "The asset must be locked on market place");
    }

    // Testing cancelSale() function
    function testBuyerCanCancelPurchase() public {
        bool result = address(asset).call(abi.encodeWithSignature("cancelSale()"));
        Assert.equal(result, true, "Purchase must be canceled");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isForSale = currentStatus == InvestmentAsset.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing refuseSale() function
    function testInvestorCanRefusePurchase() public {
        bool result = address(asset).call(abi.encodeWithSignature("refuseSale()"));
        Assert.equal(result, true, "Purchase must be refused");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isForSale = currentStatus == InvestmentAsset.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing acceptSale() function
    function testInvestorCanAcceptSale() public {
        bool result = address(asset).call(abi.encodeWithSignature("acceptSale()"));
        Assert.equal(result, true, "Sale must be accepted");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isInvested = currentStatus == InvestmentAsset.Status.INVESTED;
        Assert.equal(isInvested, true, "The asset must be invested");
    }

}