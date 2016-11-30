require_relative '../database_handler'
require_relative 'account'
require_relative 'work'
require_relative 'stored_file'
require_relative 'activity'

class Application

  def self.create(author, type, comment)
    if comment.nil?
      comment = ''
    end
    DB.query("INSERT INTO Applications VALUES (default,#{author}, '#{type}', '#{DB.escape(comment)}', 'in_process', NOW());")
    id = DB.last_id
    application = get_by_id(id)
    application
  end

  def self.get_list_with_status(status, skip, limit)
    applications = Array.new
    DB.query("SELECT * FROM Applications WHERE status='#{status}' LIMIT #{skip}, #{limit};").each do |row|
      account = Account.get_by_id(row[:author])
      applications.push({
                            id: row[:id],
                            author: {
                                id: account[:id],
                                uis_id: account[:owner]
                            },
                            type: row[:type],
                            status: row[:status],
                            creation_date: row[:creation_date].to_i
                        })
    end
    applications
  end

  def self.get_application_list_counter(status)
    counter = 0
    DB.query("SELECT count(id) as counter FROM Applications WHERE status='#{status}';").each do |row|
      counter = row[:counter]
    end
    counter
  end

  def self.get_full_list_with_status(status, skip, limit)
    applications = Array.new
    DB.query("SELECT id FROM Applications WHERE status='#{status}' LIMIT #{skip}, #{limit};").each do |row|
      applications.push(get_full_by_id(row[:id]))
    end
    applications
  end

  def self.get_users_application_counter(account_id, status=nil)
    query_string = ""
    if status.nil?
      query_string += "AND status<>'deleted'"
    else
      query_string += "AND status='#{status}'"
    end
    counter = 0
    DB.query("SELECT count(id) as counter FROM Applications WHERE author=#{account_id} #{query_string}").each do |row|
      counter = row[:counter]
    end
    counter
  end

  def self.get_full_list_users_application(account_id, skip, limit, status=nil)
    applications = Array.new
    query_string = ""
    if status.nil?
      query_string += "AND status<>'deleted'"
    else
      query_string += "AND status='#{status}'"
    end
    DB.query("SELECT id FROM Applications WHERE author=#{account_id} #{query_string} LIMIT #{skip}, #{limit};").each do |row|
        applications.push(get_full_by_id(row[:id]))
    end
    applications
  end

  def self.get_list_users_application(account_id, skip, limit, status=nil)
    applications = Array.new
    account = Account.get_by_id(account_id)
    if status.nil?
      DB.query("SELECT * FROM Applications WHERE author=#{account_id} LIMIT #{skip}, #{limit};").each do |row|
        applications.push({
            id: row[:id],
            author: account[:owner],
            type: row[:type],
            status: row[:status],
            creation_date: row[:creation_date].to_i
                          })
      end
    else
      DB.query("SELECT * FROM Applications WHERE author=#{account_id} AND status='#{status}' LIMIT #{skip}, #{limit};").each do |row|
        applications.push({
                              id: row[:id],
                              author: account[:owner],
                              type: row[:type],
                              status: row[:status],
                              creation_date: row[:creation_date].to_i
                          })
      end
    end
    applications
  end

  def self.get_by_id(id)
    application = nil
    DB.query("SELECT * FROM Applications WHERE id=#{id};").each do |row|
      application = row
      application[:creation_date] = application[:creation_date].to_i
    end
    application
  end

  def self.get_full_by_id(id)
    application = nil
    DB.query("SELECT * FROM Applications WHERE id=#{id};").each do |row|
      application = row
    end
    if application.nil?
      return application
    end
    account = Account.get_by_id(application[:author])
    if account.nil?
      return nil
    end
    result_application = Hash.new
    result_application[:id] = application[:id]
    result_application[:type] = application[:type]
    result_application[:author] = account[:owner]
    result_application[:comment] = application[:comment]
    result_application[:status] = application[:status]
    result_application[:creation_date] = application[:creation_date].to_i
    works = Work.get_list_by_application_id(application[:id])
    result_application[:work] = Array.new
    works.each do |work|
      work_account = Account.get_by_id(work[:actor])
      activity = Activity.get_by_id_with_category(work[:activity_id])
      total_price = nil
      if activity[:type] == 'permanent'
        total_price = activity[:price]
      else
        total_price = work[:amount].to_i * activity[:price].to_i
      end
      result_application[:work].push({
                                         :activity => activity,
                                         :actor => work_account[:owner],
                                         :amount => work[:amount],
                                         :total_price => total_price
                                     })
    end
    files = StoredFile.get_list_by_application_id(application[:id])
    result_application[:files] = files
    result_application
  end

  def self.get_by_id_and_author(id, author)
    application = nil
    DB.query("SELECT * FROM Applications WHERE id=#{id} AND author=#{author};").each do |row|
      application = row
      application[:creation_date] = application[:creation_date].to_i
    end
    application
  end

  def self.get_full_by_id_and_author(id, author)
    application = nil
    DB.query("SELECT * FROM Applications WHERE id=#{id} AND author=#{author};").each do |row|
      application = row
    end
    if application.nil?
      return application
    end
    account = Account.get_by_id(application[:author])
    if account.nil?
      return nil
    end
    result_application = Hash.new
    result_application[:id] = application[:id]
    result_application[:type] = application[:type]
    result_application[:author] = account[:owner]
    result_application[:comment] = application[:comment]
    result_application[:status] = application[:status]
    result_application[:creation_date] = application[:creation_date].to_i
    works = Work.get_list_by_application_id(application[:id])
    result_application[:work] = Array.new
    works.each do |work|
      work_account = Account.get_by_id(work[:actor])
      activity = Activity.get_by_id_with_category(work[:activity_id])
      total_price = nil
      if activity[:type] == 'permanent'
        total_price = activity[:price]
      else
        total_price = work[:amount].to_i * activity[:price].to_i
      end
      result_application[:work].push({
                                                 :activity => activity,
                                                 :actor => work_account[:owner],
                                                 :amount => work[:amount],
                                                 :total_price => total_price
                                             })
    end
    files = StoredFile.get_list_by_application_id(application[:id])
    result_application[:files] = files
    result_application
  end

  def self.update_comment(id, comment)
    DB.query("UPDATE Applications SET comment='#{DB.escape(comment)}' WHERE id=#{id};")
  end

  def self.update_status(id, status)
    DB.query("UPDATE Applications SET status='#{status}' WHERE id=#{id};")
  end

  def self.delete_by_id(id)
    DB.query("UPDATE Applications SET status='deleted' WHERE id=#{id};")
    # Work.delete_all_by_application_id(id)
    # StoredFile.delete_all_by_application_id(id)
    # DB.query("DELETE FROM Applications WHERE id=#{id};")
  end
end