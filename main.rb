require 'sinatra'
require 'mongo'
require 'json'
require 'fileutils'
require 'httparty'
require_relative 'config'
set :public_folder => '/public'

helpers do
  def is_token_valid(token)
    resp = HTTParty.get(ACCOUNTS_URL + token)
    # if token == 'test'
    #   resp[:status] = 'ok'
    #   resp[:result] = Hash.new
    #   resp[:result][:id] = 1
    # else
    #   resp[:status] = 'error'
    # end
    resp.body
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

# Return list of accounts
# get URL + '/accounts/:token/list' do
#   content_type :json
#   token = params[:token]
#   resp = is_token_valid(token)
#   if resp[:status] == 'ok'
#     id = resp[:result][:id]
#     account = nil
#     settings.database[:administrators].find(:user => id).each do |document|
#       account = document
#       break
#     end
#     if account.nil?
#       generate_response('error', { :description => 'WRONG USER' })
#     else
#       accounts = Array.new
#       settings.database[:accounts].find().each do |document|
#         accounts.push({:owner => document[:owner], :points_amount => document[:points_amount]})
#       end
#       generate_response('ok', accounts)
#     end
#   else
#     generate_response('error', { :description => 'USER DOES NOT EXIST' })
#   end
# end


# get '/api/v1/accounts/:token' do
#   content_type :json
#   asd = Hash.new
#   asd[:status] = 'ok'
#   asd[:result] = Hash.new
#   asd[:result][:id] = 1
#   asd.to_json
# end
#
# get '/test' do
#   content_type :json
#   result = is_token_valid('asd')
#   result
# end

=begin
Return account info
{
  result: {
    owner: id // id of user account in uis system
    points_amount: 100
  },
  status: 'ok'
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
      generate_response('error', { :description => 'ACCOUNT DOES NOT EXIST' })
    else
      generate_response('ok', { :owner => id, :points_amount => account[:points_amount] })
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
Create account
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
    puts '-----------------------'
    puts id
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
Create application
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
    commentary: ''
  }
}


=end
post URL + '/accounts/:token/applications' do

  content_type :json
  token = params[:token]
  resp = is_token_valid(token)
  # application = {
  #     type: 'personal', # personal/group
  #     personal: {
  #         work: {
  #             activity: {
  #                 _id: '576a9dcc9c05411ca409cc88',
  #                 title: 'hui',
  #                 type: 'permanent',
  #                 category: {
  #                     _id: 'some id',
  #                     title: 'Sport'
  #                 },
  #                 price: 100
  #             },
  #             amount: nil, # null for permanent actxivity
  #             total_price: 100
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
      # commentary: 'Some comment'
  # }
  application = params[:application]
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
      end
      result = settings.database[:accounts].update_one({:owner => id}, {'$set' => {applications: account[:applications]}})
      if result.n == 1
        generate_response('ok', { :_id => application_id })
      else
        generate_response('error', { :description => 'INTERNAL ERROR' })
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

=begin
Get user applications
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
      if skip.nil?
        skip = 0
      elsif skip < 0
        skip = 0
      end
      if limit.nil?
        limit = -1
      elsif limit < 0
        limit = -1
      end
      skip = skip.to_i
      if limit != 0
        limit = limit.to_i
        if limit == 0
          limit = -1
        end
      end
      counter = 0
      puts account[:applications].length
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

# Get user applications with status in process
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
      if skip.nil?
        skip = 0
      elsif skip < 0
        skip = 0
      end
      if limit.nil?
        limit = -1
      elsif limit < 0
        limit = -1
      end
      skip = skip.to_i
      if limit != 0
        limit = limit.to_i
        if limit == 0
          limit = -1
        end
      end
      counter = 0
      for i in skip..account[:applications].length
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

# Get user applications with status rework
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
      if skip.nil?
        skip = 0
      elsif skip < 0
        skip = 0
      end
      if limit.nil?
        limit = -1
      elsif limit < 0
        limit = -1
      end
      skip = skip.to_i
      if limit != 0
        limit = limit.to_i
        if limit == 0
          limit = -1
        end
      end
      counter = 0
      for i in skip..account[:applications].length
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

# Get user applications with status approved
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
      if skip.nil?
        skip = 0
      elsif skip < 0
        skip = 0
      end
      if limit.nil?
        limit = -1
      elsif limit < 0
        limit = -1
      end
      skip = skip.to_i
      if limit != 0
        limit = limit.to_i
        if limit == 0
          limit = -1
        end
      end
      counter = 0
      for i in skip..account[:applications].length
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

# Get user applications with status rejected
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
      if skip.nil?
        skip = 0
      elsif skip < 0
        skip = 0
      end
      if limit.nil?
        limit = -1
      elsif limit < 0
        limit = -1
      end
      skip = skip.to_i
      if limit != 0
        limit = limit.to_i
        if limit == 0
          limit = -1
        end
      end
      counter = 0
      for i in skip..account[:applications].length
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
        "commentary": "Some comment",
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
        application[:files].each do |file|
          download_link = URL + '/accounts/' + token + '/applications/' + application[:_id] + '/files/' + file[:_id]
          file[:download_link] = download_link
        end
        generate_response('ok', application)
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

# Get file
get URL + '/accounts/:token/applications/:application_id/files/:file_id' do
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
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

# Delete user application
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
        if app[:_id] == BSON::ObjectId(application_id) && (app[:status] == 'in_process' || app[:status] == 'rejected' || app[:status] == 'rework')
          application = account[:applications].delete(app)
        end
      end
      if application.nil?
        generate_response('error', { :description => 'APPLICATION DOES NOT EXIST OR IT IS NOT POSSIBLE TO DELETE' })
      else
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
      commentary: 'Some new comment'
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
                  _id: '576a9dcc9c05411ca409cc88',
                  title: 'hui',
                  type: 'permanent',
                  category: {
                    _id: 'some id',
                    title: 'Sport'
                  },
                  price: 100
              },
              amount: nil, # null for permanent activity
              total_price: 100
          }
      },
      group: nil,
      files: [],
      commentary: 'Some comment'
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
          case item[:type]
            when 'personal'
              item[:personal] = application[:personal]
            when 'group'
              item[:group] = application[:group]
          end
          item[:files] = application[:files]
          item[:commentary] = application[:commentary]
          break
        end
      end
      if app.nil?
        generate_response('error', { :description => 'APPLICATION DOES NOT EXIST' })
      else
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
          app[:files].push(file)
        end
        result = settings.database[:accounts].update_one({owner: id}, {'$set' => {applications: account[:applications]}})
        if result.n == 1
          generate_response('ok', { _id: app[:_id] })
        else
          generate_response('error', { :description => 'INTERNAL ERROR' })
        end
      end
    end
  else
    generate_response('error', { :description => 'USER DOES NOT EXIST' })
  end
end

#---------------------- Administrator API ---------------------------
