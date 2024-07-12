class LogSearchQueryJob < ApplicationJob
  queue_as :default

  def perform(*args)
    query, ip_address = args

    SearchQuery.log_search(ip_address, query)
  end

end
