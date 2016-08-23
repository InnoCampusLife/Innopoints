require 'mysql2'

DB = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => 'ajvxtyrj', :database => 'innopoints')
DB.query_options.merge!(:symbolize_keys => true)