class Article < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true

  def self.search(query)
    where("title ILIKE ? OR content ILIKE ?", "%#{query}%", "%#{query}%")
  end
end
