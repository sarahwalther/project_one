require 'uri'
require 'date'
require 'json'
require 'redis'
require 'httparty'
require 'sinatra/base'
require 'sinatra/reloader'

require_relative 'database_helper'
require_relative 'server'

run ProgressNotes::Server
