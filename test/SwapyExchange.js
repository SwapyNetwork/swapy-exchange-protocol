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
const grossReturn = 500;
const assetValue = 10;
const assets = [10,10,10,10];
const currency = "USD";
const offerFixedValue = 10;
const offerTerms = "111111";

// --- Test variables 
let protocol = null;
let offerAddress = null;
let offer = null;
let assetsAddress = [];
let firstAsset = null;
let secondAsset = null;
let investor = null;
let creditCompany = null;


// --- Identify events
const createOfferId = 'f6e6b40a-adea-11e7-abc4-cec278b6b50a';
const createAssetId = '18bcd316-bf02-11e7-abc4-cec278b6b50a';
const firstAddInvestmentId = '18bcd94c-bf02-11e7-abc4-cec278b6b50a';
const secondAddInvestmentId = '18bcdb90-bf02-11e7-abc4-cec278b6b50a';
const thirdAddInvestmentId = '18bcdd70-bf02-11e7-abc4-cec278b6b50a';
const cancelInvestmentId = '18bcdf46-bf02-11e7-abc4-cec278b6b50a';
const refuseInvestmentId = '18bce108-bf02-11e7-abc4-cec278b6b50a';
const withdrawFundsId = '18bce2ac-bf02-11e7-abc4-cec278b6b50a';
const returnInvestmentId = '18bce4ab-bf02-11e7-abc4-cec278b6b50a';

contract('SwapyExchange', accounts => {

    before( done => {
        creditCompany = accounts[0];
        investor = accounts[1];
        SwapyExchange.new().then(contract => {
            protocol = contract;
            done();
        })
    })
    

    it("should has a version", done => {
        protocol.VERSION.call().then(version => {
            should.exist(version);
            console.log(version);
            done();
        })
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
                assetsAddress = event._assets;
                offerAddress = event._offerAddress;
                done();        
            });
        });
    })

    it('should add an investment - first', done => {
        InvestmentAsset.at(assetsAddress[0]).then(assetContract => {
            firstAsset = assetContract;
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
        firstAsset.cancelInvestment(cancelInvestmentId, {from: investor})
            .then(transaction => {
                should.exist(transaction.tx)
                firstAsset.Canceled({_id: cancelInvestmentId}).watch((err,log) => {
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

    it("should create an investment asset", done => {
        InvestmentOffer.at(offerAddress)
            .then(offerContract => {
                offer = offerContract;
                offer.createAsset(
                    createAssetId,
                    assetValue
                ).then(transaction => {
                    should.exist(transaction.tx);
                    offer.Assets({_id: createAssetId}).watch((err,log) => {
                        const event = log.args;
                        expect(event).to.include.all.keys([
                            '_id',
                            '_from',
                            '_protocolVersion',
                            '_assetAddress',
                            '_currency',
                            '_fixedValue',
                            '_assetTermsHash'
                        ]);
                        assetsAddress.push(event._assetAddress);
                        done();        
                    });
                });
            })
    })

    it('should add an investment - second', done => {
        InvestmentAsset.at(assetsAddress[1]).then(assetContract => {
            secondAsset = assetContract;
            secondAsset.invest(secondAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
                .then(transaction => {
                    should.exist(transaction.tx)
                    secondAsset.Transferred({_id: secondAddInvestmentId}).watch((err,log) => {
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
            });
        });
    })
    
    it('should refuse a pending investment', done => {
        secondAsset.refuseInvestment(refuseInvestmentId)
            .then(transaction => {
                should.exist(transaction.tx)
                secondAsset.Refused({_id: refuseInvestmentId}).watch((err,log) => {
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


    it('should add an investment - third', done => {
        secondAsset.invest(thirdAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
            .then(transaction => {
                should.exist(transaction.tx)
                done();
            }, error => {
                console.log(error);
        });
    })

    it('should accept a pending investment and withdraw funds', done => {
        secondAsset.withdrawFunds(withdrawFundsId, agreementTerms)
            .then(transaction => {
                should.exist(transaction.tx)
                secondAsset.Withdrawal({_id: withdrawFundsId}).watch((err,log) => {
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
            }, error => {
                console.log(error);
        });
    })

    it('should return investment value', done => {
        secondAsset.returnInvestment(returnInvestmentId, {from: creditCompany, value: (1 + grossReturn/10000) * assetValue })
            .then(transaction => {
                should.exist(transaction.tx)
                secondAsset.Returned({_id: returnInvestmentId}).watch((err, log) => {
                    const event = log.args;
                    expect(event).to.include.all.keys([
                        '_id',
                        '_owner',
                        '_investor',
                        '_value',
                        '_status'
                    ]);
                    done();
                })
            }, error => {
                console.log(error);
            })
    })
})