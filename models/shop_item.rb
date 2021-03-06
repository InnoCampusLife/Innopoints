require_relative '../database_handler'
require_relative '../config'
require_relative 'item_category'

class ShopItem
  def self.get_by_id(id)
    item = nil
    DatabaseHandler.connection.query("SELECT * FROM Items WHERE id=#{id} AND is_deleted=0;").each do |row|
      item = row
    end
    item
  end

  def self.create(title, options, quantity, price, category_id, possible_joint_purchase, max_buyers)
    title = DatabaseHandler.connection.escape(title)
    query = "INSERT INTO Items "
    query << "(title, option1, value1, option2, value2, option3, value3, quantity, price, category_id, possible_joint_purchase, max_buyers, parent, is_deleted) "
    query << " VALUES ("
    query << "'#{title}', "
    counter = 0
    options.each do |option, value|
      query << "'#{option}', '#{value}', "
      counter += 1
    end
    (3 - counter).times do
      query << "NULL, NULL, "
    end
    query << "#{quantity}, "
    query << "#{price}, "
    query << "#{category_id}, "
    query << "#{possible_joint_purchase}, "
    query << "#{max_buyers}, "
    query << "NULL, 0);"
    DatabaseHandler.connection.query(query)
    id = DatabaseHandler.connection.last_id
    item = get_by_id(id)
    item
  end

  def self.get_full_info_list(skip, limit, fields_to_sort, order)
    fields = ''
    if fields_to_sort.length == 2
      fields = fields_to_sort[0] + ', ' + fields_to_sort[1]
    else
      fields = fields_to_sort[0]
    end
    items = Array.new
    DatabaseHandler.connection.query("SELECT id FROM Items WHERE parent is null AND is_deleted=0 ORDER BY #{fields} #{order} LIMIT #{skip}, #{limit}").each do |row|
      items.push(get_main_by_id(row[:id]))
    end
    items
  end

  def self.get_list(skip, limit, fields_to_sort, order)
    fields = ''
    if fields_to_sort.length == 2
      fields = fields_to_sort[0] + ', ' + fields_to_sort[1]
    else
      fields = 'i.' + fields_to_sort[0]
    end
    items = Array.new
    image_link = PUBLIC_FOLDER + ITEMS_IMAGE_FOLDER
    DatabaseHandler.connection.query("SELECT i.id, i.title, i.price, i.category_id, ic.title as category_name FROM Items as i, ItemCategories as ic WHERE parent is null AND i.category_id = ic.id AND is_deleted=0 ORDER BY #{fields} #{order} LIMIT #{skip}, #{limit};").each do |row|
      items.push({
          id: row[:id],
          title: row[:title],
          price: row[:price],
          image_link: image_link + '/' + row[:id].to_s + '.jpg',
          category: {
              id: row[:category_id],
              title: row[:category_name]
          }
                 })
    end
    items
  end

  def self.get_full_info_list_in_category(category_id, skip, limit, fields_to_sort, order)
    fields = ''
    if fields_to_sort.length == 2
      fields = fields_to_sort[0] + ', ' + fields_to_sort[1]
    else
      fields = fields_to_sort[0]
    end
    items = Array.new
    DatabaseHandler.connection.query("SELECT id FROM Items WHERE parent is null AND category_id=#{category_id} AND is_deleted=0 ORDER BY #{fields} #{order} LIMIT #{skip}, #{limit};").each do |row|
      items.push(get_main_by_id(row[:id]))
    end
    items
  end

  def self.get_list_in_category(category_id, skip, limit, fields_to_sort, order)
    fields = ''
    if fields_to_sort.length == 2
      fields = fields_to_sort[0] + ', ' + fields_to_sort[1]
    else
      fields = fields_to_sort[0]
    end
    items = Array.new
    image_link = PUBLIC_FOLDER + ITEMS_IMAGE_FOLDER
    DatabaseHandler.connection.query("SELECT i.id, i.title, i.price, i.category_id, ic.title as category_name FROM Items as i, ItemCategories as ic WHERE parent is null AND i.category_id=#{category_id} AND i.category_id = ic.id AND is_deleted=0 ORDER BY #{fields} #{order} LIMIT #{skip}, #{limit};").each do |row|
      puts row
      items.push({
                     id: row[:id],
                     title: row[:title],
                     price: row[:price],
                     image_link: image_link + '/' + row[:id].to_s + '.jpg',
                     category: {
                         id: row[:category_id],
                         title: row[:category_name]
                     }
                 })
    end
    items
  end

  def self.check_quantity(item_ids_hash)
    query_string = ''
    counter = item_ids_hash.size
    item_ids_hash.each do |id, quantity|
      query_string += "id=#{id}"
      counter -= 1
      if counter > 0
        query_string += " OR "
      end
    end
    stored_items = Hash.new
    DatabaseHandler.connection.query("SELECT * FROM Items WHERE #{query_string} ;", cast_booleans: true).each do |row|
      stored_items[row[:id]] = row
    end
    if stored_items.size < item_ids_hash.size
      return 'WRONG ITEM'
    end
    stored_items.each do |id, item|
      if item_ids_hash[id] > item[:quantity]
        return 'WRONG QUANTITY'
      end
    end
    stored_items
  end

  def self.get_main_by_id(id)
    result_item = Hash.new
    result_item[:combinations] = Array.new
    parent_item = nil
    image_link = PUBLIC_FOLDER + ITEMS_IMAGE_FOLDER
    DatabaseHandler.connection.query("SELECT * FROM Items WHERE id=#{id} AND parent is null AND is_deleted=0;", cast_booleans: true).each do |row|
      parent_item = row
      tmp_value = Hash.new
      tmp = Hash.new
      (1..3).each do |i|
        if row[('option' + i.to_s).to_sym].nil?
          break
        end
        tmp[row[('option' + i.to_s).to_sym]] = row[('value' + i.to_s).to_sym]
      end
      # if options_number == 0
      #   result_item[:id] = row[:id]
      #   result_item[:quantity] = row[:quantity]
      #   result_item[:combinations] = nil
      # else
      #   tmp_value[:id] = row[:id]
      #   tmp_value[:quantity] = row[:quantity]
      #   result_item[:combinations][tmp] = tmp_value
      # end
      tmp_value[:id] = row[:id]
      tmp_value[:quantity] = row[:quantity]
      tmp_value[:options] = tmp
      result_item[:combinations].push(tmp_value)
      category = ItemCategory.get_by_id(row[:category_id])
      result_item[:category] = category
      result_item[:title] = row[:title]
      result_item[:image_link] = image_link + '/' + row[:id].to_s + '.jpg'
    end
    if parent_item.nil?
      return nil
    end
    child_items = Array.new
    DatabaseHandler.connection.query("SELECT * FROM Items WHERE parent=#{parent_item[:id]} AND is_deleted=0").each do |row|
      child_items.push(row)
      tmp = Hash.new
      tmp_value = Hash.new
      (1..3).each do |i|
        if row[('option' + i.to_s).to_sym].nil?
          break
        end
        tmp[row[('option' + i.to_s).to_sym]] = row[('value' + i.to_s).to_sym]
      end
      tmp_value[:id] = row[:id]
      tmp_value[:quantity] = row[:quantity]
      tmp_value[:options] = tmp
      result_item[:combinations].push(tmp_value)
    end
    result_item[:id] = parent_item[:id]
    result_item[:price] = parent_item[:price]
    result_item[:possible_joint_purchase] = parent_item[:possible_joint_purchase]
    if result_item[:possible_joint_purchase]
      result_item[:max_buyers] = parent_item[:max_buyers]
    end
    options = Hash.new
    child_items.push(parent_item)
    (1..3).each do |i|
      option = 'option' + i.to_s
      value = 'value' + i.to_s
      if parent_item[option.to_sym].nil?
        break
      end
      child_items.each do |item|
        options[parent_item[option.to_sym]] = Array.new if options[parent_item[option.to_sym]].nil?
        options[parent_item[option.to_sym]].push(item[value.to_sym]) unless options[parent_item[option.to_sym]].include?(item[value.to_sym])
      end
    end
    result_item[:options] = Array.new
    options.each do |key, value|
      obj = {
          title: key,
          values: value
      }
      # result_item[:options][:title] = key
      # result_item[:options][:values] = value
      result_item[:options].push(obj)
    end
    if result_item[:options].size == 0
      result_item[:options] = nil
      result_item[:combinations].each do |combination|
        combination[:options] = nil
      end
      # result_item.delete(:combinations)
    end
    result_item
  end

  def self.update_quantity(id, quantity)
    DatabaseHandler.connection.query("UPDATE Items SET quantity=#{quantity} WHERE id=#{id};")
  end
end