require 'sinatra'
require 'mongo'
require 'json'
require 'fileutils'
require 'httparty'
require_relative 'config'
set :public_folder => '/public'

helpers do
  def create_transaction(amount)
    date = Date.today >> 12
    date = Date.civil(date.year, date.month, -1)
    object = {
        id: BSON::ObjectId.from_time(Time.now).to_s,
        amount: amount,
        amount_to_spend: amount,
        receiving_date: Time.now,
        expiration_date: date,
        status: 'active'
    }
    return object
  end

  def get_bson_id(string)
    begin
      id = BSON::ObjectId(string)
    rescue BSON::ObjectId::Invalid
      nil
    end
  end

  def is_token_valid(token)
    # resp = HTTParty.get(ACCOUNTS_URL + token)
    resp = Hash.new
    if token == 'test'
      resp[:status] = 'ok'
      resp[:result] = Hash.new
      resp[:result][:id] = 1
    elsif token == 'admin'
      resp[:status] = 'ok'
      resp[:result] = Hash.new
      resp[:result][:id] = 2
    else
      resp[:status] = 'error'
    end

    resp
    # resp.body
  end

  def generate_response(status, result)
    resp = Hash.new
    resp[:status] = status
    resp[:result] = result
    resp.to_json
  end
end

configure do
  db = Mongo::Client.new([ "#{DB_HOST}:#{DB_PORT}" ], :database => DATABASE)
  set :database, db
end

=begin
GetActivities
Response:
  {
    "status": "ok",
    "result": [
        {
            "_id": "576e87479c0541471c395a97",
            "title": "Участие в соревновании",
            "type": "permanent",
            "category": {
                "_id": "576e87479c0541471c395a94",
                "title": "Спортивное направление"
            },
            "price": 100
        },
        {

        }
    ]
  }
=end
get URL + '/activities' do
  content_type :json
  skip = params[:skip]
  limit = params[:limit]
  begin
    skip = Integer(skip)
  rescue ArgumentError, TypeError
    skip = 0
  end
  if skip < 0
    skip = 0
  end
  begin
    limit = Integer(limit)
  rescue ArgumentError, TypeError
    limit = DEFAULT_LIMIT
  end
  if limit < 0
    limit = 0
  end
  activities = Array.new
  settings.database[:activities].find().skip(skip).limit(limit).each do |document|
    activity = document
    activity[:_id] = activity[:_id].to_s
    activity[:category][:_id] = activity[:category][:_id].to_s
    activities.push(activity)
  end
  generate_response('ok', activities)
end

=begin
GetActivitiesInCategory
Response:
{
    "status": "ok",
    "result": [
        {
            "_id": "576e87479c0541471c395a97",
            "title": "Участие в соревновании",
            "type": "permanent",
            "category": {
                "_id": "576e87479c0541471c395a94",
                "title": "Спортивное направление"
            },
            "price": 100
        },
        {

        }
    ]
  }
=end
get URL + '/activities/:category_id' do
  content_type :json
  skip = params[:skip]
  limit = params[:limit]
  begin
    skip = Integer(skip)
  rescue ArgumentError, TypeError
    skip = 0
  end
  if skip < 0
    skip = 0
  end
  begin
    limit = Integer(limit)
  rescue ArgumentError, TypeError
    limit = DEFAULT_LIMIT
  end
  if limit < 0
    limit = 0
  end
  activities = Array.new
  category_bson_id = get_bson_id(params[:category_id])
  if category_bson_id.nil?
    return generate_response('error', { decriprion: 'WRONG CATEGORY ID' })
  end
  settings.database[:activities].find({'category._id' => category_bson_id}).skip(skip).limit(limit).each do |document|
    activity = document
    activity[:_id] = activity[:_id].to_s
    activity[:category][:_id] = activity[:category][:_id].to_s
    activities.push(activity)
  end
  generate_response('ok', activities)
end

=begin
GetCategories
Response:
{
  "status": "ok",
  "result": [
        {
            "_id": "576e87479c0541471c395a94",
            "title": "Спортивное направление"
        },
        {

        }
  ]
}
=end
get URL + '/categories' do
  content_type :json
  skip = params[:skip]
  limit = params[:limit]
  begin
    skip = Integer(skip)
  rescue ArgumentError, TypeError
    skip = 0
  end
  if skip < 0
    skip = 0
  end
  begin
    limit = Integer(limit)
  rescue ArgumentError, TypeError
    limit = DEFAULT_LIMIT
  end
  if limit < 0
    limit = 0
  end
  categories = Array.new
  settings.database[:categories].find().skip(skip).limit(limit).each do |document|
    category = document
    category[:_id] = category[:_id].to_s
    categories.push(category)
  end
  generate_response('ok', categories)
end

=begin
GetAccount
Response:
{
    "status": "ok",
    "result": {
        "owner": 1, // user id in accounts microservice
        "type": "student", // Or 'admin'. In this case field 'points_amount' is absent.
        "points_amount": 1700
    }
}
=end
get URL + '/accounts/:token' do
  content_type :json
  token = params[:token]
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      settings.database[:administrators].find(:user => id).each do |document|
        account = document
        break
      end
      if account.nil?
        generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
      else
        generate_response('ok', { :owner => id, :type => 'admin' })
      end
    else
      generate_response('ok', { :owner => id, :type => 'student' , :points_amount => account[:points_amount] })
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
CreateAccount
{
  result: {
    owner: id // id of user account in uis system
    points_amount: 0
  },
  status: 'ok'
}
=end
post URL + '/accounts/:token' do
  content_type :json
  token = params[:token]
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      res = settings.database[:accounts].insert_one({ :owner => id, :points_amount => 0, :creation_date => DateTime.now, :transactions => [], :applications => [], :orders => [] })
      if res.n == 1
        settings.database[:accounts].find(:owner => id).each do |document|
          account = document
          break
        end
        FileUtils::mkdir_p(Dir.pwd + FILES_FOLDER + '/' + account[:_id])
        generate_response('ok', { :owner => id, :points_amount => 0 })
      else
        generate_response('error', { :description => 'INTERNAL ERROR' })
      end
    else
      generate_response('error', { :description => 'ACCOUNT ALREADY EXISTS' })
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end
=begin
CreateApplication
Body parameters:
{
  application: {
    type: 'personal', // Can be only group or personal.
    // Fields personal and group depends on type of application.
    // If type = 'personal' then 'group' field equals null
    // If type = 'group' then 'personal' field equals null
    personal: {
      work: {
        activity: {
            _id: '576a9dcc9c05411ca409cc88',
            title: 'Волонтер мероприятия',
            type: 'hourly',
            category: {
                _id: '576a9dcc9c05411ca213112',
                title: 'Волонтерство'
            },
            price: 100
        },
        amount: 3, # null for permanent activities
        total_price: 300
      }
    },
    group: {
      work: [
        {
          // The same as for personal
        },
        {
          ...
        }
      ]
    },
    files: [  // Empty or contains files
      {
        filename: 'weather-1.jpg',
        tempfile: '#<Tempfile:/tmp/RackMultipart20160624-29189-m0ztz3.jpg>',
        type: 'image/jpeg',
        head: 'Content-Disposition: form-data; name=\"test_file\"; filename=\"weather-1.jpg\"\r\nContent-Type: image/jpeg\r\n"'
      }
    ],
    comment: ''
  }
}


