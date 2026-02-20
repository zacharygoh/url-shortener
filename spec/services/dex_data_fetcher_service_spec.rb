# frozen_string_literal: true

require "rails_helper"

RSpec.describe DexDataFetcherService do
  let(:api_key) { "test_api_key_123" }
  let(:graph_url) { "https://gateway.thegraph.com/api/#{api_key}/subgraphs/id/#{DexDataFetcherService::SUBGRAPH_ID}" }

  describe "#call" do
    context "when THE_GRAPH_API_KEY is not set" do
      it "returns error without making HTTP request" do
        service = described_class.new(query_type: :pools_list, api_key: nil)

        stub = stub_request(:post, %r{gateway\.thegraph\.com/}).to_return(body: "{}")

        result = service.call

        expect(result).to eq({ error: "THE_GRAPH_API_KEY is not set" })
        expect(stub).not_to have_been_requested
      end
    end

    context "with pools_list (Q2)" do
      it "POSTs correct GraphQL and returns normalized pools" do
        body = {
          data: {
            pools: [
              { id: "0x1", token0: { id: "t0", symbol: "USDC" }, token1: { id: "t1", symbol: "WETH" } }
            ]
          }
        }
        stub_request(:post, graph_url)
          .with(body: hash_including("query" => /pools\(first: 100\)/))
          .to_return(body: body.to_json, headers: { "Content-Type" => "application/json" })

        service = described_class.new(query_type: :pools_list, limit: 100, api_key: api_key)
        result = service.call

        expect(result).to match(hash_including(:data))
        expect(result[:data]["pools"]).to be_an(Array)
        expect(result[:data]["pools"].first["id"]).to eq("0x1")
        expect(result[:data]["pools"].first["token0"]["symbol"]).to eq("USDC")
      end

      it "uses custom limit in query" do
        stub_request(:post, graph_url)
          .with(body: hash_including("query" => /pools\(first: 50\)/))
          .to_return(body: { data: { pools: [] } }.to_json, headers: { "Content-Type" => "application/json" })

        described_class.new(query_type: :pools_list, limit: 50, api_key: api_key).call

        expect(WebMock).to have_requested(:post, graph_url).with(body: /first: 50/)
      end
    end

    context "with pools_top_liquidity (Q3)" do
      it "POSTs query with orderBy and createdAtTimestamp_gte" do
        stub_request(:post, graph_url)
          .with(body: hash_including("query" => /orderBy: totalValueLockedUSD/))
          .with(body: hash_including("query" => /createdAtTimestamp_gte/))
          .to_return(body: { data: { pools: [] } }.to_json, headers: { "Content-Type" => "application/json" })

        service = described_class.new(
          query_type: :pools_top_liquidity,
          limit: 100,
          created_since: "1738800000",
          api_key: api_key
        )
        result = service.call

        expect(result).to match(hash_including(:data))
        expect(result[:data]["pools"]).to eq([])
      end
    end

    context "with pool_by_id (Q4)" do
      let(:pool_id) { "0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8" }
      let(:graph_response) do
        {
          data: {
            pool: {
              id: pool_id,
              token0: { id: "t0", symbol: "USDC", derivedETH: "0.0005" },
              token1: { id: "t1", symbol: "WETH", derivedETH: "1.0" },
              liquidity: "123456789",
              token0Price: "2000.5",
              token1Price: "0.0005",
              volumeToken0: "1000000.25",
              volumeToken1: "500.1",
              volumeUSD: "2000000.50",
              totalValueLockedUSD: "5000000.75"
            }
          }
        }
      end

      it "POSTs pool(id: ...) query and returns single pool" do
        stub_request(:post, graph_url)
          .with(body: hash_including("query" => /pool\(id:.*#{Regexp.escape(pool_id)}/))
          .to_return(body: graph_response.to_json, headers: { "Content-Type" => "application/json" })

        service = described_class.new(query_type: :pool_by_id, pool_id: pool_id, api_key: api_key)
        result = service.call

        expect(result).to match(hash_including(:data))
        expect(result[:data]["pool"]).to be_present
        expect(result[:data]["pool"]["id"]).to eq(pool_id)
      end

      it "normalizes financial fields to string (no Float)" do
        stub_request(:post, graph_url).to_return(
          body: graph_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

        service = described_class.new(query_type: :pool_by_id, pool_id: pool_id, api_key: api_key)
        result = service.call

        pool = result[:data]["pool"]
        expect(pool["token0Price"]).to eq("2000.5")
        expect(pool["token1Price"]).to eq("0.0005")
        expect(pool["liquidity"]).to eq("123456789")
        expect(pool["volumeUSD"]).to be_a(String).and(satisfy { |s| s.to_f == 2000000.50 })
        expect(pool["totalValueLockedUSD"]).to eq("5000000.75")
        expect(pool["token0"]["derivedETH"]).to eq("0.0005")
        expect(pool["token1"]["derivedETH"]).to eq("1.0")
        expect(pool["token0Price"]).to be_a(String)
      end
    end

    context "when pool_by_id has no pool_id" do
      it "returns error without calling API" do
        service = described_class.new(query_type: :pool_by_id, pool_id: nil, api_key: api_key)
        stub = stub_request(:post, graph_url)

        result = service.call

        expect(result).to eq({ error: "Invalid query parameters" })
        expect(stub).not_to have_been_requested
      end
    end

    context "when The Graph returns HTTP error" do
      it "returns error hash" do
        stub_request(:post, graph_url).to_return(status: 502, body: "Bad Gateway")

        service = described_class.new(query_type: :pools_list, api_key: api_key)
        result = service.call

        expect(result).to match(hash_including(:error))
        expect(result[:error]).to include("502")
      end
    end

    context "when The Graph returns GraphQL errors" do
      it "returns error hash with messages" do
        stub_request(:post, graph_url).to_return(
          status: 200,
          body: { errors: [ { "message" => "Something went wrong" } ] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

        service = described_class.new(query_type: :pools_list, api_key: api_key)
        result = service.call

        expect(result).to match(hash_including(:error))
        expect(result[:error]).to include("Something went wrong")
      end
    end
  end
end
