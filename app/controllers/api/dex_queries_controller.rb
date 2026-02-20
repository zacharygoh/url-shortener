# frozen_string_literal: true

module Api
  class DexQueriesController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :require_the_graph_api_key, only: %i[index show]

    # GET /api/dex/pools
    # Params: limit (default 100), order_by, created_since (Unix seconds for Q3)
    def index
      cache_key = dex_cache_key(:index, params.slice(:limit, :order_by, :created_since))
      result = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        service_for_index.call
      end
      respond_with_result(result)
    end

    # GET /api/dex/pools/:id
    def show
      cache_key = dex_cache_key(:show, params.slice(:id))
      result = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        DexDataFetcherService.new(query_type: :pool_by_id, pool_id: params[:id]).call
      end
      respond_with_result(result)
    end

    private

    def require_the_graph_api_key
      return if ENV["THE_GRAPH_API_KEY"].present?

      render json: { error: "THE_GRAPH_API_KEY is not configured" }, status: :service_unavailable
    end

    def service_for_index
      limit = (params[:limit].presence || 100).to_i
      order_by = params[:order_by].to_s
      created_since = params[:created_since].presence

      if order_by.present? && created_since.present?
        DexDataFetcherService.new(
          query_type: :pools_top_liquidity,
          limit: limit,
          created_since: created_since
        )
      else
        DexDataFetcherService.new(query_type: :pools_list, limit: limit)
      end
    end

    def dex_cache_key(action, parts)
      parts = parts.compact_blank
      "dex/#{action}/#{parts.values.join('/')}"
    end

    def respond_with_result(result)
      if result.key?(:error)
        render json: { error: result[:error] }, status: :unprocessable_entity
      else
        render json: { data: result[:data] }, status: :ok
      end
    end
  end
end
