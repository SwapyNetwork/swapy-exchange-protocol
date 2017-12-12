
// helpers
const increaseTime  = require('./helpers/increaseTime');
const { getBalance, getGasPrice } = require('./helpers/web3');
const ether = require('./helpers/ether'); 

const should = require('chai')
    .use(require('chai-as-promised'))
    .should()
const expect = require('chai').expect;
const BigNumber = web3.BigNumber;

// --- Handled contracts
const SwapyExchange = artifacts.require("./SwapyExchange.sol");
const AssetLibrary = artifacts.require("./investment/AssetLibrary.sol");
const InvestmentAsset = artifacts.require("./investment/InvestmentAsset.sol");
const Token = artifacts.require("./token/Token.sol");

// --- Test constants
const payback = new BigNumber(12);
const grossReturn = new BigNumber(500);
const assetValue = ether(5);
// returned value =  invested value + return on investment
const returnValue = new BigNumber(1 + grossReturn.toNumber()/10000).times(assetValue);
const assets = [500,500,500,500,500];
const offerFuel = new BigNumber(5000);
const assetFuel = offerFuel.dividedBy(new BigNumber(assets.length));
const currency = "USD";
const offerTerms = "111111";

// --- Test variables
// Contracts
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
let secondInvestor = null;
// Util
let gasPrice = null;

contract('SwapyExchange', async accounts => {

    before( async () => {
   
        Swapy = accounts[0];
        creditCompany = accounts[1];
        investor = accounts[2];
        secondInvestor = accounts[3];
        gasPrice = await getGasPrice();
        gasPrice = new BigNumber(gasPrice);        
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
            // balances before invest
            const previousAssetBalance = await getBalance(assetsAddress[0]);
            const previousInvestorBalance = await getBalance(investor);
            const assets = [assetsAddress[0]];
            const {logs, receipt} = await protocol.invest(
                assets,
                {value: assetValue, from: investor}
            );
            const event = logs.find(e => e.event === 'Investments')
            const args = event.args;
            expect(args).to.include.all.keys([
                '_investor',
                '_assets',
                '_value'
            ]);
            // balances after invest
            const currentAssetBalance = await getBalance(assetsAddress[0]);
            const currentInvestorBalance = await getBalance(investor);
            const gasUsed = new BigNumber(receipt.gasUsed);
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .minus(assetValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            );
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.plus(assetValue).toNumber())
        })
    })
    
})

