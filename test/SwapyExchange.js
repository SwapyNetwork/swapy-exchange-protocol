const should = require('chai')
    .use(require('chai-as-promised'))
    .should()

const SwapyExchange = artifacts.require("./SwapyExchange.sol");
const InvestmentAsset = artifacts.require("./investment/InvestmentAsset.sol");

const currentVersion = "1.0.0";
const agreementTerms = "222222";
const investor = process.env.WALLET_ADDRESS;
const payback = 24;
const grossReturn = 5;
const assetValue = 10;
const assets = [10];
let assetAddress = [];
const currency = "USD";
const offerFixedValue = 10;
const offerTerms = "111111";

// Example of an event uuid 
const eventId = 'f6e6b40a-adea-11e7-abc4-cec278b6b50a';
// ... more code
contract('SwapyExchange', accounts => {
  
    let protocol = null;

  it("should has a version", async () => {
    protocol = await SwapyExchange.deployed();
    let version = await protocol.VERSION.call();
    assert.equal(version, currentVersion, "the protocol is not versioned")
  })

  it("should create an investment offer and log it", done => {
    protocol.Offers({_id: eventId}).watch((err,log) => {
        // @todo treat event
        done();
    });
    const transaction = protocol.createOffer(
        eventId,
        payback,
        grossReturn,
        currency,
        offerFixedValue,
        offerTerms,
        assets
    ).then(transaction => {
        should.exist(transaction.tx);
    });
  })

  it('should add an investment', async () => {
    let assetContract = await InvestmentAsset.at(assetAddress[0]);
    const investment = await assetContract.invest(eventId, agreementTerms)
        .then(async result => {
            should.exist(result.tx)
            return true;
        }, error => {
            console.log(error);
        })
        .then(async () => {
            const filter = await assetContract.Transferred();
            const event = await filter.get((err,result) => {
                console.log(err);
                console.log(result);
            });
        });
  })

  it('should log when add investment', async () => {
    let assetContract = await InvestmentAsset.at(assetAddress[0]);
    let investment = await assetContract.Transferred()
    await  investment.get((err, logs) => {
        return logs.forEach(logs => console.log(log.args))
    });
  })

  

})