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

  def self.get_full_list_in_order(order_id)
    items = Array.new
    DB.query("SELECT *, i.title as item_title, ic.title as category_title FROM ItemsInOrder as iio, Items as i, ItemCategories as ic WHERE iio.item_id = i.id AND i.category_id = ic.id AND order_id = #{order_id};", cast_booleans: true).each do |row|
      items.push(row)
    end
    items
  end
end