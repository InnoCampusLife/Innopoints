require_relative '../database_handler'

class OrderContributor
  def self.create(order_id, account_id, points_amount)
    DB.query("INSERT INTO OrderContributors VALUES (default, #{order_id}, #{account_id}, #{points_amount}, 0);")
  end
end