# coding: utf-8
module ROGv
  ROGv::Server.helpers do
    include TimeUtil
    include FortUtil

    def reload_cycle
      ['30', '60', '120']
    end

    def sample_mode?
      ServerConfig.auth_sample_mode ? true : false
    end

    def updatable_mode?
      return false if sample_mode?
      ServerConfig.auth_view_mode ? false : true
    end

    def encode_for_url(s)
      URI.encode_www_form_component(s).gsub("+", "%20")
    end

    def decode_for_url(s)
      URI.decode_www_form_component(s.gsub("%20", "+"))
    end

  end
end