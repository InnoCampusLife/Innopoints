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
    DB.query("SELECT * FROM Orders WHERE id=#{id}", cast_booleans: true).each do |row|
      order = row
    end
    order
  end

  def self.get_by_id(order_id)
    order = nil
    DB.query("SELECT * FROM Orders WHERE id=#{order_id}", cast_booleans: true).each do |row|
      order = row
    end
    order
  end

  def self.get_list(account_id, skip, limit, status = nil)
    query_string = "account_id=#{account_id} "
    unless status.nil?
      query_string += " AND status=#{status}"
    end
    DB.query("SELECT * FROM ")
  end

  def self.update_status(order_id, status)
    DB.query("UPDATE Orders SET status='#{status}' WHERE id=#{order_id}")
  end

  def self.delete_by_id(id)
    DB.query("DELETE FROM Orders WHERE id=#{id}")
  end
end