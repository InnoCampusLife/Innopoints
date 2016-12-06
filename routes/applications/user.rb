require 'sinatra'

module Applications
  module User
    def self.registered(app)

      app.get URL + '/accounts/:token' do
        content_type :json
        token = params[:token]
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner_id = resp[:result][:id]
          account = Account.get_by_owner(owner_id)
          if account.nil?
            generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            account_info = Account.to_info(account)
            prepare_account(account_info, token)
            generate_response('ok', account_info, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# CreateAccount
      app.post URL + '/accounts/:token' do
        content_type :json
        token = params[:token]
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner_id = resp[:result][:id]
          account = Account.get_by_owner(owner_id)
          if account.nil?
            type = nil
            if resp[:result][:role] == 'student'
              type = 'student'
            elsif resp[:result][:role] == 'moderator'
              type = 'admin'
            else
              generate_response('fail', nil, 'WRONG ROLE', CLIENT_ERROR_CODE)
            end
            account = Account.create(owner_id, type)
            if account.nil?
              generate_response('fail', nil, 'CAN\'T CREATE AN ACCOUNT', SERVER_ERROR_CODE)
            else
              account_info = Account.to_info(account)
              FileUtils::mkdir_p(Dir.pwd + FILES_FOLDER + '/' + account[:id].to_s)
              prepare_account(account_info, token)
              generate_response('ok', account_info, nil, SUCCESSFUL_RESPONSE_CODE)
            end
          else
            generate_response('fail', nil, 'ACCOUNT ALREADY EXISTS', CLIENT_ERROR_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

=begin
CreateApplication
{
  application: {
    type: 'personal', //'group'
    work: [
      {
        {
              actor: 1, // id of user in accounts microservice. Has to be the same as id of user with :token if type personal
              activity_id: 1 // id of activity
              amount: 3, # null for permanent activities
          },
          {
            ...
          }
      }
    ],
    comment: ""
  }
}
=end
      app.post URL + '/accounts/:token/applications' do
        content_type :json
        res = validate_input
        if res[:status] == 'fail'
          return generate_response('fail', nil, res[:result], CLIENT_ERROR_CODE)
        end
        input = res[:result]
        if input[:application].nil?
          return generate_response('fail', nil, 'APPLICATION IS NULL', CLIENT_ERROR_CODE)
        end
        application = input[:application]
        token = params[:token]
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
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
            # application[:files].each do |file|
            #   file_name = file[:filename]
            #   name_parts = file_name.split('.')
            #   extension = ''
            #   (1..(name_parts.length - 1)).each { |i|
            #     extension += ('.' + name_parts[i])
            #   }
            #   created_file = StoredFile.create(created_application[:id],file[:filename], file[:type], extension)
            #   if created_file.nil?
            #     return generate_response('fail', nil, 'ERROR WHILE CREATING FILE OCCURED', SERVER_ERROR_CODE)
            #   end
            #   File.open(folder + '/' + created_file[:id].to_s + extension, 'w') do |f|
            #     f.write(file[:tempfile].read)
            #   end
            #   download_link = URL + '/accounts/' + token + '/applications/' + created_application[:id] + '/files/' + created_file[:id].to_s + extension
            #   StoredFile.update_download_link(created_file[:id], download_link)
            # end
            generate_response('ok', { :id => created_application[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'USER DOES NOT EXIST', SERVER_ERROR_CODE)
        end
      end

# GetAllApplications
      app.get URL + '/accounts/:token/applications' do
        content_type :json
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        token = params[:token]
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner_id = resp[:result][:id]
          account = Account.get_by_owner(owner_id)
          if account.nil?
            generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            applications = Application.get_full_list_users_application(account[:id], skip, limit)
            applications.each do |application|
              prepare_application(application, token)
            end
            counter = Application.get_users_application_counter(account[:id])
            generate_response('ok', { applications: applications, applications_counter: counter }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetApplicationsInProcess
      app.get URL + '/accounts/:token/applications/in_process' do
        content_type :json
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        token = params[:token]
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner_id = resp[:result][:id]
          account = Account.get_by_owner(owner_id)
          if account.nil?
            generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            applications = Application.get_full_list_users_application(account[:id], skip, limit, 'in_process')
            applications.each do |application|
              prepare_application(application, token)
            end
            counter = Application.get_users_application_counter(account[:id])
            generate_response('ok', { applications: applications, applications_counter: counter }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetApplicationsRejected
      app.get URL + '/accounts/:token/applications/rejected' do
        content_type :json
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        token = params[:token]
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner_id = resp[:result][:id]
          account = Account.get_by_owner(owner_id)
          if account.nil?
            generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            applications = Application.get_full_list_users_application(account[:id], skip, limit, 'rejected')
            applications.each do |application|
              prepare_application(application, token)
            end
            counter = Application.get_users_application_counter(account[:id])
            generate_response('ok', { applications: applications, applications_counter: counter }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetApplicationsRework
      app.get URL + '/accounts/:token/applications/rework' do
        content_type :json
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        token = params[:token]
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner_id = resp[:result][:id]
          account = Account.get_by_owner(owner_id)
          if account.nil?
            generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            applications = Application.get_full_list_users_application(account[:id], skip, limit, 'rework')
            applications.each do |application|
              application[:rework_comment] = ReworkComment.get_rework_comment(application[:id])
              prepare_application(application, token)
            end
            counter = Application.get_users_application_counter(account[:id])
            generate_response('ok', { applications: applications, applications_counter: counter }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetApplicationsApproved
      app.get URL + '/accounts/:token/applications/approved' do
        content_type :json
        skip = validate_skip(params[:skip])
        limit =  validate_limit(params[:limit])
        token = params[:token]
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner_id = resp[:result][:id]
          account = Account.get_by_owner(owner_id)
          if account.nil?
            generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            applications = Application.get_full_list_users_application(account[:id], skip, limit, 'approved')
            applications.each do |application|
              prepare_application(application, token)
            end
            counter = Application.get_users_application_counter(account[:id])
            generate_response('ok', { applications: applications, applications_counter: counter }, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

=begin
GetApplication
{
  status: 'ok',
  result: {
    id: 1,
    type: 'personal',
    work: [
      {
        actor: 1 // uis id
        activity: {
          id: 1,
          title: 'Title',
          type: 'hourly'
          category: {
            id: 1,
            title: 'Category title'
          },
          price: 100
        },
        amount: 3,
        total_price: 300
      }
    ],
    files: [
      {
        "filename": "file.jpg",
        "type": "image/jpeg",
        "id": "576d13650000000000000000",
        "download_link": "/points/api/v1/accounts/test/applications/576d13650000000000000000/files/576d13650000000000000000"
      }
    ],
    comment: "Comment",
    creation_date: "2016-06-24 11:03:01 UTC",
    status:  "in_process"
  }
}
=end
      app.get URL + '/accounts/:token/applications/:application_id' do
        content_type :json
        token = params[:token]
        application_id = params[:application_id]
        begin
          application_id = Integer(application_id)
        rescue ArgumentError, TypeError
          return generate_response('fail', nil, 'WRONG APLICATION ID', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner_id = resp[:result][:id]
          account = Account.get_by_owner(owner_id)
          if account.nil?
            generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            application = Application.get_full_by_id_and_author(application_id, account[:id])
            if application.nil? || application[:status] == 'deleted'
              generate_response('fail', nil, 'APPLICATION DOES NOT EXIST', CLIENT_ERROR_CODE)
            else
              prepare_application(application, token)
              generate_response('ok', application, nil, SUCCESSFUL_RESPONSE_CODE)
            end
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# GetFile
      app.get URL + '/accounts/:token/files/:file_id' do
        content_type :json
        token = params[:token]
        file_id = validate_integer(params[:file_id])
        if file_id.nil?
          return generate_response('fail', nil, 'WRONG FILE ID', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          account = Account.get_by_owner(resp[:result][:id])
          if account.nil?
            return generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            file = StoredFile.get_with_author_by_id(file_id)
            if file.nil?
              return generate_response('fail', nil, 'FILE DOES NOT EXIST', CLIENT_ERROR_CODE)
            end
            if account[:type] == 'admin'
              file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + file[:account_id].to_s + '/' + file[:application_id].to_s + '/' + file_id.to_s + file[:extension]
              if File.exists?(file_url)
                send_file file_url, :filename => file[:filename], :type => 'Application/octet-stream'
              else
                generate_response('fail', nil, 'FILE DOES NOT EXIST ON SERVER', SERVER_ERROR_CODE)
              end
            else
              unless account[:id] == file[:account_id]
                return generate_response('fail', nil, 'USER DOES NOT HAVE ACCESS TO THE FILE', SERVER_ERROR_CODE)
              end
              file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + file[:account_id].to_s + '/' + file[:application_id].to_s + '/' + file_id.to_s + file[:extension]
              if File.exists?(file_url)
                send_file file_url, :filename => file[:filename], :type => 'Application/octet-stream'
              else
                generate_response('fail', nil, 'FILE DOES NOT EXIST ON SERVER', SERVER_ERROR_CODE)
              end
            end
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# DeleteFile
      app.delete URL + '/accounts/:token/files/:file_id' do
        content_type :json
        token = params[:token]
        file_id = validate_integer(params[:file_id])
        if file_id.nil?
          return generate_response('fail', nil, 'WRONG FILE ID', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            return generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            if account[:type] == 'admin'
              stored_file = StoredFile.get_with_author_by_id(file_id)
              if stored_file.nil?
                return generate_response('fail', nil, 'FILE DOES NOT EXIST', CLIENT_ERROR_CODE)
              end
              StoredFile.delete_by_id(file_id)
              file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + stored_file[:account_id].to_s + '/' + stored_file[:application_id].to_s + '/' + file_id.to_s + stored_file[:extension]
              if File.exists?(file_url)
                File.delete(file_url)
              end
              generate_response('ok', { :description => 'FILE WAS DELETED' }, nil, SUCCESSFUL_RESPONSE_CODE)
            else
              stored_file = StoredFile.get_with_author_by_id(file_id)
              if stored_file.nil?
                return generate_response('fail', nil, 'FILE DOES NOT EXIST', CLIENT_ERROR_CODE)
              end
              unless stored_file[:account_id] == account[:id]
                return generate_response('fail', nil, 'USER DOES NOT HAVE ACCESS TO THE FILE', CLIENT_ERROR_CODE)
              end
              StoredFile.delete_by_id(file_id)
              file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + stored_file[:account_id].to_s + '/' + stored_file[:application_id].to_s + '/' + file_id.to_s + stored_file[:extension]
              if File.exists?(file_url)
                File.delete(file_url)
              end
              generate_response('ok', { :description => 'FILE WAS DELETED' }, nil, SUCCESSFUL_RESPONSE_CODE)
            end
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

# DeleteApplication
      app.delete URL + '/accounts/:token/applications/:application_id' do
        content_type :json
        token = params[:token]
        application_id = validate_integer(params[:application_id])
        if application_id.nil?
          return generate_response('fail', nil, 'WRONG APPLICATION ID', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          id = resp[:result][:id]
          account = Account.get_by_owner(id)
          if account.nil?
            generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            application = Application.get_by_id_and_author(application_id, account[:id])
            if application.nil? || application[:status] == 'deleted'
              generate_response('fail', nil, 'APPLICATION DOES NOT EXIST', CLIENT_ERROR_CODE)
            else
              if application[:status] == 'in_process' || application[:status] == 'rejected'
                Application.delete_by_id(application_id)
                generate_response('ok', 'Application was deleted', nil, SUCCESSFUL_RESPONSE_CODE)
              else
                generate_response('fail', nil, 'IT IS NOT POSSIBLE TO DELETE THE APPLICATION', CLIENT_ERROR_CODE)
              end
            end
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end

=begin
UpdateApplication
{
  application: {
    type: 'personal', //'group'
    work: [
      {
        {
              actor: 1, // id of user in accounts microservice. Has to be the same as id of user with :token if type personal
              activity_id: 1 // id of activity
              amount: 3, # null for permanent activities
          },
          {
            ...
          }
      }
    ],
    comment: ""
  }
}
=end
      app.put URL + '/accounts/:token/applications/:application_id' do
        content_type :json
        token = params[:token]
        application_id = validate_integer(params[:application_id])
        res = validate_input
        if res[:status] == 'fail'
          return generate_response('fail', nil, res[:result], CLIENT_ERROR_CODE)
        end
        if application_id.nil?
          return generate_response('fail', nil, 'WRONG APPLICATION ID', CLIENT_ERROR_CODE)
        end
        application = res[:result][:application]
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner = resp[:result][:id]
          account = Account.get_by_owner(owner)
          if account.nil?
            generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            res = validate_application(application, token, account[:id])
            if res[:status] == 'fail'
              return generate_response('fail', nil, res[:description], CLIENT_ERROR_CODE)
            end
            stored_application = Application.get_full_by_id_and_author(application_id, account[:id])
            if stored_application.nil? || stored_application[:status] == 'deleted'
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

# SendToApprove
      app.put URL + '/accounts/:token/applications/:application_id/approve' do
        content_type :json
        token = params[:token]
        application_id = validate_integer(params[:application_id])
        if application_id.nil?
          return generate_response('fail', nil, 'WRONG APPLICATION ID', CLIENT_ERROR_CODE)
        end
        resp = is_token_valid(token)
        if resp[:status] == 'ok'
          owner = resp[:result][:id]
          account = Account.get_by_owner(owner)
          if account.nil?
            generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
          else
            application = Application.get_full_by_id_and_author(application_id, account[:id])
            if application.nil? || application[:status] == 'deleted'
              return generate_response('fail', nil, 'APPLICATION DOES NOT EXIST', CLIENT_ERROR_CODE)
            end
            if application[:status] != 'rework'
              return generate_response('fail', nil, 'WRONG STATUS OF THE APPLICATION', CLIENT_ERROR_CODE)
            end
            Application.update_status(application_id, 'in_process')
            generate_response('ok', { :description => 'application was sent for approval'}, nil, SUCCESSFUL_RESPONSE_CODE)
          end
        else
          generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
        end
      end
    end
  end
end