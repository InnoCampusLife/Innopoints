require_relative '../database_handler'

class Activity

  def self.get_by_id(id)
    activity = nil
    DatabaseHandler.connection.query("select * from Activities WHERE id = #{id} AND is_deleted=0").each do |row|
      activity = row
    end
    activity
  end

  def self.create(title, comment, for_approval, type, category_id, price)
    title = DatabaseHandler.connection.escape(title)
    if comment.nil?
      comment = "NULL"
    else
      comment = "'#{DatabaseHandler.connection.escape(comment)}'"
    end
    if for_approval.nil?
      for_approval = "NULL"
    else
      for_approval = "'#{DatabaseHandler.connection.escape(for_approval)}'"
    end
    query = ""
    query << "INSERT INTO Activities "
    query << "(title, comment, for_approval, type, category_id, price, main_option_exists, additional_exists) "
    query << "VALUES "
    query << "('#{title}', #{comment}, #{for_approval}, '#{type}', #{category_id}, #{price}, #{0}, #{0});"
    DatabaseHandler.connection.query(query)
    id = DatabaseHandler.connection.last_id
    activity = get_by_id(id)
    activity
  end

  def self.update(id, title, comment, for_approval, type, category_id, price)
    title = DatabaseHandler.connection.escape(title)
    if comment.nil?
      comment = "NULL"
    else
      comment = "'#{DatabaseHandler.connection.escape(comment)}'"
    end
    if for_approval.nil?
      for_approval = "NULL"
    else
      for_approval = "'#{DatabaseHandler.connection.escape(for_approval)}'"
    end
    query = "UPDATE Activities SET title = '#{title}', comment = #{comment}, for_approval = #{for_approval}, type = '#{type}', category_id = #{category_id}, price = #{price} WHERE id = #{id};"
    DatabaseHandler.connection.query(query)
  end

  def self.delete(id)
    DatabaseHandler.connection.query("UPDATE Activities SET is_deleted = 1 WHERE id=#{id};")
  end

  def self.get_by_id_with_category(id)
    activity = nil
    DatabaseHandler.connection.query("select a.id, a.title, a.type, a.price, a.category_id, c.title as category_title from Categories as c, Activities as a WHERE c.id = a.category_id AND a.id=#{id};").each do |row|
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
    DatabaseHandler.connection.query("select a.id, a.title, a.type, a.price, a.comment, a.for_approval, a.category_id, c.title as category_title from Categories as c, Activities as a WHERE c.id = a.category_id AND is_deleted=0;").each do |row|
      activities.push({
                          id: row[:id],
                          title: row[:title],
                          type: row[:type],
                          price: row[:price],
                          comment: row[:comment],
                          for_approval: row[:for_approval],
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
    DatabaseHandler.connection.query("select a.id, a.title, a.type, a.price, a.comment, a.for_approval, a.category_id, c.title as category_title from Categories as c, Activities as a WHERE c.id = a.category_id AND c.id = #{category_id} AND is_deleted=0;").each do |row|
      activities.push({
                          id: row[:id],
                          title: row[:title],
                          type: row[:type],
                          price: row[:price],
                          comment: row[:comment],
                          for_approval: row[:for_approval],
                          category: {
                              id: row[:category_id],
                              title: row[:category_title]
                          }
                      })
    end
    activities
  end
end
