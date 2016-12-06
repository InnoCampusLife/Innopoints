class ReworkComment
  def self.create(application_id, comment)
    DB.query("INSERT INTO ReworkComments VALUES (default, #{application_id}, '#{DB.escape(comment)}');")
  end

  def self.get_rework_comment(application_id)
    comment = nil
    DB.query("SELECT * FROM ReworkComments WHERE application_id=#{application_id};").each do |row|
      comment = row['comment']
    end
    return comment
  end

  def self.update(application_id, comment)
    DB.query("UPDATE ReworkComment SET comment='#{DB.escape(comment)}' WHERE application_id=#{application_id};")
  end
end