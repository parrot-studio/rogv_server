# coding: utf-8
module ROGv
  APP_ENV = ENV["RACK_ENV"] || 'development'
  APP_ROOT = File.join(File.dirname(__FILE__), '..')

  require 'bundler/setup'
  Bundler.require(:default, APP_ENV)

  path = File.join(File.dirname(__FILE__), 'rogv')
  require File.join(path, 'memcache_manager')
  require File.join(path, 'server_config')
  require File.join(path, 'fort')
  require File.join(path, 'server')
end