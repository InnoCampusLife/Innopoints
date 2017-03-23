require 'sinatra'
require_relative '../../config'

module Shop
  module User
    def self.registered(app)

      app.get URL + '/accounts/:token/orders/in_process' do
        content_type :json
        token = params[:token]
        skip = validate_skip(params[:skip])
        limit = validate_limit(params[:limit])
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          orders = Order.get_list_by_account_id(account[:id], skip, limit, 'in_process')
          orders.each do |order|
            prepare_order(order, token)
          end
          generate_response('ok', orders, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.get URL + '/accounts/:token/orders/approved' do
        content_type :json
        token = params[:token]
        skip = validate_skip(params[:skip])
        limit = validate_limit(params[:limit])
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          orders = Order.get_list_by_account_id(account[:id], skip, limit, 'approved')
          orders.each do |order|
            prepare_order(order, token)
          end
          generate_response('ok', orders, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.get URL + '/accounts/:token/orders/rejected' do
        content_type :json
        token = params[:token]
        skip = validate_skip(params[:skip])
        limit = validate_limit(params[:limit])
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          orders = Order.get_list_by_account_id(account[:id], skip, limit, 'rejected')
          orders.each do |order|
            prepare_order(order, token)
          end
          generate_response('ok', orders, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.get URL + '/accounts/:token/orders/waiting_to_process' do
        content_type :json
        token = params[:token]
        skip = validate_skip(params[:skip])
        limit = validate_limit(params[:limit])
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          orders = Order.get_list_by_account_id(account[:id], skip, limit, 'waiting_to_process')
          orders.each do |order|
            prepare_order(order, token)
          end
          generate_response('ok', orders, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.get URL + '/accounts/:token/orders/:order_id' do
        content_type :json
        token = params[:token]
        order_id = validate_integer(params[:order_id])
        if order_id.nil?
          return generate_response('fail', nil, 'WRONG ORDER ID', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          order = Order.get_full_by_id(order_id)
          if order.nil? || order[:status] == 'deleted'
            return generate_response('fail', nil, 'ORDER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          if order[:author] != account[:owner]
            return generate_response('fail', nil, 'USER DOES NOT HAVE ACCESS', CLIENT_ERROR_CODE)
          end
          prepare_order(order, token)
          generate_response('ok', order, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.post URL + '/accounts/:token/orders' do
        content_type :json
        token = params[:token]
        resp = is_token_valid(token)
        input = validate_input
        if input[:status] == 'fail'
          return generate_response('fail', nil, input[:result], CLIENT_ERROR_CODE)
        end
        order = input[:result][:order]
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          res = validate_order(order, account[:id])
          if res[:status] == 'fail'
            return generate_response('fail', nil, res[:description], CLIENT_ERROR_CODE)
          end
          created_order = Order.create(account[:id], order[:is_joint_purchase], order[:total_price])
          if created_order.nil?
            return generate_response('fail', nil, 'ERROR WHILE CREATING ORDER', SERVER_ERROR_CODE)
          end
          order[:items].each do |item|
            ItemInOrder.create(created_order[:id], item[:id], item[:amount])
            # unless order[:is_joint_purchase]
            stored_item = ShopItem.get_by_id(item[:id])
            ShopItem.update_quantity(stored_item[:id], stored_item[:quantity] - item[:amount])
            # end
          end
          unless order[:is_joint_purchase]
            Account.update_points_amount(account[:id], account[:points_amount] - order[:total_price])
          end
          if order[:is_joint_purchase]
            order[:contributors].each do |contributor|
              OrderContributor.create(created_order[:id], contributor[:id], contributor[:points_amount])
            end
          end
          return generate_response('ok', { :id => created_order[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.get URL + '/accounts/:token/orders' do
        content_type :json
        token = params[:token]
        skip = validate_skip(params[:skip])
        limit = validate_limit(params[:limit])
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          orders = Order.get_list_by_account_id(account[:id], skip, limit)
          orders.each do |order|
            prepare_order(order, token)
          end
          generate_response('ok', orders, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.put URL + '/accounts/:token/orders/:order_id/contributors/:action' do
        content_type :json
        token = params[:token]
        order_id = validate_integer(params[:order_id])
        if order_id.nil?
          return generate_response('fail', nil, 'WRONG ORDER ID', CLIENT_ERROR_CODE)
        end
        action = params[:action]
        if action != 'agree' && action != 'disagree'
          return generate_response('fail', nil, 'WRONG ACTION', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          order = Order.get_by_id(order_id)
          if order.nil? || order[:status] == 'deleted'
            return generate_response('fail', nil, 'ORDER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          if order[:status] != 'waiting_to_process'
            return generate_response('fail', nil, 'WRONG ORDER STATUS', CLIENT_ERROR_CODE)
          end
          contributor = OrderContributor.get_by_order_id_and_account_id(order_id, account[:id])
          if contributor.nil?
            return generate_response('fail', nil, 'USER IS NOT AMONG THE CONTRIBUTORS', CLIENT_ERROR_CODE)
          end
          if account[:points_amount] < contributor[:points_amount]
            return generate_response('fail', nil, 'CONTRIBUTOR DOES NOT HAVE ENOUGH POINTS', CLIENT_ERROR_CODE)
          end
          OrderContributor.update_is_agreed(action, order_id, account[:id])
          Account.update_points_amount(account[:id], account[:points_amount] - contributor[:points_amount])
          case action
            when 'agree'
              contributors = OrderContributor.get_list_by_order_id(order_id)
              all_agreed = true
              contributors.each do |user|
                unless user[:is_agreed]
                  all_agreed = false
                end
              end
              if all_agreed
                Order.update_status(order_id, 'in_process')
              end
              return generate_response('ok', { description: 'Order was updated'}, nil, SUCCESSFUL_RESPONSE_CODE)
            when 'disagree'
              Order.update_status(order_id, 'rejected_by_contributor')
              return generate_response('ok', { description: 'Order was updated'}, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.delete URL + '/accounts/:token/orders/:order_id' do
        content_type :json
        token = params[:token]
        order_id = validate_integer(params[:order_id])
        if order_id.nil?
          return generate_response('fail', nil, 'WRONG ORDER ID', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          order = Order.get_by_id(order_id)
          if order.nil?
            return generate_response('fail', nil, 'ORDER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          if order[:account_id] != account[:id]
            return generate_response('fail', nil, 'USER DOES NOT HAVE ACCESS TO THE ORDER', CLIENT_ERROR_CODE)
          end
          if order[:status] != 'in_process' && order[:status] != 'waiting_to_process'
            return generate_response('fail', nil, 'WRONG ORDER STATUS', CLIENT_ERROR_CODE)
          end
          items_in_order = ItemInOrder.get_list_in_order(order[:id])
          items_in_order.each do |item_in_order|
            item = ShopItem.get_by_id(item_in_order[:item_id])
            ShopItem.update_quantity(item[:id], item[:quantity] + item_in_order[:amount])
          end
          # ItemInOrder.delete_by_order_id(order_id)
          if order[:is_joint_purchase]
            contributors = OrderContributor.get_list_by_order_id(order_id)
            contributors.each do |contributor|
              contributor_account = Account.get_by_id(contributor[:account_id])
              Account.update_points_amount(contributor_account[:id], contributor_account[:points_amount] + contributor[:points_amount])
            end
            # OrderContributor.delete_by_order_id(order_id)
          else
            Account.update_points_amount(account[:id], account[:points_amount] + order[:total_price])
          end
          Order.delete_by_id(order_id)
          return generate_response('ok', { description: 'Order was deleted' }, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end
    end
  end
end