describe('Contract: InvestmentAsset ', async () => {
   
    const periodAfterInvestment = new BigNumber(1/2);
    await increaseTime(86400 * payback * periodAfterInvestment.toNumber())
    const returnOnPeriod = returnValue.minus(assetValue).times(periodAfterInvestment);
    const sellValue = assetValue.plus(returnOnPeriod);

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
        it('should add an investment by using the asset', async () => {
            const previousAssetBalance = await getBalance(firstAsset.address);
            const previousInvestorBalance = await getBalance(investor);
            const {logs, receipt} = await firstAsset.invest(
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
            const currentAssetBalance = await getBalance(firstAsset.address);
            const currentInvestorBalance = await getBalance(investor);
            const gasUsed = new BigNumber(receipt.gasUsed);
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .minus(assetValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            );
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.plus(assetValue).toNumber())
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
            const previousAssetBalance = await getBalance(firstAsset.address);
            const previousInvestorBalance = await getBalance(investor);
            const { logs, receipt } = await firstAsset.cancelInvestment({from: investor})
            const event = logs.find(e => e.event === 'Canceled');
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
            ]);
            const currentAssetBalance = await getBalance(firstAsset.address);
            const currentInvestorBalance = await getBalance(investor);
            const gasUsed = new BigNumber(receipt.gasUsed);
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .plus(assetValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            );
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(assetValue).toNumber())
        })
    })
    
    describe('Refuse Investment', () => {
        
        it('should add an investment', async () => {
            await firstAsset.invest(investor, {from: investor, value: assetValue})
        })
    
        it("should deny a refusement if the user isn't the asset owner", async () => {
            await firstAsset.refuseInvestment( { from: investor })
            .should.be.rejectedWith('VM Exception')
        })
    
        it('should refuse a pending investment', async () => {
            const previousAssetBalance = await getBalance(firstAsset.address);
            const previousInvestorBalance = await getBalance(investor);
            const {logs} = await firstAsset.refuseInvestment({ from: creditCompany })
            let event = logs.find(e => e.event === 'Refused')
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
            ]);
            const currentAssetBalance = await getBalance(firstAsset.address);
            const currentInvestorBalance = await getBalance(investor);
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .plus(assetValue)
                .toNumber()
            );
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(assetValue).toNumber())
        })
    
    })

    describe('Withdraw Funds', () => {

        it('should add an investment', async () => {
            await firstAsset.invest(investor,{from: investor, value: assetValue})
        })
    
        it("should deny a withdrawal if the user isn't the asset owner", async () => {
            await firstAsset.withdrawFunds({ from: investor }) 
            .should.be.rejectedWith('VM Exception')
        })
    
        it('should accept a pending investment and withdraw funds', async () => {
            const previousAssetBalance = await getBalance(firstAsset.address);
            const previousCreditCompanyBalance = await getBalance(creditCompany);
            const { logs, receipt } = await firstAsset.withdrawFunds( { from: creditCompany })
            const event = logs.find(e => e.event === 'Withdrawal');
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
            ]);
            const currentAssetBalance = await getBalance(firstAsset.address);
            const currentCreditCompanyBalance = await getBalance(creditCompany);
            const gasUsed = new BigNumber(receipt.gasUsed);
            currentCreditCompanyBalance.toNumber().should.equal(
                previousCreditCompanyBalance
                .plus(assetValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            );
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(assetValue).toNumber())
        })
          
    })

    describe('Sell', () => {
        
        it("should deny a sell order if the user isn't the investor", async() => {
            await protocol.sellAsset(assetsAddress[1], sellValue, {from: creditCompany})
            .should.be.rejectedWith('VM Exception')
        })

        it('should sell an asset by using the protocol', async() => {
            const {logs} = await protocol.sellAsset(assetsAddress[1], sellValue, {from: investor})
            const event = logs.find(e => e.event === 'ForSale')
            expect(event.args).to.include.all.keys([
                '_investor',
                '_asset',
                '_value'
            ])
        })

    })

    describe('Cancel sell order', () => {
      
        it("should deny a sell order cancelment if the user isnt't the investor", async () => {
            await firstAsset.cancelSellOrder({from: creditCompany})
            .should.be.rejectedWith('VM Exception')
        })

        it("should cancel a sell", async () => {
            const {logs} = await firstAsset.cancelSellOrder({from: investor})
            const event = logs.find(e => e.event === 'CanceledSell')
            expect(event.args).to.include.all.keys([
                '_investor',
                '_value'
            ])
        })
    
    })

    describe('Buy', () => {
        
        it("should sell an asset", async() => {
            const {logs} = await firstAsset.sell(sellValue, {from: investor})
            const event = logs.find(e => e.event === 'ForSale')
            expect(event.args).to.include.all.keys([
                '_investor',
                '_value'
            ])
        })

        it("should buy an asset by using the protocol", async () => {
            const previousAssetBalance = await getBalance(assetsAddress[1]);
            const previousBuyerBalance = await getBalance(secondInvestor);
            const { logs, receipt } = await protocol.buyAsset(assetsAddress[1], {from: secondInvestor, value: sellValue})
            const event = logs.find(e => e.event === 'Bought')
            expect(event.args).to.include.all.keys([
                '_buyer',
                '_asset',
                '_value'
            ])
            const currentAssetBalance = await getBalance(assetsAddress[1]);
            const currentBuyerBalance = await getBalance(secondInvestor);
            const gasUsed = new BigNumber(receipt.gasUsed);
            currentBuyerBalance.toNumber().should.equal(
                previousBuyerBalance
                .minus(sellValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            );
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.plus(sellValue).toNumber())
        })
    })

    describe('Cancel sale', () => {
        
        it("should deny a sale cancelment if the user isnt't the buyer", async () => {
            await firstAsset.cancelSale({from: investor})
            .should.be.rejectedWith('VM Exception')
        })

        it("should cancel a sale", async () => {
            const previousAssetBalance = await getBalance(firstAsset.address);
            const previousBuyerBalance = await getBalance(secondInvestor);
            const { logs, receipt } = await firstAsset.cancelSale({from: secondInvestor})
            const event = logs.find(e => e.event === 'Canceled')
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value'
            ])
            const currentAssetBalance = await getBalance(firstAsset.address);
            const currentBuyerBalance = await getBalance(secondInvestor);
            const gasUsed = new BigNumber(receipt.gasUsed);
            currentBuyerBalance.toNumber().should.equal(
                previousBuyerBalance
                .plus(sellValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            );
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(assetValue).toNumber())
        })
    })

    describe('Refuse sale', () => {
        
        it("should buy an asset", async () => {
            const {logs} = await firstAsset.buy(secondInvestor, {value: sellValue})
            const event = logs.find(e => e.event === 'Invested')
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value'
            ])
        })
        
        it("should deny a sale refusement if the user isnt't the investor", async () => {
            await firstAsset.refuseSale({from: secondInvestor})
            .should.be.rejectedWith('VM Exception')
        })

        it("should refuse a sale", async () => {
            const previousAssetBalance = await getBalance(firstAsset.address);
            const previousBuyerBalance = await getBalance(secondInvestor);
            const { logs, receipt } = await firstAsset.refuseSale({from: investor})
            const event = logs.find(e => e.event === 'Refused')
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value'
            ])
            const currentAssetBalance = await getBalance(firstAsset.address);
            const currentBuyerBalance = await getBalance(secondInvestor);
            currentBuyerBalance.toNumber().should.equal(
                previousBuyerBalance
                .plus(sellValue)
                .toNumber()
            );
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(sellValue).toNumber())

        })
    })

    describe('Accept sale and withdraw funds', () => {
       
        it("should buy an asset", async () => {
           await firstAsset.buy(secondInvestor, {value: sellValue})
        })
        it("should deny a sale acceptment if the user isnt't the investor", async () => {
            await firstAsset.acceptSale({from: secondInvestor})
            .should.be.rejectedWith('VM Exception')
        })

        it("should accept a sale", async () => {
            const previousAssetBalance = await getBalance(firstAsset.address);
            const previousSellerBalance = await getBalance(investor);
            const { logs, receipt } = await firstAsset.acceptSale({from: investor})
            const event = logs.find(e => e.event === 'Withdrawal')
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value'
            ])
            const currentAssetBalance = await getBalance(firstAsset.address);
            const currentSellerBalance = await getBalance(investor);
            const gasUsed = new BigNumber(receipt.gasUsed);
            currentSellerBalance.toNumber().should.equal(
                previousSellerBalance
                .plus(sellValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            );
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(sellValue).toNumber())
        })
    })


    describe("Require Asset's Fuel", () => {
        it("should deny the token fuel request if the return of investment isn't delayed", async () => {
            await firstAsset.requireTokenFuel({ from: secondInvestor })
                .should.be.rejectedWith('VM Exception')
        })
    
        it("should deny the token fuel request if the user isn't the investor", async () => {
            // simulate a long period after the funds transfer
            await increaseTime(16416000);
            await firstAsset.requireTokenFuel({ from: creditCompany })
               .should.be.rejectedWith('VM Exception')
        })
    
        it("should send the token fuel to the asset's investor", async () => {
            const previousInvestorTokenBalance = await token.balanceOf(secondInvestor);
            const previousAssetTokenBalance = await token.balanceOf(firstAsset.address);
            const { logs } =  await firstAsset.requireTokenFuel({ from: secondInvestor })
            const event = logs.find(e => e.event === 'TokenWithdrawal');
            expect(event.args).to.include.all.keys([
                '_to',
                '_amount'
            ]);
            const currentAssetBalance = await getBalance(firstAsset.address);
            const currentSellerBalance = await getBalance(investor);
            const gasUsed = new BigNumber(receipt.gasUsed);
            currentSellerBalance.toNumber().should.equal(
                previousSellerBalance
                .plus(sellValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            );
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(sellValue).toNumber())
        })  
    })

    describe('Delayed return without remaining tokens', () => {
    
        it("should deny an investment return if the user isn't the asset owner", async () => {
            await firstAsset.returnInvestment({ from: secondInvestor, value: returnValue }) 
                .should.be.rejectedWith('VM Exception')
        })
    
        it('should return the investment with delay', async () => {
            const previousAssetBalance = await getBalance(firstAsset.address);
            const previousInvestorBalance = await getBalance(secondInvestor);
            const { logs, receipt } = await firstAsset.returnInvestment({ from: creditCompany, value: returnValue })
            const event = logs.find(e => e.event === 'Returned');
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
                '_delayed'
            ]);
            assert.equal(event.args._delayed,true,"The investment must be returned with delay");
            const currentAssetBalance = await getBalance(firstAsset.address);
            const currentInvestorBalance = await getBalance(secondInvestor);
            const gasUsed = new BigNumber(receipt.gasUsed);
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .plus(assetValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            );
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(assetValue).toNumber())
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
        
        it('should add an investment', async () => {
            secondAsset = await AssetLibrary.at(assetsAddress[2]);
            await secondAsset.invest(investor,{from: investor, value: assetValue})
        })
    
        it('should accept a pending investment and withdraw funds', async () => {
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
    
        it('should add an investment', async () => {
            await thirdAsset.invest(investor, { from: investor, value: assetValue })
        })
    
        it('should accept a pending investment and withdraw funds', async () => {
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
