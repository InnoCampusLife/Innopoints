require 'mysql2'
require_relative 'config'

DB = Mysql2::Client.new(:host => MYSQL_DB_HOST, :port => MYSQL_DB_PORT, :username => MYSQL_DB_USER, :password => MYSQL_DB_PASSWORD, :database => MYSQL_DB_NAME)
DB.query_options.merge!(:symbolize_keys => true)