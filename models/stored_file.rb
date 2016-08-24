class StoredFile
  def self.create(application_id, filename, type, extension)
    DB.query("INSERT INTO Files VALUES (default, '#{filename}', '#{type}', NULL, #{application_id}, '#{extension}');")
    id = DB.last_id
    file = get_by_id(id)
    file
  end

  def self.get_by_id(id)
    file = nil
    DB.query("SELECT * FROM Files WHERE id = #{id}").each do |row|
      file = row
    end
    file
  end

  def self.update_download_link(file_id, download_link)
    DB.query("UPDATE Files SET download_link='#{download_link}' WHERE id=#{file_id};")
  end

  def self.get_list_by_application_id(application_id)
    files = nil
    DB.query("SELECT * FROM Files WHERE application_id=#{application_id};").each do |row|
      files.push({
          id: row[:id],
          filename: row[:filename],
          type: row[:type],
          download_link: row[:download_link]
                 })
    end
    files
  end

  def self.delete_by_id(id)
    DB.query("DELETE FROM Files WHERE id=#{id};")
  end

  def self.delete_all_by_application_id(application_id)
    DB.query("DELETE FROM Files WHERE application_id=#{application_id}")
  end
end