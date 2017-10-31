const should = require('chai')
    .use(require('chai-as-promised'))
    .should()
const expect = require('chai').expect;

const SwapyExchange = artifacts.require("./SwapyExchange.sol");
const InvestmentAsset = artifacts.require("./investment/InvestmentAsset.sol");

const currentVersion = "1.0.0";
const agreementTerms = "222222";
const investor = process.env.WALLET_ADDRESS;
const payback = 24;
const grossReturn = 5;
const assetValue = 10;
const assets = [10,10];
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
            const event = log.args;
            expect(event).to.include.all.keys([
                '_id',
                '_from',
                '_protocolVersion',
                '_offerAddress',
                '_assets'
            ]);
            assetAddress = event._assets;
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

    it('should add an investment', done => {
        InvestmentAsset.at(assetAddress[0]).then(assetContract => {
            assetContract.Transferred({_id: eventId}).watch((err,log) => {
                const event = log.args;
                expect(event).to.include.all.keys([
                    '_id',
                    '_from',
                    '_to',
                    '_value',
                ]);
                assert.equal(event._value, assetValue, "The invested value must be equal the sent value");
                done();
            });
            assetContract.invest(eventId, agreementTerms, {value: assetValue})
                .then(transaction => {
                    should.exist(transaction.tx)
                }, error => {
                    console.log(error);
            });
        });
    })

    it('should accept the pending investment', done => {
        InvestmentAsset.at(assetAddress[0]).then(assetContract => {
            assetContract.Withdrawal({_id: eventId}).watch((err,log) => {
                const event = log.args;
                expect(event).to.include.all.keys([
                    '_id',
                    '_owner',
                    '_investor',
                    '_value',
                    '_terms',
                ]);
                done();
            });
            assetContract.withdrawFunds(eventId, agreementTerms)
                .then(transaction => {
                    should.exist(transaction.tx)
                }, error => {
                    console.log(error);
            });
        });
    })
})