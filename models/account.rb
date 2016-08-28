require_relative '../database_handler'

class Account
  def self.create(owner, type)
    points_amount = 'NULL'
    if type == 'student'
      points_amount = 0
    end
    # creation_date = DateTime.now
    #TODO fix the time
    DB.query("INSERT INTO Accounts VALUES (default, '#{owner}', '#{type}', #{points_amount}, NOW());")
    account = get_by_owner(owner)
    account
  end

  def self.get_by_id(id)
    account = nil
    DB.query("SELECT * FROM Accounts WHERE id=#{id};").each do |row|
      account = {
          id: row[:id],
          owner: row[:owner],
          type: row[:type],
          points_amount: row[:points_amount],
          creation_date: row[:creation_date]
      }
    end
    account
  end

  def self.get_by_owner_and_type(id, type)
    account = nil
    DB.query("SELECT * FROM Accounts WHERE owner='#{id}' AND type='#{type}';").each do |row|
      account = {
          id: row[:id],
          owner: row[:owner],
          type: row[:type],
          points_amount: row[:points_amount],
          creation_date: row[:creation_date]
      }
    end
    account
  end

  def self.get_list(skip, limit)
    accounts = Array.new
    DB.query("SELECT * FROM Accounts WHERE type='student' LIMIT #{skip}, #{limit};").each do |row|
      accounts.push({
          id: row[:id],
          owner: row[:owner],
          points_amount: row[:points_amount]
                    })
    end
    accounts
  end

  def self.get_by_owner(owner)
    account = nil
    DB.query("SELECT * FROM Accounts WHERE owner='#{owner}';").each do |row|
      account = {
          id: row[:id],
          owner: row[:owner],
          type: row[:type],
          points_amount: row[:points_amount],
          creation_date: row[:creation_date]
      }
    end
    account
  end

  def self.update_points_amount(id, points_amount)
    DB.query("UPDATE Accounts SET points_amount=#{points_amount} WHERE id=#{id}")
  end

  def self.to_info(account)
    account_info = Hash.new
    account_info[:id] = account[:id]
    account_info[:owner] = account[:owner]
    account_info[:type] = account[:type]
    if account[:type] == 'student'
      account_info[:points_amount] = account[:points_amount]
    end
    account_info
  end
end