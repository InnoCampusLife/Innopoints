require_relative '../database_handler'
class Work
  def self.create(actor, activity_id, application_id, amount)
    if amount.nil?
      amount = 'NULL'
    end
    DatabaseHandler.connection.query("INSERT INTO Works VALUES (default, #{actor}, #{activity_id}, NULL, NULL, #{amount}, #{application_id});")
    id = DatabaseHandler.connection.last_id
    work = get_by_id(id)
    work
  end

  def self.get_by_id(id)
    work = nil
    DatabaseHandler.connection.query("SELECT * FROM Works WHERE id=#{id}").each do |row|
      work = row
    end
    work
  end

  def self.get_list_by_application_id(application_id)
    works = Array.new
    DatabaseHandler.connection.query("SELECT * FROM Works WHERE application_id=#{application_id};").each do |row|
      works.push(row)
    end
    return works
  end

  def self.get_by_application_id_and_actor(application_id, actor)
    work = nil
    DatabaseHandler.connection.query("SELECT * FROM Works WHERE application_id=#{application_id} AND actor=#{actor};").each do |row|
      work = row
    end
    work
  end

  def self.update(work_id, hash)
    update_query = ''
    counter = hash.size
    hash.each do |key, value|
      if hash.key?(:amount)
        if key == :amount
          update_query += "amount=null"
          next
        end
      end
      update_query += "#{key}=#{value}"
      counter -= 1
      if counter > 0
        update_query += ', '
      end
    end
    DatabaseHandler.connection.query("UPDATE Works SET #{update_query} WHERE id=#{work_id};")
  end

  def self.delete_all_by_application_id(application_id)
    DatabaseHandler.connection.query("DELETE FROM Works WHERE application_id=#{application_id};")
  end

  def self.delete_by_id(id)
    DatabaseHandler.connection.query("DELETE FROM Works WHERE id=#{id};")
  end
end