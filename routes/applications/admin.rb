require 'sinatra'

module Applications
  module Admin
    def self.registered(app)

      app.get URL + '/admin/:admin_token/accounts' do
        content_type :json
        admin_token = params[:admin_token]
        resp = is_token_valid(admin_token)
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner_and_type(id, 'admin')
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          accounts = Account.get_list(skip, limit)
          accounts.each do |account|
            prepare_account(account, admin_token)
          end
          generate_response('ok', accounts, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetAccount
      app.get URL + '/admin/:admin_token/accounts/:account_id' do
        content_type :json
        admin_token = params[:admin_token]
        resp = is_token_valid(admin_token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner_and_type(id, 'admin')
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            account_id = validate_integer(params[:account_id])
            if account_id.nil?
              return generate_response('fail', nil, 'WRONG ACCOUNT ID', CLIENT_ERROR_CODE)
            end
            target_account = Account.get_by_id(account_id)
            if target_account.nil?
              generate_response('fail', nil, 'TARGET USER DOES NOT EXIST', CLIENT_ERROR_CODE)
            else
              account_info = Account.to_info(target_account)
              prepare_account(account_info, admin_token)
              generate_response('ok', account_info, nil, SUCCESSFUL_RESPONSE_CODE)
            end
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetAccount'sApplications
      app.get URL + '/admin/:admin_token/accounts/:account_id/applications' do
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
              applications = Application.get_full_list_users_application(account_id, skip, limit)
              applications.each do |application|
                prepare_application(application, admin_token)
              end
              counter = Application.get_users_application_counter(account_id)
              generate_response('ok', { applications: applications, applications_counter: counter }, nil, SUCCESSFUL_RESPONSE_CODE)
            end
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# UpdateAccount
      app.put URL + '/admin/:admin_token/accounts/:account_id' do
        content_type :json
        res = validate_input
        if res[:status] == 'fail'
          return generate_response('fail', nil, res[:result], CLIENT_ERROR_CODE)
        end
        input = res[:result]
        admin_token = params[:admin_token]
        points_amount = validate_integer(input[:points_amount])
        action = input[:action]
        if points_amount.nil?
          return generate_response('fail', nil, 'WRONG POINTS AMOUNT', CLIENT_ERROR_CODE)
        end
        if action != 'decrease' && action != 'increase'
          return generate_response('fail', nil, 'WRONG ACTION', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(admin_token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner_and_type(id, 'admin')
          if account.nil?
            return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            account_id = validate_integer(params[:account_id])
            if account_id.nil?
              return generate_response('fail', nil, 'WRONG ACCOUNT ID', CLIENT_ERROR_CODE)
            end
            target_account = Account.get_by_id(account_id)
            if target_account.nil?
              return generate_response('fail', nil, 'TARGET USER DOES NOT EXIST', CLIENT_ERROR_CODE)
            else
              if target_account[:type] == 'admin'
                generate_response('fail', nil, 'IT IS NOT POSSIBLE TO UPDATE POINTS', CLIENT_ERROR_CODE)
              else
                case action
                  when 'increase'
                    transaction = Transaction.create(target_account[:id], points_amount)
                    if transaction.nil?
                      return generate_response('fail', nil, 'ERROR WHILE CREATING TRANSACTION', SERVER_ERROR_CODE)
                    end
                    Account.update_points_amount(target_account[:id], target_account[:points_amount].to_i + points_amount.to_i)
                    return generate_response('ok', { description: 'POINTS AMOUNT WAS UPDATED' }, nil, SUCCESSFUL_RESPONSE_CODE)
                  when 'decrease'
                    transactions = Transaction.get_list_active_by_account(target_account[:id])
                    unless is_enough_points_in_transactions(transactions, points_amount)
                      return generate_response('fail', nil, 'USER DOES NOT HAVE ENOUGH POINTS', CLIENT_ERROR_CODE)
                    end
                    update_points_in_transactions(transactions, points_amount)
                    Account.update_points_amount(target_account[:id], target_account[:points_amount] - points_amount)
                    return generate_response('ok', { description: 'POINTS AMOUNT WAS UPDATED' }, nil, SUCCESSFUL_RESPONSE_CODE)
                end
              end
            end
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetApplicationsInProcess
      app.get URL + '/admin/:admin_token/applications/in_process' do
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
            applications = Application.get_full_list_with_status('in_process', skip, limit)
            applications.each do |application|
              prepare_application(application, admin_token)
            end
            counter = Application.get_application_list_counter('in_process')
            generate_response('ok', { applications: applications, applications_counter: counter }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetApplicationsRejected
      app.get URL + '/admin/:admin_token/applications/rejected' do
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
            applications = Application.get_full_list_with_status('rejected', skip, limit)
            applications.each do |application|
              prepare_application(application, admin_token)
            end
            counter = Application.get_application_list_counter('rejected')
            generate_response('ok', { applications: applications, applications_counter: counter }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetApplicationsRework
      app.get URL + '/admin/:admin_token/applications/rework' do
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
            applications = Application.get_full_list_with_status('rework', skip, limit)
            applications.each do |application|
              application[:rework_comment] = ReworkComment.get_rework_comment(application[:id])
              prepare_application(application, admin_token)
            end
            counter = Application.get_application_list_counter('rework')
            generate_response('ok', { applications: applications, applications_counter: counter }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetApplicationsApproved
      app.get URL + '/admin/:admin_token/applications/approved' do
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
            applications = Application.get_full_list_with_status('approved', skip, limit)
            applications.each do |application|
              prepare_application(application, admin_token)
            end
            counter = Application.get_application_list_counter('approved')
            generate_response('ok', { applications: applications, applications_counter: counter }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# CreateApplication
      app.post URL + '/admin/:admin_token/applications' do
        content_type :json
        token = params[:admin_token]
        resp = is_token_valid(token)
        res = validate_input
        if res[:status] == 'fail'
          return generate_response('fail', nil, res[:result], CLIENT_ERROR_CODE)
        end
        input = res[:result]
        application = input[:application]
        if application.nil?
          return generate_response('fail', nil, 'APPLICATION PARAMETER IS NULL', CLIENT_ERROR_CODE)
        end
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner_and_type(id, 'admin')
          if account.nil?
            generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            res = validate_application(application, token, account[:id])
            if res[:status] == 'fail'
              return generate_response('fail', nil, res[:description], CLIENT_ERROR_CODE)
            end
            created_application = Application.create(account[:id], application[:type], application[:comment])
            if created_application.nil?
              return generate_response('fail', nil, 'ERROR WHILE CREATING APPLICATION OCCURED', SERVER_ERROR_CODE)
            end
            application[:work].each do |work|
              actor_account = Account.get_by_id(work[:actor])
              created_work = Work.create(actor_account[:id], work[:activity_id], created_application[:id], work[:amount])
              if created_work.nil?
                return generate_response('fail', nil, 'ERROR WHILE CREATING WORK OCCURED', SERVER_ERROR_CODE)
              end
            end
            folder = Dir.pwd + FILES_FOLDER + '/' + account[:id].to_s + '/' + created_application[:id].to_s
            FileUtils::mkdir_p(folder)
            generate_response('ok', { :id => created_application[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetApplication
      app.get URL + '/admin/:admin_token/applications/:application_id' do
        content_type :json
        admin_token = params[:admin_token]
        resp = is_token_valid(admin_token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner_and_type(id, 'admin')
          if account.nil?
            return generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          application_id = validate_integer(params[:application_id])
          if application_id.nil?
            return generate_response('fail', nil, 'WRONG TARGET APPLICATION ID', CLIENT_ERROR_CODE)
          end
          application = Application.get_full_by_id(application_id)
          if application.nil? || application[:status] == 'deleted'
            return generate_response('fail', nil, 'APPLICATION DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          prepare_application(application, admin_token)
          generate_response('ok', application, nil, SUCCESSFUL_RESPONSE_CODE)
        else
          generate_response('error', { :description => 'USER DOES NOT EXIST' })
        end
      end

# UpdateApplicationStatus
      app.put URL + '/admin/:admin_token/applications/:application_id/:action' do
        content_type :json
        admin_token = params[:admin_token]
        resp = is_token_valid(admin_token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner_and_type(id, 'admin')
          if account.nil?
            return generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          application_id = validate_integer(params[:application_id])
          if application_id.nil?
            return generate_response('fail', nil, 'WRONG TARGET APPLICATION ID', CLIENT_ERROR_CODE)
          end
          application = Application.get_by_id(application_id)
          if application.nil? || application[:status] == 'deleted'
            return generate_response('fail', nil, 'APPLICATION DOES NOT EXIST', CLIENT_ERROR_CODE)
          end
          if application[:status] != 'in_process'
            return generate_response('fail', nil, 'IT IS POSSIBLE ONLY FOR IN PROCESS APPLICATIONS', CLIENT_ERROR_CODE)
          end
          case params[:action]
            when 'reject'
              Application.update_status(application_id, 'rejected')
              return generate_response('ok', { :id => application_id }, nil, SUCCESSFUL_RESPONSE_CODE)
            when 'approve'
              works = Work.get_list_by_application_id(application_id)
              to_insert = Hash.new
              works.each do |work|
                activity = Activity.get_by_id(work[:activity_id])
                if activity[:type] == 'permanent'
                  to_insert.store(work[:actor], activity[:price])
                else
                  to_insert.store(work[:actor], activity[:price].to_i * work[:amount])
                end
                puts to_insert
              end
              Application.update_status(application_id, 'approved')
              to_insert.each do |acc_id, points|
                Transaction.create(acc_id, points)
                account = Account.get_by_id(acc_id)
                Account.update_points_amount(acc_id, account[:points_amount].to_i + points.to_i)
              end
              return generate_response('ok', { :id => application_id }, nil, SUCCESSFUL_RESPONSE_CODE)
            when 'to_rework'
              res = validate_input
              if res[:status] == 'fail'
                return generate_response('fail', nil, res[:result], CLIENT_ERROR_CODE)
              end
              comment = res[:result][:comment]
              Application.update_status(application_id, 'rework')
              rework_comment = ReworkComment.get_rework_comment(application_id)
              if rework_comment.nil?
                ReworkComment.create(application_id, comment)
              else
                ReworkComment.update(application_id, comment)
              end
              return generate_response('ok', { :id => application_id }, nil, SUCCESSFUL_RESPONSE_CODE)
            else
              return generate_response('fail', nil, 'WRONG ACTION', CLIENT_ERROR_CODE)
          end
        else
          generate_response('error', { :description => 'USER DOES NOT EXIST' })
        end
      end

# UpdateApplication
      app.put URL + '/admin/:admin_token/applications/:application_id' do
        content_type :json
        token = params[:admin_token]
        account_id = validate_integer(params[:account_id])
        application_id = validate_integer(params[:application_id])
        if account_id.nil?
          return generate_response('fail', nil, 'WRONG ACCOUNT ID', CLIENT_ERROR_CODE)
        end
        if application_id.nil?
          return generate_response('fail', nil, 'WRONG APPLICATION ID', CLIENT_ERROR_CODE)
        end
        res = validate_input
        if res[:status] == 'fail'
          return generate_response('fail', nil, res[:result], CLIENT_ERROR_CODE)
        end
        application = res[:result][:application]
        if application.nil?
          return generate_response('fail', nil, 'APPLICATION PARAMETER IS NULL', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner = resp[:result][:id]
          account = Account.get_by_owner_and_type(owner, 'admin')
          if account.nil?
            generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            res = validate_application(application, token, account[:id])
            if res[:status] == 'fail'
              return generate_response('fail', nil, res[:description], CLIENT_ERROR_CODE)
            end
            stored_application = Application.get_full_by_id(application_id)
            if stored_application.nil? || application[:status] == 'deleted'
              return generate_response('fail', nil, 'APPLICATION DOES NOT EXIST', CLIENT_ERROR_CODE)
            end
            if stored_application[:status] != 'in_process' && stored_application[:status] != 'rework'
              return generate_response('fail', nil, 'IT IS NOT POSSIBLE TO UPDATE APPLICATION', CLIENT_ERROR_CODE)
            end
            if application[:type] != stored_application[:type]
              return generate_response('fail', nil, 'IT IS NOT POSSIBLE TO CHANGE TYPE', CLIENT_ERROR_CODE)
            end
            actors = Array.new
            application[:work].each do |work|
              to_work_update = Hash.new
              stored_work = Work.get_by_application_id_and_actor(application_id, work[:actor])
              if stored_work.nil?
                created_work = Work.create(work[:actor], work[:activity_id], application_id, work[:amount])
                if created_work.nil?
                  return generate_response('fail', nil, 'ERROR WHILE CREATING WORK', SERVER_ERROR_CODE)
                end
                next
              end
              if stored_work[:activity_id] != work[:activity_id]
                to_work_update[:activity_id] = work[:activity_id]
                to_work_update[:amount] = work[:amount]
              elsif stored_work[:activity_id] == work[:activity_id] && stored_work[:amount] != work[:amount]
                to_work_update[:amount] = work[:amount]
              end
              if to_work_update.size > 0
                Work.update(stored_work[:id], to_work_update)
              end
              actors.push(work[:actor])
            end
            stored_works = Work.get_list_by_application_id(application_id)
            stored_works.each do |stored_work|
              unless actors.include?(stored_work[:actor])
                Work.delete_by_id(stored_work[:id])
              end
            end
            if application[:comment] != stored_application[:comment]
              Application.update_comment(stored_application[:id], application[:comment])
            end
            generate_response('ok', { id: stored_application[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end
    end
  end
end