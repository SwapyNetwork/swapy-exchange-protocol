pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/investment/InvestmentAsset.sol";
import "../contracts/SwapyExchange.sol";
import "./helpers/ThrowProxy.sol";
import "./AssetCall.sol";

contract TestInvestmentAsset_investment {
    
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
    AssetCall throwableAsset = new AssetCall(address(throwProxy));
    AssetCall asset = new AssetCall(address(assetInstance));
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
        bool result = throwableAsset.invest(true);
        throwProxy.shouldThrow();
    }


    function testUserCanInvest() public {
        uint256 previousBalance = address(this).balance;
        uint256 previousAssetBalance = address(assetInstance).balance;
        bool result = asset.invest.value(1 ether)(false);
        InvestmentAsset.Status currentStatus = assetInstance.status();
        bool isPending = currentStatus == InvestmentAsset.Status.PENDING_OWNER_AGREEMENT;
        Assert.equal(result, true, "Asset must be invested");
        Assert.equal(isPending, true, "The asset must be locked for investments");
        Assert.equal(
            previousBalance - address(this).balance,
            address(assetInstance).balance - previousAssetBalance,
            "balance changes must be equal"
        );
    }
    
    // Testing cancelInvestment() function
    function testOnlyInvestorCanCancelInvestment() public {
        bool result = throwableAsset.cancelInvestment();
        throwProxy.shouldThrow();
    }

    function testInvestorCanCancelInvestment() public {
        uint256 previousBalance = address(asset).balance;
        uint256 previousAssetBalance = address(assetInstance).balance;
        bool result = asset.cancelInvestment();
        InvestmentAsset.Status currentStatus = assetInstance.status();
        bool isAvailable = currentStatus == InvestmentAsset.Status.AVAILABLE;
        Assert.equal(result, true, "Investment must be canceled");
        Assert.equal(isAvailable, true, "The asset must be available for investments");
        Assert.equal(
            address(asset).balance - previousBalance,
            previousAssetBalance - address(assetInstance).balance,
            "balance changes must be equal"
        );
    }
    
    // Testing refuseInvestment() function
    function testOnlyOwnerCanRefuseInvestment() public {
        asset.invest(false);
        bool result = refuseInvestment(address(throwProxy));
        throwProxy.shouldThrow();
    }
    
    function testOwnerCanRefuseInvestment() public {
        uint256 previousBalance = address(asset).balance;
        uint256 previousAssetBalance = address(assetInstance).balance;
        bool result = refuseInvestment(address(assetInstance));
        InvestmentAsset.Status currentStatus = assetInstance.status();
        bool isAvailable = currentStatus == InvestmentAsset.Status.AVAILABLE;
        Assert.equal(result, true, "Investment must be refused");
        Assert.equal(isAvailable, true, "The asset must be available for investments");
        Assert.equal(
            address(asset).balance - previousBalance,
            previousAssetBalance - address(assetInstance).balance,
            "balance changes must be equal"
        );
    }

    // Testing withdrawFunds() function
    function testOnlyOwnerCanWithdrawFunds() public {
        asset.invest(false);
        bool result = withdrawFunds(address(throwProxy));
        throwProxy.shouldThrow();
    }
    
    function testOwnerCanWithdrawFunds() public {
        uint256 previousBalance = address(asset).balance;
        uint256 previousAssetBalance = address(assetInstance).balance;
        bool result = withdrawFunds(address(assetInstance));
        InvestmentAsset.Status currentStatus = assetInstance.status();
        bool isInvested = currentStatus == InvestmentAsset.Status.INVESTED;
        Assert.equal(result, true, "Investment must be accepted");
        Assert.equal(isInvested, true, "The asset must be invested");
        Assert.equal(
            address(asset).balance - previousBalance,
            previousAssetBalance - address(assetInstance).balance,
            "balance changes must be equal"
        );
    }


    // Testing returnInvestment() function
    function testOnlyOwnerCanReturnInvestment() public {
        returnInvestment(address(throwProxy));
        throwProxy.shouldThrow();
    }

    function testOwnerCanReturnInvestment() public {
        uint256 previousBalance = address(asset).balance;
        uint256 previousAssetBalance = address(assetInstance).balance;
        bool result = returnInvestment(address(assetInstance));
        Assert.equal(result, true, "Investment must be returned");
        InvestmentAsset.Status currentStatus = assetInstance.status();
        bool isReturned = currentStatus == InvestmentAsset.Status.RETURNED;
        Assert.equal(isReturned, true, "The asset must be returned");
        Assert.equal(
            address(asset).balance - previousBalance,
            previousAssetBalance - address(assetInstance).balance,
            "balance changes must be equal"
        );
    }

    function refuseInvestment(address _asset) returns(bool) {
        return _asset.call(abi.encodeWithSignature("refuseInvestment()"));
    }

    function withdrawFunds(address _asset) returns(bool) {
        return _asset.call(abi.encodeWithSignature("withdrawFunds()"));
    }

    function returnInvestment(address _asset) payable returns(bool) {
        return _asset.call(abi.encodeWithSignature("returnInvestment()"));
    }

}

