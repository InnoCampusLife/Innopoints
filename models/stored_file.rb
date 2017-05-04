class StoredFile
  def self.create(filename, extension)
    DatabaseHandler.connection.query("INSERT INTO Files (id, filename, extension, application_id) VALUES (default, '#{DatabaseHandler.connection.escape(filename)}', '#{DatabaseHandler.connection.escape(extension)}', NULL);")
    id = DatabaseHandler.connection.last_id
    puts '--------------- STORED FILE ID'
    puts id
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
    DatabaseHandler.connection.query("SELECT f.id, f.extension, f.filename, ap.id as application_id, ac.id as account_id FROM Files as f, Applications as ap, Accounts as ac WHERE f.application_id = ap.id AND ap.author = ac.id AND f.id = #{id};").each do |row|
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
          filename: row[:filename]
                 })
    end
    files
  end

  def self.set_application_id(id, application_id)
    DatabaseHandler.connection.query("UPDATE Files SET application_id=#{application_id} WHERE id=#{id};")
  end

  def self.delete_by_id(id)
    DatabaseHandler.connection.query("DELETE FROM Files WHERE id=#{id};")
  end

  def self.delete_all_by_application_id(application_id)
    DatabaseHandler.connection.query("DELETE FROM Files WHERE application_id=#{application_id}")
  end
end