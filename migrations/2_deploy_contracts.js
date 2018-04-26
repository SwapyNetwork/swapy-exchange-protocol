// --- Contracts
let SwapyExchange = artifacts.require("./SwapyExchange.sol")
let AssetLibrary = artifacts.require("./investment/AssetLibrary.sol")
let Token = artifacts.require("./token/Token.sol")

module.exports = function(deployer, network, accounts) {
    if(network.indexOf('test') > -1) {
        deployer.deploy(Token).then(() => {
            return deployer.deploy(AssetLibrary).then(() => {  
                return deployer.deploy(SwapyExchange, Token.address, "1.0.0", AssetLibrary.address)
            })
        })
    }else {
        deployer.deploy(AssetLibrary).then(() => {  
            return deployer.deploy(SwapyExchange, process.env.TOKEN_ADDRESS, "1.0.0", AssetLibrary.address)
        })
    }
}
