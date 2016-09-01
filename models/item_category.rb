require_relative '../database_handler'

class ItemCategory
  def self.get_by_id(id)
    category = nil
    DB.query("SELECT * FROM ItemCategories WHERE id=#{id};").each do |row|
      category = row
    end
    category
  end
end