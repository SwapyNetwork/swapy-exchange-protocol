const SwapyExchange = artifacts.require("./SwapyExchange.sol");
const currentVersion = "1.0.0";
// ... more code
contract('SwapyExchange', accounts => {
 
  it("should has a version", async function() {
    let protocol = await SwapyExchange.deployed();
    let version = await protocol.VERSION.call();
    assert.equal(version, currentVersion, "the protocol is not versioned")
  });

})