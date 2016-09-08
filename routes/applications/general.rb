require 'sinatra'
require_relative '../../config'

module Applications
  module General
    def self.registered(app)
      app.get URL + '/general' do
        'general'
      end

      app.get URL + '/categories' do
        content_type :json
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        categories = Category.get_list(skip, limit)
        generate_response('ok', categories, nil, SUCCESSFUL_RESPONSE_CODE)
      end

      app.get URL + '/activities' do
        content_type :json
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        activities = Activity.get_list_with_categories(skip, limit)
        generate_response('ok', activities, nil, SUCCESSFUL_RESPONSE_CODE)
      end


      app.get URL + '/activities/:category_id' do
        content_type :json
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        category_id = nil
        begin
          category_id = Integer(params[:category_id])
        rescue ArgumentError, TypeError
          return generate_response('fail', nil, 'WRONG CATEGORY ID', CLIENT_ERROR_CODE)
        end
        activities = Activity.get_list_with_categories_in_category(category_id, skip, limit)
        generate_response('ok', activities, nil, SUCCESSFUL_RESPONSE_CODE)
      end
    end
  end
end