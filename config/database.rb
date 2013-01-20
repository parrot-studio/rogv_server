MongoMapper.connection = Mongo::Connection.new('localhost', nil, :logger => logger)
MongoMapper.database = ROGv::ServerSettings.db.name
if (ROGv::ServerSettings.db.user && ROGv::ServerSettings.db.pass)
  MongoMapper.database.authenticate(
    ROGv::ServerSettings.db.user, ROGv::ServerSettings.db.pass)
end
