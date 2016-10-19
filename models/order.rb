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
    order = get_by_id(id)
    order
  end

  def self.get_by_id(order_id)
    order = nil
    DB.query("SELECT * FROM Orders WHERE id=#{order_id}", cast_booleans: true).each do |row|
      order = row
      order[:creation_date] = order[:creation_date].to_i
    end
    order
  end

  def self.get_full_by_id(order_id)
    order = nil
    DB.query("SELECT * FROM Orders WHERE id=#{order_id};", cast_booleans: true).each do |row|
      order = row
    end
    if order.nil?
      return order
    end
    result_order = Hash.new
    result_order[:id] = order[:id]
    result_order[:status] = order[:status]
    result_order[:creation_date] = order[:creation_date].to_i
    result_order[:is_joint_purchase] = order[:is_joint_purchase]
    result_order[:total_price] = order[:total_price]
    result_order[:items] = Array.new
    account = Account.get_by_id(order[:account_id])
    result_order[:author] = account[:owner]
    items_in_order = ItemInOrder.get_full_list_in_order(order[:id])
    items_in_order.each do |item|
      item_to_insert = Hash.new
      item_to_insert[:id] = item[:item_id]
      item_to_insert[:title] = item[:item_title]
      item_to_insert[:amount] = item[:amount]
      item_to_insert[:category] = Hash.new
      item_to_insert[:category][:id] = item[:category_id]
      item_to_insert[:category][:title] = item[:category_title]
      item_to_insert[:price] = item[:price]
      (1..3).each do |i|
        option = 'option' + i.to_s
        value = 'value' + i.to_s
        tmp_key = item[option.to_sym]
        tmp_value = item[value.to_sym]
        if tmp_key.nil?
          break
        end
        if i == 1
          item_to_insert[:properties] = Hash.new
        end
        item_to_insert[:properties][tmp_key.to_sym] = tmp_value
      end
      result_order[:items].push(item_to_insert)
    end

    if result_order[:is_joint_purchase]
      result_order[:contributors] = Array.new
      contributors = OrderContributor.get_full_list_by_order_id(order[:id])
      contributors.each do |contributor|
        contributor_to_insert = Hash.new
        contributor_to_insert[:id] = contributor[:owner]
        contributor_to_insert[:points_amount] = contributor[:points_to_contribute]
        contributor_to_insert[:is_agreed] = contributor[:is_agreed]
        result_order[:contributors].push(contributor_to_insert)
      end
    end
    result_order
  end

  def self.get_list(skip, limit, status = nil)
    query_string = ""
    unless status.nil?
      query_string += " WHERE status='#{status}'"
    end
    orders = Array.new
    DB.query("SELECT * FROM Orders #{query_string} LIMIT #{skip}, #{limit};", cast_booleans: true).each do |row|
      orders.push(row)
    end
    result_orders = Array.new
    orders.each do |order|
      account = Account.get_by_id(order[:account_id])
      result_order = Hash.new
      result_order[:id] = order[:id]
      result_order[:author] = account[:owner]
      result_order[:status] = order[:status]
      result_order[:creation_date] = order[:creation_date].to_i
      result_order[:is_joint_purchase] = order[:is_joint_purchase]
      result_order[:total_price] = order[:total_price]
      result_order[:items] = Array.new
      items_in_order = ItemInOrder.get_full_list_in_order(order[:id])
      items_in_order.each do |item|
        item_to_insert = Hash.new
        item_to_insert[:id] = item[:item_id]
        item_to_insert[:title] = item[:item_title]
        item_to_insert[:amount] = item[:amount]
        item_to_insert[:category] = Hash.new
        item_to_insert[:category][:id] = item[:category_id]
        item_to_insert[:category][:title] = item[:category_title]
        item_to_insert[:price] = item[:price]
        (1..3).each do |i|
          option = 'option' + i.to_s
          value = 'value' + i.to_s
          tmp_key = item[option.to_sym]
          tmp_value = item[value.to_sym]
          if tmp_key.nil?
            break
          end
          if i == 1
            item_to_insert[:properties] = Hash.new
          end
          item_to_insert[:properties][tmp_key.to_sym] = tmp_value
        end
        result_order[:items].push(item_to_insert)
      end

      if result_order[:is_joint_purchase]
        result_order[:contributors] = Array.new
        contributors = OrderContributor.get_full_list_by_order_id(order[:id])
        contributors.each do |contributor|
          contributor_to_insert = Hash.new
          contributor_to_insert[:id] = contributor[:owner]
          contributor_to_insert[:points_amount] = contributor[:points_to_contribute]
          contributor_to_insert[:is_agreed] = contributor[:is_agreed]
          result_order[:contributors].push(contributor_to_insert)
        end
      end
      result_orders.push(result_order)
    end
    result_orders
  end

  def self.get_list_by_account_id(account_id, skip, limit, status = nil)
    query_string = "account_id=#{account_id} "
    if status.nil?
      query_string += " AND status<>'deleted'"
    else
      query_string += " AND status='#{status}'"
    end
    orders = Array.new
    DB.query("SELECT * FROM Orders WHERE #{query_string} LIMIT #{skip}, #{limit};", cast_booleans: true).each do |row|
      orders.push(row)
    end
    account = Account.get_by_id(account_id)
    result_orders = Array.new
    orders.each do |order|
      result_order = Hash.new
      result_order[:id] = order[:id]
      result_order[:author] = account[:owner]
      result_order[:status] = order[:status]
      result_order[:creation_date] = order[:creation_date].to_i
      result_order[:is_joint_purchase] = order[:is_joint_purchase]
      result_order[:total_price] = order[:total_price]
      result_order[:items] = Array.new
      items_in_order = ItemInOrder.get_full_list_in_order(order[:id])
      items_in_order.each do |item|
        item_to_insert = Hash.new
        item_to_insert[:id] = item[:item_id]
        item_to_insert[:title] = item[:item_title]
        item_to_insert[:amount] = item[:amount]
        item_to_insert[:category] = Hash.new
        item_to_insert[:category][:id] = item[:category_id]
        item_to_insert[:category][:title] = item[:category_title]
        item_to_insert[:price] = item[:price]
        (1..3).each do |i|
          option = 'option' + i.to_s
          value = 'value' + i.to_s
          tmp_key = item[option.to_sym]
          tmp_value = item[value.to_sym]
          if tmp_key.nil?
            break
          end
          if i == 1
            item_to_insert[:properties] = Hash.new
          end
          item_to_insert[:properties][tmp_key.to_sym] = tmp_value
        end
        result_order[:items].push(item_to_insert)
      end

      if result_order[:is_joint_purchase]
        result_order[:contributors] = Array.new
        contributors = OrderContributor.get_full_list_by_order_id(order[:id])
        contributors.each do |contributor|
          contributor_to_insert = Hash.new
          contributor_to_insert[:id] = contributor[:owner]
          contributor_to_insert[:points_amount] = contributor[:points_to_contribute]
          contributor_to_insert[:is_agreed] = contributor[:is_agreed]
          result_order[:contributors].push(contributor_to_insert)
        end
      end
      result_orders.push(result_order)
    end
    result_orders
  end

  def self.update_status(order_id, status)
    DB.query("UPDATE Orders SET status='#{status}' WHERE id=#{order_id}")
  end

  def self.delete_by_id(id)
    # DB.query("DELETE FROM Orders WHERE id=#{id}")
    DB.query("UPDATE Orders SET status='deleted' WHERE id=#{id};")
  end
end