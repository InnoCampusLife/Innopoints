require_relative '../database_handler'
require_relative '../config'

class ShopItem
  def self.get_list(skip, limit, fields_to_sort, order)
    fields = ''
    if fields_to_sort.length == 2
      fields = fields_to_sort[0] + ', ' + fields_to_sort[1]
    else
      fields = 'i.' + fields_to_sort[0]
    end
    items = Array.new
    image_link = FILES_FOLDER + ITEMS_IMAGE_FOLDER
    DB.query("SELECT i.id, i.title, i.price, i.category_id, ic.title as category_name FROM Items as i, ItemCategories as ic WHERE parent is null AND i.category_id = ic.id ORDER BY #{fields} #{order} LIMIT #{skip}, #{limit};").each do |row|
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

  def self.get_list_in_category(category_id, skip, limit, fields_to_sort, order)
    fields = ''
    if fields_to_sort.length == 2
      fields = fields_to_sort[0] + ', ' + fields_to_sort[1]
    else
      fields = fields_to_sort[0]
    end
    items = Array.new
    image_link = FILES_FOLDER + ITEMS_IMAGE_FOLDER
    DB.query("SELECT i.id, i.title, i.price, i.category_id, ic.title as category_name FROM Items as i, ItemCategories as ic WHERE parent is null AND i.category_id=#{category_id} ORDER BY #{fields} #{order} LIMIT #{skip}, #{limit};").each do |row|
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

  def self.get_main_by_id(id)
    result_item = Hash.new
    result_item[:combinations] = Hash.new
    parent_item = nil
    DB.query("SELECT * FROM Items WHERE id=#{id} AND parent is null;", cast_booleans: true).each do |row|
      parent_item = row
      tmp = Hash.new
      tmp_value = Hash.new
      (1..3).each do |i|
        if row[('option' + i.to_s).to_sym].nil?
          break
        end
        tmp[row[('option' + i.to_s).to_sym]] = row[('value' + i.to_s).to_sym]
      end
      tmp_value[:id] = row[:id]
      row[:quantity] == 0 ? tmp_value[:in_stock] = false : tmp_value[:in_stock] = true
      result_item[:combinations][tmp] = tmp_value
    end
    if parent_item.nil?
      return nil
    end
    child_items = Array.new
    DB.query("SELECT * FROM Items WHERE parent=#{parent_item[:id]}").each do |row|
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
      row[:quantity] == 0 ? tmp_value[:in_stock] = false : tmp_value[:in_stock] = true
      result_item[:combinations][tmp] = tmp_value
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
      result_item[:options].push({
          title: key,
          values: value
                                 })
    end
    result_item
  end
end