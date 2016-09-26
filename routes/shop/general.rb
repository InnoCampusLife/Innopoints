require 'sinatra'
require_relative '../../config'

module Shop
  module General
    def self.registered(app)
      app.get URL + '/shop/categories' do
        content_type :json
        item_categories = ItemCategory.get_list
        return generate_response('ok', item_categories, nil, SUCCESSFUL_RESPONSE_CODE)
      end

      app.get URL + '/shop/items' do
        content_type :json
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        fields = params[:fields]
        order = params[:order]
        if fields.nil?
          fields_array = Array.new
          fields_array.push(DEFAULT_ITEMS_SORT_FIELD)
        else
          fields_array = fields.split(',')
          if fields_array.length > 2 || fields_array.length == 0
            return generate_response('fail', nil, 'ERROR IN SORT FIELDS', CLIENT_ERROR_CODE)
          end
          (0..(fields_array.length - 1)).each do |i|
            if fields_array[i].strip == 'name' || fields_array[i].strip == 'price'
              fields_array[i] = fields_array[i].strip
            else
              return generate_response('fail', nil, 'ERROR IN SORT FIELDS', CLIENT_ERROR_CODE)
            end
          end
          if fields_array.length == 2
            if fields_array[0] == fields_array[1]
              fields_array.delete_at(1)
            end
          end
        end
        if order.nil?
          order = DEFAULT_SORT_ORDER
        else
          if order != 'ASC' && order != 'DESC'
            order = DEFAULT_SORT_ORDER
          end
        end
        items = ShopItem.get_full_info_list(skip, limit, fields_array, order)
        generate_response('ok', items, nil, SUCCESSFUL_RESPONSE_CODE)
      end

# GetItemsInCategory
      app.get URL + '/shop/items/category/:category_id' do
        content_type :json
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        fields = params[:fields]
        order = params[:order]
        category_id = validate_integer(params[:category_id])
        if category_id.nil?
          return generate_response('fail', nil, 'ERROR IN CATEGORY ID', CLIENT_ERROR_CODE)
        end
        if fields.nil?
          fields_array = Array.new
          fields_array.push(DEFAULT_ITEMS_SORT_FIELD)
        else
          fields_array = fields.split(',')
          if fields_array.length > 2 || fields_array.length == 0
            return generate_response('fail', nil, 'ERROR IN SORT FIELDS', CLIENT_ERROR_CODE)
          end
          (0..(fields_array.length - 1)).each do |i|
            if fields_array[i].strip == 'name' || fields_array[i].strip == 'price'
              fields_array[i] = fields_array[i].strip
            else
              return generate_response('fail', nil, 'ERROR IN SORT FIELDS', CLIENT_ERROR_CODE)
            end
          end
          if fields_array.length == 2
            if fields_array[0] == fields_array[1]
              fields_array.delete_at(1)
            end
          end
        end
        if order.nil?
          order = DEFAULT_SORT_ORDER
        else
          if order != 'ASC' && order != 'DESC'
            order = DEFAULT_SORT_ORDER
          end
        end
        items = ShopItem.get_full_info_list_in_category(category_id, skip, limit, fields_array, order)
        generate_response('ok', items, nil, SUCCESSFUL_RESPONSE_CODE)
      end

# GetItem
      app.get URL + '/shop/items/:id' do
        content_type :json
        item_id = validate_integer(params[:id])
        if item_id.nil?
          return generate_response('fail', nil, 'WRONG ITEM ID', CLIENT_ERROR_CODE)
        end
        item = ShopItem.get_main_by_id(item_id)
        if item.nil?
          generate_response('fail', nil, 'ITEM DOES NOT EXIST', CLIENT_ERROR_CODE)
        else
          generate_response('ok', item, nil, SUCCESSFUL_RESPONSE_CODE)
        end
      end
    end
  end
end