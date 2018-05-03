pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/investment/InvestmentAsset.sol";
import "../contracts/SwapyExchange.sol";
import "./helpers/ThrowProxy.sol";

contract TestInvestmentAsset {
    SwapyExchange protocol = SwapyExchange(DeployedAddresses.SwapyExchange());
    address token = protocol.token();
    bytes8 version = protocol.latestVersion();
    address _library = protocol.getLibrary(version);

    InvestmentAsset asset = new InvestmentAsset(
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

    ThrowProxy throwProxy = new ThrowProxy(address(asset)); 
    InvestmentAsset throwableAsset = InvestmentAsset(address(throwProxy));

    // Truffle looks for `initialBalance` when it compiles the test suite 
    // and funds this test contract with the specified amount on deployment.
    uint public initialBalance = 10 ether;

    function() payable public {
        
    }

    function shouldThrow(bool result) public {
        Assert.isFalse(result, "Should throw an exception");
    }

    // Testing invest() function
    function testInvestorAddressMustBeValid() {
        bool result = address(throwableAsset).call(abi.encodeWithSignature("invest(address)", address(0)));
        throwProxy.shouldThrow();
    }

    function testUserCanInvest() public {
        bool result = address(asset).call.value(1 ether)(abi.encodeWithSignature("invest(address)", address(this)));
        Assert.equal(result, true, "Asset must be invested");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isPending = currentStatus == InvestmentAsset.Status.PENDING_OWNER_AGREEMENT;
        Assert.equal(isPending, true, "The asset must be locked for investments");
    }
    
    // Testing cancelInvestment() function
    function testOnlyInvestorCanCancelInvestment() public {
        bool result = address(throwableAsset).call(abi.encodeWithSignature("cancelInvestment()"));
        throwProxy.shouldThrow();
    }

    function testInvestorCanCancelInvestment() public {
        bool result = address(asset).call(abi.encodeWithSignature("cancelInvestment()"));
        Assert.equal(result, true, "Investment must be canceled");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isAvailable = currentStatus == InvestmentAsset.Status.AVAILABLE;
        Assert.equal(isAvailable, true, "The asset must be available for investments");
    }
    
    // Testing refuseInvestment() function
    function testOnlyOwnerCanRefuseInvestment() public {
        address(asset).call.value(1 ether)(abi.encodeWithSignature("invest(address)", address(this)));
        bool result = address(throwableAsset).call(abi.encodeWithSignature("refuseInvestment()"));
        throwProxy.shouldThrow();
    }
    
    function testOwnerCanRefuseInvestment() public {
        bool result = address(asset).call(abi.encodeWithSignature("refuseInvestment()"));
        Assert.equal(result, true, "Investment must be refused");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isAvailable = currentStatus == InvestmentAsset.Status.AVAILABLE;
        Assert.equal(isAvailable, true, "The asset must be available for investments");
    }

    // Testing withdrawFunds() function
    function testOnlyOwnerCanWithdrawFunds() public {
        address(asset).call.value(1 ether)(abi.encodeWithSignature("invest(address)", address(this)));
        bool result = address(throwableAsset).call(abi.encodeWithSignature("withdrawFunds()"));
        throwProxy.shouldThrow();
    }
    
    function testOwnerCanWithdrawFunds() public {
        bool result = address(asset).call(abi.encodeWithSignature("withdrawFunds()"));
        Assert.equal(result, true, "Investment must be accepted");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isInvested = currentStatus == InvestmentAsset.Status.INVESTED;
        Assert.equal(isInvested, true, "The asset must be invested");
    }

    // Testing sell() function
    function testOnlyInvestorCanPutOnSale() public {
        bool result = address(throwableAsset).call(abi.encodeWithSignature("sell(uint256)",uint256(525)));
        throwProxy.shouldThrow();
    }

    function testInvestorCanPutOnSale() public {
        bool result = address(asset).call(abi.encodeWithSignature("sell(uint256)",uint256(525)));
        Assert.equal(result, true, "Asset must be put up on sale");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isForSale = currentStatus == InvestmentAsset.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing cancelSellOrder() function
    function testOnlyInvestorCanRemoveOnSale() public {
        bool result = address(throwableAsset).call(abi.encodeWithSignature("cancelSellOrder()"));
        throwProxy.shouldThrow();
    }

    function testInvestorCanRemoveOnSale() public {
        bool result = address(asset).call(abi.encodeWithSignature("cancelSellOrder()"));
        Assert.equal(result, true, "Asset must be removed for sale");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isInvested = currentStatus == InvestmentAsset.Status.INVESTED;
        Assert.equal(isInvested, true, "The asset must be invested");
    }
    
    // Testing buy() function
    function testBuyerAddressMustBeValid() {
        address(asset).call(abi.encodeWithSignature("sell(uint256)", uint256(525)));
        bool result = address(throwableAsset).call.value(1050 finney)(abi.encodeWithSignature("buyer(address)", address(0)));
        throwProxy.shouldThrow();
    }

    function testUserCanBuyAsset() public {
        bool result = address(asset).call.value(1050 finney)(abi.encodeWithSignature("buy(address)", address(this)));
        Assert.equal(result, true, "Asset must be bought");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isPendingSale = currentStatus == InvestmentAsset.Status.PENDING_INVESTOR_AGREEMENT;
        Assert.equal(isPendingSale, true, "The asset must be locked on market place");
    }

    // Testing cancelSale() function
    function testOnlyBuyerCanCancelPurchase() public {
        bool result = address(throwableAsset).call(abi.encodeWithSignature("cancelSale()"));
        throwProxy.shouldThrow();
    }

    function testBuyerCanCancelPurchase() public {
        bool result = address(asset).call(abi.encodeWithSignature("cancelSale()"));
        Assert.equal(result, true, "Purchase must be canceled");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isForSale = currentStatus == InvestmentAsset.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing refuseSale() function
    function testOnlyInvestorCanRefusePurchase() public {
        address(asset).call.value(1050 finney)(abi.encodeWithSignature("buy(address)", address(this)));
        bool result = address(throwableAsset).call(abi.encodeWithSignature("refuseSale()"));
        throwProxy.shouldThrow();
    }
    
    function testInvestorCanRefusePurchase() public {
        bool result = address(asset).call(abi.encodeWithSignature("refuseSale()"));
        Assert.equal(result, true, "Purchase must be refused");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isForSale = currentStatus == InvestmentAsset.Status.FOR_SALE;
        Assert.equal(isForSale, true, "The asset must be available on market place");
    }

    // Testing acceptSale() function
    function testOnlyInvestorCanAcceptSale() public {
        address(asset).call.value(1050 finney)(abi.encodeWithSignature("buy(address)", address(this)));
        bool result = address(throwableAsset).call(abi.encodeWithSignature("acceptSale()"));
        throwProxy.shouldThrow();
    }

    function testInvestorCanAcceptSale() public {
        bool result = address(asset).call(abi.encodeWithSignature("acceptSale()"));
        Assert.equal(result, true, "Sale must be accepted");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isInvested = currentStatus == InvestmentAsset.Status.INVESTED;
        Assert.equal(isInvested, true, "The asset must be invested");
    }

    // Testing returnInvestment() function
    function testOnlyOwnerCanReturnInvestment() public {
        address(throwableAsset).call.value(1100 finney)(abi.encodeWithSignature("returnInvestment()"));
        throwProxy.shouldThrow();
    }

    function testOwnerCanReturnInvestment() public {
        bool result = address(asset).call.value(1100 finney)(abi.encodeWithSignature("returnInvestment()"));
        Assert.equal(result, true, "Investment must be returned");
        InvestmentAsset.Status currentStatus = asset.status();
        bool isReturned = currentStatus == InvestmentAsset.Status.RETURNED;
        Assert.equal(isReturned, true, "The asset must be returned");
    }

}
