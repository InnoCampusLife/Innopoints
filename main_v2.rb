require 'sinatra'
require 'json'
require 'fileutils'
require 'httparty'
require_relative 'config'
require_relative 'models/category'
require_relative 'models/account'
require_relative 'models/activity'
require_relative 'models/application'
require_relative 'models/shop_item'
require_relative 'models/stored_file'
require_relative 'models/transaction'
require_relative 'models/work'
require_relative 'models/order'
require_relative 'models/item_in_order'
require_relative 'models/order_contributor'

set :public_folder => '/public'

set :bind, WEB_HOST
set :port, WEB_PORT

SERVER_ERROR_CODE = 500
CLIENT_ERROR_CODE = 400
SUCCESSFUL_RESPONSE_CODE = 200

helpers do

  def is_integer_valid(integer)
    begin
      integer = Integer(integer)
      integer
    rescue ArgumentError, TypeError
      nil
    end
  end

  def validate_skip(skip)
    begin
      skip = Integer(skip)
    rescue ArgumentError, TypeError
      skip = 0
    end
    if skip < 0
      skip = 0
    end
    skip
  end

  def validate_limit(limit)
    begin
      limit = Integer(limit)
    rescue ArgumentError, TypeError
      limit = DEFAULT_LIMIT
    end
    if limit < 0
      limit = 0
    end
    limit
  end

  def generate_response(status, result, error, status_code)
    status status_code
    resp = Hash.new
    resp[:status] = status
    if status == 'ok'
      resp[:result] = result
    else
      resp[:error] = error
    end
    resp.to_json
  end

  # CheckToken
  def is_token_valid(token)
    # resp = HTTParty.get(ACCOUNTS_URL + token)
    resp = Hash.new
    if token == 'test'
      resp[:status] = 'ok'
      resp[:result] = Hash.new
      resp[:result][:id] = 1
      resp[:result][:role] = 'student'
    elsif token == 'admin'
      resp[:status] = 'ok'
      resp[:result] = Hash.new
      resp[:result][:id] = 2
      resp[:result][:role] = 'moderator'
    elsif token == 'student'
      resp[:status] = 'ok'
      resp[:result] = Hash.new
      resp[:result][:id] = 3
      resp[:result][:role] = 'student'
    else
      resp[:status] = 'error'
    end
    #
    resp
    # JSON.parse(resp.body, symbolize_names: true)
  end

  def is_activity_correct(activity_id, price)
    activity = Activity.get_by_id(activity_id)
    if activity.nil?
      return false
    end
    if activity[:price] != price
      return false
    end
    true
  end


end
# GetCategories
get URL + '/categories' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  categories = Category.get_list(skip, limit)
  generate_response('ok', categories, nil, SUCCESSFUL_RESPONSE_CODE)
end

# GetActivities
get URL + '/activities' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  activities = Activity.get_list_with_categories(skip, limit)
  generate_response('ok', activities, nil, SUCCESSFUL_RESPONSE_CODE)
end

# GetActivitiesInCategory
get URL + '/activities/:category_id' do
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

