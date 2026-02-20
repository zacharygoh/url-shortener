# frozen_string_literal: true

class DexDataFetcherService
  SUBGRAPH_ID = "5zvR82QoaXYFyDEKLZ9t6v9adgnptxYpKpSbxtgVENFV"
  FINANCIAL_KEYS = %w[
    token0Price token1Price liquidity volumeToken0 volumeToken1 volumeUSD totalValueLockedUSD
    derivedETH
  ].freeze

  attr_reader :query_type, :limit, :created_since, :pool_id, :api_key

  def initialize(query_type:, limit: 100, created_since: nil, pool_id: nil, api_key: nil)
    @query_type = query_type.to_sym
    @limit = limit.to_i
    @created_since = created_since
    @pool_id = pool_id
    @api_key = api_key.presence || ENV["THE_GRAPH_API_KEY"]
  end

  def call
    return { error: "THE_GRAPH_API_KEY is not set" } if api_key.blank?

    query = build_query
    return { error: "Invalid query parameters" } if query.blank?

    response = post_graphql(query)
    return response if response.key?(:error)

    normalize_response(response[:data])
  rescue StandardError => e
    Rails.logger.error("DexDataFetcherService error: #{e.message}")
    { error: "Failed to fetch DEX data" }
  end

  private

  def graph_url
    "https://gateway.thegraph.com/api/#{api_key}/subgraphs/id/#{SUBGRAPH_ID}"
  end

  def build_query
    case query_type
    when :pools_list
      "{ pools(first: #{limit}) { id token0 { id symbol } token1 { id symbol } } }"
    when :pools_top_liquidity
      return nil if created_since.blank?
      "{ pools(first: #{limit}, orderBy: totalValueLockedUSD, orderDirection: desc, where: { createdAtTimestamp_gte: \"#{created_since}\" }) { id token0 { id symbol } token1 { id symbol } } }"
    when :pool_by_id
      return nil if pool_id.blank?
      "{ pool(id: \"#{pool_id}\") { id token0 { id symbol derivedETH } token1 { id symbol derivedETH } liquidity token0Price token1Price volumeToken0 volumeToken1 volumeUSD totalValueLockedUSD } }"
    else
      nil
    end
  end

  def post_graphql(query)
    body = { query: query }.to_json
    resp = HTTParty.post(
      graph_url,
      body: body,
      headers: { "Content-Type" => "application/json" },
      timeout: 15
    )

    unless resp.success?
      return { error: "The Graph API error: #{resp.code}" }
    end

    parsed = JSON.parse(resp.body)
    if parsed["errors"].present?
      return { error: parsed["errors"].map { |e| e["message"] }.join("; ") }
    end

    { data: parsed["data"] }
  end

  def normalize_response(data)
    return { data: data } if data.blank?

    if data["pool"]
      { data: { "pool" => normalize_pool(data["pool"]) } }
    elsif data["pools"]
      { data: { "pools" => data["pools"].map { |p| normalize_pool(p) } } }
    else
      { data: data }
    end
  end

  def normalize_pool(pool)
    return pool if pool.blank?

    out = pool.dup
    FINANCIAL_KEYS.each do |key|
      next unless out.key?(key)
      out[key] = to_decimal_string(out[key])
    end
    %w[token0 token1].each do |token_key|
      next unless out[token_key].is_a?(Hash) && out[token_key].key?("derivedETH")
      out[token_key] = out[token_key].dup
      out[token_key]["derivedETH"] = to_decimal_string(out[token_key]["derivedETH"])
    end
    out
  end

  def to_decimal_string(value)
    return value if value.nil?
    return value.to_s if value.is_a?(String) && !value.strip.empty?
    BigDecimal(value.to_s).to_s
  rescue ArgumentError, TypeError
    value.to_s
  end
end
