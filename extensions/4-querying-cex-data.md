# Extension 4: Building interface to query data from Centralized Exchange

Build an interface to query data from centralized exchanges

## Specifications
#### Section 1 - Coding the methods

- refers to file **4-section-1-ruby-pseudocode-template.rb** for submission format (you may use any language of your preference)

1. Using the [Binance API (exchange-information) endpoint](https://binance-docs.github.io/apidocs/spot/en/#exchange-information), build a method that returns an array of hashes with following attributes. Name this method `pairs`

```
{
 base: <baseAsset>,
 target: <quoteAsset>,
 market: "binance"
}
```

2. Using the [Binance API (ticker) endpoint](https://binance-docs.github.io/apidocs/spot/en/#24hr-ticker-price-change-statistics), build a method that accepts 2 parameter, `base` and `target` as string and returns a `ticker object` with following attributes. Name this method `ticker`


```
{
    base: <base parameter>,
    target: <target parameter>,
    market: "binance",
    bid: <bidPrice>,
    ask: <askPrice>,
    last: <lastPrice>,
    volume: <volume>
}
```

3. Using the [Binance API (orderbook) endpoint](https://binance-docs.github.io/apidocs/spot/en/#order-book), build a method that accepts 2 parameter `base` and `target` as string, and returns a hash with following attributes. Name this method `orderbook`

```
{
    base: <base parameter>,
    target: <target parameter>,
    market: "binance",
    asks: <array of ask hash - refer to bid/ask hash below>,
    bids: <array of bid hash - refer to bid/ask hash below>
}
```

bid/ask hash
```
{
    price: <PRICE>,
    amount: <QTY>
}
```

#### Section 2 - Running the script

- refers to file **4-section-2-sample-submission** for submission format

1. run `pairs`, copy the results in a snippet

2. run `ticker('btc', 'usdt')`, copy the results in a snippet

3. run `orderbook('btc', 'usdt')`, copy the results in a snippet

## Scoring Guide

Submissions will be evaluated based on the following criteria:

- Ability to meet the above challenges (2 sections)

#### Extra Credits

- Test coverage and overall approach to automated testing including unit tests.
