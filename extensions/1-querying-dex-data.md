# Extension 1: Querying Data from Decentralized Exchanges

You are allowed to use Postman, Insomnia or any other API Client you are comfortable with.

## Specifications

Resource:

- Uniswap GraphQL API Docs: https://docs.uniswap.org/api/subgraph/overview
- UniswapV3 GraphQL API Endpoint: `https://gateway.thegraph.com/api/<YOUR_API_KEY_HERE>/subgraphs/id/5zvR82QoaXYFyDEKLZ9t6v9adgnptxYpKpSbxtgVENFV`
  - To retrieve your own API key, you'll need to connect your crypto wallet to the [Studio](https://thegraph.com/studio/apikeys/). You do not need to have funds in this wallet, you are free to use a fresh one.

1.  Given the documentation above, retrieve the schema via an Introspection Query

    - Submit as a `.json` or `.graphql` file
    - _Hint: Use your API client (Postman/Insomnia/etc) to send an introspection query, or use a GraphQL playground on your browser_

2.  Using above API, query 100 pools, with below attributes

    ```
    id
    token0 id
    token0 symbol
    token1 id
    token1 symbol

    ```

    - Submit the `cURL` query
    - _Hint: use `pools()` - details can be obtained from the GraphQL schema_

3.  Repeat #2 with additional conditions: query 100 pools with the **highest liquidity** that were **created in the past week**

    - Submit the `cURL` query

4.  Using this USDC/WETH pool `0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8`, query the below attributes:

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

    - Submit the `cURL` query
    - _Hint: refer back to the schema_

## Scoring Guide

Submissions will be evaluated based on the following criteria:

- Ability to complete the above 4 challenges (how many attributes are correctly retrieved as per the question, except #1)
- Proficiency in using API Client tools, and ability to demonstrate re-usability like request Import/Export.

## Deliverables

Please submit:

1. Schema file (`.json` or `.graphql`) from Question 1
2. cURL command for Question 2
3. cURL command for Question 3
4. cURL command for Question 4
5. (Optional) Collection export (e.g., Postman .json, Insomnia .yaml, or equivalent from your chosen tool)
