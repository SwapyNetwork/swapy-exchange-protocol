
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

// --- Test variables
// Contracts
let token = null
let library = null
let protocol = null
let firstAsset = null
let secondAsset = null
let thirdAsset = null
let fourthAsset = null
let fifthAsset = null
// Assets
let assetsAddress = []
// Agents
let investor = null
let creditCompany = null
let Swapy = null
let secondInvestor = null
// Util
let gasPrice = null
let sellValue = null


contract('SwapyExchange', async accounts => {

    before( async () => {

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

        // payback and sell constants
        const periodAfterInvestment = new BigNumber(1/2)
        await increaseTime(86400 * payback * periodAfterInvestment.toNumber())
        const returnOnPeriod = returnValue.minus(assetValue).times(periodAfterInvestment)
        sellValue = assetValue.plus(returnOnPeriod)

    })

    it("should have a version", async () => {
        const version = await protocol.VERSION.call()
        should.exist(version)
    })

    context('Fundraising offers', () => {

        it("should create an investment offer with assets", async () => {
            const {logs} = await protocol.createOffer(
                payback,
                grossReturn,
                currency,
                assets,
                {from: creditCompany}
            )
            const event = logs.find(e => e.event === 'LogOffers')
            const args = event.args
            expect(args).to.include.all.keys([ '_from', '_protocolVersion', '_assets' ])
            assetsAddress = args._assets
            assert.equal(args._from, creditCompany, 'The credit company must be the offer owner')
            assert.equal(args._assets.length, assets.length, 'The count of created assets must be equal the count of sent')
            firstAsset = await AssetLibrary.at(assetsAddress[0])
            secondAsset = await AssetLibrary.at(assetsAddress[1])
            thirdAsset = await AssetLibrary.at(assetsAddress[2])
            fourthAsset = await AssetLibrary.at(assetsAddress[3])
            fifthAsset = await AssetLibrary.at(assetsAddress[4])
            await token.approve(assetsAddress[0], assetFuel, {from: creditCompany})
            await token.approve(assetsAddress[1], assetFuel, {from: creditCompany})
            await token.approve(assetsAddress[2], assetFuel, {from: creditCompany})
            await token.approve(assetsAddress[3], assetFuel, {from: creditCompany})
            await token.approve(assetsAddress[4], assetFuel, {from: creditCompany})
            await firstAsset.supplyFuel(assetFuel, { from: creditCompany })
            await secondAsset.supplyFuel(assetFuel, { from: creditCompany })
            await thirdAsset.supplyFuel(assetFuel, { from: creditCompany })
            await fourthAsset.supplyFuel(assetFuel, { from: creditCompany })
            await fifthAsset.supplyFuel(assetFuel, { from: creditCompany })
        })
    })

    context('Investment', () => {

        it("should add an investment of many assets", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            // balances before invest
            let previousAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                previousAssetsBalance = previousAssetsBalance.plus(assetBalance)
            }
            const previousInvestorBalance = await getBalance(investor)
            const { logs, receipt } = await protocol.invest( assets, assetValue, { value: assetValue * assets.length, from: investor })
            // balances after invest
            let currentAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                currentAssetsBalance = currentAssetsBalance.plus(assetBalance)
            }
            const currentInvestorBalance = await getBalance(investor)
            const gasUsed = new BigNumber(receipt.gasUsed)
            const event = logs.find(e => e.event === 'LogInvestments')
            const args = event.args
            expect(args).to.include.all.keys([ '_investor', '_assets', '_value' ])
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .minus(assetValue * assets.length)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetsBalance.toNumber().should.equal(previousAssetsBalance.plus(assetValue * assets.length).toNumber())
        })

        it("should deny a cancelment if the user isn't the investor", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            await protocol.cancelInvestment(assets, { from: creditCompany })
                .should.be.rejectedWith('VM Exception')
        })

        it("should cancel an investment on many assets", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            // balances before invest
            let previousAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                previousAssetsBalance = previousAssetsBalance.plus(assetBalance)
            }
            const previousInvestorBalance = await getBalance(investor)
            const { receipt } = await protocol.cancelInvestment( assets, { from: investor })
            // balances after invest
            let currentAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                currentAssetsBalance = currentAssetsBalance.plus(assetBalance)
            }
            const currentInvestorBalance = await getBalance(investor)
            const gasUsed = new BigNumber(receipt.gasUsed)
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .plus(assetValue * assets.length)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetsBalance.toNumber().should.equal(previousAssetsBalance.minus(assetValue * assets.length).toNumber())

        })

        it("should deny an investment refusement if the user isn't the owner", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            await protocol.invest( assets, assetValue, { value: assetValue * assets.length, from: investor })
            await protocol.refuseInvestment(assets, { from: investor })
                .should.be.rejectedWith('VM Exception')
        })

        it("should refuse an investment on many assets", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            // balances before invest
            let previousAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                previousAssetsBalance = previousAssetsBalance.plus(assetBalance)
            }
            const previousInvestorBalance = await getBalance(investor)
            await protocol.refuseInvestment(assets, { from: creditCompany })
            // balances after invest
            let currentAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                currentAssetsBalance = currentAssetsBalance.plus(assetBalance)
            }
            const currentInvestorBalance = await getBalance(investor)
            currentInvestorBalance.toNumber().should.equal(
                previousInvestorBalance
                .plus(assetValue * assets.length)
                .toNumber()
            )
            currentAssetsBalance.toNumber().should.equal(previousAssetsBalance.minus(assetValue * assets.length).toNumber())
        })

        it("should deny an investment withdrawal if the user isn't the owner", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            await protocol.invest( assets, assetValue, { value: assetValue * assets.length, from: investor })
            await protocol.withdrawFunds(assets, { from: investor })
                .should.be.rejectedWith('VM Exception')
        })

        it("should withdraw funds on many assets", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            // balances before invest
            let previousAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                previousAssetsBalance = previousAssetsBalance.plus(assetBalance)
            }
            const previousCreditCompanyBalance = await getBalance(creditCompany)
            const {receipt} = await protocol.withdrawFunds( assets, { from: creditCompany })
            // balances after invest
            let currentAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                currentAssetsBalance = currentAssetsBalance.plus(assetBalance)
            }
            const currentCreditCompanyBalance = await getBalance(creditCompany)
            const gasUsed = new BigNumber(receipt.gasUsed)
            currentCreditCompanyBalance.toNumber().should.equal(
                previousCreditCompanyBalance
                .plus(assetValue * assets.length)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetsBalance.toNumber().should.equal(previousAssetsBalance.minus(assetValue * assets.length).toNumber())
        })

        it("should deny collateral tokens request if the user isn't the investor", async() => {
            // simulate a long period after the funds transfer
            await increaseTime(16416000)
            const assets = [assetsAddress[0], assetsAddress[1]]
            await protocol.requireTokenFuel(assets, { from: creditCompany })
            .should.be.rejectedWith('VM Exception')
        })

        it("should request collateral tokens of many assets", async() => {
            const assets = [assetsAddress[0], assetsAddress[1]]
            const previousInvestorTokenBalance = await token.balanceOf(investor)
            let previousAssetsTokenBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await token.balanceOf(assetAddress)
                previousAssetsTokenBalance = previousAssetsTokenBalance.plus(assetBalance)
            }
            await protocol.requireTokenFuel(assets, { from: investor })
            // balances after invest
            let currentInvestorTokenBalance = await token.balanceOf(investor)
            let currentAssetsTokenBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await token.balanceOf(assetAddress)
                currentAssetsTokenBalance = currentAssetsTokenBalance.plus(assetBalance)
            }
            currentInvestorTokenBalance.toNumber().should.equal(
                previousInvestorTokenBalance
                .plus(assetFuel.times(new BigNumber(assets.length)))
                .toNumber()
            )
            currentAssetsTokenBalance.toNumber().should.equal(previousAssetsTokenBalance.minus(assetFuel.times(new BigNumber(assets.length))).toNumber())
        })

    })

    context('Market Place', () => {

        it("should deny a sell order if the user isn't the investor", async() => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            const values = [sellValue, sellValue, sellValue, sellValue, sellValue]
            await protocol.sellAssets(assets, values, { from: creditCompany })
                .should.be.rejectedWith('VM Exception')
        })
    
        it('should create sell orders of many assets', async() => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            const values = [sellValue, sellValue, sellValue, sellValue, sellValue]
            const { logs } = await protocol.sellAssets(assets, values, { from: investor })
            const event = logs.find(e => e.event === 'LogForSale')
            expect(event.args).to.include.all.keys([ '_investor', '_asset', '_value' ])
        })

        it("should deny a sell order cancelment if the user isn't the investor", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            await protocol.cancelSellOrder(assets, { from: creditCompany })
            .should.be.rejectedWith('VM Exception')
        })

        it("should cancel a sell", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            const { receipt } = await protocol.cancelSellOrder(assets, { from: investor })
            receipt.status.should.equal(1)
        })

        it("should buy an asset" , async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            const values = [sellValue, sellValue, sellValue, sellValue, sellValue]
            await protocol.sellAssets(assets, values, { from: investor })
            const asset = assets[0]
            const previousAssetBalance = await getBalance(asset)
            const previousBuyerBalance = await getBalance(secondInvestor)
            const { logs, receipt } = await protocol.buyAsset(asset, { from: secondInvestor, value: sellValue })
            const event = logs.find(e => e.event === 'LogBought')
            expect(event.args).to.include.all.keys([ '_buyer', '_asset', '_value' ])
            const currentAssetBalance = await getBalance(asset)
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

        it("should deny a sale cancelment if the user isn't the buyer", async () => {
            const assets = [assetsAddress[0]]
            await protocol.cancelSale(assets, { from: investor })
            .should.be.rejectedWith('VM Exception')
        })

        it("should cancel many sales", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            await protocol.buyAsset(assets[1], { from: secondInvestor, value: sellValue })
            await protocol.buyAsset(assets[2], { from: secondInvestor, value: sellValue })
            await protocol.buyAsset(assets[3], { from: secondInvestor, value: sellValue })
            await protocol.buyAsset(assets[4], { from: secondInvestor, value: sellValue })
            let previousAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                previousAssetsBalance = previousAssetsBalance.plus(assetBalance)
            }
            const previousBuyerBalance = await getBalance(secondInvestor)
            const { receipt } = await protocol.cancelSale(assets, { from: secondInvestor })
            let currentAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                currentAssetsBalance = currentAssetsBalance.plus(assetBalance)
            }
            const currentBuyerBalance = await getBalance(secondInvestor)
            const gasUsed = new BigNumber(receipt.gasUsed)
            currentBuyerBalance.toNumber().should.equal(
                previousBuyerBalance
                .plus(sellValue * assets.length)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetsBalance.toNumber().should.equal(previousAssetsBalance.minus(sellValue * assets.length).toNumber())
        })

        it("should deny a sale refusement if the user isn't the investor", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            const values = [sellValue, sellValue, sellValue, sellValue, sellValue]
            await protocol.buyAsset(assets[0], { from: secondInvestor, value: sellValue })
            await protocol.buyAsset(assets[1], { from: secondInvestor, value: sellValue })
            await protocol.buyAsset(assets[2], { from: secondInvestor, value: sellValue })
            await protocol.buyAsset(assets[3], { from: secondInvestor, value: sellValue })
            await protocol.buyAsset(assets[4], { from: secondInvestor, value: sellValue })
            await protocol.refuseSale(assets, { from: secondInvestor })
            .should.be.rejectedWith('VM Exception')
        })

        it("should refuse many sales", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            let previousAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                previousAssetsBalance = previousAssetsBalance.plus(assetBalance)
            }
            const previousBuyerBalance = await getBalance(secondInvestor)
            await protocol.refuseSale(assets, { from: investor })
            let currentAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                currentAssetsBalance = currentAssetsBalance.plus(assetBalance)
            }
            const currentBuyerBalance = await getBalance(secondInvestor)
            currentBuyerBalance.toNumber().should.equal(
                previousBuyerBalance
                .plus(sellValue * assets.length)
                .toNumber()
            )
            currentAssetsBalance.toNumber().should.equal(previousAssetsBalance.minus(sellValue * assets.length).toNumber())
        })

        it("should deny a sale acceptment if the user isnt't the investor", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            const values = [sellValue, sellValue, sellValue, sellValue, sellValue]
            await protocol.buyAsset(assets[0], { from: secondInvestor, value: sellValue })
            await protocol.buyAsset(assets[1], { from: secondInvestor, value: sellValue })
            await protocol.buyAsset(assets[2], { from: secondInvestor, value: sellValue })
            await protocol.buyAsset(assets[3], { from: secondInvestor, value: sellValue })
            await protocol.buyAsset(assets[4], { from: secondInvestor, value: sellValue })
            await protocol.acceptSale(assets, { from: secondInvestor })
            .should.be.rejectedWith('VM Exception')
        })

        it("should accept many sales", async () => {
            const assets = [assetsAddress[0], assetsAddress[1], assetsAddress[2], assetsAddress[3], assetsAddress[4]]
            let previousAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets){
                let assetBalance = await getBalance(assetAddress)
                previousAssetsBalance = previousAssetsBalance.plus(assetBalance)
            }
            const previousSellerBalance = await getBalance(investor)
            const { receipt } = await protocol.acceptSale(assets, { from: investor })
            let currentAssetsBalance = new BigNumber(0)
            for(let assetAddress of assets)  { 
                let assetBalance = await getBalance(assetAddress)
                currentAssetsBalance = currentAssetsBalance.plus(assetBalance)
            }
            const currentSellerBalance = await getBalance(investor)
            const gasUsed = new BigNumber(receipt.gasUsed)
            currentSellerBalance.toNumber().should.equal(
                previousSellerBalance
                .plus(sellValue * assets.length)
                .minus(gasPrice.times(gasUsed))
                .toNumber()
            )
            currentAssetsBalance.toNumber().should.equal(previousAssetsBalance.minus(sellValue * assets.length).toNumber())
        })
    
    })

})
