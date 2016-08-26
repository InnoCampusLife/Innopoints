class ItemInOrder
  def self.create(order_id, item_id, amount)
    DB.query("INSERT INTO ItemsInOrder VALUES (default, #{order_id}, #{item_id}, #{amount});")
  end
end