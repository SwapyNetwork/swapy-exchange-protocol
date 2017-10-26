// --- Contracts
let SwapyExchange   = artifacts.require("./SwapyExchange.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(SwapyExchange)
    .then(() => {
      SwapyExchange
        .deployed()
        .then(console.log);
    });
};