=end
post URL + '/accounts/:token/applications' do
  content_type :json
  token = params[:token]
  resp = is_token_valid(token)
  application = {
      type: 'personal', # personal/group
      personal: {
          work: {
              activity: {
                  _id: '576e87479c0541471c395a97',
                  title: 'hui',
                  type: 'permanent',
                  category: {
                      _id: 'some id',
                      title: 'Sport'
                  },
                  price: 100
              },
              amount: nil, # null for permanent actxivity
          }
      },
      group: nil,
      files: [
          # {
          #     filename: 'weather-1.jpg',
          #     tempfile: '#<Tempfile:/tmp/RackMultipart20160624-29189-m0ztz3.jpg>',
          #     type: 'image/jpeg',
          #     head: 'Content-Disposition: form-data; name=\"test_file\"; filename=\"weather-1.jpg\"\r\nContent-Type: image/jpeg\r\n"'
          # }
      ],
      comment: 'Some comment'
  }
  # application = params[:application]
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      #Todo rework to dynamic
      case application[:type]
        when 'personal'
          activity = application[:personal][:work][:activity]
          actual_activity = nil
          settings.database[:activities].find(:_id => BSON::ObjectId(activity[:_id])).each do |document|
            actual_activity = document
          end
          if actual_activity.nil? || actual_activity[:price] != activity[:price]
            return generate_response('error', { :description => 'ERROR IN ACTIVITY' })
          end
        when 'group'
          application[:group][:work].each do |work|
            activity = work[:activity]
            actual_activity = nil
            settings.database[:activities].find(:_id => BSON::ObjectId(activity[:_id])).each do |document|
              actual_activity = document
            end
            if actual_activity.nil? || actual_activity[:price] != activity[:price]
              return generate_response('error', { :description => 'ERROR IN ACTIVITY' })
            end
          end
      end
      application[:author] = id
      application[:creation_date] = Time.now
      application[:status] = 'in_process'
      application_id = BSON::ObjectId.from_time(application[:creation_date])
      application[:_id] = application_id
      account[:applications].push(application)
      folder = Dir.pwd + FILES_FOLDER + '/' + account[:_id] + '/' +application[:_id]
      FileUtils::mkdir_p(folder)
      application[:files].each do |file|
        file_name = file[:filename]
        name_parts = file_name.split('.')
        extension = ''
        (1..(name_parts.length - 1)).each { |i|
          extension += ('.' + name_parts[i])
        }
        file_id = BSON::ObjectId.from_time(Time.now)
        file[:_id] = file_id.to_s + extension
        File.open(folder + '/' + file_id + extension, 'w') do |f|
          f.write(file[:tempfile].read)
        end
        file.delete(:tempfile)
        file.delete(:name)
        file.delete(:head)
        download_link = URL + '/accounts/' + token + '/applications/' + application[:_id] + '/files/' + file[:_id]
        file[:download_link] = download_link
      end
      result = settings.database[:accounts].update_one({:owner => id}, {'$set' => {applications: account[:applications]}})
      if result.n == 1
        settings.database[:applications_in_work].insert_one({:author => application[:author], :application_id => application_id.to_s, :status => 'in_process'})
        generate_response('ok', { :_id => application_id.to_s })
      else
        generate_response('error', { :description => 'INTERNAL ERROR' })
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
GetUserApplications
Response:
{
  result: [
    {
      _id: 1, // id of application
      author: 1 // id of user in accounts microservice
      type: 'personal',
      status: 'in_process',
      creation_date: '2016-06-24 11:03:01 UTC'
    },
    {
      ...
    }
  ],
  status: 'ok'
}
=end
get URL + '/accounts/:token/applications' do
  content_type :json
  token = params[:token]
  skip = params[:skip]
  limit = params[:limit]
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      applications = Array.new
      begin
        skip = Integer(skip)
      rescue ArgumentError, TypeError
        skip = 0
      end
      if skip < 0
        skip = 0
      end
      begin
        limit = Integer(limit)
      rescue ArgumentError, TypeError
        limit = DEFAULT_LIMIT
      end
      if limit < 0
        limit = -1
      end
      counter = 0
      for i in skip..account[:applications].length - 1
        if counter == limit
          break
        end
        application = account[:applications][i]
        applications.push({
            _id: application[:_id].to_s,
            author: application[:author],
            type: application[:type],
            status: application[:status],
            creation_date: application[:creation_date]
                          })
        counter += 1
      end
      generate_response('ok', applications)
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end
=begin
# Get user applications with status in process
Response:
{
  result: [
    {
      _id: 1, // id of application
      author: 1 // id of user in accounts microservice
      type: 'personal',
      status: 'in_process',
      creation_date: '2016-06-24 11:03:01 UTC'
    },
    {
      ...
    }
  ],
  status: 'ok'
}
=end
get URL + '/accounts/:token/applications/in_process' do
  content_type :json
  token = params[:token]
  skip = params[:skip]
  limit = params[:limit]
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      applications = Array.new
      begin
        skip = Integer(skip)
      rescue ArgumentError, TypeError
        skip = 0
      end
      if skip < 0
        skip = 0
      end
      begin
        limit = Integer(limit)
      rescue ArgumentError, TypeError
        limit = DEFAULT_LIMIT
      end
      if limit < 0
        limit = -1
      end
      counter = 0
      for i in skip..account[:applications].length - 1
        if counter == limit
          break
        end
        application = account[:applications][i]
        if application[:status] == 'in_process'
          applications.push({
                                _id: application[:_id].to_s,
                                author: application[:author],
                                type: application[:type],
                                status: application[:status],
                                creation_date: application[:creation_date]
                            })
          counter += 1
        end
      end
      generate_response('ok', applications )
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end
=begin
# Get user applications with status rework
Response:
{
  result: [
    {
      _id: 1, // id of application
      author: 1 // id of user in accounts microservice
      type: 'personal',
      status: 'rework',
      creation_date: '2016-06-24 11:03:01 UTC'
    },
    {
      ...
    }
  ],
  status: 'ok'
}
=end
get URL + '/accounts/:token/applications/rework' do
  content_type :json
  token = params[:token]
  resp = is_token_valid(token)
  skip = params[:skip]
  limit = params[:limit]
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      applications = Array.new
      begin
        skip = Integer(skip)
      rescue ArgumentError, TypeError
        skip = 0
      end
      if skip < 0
        skip = 0
      end
      begin
        limit = Integer(limit)
      rescue ArgumentError, TypeError
        limit = DEFAULT_LIMIT
      end
      if limit < 0
        limit = -1
      end
      counter = 0
      for i in skip..account[:applications].length - 1
        if counter == limit
          break
        end
        application = account[:applications][i]
        if application[:status] == 'rework'
          applications.push({
                                _id: application[:_id].to_s,
                                author: application[:author],
                                type: application[:type],
                                status: application[:status],
                                creation_date: application[:creation_date]
                            })
          counter += 1
        end
      end
      generate_response('ok', applications )
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
Get user applications with status approved
Response:
{
  result: [
    {
      _id: 1, // id of application
      author: 1 // id of user in accounts microservice
      type: 'personal',
      status: 'approved',
      creation_date: '2016-06-24 11:03:01 UTC'
    },
    {
      ...
    }
  ],
  status: 'ok'
}
=end
get URL + '/accounts/:token/applications/approved' do
  content_type :json
  token = params[:token]
  skip = params[:skip]
  limit = params[:limit]
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      applications = Array.new
      begin
        skip = Integer(skip)
      rescue ArgumentError, TypeError
        skip = 0
      end
      if skip < 0
        skip = 0
      end
      begin
        limit = Integer(limit)
      rescue ArgumentError, TypeError
        limit = DEFAULT_LIMIT
      end
      if limit < 0
        limit = -1
      end
      counter = 0
      for i in skip..account[:applications].length - 1
        if counter == limit
          break
        end
        application = account[:applications][i]
        if application[:status] == 'approved'
          applications.push({
                                _id: application[:_id].to_s,
                                author: application[:author],
                                type: application[:type],
                                status: application[:status],
                                creation_date: application[:creation_date]
                            })
          counter += 1
        end
      end
      generate_response('ok', applications )
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
Get user applications with status rejected
Response:
{
  result: [
    {
      _id: 1, // id of application
      author: 1 // id of user in accounts microservice
      type: 'personal',
      status: 'rejected',
      creation_date: '2016-06-24 11:03:01 UTC'
    },
    {
      ...
    }
  ],
  status: 'ok'
}
=end
get URL + '/accounts/:token/applications/rejected' do
  content_type :json
  skip = params[:skip]
  limit = params[:limit]
  token = params[:token]
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      applications = Array.new
      begin
        skip = Integer(skip)
      rescue ArgumentError, TypeError
        skip = 0
      end
      if skip < 0
        skip = 0
      end
      begin
        limit = Integer(limit)
      rescue ArgumentError, TypeError
        limit = DEFAULT_LIMIT
      end
      if limit < 0
        limit = -1
      end
      counter = 0
      for i in skip..account[:applications].length - 1
        if counter == limit
          break
        end
        application = account[:applications][i]
        if application[:status] == 'rejected '
          applications.push({
                                _id: application[:_id].to_s,
                                author: application[:author],
                                type: application[:type],
                                status: application[:status],
                                creation_date: application[:creation_date]
                            })
          counter += 1
        end
      end
      generate_response('ok', applications )
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
Get particular user application
{
  result: {
    "status": "ok",
    "result": {
        "type": "personal",
        "personal": {
            "work": {
                "activity": {
                    "_id": "576a9dcc9c05411ca409cc88",
                    "title": "hui",
                    "type": "permanent",
                    "category": {
                        "_id": "some id",
                        "title": "Sport"
                    },
                    "price": 100
                },
                "amount": null,
                "total_price": 100
            }
        },
        "group": null,
        "files": [
            {
                "filename": "weather-1.jpg",
                "type": "image/jpeg",
                "_id": "576d13650000000000000000.jpg",
                "download_link": "/points/api/v1/accounts/test/applications/576d13650000000000000000/files/576d13650000000000000000.jpg"
            }
        ],
        "comment": "Some comment",
        "creation_date": "2016-06-24 11:03:01 UTC",
        "status": "in_process",
        "_id": "576d13650000000000000000"
    }
  }
}
=end
get URL + '/accounts/:token/applications/:application_id' do
  content_type :json
  token = params[:token]
  application_id = params[:application_id]
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      application = nil
      account[:applications].each do |app|
        if app[:_id] == BSON::ObjectId(application_id)
          application = app
        end
      end
      if application.nil?
        generate_response('error', { :description => 'APPLICATION DOES NOT EXIST' })
      else
        application[:_id] = application[:_id].to_s
        generate_response('ok', application)
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
# Get file
Link to download file
=end
get URL + '/accounts/:account_id/applications/:application_id/files/:file_id' do
  content_type :json
  id = params[:account_id]
  application_id = params[:application_id]
  account = nil
  settings.database[:administrators].find(:user => id).each do |document|
    account = document
    break
  end
  if account.nil?
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      return generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
  end
    application = nil
    account[:applications].each do |app|
      if app[:_id] == BSON::ObjectId(application_id)
        application = app
      end
    end
    if application.nil?
      generate_response('error', { :description => 'APPLICATION DOES NOT EXIST' })
    else
      file = nil
      application[:files].each do |f|
        if f[:_id] == params[:file_id]
          file = f
        end
      end
      if file.nil?
        generate_response('error', { :description => 'FILE DOES NOT EXIST' })
      else
        file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + account[:_id] + '/' + application[:_id] + '/' + params[:file_id]
        if File.exists?(file_url)
          send_file file_url, :filename => file[:filename], :type => 'Application/octet-stream'
        else
          generate_response('error', { :description => 'FILE DOES NOT EXIST ON SERVER' })
        end
      end
    end
  end
