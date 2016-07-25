require 'rubygems'
require 'sinatra'
require File.expand_path '../openapi_ui.rb', __FILE__ #absolute path to the file /var/www/rubyapp/openapi_sample/app.rb

run Sinatra::Application
