require_relative '../database_handler'

class Activity

  def self.get_by_id(id)
    activity = nil
    DB.query("select * from Activities WHERE id = #{id} AND is_deleted=0").each do |row|
      activity = row
    end
    activity
  end

  def self.get_by_id_with_category(id)
    activity = nil
    DB.query("select a.id, a.title, a.type, a.price, a.category_id, c.title as category_title from Categories as c, Activities as a WHERE c.id = a.category_id AND a.id=#{id};").each do |row|
      activity = {
                          id: row[:id],
                          title: row[:title],
                          type: row[:type],
                          price: row[:price],
                          category: {
                              id: row[:category_id],
                              title: row[:category_title]
                          }
      }
    end
    activity
  end

  def self.get_list_with_categories(skip, limit)
    activities = Array.new
    # LIMIT #{skip}, #{limit}
    DB.query("select a.id, a.title, a.type, a.price, a.category_id, c.title as category_title from Categories as c, Activities as a WHERE c.id = a.category_id AND is_deleted=0;").each do |row|
      activities.push({
                          id: row[:id],
                          title: row[:title],
                          type: row[:type],
                          price: row[:price],
                          category: {
                              id: row[:category_id],
                              title: row[:category_title]
                          }
                      })
    end
    activities
  end

  def self.get_list_with_categories_in_category(category_id, skip, limit)
    activities = Array.new
    # LIMIT #{skip}, #{limit}
    DB.query("select a.id, a.title, a.type, a.price, a.category_id, c.title as category_title from Categories as c, Activities as a WHERE c.id = a.category_id AND c.id = #{category_id} AND is_deleted=0;").each do |row|
      activities.push({
                          id: row[:id],
                          title: row[:title],
                          type: row[:type],
                          price: row[:price],
                          category: {
                              id: row[:category_id],
                              title: row[:category_title]
                          }
                      })
    end
    activities
  end
end
