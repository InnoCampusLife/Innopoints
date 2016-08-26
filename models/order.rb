class Order
  def self.create(account_id, is_joint_purchase, total_price)
    status = nil
    if is_joint_purchase
      status = 'waiting_to_process'
    else
      status = 'in_process'
    end
    order = nil
    DB.query("INSERT INTO Orders VALUES (default, '#{status}', now(), #{is_joint_purchase}, #{account_id}, #{total_price});")
    id = DB.last_id
    DB.query("SELECT * FROM Orders WHERE id=#{id}").each do |row|
      order = row
    end
    order
  end
end