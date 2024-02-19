# Extension 1: Querying Data from Decentralized Exchanges

You are allowed to use Postman, Insomnia or any other API Client you are comfortable with.

## Specifications

Given the following resources:

* Uniswap GraphQL API Endpoint: https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3

* Uniswap GraphQL API Interface: https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3/graphql

1. Using the above API endpoint, retrieve the schema (submit as a JSON file. Hint: browser inspector)

2. Using above API, query 100 pairs, with below attributes (submit the CURL query, Hint: use pairs())

```
id
token0 id
token0 symbol
token1 id
token1 symbol
```

3. Repeat #2 with this condition, with liqudity greater than 2 ETH

4. Using this pool id `0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640`, query below attributes (submit the CURL query, Hint: use `pools()`)

```
id
token0 id
token0 symbol
token0 derivedETH
token1 id
token1 symbol
token1 derivedETH
liquidity
token0Price
token1Price
volumeToken0
volumeToken1
volumeUSD
totalValueLockedUSD
```

## Scoring Guide

Submissions will be evaluated based on the following criteria:

* Ability to meet the above 4 challenge (how much attributes are given as per the question, except #1)
* Proficiency in using API Client tools, and ability to demonstrate re-usability like request Import/Export.
