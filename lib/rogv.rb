# coding: utf-8
module ROGv
  APP_ENV = ENV["RACK_ENV"] || 'development'
  APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  require 'bundler/setup'
  Bundler.require(:default, APP_ENV)

  path = File.expand_path(File.join(File.dirname(__FILE__), 'rogv'))
  require File.join(path, 'time_util')
  require File.join(path, 'memcache_manager')
  require File.join(path, 'server_config')
  require File.join(path, 'mongo')
  require File.join(path, 'fort')
  require File.join(path, 'situation')
  require File.join(path, 'posted_situation')
  require File.join(path, 'updater')
  require File.join(path, 'fort_timeline')
  require File.join(path, 'guild_timeline')
  require File.join(path, 'dumper')
  require File.join(path, 'server')
end