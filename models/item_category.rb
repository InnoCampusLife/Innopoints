require_relative '../database_handler'

class ItemCategory
  def self.get_list
    categories = Array.new
    DatabaseHandler.connection.query("SELECT * FROM ItemCategories;").each do |row|
      categories.push(row)
    end
    categories
  end

  def self.get_by_id(id)
    category = nil
    DatabaseHandler.connection.query("SELECT * FROM ItemCategories WHERE id=#{id};").each do |row|
      category = row
    end
    category
  end
end