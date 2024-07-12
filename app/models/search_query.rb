class SearchQuery < ApplicationRecord
  validates :query, :ip_address, presence: true
  scope :for_ip, ->(ip) { where(ip_address: ip).order(created_at: :desc) }

  def self.log_search(ip_address, new_query)
    current_time = Time.current
    last_query = for_ip(ip_address).first

    if last_query && !is_new_search?(last_query, new_query, current_time)
      last_query.update(query: new_query, last_key_press_at: current_time)
    else
      create(query: new_query, ip_address: ip_address, last_key_press_at: current_time)
    end

    cleanup_incomplete_searches(ip_address, new_query)
  end

  def self.consolidate_queries
    group(:query).select('query, COUNT(*) as count').order('count DESC')
  end
  private

  def self.is_new_search?(last_query, new_query, current_time)
    return true if last_query.nil?
    
    time_since_last_keypress = current_time - last_query.last_key_press_at
    chars_deleted = last_query.query.length - new_query.length

    if time_since_last_keypress > 10.seconds
      true
    elsif new_query.length < last_query.query.length / 2
      true
    elsif !last_query.query.include?(new_query) && !new_query.start_with?(last_query.query)
      true
    else
      false
    end
  end

  def self.is_search_complete?(last_query, new_query, current_time)
    return true if last_query.query == new_query
    return false if is_frequent_backspacing?(last_query, new_query, current_time)
    
    new_query.length >= 3
    new_query.match?(/\s$/) || new_query.match?(/[.!?]$/)
  end

  def self.is_frequent_backspacing?(last_query, new_query, current_time)
    return false if new_query.length >= last_query.query.length
    
    time_since_last_keypress = current_time - last_query.last_key_press_at
    chars_deleted = last_query.query.length - new_query.length
    
    chars_deleted > 0 && time_since_last_keypress < 2.seconds
  end



  def self.cleanup_incomplete_searches(ip_address, current_query)
    last_query = for_ip(ip_address).first
    return unless last_query

    current_time = Time.current
    
    if is_new_search?(last_query, current_query, current_time)
      incomplete_searches = for_ip(ip_address)
        .where("created_at > ?", 5.minutes.ago)
        .where.not(query: current_query)
      
      if incomplete_searches.any?
        incomplete_searches.destroy_all
        Rails.logger.info("Cleaned up incomplete searches for IP: #{ip_address}")
      end
    end
  end
end