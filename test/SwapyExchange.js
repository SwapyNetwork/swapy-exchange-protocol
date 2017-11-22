
// helpers
const increaseTime  = require('./helpers/increaseTime');

const should = require('chai')
    .use(require('chai-as-promised'))
    .should()
const expect = require('chai').expect;

// --- Handled contracts
const SwapyExchange = artifacts.require("./SwapyExchange.sol");
const AssetLibrary = artifacts.require("./investment/AssetLibrary.sol");
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

let investor = null;
let creditCompany = null;
let Swapy = null;

contract('SwapyExchange', accounts => {

    before( async () => {
        Swapy = accounts[0];
        creditCompany = accounts[1];
        investor = accounts[2];
        library = await AssetLibrary.new({ from: Swapy });
        protocol = await SwapyExchange.new(library.address, { from: Swapy });

    })
    

    it("should has a version", async () => {
        const version = await protocol.VERSION.call();
        should.exist(version)
        console.log(`Protocol version: ${version}`);
    })

    it("should create an investment offer", async () => {
        const {logs} = await protocol.createOffer(
            payback,
            grossReturn,
            currency,
            offerTerms,
            assets,
            {from: creditCompany}
        );
        const event = logs.find(e => e.event === 'Offers')
        const args = event.args;
        expect(args).to.include.all.keys([
            '_from',
            '_protocolVersion',
            '_assets'
        ]);
        assert.equal(args._from, creditCompany, '');
        assert.equal(args._assets.length, assets.length, 'The count of created assets must be equal the count of sent');
        assetsAddress = args._assets;
    })
})

describe('Contract: InvestmentAsset ', () => {
    
    it('should add an investment - first', async () => {
        firstAsset = await InvestmentAsset.at(assetsAddress[0]);
        const owner = await firstAsset.owner.call();
        const { logs } = await firstAsset.invest(
            agreementTerms,
            {from: investor, value: assetValue}
        );
        const event = logs.find(e => e.event === 'Transferred')
        const args = event.args;
        expect(args).to.include.all.keys([
            '_from',
            '_to',
            '_value',
        ]);
        assert.equal(args._from, investor, "The current user must the asset's investor");
        assert.equal(args._to, creditCompany, "The credit company must be the asset's seller");
        assert.equal(args._value, assetValue, "The invested value must be equal the sent value");
    });

    it("should deny an investment if the asset isn't available", async () => {
        await firstAsset.invest(agreementTerms, {from: investor, value: assetValue})
            .should.be.rejectedWith('VM Exception')
    })
    
    it("should deny a cancelment if the user isn't the investor", async () => {
        await firstAsset.cancelInvestment({from: creditCompany})
            .should.be.rejectedWith('VM Exception')
    })

    it('should cancel a pending investment', async () => {
        const { logs } = await firstAsset.cancelInvestment({from: investor})
        const event = logs.find(e => e.event === 'Canceled');
        expect(event.args).to.include.all.keys([
            '_owner',
            '_investor',
            '_value',
        ]);
    })

    it('should add an investment - second', async () => {
        await firstAsset.invest(agreementTerms, {from: investor, value: assetValue})
    })

    it("should deny a refusement if the user isn't the asset owner", async () => {
        await firstAsset.refuseInvestment( { from: investor })
        .should.be.rejectedWith('VM Exception')
    })

    it('should refuse a pending investment', async () => {
        const {logs} = await firstAsset.refuseInvestment({ from: creditCompany })
        let event = logs.find(e => e.event === 'Refused')
        expect(event.args).to.include.all.keys([
            '_owner',
            '_investor',
            '_value',
        ]);
    })


    it('should add an investment - third', async () => {
        await firstAsset.invest(agreementTerms, {from: investor, value: assetValue})
    })

    it("should deny a withdrawal if the user isn't the asset owner", async () => {
        await firstAsset.withdrawFunds(agreementTerms, { from: investor }) 
        .should.be.rejectedWith('VM Exception')
    })
    
    it('should accept a pending investment and withdraw funds', async () => {
        const {logs} = await firstAsset.withdrawFunds( agreementTerms, { from: creditCompany })
        const event = logs.find(e => e.event === 'Withdrawal');
        expect(event.args).to.include.all.keys([
            '_owner',
            '_investor',
            '_value',
            '_terms',
        ]);
    })


    it("should deny an investment return if the user isn't the asset owner", async () => {
        await firstAsset.returnInvestment({ from: investor, value: returnValue }) 
            .should.be.rejectedWith('VM Exception')
    })
    
    it('should return the investment with delay', async () => {
        // simulate a long period after the funds transfer
        await increaseTime(16416000);
        const {logs} = await firstAsset.returnInvestment({ from: creditCompany, value: returnValue })
        const event = logs.find(e => e.event === 'Returned');
        expect(event.args).to.include.all.keys([
            '_owner',
            '_investor',
            '_value',
            '_delayed'
        ]);
        assert.equal(event.args._delayed,true,"The investment must be returned with delay");
    })

    it('should add an investment - fourth', async () => {
        secondAsset = await InvestmentAsset.at(assetsAddress[1]);
        await secondAsset.invest(agreementTerms, {from: investor, value: assetValue})
    })

    it('should accept a pending investment and withdraw funds - second', async () => {
        const {logs} =  await secondAsset.withdrawFunds(agreementTerms, {from: creditCompany})
        const event = logs.find(e => e.event === 'Withdrawal');
        expect(event.args).to.include.all.keys([
            '_owner',
            '_investor',
            '_value',
            '_terms',
        ]);
    })

    it('should return the investment correctly', async () => {
        const {logs} = await secondAsset.returnInvestment({ from: creditCompany, value: returnValue })
        const event = logs.find(e => e.event === 'Returned');
        expect(event.args).to.include.all.keys([
            '_owner',
            '_investor',
            '_value',
            '_delayed'
        ]);
        assert.equal(event.args._delayed,false,"The investment must be returned without delay");
    })
})

    
