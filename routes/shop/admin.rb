require 'sinatra'
require_relative '../../config'

module Shop
  module Admin
    def self.registered(app)

      app.get URL + '/admin/:admin_token/accounts/:account_id/orders' do
        content_type :json
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        admin_token = params[:admin_token]
        resp = is_token_valid(admin_token)
        if resp[:status] == 'ok'
          owner_id = resp[:result][:id]
          account = Account.get_by_owner_and_type(owner_id, 'admin')
          if account.nil?
            generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            account_id = validate_integer(params[:account_id])
            if account_id.nil?
              return generate_response('fail', nil, 'WRONG ACCOUNT ID', CLIENT_ERROR_CODE)
            end
            target_account = Account.get_by_id(account_id)
            if target_account.nil?
              generate_response('fail', nil, 'TARGET USER DOES NOT EXIST', CLIENT_ERROR_CODE)
            else
              orders = Order.get_list_by_account_id(account_id, skip, limit)
              orders.each do |order|
                prepare_order(order, admin_token)
              end
              generate_response('ok', orders, nil, SUCCESSFUL_RESPONSE_CODE)
            end
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

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

      app.get URL + '/admin/:admin_token/orders/:order_id' do
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
          if order[:status] != 'in_process' && order[:status] != 'approved'
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
                  if order[:status] == 'approved'
                    deposit_points(contributor[:account_id], contributor[:points_amount])
                  else
                    Account.update_points_amount(contributor_account[:id], contributor_account[:points_amount] + contributor[:points_amount])
                  end
                end
              else
                customer_account = Account.get_by_id(order[:account_id])
                if order[:status] == 'approved'
                  deposit_points(customer_account[:id], order[:total_price])
                else
                  Account.update_points_amount(customer_account[:id], customer_account[:points_amount] + order[:total_price])
                end
              end
              Order.update_status(order_id, 'rejected')
              return generate_response('ok', { id: order[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

      # CreateItem
      app.post URL + '/admin/:admin_token/items' do
        content_type :json
        token = params[:admin_token]
        res = validate_input
        if res[:status] == 'fail'
          return generate_response('fail', nil, res[:result], CLIENT_ERROR_CODE)
        end
        item = res[:result][:item]
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner = resp[:result][:id]
          account = Account.get_by_owner_and_type(owner, 'admin')
          return generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE) if account.nil?
          res = validate_item(item)
          return generate_response('fail', nil, res[:description], CLIENT_ERROR_CODE) if res[:status] == 'fail'
          created_item = ShopItem.create(item[:title], item[:options], item[:quantity], item[:price], item[:category_id], item[:possible_joint_purchase], item[:max_buyers])
          if created_item.nil?
            return generate_response('fail', nil, 'ERROR WHILE CREATING ITEM', SERVER_ERROR_CODE)
          end
          generate_response('ok', { id: created_item[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          return generate_response('fail', nil, 'ERROR IN THE ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end


    end
  end
end