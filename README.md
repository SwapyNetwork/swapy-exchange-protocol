# Swapy Exchange Protocol
#### NOTE: The protocol was previously created on a private repository. Since the beginning, we have thought about open sourcing the protocol as the community has much to contribute to it as well as the protocol and the source code may be helpful to other projects too. As the protocol achieved a certain level of maturity we decided to move it to a public repository under Apache 2.0 License (without its history). We invite you all to join us in our dream of a world in which everyone has ACCESS TO CREDIT. The Swapy team is looking forward to your comments, issues, contributions, derivations, and so on.


## Table of Contents

* [Project Usage](#project-usage)
* [Architecture](#architecture)
* [Contracts](#contracts)

## Project Usage

In construction...

## Architecture

In construction...

## Contracts

#### [SwapyExchange.sol](https://github.com/swapynetwork/swapy-exchange-protocol/blob/master/contracts/protocol/SwapyExchange.sol)
Credit companies can order investment by using the SwapyExchange contract. It works as a factory of InvestmentOffer contract and organizes the protocol versioning. 

### [InvestmentOffer.sol](https://github.com/swapynetwork/swapy-exchange-protocol/blob/master/contracts/protocol/InvestmentOffer.sol)
InvestmentOffer defines a fund raising contract with its payback period and gross return of investment. Its owner can create investment assets associated to the fund raising and sell it to investors. 

### [InvestmentAsset.sol](https://github.com/swapynetwork/swapy-exchange-protocol/blob/master/contracts/protocol/InvestmentAsset.sol)
InvestmentAsset defines a fund raising asset with its value, investor and agreement terms hash. It provides methods to interact with the asset contract and agree the investment. These methods are only accessible by the investor or the credit company, according to its functionalities.
