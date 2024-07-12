class SearchesController < ApplicationController
  def search
    @query = params[:query]
    @articles = Article.search(@query)

    LogSearchQueryJob.perform_later(@query, request.remote_ip)

    render json: { articles: @articles }
  end

  def analytics
    last_update_time_str = REDIS.get('last_update_time')
    last_update_time = last_update_time_str.present? ? Time.parse(last_update_time_str) : nil
    latest_query_time = SearchQuery.maximum(:created_at)
  
    if last_update_time.nil? || latest_query_time.nil? || latest_query_time > last_update_time
      popular_searches = SearchQuery.consolidate_queries.limit(10)
      REDIS.set('popular_searches', popular_searches.to_json, ex: 5.minutes)
      REDIS.set('last_update_time', latest_query_time.to_s, ex: 5.minutes) if latest_query_time
    else
      popular_searches = JSON.parse(REDIS.get('popular_searches'))
    end
  
    render json: { popular_searches: popular_searches }
  end
end