end
=begin
Delete user application
Response
{
  status: 'ok',
  result: {
    description: 'Application was deleted'
  }
}
=end
delete URL + '/accounts/:token/applications/:application_id' do
  content_type :json
  token = params[:token]
  application_id = params[:application_id]
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      application = nil
      account[:applications].each do |app|
        if app[:_id] == BSON::ObjectId(application_id) && (app[:status] == 'in_process'  || app[:status] == 'rework')
          application = account[:applications].delete(app)
        end
      end
      if application.nil?
        generate_response('error', { :description => 'APPLICATION DOES NOT EXIST OR IT IS NOT POSSIBLE TO DELETE' })
      else
        settings.database[:accounts].update_one({owner: id}, {'$set' => {applications: account[:applications]}})
        if application[:status] == 'in_process' || application[:status] == 'rework'
          settings.database[:applications_in_work].find(application_id: application[:_id].to_s).each do |item|
            item.remove
          end
        elsif application[:status] == 'rejected'
          settings.database[:applications_archive].find(application_id: application[:_id].to_s).each do |item|
            item.remove
          end
        end
        generate_response('ok', { :description => 'APPLICATION WAS DELETED' })
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
Update application. It is not possible to update type of application.
Body parameters:
{
      personal: {
          work: {
              activity: {
                  _id: '576a9dcc9c05411ca409cc88',
                  title: 'Волонтер мероприятия',
                  type: 'permanent',
                  category: {
                    _id: 'some id',
                    title: 'Волонтерство'
                  },
                  price: 100
              },
              amount: 4, # null for permanent activity
              total_price: 400
          }
      },
      group: nil,
      files: [
          {
              filename: 'newfile.jpg',
              tempfile: '#<Tempfile:/tmp/RackMultipart20160624-29189-m0ztz3.jpg>',
              type: 'image/jpeg',
              head: 'Content-Disposition: form-data; name=\"test_file\"; filename=\"weather-1.jpg\"\r\nContent-Type: image/jpeg\r\n"'
          }
      ],
      comment: 'Some new comment'
  }
}
Response:

