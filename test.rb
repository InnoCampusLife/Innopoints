require_relative 'database_handler'

DB.query("SELECT *, oc.points_amount as points_to_contribute FROM OrderContributors as oc, Accounts as a WHERE oc.account_id = a.id").each do |row|
  puts row
end