class AddLastKeyPressAtToSearchQueries < ActiveRecord::Migration[7.1]
  def change
    add_column :search_queries, :last_key_press_at, :timestamp
  end
end