{
  result: {
    _id: 123 // Application id
  },
  status: 'ok'
}
=end
put URL + '/accounts/:token/applications/:application_id' do
  content_type :json
  token = params[:token]
  application_id = params[:application_id]
  application = {
      personal: {
          work: {
              activity: {
                  _id: '576e87479c0541471c395a98',
                  title: 'Первое место в соревновании',
                  type: 'permanent',
                  category: {
                    _id: 'some id',
                    title: 'Sport'
                  },
                  price: 300
              },
              amount: nil, # null for permanent activity
          }
      },
      group: nil,
      files: [],
      comment: 'Some comment'
  }
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      app = nil
      account[:applications].each do |item|
        if item[:_id] == BSON::ObjectId(application_id)
          app = item
          break
        end
      end
      if app.nil?
        generate_response('error', { :description => 'APPLICATION DOES NOT EXIST' })
      else
        case app[:type]
          when 'personal'
            activity = application[:personal][:work][:activity]
            actual_activity = nil
            settings.database[:activities].find(:_id => BSON::ObjectId(activity[:_id])).each do |document|
              actual_activity = document
            end
            if actual_activity.nil? || actual_activity[:price] != activity[:price]
              return generate_response('error', { :description => 'ERROR IN ACTIVITY' })
            end
            app[:personal] = application[:personal]
          when 'group'
            application[:group][:work].each do |work|
              activity = work[:activity]
              actual_activity = nil
              settings.database[:activities].find(:_id => BSON::ObjectId(activity[:_id])).each do |document|
                actual_activity = document
              end
              if actual_activity.nil? || actual_activity[:price] != activity[:price]
                return generate_response('error', { :description => 'ERROR IN ACTIVITY' })
              end
            end
            app[:group] = application[:group]
        end
        app[:comment] = application[:comment]
        existed_files = Array.new
        new_files = Array.new
        application[:files].each do |f|
          if f[:_id].nil?
            new_files.push(f)
          else
            existed_files.push(f)
          end
        end
        if existed_files.length != app[:files].length
          app[:files].each do |file_in_db|
            found = false
            existed_files.each do |existed_file|
              if file_in_db[:_id].to_s == existed_file[:_id]
                found = true
                break
              end
            end
            unless found
              app[:files].delete(file_in_db)
              file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + account[:_id] + '/' + application[:_id] + '/' + file_in_db[:_id]
              if File.exists?(file_url)
                File.delete(file_url)
              end
            end
          end
        end
        new_files.each do |file|
          file_name = file[:filename]
          name_parts = file_name.split('.')
          extension = ''
          (1..(name_parts.length - 1)).each { |i|
            extension += ('.' + name_parts[i])
          }
          file_id = BSON::ObjectId.from_time(Time.now)
          file[:_id] = file_id.to_s + extension
          file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + account[:_id] + '/' + application[:_id] + '/' + file[:_id]
          File.open(file_url) do |f|
            f.write(file[:tempfile].read)
          end
          file.delete(:tempfile)
          file.delete(:name)
          file.delete(:head)
          download_link = URL + '/accounts/' + account[:_id] + '/applications/' + application[:_id] + '/files/' + file[:_id]
          file[:download_link] = download_link
          app[:files].push(file)
        end
        result = settings.database[:accounts].update_one({owner: id}, {'$set' => {applications: account[:applications]}})
        if result.n == 1
          generate_response('ok', { _id: app[:_id].to_s })
        else
          generate_response('error', { :description => 'INTERNAL ERROR' })
        end
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end


