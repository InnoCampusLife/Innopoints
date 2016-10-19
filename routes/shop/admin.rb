require 'sinatra'
require_relative '../../config'

module Shop
  module Admin
    def self.registered(app)

      app.get URL + '/admin/:admin_token/orders/in_process' do
        content_type :json
        token = params[:admin_token]
        skip = validate_skip(params[:skip])
        limit = validate_limit(params[:limit])
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner_and_type(id, 'admin')
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          orders = Order.get_list(skip, limit, 'in_process')
          orders.each do |order|
            prepare_order(order, token)
          end
          generate_response('ok', orders, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.get URL + '/admin/:admin_token/orders/rejected' do
        content_type :json
        token = params[:admin_token]
        skip = validate_skip(params[:skip])
        limit = validate_limit(params[:limit])
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner_and_type(id, 'admin')
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          orders = Order.get_list(skip, limit, 'rejected')
          orders.each do |order|
            prepare_order(order, token)
          end
          generate_response('ok', orders, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.get URL + '/admin/:admin_token/orders/approved' do
        content_type :json
        token = params[:admin_token]
        skip = validate_skip(params[:skip])
        limit = validate_limit(params[:limit])
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner_and_type(id, 'admin')
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          orders = Order.get_list(skip, limit, 'approved')
          orders.each do |order|
            prepare_order(order, token)
          end
          generate_response('ok', orders, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.get URL + '/admin/:admin_token/orders/waiting_to_process' do
        content_type :json
        token = params[:admin_token]
        skip = validate_skip(params[:skip])
        limit = validate_limit(params[:limit])
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner_and_type(id, 'admin')
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          orders = Order.get_list(skip, limit, 'waiting_to_process')
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
        token = params[:admin_token]
        order_id = validate_integer(params[:order_id])
        if order_id.nil?
          return generate_response('fail', nil, 'WRONG ORDER ID', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner_and_type(id, 'admin')
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          order = Order.get_full_by_id(order_id)
          if order.nil? || order[:status] == 'deleted'
            return generate_response('fail', nil, 'ORDER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          prepare_order(order, token)
          generate_response('ok', order, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      app.put URL + '/admin/:admin_token/orders/:order_id/:action' do
        content_type :json
        token = params[:admin_token]
        order_id = validate_integer(params[:order_id])
        if order_id.nil?
          return generate_response('fail', nil, 'WRONG ORDER ID', CLIENT_ERROR_CODE)
        end
        action = params[:action]
        if action != 'approve' && action != 'reject'
          return generate_response('fail', nil, 'WRONG ACTION', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          account = Account.get_by_owner_and_type(resp[:result][:id], 'admin')
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          order = Order.get_by_id(order_id)
          if order.nil? || order[:status] == 'deleted'
            return generate_response('fail', nil, 'ORDER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          if order[:status] != 'in_process'
            return generate_response('fail', nil, 'WRONG ORDER STATUS', CLIENT_ERROR_CODE)
          end
          case action
            when 'approve'
              if order[:is_joint_purchase]
                contributors = OrderContributor.get_list_by_order_id(order[:id])
                account_transaction = Hash.new
                contributors.each do |contributor|
                  transactions = Transaction.get_list_active_by_account(contributor[:account_id])
                  account_transaction[contributor[:account_id]] = transactions
                  unless is_enough_points_in_transactions(transactions, contributor[:points_amount])
                    return generate_response('fail', nil, 'USER DOES NOT HAVE ENOUGH POINTS')
                  end
                end
                contributors.each do |contributor|
                  transactions = account_transaction[contributor[:account_id]]
                  amount = contributor[:points_amount]
                  update_points_in_transactions(transactions, amount)
                end
              else
                customer_account = Account.get_by_id(order[:account_id])
                transactions = Transaction.get_list_active_by_account(customer_account[:id])
                unless is_enough_points_in_transactions(transactions, order[:total_price])
                  return generate_response('fail', nil, 'USER DOES NOT HAVE ENOUGH POINTS', CLIENT_ERROR_CODE)
                end
                update_points_in_transactions(transactions, order[:total_price])
              end
              Order.update_status(order[:id], 'approved')
              return generate_response('ok', { id: order[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
            when 'reject'
              items_in_order = ItemInOrder.get_list_in_order(order[:id])
              items_in_order.each do |item_in_order|
                item = ShopItem.get_by_id(item_in_order[:item_id])
                ShopItem.update_quantity(item[:id], item[:quantity] + item_in_order[:amount])
              end
              if order[:is_joint_purchase]
                contributors = OrderContributor.get_list_by_order_id(order_id)
                contributors.each do |contributor|
                  contributor_account = Account.get_by_id(contributor[:account_id])
                  Account.update_points_amount(contributor_account[:id], contributor_account[:points_amount] + contributor[:points_amount])
                end
              else
                customer_account = Account.get_by_id(order[:account_id])
                Account.update_points_amount(customer_account[:id], customer_account[:points_amount] + order[:total_price])
              end
              Order.update_status(order_id, 'rejected')
              return generate_response('ok', { id: order[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end
    end
  end
end