// --- Contracts

let InvestmentOffer = artifacts.require("./protocol/InvestmentOffer.sol");
let InvestmentAsset = artifacts.require("./protocol/InvestmentAsset.sol");
let SwapyExchange   = artifacts.require("./protocol/SwapyExchange.sol");

// --- Reference values

/* Example of an agreement terms hash 
 * that represents a document signed by the asset owner and buyer  
 **/ 
const terms = "111111";
const investor = process.env.WALLET_ADDRESS;
const payback = 24;
const grossReturn = 5;
const assetValue = 10;
const assets = [10,10,10,10,10];

module.exports = function(deployer, network, accounts) {
  deployer.deploy(SwapyExchange)
    .then(() => {
      SwapyExchange
        .deployed()
        .then(instance => {
          let protocol = instance;
          protocol.Offers().watch((err,response) => {
            if(!err){
              console.log('Offer created...');
              console.log(response.args);
              let offerAddress = response.args._offerAddress;
              let deployedAssets = response.args._assets;
              let assetAddress = deployedAssets[0];
              let asset = InvestmentAsset.at(assetAddress);
              let agreeInvestment = asset.Agreements().watch((err,response) => {
                if(!err){
                  console.log('Investment Agreed...');
                  console.log(response.args);
                  asset.Transferred().watch((err,response) => {
                    if(!err){
                      console.log('Asset invested...');
                      console.log(response.args);
                    }
                  });
                  asset.transferFunds(terms,{value: assetValue});
                }
              });
              asset.agreeInvestment(investor, terms, assetValue);
            }
          });
          protocol.createOffer(payback, grossReturn, assets);  
        });
    });
};
