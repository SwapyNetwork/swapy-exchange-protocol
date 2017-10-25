// --- Contracts

let InvestmentOffer = artifacts.require("./protocol/InvestmentOffer.sol");
let InvestmentAsset = artifacts.require("./protocol/InvestmentAsset.sol");
let SwapyExchange   = artifacts.require("./protocol/SwapyExchange.sol");

// --- Reference values

/* Example of an agreement terms hash 
 * that represents a document signed by the asset owner and buyer  
 **/ 
const agreementTerms = "222222";
const investor = process.env.WALLET_ADDRESS;
const payback = 24;
const grossReturn = 5;
const assetValue = 10;
const assets = [10,10,10,10,10];
const currency = "USD";
const offerFixedValue = 50;
const offerTerms = "111111";

// Example of an event uuid 
const eventId = 'f6e6b40a-adea-11e7-abc4-cec278b6b50a';

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
              asset.Transferred().watch((err,response) => {
                if(!err){
                  console.log('Funds transferred by investor...');
                  console.log(response.args);
                  asset.Withdrawal().watch((err,response) => {
                    if(!err){
                      console.log('Investment agreed and funds withdrawal by credit co. ...');
                      console.log(response.args);
                    }
                  });
                  asset.withdrawFunds(
                    eventId,
                    agreementTerms
                  );
                }
              });
              asset.invest(
                eventId,
                agreementTerms,
                {value: assetValue}
              );
            }
          });
          protocol.createOffer(
            eventId,
            payback,
            grossReturn,
            currency,
            offerFixedValue,
            offerTerms,
            assets
          );  
        });
    });
};
