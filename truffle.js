var bip39 = require("bip39");
var hdkey = require('ethereumjs-wallet/hdkey');
var ProviderEngine = require("web3-provider-engine");
var WalletSubprovider = require('web3-provider-engine/subproviders/wallet.js');
var Web3Subprovider = require("web3-provider-engine/subproviders/web3.js");
var Web3 = require("web3");

// Get our mnemonic and create an hdwallet
var mnemonic = process.env.WALLET_MNEMONIC;
var hdwallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(mnemonic));
// Get the first account using the standard hd path.
var wallet_hdpath = "m/44'/60'/0'/0/";
var wallet = hdwallet.derivePath(wallet_hdpath + "0").getWallet();
var address = "0x" + wallet.getAddress().toString("hex");

// Configure the custom provider
var engine = new ProviderEngine();
const FilterSubprovider = require('web3-provider-engine/subproviders/filters.js')
engine.addProvider(new FilterSubprovider())
engine.addProvider(new WalletSubprovider(wallet, {}));
var providerUrl = process.env.PROVIDER_URL;
engine.addProvider(new Web3Subprovider(new Web3.providers.HttpProvider(providerUrl)));
engine.start(); // Required by the provider engine.


const network_id = process.env.NETWORK_ID;
const dev_network_id = process.env.DEV_NETWORK_ID;

module.exports = {
  networks: {
    custom : {
      network_id: network_id, // custom network id
      provider: engine, // Use our custom provider
      from: address,     // Use the address we derived
      gas: 4670000
    },
    dev : {
      host: "localhost",
      network_id: '*',
      port: 8545
    },
    test : {
      host: "localhost",
      network_id: '*',
      port: 8545
    }
  },
  rpc: {
    // Use the default host and port when not using ropsten
    host: "localhost",
    port: 8545
  }
};
