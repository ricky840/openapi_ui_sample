require 'rubygems'
require 'akamai/edgegrid'
require 'net/http'
require 'uri'
require 'json'
require 'sinatra'

require File.expand_path '../openapi_ui.rb', __FILE__ #absolute path to the file /var/www/rubyapp/openapi_sample/app.rb

run Sinatra::Application
