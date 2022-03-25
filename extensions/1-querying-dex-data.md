# Extension 1: Querying Data from Decentralized Exchanges

You are allowed to use Postman, Insomnia or any other API Client you are comfortable with.

## Specifications

Given the following resources: 

* Uniswap GraphQL API Endpoint: https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2/
	
* Uniswap GraphQL API Interface: https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2/graphql

1. Using the above API endpoint, retrieve the schema (submit as a JSON file. Hint: browser inspector)

2. Using above API, query 100 pairs, with below attributes (submit the CURL query, Hint: use pairs())

```
id
token0 id
token0 symbol
token1 id
token1 symbol
```

3. Repeat #2 with this condition, with reserveETH greater than 2

4. Using this pair id `0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc`, query below attributes (submit the CURL query, Hint: use `pair()`)
using pair

```
id
token0 id
token0 symbol
token1 id
token1 symbol
trackedReserveETH
reserveETH
reserveUSD
token0Price
token1Price
volumeToken0
volumeToken1
volumeUSD
```

## Scoring Guide

Submissions will be evaluated based on the following criteria:

* Ability to meet the above 4 challenge (how much attributes are given as per the question, except #1)
* Proficiency in using API Client tools, and ability to demonstrate re-usability like request Import/Export.
