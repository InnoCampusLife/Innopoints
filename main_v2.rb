require 'sinatra/base'
require 'json'
require 'httparty'
require_relative 'config'
require_relative 'routes/applications/init'
require_relative 'routes/shop/init'
require_relative 'models/init'
require_relative 'helpers/helper'
require_relative './env' if File.exists?('env.rb')

class MyApp < Sinatra::Base

  set :public_folder => '/public'

  set :bind, WEB_HOST
  set :port, WEB_PORT

  helpers ValidationHelpers
  register Applications::User
  register Applications::Admin
  register Applications::General
  register Shop::User
  register Shop::Admin
  register Shop::General

  run!
end