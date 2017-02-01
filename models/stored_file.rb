class StoredFile
  def self.create(application_id, filename, type, extension)
    DatabaseHandler.connection.query("INSERT INTO Files VALUES (default, '#{DatabaseHandler.connection.escape(filename)}', '#{type}', NULL, #{application_id}, '#{DatabaseHandler.connection.escape(extension)}');")
    id = DatabaseHandler.connection.last_id
    file = get_by_id(id)
    file
  end

  def self.get_by_id(id)
    file = nil
    DatabaseHandler.connection.query("SELECT * FROM Files WHERE id = #{id}").each do |row|
      file = row
    end
    file
  end

  def self.get_with_author_by_id(id)
    file = nil
    DatabaseHandler.connection.query("SELECT f.id, f.extension, f.filename, f.type, ap.id as application_id, ac.id as account_id FROM Files as f, Applications as ap, Accounts as ac WHERE f.application_id = ap.id AND ap.author = ac.id AND f.id = #{id};").each do |row|
      file = row
    end
    file
  end

  def self.update_download_link(file_id, download_link)
    DatabaseHandler.connection.query("UPDATE Files SET download_link='#{DatabaseHandler.connection.escape(download_link)}' WHERE id=#{file_id};")
  end

  def self.get_list_by_application_id(application_id)
    files = Array.new
    DatabaseHandler.connection.query("SELECT * FROM Files WHERE application_id=#{application_id};").each do |row|
      files.push({
          id: row[:id],
          filename: row[:filename],
          type: row[:type]
                 })
    end
    files
  end

  def self.delete_by_id(id)
    DatabaseHandler.connection.query("DELETE FROM Files WHERE id=#{id};")
  end

  def self.delete_all_by_application_id(application_id)
    DatabaseHandler.connection.query("DELETE FROM Files WHERE application_id=#{application_id}")
  end
end