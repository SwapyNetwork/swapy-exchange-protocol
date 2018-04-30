pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "../contracts/SwapyExchange.sol";
import "./helpers/ThrowProxy.sol";

contract TestSwapyExchange_versioning {
    SwapyExchange protocol = new SwapyExchange(address(0x281055afc982d96fab65b3a49cac8b878184cb16),"1.0.0",address(0x6f46cf5569aefa1acc1009290c8e043747172d89));
    ThrowProxy throwProxy = new ThrowProxy(address(protocol)); 
    SwapyExchange throwableProtocol = SwapyExchange(address(throwProxy));

    // Truffle looks for `initialBalance` when it compiles the test suite 
    // and funds this test contract with the specified amount on deployment.
    uint public initialBalance = 10 ether;

    function shouldThrow(bool execution) private {
        Assert.isFalse(execution, "Should throw an exception");
    }
    // Testing the addLibrary() function
    function testOnlyProtocolOwnerCanAddLibrary() public {
        address lib2 = address(0x8f46cf5569aefa1acc1009290c8e043747172d45);
        address(throwableProtocol).call(abi.encodeWithSignature("addLibrary(bytes8,address)", bytes8("3.0.0"), lib2));
        throwProxy.shouldThrow();
    }

    function testProtocolOwnerCanAddLibraryVersion() public {
        address lib3 = address(0x9f46cf5569aefa1acc1009290c8e043747172d45);
        bool result = protocol.addLibrary(bytes8("3.0.0"), lib3);
        bytes8 latestVersion = protocol.latestVersion();
        address latestLib = protocol.getLibrary(latestVersion);
        bool check = (latestVersion == bytes8("3.0.0")) && (latestLib == address(lib3));
        Assert.equal(check, true, "The latest version must be 3.0.0 and the library address of this version must be equal the lastest deployed library");
    }

    function testOwnerCannotAddDuplicatedVersion() public {
        address lib3 = address(0x9f46cf5569aefa1acc1009290c8e043747172d45);
        bool result = address(protocol).call(abi.encodeWithSignature("addLibrary(bytes8,address)", bytes8("3.0.0"), lib3));
        shouldThrow(result);
    }

    function testOwnerCannotAddInvalidLibrary() public {
        bool result = address(protocol).call(abi.encodeWithSignature("addLibrary(bytes8,address)", bytes8("3.0.0"), address(0)));
        shouldThrow(result);
    }



}