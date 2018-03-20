
// helpers
const increaseTime  = require('./helpers/increaseTime')
const { getBalance, getGasPrice } = require('./helpers/web3')
const ether = require('./helpers/ether')

const BigNumber = web3.BigNumber
const should = require('chai')
    .use(require('chai-as-promised'))
    .should()
const expect = require('chai').expect


// --- Handled contracts
const SwapyExchange = artifacts.require("./SwapyExchange.sol")
const AssetLibrary = artifacts.require("./investment/AssetLibrary.sol")
const InvestmentAsset = artifacts.require("./investment/InvestmentAsset.sol")
const Token = artifacts.require("./token/Token.sol")

// --- Test constants
const payback = new BigNumber(12)
const grossReturn = new BigNumber(500)
const assetValue = ether(5)
// returned value =  invested value + return on investment
const returnValue = new BigNumber(1 + grossReturn.toNumber()/10000).times(assetValue)
const assets = [500,500,500,500,500]
const offerFuel = new BigNumber(5000)
const assetFuel = offerFuel.dividedBy(new BigNumber(assets.length))
const currency = "USD"
// asset status
const AVAILABLE = new BigNumber(0)
const PENDING_OWNER_AGREEMENT = new BigNumber(1)
const INVESTED = new BigNumber(2)
const FOR_SALE = new BigNumber(3)
const PENDING_INVESTOR_AGREEMENT = new BigNumber(4)
const RETURNED = new BigNumber(5)
const DELAYED_RETURN = new BigNumber(6)

// --- Test variables
// Contracts
let token = null
let library = null
let protocol = null
// Assets
let assetsAddress = []
let firstAsset = null
let secondAsset = null
let thirdAsset = null
let fourthAsset = null
// Agents
let investor = null
let creditCompany = null
let Swapy = null
let secondInvestor = null
// Util
let gasPrice = null
let sellValue = null