# GetAccount
get URL + '/accounts/:token' do
  content_type :json
  resp = is_token_valid(params[:token])
  if resp[:status] == 'ok'
    owner_id = resp[:result][:id]
    account = Account.get_by_owner(owner_id)
    if account.nil?
      generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      account_info = Account.to_info(account)
      generate_response('ok', account_info, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# CreateAccount
post URL + '/accounts/:token' do
  content_type :json
  resp = is_token_valid(params[:token])
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
        generate_response('ok', account_info, nil, SUCCESSFUL_RESPONSE_CODE)
      end
    else
      generate_response('fail', nil, 'ACCOUNT ALREADY EXISTS', CLIENT_ERROR_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# CreateApplication
post URL + '/accounts/:token/applications' do
  content_type :json
  token = params[:token]
  resp = is_token_valid(token)
  application = params[:application]
  # application = {
  #     type: 'personal', # personal/group
  #     personal: {
  #         work: {
  #             activity: {
  #                 id: '2',
  #                 title: 'hui',
  #                 type: 'permanent',
  #                 category: {
  #                     id: '2',
  #                     title: 'Sport'
  #                 },
  #                 price: 200
  #             },
  #             amount: nil, # null for permanent actxivity
  #         }
  #     },
  #     group: nil,
  #     files: [
          # {
          #     filename: 'weather-1.jpg',
          #     tempfile: '#<Tempfile:/tmp/RackMultipart20160624-29189-m0ztz3.jpg>',
          #     type: 'image/jpeg',
          #     head: 'Content-Disposition: form-data; name=\"test_file\"; filename=\"weather-1.jpg\"\r\nContent-Type: image/jpeg\r\n"'
          # }
      # ],
      # comment: 'Some comment'
  # }
  # application = params[:application]
  puts '----------------------------------------'
  puts params
  puts '----------------------------------------'
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = Account.get_by_owner(id)
    if account.nil?
      generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      if application.nil?
        return generate_response('fail', nil, 'APPLICATION PARAMETER IS NULL', CLIENT_ERROR_CODE)
      end
      if account[:type] == 'admin' && application[:type] == 'personal'
        return generate_response('fail', nil, 'ADMIN CAN\'T CREATE PERSONAL APPLICATION', CLIENT_ERROR_CODE)
      end
      works = Array.new
      case application[:type]
        when 'personal'
          work = application[:personal][:work]
          unless is_activity_correct(work[:activity][:id], work[:activity][:price])
            return generate_response('fail', nil, 'ERROR IN AN ACTIVITY', CLIENT_ERROR_CODE)
          end
          work[:actor] = account[:owner]
          works.push(work)
        when 'group'
          application[:group][:work].each do |work|
            unless is_activity_correct(work[:activity][:id], work[:activity][:price])
              return generate_response('fail', nil, 'ERROR IN AN ACTIVITY', CLIENT_ERROR_CODE)
            end
          end
          works = application[:group][:work]
      end
      created_application = Application.create(account[:id], application[:type], application[:comment])
      if created_application.nil?
        return generate_response('fail', nil, 'ERROR WHILE CREATING APPLICATION OCCURED', SERVER_ERROR_CODE)
      end
      works.each do |work|
        actor_account = Account.get_by_owner(work[:actor])
        if actor_account.nil?
          actor_account = Account.create(work[:actor], 'student')
        end
        created_work = Work.create(actor_account[:id], work[:activity][:id], created_application[:id], work[:amount])
        if created_work.nil?
          return generate_response('fail', nil, 'ERROR WHILE CREATING WORK OCCURED', SERVER_ERROR_CODE)
        end
      end
      folder = Dir.pwd + FILES_FOLDER + '/' + account[:id].to_s + '/' + created_application[:id].to_s
      FileUtils::mkdir_p(folder)
      application[:files].each do |file|
        file_name = file[:filename]
        name_parts = file_name.split('.')
        extension = ''
        (1..(name_parts.length - 1)).each { |i|
          extension += ('.' + name_parts[i])
        }
        created_file = StoredFile.create(created_application[:id],file[:filename], file[:type], extension)
        if created_file.nil?
          return generate_response('fail', nil, 'ERROR WHILE CREATING FILE OCCURED', SERVER_ERROR_CODE)
        end
        File.open(folder + '/' + created_file[:id].to_s + extension, 'w') do |f|
          f.write(file[:tempfile].read)
        end
        download_link = URL + '/accounts/' + token + '/applications/' + created_application[:id] + '/files/' + created_file[:id].to_s + extension
        StoredFile.update_download_link(created_file[:id], download_link)
      end
      generate_response('ok', { :id => created_application[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'USER DOES NOT EXIST', SERVER_ERROR_CODE)
  end
end

# GetAllApplications
get URL + '/accounts/:token/applications' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  resp = is_token_valid(params[:token])
  if resp[:status] == 'ok'
    owner_id = resp[:result][:id]
    account = Account.get_by_owner(owner_id)
    if account.nil?
      generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      applications = Application.get_list_users_application(account[:id], skip, limit)
      generate_response('ok', applications, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetApplicationsInProcess
get URL + '/accounts/:token/applications/in_process' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  resp = is_token_valid(params[:token])
  if resp[:status] == 'ok'
    owner_id = resp[:result][:id]
    account = Account.get_by_owner(owner_id)
    if account.nil?
      generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      applications = Application.get_list_users_application(account[:id], skip, limit, 'in_process')
      generate_response('ok', applications, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetApplicationsRejected
get URL + '/accounts/:token/applications/rejected' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  resp = is_token_valid(params[:token])
  if resp[:status] == 'ok'
    owner_id = resp[:result][:id]
    account = Account.get_by_owner(owner_id)
    if account.nil?
      generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      applications = Application.get_list_users_application(account[:id], skip, limit, 'rejected')
      generate_response('ok', applications, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetApplicationsRework
get URL + '/accounts/:token/applications/rework' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  resp = is_token_valid(params[:token])
  if resp[:status] == 'ok'
    owner_id = resp[:result][:id]
    account = Account.get_by_owner(owner_id)
    if account.nil?
      generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      applications = Application.get_list_users_application(account[:id], skip, limit, 'rework')
      generate_response('ok', applications, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetApplicationsApproved
get URL + '/accounts/:token/applications/approved' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  resp = is_token_valid(params[:token])
  if resp[:status] == 'ok'
    owner_id = resp[:result][:id]
    account = Account.get_by_owner(owner_id)
    if account.nil?
      generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      applications = Application.get_list_users_application(account[:id], skip, limit, 'approved')
      generate_response('ok', applications, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetApplication
get URL + '/accounts/:token/applications/:application_id' do
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
      if application.nil?
        generate_response('fail', nil, 'APPLICATION DOES NOT EXIST', CLIENT_ERROR_CODE)
      else
        generate_response('ok', application, nil, SUCCESSFUL_RESPONSE_CODE)
      end
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetFile
get URL + '/accounts/:account_id/applications/:application_id/files/:file' do
  content_type :json
  account_id = params[:account_id]
  application_id = params[:application_id]
  filename = params[:file]
  begin
    application_id = Integer(application_id)
  rescue ArgumentError, TypeError
    return generate_response('fail', nil, 'WRONG APLICATION ID', CLIENT_ERROR_CODE)
  end
  begin
    account_id = Integer(account_id)
  rescue ArgumentError, TypeError
    return generate_response('fail', nil, 'WRONG ACCOUNT ID', CLIENT_ERROR_CODE)
  end
  name_parts = filename.split('.')
  file_id = name_parts[0]
  account = Account.get_by_id(account_id)
  if account.nil?
    return generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
  else
    file = StoredFile.get_by_id(file_id)
    if file.nil?
      generate_response('fail', nil, 'FILE DOES NOT EXIST', CLIENT_ERROR_CODE)
    elsif file[:application_id] != application_id
      generate_response('fail', nil, 'WRONG APPLICATION', CLIENT_ERROR_CODE)
    else
      file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + account[:id] + '/' + application[:id] + '/' + params[:file]
      if File.exists?(file_url)
        send_file file_url, :filename => file[:filename], :type => 'Application/octet-stream'
      else
        generate_response('fail', nil, 'FILE DOES NOT EXIST ON SERVER', SERVER_ERROR_CODE)
      end
    end
  end
end

# DeleteFile
delete URL + '/accounts/:token/applications/:application_id/files/:file' do
  content_type :json
  token = params[:token]
  application_id = params[:application_id]
  filename = params[:file]
  name_parts = filename.split('.')
  file_id = name_parts[0]
  begin
    application_id = Integer(application_id)
  rescue ArgumentError, TypeError
    return generate_response('fail', nil, 'WRONG APLICATION ID', CLIENT_ERROR_CODE)
  end
  begin
    file_id = Integer(file_id)
  rescue ArgumentError, TypeError
    return generate_response('fail', nil, 'WRONG FILE ID', CLIENT_ERROR_CODE)
  end
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = Account.get_by_owner(id)
    if account.nil?
      generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      application = Application.get_by_id_and_author(application_id, account[:id])
      if application.nil?
        generate_response('fail', nil, 'APPLICATION DOES NOT EXIST', CLIENT_ERROR_CODE)
      else
        stored_file = StoredFile.get_by_id(file_id)
        if stored_file.nil?
          generate_response('fail', nil, 'FILE DOES NOT EXIST', CLIENT_ERROR_CODE)
        end
        StoredFile.delete_by_id(file_id)
        file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + account[:id].to_s + '/' + application[:id].to_s + '/' + file_id.to_s + stored_file[:extension]
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
delete URL + '/accounts/:token/applications/:application_id' do
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
    id = resp[:result][:id]
    account = Account.get_by_owner(id)
    if account.nil?
      generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      application = Application.get_by_id_and_author(application_id, account[:id])
      if application.nil?
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

# UpdateApplication
put URL + '/accounts/:token/applications/:application_id' do
  content_type :json
  token = params[:token]
  application_id = params[:application_id]
  application = params[:application]
  # application = {
  #     personal: {
  #         work: {
  #             activity: {
  #                 id: '1',
  #                 title: 'Активность 1',
  #                 type: 'hourly',
  #                 category: {
  #                     id: '1',
  #                     title: 'Sport'
  #                 },
  #                 price: 100
  #             },
  #             amount: 1, # null for permanent activity
  #         }
  #     },
  #     type: 'personal',
  #     group: nil,
  #     files: [],
  #     comment: 'Some other comment'
  # }
  if application.nil?
    return generate_response('fail', nil, 'APPLICATION PARAMETER IS NULL', CLIENT_ERROR_CODE)
  end
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    owner = resp[:result][:id]
    account = Account.get_by_owner(owner)
    if account.nil?
      generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      stored_application = Application.get_full_by_id_and_author(application_id, account[:id])
      if stored_application.nil?
        return generate_response('fail', nil, 'APPLICATION DOES NOT EXIST', CLIENT_ERROR_CODE)
      end
      case stored_application[:type]
        when 'personal'
          work = application[:personal][:work]
          if application[:personal].nil?
            return generate_response('fail',nil, 'FIELD \'personal\' can\'t be null', CLIENT_ERROR_CODE)
          end
          stored_work = Work.get_by_application_id_and_actor(application_id, account[:id])
          if stored_work.nil?
            return generate_response('fail',nil, 'INTERNAL ERROR', SERVER_ERROR_CODE)
          end
          to_work_update = Hash.new
          if work[:activity][:id] != stored_work[:activity_id]
            unless is_activity_correct(work[:activity][:id], work[:activity][:price])
              return generate_response('fail',nil, 'ERROR IN ACTIVITY', CLIENT_ERROR_CODE)
            end
            to_work_update[:activity_id] = work[:activity][:id]
          end
          if ((work[:activity][:type] == 'hourly' || work[:activity][:type] == 'quantity') && !(work[:amount] > 0)) || (work[:activity][:type] == 'permanent' && work[:amount].nil?)
            return generate_response('fail',nil, 'ERROR IN WORK', CLIENT_ERROR_CODE)
          end
          if work[:amount] != stored_work[:amount]
            to_work_update[:amount] = work[:amount]
          end
          if to_work_update.size > 0
            Work.update(stored_work[:id], to_work_update)
          end
        when 'group'
          if application[:group].nil?
            return generate_response('fail',nil, 'FIELD \'group\' can\'t be null', CLIENT_ERROR_CODE)
          end
          to_work_update = Hash.new
          application[:group][:work].each do |work|
            actor_account = Account.get_by_owner(work[:actor])
            stored_work = Work.get_by_application_id_and_actor(application_id, actor_account[:id])
            to_work_update[stored_work[:id]] = Hash.new
            if stored_work.nil?
              return generate_response('fail',nil, 'INTERNAL ERROR', SERVER_ERROR_CODE)
            end
            if work[:activity][:id] != stored_work[:activity_id]
              unless is_activity_correct(work[:activity][:id], work[:activity][:price])
                return generate_response('fail',nil, 'ERROR IN ACTIVITY', CLIENT_ERROR_CODE)
              end
              to_work_update[stored_work[:id]][:activity_id] = work[:activity][:id]
            end
            if ((work[:activity][:type] == 'hourly' || work[:activity][:type] == 'quantity') && !(work[:amount] > 0)) || (work[:activity][:type] == 'permanent' && work[:amount].nil?)
              return generate_response('fail',nil, 'ERROR IN WORK', CLIENT_ERROR_CODE)
            end
            if stored_work[:amount] != work[:amount]
              to_work_update[stored_work[:id]][:amount] = work[:amount]
            end
          end
          to_work_update.each do |work_id, work_hash|
            if work_hash.size > 0
              Work.update(work_id, work_hash)
            end
          end
      end
      if application[:comment] != stored_application[:comment]
        Application.update_comment(stored_application[:id], application[:comment])
      end
      #TODO Work with files
      folder = Dir.pwd + FILES_FOLDER + '/' + account[:id].to_s + '/' + stored_application[:id].to_s
      application[:files].each do |file|
        file_name = file[:filename]
        name_parts = file_name.split('.')
        extension = ''
        (1..(name_parts.length - 1)).each { |i|
          extension += ('.' + name_parts[i])
        }
        created_file = StoredFile.create(stored_application[:id],file[:filename], file[:type], extension)
        if created_file.nil?
          return generate_response('fail', nil, 'ERROR WHILE CREATING FILE OCCURED', SERVER_ERROR_CODE)
        end
        File.open(folder + '/' + created_file[:id].to_s + extension, 'w') do |f|
          f.write(file[:tempfile].read)
        end
        download_link = URL + '/accounts/' + token + '/applications/' + stored_application[:id] + '/files/' + created_file[:id].to_s + extension
        StoredFile.update_download_link(created_file[:id], download_link)
      end
      generate_response('ok', { id: stored_application[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# SendToApprove
put URL + '/accounts/:token/applications/:application_id/approve' do
  content_type :json
  token = params[:token]
  application_id = params[:application_id]
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    owner = resp[:result][:id]
    account = Account.get_by_owner(owner)
    if account.nil?
      generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      application = Application.get_full_by_id_and_author(application_id, account[:id])
      if application.nil?
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

#---------------------------- Adminstrators ------------------------------

# GetAccounts
get URL + '/admin/:admin_token/accounts' do
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
    generate_response('ok', accounts, nil, SUCCESSFUL_RESPONSE_CODE)
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetAccount
get URL + '/admin/:admin_token/accounts/:account_id' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = Account.get_by_owner_and_type(id, 'admin')
    if account.nil?
      return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      account_id = is_integer_valid(params[:account_id])
      if account_id.nil?
        return generate_response('fail', nil, 'WRONG ACCOUNT ID', CLIENT_ERROR_CODE)
      end
      target_account = Account.get_by_id(account_id)
      if target_account.nil?
        generate_response('fail', nil, 'TARGET USER DOES NOT EXIST', CLIENT_ERROR_CODE)
      else
        account_info = Account.to_info(target_account)
        generate_response('ok', account_info, nil, SUCCESSFUL_RESPONSE_CODE)
      end
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# UpdateAccount
put URL + '/admin/:admin_token/accounts/:account_id' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = Account.get_by_owner_and_type(id, 'admin')
    if account.nil?
      return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      account_id = is_integer_valid(params[:account_id])
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
          points_amount = is_integer_valid(params[:points_amount])
          if points_amount.nil?
            return generate_response('fail', nil, 'WRONG POINTS AMOUNT', CLIENT_ERROR_CODE)
          end
          Account.update_points_amount(target_account[:id], points_amount)
          generate_response('ok', { description: 'POINTS AMOUNT WAS UPDATED' }, nil, SUCCESSFUL_RESPONSE_CODE)
        end
      end
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetApplicationsInProcess
get URL + '/admin/:admin_token/applications/in_process' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  resp = is_token_valid(params[:admin_token])
  if resp[:status] == 'ok'
    owner_id = resp[:result][:id]
    account = Account.get_by_owner_and_type(owner_id, 'admin')
    if account.nil?
      generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      applications = Application.get_list_with_status('in_process', skip, limit)
      generate_response('ok', applications, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetApplicationsRejected
get URL + '/admin/:admin_token/applications/rejected' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  resp = is_token_valid(params[:admin_token])
  if resp[:status] == 'ok'
    owner_id = resp[:result][:id]
    account = Account.get_by_owner_and_type(owner_id, 'admin')
    if account.nil?
      generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      applications = Application.get_list_with_status('rejected', skip, limit)
      generate_response('ok', applications, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetApplicationsRework
get URL + '/admin/:admin_token/applications/rework' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  resp = is_token_valid(params[:admin_token])
  if resp[:status] == 'ok'
    owner_id = resp[:result][:id]
    account = Account.get_by_owner_and_type(owner_id, 'admin')
    if account.nil?
      generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      applications = Application.get_list_with_status('rework', skip, limit)
      generate_response('ok', applications, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetApplicationsApproved
get URL + '/admin/:admin_token/applications/approved' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  resp = is_token_valid(params[:admin_token])
  if resp[:status] == 'ok'
    owner_id = resp[:result][:id]
    account = Account.get_by_owner_and_type(owner_id, 'admin')
    if account.nil?
      generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      applications = Application.get_list_with_status('approved', skip, limit)
      generate_response('ok', applications, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# CreateApplication
post URL + '/admin/:admin_token/applications' do
  content_type :json
  token = params[:admin_token]
  resp = is_token_valid(token)
  application = params[:application]
  # application = {
  #     type: 'group', # personal/group
  #     group: {
  #         work: [
  #             {
  #                 actor: 1,
  #                 activity: {
  #                     id: '1',
  #                     title: 'Активность 1',
  #                     type: 'hourly',
  #                     category: {
  #                         id: 'some id',
  #                         title: 'Sport'
  #                     },
  #                     price: 100
  #                 },
  #                 amount: 2, # null for permanent actxivity
  #                 total_price: 200
  #             }
  #         ]
  #     },
  #     personal: nil,
  #     files: [
          # {
          #     filename: 'weather-1.jpg',
          #     tempfile: '#<Tempfile:/tmp/RackMultipart20160624-29189-m0ztz3.jpg>',
          #     type: 'image/jpeg',
          #     head: 'Content-Disposition: form-data; name=\"test_file\"; filename=\"weather-1.jpg\"\r\nContent-Type: image/jpeg\r\n"'
          # }
  #     ],
  #     comment: 'Some comment'
  # }
  # application = params[:application]
  if application.nil?
    return generate_response('fail', nil, 'APPLICATION PARAMETER IS NULL', CLIENT_ERROR_CODE)
  end
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = Account.get_by_owner_and_type(id, 'admin')
    if account.nil?
      generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
    else
      if application[:type] == 'personal'
        return generate_response('fail', nil, 'ADMIN CAN\'T CREATE PERSONAL APPLICATION', CLIENT_ERROR_CODE)
      end
      application[:group][:work].each do |work|
        activity_id = is_integer_valid(work[:activity][:id])
        if activity_id.nil?
          return generate_response('fail', nil, 'WRONG ACTIVITY ID', CLIENT_ERROR_CODE)
        end
        unless is_activity_correct(activity_id, work[:activity][:price])
          return generate_response('fail', nil, 'ERROR IN AN ACTIVITY', CLIENT_ERROR_CODE)
        end
      end
      works = application[:group][:work]
      created_application = Application.create(account[:id], application[:type], application[:comment])
      if created_application.nil?
        return generate_response('fail', nil, 'ERROR WHILE CREATING APPLICATION OCCURED', SERVER_ERROR_CODE)
      end
      works.each do |work|
        actor_account = Account.get_by_owner(work[:actor])
        if actor_account.nil?
          actor_account = Account.create(work[:actor], 'student')
        end
        created_work = Work.create(actor_account[:id], work[:activity][:id], created_application[:id], work[:amount])
        if created_work.nil?
          return generate_response('fail', nil, 'ERROR WHILE CREATING WORK OCCURED', SERVER_ERROR_CODE)
        end
      end
      folder = Dir.pwd + FILES_FOLDER + '/' + account[:id].to_s + '/' + created_application[:id].to_s
      FileUtils::mkdir_p(folder)
      application[:files].each do |file|
        file_name = file[:filename]
        name_parts = file_name.split('.')
        extension = ''
        (1..(name_parts.length - 1)).each { |i|
          extension += ('.' + name_parts[i])
        }
        created_file = StoredFile.create(created_application[:id],file[:filename], file[:type], extension)
        if created_file.nil?
          return generate_response('fail', nil, 'ERROR WHILE CREATING FILE OCCURED', SERVER_ERROR_CODE)
        end
        File.open(folder + '/' + created_file[:id].to_s + extension, 'w') do |f|
          f.write(file[:tempfile].read)
        end
        download_link = URL + '/accounts/' + token + '/applications/' + created_application[:id] + '/files/' + created_file[:id].to_s + extension
        StoredFile.update_download_link(created_file[:id], download_link)
      end
      generate_response('ok', { :id => created_application[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# GetApplication
get URL + '/admin/:admin_token/accounts/:account_id/applications/:application_id' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = Account.get_by_owner_and_type(id, 'admin')
    if account.nil?
      return generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
    end
    target_account_id = is_integer_valid(params[:account_id])
    if target_account_id.nil?
      return generate_response('fail', nil, 'WRONG TARGET ACCOUNT ID', CLIENT_ERROR_CODE)
    end
    application_id = is_integer_valid(params[:application_id])
    if application_id.nil?
      return generate_response('fail', nil, 'WRONG TARGET APPLICATION ID', CLIENT_ERROR_CODE)
    end
    application = Application.get_full_by_id_and_author(application_id, target_account_id)
    if application.nil?
      return generate_response('fail', nil, 'APPLICATION DOES NOT EXIST', CLIENT_ERROR_CODE)
    end
    generate_response('ok', application, nil, SUCCESSFUL_RESPONSE_CODE)
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

# UpdateApplicationStatus
put URL + '/admin/:admin_token/accounts/:account_id/applications/:application_id/:action' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = Account.get_by_owner_and_type(id, 'admin')
    if account.nil?
      return generate_response('fail', nil, 'ACCOUNT DOES NOT EXIST', CLIENT_ERROR_CODE)
    end
    target_account_id = is_integer_valid(params[:account_id])
    if target_account_id.nil?
      return generate_response('fail', nil, 'WRONG TARGET ACCOUNT ID', CLIENT_ERROR_CODE)
    end
    application_id = is_integer_valid(params[:application_id])
    if application_id.nil?
      return generate_response('fail', nil, 'WRONG TARGET APPLICATION ID', CLIENT_ERROR_CODE)
    end
    application = Application.get_by_id(application_id)
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
          puts '---------------'
          puts activity[:price]
          puts work[:actor]
          puts '---------------'
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
          Account.update_points_amount(acc_id, account[:points_amount] + points)
        end
        return generate_response('ok', { :id => application_id }, nil, SUCCESSFUL_RESPONSE_CODE)
      when 'to_rework'
        Application.update_status(application_id, 'rework')
        return generate_response('ok', { :id => application_id }, nil, SUCCESSFUL_RESPONSE_CODE)
      else
        return generate_response('fail', nil, 'WRONG ACTION', CLIENT_ERROR_CODE)
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

# UpdateApplication
put URL + '/admin/:admin_token/accounts/:account_id/applications/:application_id' do
  content_type :json
  token = params[:admin_token]
  account_id = params[:account_id]
  application_id = params[:application_id]
  application = params[:application]

  # application = {
  #     personal: {
  #         work: {
  #             activity: {
  #                 id: '1',
  #                 title: 'Активность 1',
  #                 type: 'hourly',
  #                 category: {
  #                     id: '1',
  #                     title: 'Sport'
  #                 },
  #                 price: 100
  #             },
  #             amount: 1, # null for permanent activity
  #         }
  #     },
  #     type: 'personal',
  #     group: nil,
  #     files: [],
  #     comment: 'Some other comment'
  # }
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
      stored_application = Application.get_full_by_id_and_author(application_id, account_id)
      if stored_application.nil?
        return generate_response('fail', nil, 'APPLICATION DOES NOT EXIST', CLIENT_ERROR_CODE)
      end
      case stored_application[:type]
        when 'personal'
          work = application[:personal][:work]
          if application[:personal].nil?
            return generate_response('fail',nil, 'FIELD \'personal\' can\'t be null', CLIENT_ERROR_CODE)
          end
          stored_work = Work.get_by_application_id_and_actor(application_id, account_id)
          if stored_work.nil?
            return generate_response('fail',nil, 'INTERNAL ERROR', SERVER_ERROR_CODE)
          end
          to_work_update = Hash.new
          if work[:activity][:id] != stored_work[:activity_id]
            unless is_activity_correct(work[:activity][:id], work[:activity][:price])
              return generate_response('fail',nil, 'ERROR IN ACTIVITY', CLIENT_ERROR_CODE)
            end
            to_work_update[:activity_id] = work[:activity][:id]
          end
          if ((work[:activity][:type] == 'hourly' || work[:activity][:type] == 'quantity') && !(work[:amount] > 0)) || (work[:activity][:type] == 'permanent' && work[:amount].nil?)
            return generate_response('fail',nil, 'ERROR IN WORK', CLIENT_ERROR_CODE)
          end
          if work[:amount] != stored_work[:amount]
            to_work_update[:amount] = work[:amount]
          end
          if to_work_update.size > 0
            Work.update(stored_work[:id], to_work_update)
          end
        when 'group'
          if application[:group].nil?
            return generate_response('fail',nil, 'FIELD \'group\' can\'t be null', CLIENT_ERROR_CODE)
          end
          to_work_update = Hash.new
          application[:group][:work].each do |work|
            actor_account = Account.get_by_owner(work[:actor])
            stored_work = Work.get_by_application_id_and_actor(application_id, actor_account[:id])
            to_work_update[stored_work[:id]] = Hash.new
            if stored_work.nil?
              return generate_response('fail',nil, 'INTERNAL ERROR', SERVER_ERROR_CODE)
            end
            if work[:activity][:id] != stored_work[:activity_id]
              unless is_activity_correct(work[:activity][:id], work[:activity][:price])
                return generate_response('fail',nil, 'ERROR IN ACTIVITY', CLIENT_ERROR_CODE)
              end
              to_work_update[stored_work[:id]][:activity_id] = work[:activity][:id]
            end
            if ((work[:activity][:type] == 'hourly' || work[:activity][:type] == 'quantity') && !(work[:amount] > 0)) || (work[:activity][:type] == 'permanent' && work[:amount].nil?)
              return generate_response('fail',nil, 'ERROR IN WORK', CLIENT_ERROR_CODE)
            end
            if stored_work[:amount] != work[:amount]
              to_work_update[stored_work[:id]][:amount] = work[:amount]
            end
          end
          to_work_update.each do |work_id, work_hash|
            if work_hash.size > 0
              Work.update(work_id, work_hash)
            end
          end
      end
      if application[:comment] != stored_application[:comment]
        Application.update_comment(stored_application[:id], application[:comment])
      end
      #TODO Work with files
      folder = Dir.pwd + FILES_FOLDER + '/' + account[:id].to_s + '/' + stored_application[:id].to_s
      application[:files].each do |file|
        file_name = file[:filename]
        name_parts = file_name.split('.')
        extension = ''
        (1..(name_parts.length - 1)).each { |i|
          extension += ('.' + name_parts[i])
        }
        created_file = StoredFile.create(stored_application[:id],file[:filename], file[:type], extension)
        if created_file.nil?
          return generate_response('fail', nil, 'ERROR WHILE CREATING FILE OCCURED', SERVER_ERROR_CODE)
        end
        File.open(folder + '/' + created_file[:id].to_s + extension, 'w') do |f|
          f.write(file[:tempfile].read)
        end
        download_link = URL + '/accounts/' + token + '/applications/' + stored_application[:id] + '/files/' + created_file[:id].to_s + extension
        StoredFile.update_download_link(created_file[:id], download_link)
      end
      generate_response('ok', { id: stored_application[:id] }, nil, SUCCESSFUL_RESPONSE_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# ------------------------ e-shop api ---------------------------

=begin
 GetItems
=end
get URL + '/shop/items' do
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
  items = ShopItem.get_list(skip, limit, fields_array, order)
  generate_response('ok', items, nil, SUCCESSFUL_RESPONSE_CODE)
end

# GetItemsInCategory
get URL + '/shop/items/category/:category_id' do
  content_type :json
  skip = validate_skip(params[:skip])
  limit =  validate_limit(params[:limit])
  fields = params[:fields]
  order = params[:order]
  category_id = is_integer_valid(params[:category_id])
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
  items = ShopItem.get_list_in_category(category_id, skip, limit, fields_array, order)
  generate_response('ok', items, nil, SUCCESSFUL_RESPONSE_CODE)
end

# GetItem
get URL + '/shop/items/:id' do
  content_type :json
  item_id = is_integer_valid(params[:id])
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

# CreateOrder
post URL + '/accounts/:token/orders' do
  content_type :json
  token = params[:token]
  resp = is_token_valid(token)
  order = params[:order]
  # order = {
  #     is_joint_purchase: false,
  #     items: [
  #         {
  #             id: 1,
  #             amount: 2
  #         },
  #         {
  #             id: 2,
  #             amount: 1
  #         }
  #     ],
  #     contributors: nil
  # }

  # order = {
  #     is_joint_purchase: true,
  #     items: [ # only 1 item
  #         {
  #             id: 5,
  #             amount: 1
  #         }
  #     ],
  #     contributors: [
  #         {
  #             id: 1, # uis id of author of order
  #             points_amount: 200
  #         },
  #         {
  #             id: 3, #uis id o some other person
  #             points_amount: 200
  #         }
  #     ]
  # }
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = Account.get_by_owner(id)
    if account.nil?
      return generate_response('fail', nil, 'USER DOES NOT EXIST', CLIENT_ERROR_CODE)
    end
    puts order
    if order[:is_joint_purchase].nil?
      puts '--------------------'
      puts 'wrong is_joint_purchase'
      puts '--------------------'
      return generate_response('fail', nil, 'WRONG FORMAT OF ORDER', CLIENT_ERROR_CODE)
    end
    if order[:is_joint_purchase] == true
      items = order[:items]
      if items.nil? || items.size != 1
        puts '--------------------'
        puts 'wrong items array'
        puts '--------------------'
        return generate_response('fail', nil, 'WRONG FORMAT OF ORDER', CLIENT_ERROR_CODE)
      end
      item_ids_hash = Hash.new
      item = items[0]
      item_id = is_integer_valid(item[:id])
      item_amount = is_integer_valid(item[:amount])
      if item_id.nil? || item_amount.nil? || item_id <= 0 || item_amount <= 0
        return generate_response('fail', nil, 'WRONG FORMAT OF ITEM', CLIENT_ERROR_CODE)
      end
      item_ids_hash[item_id] = item_amount
      result = ShopItem.check_quantity(item_ids_hash)
      stored_items = nil
      case result
        when 'WRONG ITEM'
          puts '------------------'
          puts 'Some item is missing'
          puts '------------------'
          return generate_response('fail', nil, 'WRONG ITEM IN ORDER', CLIENT_ERROR_CODE)
        when 'WRONG QUANTITY'
          puts '------------------'
          puts 'Too much for some item'
          puts '------------------'
          return generate_response('fail', nil, 'WRONG QUANTITY OF AN ITEM', CLIENT_ERROR_CODE)
        else
          stored_items = result
      end
      stored_item = stored_items[item_id]
      puts stored_item
      unless stored_item[:possible_joint_purchase]
        return generate_response('fail', nil, 'JOINT PURCHASE IS NOT POSSIBLE', CLIENT_ERROR_CODE)
      end
      contributors = order[:contributors]
      if contributors.nil? || contributors.size < 2 || contributors.size > stored_item[:max_buyers]
        return generate_response('fail', nil, 'WRONG CONTRIBUTORS FORMAT', CLIENT_ERROR_CODE)
      end
      author_found = false
      total_points = 0
      contributor_ids_hash = Hash.new
      contributors.each do |contributor|
        contributor_id = is_integer_valid(contributor[:id])
        contributor_points = is_integer_valid(contributor[:points_amount])
        if contributor_id == id
          author_found = true
        end
        if contributor_id.nil? || contributor_points.nil?
          return generate_response('fail', nil, 'WRONG IN CONTRIBUTOR', CLIENT_ERROR_CODE)
        end
        contributor_account = Account.get_by_owner(contributor_id)
        if contributor_account.nil?
          return generate_response('fail', nil, 'CONTRIBUTOR DOES NOT EXIST', CLIENT_ERROR_CODE)
        end
        if contributor_account[:type] == 'admin'
          return generate_response('fail', nil, 'WRONG CONTRIBUTOR', CLIENT_ERROR_CODE)
        end
        if contributor_account[:points_amount] < contributor_points
          return generate_response('fail', nil, 'WRONG CONTRIBUTOR POINTS AMOUNT', CLIENT_ERROR_CODE)
        end
        total_points += contributor_points
        contributor_ids_hash[contributor_account[:id]] = contributor_points
      end
      unless author_found
        return generate_response('fail', nil, 'AUTHOR IS NOT FOUND AMONG CONTRIBUTORS', CLIENT_ERROR_CODE)
      end
      created_order = Order.create(id, order[:is_joint_purchase], total_points)
      if created_order.nil?
        return generate_response('fail', nil, 'ERROR WHILE CREATING ORDER', SERVER_ERROR_CODE)
      end
      ItemInOrder.create(created_order[:id], item_id, item_amount)
      contributor_ids_hash.each do |acc_id, points|
        OrderContributor.create(created_order[:id], acc_id, points)
      end
      generate_response('ok', { id: created_order[:id] } ,nil, SUCCESSFUL_RESPONSE_CODE)
    elsif order[:is_joint_purchase] == false
      items = order[:items]
      if items.nil? || items.size == 0
        puts '--------------------'
        puts 'wrong items array'
        puts '--------------------'
        return generate_response('fail', nil, 'WRONG FORMAT OF ORDER', CLIENT_ERROR_CODE)
      end
      item_ids_hash = Hash.new
      items.each do |item|
        item_id = is_integer_valid(item[:id])
        item_amount = is_integer_valid(item[:amount])
        if item_id.nil? || item_amount.nil? || item_id <= 0 || item_amount <= 0
          return generate_response('fail', nil, 'WRONG FORMAT OF ITEMS', CLIENT_ERROR_CODE)
        end
        if item_ids_hash[item_id].nil?
          item_ids_hash[item_id] = item_amount
        else
          item_ids_hash[item_id] += item_amount
        end
      end
      result = ShopItem.check_quantity(item_ids_hash)
      stored_items = nil
      case result
        when 'WRONG ITEM'
          puts '------------------'
          puts 'Some item is missing'
          puts '------------------'
          return generate_response('fail', nil, 'WRONG ITEM IN ORDER', CLIENT_ERROR_CODE)
        when 'WRONG QUANTITY'
          puts '------------------'
          puts 'Too much for some item'
          puts '------------------'
          return generate_response('fail', nil, 'WRONG QUANTITY OF AN ITEM', CLIENT_ERROR_CODE)
        else
          stored_items = result
      end
      total_price = 0
      stored_items.each do |id, stored_item|
        total_price += stored_item[:price].to_i
      end
      if account[:points_amount] < total_price
        puts '---------------'
        puts 'account balance: ' + account[:points_amount].to_s
        puts 'total price: ' + total_price.to_s
        puts '---------------'
        return generate_response('fail', nil, 'USER DOES NOT HAVE ENOUGH POINTS', CLIENT_ERROR_CODE)
      end
      acc_points = account[:points_amount] - total_price
      created_order = Order.create(account[:id], order[:is_joint_purchase], total_price)
      if created_order.nil?
        return generate_response('fail', nil, 'ERROR WHILE CREATING THE ORDER', SERVER_ERROR_CODE)
      end
      item_ids_hash.each do |item_id, amount|
        ItemInOrder.create(created_order[:id], item_id, amount)
      end
      Account.update_points_amount(account[:id], acc_points)
      stored_items.each do |id, stored_item|
        in_stock = stored_item[:quantity] - item_ids_hash[id]
        ShopItem.update_quantity(stored_item[:id], in_stock)
      end
      generate_response('ok', { id: created_order[:id] } ,nil, SUCCESSFUL_RESPONSE_CODE)
    else
      return generate_response('fail', nil, 'WRONG FORMAT OF ORDER', CLIENT_ERROR_CODE)
    end
  else
    generate_response('fail', nil, 'ERROR IN ACCOUNTS MICROSERVICE', CLIENT_ERROR_CODE)
  end
end

# get URL + '/accounts/:token'