MongoMapper.connection = Mongo::Connection.new('localhost', nil, :logger => logger)
MongoMapper.database = ROGv::ServerConfig.db_name
if (ROGv::ServerConfig.db_user && ROGv::ServerConfig.db_pass)
  MongoMapper.database.authenticate(
    ROGv::ServerConfig.db_user, ROGv::ServerConfig.db_pass)
end