contract('InvestmentAsset', accounts => {

    before(async() => {

        // Get accounts and init contracts
        Swapy = accounts[0]
        creditCompany = accounts[1]
        investor = accounts[2]
        secondInvestor = accounts[3]
        gasPrice = await getGasPrice()
        gasPrice = new BigNumber(gasPrice)
        const library = await AssetLibrary.new({ from: Swapy })
        token  = await Token.new({from: Swapy})
        protocol = await SwapyExchange.new(library.address, token.address, { from: Swapy })
        await token.mint(creditCompany, offerFuel, {from: Swapy})
        
        // Creating assets by the protocol
        const {logs} = await protocol.createOffer(
            payback,
            grossReturn,
            currency,
            assets,
            {from: creditCompany}
        )
        const event = logs.find(e => e.event === 'Offers')
        const args = event.args
        assetsAddress = args._assets

        // payback and sell constants
        const periodAfterInvestment = new BigNumber(1/2)
        await increaseTime(86400 * payback * periodAfterInvestment.toNumber())
        const returnOnPeriod = returnValue.minus(assetValue).times(periodAfterInvestment)
        sellValue = assetValue.plus(returnOnPeriod)
    })


    it('should return the asset when calling getAsset', async () => {
        const asset = await InvestmentAsset.at(assetsAddress[0])
        const assetValues = await asset.getAsset()
        assert.equal(assetValues.length, 13, "The asset must have 13 variables")
        assert.equal(assetValues[0], creditCompany, "The asset owner must be the creditCompany")
    })

    context('Token Supply', () => {
        it("should supply tokens as fuel to the first asset", async () => {
            await token.approve(assetsAddress[1], assetFuel, {from: creditCompany})
            firstAsset = await AssetLibrary.at(assetsAddress[1])
            const {logs} = await firstAsset.supplyFuel(
                assetFuel,
                {from: creditCompany}
            )
            const event = logs.find(e => e.event === 'Supplied')
            const args = event.args
            expect(args).to.include.all.keys([
               '_owner',
               '_amount',
               '_assetFuel'
            ])
        })
    })

    context('Invest', () => {
        it('should add an investment by using the asset', async () => {
            const previousAssetBalance = await getBalance(firstAsset.address)
            const previousInvestorBalance = await getBalance(investor)
            const {logs, receipt} = await firstAsset.invest(
                investor,
                {value: assetValue, from: investor}
            )
            const currentAssetBalance = await getBalance(firstAsset.address)
            const currentInvestorBalance = await getBalance(investor)
            const gasUsed = new BigNumber(receipt.gasUsed)
            const event = logs.find(e => e.event === 'Invested')
            const args = event.args
            expect(args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
            ])
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .minus(assetValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.plus(assetValue).toNumber())
        })

        it("should deny an investment if the asset isn't available", async () => {
            await firstAsset.invest(investor,{from: investor, value: assetValue})
                .should.be.rejectedWith('VM Exception')
        })
    })

    context('Cancel Investment', () => {
        it("should deny a cancelment if the user isn't the investor", async () => {
            await firstAsset.cancelInvestment({from: creditCompany})
                .should.be.rejectedWith('VM Exception')
        })

        it('should cancel a pending investment', async () => {
            const previousAssetBalance = await getBalance(firstAsset.address)
            const previousInvestorBalance = await getBalance(investor)
            const { logs, receipt } = await firstAsset.cancelInvestment({from: investor})
            const event = logs.find(e => e.event === 'Canceled')
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
            ])
            const currentAssetBalance = await getBalance(firstAsset.address)
            const currentInvestorBalance = await getBalance(investor)
            const gasUsed = new BigNumber(receipt.gasUsed)
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .plus(assetValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(assetValue).toNumber())
        })
    })

    context('Refuse Investment', () => {

        it('should add an investment', async () => {
            await firstAsset.invest(investor, {from: investor, value: assetValue})
        })

        it("should deny a refusement if the user isn't the asset owner", async () => {
            await firstAsset.refuseInvestment( { from: investor })
            .should.be.rejectedWith('VM Exception')
        })

        it('should refuse a pending investment', async () => {
            const previousAssetBalance = await getBalance(firstAsset.address)
            const previousInvestorBalance = await getBalance(investor)
            const {logs} = await firstAsset.refuseInvestment({ from: creditCompany })
            let event = logs.find(e => e.event === 'Refused')
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
            ])
            const currentAssetBalance = await getBalance(firstAsset.address)
            const currentInvestorBalance = await getBalance(investor)
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .plus(assetValue)
                .toNumber()
            )
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(assetValue).toNumber())
        })

    })

    context('Withdraw Funds', () => {

        it('should add an investment', async () => {
            await firstAsset.invest(investor,{from: investor, value: assetValue})
        })

        it("should deny a withdrawal if the user isn't the asset owner", async () => {
            await firstAsset.withdrawFunds({ from: investor })
            .should.be.rejectedWith('VM Exception')
        })

        it('should accept a pending investment and withdraw funds', async () => {
            const previousAssetBalance = await getBalance(firstAsset.address)
            const previousCreditCompanyBalance = await getBalance(creditCompany)
            const { logs, receipt } = await firstAsset.withdrawFunds( { from: creditCompany })
            const currentAssetBalance = await getBalance(firstAsset.address)
            const currentCreditCompanyBalance = await getBalance(creditCompany)
            const gasUsed = new BigNumber(receipt.gasUsed)
            const event = logs.find(e => e.event === 'Withdrawal')

            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
            ])
            currentCreditCompanyBalance.toNumber().should.equal(
                previousCreditCompanyBalance
                .plus(assetValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(assetValue).toNumber())
        })

    })

    context('Sell', () => {

        it("should deny a sell order if the user isn't the investor", async() => {
            await firstAsset.sell(sellValue, {from: creditCompany})
            .should.be.rejectedWith('VM Exception')
        })

        it('should sell an asset', async() => {
            const {logs} = await firstAsset.sell(sellValue, { from: investor })
            const event = logs.find(e => e.event === 'ForSale')

            expect(event.args).to.include.all.keys([
                '_investor',
                '_value'
            ])
        })

    })

    context('Cancel sell order', () => {

        it("should deny a sell order cancelment if the user isn't the investor", async () => {
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

    context('Buy', () => {
        
        it("should buy an asset", async () => {
            await firstAsset.sell(sellValue, {from: investor})
            const previousAssetBalance = await getBalance(assetsAddress[1])
            const previousBuyerBalance = await getBalance(secondInvestor)
            const { logs, receipt } = await firstAsset.buy(secondInvestor, { from: secondInvestor, value: sellValue })
            const event = logs.find(e => e.event === 'Invested')
            expect(event.args).to.include.all.keys([ '_owner', '_investor', '_value' ])
            const currentAssetBalance = await getBalance(assetsAddress[1])
            const currentBuyerBalance = await getBalance(secondInvestor)
            const gasUsed = new BigNumber(receipt.gasUsed)
            currentBuyerBalance.toNumber().should.equal(
                previousBuyerBalance
                .minus(sellValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.plus(sellValue).toNumber())
        })
    })

    context('Cancel sale', () => {

        it("should deny a sale cancelment if the user isnt't the buyer", async () => {
            await firstAsset.cancelSale({from: investor})
            .should.be.rejectedWith('VM Exception')
        })

        it("should cancel a sale", async () => {
            const previousAssetBalance = await getBalance(firstAsset.address)
            const previousBuyerBalance = await getBalance(secondInvestor)
            const { logs, receipt } = await firstAsset.cancelSale({from: secondInvestor})
            const event = logs.find(e => e.event === 'Canceled')
            expect(event.args).to.include.all.keys([ '_owner', '_investor', '_value' ])
            const currentAssetBalance = await getBalance(firstAsset.address)
            const currentBuyerBalance = await getBalance(secondInvestor)
            const gasUsed = new BigNumber(receipt.gasUsed)
            currentBuyerBalance.toNumber().should.equal(
                previousBuyerBalance
                .plus(sellValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(sellValue).toNumber())
        })
    })

    context('Refuse sale', () => {

        it("should buy an asset", async () => {
            const previousAssetBalance = await getBalance(firstAsset.address)
            const previousBuyerBalance = await getBalance(secondInvestor)
            const { logs, receipt } = await firstAsset.buy(secondInvestor, { from: secondInvestor, value: sellValue })
            const event = logs.find(e => e.event === 'Invested')
            expect(event.args).to.include.all.keys([ '_owner', '_investor', '_value' ])
            const currentAssetBalance = await getBalance(firstAsset.address)
            const currentBuyerBalance = await getBalance(secondInvestor)
            const gasUsed = new BigNumber(receipt.gasUsed)
            currentBuyerBalance.toNumber().should.equal(
                previousBuyerBalance
                .minus(sellValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.plus(sellValue).toNumber())
        })

        it("should deny a sale refusement if the user isnt't the investor", async () => {
            await firstAsset.refuseSale({from: secondInvestor})
            .should.be.rejectedWith('VM Exception')
        })

        it("should refuse a sale", async () => {
            const previousAssetBalance = await getBalance(firstAsset.address)
            const previousBuyerBalance = await getBalance(secondInvestor)
            const { logs, receipt } = await firstAsset.refuseSale({from: investor})
            const event = logs.find(e => e.event === 'Refused')
            expect(event.args).to.include.all.keys([ '_owner', '_investor', '_value' ])
            const currentAssetBalance = await getBalance(firstAsset.address)
            const currentBuyerBalance = await getBalance(secondInvestor)
            currentBuyerBalance.toNumber().should.equal(
                previousBuyerBalance
                .plus(sellValue)
                .toNumber()
            )
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(sellValue).toNumber())

        })
    })

    context('Accept sale and withdraw funds', () => {

        it("should deny a sale acceptment if the user isnt't the investor", async () => {
            await firstAsset.buy(secondInvestor, { value: sellValue })
            await firstAsset.acceptSale({from: secondInvestor})
            .should.be.rejectedWith('VM Exception')
        })

        it("should accept a sale", async () => {
            const previousAssetBalance = await getBalance(firstAsset.address)
            const previousSellerBalance = await getBalance(investor)
            const asset = await InvestmentAsset.at(firstAsset.address);
            const assetValues = await asset.getAsset();
            const sellValue = assetValues[11];
            const { logs, receipt } = await firstAsset.acceptSale({from: investor})
            const event = logs.find(e => e.event === 'Withdrawal')
            expect(event.args).to.include.all.keys([ '_owner', '_investor', '_value' ])
            const currentAssetBalance = await getBalance(firstAsset.address)
            const currentSellerBalance = await getBalance(investor)
            const gasUsed = new BigNumber(receipt.gasUsed)
            currentSellerBalance.toNumber().should.equal(
                previousSellerBalance
                .plus(sellValue)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetBalance.toNumber().should.equal(previousAssetBalance.minus(sellValue).toNumber())
            const boughtValue = await firstAsset.boughtValue.call();
            sellValue.toNumber().should.equal(boughtValue.toNumber());
        })
    })


    context("Require Asset's Fuel", () => {

        it("should deny the token fuel request if the return of investment isn't delayed", async () => {
            await firstAsset.requireTokenFuel({ from: secondInvestor })
                .should.be.rejectedWith('VM Exception')
        })

        it("should deny the token fuel request if the user isn't the investor", async () => {
            // simulate a long period after the funds transfer
            await increaseTime(16416000)
            await firstAsset.requireTokenFuel({ from: creditCompany })
               .should.be.rejectedWith('VM Exception')
        })

        it("should send the token fuel to the asset's investor", async () => {
            const previousInvestorTokenBalance = await token.balanceOf(secondInvestor)
            const previousAssetTokenBalance = await token.balanceOf(firstAsset.address)
            const { logs, receipt } =  await firstAsset.requireTokenFuel({ from: secondInvestor })
            const event = logs.find(e => e.event === 'TokenWithdrawal')
            expect(event.args).to.include.all.keys([
                '_to',
                '_amount'
            ])
            const currentInvestorTokenBalance = await token.balanceOf(secondInvestor)
            const currentAssetTokenBalance = await token.balanceOf(firstAsset.address)
            currentInvestorTokenBalance.toNumber().should.equal(
                previousInvestorTokenBalance
                .plus(assetFuel)
                .toNumber()
            )
            currentAssetTokenBalance.toNumber().should.equal(previousAssetTokenBalance.minus(assetFuel).toNumber())
        })
    })

    context('Delayed return without remaining tokens', () => {

        it("should deny an investment return if the user isn't the asset owner", async () => {
            await firstAsset.returnInvestment({ from: secondInvestor, value: returnValue })
                .should.be.rejectedWith('VM Exception')
        })

        it('should return the investment with delay', async () => {
            const previousInvestorBalance = await getBalance(secondInvestor)
            const { logs, receipt } = await firstAsset.returnInvestment({ from: creditCompany, value: returnValue })
            const event = logs.find(e => e.event === 'Returned')
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
                '_delayed'
            ])
            assert.equal(event.args._delayed,true,"The investment must be returned with delay")
            const currentInvestorBalance = await getBalance(secondInvestor)
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .plus(returnValue)
                .toNumber()
            )
        })

    })

    context('Delayed return with remaining tokens', () => {
        it("should supply tokens to the second asset", async () => {
            await token.approve(assetsAddress[2], assetFuel, {from: creditCompany})
            secondAsset = await AssetLibrary.at(assetsAddress[2])
            await secondAsset.supplyFuel(assetFuel, { from: creditCompany })
        })

        it('should add an investment', async () => {
            secondAsset = await AssetLibrary.at(assetsAddress[2])
            await secondAsset.invest(investor,{from: investor, value: assetValue})
        })

        it('should accept a pending investment and withdraw funds', async () => {
            await secondAsset.withdrawFunds({from: creditCompany})
        })

        it("should return the investment with delay and send tokens to the asset's investor", async () => {
            // simulate a long period after the funds transfer
            await increaseTime(16416000)
            const previousInvestorTokenBalance = await token.balanceOf(investor)
            const previousAssetTokenBalance = await token.balanceOf(secondAsset.address)
            const { logs, receipt } = await secondAsset.returnInvestment({ from: creditCompany, value: returnValue })
            const event = logs.find(e => e.event === 'Returned')
            expect(event.args).to.include.all.keys([
                '_owner',
                '_investor',
                '_value',
                '_delayed'
            ])
            assert.equal(event.args._delayed,true,"The investment must be returned with delay")
            const currentInvestorTokenBalance = await token.balanceOf(investor)
            const currentAssetTokenBalance = await token.balanceOf(secondAsset.address)
            currentInvestorTokenBalance.toNumber().should.equal(
                previousInvestorTokenBalance
                .plus(assetFuel)
                .toNumber()
            )
            currentAssetTokenBalance.toNumber().should.equal(previousAssetTokenBalance.minus(assetFuel).toNumber())
        })
    })

    context('Correct return with remaining tokens', () => {
        it("should supply tokens to the third asset", async () => {
            await token.approve(assetsAddress[3], assetFuel, {from: creditCompany})
            thirdAsset = await AssetLibrary.at(assetsAddress[3])
            await thirdAsset.supplyFuel(assetFuel, { from: creditCompany })
        })

        it('should add an investment', async () => {
            await thirdAsset.invest(investor, { from: investor, value: assetValue })
        })

        it('should accept a pending investment and withdraw funds', async () => {
            await thirdAsset.withdrawFunds({from: creditCompany})
        })

        it("should return the investment correctly and send tokens to the asset's owner", async () => {
            const previousCreditCompanyTokenBalance = await token.balanceOf(creditCompany)
            const previousAssetTokenBalance = await token.balanceOf(thirdAsset.address)
            const { logs } = await thirdAsset.returnInvestment({ from: creditCompany, value: returnValue })
            const event = logs.find(e => e.event === 'Returned')
            expect(event.args).to.include.all.keys([ '_owner', '_investor', '_value', '_delayed' ])
            assert.equal(event.args._delayed,false,"The investment must be returned without delay")
            const currentCreditCompanyTokenBalance = await token.balanceOf(creditCompany)
            const currentAssetTokenBalance = await token.balanceOf(thirdAsset.address)
            currentCreditCompanyTokenBalance.toNumber().should.equal(
                previousCreditCompanyTokenBalance
                .plus(assetFuel)
                .toNumber()
            )
            currentAssetTokenBalance.toNumber().should.equal(previousAssetTokenBalance.minus(assetFuel).toNumber())
        })
    })

    context('Return the investment when the asset is being sold and refund the buyer', () => {
        it('should add an investment', async () => {
            fourthAsset = await AssetLibrary.at(assetsAddress[4])
            await fourthAsset.invest(investor,{ from: investor, value: assetValue })
        })

        it('should accept a pending investment and withdraw funds', async () => {
            await fourthAsset.withdrawFunds({from: creditCompany})
        })

        it('should sell the asset', async () => {
            await fourthAsset.sell(sellValue, {from: investor})
        })
        
        it('should buy the asset', async () => {
            await fourthAsset.buy(secondInvestor, { value: sellValue })
        })
        it("should return the investment to the investor and refund the buyer", async () => {
            const previousInvestorBalance = await getBalance(investor)
            const previousBuyerBalance = await getBalance(secondInvestor)
            const { logs } = await fourthAsset.returnInvestment({ from: creditCompany, value: returnValue })
            const event = logs.find(e => e.event === 'Returned')
            assert.equal(event.args._investor, investor, "The investment must be returned to the asset's investor")
            const currentInvestorBalance = await getBalance(investor)
            const currentBuyerBalance = await getBalance(secondInvestor)
            currentBuyerBalance.toNumber().should.equal(
                previousBuyerBalance
                .plus(sellValue)
                .toNumber()
            )
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .plus(returnValue)
                .toNumber()        
            )
        })
    })

})
