class ReworkComment
  def self.create(application_id, comment)
    DatabaseHandler.connection.query("INSERT INTO ReworkComments VALUES (default, #{application_id}, '#{DatabaseHandler.connection.escape(comment)}');")
  end

  def self.get_rework_comment(application_id)
    comment = nil
    DatabaseHandler.connection.query("SELECT * FROM ReworkComments WHERE application_id=#{application_id};").each do |row|
      comment = row['comment']
    end
    return comment
  end

  def self.update(application_id, comment)
    DatabaseHandler.connection.query("UPDATE ReworkComment SET comment='#{DatabaseHandler.connection.escape(comment)}' WHERE application_id=#{application_id};")
  end
end