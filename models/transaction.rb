class Transaction
  def self.create(account_id, amount)
    date = Date.today >> 12
    date = Date.civil(date.year, date.month, -1)
    DB.query("INSERT INTO Transactions VALUES (default, #{account_id}, #{amount}, #{amount}, now(), '#{date}', 'active');")
    transaction = nil
    id = DB.last_id
    DB.query("SELECT * FROM Transactions WHERE id=#{id};").each do |row|
      transaction = row
    end
    transaction
  end
end