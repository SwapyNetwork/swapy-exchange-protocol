pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SwapyExchange.sol";
import "./helpers/ThrowProxy.sol";

contract TestSwapyExchange {
    
    SwapyExchange protocol = SwapyExchange(DeployedAddresses.SwapyExchange());
    ThrowProxy throwProxy = new ThrowProxy(address(protocol)); 
    SwapyExchange throwableProtocol = SwapyExchange(address(throwProxy));
    uint256[] _assetValues;
    address[] assets;

    // Truffle looks for `initialBalance` when it compiles the test suite 
    // and funds this test contract with the specified amount on deployment.
    uint public initialBalance = 10 ether;

    function() payable public {
        
    }

    // Testing the createOffer() function
    function testUserCanCreateOffer() public {
        _assetValues.push(uint256(500));
        _assetValues.push(uint256(500));
        _assetValues.push(uint256(500));
        assets = protocol.createOffer(
            uint256(360),
            uint256(10),
            bytes5("USD"),
            _assetValues
        );
        Assert.equal(assets.length, 3, "3 Assets must be created");
    }
    
    // testing invest() function
    function testUnitValueAndFundsMustMatch() {
        address(throwableProtocol).call.value(2 ether)(abi.encodeWithSignature("invest(address[], uint256)", assets, 1 ether));
        throwProxy.shouldThrow();
    }

    function testUserCanInvest() public {
        bool result = protocol.invest.value(3 ether)(assets, 1 ether);
        Assert.equal(result, true, "Assets must be invested");
    }
    
    // Testing cancelInvestment() function
    function testOnlyInvestorCanCancelInvestment() public {
        address(throwableProtocol).call(abi.encodeWithSignature("cancelInvestment(address[])", assets));
        throwProxy.shouldThrow();
    }

    function testInvestorCanCancelInvestment() public {
        bool result = protocol.cancelInvestment(assets);
        Assert.equal(result, true, "Investments must be canceled");
    }
    
    // Testing refuseInvestment() function
    function testOnlyOwnerCanRefuseInvestment() public {
        protocol.invest.value(3 ether)(assets, 1 ether);
        address(throwableProtocol).call(abi.encodeWithSignature("refuseInvestment(address[])", assets));
        throwProxy.shouldThrow();
    }
    
    function testOwnerCanRefuseInvestment() public {
        bool result = protocol.refuseInvestment(assets);
        Assert.equal(result, true, "Investments must be refused");
    }

    // Testing withdrawFunds() function
    function testOnlyOwnerCanWithdrawFunds() public {
        protocol.invest.value(3 ether)(assets, 1 ether);
        address(throwableProtocol).call(abi.encodeWithSignature("withdrawFunds(address[])", assets));
        throwProxy.shouldThrow();
    }
    
    function testOwnerCanWithdrawFunds() public {
        bool result = protocol.withdrawFunds(assets);
        Assert.equal(result, true, "Investments must be accepted");
    }

    // Testing sell() function
    
    function testOnlyInvestorCanPutOnSale() public {
        _assetValues[0] += 25;
        _assetValues[1] += 25;
        _assetValues[2] += 25;
        address(throwableProtocol).call(abi.encodeWithSignature("sellAssets(address[],uint256[])",assets, _assetValues));
        throwProxy.shouldThrow();
    }

    function testInvestorCanPutOnSale() public {
        bool result = protocol.sellAssets(assets,  _assetValues);
        Assert.equal(result, true, "Assets must be put up on sale");
    }

    // Testing cancelSellOrder() function
    function testOnlyInvestorCanRemoveOnSale() public {
        address(throwableProtocol).call(abi.encodeWithSignature("cancelSellOrder(address[])", assets));
        throwProxy.shouldThrow();
    }

    function testInvestorCanRemoveOnSale() public {
        bool result = protocol.cancelSellOrder(assets);
        Assert.equal(result, true, "Asset must be removed for sale");
    }
    
    // Testing buy() function

    function testUserCanBuyAsset() public {
        protocol.sellAssets(assets,  _assetValues);
        bool result = protocol.buyAsset.value(1050 finney)(assets[0]);
        Assert.equal(result, true, "Asset must be bought");
    }

    // Testing cancelSale() function
    function testOnlyBuyerCanCancelPurchase() public {
        protocol.buyAsset.value(1050 finney)(assets[1]);
        protocol.buyAsset.value(1050 finney)(assets[2]);
        address(throwableProtocol).call(abi.encodeWithSignature("cancelSale(address[])", assets));
        throwProxy.shouldThrow();
    }

    function testBuyerCanCancelPurchase() public {
        bool result = protocol.cancelSale(assets);
        Assert.equal(result, true, "Purchase must be canceled");
    }

    // // Testing refuseSale() function
    // function testOnlyInvestorCanRefusePurchase() public {
    //     address(asset).call.value(1050 finney)(abi.encodeWithSignature("buy(address)", address(this)));
    //     address(throwableAsset).call(abi.encodeWithSignature("refuseSale()"));
    //     throwProxy.shouldThrow();
    // }
    
    // function testInvestorCanRefusePurchase() public {
    //     bool result = address(asset).call(abi.encodeWithSignature("refuseSale()"));
    //     Assert.equal(result, true, "Purchase must be refused");
    //     InvestmentAsset.Status currentStatus = asset.status();
    //     bool isForSale = currentStatus == InvestmentAsset.Status.FOR_SALE;
    //     Assert.equal(isForSale, true, "The asset must be available on market place");
    // }

    // // Testing acceptSale() function
    // function testOnlyInvestorCanAcceptSale() public {
    //     address(asset).call.value(1050 finney)(abi.encodeWithSignature("buy(address)", address(this)));
    //     address(throwableAsset).call(abi.encodeWithSignature("acceptSale()"));
    //     throwProxy.shouldThrow();
    // }

    // function testInvestorCanAcceptSale() public {
    //     bool result = address(asset).call(abi.encodeWithSignature("acceptSale()"));
    //     Assert.equal(result, true, "Sale must be accepted");
    //     InvestmentAsset.Status currentStatus = asset.status();
    //     bool isInvested = currentStatus == InvestmentAsset.Status.INVESTED;
    //     Assert.equal(isInvested, true, "The asset must be invested");
    // }

}