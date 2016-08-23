require_relative '../database_handler'

class Category

  def self.get_list(skip, limit)
    categories = Array.new
    DB.query("SELECT * FROM Categories LIMIT #{skip}, #{limit};").each do |row|
      puts row
      categories.push({
          _id: row[:id],
          title: row[:title]
                      })
    end
    categories
  end
end