class ItemInOrder
  def self.create(order_id, item_id, amount)
    DB.query("INSERT INTO ItemsInOrder VALUES (default, #{order_id}, #{item_id}, #{amount});")
  end

  def self.delete_by_order_id(order_id)
    DB.query("DELETE FROM ItemsInOrder WHERE order_id=#{order_id}")
  end

  def self.get_list_in_order(order_id)
    items = Array.new
    DB.query("SELECT * FROM ItemsInOrder WHERE order_id=#{order_id}").each do |row|
      items.push(row)
    end
    items
  end
end