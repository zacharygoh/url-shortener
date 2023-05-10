class CexData
  def initialize
  end

  def pairs
    # return an array of hashes
    # sample results

    # [
    #   {
    #     base: "BTC",
    #     target: "USDT",
    #     market: "binance"
    #   },
    #   {
    #     base: "ETH",
    #     target: "USDC",
    #     market: "binance"
    #   },
    #   ...
    # ]
  end

  def ticker(base, target)
    # return a hash
    # sample result

    # {
    #   base: "BTC",
    #   target: "USDT",
    #   market: "binance",
    #   bid: 2,
    #   ask: 2,
    #   last: 2,
    #   volume: 2
    # }
  end

  def orderbook(base, target)
    # return a hash
    # sample result

    # {
    #   base: "BTC",
    #   target: "USDT",
    #   market: "binance",
    #   asks: [
    #     {
    #       price: 3,
    #       amount: 100
    #     },
    #     {
    #       price: 4,
    #       amount: 200
    #     }
    #   ],
    #   bids: [
    #     {
    #       price: 1,
    #       amount: 100
    #     },
    #     {
    #       price: 2,
    #       amount: 200
    #     }
    #   ]
    # }
  end
end
