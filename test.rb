require 'mongo'
require 'json'
require_relative 'config'
require_relative 'database_handler'

# db = Mongo::Client.new([ "#{DB_HOST}:#{DB_PORT}" ], :database => DATABASE)
#
# db[:accounts].insert_one({:owner => 10, :points_amount => 100, :transactions => [], :applications => [], :orders => [], :creation_date => Time.now})
# db[:applications_archive].find().delete_many
#577f598b0000000000000000
# db[:applications_in_work].find().each do |activity|
#   puts activity
#   break
# end
# db[:applications_in_work].insert_one({author: 1, application_id: '577b96ca0000000000000000', status: 'in_process'})
# 577b96ca0000000000000000
# {"_id"=>BSON::ObjectId('577b96ca9c05411662685296'), "author"=>1, "application_id"=>"577b96ca0000000000000000", "status"=>"in_process"}

# puts '------------------------'
# db[:accounts].find().each do |activity|
#   puts activity
#   activity[:applications].each do |application|
#     if application[:_id] === '577f598b0000000000000000'
#       application[:status] = 'in_process'
#       db[:accounts].update_one({:owner => activity[:owner]}, {'$set' => {:applications => activity[:applications]}})
#       break
#     end
#   end
# end
#577b96ca0000000000000000
#577b96ca0000000000000000
# asd = nil
# begin
# asd = Integer(asd)
# rescue ArgumentError, TypeError
#   asd = 0
# end
#
# puts asd

#577b96ca0000000000000000
# begin
# asd = BSON::ObjectId('asd')
# rescue BSON::ObjectId::Invalid
#   puts 'asd'
# end
asd = 'asd'
if asd == true
  puts 'true'
elsif asd == false
  puts 'false'
else
  puts 'nil'
end
