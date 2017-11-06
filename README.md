# Swapy Exchange Protocol
#### NOTE: The protocol was previously created on a private repository. Since the beginning, we have thought about open sourcing the protocol as the community has much to contribute to it as well as the protocol and the source code may be helpful to other projects too. As the protocol achieved a certain level of maturity we decided to move it to a public repository under Apache 2.0 License (without its history). We invite you all to join us in our dream of a world in which everyone has ACCESS TO CREDIT. The Swapy team is looking forward to your comments, issues, contributions, derivations, and so on.
[![Join the chat at https://gitter.im/swapynetwork/general](https://badges.gitter.im/swapynetwork/general.svg)](https://gitter.im/swapynetwork/general?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)


## Table of Contents

* [Architecture](#architecture)
* [Contracts](#contracts)
* [Setup](#setup)

## Architecture
The diagram below describes the flow of fundraising provided by [Swapy Exchange](https://www.swapy.network/) protocol.
![architecture-diagram-1](https://www.swapy.network/images/diagrams/1-investment-flow.png)

## Contracts

### [SwapyExchange.sol](https://github.com/swapynetwork/swapy-exchange-protocol/blob/master/contracts/SwapyExchange.sol)
Credit companies can order investment by using the SwapyExchange contract. It works as a factory of InvestmentOffer contract and organizes the protocol versioning.

### [InvestmentOffer.sol](https://github.com/swapynetwork/swapy-exchange-protocol/blob/master/contracts/investment/InvestmentOffer.sol)
InvestmentOffer defines a fundraising contract with its payback period and gross return of investment. Its owner can create investment assets associated to the fundraising and sell it to investors.

### [InvestmentAsset.sol](https://github.com/swapynetwork/swapy-exchange-protocol/blob/master/contracts/investment/InvestmentAsset.sol)
InvestmentAsset defines a fundraising asset with its value, investor and agreement terms hash. It provides methods to interact with the asset contract and agree the investment. These methods are only accessible by the investor or the credit company, according to its functionalities.

## Setup

Install [Node v6.11.2](https://nodejs.org/en/download/releases/)

[Truffle](http://truffleframework.com/) is used for deployment. We run the version installed from our dependencies using npm scripts, but if you prefer to install it globally you can do:
```
$ npm install -g truffle
```

Install project dependencies:
```
$ npm install
```
For setup your wallet configuration, addresses and blockchain node provider to deploy, an environment file is necessary. We provide a `sample.env` file. We recommend that you set up your own variables and rename the file to `.env`.

sample.env
```
export WALLET_ADDRESS="0x43...F0932X"
export NETWORK_ID=...
export PROVIDER_URL="https://yourfavoriteprovider.../..."
export WALLET_MNEMONIC="twelve words mnemonic ... potato bread coconut pencil"
```
Use your own provider. Some known networks below:
#### NOTE: the current protocol version is not intended to be used on mainnet.

| Network   | Description        | URL                         |
|-----------|--------------------|-----------------------------|
| Mainnet   | production network | https://mainnet.infura.io   |
| Ropsten   | test network       | https://ropsten.infura.io   |
| INFURAnet | test network       | https://infuranet.infura.io |
| Kovan     | test network       | https://kovan.infura.io     |
| Rinkeby   | test network       | https://rinkeby.infura.io   |
| IPFS      | gateway            | https://ipfs.infura.io      |
| Local     | Local provider     | http://localhost:8545       |
| Etc       | ...                | ...                         |

Use a NETWORK_ID that matches with your network:
* 0: Olympic, Ethereum public pre-release testnet
* 1: Frontier, Homestead, Metropolis, the Ethereum public main network
* 1: Classic, the (un)forked public Ethereum Classic main network, chain ID 61
* 1: Expanse, an alternative Ethereum implementation, chain ID 2
* 2: Morden, the public Ethereum testnet, now Ethereum Classic testnet
* 3: Ropsten, the public cross-client Ethereum testnet
* 4: Rinkeby, the public Geth Ethereum testnet
* 42: Kovan, the public Parity Ethereum testnet
* 7762959: Musicoin, the music blockchain
* etc

After that, make available your environment file inside the bash context:
```
$ source .env
```

By using a local network, this lecture may be useful: [Connecting to the network](https://github.com/ethereum/go-ethereum/wiki/Connecting-to-the-network)

Compile the contracts with truffle:
```
$ npm run compile
```
Run our migrations:
```
$ npm run migrate
```
We're running the contracts in a custom network defined in  [truffle.js](https://github.com/swapynetwork/swapy-exchange-protocol/blob/master/truffle.js).

After the transaction mining, the protocol is disponible for usage.

We're using Truffle's test support. The script scripts/test.sh creates a local network and call the unit tests.

Type 
```
$ npm test
```
and run our tests.

[Truffle console](https://truffle.readthedocs.io/en/beta/getting_started/console/) can be used to interact with protocol. For example:
```
$ truffle console --network custom
```
```
truffle(custom)> SwapyExchange.deployed().VERSION.call(); // "1.0.0"
```
