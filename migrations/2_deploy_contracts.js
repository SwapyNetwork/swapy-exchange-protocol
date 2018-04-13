// --- Contracts
let SwapyExchange = artifacts.require("./SwapyExchange.sol")
let AssetLibrary = artifacts.require("./investment/AssetLibrary.sol")
let Token = artifacts.require("./token/Token.sol")

module.exports = function(deployer, network, accounts) {
  if(network.indexOf('test') > -1) {
    deployer.deploy(Token).then(() => {
      return deployer.deploy(AssetLibrary).then(() => {  
        return deployer.deploy(SwapyExchange, AssetLibrary.address, Token.address)
      })
    })
  }else {
    deployer.deploy(AssetLibrary).then(() => {  
      return deployer.deploy(SwapyExchange, AssetLibrary.address, process.env.TOKEN_ADDRESS)
    })
  }
}
