const should = require('chai')
    .use(require('chai-as-promised'))
    .should()
const expect = require('chai').expect;


// --- Handled contracts
const SwapyExchange = artifacts.require("./SwapyExchange.sol");
const InvestmentOffer = artifacts.require("./investment/InvestmentOffer.sol");
const InvestmentAsset = artifacts.require("./investment/InvestmentAsset.sol");

// --- Test constants 
const agreementTerms = "222222";
const payback = 24;
const grossReturn = 5;
const assetValue = 10;
const assets = [10];
const currency = "USD";
const offerFixedValue = 10;
const offerTerms = "111111";

// --- Test variables 
let assetsAddress = [];
let asset = null;
let offerAddress = null;
let investor = null;

// --- Identify events
const createOfferId = 'f6e6b40a-adea-11e7-abc4-cec278b6b50a';
const createAssetId = '18bcd316-bf02-11e7-abc4-cec278b6b50a';
const firstAddInvestmentId = '18bcd94c-bf02-11e7-abc4-cec278b6b50a';
const secondAddInvestmentId = '18bcdb90-bf02-11e7-abc4-cec278b6b50a';
const thirdAddInvestmentId = '18bcdd70-bf02-11e7-abc4-cec278b6b50a';
const cancelInvestmentId = '18bcdf46-bf02-11e7-abc4-cec278b6b50a';
const refuseInvestmentId = '18bce108-bf02-11e7-abc4-cec278b6b50a';
const withdrawFundsId = '18bce2ac-bf02-11e7-abc4-cec278b6b50a';

contract('SwapyExchange', accounts => {
    
    let protocol = null;
    investor = accounts[1];


    it("should has a version", async () => {
        protocol = await SwapyExchange.new();
        const version = await protocol.VERSION.call()
        console.log(version);
    })

    it("should create an investment offer", done => {
        protocol.createOffer(
            createOfferId,
            payback,
            grossReturn,
            currency,
            offerFixedValue,
            offerTerms,
            assets
        ).then(transaction => {
            should.exist(transaction.tx);
            protocol.Offers({_id: createOfferId}).watch((err,log) => {
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
        });
    })

    it('should add an investment - first', done => {
        InvestmentAsset.at(assetAddress[0]).then(assetContract => {
            asset = assetContract;
            assetContract.invest(firstAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
                .then(transaction => {
                    assetContract.Transferred({_id: firstAddInvestmentId}).watch((err,log) => {
                        const event = log.args;
                        expect(event).to.include.all.keys([
                            '_id',
                            '_from',
                            '_to',
                            '_value',
                        ]);
                        assert.equal(event._value, assetValue, "The invested value must be equal the sent value");
                    });
                    done();
                }, error => {
                    console.log(error);
                    done();
            });
        });
    })

    it('should cancel a pending investment', done => {
        asset.cancelInvestment(cancelInvestmentId, {from: investor})
            .then(transaction => {
                should.exist(transaction.tx)
                asset.Canceled({_id: cancelInvestmentId}).watch((err,log) => {
                    const event = log.args;
                    expect(event).to.include.all.keys([
                        '_id',
                        '_owner',
                        '_investor',
                        '_value',
                    ]);
                    done();
                });
            }, error => {
                console.log(error);
        });
    })

    it('should add an investment - second', done => {
        asset.invest(secondAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
            .then(transaction => {
                should.exist(transaction.tx)
                done();
            }, error => {
                console.log(error);
        });
    })
    
    it('should refuse a pending investment', done => {
        InvestmentAsset.at(assetAddress[0]).then(assetContract => {
            assetContract.Refused({_id: refuseInvestmentId}).watch((err,log) => {
                const event = log.args;
                expect(event).to.include.all.keys([
                    '_id',
                    '_owner',
                    '_investor',
                    '_value',
                ]);
                done();
            });
            assetContract.refuseInvestment(refuseInvestmentId)
                .then(transaction => {
                    should.exist(transaction.tx)
                }, error => {
                    console.log(error);
            });
        });
    })


    it('should add an investment - third', done => {
        asset.invest(thirdAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
            .then(transaction => {
                should.exist(transaction.tx)
                done();
            }, error => {
                console.log(error);
        });
    })

    it('should accept a pending investment and withdraw funds', done => {
        InvestmentAsset.at(assetAddress[0]).then(assetContract => {
            assetContract.Withdrawal({_id: withdrawFundsId}).watch((err,log) => {
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
            assetContract.withdrawFunds(withdrawFundsId, agreementTerms)
                .then(transaction => {
                    should.exist(transaction.tx)
                }, error => {
                    console.log(error);
            });
        });
    })
})