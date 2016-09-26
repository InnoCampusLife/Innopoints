require_relative '../database_handler'

class Category

  def self.get_list(skip, limit)
    categories = Array.new
    # LIMIT #{skip}, #{limit}
    DB.query("SELECT * FROM Categories;").each do |row|
      puts row
      categories.push({
          id: row[:id],
          title: row[:title]
                      })
    end
    categories
  end
end