=begin
SendForApproval
{
  status: 'ok',
  result: {
    description: 'APPLICATION IS SENT TO APPROVAL'
  }
}
=end
put URL + '/accounts/:token/applications/:application_id/approve' do
  content_type :json
  token = params[:token]
  application_id = params[:application_id]
  resp = is_token_valid(token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:accounts].find(:owner => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      application = nil
      account[:applications].each do |app|
        if app[:_id] == BSON::ObjectId(application_id)
          application = app
        end
      end
      if application.nil?
        generate_response('error', { :description => 'APPLICATION DOES NOT EXIST' })
      else
        if application[:status] != 'rework'
          return generate_response('error', { :description => 'IT IS NOT POSSIBLE TO SEND TO APPROVE THE APPLICATION' })
        end
        application[:status] = 'in_process'
        settings.database[:accounts].update_one({:owner => account[:owner]}, {'$set' => {:applications => account[:applications]}})
        settings.database[:applications_in_work].update_one({application_id: application[:_id].to_s}, {'$set' => {status: 'in_process'}})
        generate_response('ok', { :description => 'APPLICATIONS IS SENT FOR APPROVAL' })
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end
#---------------------- Administrator API ---------------------------

=begin
GetAccounts
Response:
{
  result: [
    {
      _id: 123,
      owner: 12, // user id in accounts microservice
      points_amount: 100
    },
    {
      ...
    }
  ],
  status: 'ok'
}
=end
get URL + '/admin/:admin_token/accounts' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  skip = params[:skip]
  limit = params[:limit]
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:administrators].find(:user => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'WRONG USER' })
    else
      accounts = Array.new
      begin
        skip = Integer(skip)
      rescue ArgumentError, TypeError
        skip = 0
      end
      if skip < 0
        skip = 0
      end
      begin
        limit = Integer(limit)
      rescue ArgumentError, TypeError
        limit = 0
      end
      if limit < 0
        limit = 0
      end
      settings.database[:accounts].find().skip(skip).limit(limit).each do |document|
        accounts.push({_id: document[:_id].to_s ,:owner => document[:owner], :points_amount => document[:points_amount]})
      end
      generate_response('ok', accounts)
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
GetAccount
Response:
{
  result: {
    _id: 23,
    owner: 12, // user id in accounts microservice
    points_amount: 100
  },
  status: 'ok'
}
=end
get URL + '/admin/:admin_token/accounts/:account_id' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:administrators].find(:user => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'WRONG USER' })
    else
      target_account = nil
      settings.database[:accounts].find(:_id => BSON::ObjectId(params[:account_id])).each do |document|
        target_account = document
        break
      end
      if target_account.nil?
        generate_response('error', { :description => 'TARGET USER DOES NOT EXIST' })
      else
        result = Hash.new
        result[:_id] = target_account[:_id].to_s
        result[:owner] = target_account[:owner]
        result[:points_amount] = target_account[:points_amount]
        generate_response('ok', result)
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
UpdateAccount
Body parameters:
{
  points_amount: 200 // new points amount
}
Response
{
  result: {
    description: 'POINTS AMOUNT WAS UPDATED'
  },
  status: 'ok'
}
=end
put URL + '/admin/:admin_token/accounts/:account_id' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:administrators].find(:user => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'WRONG USER' })
    else
      result = settings.database[:accounts].update_one({:_id => BSON::ObjectId(params[:account_id])}, {'$set' => {:points_amount => params[:points_amount]}})
      if result.n == 1
        generate_response('ok', { :description => 'POINTS AMOUNT WAS UPDATED' })
      else
        generate_response('error', { :description => 'INTERNAL ERROR' })
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
GetApplicationsInProcess
Response:
{
    "status": "ok",
    "result": [
        {
            "_id": "577f604d0000000000000000",
            "author": {
                "id": "5777b5cb9c054113671c1d1d",
                "uis_id": 1
            },
            "type": "personal",
            "status": "in_process",
            "creation_date": "2016-07-08 08:11:57 UTC"
        },
        {

        }
    ]
}
=end
get URL + '/admin/:admin_token/applications/in_process' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  skip = params[:skip]
  limit = params[:limit]
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:administrators].find(:user => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'WRONG USER' })
    else
      begin
        skip = Integer(skip)
      rescue ArgumentError, TypeError
        skip = 0
      end
      if skip < 0
        skip = 0
      end
      begin
        limit = Integer(limit)
      rescue ArgumentError, TypeError
        limit = DEFAULT_LIMIT
      end
      if limit < 0
        limit = 0
      end
      owner_to_applications = Hash.new
      settings.database[:applications_in_work].find(status: 'in_process').skip(skip).limit(limit).each do |document|
        if owner_to_applications.key?(document[:author])
          owner_to_applications[document[:author]].push(document[:application_id])
        else
          owner_to_applications[document[:author]] = Array.new
          owner_to_applications[document[:author]].push(document[:application_id])
        end
      end
      applications = Array.new
      owner_to_applications.each do |key, value|
        settings.database[:accounts].find(:owner => key).each do |document|
          document[:applications].each do |application|
            if value.include?(application[:_id].to_s)
              applications.push({
                                    _id: application[:_id].to_s,
                                    author: {
                                        id: document[:_id].to_s,
                                        uis_id: document[:owner]
                                    },
                                    type: application[:type],
                                    status: application[:status],
                                    creation_date: application[:creation_date]
                                })
            end
          end
        end
      end
      generate_response('ok',  applications)
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
GetApplicationsRework
Response:
{
    "status": "ok",
    "result": [
        {
            "_id": "577f604d0000000000000000",
            "author": {
                "id": "5777b5cb9c054113671c1d1d",
                "uis_id": 1
            },
            "type": "personal",
            "status": "rework",
            "creation_date": "2016-07-08 08:11:57 UTC"
        },
        {

        }
    ]
}
=end
get URL + '/admin/:admin_token/applications/rework' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  skip = params[:skip]
  limit = params[:limit]
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:administrators].find(:user => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'WRONG USER' })
    else
      begin
        skip = Integer(skip)
      rescue ArgumentError, TypeError
        skip = 0
      end
      if skip < 0
        skip = 0
      end
      begin
        limit = Integer(limit)
      rescue ArgumentError, TypeError
        limit = DEFAULT_LIMIT
      end
      if limit < 0
        limit = 0
      end
      owner_to_applications = Hash.new
      settings.database[:applications_in_work].find(status: 'rework').skip(skip).limit(limit).each do |document|
        if owner_to_applications.key?(document[:author])
          owner_to_applications[document[:author]].push(document[:application_id])
        else
          owner_to_applications[document[:author]] = Array.new
          owner_to_applications[document[:author]].push(document[:application_id])
        end
      end
      applications = Array.new
      owner_to_applications.each do |key, value|
        settings.database[:accounts].find(:owner => key).each do |document|
          document[:applications].each do |application|
            if value.include?(application[:_id].to_s)
              applications.push({
                                    _id: application[:_id].to_s,
                                    author: application[:author],
                                    type: application[:type],
                                    status: application[:status],
                                    creation_date: application[:creation_date]
                                })
            end
          end
        end
      end
      generate_response('ok',  applications)
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
GetApplicationsApproved
Response:
{
    "status": "ok",
    "result": [
        {
            "_id": "577f604d0000000000000000",
            "author": {
                "id": "5777b5cb9c054113671c1d1d",
                "uis_id": 1
            },
            "type": "personal",
            "status": "approved",
            "creation_date": "2016-07-08 08:11:57 UTC"
        },
        {

        }
    ]
}
=end
get URL + '/admin/:admin_token/applications/approved' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  skip = params[:skip]
  limit = params[:limit]
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:administrators].find(:user => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'WRONG USER' })
    else
      begin
        skip = Integer(skip)
      rescue ArgumentError, TypeError
        skip = 0
      end
      if skip < 0
        skip = 0
      end
      begin
        limit = Integer(limit)
      rescue ArgumentError, TypeError
        limit = DEFAULT_LIMIT
      end
      if limit < 0
        limit = 0
      end
      owner_to_applications = Hash.new
      settings.database[:applications_archive].find(status: 'approved').skip(skip).limit(limit).each do |document|
        if owner_to_applications.key?(document[:author])
          owner_to_applications[document[:author]].push(document[:application_id])
        else
          owner_to_applications[document[:author]] = Array.new
          owner_to_applications[document[:author]].push(document[:application_id])
        end
      end
      applications = Array.new
      owner_to_applications.each do |key, value|
        settings.database[:accounts].find(:owner => key).each do |document|
          document[:applications].each do |application|
            if value.include?(application[:_id].to_s)
              applications.push({
                                    _id: application[:_id].to_s,
                                    author: {
                                        id: document[:_id].to_s,
                                        uis_id: document[:owner]
                                    },
                                    type: application[:type],
                                    status: application[:status],
                                    creation_date: application[:creation_date]
                                })
            end
          end
        end
      end
      generate_response('ok',  applications)
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
GetApplicationsRejected
Response:
{
    "status": "ok",
    "result": [
        {
            "_id": "577f604d0000000000000000",
            "author": {
                "id": "5777b5cb9c054113671c1d1d",
                "uis_id": 1
            },
            "type": "personal",
            "status": "rejected",
            "creation_date": "2016-07-08 08:11:57 UTC"
        },
        {

        }
    ]
}
=end
get URL + '/admin/:admin_token/applications/rejected' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  skip = params[:skip]
  limit = params[:limit]
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:administrators].find(:user => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'WRONG USER' })
    else
      begin
        skip = Integer(skip)
      rescue ArgumentError, TypeError
        skip = 0
      end
      if skip < 0
        skip = 0
      end
      begin
        limit = Integer(limit)
      rescue ArgumentError, TypeError
        limit = DEFAULT_LIMIT
      end
      if limit < 0
        limit = 0
      end
      owner_to_applications = Hash.new
      settings.database[:applications_archive].find(status: 'rejected').skip(skip).limit(limit).each do |document|
        if owner_to_applications.key?(document[:author])
          owner_to_applications[document[:author]].push(document[:application_id])
        else
          owner_to_applications[document[:author]] = Array.new
          owner_to_applications[document[:author]].push(document[:application_id])
        end
      end
      applications = Array.new
      owner_to_applications.each do |key, value|
        settings.database[:accounts].find(:owner => key).each do |document|
          document[:applications].each do |application|
            if value.include?(application[:_id].to_s)
              applications.push({
                                    _id: application[:_id].to_s,
                                    author: {
                                        id: document[:_id].to_s,
                                        uis_id: document[:owner]
                                    },
                                    type: application[:type],
                                    status: application[:status],
                                    creation_date: application[:creation_date]
                                })
            end
          end
        end
      end
      generate_response('ok',  applications)
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
CreateApplication
Body parameters:
{
  application: {
    type: 'group', // Can be only group for administrators.
    // If type = 'group' then 'personal' field equals null
    personal: null,
    group: {
      work: [
        {
          // The same as for personal
        },
        {
          ...
        }
      ]
    },
    files: [  // Empty or contains files
      {
        filename: 'weather-1.jpg',
        tempfile: '#<Tempfile:/tmp/RackMultipart20160624-29189-m0ztz3.jpg>',
        type: 'image/jpeg',
        head: 'Content-Disposition: form-data; name=\"test_file\"; filename=\"weather-1.jpg\"\r\nContent-Type: image/jpeg\r\n"'
      }
    ],
    comment: ''
  }
}
Reponse:
{
    "status": "ok",
    "result": {
        "_id": "577f6b7c0000000000000000"
    }
}
=end
post URL + '/admin/:admin_token/applications' do
  content_type :json
  token = params[:admin_token]
  resp = is_token_valid(token)
  application = {
      type: 'group', # personal/group
      group: {
          work: [
              {
                actor: 1,
                activity: {
                    _id: '576a9dcc9c05411ca409cc88',
                    title: 'hui',
                    type: 'permanent',
                    category: {
                        _id: 'some id',
                        title: 'Sport'
                    },
                    price: 100
                },
                amount: nil, # null for permanent actxivity
                total_price: 100
              }
          ]
      },
      personal: nil,
      files: [
  # {
  #     filename: 'weather-1.jpg',
  #     tempfile: '#<Tempfile:/tmp/RackMultipart20160624-29189-m0ztz3.jpg>',
  #     type: 'image/jpeg',
  #     head: 'Content-Disposition: form-data; name=\"test_file\"; filename=\"weather-1.jpg\"\r\nContent-Type: image/jpeg\r\n"'
  # }
      ],
      comment: 'Some comment'
  }
  # application = params[:application]
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:administrators].find(:user => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      if application[:type] == 'personal'
        return generate_response('error', { :description => 'ADMIN CAN\'T CREATE PERSONAL APPLICATIONS' })
      end
      #Todo rework to dynamic
      application[:author] = id
      application[:creation_date] = Time.now
      application[:status] = 'approved'
      application_id = BSON::ObjectId.from_time(application[:creation_date])
      application[:_id] = application_id
      account[:applications].push(application)
      folder = Dir.pwd + FILES_FOLDER + '/' + account[:_id] + '/' +application[:_id]
      FileUtils::mkdir_p(folder)
      application[:files].each do |file|
        file_name = file[:filename]
        name_parts = file_name.split('.')
        extension = ''
        (1..(name_parts.length - 1)).each { |i|
          extension += ('.' + name_parts[i])
        }
        file_id = BSON::ObjectId.from_time(Time.now)
        file[:_id] = file_id.to_s + extension
        File.open(folder + '/' + file_id + extension, 'w') do |f|
          f.write(file[:tempfile].read)
        end
        file.delete(:tempfile)
        file.delete(:name)
        file.delete(:head)
        download_link = URL + '/accounts/' + account[:_id] + '/applications/' + application[:_id] + '/files/' + file[:_id]
        file[:download_link] = download_link
      end
      result = settings.database[:administrators].update_one({:user => id}, {'$set' => {applications: account[:applications]}})
      if result.n == 1
        case application[:type]
          when 'personal'
             return generate_response('error', { description: 'ADMIN CAN\'T CREATE PERSONAL APPLICATION' })
          when 'group'
            accounts_to_update = Array.new
            application[:group][:work].each do |work|
              actor = nil
              settings.database[:accounts].find(owner: work[:actor]).each do |document|
                actor = document
              end
              if actor.nil?
                return generate_response('error', { :description => 'ACTOR DOES NOT EXIST'})
              end
              amount = nil
              if work[:activity][:type] == 'permanent'
                amount = work[:activity][:price]
              else
                amount = work[:activity][:price] * work[:amount]
              end
              transaction = create_transaction(amount)
              actor[:transactions].push(transaction)
              actor[:points_amount] = actor[:points_amount].to_i + amount
              accounts_to_update.push(actor)
            end
            accounts_to_update.each do |acc|
              settings.database[:accounts].update_one({:owner => acc[:owner]}, {'$set' => {:points_amount => acc[:points_amount], :transactions => acc[:transactions]}})
            end
            settings.database[:applications_archive].insert_one({author: id, application_id: application_id.to_s, status: 'approved'})
        end
        generate_response('ok', { :_id => application_id.to_s })
      else
        generate_response('error', { :description => 'INTERNAL ERROR' })
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
GetApplication
Response
{
    "status": "ok",
    "result": {
        "type": "personal",
        "personal": {
            "work": {
                "activity": {
                    "_id": "576e87479c0541471c395a97",
                    "title": "hui",
                    "type": "permanent",
                    "category": {
                        "_id": "some id",
                        "title": "Sport"
                    },
                    "price": 100
                },
                "amount": null
            }
        },
        "group": null,
        "files": [],
        "comment": "Some comment",
        "author": 1,
        "creation_date": "2016-07-08 08:11:57 UTC",
        "status": "rejected",
        "_id": "577f604d0000000000000000"
    }
}
=end
get URL + '/admin/:admin_token/accounts/:account_id/applications/:application_id' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:administrators].find(:user => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'WRONG USER' })
    else
      target_account = nil
      account_bson_id = get_bson_id(params[:account_id])
      if account_bson_id.nil?
        return generate_response('error', { :description => 'WRONG ACCOUNT ID' })
      end
      settings.database[:administrators].find(:_id => account_bson_id).each do |document|
        target_account = document
        break
      end
      if target_account.nil?
        account_bson_id = get_bson_id(params[:account_id])
        if account_bson_id.nil?
          return generate_response('error', { :description => 'WRONG ACCOUNT ID' })
        end
        settings.database[:accounts].find(:_id => account_bson_id).each do |document|
          target_account = document
          break
        end
        if target_account.nil?
          return generate_response('error', { :description => 'TARGET USER DOES NOT EXIST' })
        end
      end
      application = nil
      target_account[:applications].each do |item|
        if item[:_id] === params[:application_id]
          application = item
          break
        end
      end
      if application.nil?
        generate_response('error', { :description => 'APPLICATION DOES NOT EXIST' })
      else
        application[:_id] = application[:_id].to_s
        generate_response('ok', application)
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
Update application. It is not possible to update type of application.
Body parameters:
{
  application: {
        personal: {
            work: {
                activity: {
                    _id: '576a9dcc9c05411ca409cc88',
                    title: 'Волонтер мероприятия',
                    type: 'permanent',
                    category: {
                      _id: 'some id',
                      title: 'Волонтерство'
                    },
                    price: 100
                },
                amount: 4, # null for permanent activity
                total_price: 400
            }
        },
        group: null,
        files: [
            {
                filename: 'newfile.jpg',
                tempfile: '#<Tempfile:/tmp/RackMultipart20160624-29189-m0ztz3.jpg>',
                type: 'image/jpeg',
                head: 'Content-Disposition: form-data; name=\"test_file\"; filename=\"weather-1.jpg\"\r\nContent-Type: image/jpeg\r\n"'
            }
        ],
        comment: 'Some new comment'
    }
  }
}
Response:

