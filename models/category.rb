require_relative '../database_handler'

class Category

  def self.get_list(skip, limit)
    categories = Array.new
    # LIMIT #{skip}, #{limit}
    DatabaseHandler.connection.query("SELECT * FROM Categories;").each do |row|
      puts row
      categories.push({
          id: row[:id],
          title: row[:title]
                      })
    end
    categories
  end

  def self.exists?(id)
    category = nil
    DatabaseHandler.connection.query("SELECT * FROM Categories WHERE id = #{id};").each do |row|
      category = row
    end
    !category.nil?
  end
end