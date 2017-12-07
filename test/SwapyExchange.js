
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
const Token = artifacts.require("./token/Token.sol");

// --- Test constants
const payback = 12;
const grossReturn = 500;
const assetValue = 10;
// returned value =  invested value + return on investment
const returnValue = (1 + grossReturn/10000) * assetValue;
const assets = [10,10,10,10,10];
const offerFuel = 5000;
const assetFuel = offerFuel / assets.length;
const currency = "USD";
const offerTerms = "111111";

// --- Test variables
let token = null;
let library = null;
let protocol = null;
// Assets
let assetsAddress = [];
let firstAsset = null;
let secondAsset = null;
let thirdAsset = null;
// Agents
let investor = null;
let creditCompany = null;
let Swapy = null;

contract('SwapyExchange', async accounts => {

    before( async () => {
   
        Swapy = accounts[0];
        creditCompany = accounts[1];
        investor = accounts[2];
        const library = await AssetLibrary.new({ from: Swapy });
        token  = await Token.new({from: Swapy});
        protocol = await SwapyExchange.new(library.address, token.address, { from: Swapy });
        await token.transfer(creditCompany, offerFuel, {from: Swapy});
   
    })

    it("should have a version", async () => {
        const version = await protocol.VERSION.call();
        should.exist(version)
    })

    describe('Fundraising offers', () => {
        it("should create an investment offer with assets", async () => {
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
            assert.equal(args._from, creditCompany, 'The credit company must be the offer owner');
            assert.equal(args._assets.length, assets.length, 'The count of created assets must be equal the count of sent');
            assetsAddress = args._assets;
        })
    
        it("should add an investment by using the protocol", async () => {
            const assets = [assetsAddress[0]];
            const {logs} = await protocol.invest(
                assets,
                {value: assetValue * assets.length, from: investor}
            );
            const event = logs.find(e => e.event === 'Investments')
            const args = event.args;
            expect(args).to.include.all.keys([
                '_investor',
                '_assets',
                '_value'
            ]);

        })
    })
    
})

