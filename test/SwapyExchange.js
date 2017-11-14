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
const payback = 12;
const grossReturn = 500;
const assetValue = 10;
// invested value + return on investment
const returnValue = (1 + grossReturn/10000) * assetValue;
const assets = [10,10];
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
const fourthAddInvestmentId = '18bc3213-bf02-11e7-abc4-cec278b6b50a';
const cancelInvestmentId = '18bcdf46-bf02-11e7-abc4-cec278b6b50a';
const refuseInvestmentId = '18bce108-bf02-11e7-abc4-cec278b6b50a';
const withdrawFundsId = '18bce2ac-bf02-11e7-abc4-cec278b6b50a';
const returnInvestmentId = '18bce4ab-bf02-11e7-abc4-cec278b6b50a';

contract('SwapyExchange', accounts => {

    before( done => {
        creditCompany = accounts[0];
        investor = accounts[1];
        anotherUser = accounts[2];
        SwapyExchange.new().then(contract => {
            protocol = contract;
            done();
        })
    })
    

    it("should has a version", done => {
        protocol.VERSION.call().then(version => {
            should.exist(version);
            console.log(`Protocol version: ${version}`);
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
})

describe('Contract: InvestmentOffer', () => {
    
    it("should deny an investment asset creation if the user isn't offer's owner", done => {
        InvestmentOffer.at(offerAddress).then(offerContract => {
            offer = offerContract;
            offer.createAsset(
                createAssetId,
                assetValue,
                { from: anotherUser }
            ).should.be.rejectedWith('VM Exception')
            .then(() => {
                done();
            })
         })
    })

    it("should create an investment asset", done => {
        InvestmentOffer.at(offerAddress).then(offerContract => {
            offer = offerContract;
            offer.createAsset(
                createAssetId,
                assetValue,
                { from: creditCompany}
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

})
    
describe('Contract: InvestmentAsset ', () => {
    
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

    it("should deny an investment if the asset isn't available", done => {
        firstAsset.invest(firstAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
        .should.be.rejectedWith('VM Exception')
        .then(() => {
            done();
        })
    })
    
    it("should deny a cancelment if the user isn't the investor", done=> {
        firstAsset.cancelInvestment(cancelInvestmentId, {from: creditCompany})
        .should.be.rejectedWith('VM Exception')
        .then(() => {
            done();
        })
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

    it("should deny a refusement if the user isn't the asset owner", done=> {
        secondAsset.refuseInvestment(refuseInvestmentId, { from: investor })
        .should.be.rejectedWith('VM Exception')
        .then(() => {
            done();
        })
    })
    
    it('should refuse a pending investment', done => {
        secondAsset.refuseInvestment(refuseInvestmentId, { from: creditCompany })
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

    it("should deny a withdrawal if the user isn't the asset owner", done=> {
        secondAsset.withdrawFunds(withdrawFundsId, agreementTerms, { from: investor }) 
        .should.be.rejectedWith('VM Exception')
        .then(() => {
            done();
        })
    })
    
    it('should accept a pending investment and withdraw funds', done => {
        secondAsset.withdrawFunds(withdrawFundsId, agreementTerms, { from: creditCompany })
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

    it("should deny a withdrawal if the user isn't the asset owner", done=> {
        secondAsset.withdrawFunds(withdrawFundsId, agreementTerms, { from: investor }) 
        .should.be.rejectedWith('VM Exception')
        .then(() => {
            done();
        })
    })

    it("should deny an investment return if the user isn't the asset owner", done=> {
        secondAsset.returnInvestment(
            returnInvestmentId,
            { from: investor, value: returnValue }
        ) 
        .should.be.rejectedWith('VM Exception')
        .then(() => {
            done();
        })
    })
    
    it('should return the investment with delay', done => {
        // simulate a long period after the funds transfer
        web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [16416000], id: 123});
        secondAsset.returnInvestment(
            returnInvestmentId,
            { from: creditCompany, value: returnValue }
        ).then(transaction => {
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
                assert.equal(event._status.toNumber(),4,"The investment must be returned with delay");
                done();
            })
        }, error => {
            console.log(error);
        })
    })

    it('should add an investment - fourth', done => {
        firstAsset.invest(fourthAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
            .then(transaction => {
                should.exist(transaction.tx)
                done();
            }, error => {
                console.log(error);
        });
    })

    it('should accept a pending investment and withdraw funds - second', done => {
        firstAsset.withdrawFunds(withdrawFundsId, agreementTerms)
            .then(transaction => {
                should.exist(transaction.tx)
                firstAsset.Withdrawal({_id: withdrawFundsId}).watch((err,log) => {
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

    it('should return the investment correctly', done => {
        firstAsset.returnInvestment(
            returnInvestmentId,
            { from: creditCompany, value: returnValue }
        ).then(transaction => {
            should.exist(transaction.tx)
            firstAsset.Returned({_id: returnInvestmentId}).watch((err, log) => {
                const event = log.args;
                expect(event).to.include.all.keys([
                    '_id',
                    '_owner',
                    '_investor',
                    '_value',
                    '_status'
                ]);
                assert.equal(event._status.toNumber(),3,"The investment must be returned without delay");
                done();
            })
        }, error => {
            console.log(error);
        })
    })
})

    
