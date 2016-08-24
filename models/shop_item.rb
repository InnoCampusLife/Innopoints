require_relative '../database_handler'

class ShopItem
  def self.get_list(skip, limit, fields_to_sort, order)
    fields = ''
    if fields_to_sort.length == 2
      fields = fields_to_sort[0] + ', ' + fields_to_sort[1]
    else
      fields = fields_to_sort[0]
    end
    items = Array.new
    DB.query("SELECT * FROM Items WHERE main=true LIMIT #{skip}, #{limit} ORDER BY #{fields_to_sort} #{order};").each do |row|
      items.push({
          id: row[:id],

                 })
    end
  end
end