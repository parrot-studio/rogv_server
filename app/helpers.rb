# coding: utf-8
module ROGv
  ROGv::Server.helpers do
    include TimeUtil
    include FortUtil

    def reload_cycle
      ['30', '60', '120']
    end

    def sample_mode?
      ServerSettings.sample_mode? ? true : false
    end

    def updatable_mode?
      return false if sample_mode?
      ServerSettings.view_mode? ? false : true
    end

    def encode_for_url(s)
      URI.encode_www_form_component(s).gsub("+", "%20")
    end

    def decode_for_url(s)
      URI.decode_www_form_component(s.gsub("%20", "+"))
    end

    def use_db_cache?
      return false unless ServerSettings.use_db_cache?
      TimeUtil.in_battle_time? ? false : true
    end

    def format_span(from, to)
      return unless (from && to)
      "#{devided_date(from)} - #{devided_date(to)}"
    end

  end
end