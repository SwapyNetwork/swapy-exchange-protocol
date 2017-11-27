
// helpers
const increaseTime  = require('./helpers/increaseTime');

const should = require('chai')
    .use(require('chai-as-promised'))
    .should()
const expect = require('chai').expect;

// --- Handled contracts
const SwapyExchange = artifacts.require("./SwapyExchange.sol");
const InvestmentAsset = artifacts.require("./investment/InvestmentAsset.sol");

// --- Test constants
const agreementTerms = "222222";
const payback = 12;
const grossReturn = 500;
const assetValue = 10;
// returned value =  invested value + return on investment
const returnValue = (1 + grossReturn/10000) * assetValue;
const assets = [10,10];
const currency = "USD";
const offerTerms = "111111";

// --- Test variables
let protocol = null;
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

    before( async () => {
        creditCompany = accounts[0];
        investor = accounts[1];
        protocol = await SwapyExchange.new();
    })


    it("should have a version", async () => {
        const version = await protocol.VERSION.call();
        should.exist(version)
        console.log(`Protocol version: ${version}`);
    })

    it("should create an investment offer", async () => {
        const {logs} = await protocol.createOffer(
            createOfferId,
            payback,
            grossReturn,
            currency,
            offerTerms,
            assets
        );
        const event = logs.find(e => e.event === 'Offers')
        should.exist(event)
        expect(event.args).to.include.all.keys([
            '_id',
            '_from',
            '_protocolVersion',
            '_assets'
        ]);
        assetsAddress = event.args._assets;
    })
})

describe('Contract: InvestmentAsset ', () => {

    it('should add an investment - first', async () => {
        firstAsset = await InvestmentAsset.at(assetsAddress[0]);
        const { logs } = await firstAsset.invest(firstAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
        const event = logs.find(e => e.event === 'Transferred')
        expect(event.args).to.include.all.keys([
            '_id',
            '_from',
            '_to',
            '_value',
        ]);
        assert.equal(event.args._value, assetValue, "The invested value must be equal the sent value");
    });

    it('should return the asset when calling getAsset', async () => {
       const firstAsset = await InvestmentAsset.at(assetsAddress[0]);
       const assetValues = await firstAsset.getAsset();
       assert.equal(assetValues.length, 11, "The asset must have 10 variables");
       assert.equal(assetValues[0], creditCompany, "The asset owner must be the creditCompany");
    });

    it("should deny an investment if the asset isn't available", async () => {
        await firstAsset.invest(firstAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
            .should.be.rejectedWith('VM Exception')
    })

    it("should deny a cancelment if the user isn't the investor", async () => {
        await firstAsset.cancelInvestment(cancelInvestmentId, {from: creditCompany})
            .should.be.rejectedWith('VM Exception')
    })

    it('should cancel a pending investment', async () => {
        const { logs } = await firstAsset.cancelInvestment(cancelInvestmentId, {from: investor})
        const event = logs.find(e => e.event === 'Canceled');
        expect(event.args).to.include.all.keys([
            '_id',
            '_owner',
            '_investor',
            '_value',
        ]);
    })

    it('should add an investment - second', async () => {
        secondAsset = await InvestmentAsset.at(assetsAddress[1]);
        await secondAsset.invest(secondAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
    })

    it("should deny a refusement if the user isn't the asset owner", async () => {
        await secondAsset.refuseInvestment(refuseInvestmentId, { from: investor })
        .should.be.rejectedWith('VM Exception')
    })

    it('should refuse a pending investment', async () => {
        const {logs} = await secondAsset.refuseInvestment(refuseInvestmentId, { from: creditCompany })
        const event = logs.find(e => e.event === 'Refused')
        expect(event.args).to.include.all.keys([
            '_id',
            '_owner',
            '_investor',
            '_value',
        ]);
    })


    it('should add an investment - third', async () => {
        await secondAsset.invest(thirdAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
    })

    it("should deny a withdrawal if the user isn't the asset owner", async () => {
        await secondAsset.withdrawFunds(withdrawFundsId, agreementTerms, { from: investor })
        .should.be.rejectedWith('VM Exception')
    })

    it('should accept a pending investment and withdraw funds', async () => {
        const {logs} = await secondAsset.withdrawFunds(withdrawFundsId, agreementTerms, { from: creditCompany })
        const event = logs.find(e => e.event === 'Withdrawal');
        expect(event.args).to.include.all.keys([
            '_id',
            '_owner',
            '_investor',
            '_value',
            '_terms',
        ]);
    })


    it("should deny an investment return if the user isn't the asset owner", async () => {
        await secondAsset.returnInvestment( returnInvestmentId, { from: investor, value: returnValue })
            .should.be.rejectedWith('VM Exception')
    })

    it('should return the investment with delay', async () => {
        // simulate a long period after the funds transfer
        const id  = Date.now();
        await increaseTime(16416000);
        const {logs} = await secondAsset.returnInvestment( returnInvestmentId, { from: creditCompany, value: returnValue })
        const event = logs.find(e => e.event === 'Returned');
        expect(event.args).to.include.all.keys([
            '_id',
            '_owner',
            '_investor',
            '_value',
            '_status'
        ]);
        assert.equal(event.args._status.toNumber(),4,"The investment must be returned with delay");
    })

    it('should add an investment - fourth', async () => {
        await firstAsset.invest(fourthAddInvestmentId, agreementTerms, {from: investor, value: assetValue})
    })

    it('should accept a pending investment and withdraw funds - second', async () => {
        const {logs} =  await firstAsset.withdrawFunds(withdrawFundsId, agreementTerms)
        const event = logs.find(e => e.event === 'Withdrawal');
        expect(event.args).to.include.all.keys([
            '_id',
            '_owner',
            '_investor',
            '_value',
            '_terms',
        ]);
    })

    it('should return the investment correctly', async () => {
        const {logs} = await firstAsset.returnInvestment( returnInvestmentId, { from: creditCompany, value: returnValue })
        const event = logs.find(e => e.event === 'Returned');
        expect(event.args).to.include.all.keys([
            '_id',
            '_owner',
            '_investor',
            '_value',
            '_status'
        ]);
        assert.equal(event.args._status.toNumber(),3,"The investment must be returned without delay");
    })
})
