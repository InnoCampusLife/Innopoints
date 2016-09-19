require_relative '../database_handler'

class OrderContributor
  def self.create(order_id, account_id, points_amount)
    DB.query("INSERT INTO OrderContributors VALUES (default, #{order_id}, #{account_id}, #{points_amount}, 0);")
  end

  def self.get_by_order_id_and_account_id(order_id, account_id)
    contributor = nil
    DB.query("SELECT * FROM OrderContributors WHERE order_id=#{order_id} AND account_id=#{account_id}").each do |row|
      contributor = row
    end
    contributor
  end

  def self.get_list_by_order_id(order_id)
    contributors = Array.new
    DB.query("SELECT * FROM OrderContributors WHERE order_id=#{order_id}").each do |row|
      contributors.push(row)
    end
    contributors
  end

  def self.get_full_list_by_order_id(order_id)
    contributors = Array.new
    DB.query("SELECT *, oc.points_amount as points_to_contribute FROM OrderContributors as oc, Accounts as a WHERE oc.account_id = a.id AND oc.order_id = #{order_id};").each do |row|
      contributors.push(row)
    end
    contributors
  end

  def self.update_is_agreed(is_agreed, order_id, account_id)
    if is_agreed
      is_agreed = 1
    else
      is_agreed = 0
    end
    DB.query("UPDATE OrderContributors SET is_agreed=#{is_agreed} WHERE order_id=#{order_id} AND account_id=#{account_id}")
  end

  def self.delete_by_order_id(order_id)
    DB.query("DELETE FROM OrderContributors WHERE order_id=#{order_id}")
  end
end