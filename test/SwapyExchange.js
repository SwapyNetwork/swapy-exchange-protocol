const should = require('chai')
    .use(require('chai-as-promised'))
    .should()

const SwapyExchange = artifacts.require("./SwapyExchange.sol");

const currentVersion = "1.0.0";
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
// ... more code
contract('SwapyExchange', accounts => {
  let protocol = null;
  it("should has a version", async () => {
    protocol = await SwapyExchange.deployed();
    let version = await protocol.VERSION.call();
    assert.equal(version, currentVersion, "the protocol is not versioned")
  });

  it("should create an investment offer", async (done) => {
    return await protocol.createOffer(
        eventId,
        payback,
        grossReturn,
        currency,
        offerFixedValue,
        offerTerms,
        assets
    )
    .then(result => {
       should.exist(result.tx);
    }, error => {
       console.log(error);
    })
    .catch(done);
  });

  it('should log investment offer creation', async  () =>  {
    const event = await protocol.Offers().watch((err,event) => {
        return event;
    });  
    should.exist(event);
    console.log(event);
    event.args._id.should.equal(eventId)
    const createdAssets = event.args._assets;
    createdAssets.length.should.equal(assets.length);
 
  })

  

})