{
  result: {
    _id: 123 // Application id
  },
  status: 'ok'
}
=end
put URL + '/admin/:admin_token/accounts/:account_id/applications/:application_id' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  application = {
      personal: {
          work: {
              activity: {
                  _id: '576e87479c0541471c395a97',
                  title: 'Участие в соревновании',
                  type: 'permanent',
                  category: {
                      _id: 'some id',
                      title: 'Sport'
                  },
                  price: 100
              },
              amount: nil, # null for permanent activity
          }
      },
      group: nil,
      files: [],
      comment: 'Some new comment'
  }
  # application = params[:application]
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:administrators].find(:user => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'WRONG USER' })
    else
      target_account = nil
      target_database = nil
      account_bson_id = get_bson_id(params[:account_id])
      if account_bson_id.nil?
        return generate_response('error', { :description => 'WRONG ACCOUNT ID' })
      end
      settings.database[:administrators].find(:_id => account_bson_id).each do |document|
        target_account = document
        target_database = 'administrators'
      end
      if target_account.nil?
        settings.database[:accounts].find(:_id => account_bson_id).each do |document|
          target_account = document
          target_database = 'accounts'
          break
        end
      end
      if target_account.nil?
        return generate_response('error', { :description => 'TARGET USER DOES NOT EXIST' })
      end
      app = nil
      target_account[:applications].each do |item|
        if item[:_id] === params[:application_id]
          app = item
          break
        end
      end
      if app.nil?
        generate_response('error', { :description => 'APPLICATION DOES NOT EXIST' })
      else
        case app[:type]
          when 'personal'
            activity = application[:personal][:work][:activity]
            actual_activity = nil
            activity_bson_id = get_bson_id(activity[:_id])
            if activity_bson_id.nil?
              return generate_response('error', { :description => 'WRONG ACTIVITY ID' })
            end
            settings.database[:activities].find(:_id => activity_bson_id).each do |document|
              actual_activity = document
            end
            if actual_activity.nil? || actual_activity[:price] != activity[:price]
              return generate_response('error', { :description => 'ERROR IN ACTIVITY' })
            end
            app[:personal] = application[:personal]
          when 'group'
            application[:group][:work].each do |work|
              activity = work[:activity]
              actual_activity = nil
              activity_bson_id = get_bson_id(activity[:_id])
              if activity_bson_id.nil?
                return generate_response('error', { :description => 'WRONG ACTIVITY ID' })
              end
              settings.database[:activities].find(:_id => activity_bson_id).each do |document|
                actual_activity = document
              end
              if actual_activity.nil? || actual_activity[:price] != activity[:price]
                return generate_response('error', { :description => 'ERROR IN ACTIVITY' })
              end
            end
            app[:group] = application[:group]
        end
        app[:comment] = application[:comment]
        existed_files = Array.new
        new_files = Array.new
        application[:files].each do |f|
          if f[:_id].nil?
            new_files.push(f)
          else
            existed_files.push(f)
          end
        end
        if existed_files.length != app[:files].length
          app[:files].each do |file_in_db|
            found = false
            existed_files.each do |existed_file|
              if file_in_db[:_id].to_s == existed_file[:_id]
                found = true
                break
              end
            end
            unless found
              app[:files].delete(file_in_db)
              file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + target_account[:_id] + '/' + application[:_id] + '/' + file_in_db[:_id]
              if File.exists?(file_url)
                File.delete(file_url)
              end
            end
          end
        end
        new_files.each do |file|
          file_name = file[:filename]
          name_parts = file_name.split('.')
          extension = ''
          (1..(name_parts.length - 1)).each { |i|
            extension += ('.' + name_parts[i])
          }
          file_id = BSON::ObjectId.from_time(Time.now)
          file[:_id] = file_id.to_s + extension
          file_url = Dir.pwd + '/' + FILES_FOLDER + '/' + target_account[:_id] + '/' + application[:_id] + '/' + file[:_id]
          File.open(file_url) do |f|
            f.write(file[:tempfile].read)
          end
          file.delete(:tempfile)
          file.delete(:name)
          file.delete(:head)
          download_link = URL + '/accounts/' + target_account[:_id] + '/applications/' + application[:_id] + '/files/' + file[:_id]
          file[:download_link] = download_link
          app[:files].push(file)
        end
        result = settings.database[target_database].update_one({owner: target_account[:owner]}, {'$set' => {applications: target_account[:applications]}})
        if result.n == 1
          generate_response('ok', { _id: app[:_id].to_s })
        else
          generate_response('error', { :description => 'INTERNAL ERROR' })
        end
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
ChangeApplicationStatus
Response:
{
    "status": "ok",
    "result": {
        "_id": "577f6bef0000000000000000"
    }
}
=end
put URL + '/admin/:admin_token/accounts/:account_id/applications/:application_id/:action' do
  content_type :json
  admin_token = params[:admin_token]
  resp = is_token_valid(admin_token)
  if resp[:status] == 'ok'
    id = resp[:result][:id]
    account = nil
    settings.database[:administrators].find(:user => id).each do |document|
      account = document
      break
    end
    if account.nil?
      generate_response('error', { :description => 'WRONG USER' })
    else
      target_account = nil
      account_bson_id = get_bson_id(params[:account_id])
      if account_bson_id.nil?
        return generate_response('error', { :description => 'WRONG TARGET USER ACCOUNT ID' })
      end
      settings.database[:accounts].find(:_id => account_bson_id).each do |document|
        target_account = document
        break
      end
      if target_account.nil?
        return generate_response('error', { :description => 'TARGET USER DOES NOT EXIST' })
      end
      application = nil
      target_account[:applications].each do |item|
        if item[:_id] === params[:application_id]
          application = item
          break
        end
      end
      if application.nil?
        generate_response('error', { :description => 'APPLICATION DOES NOT EXIST' })
      else
        case params[:action]
          when 'reject'
            if application[:status] != 'in_process'
              return generate_response('error', { :description => 'IT IS NOT POSSIBLE TO REJECT THE APPLICATION' })
            end
            application[:status] = 'rejected'
            settings.database[:accounts].update_one({:owner => target_account[:owner]}, {'$set' => {:applications => target_account[:applications]}})
            settings.database[:applications_in_work].find(application_id: application[:_id].to_s).delete_many
            #     .each do |item|
            #   item.remove
            # end
            settings.database[:applications_archive].insert_one({author: application[:author], application_id: application[:_id].to_s, status: 'rejected'})
          when 'approve'
            if application[:status] != 'in_process'
              return generate_response('error', { :description => 'IT IS NOT POSSIBLE TO APPROVE THE APPLICATION' })
            end
            application[:status] = 'approved'
            settings.database[:accounts].update_one({:owner => target_account[:owner]}, {'$set' => {:applications => target_account[:applications]}})
            case application[:type]
              when 'personal'
                amount = nil
                work = application[:personal][:work]
                if work[:activity][:type] == 'permanent'
                  amount = work[:activity][:price].to_i
                else
                  amount = work[:activity][:price].to_i * work[:amount]
                end
                transaction = create_transaction(amount)
                target_account[:transactions].push(transaction)
                target_account[:points_amount] += amount
                settings.database[:accounts].update_one({:owner => target_account[:owner]}, {'$set' => {:points_amount => target_account[:points_amount], :transactions => target_account[:transactions]}})
              when 'group'
                accounts_to_update = Array.new
                application[:group][:work].each do |work|
                  actor = nil
                  settings.database[:accounts].find(owner: work[:actor]).each do |document|
                    actor = document
                  end
                  if actor.nil?
                    return generate_response('error', { :description => 'ACTOR DOES NOT EXIST'})
                  end
                  amount = nil
                  if work[:activity][:type] == 'permanent'
                    amount = work[:activity][:price]
                  else
                    amount = work[:activity][:price] * work[:amount]
                  end
                  transaction = create_transaction(amount)
                  actor[:transactions].push(transaction)
                  actor[:points_amount] += amount
                  accounts_to_update.push(actor)
                end
                accounts_to_update.each do |acc|
                  settings.database[:accounts].update_one({:owner => acc[:owner]}, {'$set' => {:points_amount => acc[:points_amount], :transactions => acc[:transactions]}})
                end
            end
            # settings.database[:applications_in_work].find(application_id: application[:_id].to_s).each do |item|
            #   item.remove
            # end
            settings.database[:applications_in_work].find(application_id: application[:_id].to_s).delete_many
            settings.database[:applications_archive].insert_one({author: application[:author], application_id: application[:_id].to_s, status: 'approved'})
          when 'to_rework'
            if application[:status] != 'in_process'
              return generate_response('error', { :description => 'IT IS NOT POSSIBLE TO SEND TO REWORK THE APPLICATION' })
            end
            application[:status] = 'rework'
            settings.database[:accounts].update_one({:owner => target_account[:owner]}, {'$set' => {:applications => target_account[:applications]}})
            settings.database[:applications_in_work].update_one({application_id: application[:_id].to_s}, {'$set' => {status: 'rework'}})
          else
            return generate_response('error', { :description => 'WRONG ACTION' })
        end
        generate_response('ok', { :_id => application[:_id].to_s })
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end
