# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API::DexQueries", type: :request do
  let(:api_key) { "test_key" }
  let(:graph_url) { "https://gateway.thegraph.com/api/#{api_key}/subgraphs/id/#{DexDataFetcherService::SUBGRAPH_ID}" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("THE_GRAPH_API_KEY").and_return(api_key)
  end

  def json_response
    JSON.parse(response.body)
  end

  describe "GET /api/dex/pools" do
    context "pools list (Q2)" do
      before do
        stub_request(:post, graph_url)
          .with(body: hash_including("query" => /pools\(first: 100\)/))
          .to_return(
            body: { data: { pools: [{ id: "0x1", token0: { id: "a", symbol: "A" }, token1: { id: "b", symbol: "B" } }] } }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns 200 and data.pools" do
        get "/api/dex/pools"

        expect(response).to have_http_status(:ok)
        expect(json_response["data"]["pools"]).to be_an(Array)
        expect(json_response["data"]["pools"].first["id"]).to eq("0x1")
      end
    end

    context "pools top liquidity (Q3)" do
      before do
        stub_request(:post, graph_url)
          .with(body: hash_including("query" => /orderBy: totalValueLockedUSD/))
          .with(body: hash_including("query" => /createdAtTimestamp_gte/))
          .to_return(
            body: { data: { pools: [] } }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns 200 when order_by and created_since present" do
        get "/api/dex/pools", params: { order_by: "total_value_locked_usd", created_since: "1738800000" }

        expect(response).to have_http_status(:ok)
        expect(json_response["data"]["pools"]).to eq([])
      end
    end
  end

  describe "GET /api/dex/pools/:id" do
    let(:pool_id) { "0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8" }

    before do
      stub_request(:post, graph_url)
        .with(body: hash_including("query" => /pool\(id:/))
        .to_return(
          body: {
            data: {
              pool: {
                id: pool_id,
                token0: { id: "t0", symbol: "USDC", derivedETH: "0.0005" },
                token1: { id: "t1", symbol: "WETH", derivedETH: "1.0" },
                liquidity: "123",
                token0Price: "2000.5",
                token1Price: "0.0005",
                volumeUSD: "1000000.25",
                totalValueLockedUSD: "5000000.75"
              }
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "returns 200 and data.pool with financial fields as strings" do
      get "/api/dex/pools/#{pool_id}"

      expect(response).to have_http_status(:ok)
      pool = json_response["data"]["pool"]
      expect(pool["id"]).to eq(pool_id)
      expect(pool["token0Price"]).to eq("2000.5")
      expect(pool["totalValueLockedUSD"]).to eq("5000000.75")
      expect(pool["token0Price"]).to be_a(String)
    end
  end

  describe "API key requirement" do
    it "returns 503 when THE_GRAPH_API_KEY is not set" do
      allow(ENV).to receive(:[]).with("THE_GRAPH_API_KEY").and_return(nil)

      get "/api/dex/pools"

      expect(response).to have_http_status(:service_unavailable)
      expect(json_response["error"]).to include("THE_GRAPH_API_KEY")
    end
  end
end
