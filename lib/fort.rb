# coding: utf-8
module ROGv
  class Fort
    include MongoMapper::EmbeddedDocument

    key :fort_id,     String, :required => true
    key :fort_name,   String, :required => true
    key :formal_name, String, :required => true
    key :guild_name,  String, :required => true
    key :update_time, Time,   :required => true

    def self.create_from_data(d)
      f = Fort.new
      f.fort_id = d['id']
      f.fort_name = d['name']
      f.formal_name = d['formal_name']
      f.guild_name = d['guild_name']
      f.update_time = Time.parse(d['update_time'])
      f
    end

    def changed?(udata)
      return false unless udata
      return false if self.update_time > udata.update_time
      return false if self.guild_name == udata.guild_name
      true
    end

    def uptime_from(t)
      return unless t
      (t - self.update_time).to_i
    end

    def hot?(t)
      ut = uptime_from(t)
      return false unless ut
      ut <= ROGv::ServerConfig.attention_minitues * 60 ? true : false
    end
  end
end
