// helpers
const increaseTime  = require('./helpers/increaseTime');

const should = require('chai')
    .use(require('chai-as-promised'))
    .should()
const expect = require('chai').expect;

// --- Handled contracts
const FinId = artifacts.require("./identity/FinId.sol");

// --- Test variables
let finId = null;
let investor = null;
let creditCompany = null;

const CREDIT_COMPANY = 0;
const INVESTOR = 1;

contract('FinId', accounts => {

    before( async () => {
        Swapy = accounts[0];
        creditCompany = accounts[1];
        investor = accounts[2];
        finId = await FinId.new({ from: Swapy });
    });

    it("should create a new user as a Credit Company", async () => {
        await finId.newUser(CREDIT_COMPANY, { from: creditCompany });
        const createdUser = await finId.getUser(creditCompany);
        expect(createdUser.toNumber()).to.equal(CREDIT_COMPANY);
    })

    it("should create a new user as an Investor", async () => {
        await finId.newUser(INVESTOR, { from: investor });
        const createdUser = await finId.getUser(investor);
        expect(createdUser.toNumber()).to.equal(INVESTOR);
    })
})
