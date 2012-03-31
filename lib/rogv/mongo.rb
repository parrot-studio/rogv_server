# coding: utf-8
require 'mongo_mapper'
MongoMapper.database = ROGv::ServerConfig.db_name
if (ROGv::ServerConfig.db_user && ROGv::ServerConfig.db_pass)
  MongoMapper.database.authenticate(
    ROGv::ServerConfig.db_user, ROGv::ServerConfig.db_pass)
end