describe('Contract: InvestmentAsset ', async () => {
    
    it('should return the asset when calling getAsset', async () => {
        const asset = await InvestmentAsset.at(assetsAddress[0]);
        const assetValues = await asset.getAsset();
        assert.equal(assetValues.length, 11, "The asset must have 11 variables");
        assert.equal(assetValues[0], creditCompany, "The asset owner must be the creditCompany");
    })

    describe('Token Supply', () => {
        it("should supply tokens as fuel to the first asset", async () => {
            await token.transfer(assetsAddress[1], assetFuel, {from: creditCompany});
            firstAsset = await AssetLibrary.at(assetsAddress[1]);
            const {logs} = await firstAsset.supplyFuel(
                assetFuel,
                {from: creditCompany}
            );
            const event = logs.find(e => e.event === 'Supplied')
            const args = event.args;
            expect(args).to.include.all.keys([
               '_owner',
               '_amount',
               '_assetFuel'
            ]);
        })  
    })
    
    describe('Invest', () => {
        it('should add an investment - first', async () => {
            const {logs} = await firstAsset.invest(
                investor,
                {value: assetValue, from: investor}
            );
            const event = logs.find(e => e.event === 'Invested')
            const args = event.args;
            expect(args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
            ]);
            assert.equal(args._owner, creditCompany, "The credit company must be the asset's seller");
            assert.equal(args._investor, investor, "The current user must the asset's investor");
            assert.equal(args._value, assetValue, "The invested value must be equal the sent value");
        });
    
        it("should deny an investment if the asset isn't available", async () => {
            await firstAsset.invest(investor,{from: investor, value: assetValue})
                .should.be.rejectedWith('VM Exception')
        })
    })

    describe('Cancel Investment', () => {
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
    })
    
    describe('Refuse Investment', () => {
        
        it('should add an investment - second', async () => {
            await firstAsset.invest(investor, {from: investor, value: assetValue})
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
    
    })

    describe('Withdraw Funds', () => {

        it('should add an investment - third', async () => {
            await firstAsset.invest(investor,{from: investor, value: assetValue})
        })
    
        it("should deny a withdrawal if the user isn't the asset owner", async () => {
            await firstAsset.withdrawFunds({ from: investor }) 
            .should.be.rejectedWith('VM Exception')
        })
    
        it('should accept a pending investment and withdraw funds', async () => {
            const {logs} = await firstAsset.withdrawFunds( { from: creditCompany })
            const event = logs.find(e => e.event === 'Withdrawal');
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
            ]);
        })
          
    })

    describe('Sell', () => {

        it('should sell an asset by using the protocol', async() => {
            const periodAfterInvestment = 1/2;
            await increaseTime(86400 * payback * periodAfterInvestment)
            const sellValue = returnValue - (returnValue - assetValue) * periodAfterInvestment;
            const {logs} = await protocol.sellAsset(assetsAddress[1], sellValue)
            const event = logs.find(e => e.event === 'ForSale')
            expect(event.args).to.include.all.keys([
                '_investor',
                '_asset',
                '_value'
            ])
            console.log(sellValue);
        })
    })
    describe("Require Asset's Fuel", () => {
        it("should deny the token fuel request if the return of investment isn't delayed", async () => {
            await firstAsset.requireTokenFuel({ from: investor })
                .should.be.rejectedWith('VM Exception')
        })
    
        it("should deny the token fuel request if the user isn't the investor", async () => {
            // simulate a long period after the funds transfer
            await increaseTime(16416000);
            await firstAsset.requireTokenFuel({ from: creditCompany })
               .should.be.rejectedWith('VM Exception')
        })
    
        it("should send the token fuel to the asset's investor", async () => {
            const {logs} =  await firstAsset.requireTokenFuel({ from: investor })
            const event = logs.find(e => e.event === 'TokenWithdrawal');
            expect(event.args).to.include.all.keys([
                '_to',
                '_amount'
            ]);
        })  
    })

    describe('Delayed return without remaining tokens', () => {
    
        it("should deny an investment return if the user isn't the asset owner", async () => {
            await firstAsset.returnInvestment({ from: investor, value: returnValue }) 
                .should.be.rejectedWith('VM Exception')
        })
    
        it('should return the investment with delay', async () => {
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
        
    })
   
    describe('Delayed return with remaining tokens', () => {
        it("should supply tokens to the second asset", async () => {
            await token.transfer(assetsAddress[2], assetFuel, {from: creditCompany});
            secondAsset = await AssetLibrary.at(assetsAddress[2]);
            await secondAsset.supplyFuel(
                assetFuel,
                {from: creditCompany}
            );
        })  
        
        it('should add an investment - fourth', async () => {
            secondAsset = await AssetLibrary.at(assetsAddress[2]);
            await secondAsset.invest(investor,{from: investor, value: assetValue})
        })
    
        it('should accept a pending investment and withdraw funds - second', async () => {
            const {logs} =  await secondAsset.withdrawFunds({from: creditCompany})
            const event = logs.find(e => e.event === 'Withdrawal');
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
            ]);
        })
    
        it("should return the investment with delay and send tokens to the asset's investor", async () => {
            // simulate a long period after the funds transfer
            await increaseTime(16416000);
            const investorTokenBalance = await token.balanceOf(investor);
            const assetTokenBalance = await token.balanceOf(secondAsset.address);
            const {logs} = await secondAsset.returnInvestment({ from: creditCompany, value: returnValue })
            const event = logs.find(e => e.event === 'Returned');
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
                '_delayed'
            ]);
            assert.equal(event.args._delayed,true,"The investment must be returned with delay");
            const currentInvestorTokenBalance = await token.balanceOf(investor);
            assert.equal(
                investorTokenBalance.toNumber() + assetTokenBalance.toNumber(),
                currentInvestorTokenBalance.toNumber(),
                "The investor must receive the asset's fuel if the investment is returned with delay"
            )
        })
        
    })

    describe('Correct return with remaining tokens', () => {
        it("should supply tokens to the third asset", async () => {
            await token.transfer(assetsAddress[3], assetFuel, {from: creditCompany});
            thirdAsset = await AssetLibrary.at(assetsAddress[3]);
            await thirdAsset.supplyFuel(
                assetFuel,
                {from: creditCompany}
            );
        }) 
    
        it('should add an investment - fifth', async () => {
            await thirdAsset.invest(investor, { from: investor, value: assetValue })
        })
    
        it('should accept a pending investment and withdraw funds - third', async () => {
            const {logs} =  await thirdAsset.withdrawFunds({from: creditCompany})
            const event = logs.find(e => e.event === 'Withdrawal');
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
            ]);
        })
        
        it("should return the investment correctly and send tokens to the asset's owner", async () => {
            const creditCoTokenBalance = await token.balanceOf(creditCompany);
            const assetTokenBalance = await token.balanceOf(thirdAsset.address);
            const {logs} = await thirdAsset.returnInvestment({ from: creditCompany, value: returnValue })
            const event = logs.find(e => e.event === 'Returned');
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
                '_delayed'
            ]);
            assert.equal(event.args._delayed,false,"The investment must be returned without delay");
            const currentCreditCoTokenBalance = await token.balanceOf(creditCompany);
            assert.equal(
                creditCoTokenBalance.toNumber() + assetTokenBalance.toNumber(),
                currentCreditCoTokenBalance.toNumber(),
                "The credit company must receive the asset's fuel if the investment is returned without delay"
            )
        })
    })

})
