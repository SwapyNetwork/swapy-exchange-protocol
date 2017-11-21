// --- Contracts
let SwapyExchange = artifacts.require("./SwapyExchange.sol");
let AssetLibrary = artifacts.require("../investment/AssetLibrary.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(AssetLibrary).then(() => {  
    return deployer.deploy(SwapyExchange, AssetLibrary.address);
  })
};
